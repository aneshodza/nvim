-- The previous version built its cmd in `on_new_config`, which is a hook of the
-- old require("lspconfig").x.setup{} framework and is never called by
-- vim.lsp.config - so ~40 lines of probe-path logic never ran and the server
-- silently used nvim-lspconfig's own cmd. Rebuilt inside a cmd function, which
-- does run.
--
-- Paths go through vim.fn.stdpath "data" rather than a literal
-- ~/.local/share/nvim, so a non-default XDG_DATA_HOME or NVIM_APPNAME resolves
-- correctly.

local function probe_paths()
  local probes = {}

  -- cmd receives no root_dir, so derive it from the buffer triggering the
  -- attach - which is the same buffer whose root_dir matched above
  local root = vim.fs.root(0, { "angular.json", "nx.json" })

  if root then
    local local_ts = vim.fs.joinpath(root, "node_modules/typescript/lib")

    if vim.fn.isdirectory(local_ts) == 1 then
      table.insert(probes, local_ts)
    end
  end

  -- fall back to mason's typescript so the server works before npm install
  local mason_ts =
    vim.fs.joinpath(vim.fn.stdpath "data", "mason/packages/typescript-language-server/node_modules/typescript/lib")

  if vim.fn.isdirectory(mason_ts) == 1 then
    table.insert(probes, mason_ts)
  end

  return table.concat(probes, ",")
end

return {
  filetypes = { "typescript", "html", "htmlangular", "typescriptreact" },

  cmd = function(dispatchers)
    local probes = probe_paths()
    local bin = vim.fn.exepath "ngserver"

    local cmd = bin ~= "" and { bin }
      or {
        "node",
        vim.fs.joinpath(
          vim.fn.stdpath "data",
          "mason/packages/angular-language-server/node_modules/@angular/language-server/bin/ngserver"
        ),
      }

    vim.list_extend(cmd, {
      "--stdio",
      "--tsProbeLocations",
      probes,
      "--ngProbeLocations",
      probes,
    })

    return vim.lsp.rpc.start(cmd, dispatchers)
  end,

  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(vim.api.nvim_buf_get_name(bufnr), { "angular.json", "nx.json" })

    if root then
      on_dir(root)
    end
  end,
}
