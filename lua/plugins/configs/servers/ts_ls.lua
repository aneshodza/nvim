local lspconfig = require("lspconfig")

return {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "html",
    "css",
    "json"
  },
  root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", ".git"),
}
