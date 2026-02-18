local is_mac = vim.loop.os_uname().sysname == "Darwin"
local home = os.getenv("HOME")

-- Initialize variables
local dotnet_bin = "dotnet"
local omnisharp_dll = ""

if is_mac then
    local handle = io.popen("asdf where dotnet 2>/dev/null")
    local asdf_path = handle:read("*a"):gsub("%s+", "")
    handle:close()

    if asdf_path ~= "" then
        dotnet_bin = asdf_path .. "/dotnet"
        vim.env.DOTNET_ROOT = asdf_path
    else
        dotnet_bin = vim.fn.exepath("dotnet")
        vim.env.DOTNET_ROOT = home .. "/.dotnet"
    end
    omnisharp_dll = home .. "/.local/share/nvim/mason/packages/omnisharp/libexec/OmniSharp.dll"
else
    -- WSL / Linux
    dotnet_bin = home .. "/.dotnet/dotnet"
    omnisharp_dll = home .. "/.local/share/nvim/omnisharp/OmniSharp.dll"
    vim.env.DOTNET_ROOT = home .. "/.dotnet"
end

vim.env.MSBUILDDISABLENODEREUSE = "1" 

return {
  -- Use the list of filetypes the server should attach to
  filetypes = { "cs", "vb", "csproj", "sln" },
  
  cmd = {
    dotnet_bin,
    omnisharp_dll,
    "--languageserver",
    "--hostPID",
    tostring(vim.fn.getpid()),
  },
  
  root_dir = function(fname)
    -- Corrected glob-like behavior for 0.11
    return vim.fs.root(fname, function(name)
      return name:match("%.sln$") or name:match("%.csproj$")
    end) or vim.fs.root(fname, ".git") or vim.fs.dirname(fname)
  end,
  
  settings = {
    omnisharp = {
      useModernNet = true,
      enableEditorConfigSupport = true,
      enablePackageRestore = true,
      analyzeOpenDocumentsOnly = true, 
      enableMsBuildLoadProjectsOnDemand = true,
    },
  },

  -- Ensure capabilities are handled safely for the new API
  capabilities = (function()
    local ok, lsp_configs = pcall(require, "plugins.configs.lspconfig")
    return ok and lsp_configs.capabilities or vim.lsp.protocol.make_client_capabilities()
  end)(),

  on_attach = function(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
    local ok, lsp_configs = pcall(require, "plugins.configs.lspconfig")
    if ok and lsp_configs.on_attach then 
        lsp_configs.on_attach(client, bufnr) 
    end
  end,
}
