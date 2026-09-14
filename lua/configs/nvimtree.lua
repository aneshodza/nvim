-- Delta over nvchad.configs.nvimtree.
--
-- Dropped as redundant (these restated nvim-tree's own defaults): hijack_netrw,
-- hijack_unnamed_buffer_when_opening, view.adaptive_size, view.side,
-- git.enable, filesystem_watchers.enable, actions.open_file.resize_window,
-- renderer.highlight_opened_files, renderer.icons.show.*.
--
-- Also dropped: filters.exclude pointed at lua/custom, which no longer exists.

return vim.tbl_deep_extend("force", require "nvchad.configs.nvimtree", {
  -- show gitignored files (nvim-tree hides them by default)
  git = { ignore = false },

  -- NvChad turns these on
  renderer = {
    indent_markers = { enable = false },

    icons = {
      glyphs = {
        symlink = "",
        folder = {
          symlink_open = "",
          arrow_open = "",
          arrow_closed = "",
        },
        git = {
          unstaged = "✗",
          staged = "✓",
          unmerged = "",
          renamed = "➜",
          untracked = "★",
          deleted = "",
          ignored = "◌",
        },
      },
    },
  },
})
