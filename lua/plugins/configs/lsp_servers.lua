--
-- if os_check.is_fedora() then
--   lspconfig.solargraph.setup{
--     cmd = {
--       '/home/aneshodza/solargraph_lsp_wrapper.sh'
--     }
--   }
-- else
--   lspconfig.solargraph.setup{}
-- end

local lspconfig = require("lspconfig")
local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local server_configs_path = vim.fn.stdpath("config") .. "/lua/plugins/configs/servers"

for _, file in ipairs(vim.fn.readdir(server_configs_path)) do
  if file:match("%.lua$") then
    local server_name = file:gsub("%.lua$", "")
    local ok, opts = pcall(require, "plugins.configs.servers." .. server_name)

    if ok and type(opts) == "table" then
      if not opts.on_attach then
        vim.notify("Missing `on_attach` in config for LSP: " .. server_name, vim.log.levels.ERROR)
      elseif not opts.capabilities then
        vim.notify("Missing `capabilities` in config for LSP: " .. server_name, vim.log.levels.ERROR)
      else
        lspconfig[server_name].setup(opts)
      end
    else
      vim.notify("Failed to load LSP config for " .. server_name, vim.log.levels.WARN)
    end
  end
end
