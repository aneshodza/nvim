local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

return {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less" },
  settings = {
    css = {
      validate = true,
    },
    scss = {
      validate = true,
    },
    less = {
      validate = true,
    },
  }
}

