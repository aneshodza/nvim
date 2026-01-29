local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

return {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "solargraph", "stdio" },
  filetypes = { "ruby" },
  root_dir = function(bufnr)
    return vim.fs.root(bufnr, { "Gemfile", ".git" })
  end,
  settings = {
    solargraph = {
      diagnostics = true,
    },
  },
}
