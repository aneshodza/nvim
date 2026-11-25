-- Overrides and extras only. NvChad's own spec (nvchad.plugins) already ships
-- plenary, base46, ui, web-devicons, indent-blankline, which-key, mason,
-- nvim-lspconfig, nvim-cmp + sources, telescope, nvim-tree, gitsigns, conform
-- and nvim-treesitter, so those are declared here purely to change opts.
--
-- Deliberately gone, not ported:
--   NvChad/nvterm          -> nvchad.term
--   numToStr/Comment.nvim  -> built-in commenting, mapped to <leader>/ upstream
--   NvChad/nvim-colorizer  -> ui's colorify, on by default

return {
  -------------------------------------------------- overrides
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      -- lazy replaces arrays rather than concatenating, so NvChad's own
      -- parsers have to be repeated here or they are dropped
      ensure_installed = {
        "lua",
        "luadoc",
        "printf",
        "vim",
        "vimdoc",

        "bash",
        "c",
        "c_sharp",
        "css",
        "dart",
        "go",
        "gomod",
        "html",
        "javascript",
        "json",
        "jsonnet",
        "markdown",
        "markdown_inline",
        "python",
        "ruby",
        "rust",
        "starlark",
        "tsx",
        "typescript",
        "yaml",
      },
    },

    branch = "main",
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "nvimtools/none-ls.nvim",
        name = "null-ls.nvim",
        dependencies = { "nvimtools/none-ls-extras.nvim" },
        config = function()
          require "configs.null-ls"
        end,
      },
    },
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    dependencies = { "zbirenbaum/copilot-cmp" },
    opts = function()
      return require "configs.cmp"
    end,
  },

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = function()
      return require "configs.conform"
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        -- Compiled sorter. Telescope's default is pure Lua, which is
        -- noticeably slower once a repo gets large. `make` needs a C compiler;
        -- if the build fails telescope falls back to the Lua sorter rather
        -- than breaking, and configs/telescope.lua only loads the extension
        -- when it is actually present.
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    opts = function()
      return require "configs.telescope"
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = function()
      return require "configs.nvimtree"
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "󰍵" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "│" },
      },
      -- GitLens-style inline blame at the end of the current line
      current_line_blame = true,
      current_line_blame_opts = { delay = 500 },
      current_line_blame_formatter = "<author>, <author_time:%R> • <summary>",
    },
  },

  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      return vim.tbl_deep_extend("force", opts, require "configs.whichkey")
    end,
  },

  {
    -- GitLens' history and compare views: file/line history, branch diffs and
    -- a three-way merge view for conflicts
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    opts = function()
      -- Closing a view runs :tabclose, which lands on the tab to the right, not
      -- the one the view was opened from. Remember that tab and go back to it.
      local origin = {}

      return {
        hooks = {
          view_opened = function(view)
            origin[view] = vim.api.nvim_list_tabpages()[vim.fn.tabpagenr "#"]
          end,
          view_closed = function(view)
            local tab = origin[view]
            origin[view] = nil

            if tab and vim.api.nvim_tabpage_is_valid(tab) then
              vim.schedule(function()
                if vim.api.nvim_tabpage_is_valid(tab) then
                  vim.api.nvim_set_current_tabpage(tab)
                end
              end)
            end
          end,
        },
      }
    end,
  },

  -------------------------------------------------- extras
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    opts = function()
      local files = {
        select_next_entry = { lhs = "<Tab>", desc = "move to next changed file" },
        select_prev_entry = { lhs = "<S-Tab>", desc = "move to previous changed file" },
      }

      return {
        gh_cmd = require("utils.mise").which "gh" or "gh",
        picker = "telescope",
        default_remote = { "upstream", "origin" },
        use_local_fs = true,
        mappings = {
          review_diff = vim.tbl_extend("force", files, {
            add_review_comment = { lhs = "<leader>oa", desc = "Octo add review comment", mode = { "n", "x" } },
            add_review_suggestion = { lhs = "<leader>oA", desc = "Octo add review suggestion", mode = { "n", "x" } },
            toggle_viewed = { lhs = "<leader>ov", desc = "Octo toggle file viewed" },
          }),
          file_panel = vim.tbl_extend("force", files, {
            toggle_viewed = { lhs = "<leader>ov", desc = "Octo toggle file viewed" },
          }),
          review_thread = files,
        },
      }
    end,
    config = function(_, opts)
      require("octo").setup(opts)

      local DiffEntry = require("octo.reviews.file-entry").FileEntry
      local show_diff = DiffEntry.show_diff

      function DiffEntry:show_diff()
        show_diff(self)

        for _, win in ipairs { self.left_winid, self.right_winid } do
          if win and vim.api.nvim_win_is_valid(win) then
            vim.wo[win].foldenable = false
          end
        end
      end

      local reviews = require "octo.reviews"
      local Layout = require("octo.reviews.layout").Layout
      local FileEntry = require("octo.reviews.file-entry").FileEntry
      local healing = false

      local function heal(layout)
        if healing then
          return
        end

        healing = true
        local ok, err = pcall(function()
          layout:ensure_layout()

          local file = layout:get_current_file()

          if file then
            file:load_buffers(layout.left_winid, layout.right_winid)
          end
        end)
        healing = false

        if not ok then
          vim.notify("octo: " .. tostring(err), vim.log.levels.ERROR)
        end
      end

      local octo = require "octo"
      local update_layout_for_current_file = octo.update_layout_for_current_file

      octo.update_layout_for_current_file = function()
        if healing or pcall(update_layout_for_current_file) then
          return
        end

        vim.schedule(function()
          local review = reviews.get_current_review()

          if review then
            heal(review.layout)
          end
        end)
      end

      local recover_layout = Layout.recover_layout

      function Layout:recover_layout(state)
        if not pcall(recover_layout, self, state) then
          vim.schedule(function()
            heal(self)
          end)
        end
      end

      for _, name in ipairs { "get_win", "get_alternative_win" } do
        local original = FileEntry[name]

        FileEntry[name] = function(self, split)
          local review = reviews.get_current_review()
          local stale = not (
            self.left_winid
            and self.right_winid
            and vim.api.nvim_win_is_valid(self.left_winid)
            and vim.api.nvim_win_is_valid(self.right_winid)
          )

          if stale and review and review.layout:get_current_file() == self then
            heal(review.layout)
          end

          return original(self, split)
        end
      end
    end,
  },

  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    ft = { "rust" },
    init = function()
      -- rustaceanvim reads this global; it must be set before the plugin loads
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              -- checkOnSave is a boolean; the command moved to check.command.
              -- The old `checkOnSave = { command = "clippy" }` made
              -- rust-analyzer log "invalid type: map, expected a boolean" and
              -- fall back to cargo check, so clippy-on-save was never running.
              checkOnSave = true,
              check = { command = "clippy" },
            },
          },
        },
      }
    end,
  },

  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },

  {
    "lervag/vimtex",
    -- master hard-requires nvim 0.12.4 and aborts its ftplugin otherwise, which
    -- also breaks the FileType chain. v2.18 is the last release that supports
    -- 0.10+. Drop this pin once Neovim is upgraded.
    version = "v2.18",
    ft = { "tex" },
    init = function()
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = { continuous = 1 }
    end,
  },

  {
    "akinsho/flutter-tools.nvim",
    ft = { "dart" },
    config = true,
  },

  {
    -- Owns vim.ui.select and vim.ui.input. Without it both fall back to the
    -- command-line prompt, which is what code actions render as.
    --
    -- This used to come in as a dressing.nvim dependency of flutter-tools,
    -- which only worked because flutter-tools was eagerly loaded; dressing is
    -- archived upstream in favour of this.
    --
    -- lazy = false on purpose: it has to be in place before anything calls
    -- vim.ui.select, and priority puts it ahead of other eager plugins.
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      -- picker.ui_select defaults to true, which is what replaces vim.ui.select.
      -- telescope stays the driver for the <leader>f pickers.
      picker = { enabled = true },
      input = { enabled = true },
    },
  },

  {
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- eager on purpose: besides the commands it installs a BufNewFile autocmd
  -- that chmod +x files with a shebang, which cmd-lazy loading would lose
  { "tpope/vim-eunuch", lazy = false },

  {
    -- Neovim's built-in commenting covers gc/gcc (and NvChad maps <leader>/),
    -- but there is no built-in blockwise equivalent, so this stays purely for
    -- gb/gbc.
    "numToStr/Comment.nvim",
    keys = {
      { "gbc", mode = "n", desc = "Comment toggle current block" },
      { "gb", mode = { "n", "o" }, desc = "Comment toggle blockwise" },
      { "gb", mode = "x", desc = "Comment toggle blockwise (visual)" },
    },
    opts = {},
  },

  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup {}
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    init = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_page_title = "${name}"
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_theme = "light"
    end,
  },

  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    opts = {
      -- copilot-cmp requires both of these off, otherwise ghost text and the
      -- completion menu fight over the same suggestions
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
  },

  {
    "zbirenbaum/copilot-cmp",
    config = function()
      require("copilot_cmp").setup()
    end,
  },

  {
    "stevearc/aerial.nvim",
    -- master requires nvim 0.12 and warns loudly on anything older. Drop this
    -- pin once Neovim is upgraded.
    branch = "nvim-0.11",
    cmd = { "AerialToggle" },
    opts = {
      layout = { default_direction = "right", min_width = 30 },
      attach_mode = "global",
    },
  },

  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = { signs = true },
  },
}
