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
        "html",
        "javascript",
        "json",
        "latex",
        "markdown",
        "markdown_inline",
        "python",
        "ruby",
        "rust",
        "tsx",
        "typescript",
        "yaml",
      },
    },
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
    },
  },

  -------------------------------------------------- extras
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
              checkOnSave = { command = "clippy" },
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
    dependencies = { "stevearc/dressing.nvim" },
    config = true,
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
