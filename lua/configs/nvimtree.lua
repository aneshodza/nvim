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

  -- Every expanded directory gets a watcher, and on macOS stopping one blocks
  -- the UI until the FSEvents thread acknowledges it. Expanding Bazel's output
  -- (bazel-bin resolves into ~/Library/Caches/bazel) left 1,800 watchers on
  -- vendored site-packages, and each rebuild of the symlink froze nvim for
  -- ~30 s while they were torn down. Paths are matched after symlinks resolve.
  -- This replaces nvim-tree's defaults, so they are repeated first.
  filesystem_watchers = {
    ignore_dirs = {
      "/.ccls-cache",
      "/build",
      "/node_modules",
      "/target",
      "/.zig-cache",
      "/bazel-",
      "/_bazel_",
      "/\\.venv",
      "/site-packages",
      "/__pycache__",
      "/\\.\\(mypy\\|ruff\\|pytest\\)_cache",
      "/\\.next",
    },
  },

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
