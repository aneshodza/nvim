-- Root at the outermost oxlint config rather than nvim-lspconfig's nearest one.
-- Monorepos like dj2 keep run-wide options (typeAware, ...) in a root config
-- that nested package configs may not carry, and resolve plugin settings
-- against the cwd, so the server has to run from where the CLI does.
local markers = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" }

return {
  root_dir = function(bufnr, on_dir)
    local found = vim.fs.find(markers, {
      path = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)),
      upward = true,
      limit = math.huge,
    })

    if #found > 0 then
      on_dir(vim.fs.dirname(found[#found]))
    end
  end,
}
