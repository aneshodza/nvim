local opt = vim.opt
local api = vim.api
local cmd = vim.cmd
local g = vim.g

cmd('command! -nargs=* Q wqa <args>')
cmd('command! -nargs=* T NvimTreeToggle <args>')
cmd('command! -nargs=* F Telescope find_files <args>')
cmd('command! -nargs=* FA Telescope find_files hidden=true <args>') -- This finds ignored stuff too
cmd('command! -nargs=* FF Telescope live_grep <args>')
cmd('command! -nargs=* B Telescope buffers <args>')
cmd('command! -nargs=* GB Telescope git_branches <args>')

-- This opens file tree if no file is specified
-- vim.cmd([[
--   autocmd StdinReadPre * let s:std_in=1
--   autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NvimTreeToggle | endif
-- ]])

opt.guicursor = ""
opt.encoding = "UTF-8"

-- lsp stuff
cmd('command! -nargs=* Rn lua vim.lsp.buf.rename() <args>')
cmd('command! -nargs=* Fm lua vim.lsp.buf.format() <args>')
cmd('command! -nargs=* Fi lua vim.lsp.buf.code_action() <args>')
-- g.steep_path = "~/Steepfile"

-- markdown previewer
g.mkdp_auto_start = 0
g.mkdp_auto_close = 0
g.mkdp_page_title = '${name}'
g.mkdp_refresh_slow = 0
g.mkdp_theme = 'light'

-- Vimtex configuration
cmd [[
    " Vimtex options here. For example:
    let g:vimtex_quickfix_mode=0
    let g:vimtex_fold_enabled=0
    let g:vimtex_compiler_progname = 'nvr'
]]

-- Set language to English
vim.o.langmenu = 'en_US.UTF-8'
vim.cmd('language messages en_US.UTF-8')

-- Set environment variables
vim.env.LANG = 'en_US.UTF-8'
vim.env.LC_ALL = 'en_US.UTF-8'
