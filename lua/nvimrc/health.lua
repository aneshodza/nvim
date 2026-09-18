-- :checkhealth nvimrc
--
-- Covers the things this config depends on that live outside the repo, so a
-- fresh machine can be checked in one command.

local M = {}

local start = vim.health.start
local ok = vim.health.ok
local warn = vim.health.warn
local error = vim.health.error
local info = vim.health.info

--- Tools that are not mason packages and have to be installed by hand.
local external = {
  { bin = "git", why = "gitsigns, lazy.nvim, <leader>gc" },
  { bin = "rg", why = "telescope live_grep" },
  { bin = "node", why = "ts_ls, angularls, html/css servers" },
  { bin = "dotnet", why = "omnisharp, <leader>de" },
  { bin = "solargraph", why = "ruby lsp (gem install solargraph)" },
  { bin = "latexmk", why = "vimtex compilation" },
  { bin = "python3", why = "basedpyright interpreter fallback" },
}

local function check_external()
  start "external tools"

  for _, tool in ipairs(external) do
    local path = vim.fn.exepath(tool.bin)

    if path ~= "" then
      ok(("%s: %s"):format(tool.bin, path))
    else
      warn(("%s not on PATH - needed for %s"):format(tool.bin, tool.why))
    end
  end
end

local function check_mason()
  start "mason packages"

  local present, registry = pcall(require, "mason-registry")

  if not present then
    warn "mason-registry unavailable (run :Mason once)"
    return
  end

  local derived = require("nvchad.mason").get_pkgs()
  local missing = {}

  for _, name in ipairs(derived) do
    local found, pkg = pcall(registry.get_package, name)

    if not found or not pkg:is_installed() then
      table.insert(missing, name)
    end
  end

  if #missing == 0 then
    ok(("all %d derived packages installed"):format(#derived))
  else
    warn(("not installed: %s"):format(table.concat(missing, ", ")), { "Run :MasonInstallAll" })
  end
end

local function check_pyvenv()
  start "pylsp rope auto-import"

  local pyvenv = require "utils.pyvenv"
  local state = pyvenv.ensure()

  if state == "missing" then
    info("python-lsp-server not installed; nothing to check (" .. pyvenv.cfg_path() .. ")")
  elseif state == "fixed" then
    warn "pyvenv.cfg had include-system-site-packages = true and was reset to false"
    info "Mason rebuilds that venv with --system-site-packages, which makes rope index the global python"
  else
    ok "include-system-site-packages = false"
  end
end

local function check_python_lsp_pair()
  start "python servers"

  for _, name in ipairs { "basedpyright", "pylsp" } do
    if (vim.lsp._enabled_configs or {})[name] then
      ok(name .. " enabled")
    else
      error(name .. " not enabled - check lua/configs/servers/" .. name .. ".lua")
    end
  end
end

function M.check()
  check_external()
  check_mason()
  check_pyvenv()
  check_python_lsp_pair()
end

return M
