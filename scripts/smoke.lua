-- nvim --headless -l scripts/smoke.lua
--
-- Boots the real config and asserts on the result. Two traps shape this:
--
--   1. `nvim --headless -u init.lua +qa` exits 0 even when the config raises,
--      so it can never be the CI gate. `nvim -l` exits 1 when the script
--      errors, which is why this is a script and not a -c invocation.
--   2. lazy.nvim wraps every plugin init/config in Util.try, whose handler
--      defers to vim.notify, so plugin errors become deferred notifications
--      rather than propagating. scripts/lib.lua captures them.

local config_dir = vim.fn.stdpath "config"
local lib = dofile(config_dir .. "/scripts/lib.lua")

local failures = {}

local function check(cond, msg)
  if not cond then
    failures[#failures + 1] = msg
  end
end

local errors = lib.boot()

-- base46 actually compiled; init.lua dofile()s these unconditionally
for _, name in ipairs { "defaults", "statusline" } do
  check(vim.fn.filereadable(vim.g.base46_cache .. name) == 1, "missing base46 cache: " .. name)
end

-- lazy resolved the spec without complaints
local lz = require "lazy.core.config"
check(#lz.spec.notifs == 0, "lazy spec notifications: " .. vim.inspect(lz.spec.notifs))

for name, plugin in pairs(lz.spec.plugins) do
  check(plugin._.installed, "plugin not installed: " .. name)
end

-- every server we ship is configured AND enabled
local expected_servers =
  { "angularls", "basedpyright", "clangd", "cssls", "html", "omnisharp", "pylsp", "solargraph", "ts_ls" }

for _, name in ipairs(expected_servers) do
  check((vim.lsp._enabled_configs or {})[name] ~= nil, "server not enabled: " .. name)
end

-- the regression this whole server-spec convention exists to prevent
local omnisharp = vim.lsp.config.omnisharp
check(
  omnisharp
    and omnisharp.capabilities
    and omnisharp.capabilities.workspace
    and omnisharp.capabilities.workspace.workspaceFolders == false,
  "omnisharp lost nvim-lspconfig's workspaceFolders = false workaround "
    .. "(a per-server capabilities table will do this)"
)

-- conform still routes the filetypes we care about
local conform = require("conform").formatters_by_ft
check(conform.cs and conform.cs[1] == "csharpier", "conform lost the cs formatter")
check(conform.lua and conform.lua[1] == "stylua", "conform lost the lua formatter")

-- mason derives the packages that used to be missing from ensure_installed
local pkgs = require("nvchad.mason").get_pkgs()

for _, name in ipairs { "angular-language-server", "omnisharp", "csharpier", "eslint_d", "rust-analyzer" } do
  check(vim.tbl_contains(pkgs, name), "mason no longer derives: " .. name)
end

check(not vim.tbl_contains(pkgs, "deno"), "stale mason package 'deno' is back")

-- keymaps match the golden file, collected exactly as dump.lua collects it
local maps = lib.keymaps()

local golden_path = config_dir .. "/scripts/expected/keymaps.txt"

if vim.fn.filereadable(golden_path) == 1 then
  local golden = vim.fn.readfile(golden_path)

  if not vim.deep_equal(maps, golden) then
    local want, got = {}, {}
    for _, line in ipairs(golden) do
      want[line] = true
    end
    for _, line in ipairs(maps) do
      got[line] = true
    end

    local missing, extra = {}, {}
    for _, line in ipairs(golden) do
      if not got[line] then
        missing[#missing + 1] = line
      end
    end
    for _, line in ipairs(maps) do
      if not want[line] then
        extra[#extra + 1] = line
      end
    end

    check(
      false,
      ("keymap drift (regenerate with scripts/dump.lua)\n  missing: %s\n  extra: %s"):format(
        table.concat(missing, " | "),
        table.concat(extra, " | ")
      )
    )
  end
else
  io.stdout:write "note: scripts/expected/keymaps.txt absent, skipping keymap check\n"
end

check(#errors == 0, "ERROR notifications during startup:\n" .. table.concat(errors, "\n---\n"))

if #failures > 0 then
  io.stderr:write("\n" .. table.concat(failures, "\n\n") .. "\n")
  error(("smoke: %d check(s) failed"):format(#failures), 0)
end

io.stdout:write "smoke: ok\n"
