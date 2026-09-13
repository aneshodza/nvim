-- Report startup time once the UI has settled, coloured by threshold.

local M = {}

-- Milliseconds. This config measures ~25ms with 7/43 plugins loaded eagerly,
-- so these leave a lot of headroom - they are meant to catch a regression,
-- not to nag about normal variance.
M.warn_ms = 100
M.slow_ms = 250

local GROUPS = {
  ok = { name = "StartupTimeOk", link = "DiagnosticOk", icon = "" },
  warn = { name = "StartupTimeWarn", link = "DiagnosticWarn", icon = "" },
  slow = { name = "StartupTimeSlow", link = "DiagnosticError", icon = "" },
}

--- @param ms number
--- @return { name: string, link: string, icon: string }
function M.level_for(ms)
  if ms >= M.slow_ms then
    return GROUPS.slow
  elseif ms >= M.warn_ms then
    return GROUPS.warn
  end

  return GROUPS.ok
end

--- Link our groups to the diagnostic ones so they follow the colourscheme.
--- Re-linked on ColorScheme because base46 rebuilds highlights on theme switch.
function M.set_highlights()
  for _, group in pairs(GROUPS) do
    vim.api.nvim_set_hl(0, group.name, { link = group.link, default = true })
  end
end

function M.report()
  local ok, lazy = pcall(require, "lazy")

  if not ok then
    return
  end

  local stats = lazy.stats()

  -- startuptime is only populated at UIEnter, which never fires headless
  if not stats.startuptime or stats.startuptime == 0 then
    return
  end

  local ms = stats.startuptime
  local level = M.level_for(ms)

  local message = string.format("%s  %.0fms   %d/%d plugins", level.icon, ms, stats.loaded, stats.count)

  vim.api.nvim_echo({ { message, level.name } }, true, {})
end

return M
