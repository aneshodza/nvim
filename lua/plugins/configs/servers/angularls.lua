local lspconfig = require "lspconfig"
local util = lspconfig.util
local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

-- Mason path for the server binary (as you have working)
local mason_pkg = vim.fn.stdpath "data" .. "/mason/packages/angular-language-server"
local ngserver = mason_pkg .. "/node_modules/@angular/language-server/bin/ngserver"

-- Probe the GLOBAL npm node_modules so the LS finds @angular/language-service and typescript
local npm_root_g = (vim.fn.systemlist("npm root -g")[1] or ""):gsub("%s+$", "")

return {
  cmd = {
    "node",
    ngserver,
    "--stdio",
    "--tsProbeLocations",
    npm_root_g,
    "--ngProbeLocations",
    npm_root_g,
  },
  filetypes = { "typescript", "html" },
  root_dir = util.root_pattern("angular.json", "project.json", ".git"),
  on_new_config = function(new_config, root_dir)
    new_config.cmd = {
      "node",
      ngserver,
      "--stdio",
      "--tsProbeLocations",
      npm_root_g,
      "--ngProbeLocations",
      npm_root_g,
    }
  end,
  on_attach = on_attach,
  capabilities = capabilities,
}
