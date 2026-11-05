local M = {}

-- No LSP request does this: definition and declaration both jump into the
-- imported module rather than to the line that imports it.
local import_nodes = {
  python = { "import_statement", "import_from_statement", "future_import_statement" },
  typescript = { "import_statement" },
  tsx = { "import_statement" },
  javascript = { "import_statement" },
  go = { "import_spec" },
  rust = { "use_declaration" },
  c_sharp = { "using_directive" },
}

--- First named leaf under `node` whose text is `word`, searching from the end
--- so `from a import b as c` lands on the alias.
local function find_name(node, word, bufnr)
  for i = node:named_child_count() - 1, 0, -1 do
    local child = node:named_child(i)
    local hit = find_name(child, word, bufnr)

    if hit then
      return hit
    end
  end

  if node:named_child_count() == 0 and vim.treesitter.get_node_text(node, bufnr) == word then
    return node
  end
end

--- Jump to where the word under the cursor is imported. The jump goes on the
--- jumplist, so <C-o> returns.
function M.goto_import()
  local bufnr = vim.api.nvim_get_current_buf()
  local word = vim.fn.expand "<cword>"
  local parser = vim.treesitter.get_parser(bufnr, nil, { error = false })
  local types = parser and import_nodes[parser:lang()]

  if not types then
    vim.notify("No import lookup for this filetype", vim.log.levels.WARN)
    return
  end

  local query = vim.treesitter.query.parse(parser:lang(), "[" .. "(" .. table.concat(types, ") (") .. ")] @import")
  local root = parser:parse()[1]:root()

  for _, node in query:iter_captures(root, bufnr) do
    local hit = find_name(node, word, bufnr)

    if hit then
      local row, col = hit:range()
      vim.cmd "normal! m'"
      vim.api.nvim_win_set_cursor(0, { row + 1, col })
      return
    end
  end

  vim.notify(("No import of %s in this file"):format(word), vim.log.levels.INFO)
end

return M
