---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
["<leader>rp"] = {
      ":lua local search = vim.fn.input('Search for: '); local replace = vim.fn.input('Replace with: '); vim.fn.feedkeys(':%s#' .. search .. '#' .. replace .. '#gi')<CR>",
      "Replace word"
    },

    -- split
    ["<leader>sh"] = { "<cmd>split<CR>", "Split horizontal" },
    ["<leader>sv"] = { "<cmd>vsplit<CR>", "Split vertical" },

    -- resize
    ['<leader>rhm'] = { "<cmd>horizontal resize +10<CR>", "Resize horizontal +10" },
    ['<leader>rhl'] = { "<cmd>horizontal resize -10<CR>", "Resize horizontal -10" },
    ['<leader>rhs'] = { "<cmd>horizontal resize 15<CR>", "Resize horizontal to be small (15)" },
    ['<leader>rhc'] = { "<cmd>horizontal resize ", "Resize horizontal custom" },

    ['<leader>rvm'] = { "<cmd>vertical resize +10<CR>", "Resize vertical +10" },
    ['<leader>rvl'] = { "<cmd>vertical resize -10<CR>", "Resize vertical -10" },
    ['<leader>rvs'] = { "<cmd>vertical resize 15<CR>", "Resize vertical to be small (15)" },
    ['<leader>rvc'] = { "<cmd>vertical resize ", "Resize vertical custom" },

    -- lsp-keybinds
    ["K"] = { "<cmd>lua vim.lsp.buf.hover()<CR>", "Show hover" },
    ["<leader>fm"] = { "<cmd>lua vim.lsp.buf.format()<CR>", "Format" },
    ["<leader>rn"] = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename" },
    ["<leader>fi"] = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Autofix" },
    ["<leader>gi"] = { "<cmd>lua vim.lsp.buf.implementation()<CR>", "Go to implementation" },
    ["<leader>gd"] = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Go to definition" },

    -- vimtex stuff
    ["<leader>lc"] = { ":VimtexCompile<CR>", "Compile latex document" },
    ["<leader>lo"] = { ":VimtexView<CR>", "View latex output" },
    ["<leader>ll"] = { ":copen<CR>", "Open latex compiler output"},

    -- markdown
    ["<leader>mp"] = { ":MarkdownPreview<CR>", "Preview markdown" },

    -- surround
    ["<leader>sw"] = { ":lua local char = vim.fn.input('Enter surround symbol: '); vim.fn.feedkeys('ysiw' .. char .. '<CR>')<CR>", "Surround word" },
    ["<leader>sl"] = { ":lua local char = vim.fn.input('Enter surround symbol: '); vim.fn.feedkeys('yss' .. char .. '<CR>')<CR>", "Surround line" },

    -- spectre
    ['<leader>St'] = { "<cmd>lua require(\"spectre\").toggle()<CR>", "Toggle Spectre" },
    ['<leader>Sw'] = { "<cmd>lua require(\"spectre\").open_visual({select_word=true})<CR>", "Search current word" },
    ['<leader>Sf'] = { "<cmd>lua require(\"spectre\").open_file_search({select_word=true})<CR>", "Search on current file" },
    -- dap
    ["<leader>dt"] = { ":lua require'dap'.toggle_breakpoint()<CR>", 'Toggle breakpoint'}


  },

  i = {
    ["<Tab>"] = { "<Tab>", "insert a tab character" },
  },
  
  v = {
    ['<leader>Sw'] = { "<esc><cmd>lua require(\"spectre\").open_visual()<CR>", "Search current word" },
  }
}

return M
