require "nvchad.autocmds"

local autocmd = vim.api.nvim_create_autocmd
local new_cmd = vim.api.nvim_create_user_command

-- don't list quickfix buffers
autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.opt_local.buflisted = false
  end,
})

-- vimtex is ft-gated, so its mapping has to be too
autocmd("FileType", {
  pattern = "tex",
  callback = function(args)
    vim.keymap.set("n", "<leader>lp", "<cmd>VimtexCompile<CR>", {
      buffer = args.buf,
      desc = "LaTeX compile",
    })
  end,
})

new_cmd("DuplicateKeybinds", function()
  require("utils.keymaps").report()
end, { desc = "List colliding keybinds for this buffer" })

new_cmd("Q", "wqa <args>", { nargs = "*" })
new_cmd("S", "suspend", { nargs = "*" })
new_cmd("T", "NvimTreeToggle <args>", { nargs = "*" })
new_cmd("C", "NvimTreeCollapse <args>", { nargs = "*" })

-- Startup time, once the UI has settled. VeryLazy fires just after UIEnter,
-- which is when lazy.nvim finishes computing stats.startuptime.
local startup = require "utils.startup"

startup.set_highlights()

autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    vim.schedule(startup.report)
  end,
})

autocmd("ColorScheme", {
  callback = startup.set_highlights,
})

-- Large files: skip the expensive machinery. Treesitter parsing and LSP
-- attachment on a multi-megabyte log or a minified bundle will hang the editor
-- for seconds. NvChad starts treesitter from a FileType autocmd and vim.lsp
-- starts clients the same way, so clearing the filetype prevents both.
local large_file = 1024 * 1024 -- 1 MB

autocmd("BufReadPre", {
  callback = function(args)
    local ok, stat = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))

    if not ok or not stat or stat.size <= large_file then
      return
    end

    vim.b[args.buf].large_file = true
    vim.b[args.buf].disable_autoformat = true

    vim.opt_local.foldmethod = "manual"
    vim.opt_local.spell = false
    vim.opt_local.undofile = false

    -- after the buffer loads, or filetype detection re-sets it
    autocmd("BufReadPost", {
      buffer = args.buf,
      once = true,
      callback = function()
        vim.bo[args.buf].filetype = ""
        vim.notify(
          ("Large file (%.1f MB): treesitter, LSP and format-on-save disabled"):format(stat.size / 1024 / 1024),
          vim.log.levels.WARN
        )
      end,
    })
  end,
})
