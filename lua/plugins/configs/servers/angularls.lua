-- Helper to find the TypeScript library path required by Angular LS
local function get_probe_paths(root_dir)
  local probes = {}
  
  -- 1. Check for local node_modules in the project
  if root_dir then
    local local_ts = root_dir.. "/node_modules/typescript/lib"
    if vim.fn.isdirectory(local_ts) == 1 then
      table.insert(probes, local_ts)
    end
  end
  
  -- 2. Fallback to Mason's global typescript installation
  -- This ensures the server works even if you haven't run npm install yet
  local mason_ts = vim.fn.expand("~/.local/share/nvim/mason/packages/typescript-language-server/node_modules/typescript/lib")
  if vim.fn.isdirectory(mason_ts) == 1 then
    table.insert(probes, mason_ts)
  end
  
  return table.concat(probes, ",")
end

return {
  filetypes = { "typescript", "html", "htmlangular", "typescriptreact" },
  
  -- Dynamic root detection for Angular and Nx projects
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(fname, { 
      "angular.json", 
      "nx.json", 
      "tsconfig.json", 
      "package.json", 
      ".git" 
    })
    
    if root then
      on_dir(root)
    end
  end,

  -- Use on_new_config to inject the dynamic probe paths just before spawn
  on_new_config = function(new_config, root_dir)
    local ngserver_bin = vim.fn.expand("~/.local/share/nvim/mason/packages/angular-language-server/node_modules/@angular/language-server/bin/ngserver")
    local probe_paths = get_probe_paths(root_dir)
    
    new_config.cmd = {
      "node",
      ngserver_bin,
      "--stdio",
      "--tsProbeLocations",
      probe_paths,
      "--ngProbeLocations",
      probe_paths,
    }
  end,

  on_attach = function(client, bufnr)
    local nvlsp = require("plugins.configs.lspconfig")
    if nvlsp and nvlsp.on_attach then
      nvlsp.on_attach(client, bufnr)
    end
  end,

  capabilities = (function()
    local ok, nvlsp = pcall(require, "plugins.configs.lspconfig")
    return ok and nvlsp.capabilities or nil
  end)(),
}
