return {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
  },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(fname, { "package.json", "tsconfig.json", ".git" })
                 or vim.uv.cwd()
    if root then
      on_dir(root)
    end
  end,
  init_options = {
    hostInfo = "neovim",
    preferences = {
      importModuleSpecifierPreference = "non-relative",
    },
  },
}
