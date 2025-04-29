local on_attach = require("plugins.configs.lspconfig").on_attach
local cmp_nvim_lsp = require "cmp_nvim_lsp"

return {
  on_attach = on_attach,
  capabilities = cmp_nvim_lsp.default_capabilities(),
  cmd = {
    "clangd",
    "--offset-encoding=utf-16",
  },
}
