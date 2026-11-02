-- Tools a project pins through mise. Two reasons not to trust a bare PATH
-- lookup: mason's bin dir is prepended to PATH (nvchad/options.lua), so a
-- mason copy shadows the pinned version pre-commit runs; and mise's shims are
-- on PATH everywhere, so a tool looks executable even in projects that don't
-- pin it, where the shim then fails.

local M = {}

local cache = {}

--- The path of `tool` as mise pins it for `dir`, or nil when nothing pins it.
--- @param tool string
--- @param dir string?
--- @return string?
function M.which(tool, dir)
  dir = dir or vim.fn.getcwd()
  local key = tool .. "\0" .. dir

  if cache[key] == nil then
    cache[key] = false

    if vim.fn.executable "mise" == 1 then
      local result = vim.system({ "mise", "which", tool, "-C", dir }, { text = true }):wait()
      local path = vim.trim(result.stdout or "")

      if result.code == 0 and path ~= "" and vim.fn.executable(path) == 1 then
        cache[key] = path
      end
    end
  end

  return cache[key] or nil
end

return M
