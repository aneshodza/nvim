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

-- Keymaps: the golden file is a regression FLOOR, not an exact match.
--
-- Asserting equality breaks across Neovim versions for reasons that are not
-- regressions: 0.12 adds grt/grx as LSP defaults and a set of treesitter
-- node-selection maps, and reworded [<C-T>. So compare on (mode, lhs) only -
-- descriptions churn upstream - and fail only on mappings that disappeared.
-- Additions are printed for review but do not fail the build; scripts/dump.lua
-- is the tool for inspecting those.
local golden_path = config_dir .. "/scripts/expected/keymaps.txt"

if vim.fn.filereadable(golden_path) == 1 then
  local function lhs_only(lines)
    local set = {}

    for _, line in ipairs(lines) do
      local mode, lhs = line:match "^([^\t]*)\t([^\t]*)"

      if mode then
        set[mode .. "\t" .. lhs] = true
      end
    end

    return set
  end

  local want = lhs_only(vim.fn.readfile(golden_path))
  local got = lhs_only(lib.keymaps())

  local missing, extra = {}, {}

  for key in pairs(want) do
    if not got[key] then
      missing[#missing + 1] = key
    end
  end

  for key in pairs(got) do
    if not want[key] then
      extra[#extra + 1] = key
    end
  end

  table.sort(missing)
  table.sort(extra)

  check(#missing == 0, "keymaps lost:\n  " .. table.concat(missing, "\n  "))

  if #extra > 0 then
    io.stdout:write(
      "note: " .. #extra .. " new keymap(s) not in the golden file:\n  " .. table.concat(extra, "\n  ") .. "\n"
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
