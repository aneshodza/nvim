local lspconfig = require("lspconfig")
local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

return {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "json"
  },
  root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", ".git"),
  on_attach = on_attach,
  capabilities = capabilities,
}
