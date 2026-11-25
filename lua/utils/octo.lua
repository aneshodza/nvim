local M = {}

local function submit(review, path, body, on_done)
  local gh = require "octo.gh"
  local mutations = require "octo.gh.mutations"

  gh.api.graphql {
    query = mutations.add_pull_request_review_thread,
    F = {
      input = {
        pullRequestReviewId = review.id,
        path = path,
        body = body,
        subjectType = "FILE",
      },
    },
    opts = {
      cb = gh.create_callback {
        failure = function(err)
          vim.notify("octo: file comment failed: " .. tostring(err), vim.log.levels.ERROR)
        end,
        success = function()
          vim.notify("octo: file comment added to " .. path .. " (pending until you submit the review)")
          on_done()
        end,
      },
    },
  }
end

function M.file_comment()
  local review = require("octo.reviews").get_current_review()

  if not review then
    vim.notify("octo: no review in this tab", vim.log.levels.WARN)
    return
  end

  if review.id == -1 then
    vim.notify("octo: start or resume a review first", vim.log.levels.WARN)
    return
  end

  local file = review.layout:get_current_file()

  if not file then
    vim.notify("octo: no file selected in the review", vim.log.levels.WARN)
    return
  end

  local path = file.path
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_name(buf, "octo-file-comment://" .. path)
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"

  local width = math.min(90, vim.o.columns - 8)
  local height = math.min(12, vim.o.lines - 8)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " Comment on " .. path .. " ",
    title_pos = "center",
    footer = " :w post · q cancel ",
    footer_pos = "center",
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local body = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))

      if body == "" then
        vim.notify("octo: empty comment, nothing posted", vim.log.levels.WARN)
        return
      end

      vim.bo[buf].modified = false
      submit(review, path, body, function()
        vim.schedule(close)
      end)
    end,
  })

  vim.keymap.set("n", "q", close, { buffer = buf, desc = "Cancel file comment" })
  vim.cmd "startinsert"
end

function M.find_file()
  local review = require("octo.reviews").get_current_review()

  if not review then
    vim.notify("octo: no review in this tab", vim.log.levels.WARN)
    return
  end

  local layout = review.layout
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  pickers
    .new({}, {
      prompt_title = "Changed files",
      finder = finders.new_table {
        results = layout.files,
        entry_maker = function(file)
          local display = string.format("%s %s", (file.status or "?"):sub(1, 1), file.path)

          return { value = file, display = display, ordinal = file.path }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if entry then
            layout:set_current_file(entry.value)
          end
        end)

        return true
      end,
    })
    :find()
end

return M
