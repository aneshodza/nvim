local nvlsp = require "plugins.configs.lspconfig"

local on_attach = nvlsp.on_attach
local capabilities = nvlsp.capabilities

-- 1. HARDCODED PATHS
local project_root = "/home/aneshodza/work/Aventis/src/Aventis.Frontend/ClientApp"
-- Path to the actual JS entry point inside Mason
local tsserver_js = "/home/aneshodza/.local/share/nvim/mason/packages/typescript-language-server/node_modules/typescript-language-server/lib/cli.mjs"

return {
  -- Call node directly and point to the .mjs file
  cmd = { 
    "node", 
    tsserver_js, 
    "--stdio" 
  },
  
  filetypes = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "json",
  },

  -- Force the root directory
  root_dir = project_root,

  on_attach = on_attach,
  capabilities = capabilities,
  
  init_options = {
    hostInfo = "neovim",
    preferences = {
      -- Important for Angular project structures
      importModuleSpecifierPreference = "non-relative",
    },
  },
}
