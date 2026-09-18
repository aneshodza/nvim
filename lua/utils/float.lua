-- Read-only scratch float, shared by the <leader>uv tools and
-- :DuplicateKeybinds.

local M = {}

--- @param title string
--- @param lines string[]
function M.open(title, lines)
  if #lines == 0 then
    lines = { "(nothing to show)" }
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "nvfloat"

  local width = 0

  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  width = math.min(math.max(width + 4, 46), vim.o.columns - 8)
  local height = math.min(math.max(#lines, 3), vim.o.lines - 8)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })

  vim.wo[win].wrap = false

  for _, key in ipairs { "q", "<Esc>" } do
    vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, nowait = true })
  end

  return buf, win
end

return M
