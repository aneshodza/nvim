require "core"

local custom_init_path = vim.api.nvim_get_runtime_file("lua/custom/init.lua", false)[1]

if custom_init_path then
  dofile(custom_init_path)
end

require("core.utils").load_mappings()

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

-- bootstrap lazy.nvim!
if not vim.loop.fs_stat(lazypath) then
  require("core.bootstrap").gen_chadrc_template()
  require("core.bootstrap").lazy(lazypath)
end

dofile(vim.g.base46_cache .. "defaults")
vim.opt.rtp:prepend(lazypath)
require "plugins"

-- Add Q shortcut to quit all
vim.cmd('command! -nargs=* Q wqa <args>')

-- Add T shortcut to toggle Filetree
vim.cmd('command! -nargs=* T NvimTreeToggle <args>')

-- Set language to English
vim.o.langmenu = 'en_US.UTF-8'
vim.cmd('language messages en_US.UTF-8')

-- Set environment variables
vim.env.LANG = 'en_US.UTF-8'
vim.env.LC_ALL = 'en_US.UTF-8'
vim.opt.guicursor = ""
vim.opt.encoding = "UTF-8"
