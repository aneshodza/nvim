-- Mason builds python-lsp-server's venv with --system-site-packages, which puts
-- the global (asdf) python's site-packages on sys.path. rope builds its
-- auto-import index from sys.path, so with that flag on it indexes every
-- globally installed package and offers imports that do not exist in the
-- project - 60k+ names from AppKit, PIL and friends in one measured case.
--
-- The fix is one line in pyvenv.cfg, which lives outside the repo and is
-- silently reverted by any mason reinstall. Hence a self-heal rather than a
-- one-off edit.

local M = {}

local KEY = "include-system-site-packages"
local WANT = KEY .. " = false"

function M.cfg_path()
  return vim.fs.joinpath(vim.fn.stdpath "data", "mason/packages/python-lsp-server/venv/pyvenv.cfg")
end

--- Idempotently force include-system-site-packages = false.
--- @param path string? defaults to the mason pylsp venv
--- @return "ok"|"fixed"|"missing"
function M.ensure(path)
  path = path or M.cfg_path()

  if vim.fn.filereadable(path) ~= 1 then
    return "missing"
  end

  local lines = vim.fn.readfile(path)
  local changed, seen = false, false

  -- vim.pesc matters: the key contains '-', which is a quantifier in a Lua
  -- pattern, so an unescaped match never fires and every call appends a
  -- duplicate line instead of rewriting the existing one.
  local key_pat = "^%s*" .. vim.pesc(KEY) .. "%s*="

  for i, line in ipairs(lines) do
    if line:match(key_pat) then
      seen = true

      if not line:match "=%s*false%s*$" then
        lines[i], changed = WANT, true
      end
    end
  end

  if not seen then
    table.insert(lines, WANT)
    changed = true
  end

  if changed then
    vim.fn.writefile(lines, path)
  end

  return changed and "fixed" or "ok"
end

return M
