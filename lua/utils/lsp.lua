local M = {}

-- pylsp's rope auto-import only offers "add import" actions for diagnostics that
-- look like flake8's ("undefined name") or mypy's ("name-defined"). basedpyright
-- reports reportUndefinedVariable, so relabel a copy for the request - it ignores
-- context.diagnostics itself, and this avoids running a second linter just to
-- produce a matching message. Titles are deduplicated because both servers
-- suggest the same import when they both know the symbol.
M.code_action = function()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = {}

  for _, d in ipairs(vim.diagnostic.get(0, { lnum = lnum })) do
    local lsp_diagnostic = d.user_data and d.user_data.lsp

    if lsp_diagnostic then
      if lsp_diagnostic.code == "reportUndefinedVariable" then
        lsp_diagnostic = vim.tbl_extend("force", lsp_diagnostic, { code = "name-defined" })
      end

      table.insert(diagnostics, lsp_diagnostic)
    end
  end

  local seen = {}

  vim.lsp.buf.code_action {
    context = { diagnostics = diagnostics },
    filter = function(action)
      if seen[action.title] then
        return false
      end

      seen[action.title] = true
      return true
    end,
  }
end

return M
