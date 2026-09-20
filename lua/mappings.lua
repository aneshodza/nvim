require "nvchad.mappings"

local map = vim.keymap.set

-- IMPORTANT: everything below must stay AFTER the require above. <leader>h and
-- <leader>v deliberately shadow NvChad's defaults (which open terminals) to
-- keep them as window splits. Move that require down the file and they
-- silently become terminal-openers.
--
-- Dropped here because NvChad already maps them identically: <C-h/j/k/l> in
-- both normal and insert, <Esc> noh, <C-s>, <C-c>, <leader>n, <leader>rn,
-- <leader>b, <leader>ch, <leader>fm, <leader>ff/fw/fb/fh/fo/fz/cm/gt/ma/th,
-- <leader>wk/wK, <leader>x, <tab>/<S-tab>, t <C-x>.

-- general -------------------------------------------------------------------
map(
  "n",
  "<leader>rp",
  ":lua local search = vim.fn.input('Search for: '); local replace = vim.fn.input('Replace with: '); vim.fn.feedkeys(':%s#' .. search .. '#' .. replace .. '#gi')<CR>",
  { desc = "Replace word in buffer" }
)

map("n", "<leader>rhm", "<cmd>horizontal resize +10<CR>", { desc = "Window resize horizontal +10" })
map("n", "<leader>rhl", "<cmd>horizontal resize -10<CR>", { desc = "Window resize horizontal -10" })
map("n", "<leader>rhs", "<cmd>horizontal resize 15<CR>", { desc = "Window resize horizontal small" })
map("n", "<leader>rhc", "<cmd>horizontal resize ", { desc = "Window resize horizontal custom" })

map("n", "<leader>rvm", "<cmd>vertical resize +10<CR>", { desc = "Window resize vertical +10" })
map("n", "<leader>rvl", "<cmd>vertical resize -10<CR>", { desc = "Window resize vertical -10" })
map("n", "<leader>rvs", "<cmd>vertical resize 15<CR>", { desc = "Window resize vertical small" })
map("n", "<leader>rvc", "<cmd>vertical resize ", { desc = "Window resize vertical custom" })

