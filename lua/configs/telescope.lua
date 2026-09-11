-- Delta over nvchad.configs.telescope, which already sets prompt_prefix,
-- sorting_strategy, the horizontal layout, the `q` mapping and extensions_list
-- (so the extension-loading loop that used to live here is gone too).
--
-- Dropped as redundant: file_sorter, generic_sorter and buffer_previewer_maker
-- were all explicitly set to telescope's own defaults.

return vim.tbl_deep_extend("force", require "nvchad.configs.telescope", {
  defaults = {
    vimgrep_arguments = {
      "rg",
      "-L",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
    },

    selection_caret = "  ",
    entry_prefix = "  ",
    initial_mode = "insert",
    selection_strategy = "reset",
    layout_strategy = "horizontal",

    layout_config = {
      horizontal = { results_width = 0.8 },
      vertical = { mirror = false },
      preview_cutoff = 120,
    },

    file_ignore_patterns = { "node_modules" },
    path_display = { "truncate" },
    winblend = 0,
    border = {},
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
    color_devicons = true,
    set_env = { COLORTERM = "truecolor" },
    preview = { treesitter = true },
  },
})
