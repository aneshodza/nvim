local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("cmp_nvim_lsp").default_capabilities()

return {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = {
    vim.fn.stdpath("data") .. "/mason/bin/omnisharp",
    "--languageserver",
    "--hostPID",
    tostring(vim.fn.getpid()),
  },
  root_dir = require("lspconfig.util").root_pattern("*.sln", "*.csproj", ".git"),
}
