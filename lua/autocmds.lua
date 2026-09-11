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

new_cmd("Q", "wqa <args>", { nargs = "*" })
new_cmd("S", "suspend", { nargs = "*" })
new_cmd("T", "NvimTreeToggle <args>", { nargs = "*" })
new_cmd("C", "NvimTreeCollapse <args>", { nargs = "*" })
