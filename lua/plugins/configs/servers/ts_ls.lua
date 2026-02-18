return {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
  },
  root_dir = function(fname)
    return vim.fs.root(fname, { "package.json", "tsconfig.json", ".git" }) 
           or vim.uv.cwd()
  end,
  init_options = {
    hostInfo = "neovim",
    preferences = {
      importModuleSpecifierPreference = "non-relative",
    },
  },
}
