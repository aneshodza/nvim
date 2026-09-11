local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

return {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "solargraph", "stdio" },
  filetypes = { "ruby" },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(fname, { "Gemfile", ".git" })
    if root then
      on_dir(root)
    end
  end,
  settings = {
    solargraph = {
      diagnostics = true,
    },
  },
}
