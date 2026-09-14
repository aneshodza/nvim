-- Everything that used to run at module load - io.popen("asdf where dotnet"),
-- two vim.env writes, an is_mac branch and two hardcoded $HOME paths - now runs
-- inside cmd, i.e. only when a C# buffer actually starts the server. The
-- readdir loop in init.lua requires every file in this directory on the first
-- BufReadPost of any filetype, so load-time side effects were being paid on
-- every session regardless of language.
--
-- A function cmd also skips vim.lsp's executable() precheck, which is what we
-- want when dotnet may legitimately be absent.
--
-- No `capabilities` key: nvim-lspconfig's lsp/omnisharp.lua sets
-- workspace.workspaceFolders = false (OmniSharp-roslyn#909) and a name-level
-- capabilities table would silently override it.

return {
  filetypes = { "cs", "vb", "csproj", "sln", "slnx" },

  cmd = function(dispatchers)
    -- mason's bin dir is on PATH, so the wrapper resolves dotnet itself
    local bin = vim.fn.exepath "omnisharp"

    local cmd = bin ~= "" and { bin }
      or {
        "dotnet",
        vim.fs.joinpath(vim.fn.stdpath "data", "mason/packages/omnisharp/libexec/OmniSharp.dll"),
      }

    vim.list_extend(cmd, { "--languageserver", "--hostPID", tostring(vim.fn.getpid()) })

    local env = { MSBUILDDISABLENODEREUSE = "1" }
    local asdf = vim.fn.trim(vim.fn.system "asdf where dotnet 2>/dev/null")

    if vim.v.shell_error == 0 and asdf ~= "" then
      env.DOTNET_ROOT = asdf
    end

    return vim.lsp.rpc.start(cmd, dispatchers, { env = env })
  end,

  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)

    local root = vim.fs.root(fname, function(name)
      return name:match "%.slnx?$" or name:match "%.csproj$"
    end) or vim.fs.root(fname, ".git")

    if root then
      on_dir(root)
    end
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
}
