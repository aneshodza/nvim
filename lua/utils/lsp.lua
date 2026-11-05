local M = {}

-- ty runs with its diagnostics off (configs/servers/ty.lua), and it only offers
-- "import ..." fixes for diagnostics it recognises as its own
-- unresolved-reference. basedpyright reports the same thing as
-- reportUndefinedVariable, so a relabelled copy is added for the request. The
-- copy must not carry basedpyright's `data` or `codeDescription`: ty ignores a
-- diagnostic whose `data` it can't parse. ty's own "Ignore ... for this line"
-- action is dropped because ty isn't the checker here. Titles are deduplicated
-- in case two servers suggest the same fix.
--- @param lsp_diagnostic lsp.Diagnostic
--- @return lsp.Diagnostic?
function M.as_ty_diagnostic(lsp_diagnostic)
  if lsp_diagnostic.code ~= "reportUndefinedVariable" then
    return nil
  end

  return {
    range = lsp_diagnostic.range,
    severity = lsp_diagnostic.severity,
    message = lsp_diagnostic.message,
    code = "unresolved-reference",
    source = "ty",
  }
end

M.code_action = function()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = {}

  for _, d in ipairs(vim.diagnostic.get(0, { lnum = lnum })) do
    local lsp_diagnostic = d.user_data and d.user_data.lsp

    if lsp_diagnostic then
      table.insert(diagnostics, lsp_diagnostic)
      table.insert(diagnostics, M.as_ty_diagnostic(lsp_diagnostic))
    end
  end

  local seen = {}

  vim.lsp.buf.code_action {
    context = { diagnostics = diagnostics },
    filter = function(action, client_id)
      local client = vim.lsp.get_client_by_id(client_id)

      if client and client.name == "ty" and action.title:match "^Ignore " then
        return false
      end

      if seen[action.title] then
        return false
      end

      seen[action.title] = true
      return true
    end,
  }
end

return M
