local M = {}

--- Working directory of whatever runs in the terminal: the deepest child of the
--- shell (e.g. claude), else the shell, else the directory in the term:// name.
--- Relative paths printed by the program are relative to that, not to nvim's cwd.
--- @param bufnr integer
--- @return string?
local function job_cwd(bufnr)
  local pid = vim.b[bufnr].terminal_job_pid

  while pid do
    local children = vim.api.nvim_get_proc_children(pid)

    if #children == 0 then
      break
    end

    pid = children[#children]
  end

  if pid then
    local out = vim.fn.system { "lsof", "-a", "-d", "cwd", "-p", tostring(pid), "-Fn" }
    local cwd = out:match "\nn(/[^\n]+)"

    if cwd then
      return cwd
    end
  end

  local dir = vim.api.nvim_buf_get_name(bufnr):match "^term://(.-)//"
  return dir and vim.fn.expand(dir) or nil
end

--- First changed line of the diff Claude Code prints under `Update(path)`:
---       5 -from fastapi import Depends
---       5 +from fastapi import Depends, HTTPException, status
--- The numbers before the first change are the same in the old and new file,
--- so a `-` line is as good as a `+` one. Stops at the next `⏺` message or `>`
--- prompt so a later tool call's diff is never picked up.
--- @param bufnr integer
--- @param row integer 1-based row of the path
--- @return string?
local function diff_line(bufnr, row)
  for _, text in ipairs(vim.api.nvim_buf_get_lines(bufnr, row, row + 60, false)) do
    local trimmed = vim.trim(text)

    if vim.startswith(trimmed, "⏺") or vim.startswith(trimmed, ">") then
      return nil
    end

    local line = trimmed:match "^(%d+) [-+]"

    if line then
      return line
    end
  end
end

--- Open the path under the cursor of a terminal buffer in the window you came
--- from, so the terminal split stays put. Understands `path:line`,
--- `path:line:col` and the diff Claude Code prints below an edit.
function M.open_path()
  local bufnr = vim.api.nvim_get_current_buf()
  local word = vim.fn.expand "<cWORD>"
  local file = vim.fn.expand "<cfile>"
  local cwd = job_cwd(bufnr)

  -- A terminal hard-wraps long lines with no marker, so a path ending at the
  -- right edge may continue at the start of the next line.
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local next_line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  local continuation = next_line:match "^[%w%._/%-]+" or ""
  local tail = next_line:match "^[%w%._/%-]+(:%d+)" or ""

  local path, line

  for _, name in ipairs { file, file .. continuation } do
    local candidates = { name }

    if cwd and not vim.startswith(name, "/") then
      table.insert(candidates, 1, vim.fs.joinpath(cwd, name))
    end

    for _, candidate in ipairs(candidates) do
      if not path and vim.fn.filereadable(candidate) == 1 then
        path = candidate
        line = name == file and word:match(vim.pesc(file) .. ":(%d+)") or tail:match "%d+"
      end
    end
  end

  if not path then
    vim.notify(("No file %s (looked in %s)"):format(file, cwd or vim.fn.getcwd()), vim.log.levels.WARN)
    return
  end

  line = line or diff_line(bufnr, row)

  -- the previous window unless it is a terminal too, else a fresh split
  vim.cmd "wincmd p"

  if vim.bo.buftype == "terminal" or vim.api.nvim_get_current_buf() == bufnr then
    vim.cmd "aboveleft new"

    -- a split copies the terminal window's options, and the terminal has
    -- line numbers off
    vim.wo.number = vim.go.number
    vim.wo.relativenumber = vim.go.relativenumber
  end

  vim.cmd.edit(vim.fn.fnameescape(path))

  if line then
    vim.api.nvim_win_set_cursor(0, { math.min(tonumber(line), vim.api.nvim_buf_line_count(0)), 0 })
  end
end

local function runs_claude(pid, depth)
  local proc = vim.api.nvim_get_proc(pid)

  if proc and proc.name == "claude" then
    return true
  end

  if depth == 0 then
    return false
  end

  for _, child in ipairs(vim.api.nvim_get_proc_children(pid)) do
    if runs_claude(child, depth - 1) then
      return true
    end
  end

  return false
end

function M.latest_claude_buf()
  local best

  for _, info in ipairs(vim.fn.getbufinfo()) do
    local pid = vim.b[info.bufnr].terminal_job_pid

    if pid and (not best or info.lastused > best.lastused) and runs_claude(pid, 2) then
      best = info
    end
  end

  return best and best.bufnr
end

function M.show_claude_split()
  local buf = M.latest_claude_buf()

  if not buf then
    return
  end

  local prev = vim.api.nvim_get_current_win()
  local shown = vim.fn.win_findbuf(buf)[1]
  local width = shown and vim.api.nvim_win_get_width(shown) or math.floor(vim.o.columns / 3)

  vim.cmd "botright vsplit"

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_width(win, width)

  vim.wo[win].winfixwidth = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  vim.api.nvim_set_current_win(prev)
end

return M
