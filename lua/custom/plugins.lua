local os_check = require "custom.os_check"
local overrides = require "custom.configs.overrides"
---@type NvPluginSpec[]
local plugins = {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "nvimtools/none-ls.nvim",
        name = "null-ls.nvim",
        config = function()
          require "custom.configs.null-ls"
        end,
      },
    },
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
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
    "simrat39/rust-tools.nvim",
    requires = {
      "nvim-lua/popup.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "mfussenegger/nvim-dap",
    },
    ft = { "rust" },
    config = function()
      require("rust-tools").setup {}
    end,
    lazy = false,
  },

  {
    "mfussenegger/nvim-dap",
  },

  {
    "tpope/vim-rails",
  },

  {
    "tpope/vim-surround",
  },

  {
    "williamboman/mason.nvim",
    opts = overrides.mason,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
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
    ft = { "tex" },
  },

  {
    "akinsho/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- optional for vim.ui.select
    },
    config = true,
  },

  {
    "nvim-pack/nvim-spectre",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },

  {
    "tpope/vim-eunuch",
    lazy = false,
  },

  -- TODO: Try to get java to work in nvim
  -- {
  --   "mfussenegger/nvim-jdtls",
  --   ft = { "java" },
  -- },
}

if not os_check.is_fedora() then
  table.insert(plugins, {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    opts = overrides.copilot,
  })

  table.insert(plugins, {
    "hrsh7th/nvim-cmp",
    dependencies = {
      {
        "zbirenbaum/copilot-cmp",
        config = function()
          require("copilot_cmp").setup()
        end,
      },
    },
    opts = overrides.cmp,
  })
end

return plugins
