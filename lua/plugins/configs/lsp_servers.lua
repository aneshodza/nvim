local server_configs_path = vim.fn.stdpath("config") .. "/lua/plugins/configs/servers"
local files = vim.fn.readdir(server_configs_path)

for _, file in ipairs(files) do
  if file:match("%.lua$") then
    local server_name = file:gsub("%.lua$", "")
    local ok, opts = pcall(require, "plugins.configs.servers." .. server_name)
    
    if ok and type(opts) == "table" then
      -- Get your global defaults (on_attach, capabilities)
      local common = require("plugins.configs.lspconfig")
      
      -- Merge them into the server-specific opts
      opts.on_attach = opts.on_attach or common.on_attach
      opts.capabilities = opts.capabilities or common.capabilities

      -- REGISTER AND ENABLE IN ONE GO (The 0.11 way)
      vim.lsp.enable(server_name, opts)
    end
  end
end
