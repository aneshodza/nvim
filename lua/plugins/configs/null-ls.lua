local present, null_ls = pcall(require, "null-ls")
if not present then return end

local function use_extra(path)
  local ok, extra = pcall(require, "none-ls." .. path)
  if ok then
    return extra
  end
  return nil
end

local sources = {
  use_extra("diagnostics.eslint_d") and use_extra("diagnostics.eslint_d").with({
    filetypes = { "javascript", "typescript", "html", "htmlangular" },
    timeout = 5000,
    condition = function(utils)
      local cwd = vim.fn.getcwd()
      local configs = {
        "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs",
        ".eslintrc.js", ".eslintrc.json", ".eslintrc"
      }
      for _, config in ipairs(configs) do
        if vim.fn.filereadable(cwd .. "/" .. config) == 1 then
          return true
        end
      end
      return false
    end,
    method = {
      null_ls.methods.DIAGNOSTICS_ON_OPEN,
      null_ls.methods.DIAGNOSTICS_ON_SAVE
    },
    cwd = function(params)
      return vim.fn.getcwd()
    end,
  }),

  use_extra("code_actions.eslint_d"),
}

local active_sources = {}
for _, source in ipairs(sources) do
  if source then
    table.insert(active_sources, source)
  end
end

null_ls.setup({
  debug = true,
  sources = active_sources,
})
