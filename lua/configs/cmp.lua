local cmp = require "cmp"
local opts = require "nvchad.configs.cmp"

-- The window/border/formatting blocks that used to live here are all supplied
-- by nvchad.configs.cmp + nvchad.cmp now, driven by chadrc's ui.cmp.

opts.sources = {
  { name = "copilot" },
  { name = "nvim_lsp" },
  { name = "luasnip" },
  { name = "buffer" },
  { name = "nvim_lua" },
  -- NvChad v2.5 swapped cmp-path for async_path
  { name = "async_path" },
}

-- Keep <Tab>/<S-Tab>/<CR> as literal keys and confirm only on <C-Right>/<C-Enter>.
--
-- This matches what the v2.0 config actually did, though not what it looked
-- like it did: those mappings were guarded on `vim.fn.pumvisible()`, which is
-- always 0 because nvim-cmp draws its own float rather than the built-in popup
-- menu, and on a `cmp_active` flag that was only ever set from a `config.event`
-- table nvim-cmp does not read. So both branches were dead and the keys always
-- fell through. NvChad maps all three to cmp actions, so they must be
-- explicitly reclaimed here. Delete this block to adopt NvChad's behaviour.
opts.mapping["<Tab>"] = nil
opts.mapping["<S-Tab>"] = nil
opts.mapping["<CR>"] = nil

local confirm = cmp.mapping.confirm {
  behavior = cmp.ConfirmBehavior.Insert,
  select = true,
}

opts.mapping["<C-Right>"] = confirm
opts.mapping["<C-Enter>"] = confirm
opts.mapping["<Down>"] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Select }
opts.mapping["<Up>"] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Select }

return opts