map("n", "<leader>sh", "<cmd>split<CR>", { desc = "Window split horizontal" })
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Window split vertical" })
map("n", "<leader>h", "<cmd>split<CR>", { desc = "Window split horizontal" })
map("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "Window split vertical" })

map("n", "<C-Up>", ":m .-2<CR>==", { desc = "Move line up" })
map("n", "<C-Down>", ":m .+1<CR>==", { desc = "Move line down" })

-- move through wrapped lines, but not in operator-pending mode so d/y/c are unaffected
local wrapped = { expr = true }
map("n", "j", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', vim.tbl_extend("force", wrapped, { desc = "Move down" }))
map("n", "k", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', vim.tbl_extend("force", wrapped, { desc = "Move up" }))
map(
  "n",
  "<Down>",
  'v:count || mode(1)[0:1] == "no" ? "j" : "gj"',
  vim.tbl_extend("force", wrapped, { desc = "Move down" })
)
map("n", "<Up>", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', vim.tbl_extend("force", wrapped, { desc = "Move up" }))
map(
  "v",
  "<Down>",
  'v:count || mode(1)[0:1] == "no" ? "j" : "gj"',
  vim.tbl_extend("force", wrapped, { desc = "Move down" })
)
map("v", "<Up>", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', vim.tbl_extend("force", wrapped, { desc = "Move up" }))
map("x", "j", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', vim.tbl_extend("force", wrapped, { desc = "Move down" }))
map("x", "k", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', vim.tbl_extend("force", wrapped, { desc = "Move up" }))

map("x", "p", 'p:let @+=@0<CR>:let @"=@0<CR>', { silent = true, desc = "Dont copy replaced text" })
map("x", "<C-Up>", ":move '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
map("x", "<C-Down>", ":move '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })

map(
  "n",
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "Telescope find all" }
)
map("n", "<leader>ft", "<cmd>TodoTelescope<CR>", { desc = "Telescope find todos" })

map("n", "<leader>fd", function()
  require("utils.folders").pick()
end, { desc = "Telescope find directory" })

map("n", "<leader>tf", function()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  vim.notify("Format on save " .. (vim.g.disable_autoformat and "disabled" or "enabled"))
end, { desc = "Toggle format on save" })

map("n", "<leader>de", require("utils.quickfix").dotnet_build, { desc = "Quickfix dotnet build errors" })
map("n", "<leader>gc", require("utils.quickfix").git_conflicts, { desc = "Quickfix git conflict markers" })

-- terminals -----------------------------------------------------------------
-- <A-i>/<A-h>/<A-v> toggles come from NvChad. These open *new* terminals, and
-- moved off <leader>th (which is NvChad's theme picker) and <leader>h.
map("n", "<leader>ts", function()
  require("nvchad.term").new { pos = "sp" }
end, { desc = "Terminal new horizontal" })

map("n", "<leader>tv", function()
  require("nvchad.term").new { pos = "vsp" }
end, { desc = "Terminal new vertical" })

-- plugins -------------------------------------------------------------------
map("n", "<leader>mp", "<cmd>MarkdownPreview<CR>", { desc = "Markdown preview" })
map("n", "<leader>sa", "<cmd>AerialToggle right<CR>", { desc = "Aerial symbols outline" })
map("n", "<leader>sr", "<cmd>Spectre<CR>", { desc = "Search and replace in project" })
map("n", "<leader>sw", "ysiw", { remap = true, desc = "Surround word" })
map("n", "<leader>sl", "yss", { remap = true, desc = "Surround line" })

-- gitsigns ------------------------------------------------------------------
map("n", "]c", function()
  if vim.wo.diff then
    return "]c"
  end
  vim.schedule(function()
    require("gitsigns").next_hunk()
  end)
  return "<Ignore>"
end, { expr = true, desc = "Git next hunk" })

map("n", "[c", function()
  if vim.wo.diff then
    return "[c"
  end
  vim.schedule(function()
    require("gitsigns").prev_hunk()
  end)
  return "<Ignore>"
end, { expr = true, desc = "Git prev hunk" })

-- <leader>gr, not <leader>rh: the latter is a prefix of <leader>rhm/rhl/rhs/rhc
-- (the resizes), so every press stalled for timeoutlen before resolving.
map("n", "<leader>gr", function()
  require("gitsigns").reset_hunk()
end, { desc = "Git reset hunk" })

map("n", "<leader>gp", function()
  require("gitsigns").preview_hunk()
end, { desc = "Git preview hunk" })

-- was package.loaded.gitsigns.blame_line(), which nil-indexes before gitsigns loads
map("n", "<leader>gb", function()
  require("gitsigns").blame_line()
end, { desc = "Git blame line" })

-- moved off <leader>td, which collided with TodoTelescope
map("n", "<leader>gD", function()
  require("gitsigns").toggle_deleted()
end, { desc = "Git toggle deleted" })

-- uv ------------------------------------------------------------------------
-- Required lazily, so a session that never touches a uv project never loads it.
for _, entry in ipairs {
  { "d", "deps", "Uv direct dependencies" },
  { "p", "env", "Uv environment and interpreter" },
  { "y", "sync", "Uv sync and restart LSP" },
  { "a", "audit", "Uv audit for vulnerabilities" },
  { "t", "tree", "Uv dependency tree" },
} do
  local key, fn, desc = entry[1], entry[2], entry[3]

  map("n", "<leader>uv" .. key, function()
    require("utils.uv")[fn]()
  end, { desc = desc })
end

-- diagnostics ---------------------------------------------------------------
-- global rather than buffer-local: vim.diagnostic works with no client attached
map("n", "<leader>df", function()
  vim.diagnostic.open_float { border = "rounded" }
end, { desc = "Diagnostic float" })

map("n", "<leader>dp", function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = "Diagnostic prev" })

map("n", "<leader>dn", function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = "Diagnostic next" })

map("n", "<leader>dc", function()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })

  if #diagnostics == 0 then
    vim.notify "No diagnostics under cursor"
    return
  end

  local messages = vim.tbl_map(function(d)
    return d.message
  end, diagnostics)

  vim.fn.setreg("+", table.concat(messages, "\n"))
  vim.notify("Copied " .. #diagnostics .. " diagnostic(s)")
end, { desc = "Diagnostic copy to clipboard" })

map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostic loclist" })

-- required lazily: configs.diagnostics applies its config on first require, and
-- it must land after nvchad.configs.lspconfig.defaults() rather than at startup
map("n", "<leader>dv", function()
  require("configs.diagnostics").toggle_virtual_lines()
end, { desc = "Diagnostic toggle virtual lines" })

map("n", "<leader>dh", function()
  local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = 0 }
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
  vim.notify("Inlay hints " .. (enabled and "off" or "on"))
end, { desc = "Diagnostic toggle inlay hints" })

-- lsp -----------------------------------------------------------------------
-- Buffer-local, so these replace the old M.lspconfig section. K is deliberately
-- absent: nvim 0.11 maps it to hover on attach, but only when nothing else has
-- claimed it. gd/gD are NOT nvim defaults (only grn/gra/grr/gri are), so they
-- stay here.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspMappings", { clear = true }),
  callback = function(args)
    local function opts(desc)
      return { buffer = args.buf, desc = desc }
    end

    map("n", "gd", vim.lsp.buf.definition, opts "LSP definition")
    map("n", "gD", vim.lsp.buf.declaration, opts "LSP declaration")
    map("n", "<leader>gd", vim.lsp.buf.definition, opts "LSP definition (leader)")
    map("n", "<leader>gi", vim.lsp.buf.implementation, opts "LSP implementation")
    map("n", "<leader>D", vim.lsp.buf.type_definition, opts "LSP type definition")
    map("n", "<leader>ls", vim.lsp.buf.signature_help, opts "LSP signature help")

    -- No <leader>ra here: nvchad.configs.lspconfig already binds it to its own
    -- renamer popup, and its LspAttach runs after this one so it would win
    -- anyway. grn is Neovim's built-in rename.

    map("n", "<leader>rf", function()
      require("telescope.builtin").lsp_references()
    end, opts "LSP references")

    map("n", "<leader>fi", require("utils.lsp").code_action, opts "LSP code action / autofix")

    map("n", "<leader>cl", vim.lsp.codelens.run, opts "LSP run codelens")
    map("n", "<leader>cL", vim.lsp.codelens.refresh, opts "LSP refresh codelens")
  end,
})
