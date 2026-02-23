local server_configs_path = vim.fn.stdpath("config") .. "/lua/plugins/configs/servers"
local files = vim.fn.readdir(server_configs_path)

for _, file in ipairs(files) do
  if file:match("%.lua$") then
    local server_name = file:gsub("%.lua$", "")
    -- 1. Load the server-specific file
    local ok, opts = pcall(require, "plugins.configs.servers." .. server_name)
    
    if ok then
      local common = require("plugins.configs.lspconfig")
      
      -- 2. Use 'opts' (the variable you actually loaded)
      local final_opts = vim.tbl_deep_extend("force", {
        on_attach = common.on_attach,
        capabilities = common.capabilities,
      }, opts or {})

      -- 3. Configure and enable the server
      vim.lsp.config(server_name, final_opts)
      vim.lsp.enable(server_name)
    end
  end
end
