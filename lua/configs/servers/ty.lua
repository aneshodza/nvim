-- basedpyright owns diagnostics, completion, hover and navigation. ty runs
-- alongside it only for auto-imports: its index covers every package installed
-- in the venv, while basedpyright only suggests packages already imported
-- somewhere in the workspace. configs/lspconfig.lua strips ty's other
-- capabilities, configs/cmp.lua keeps only its import completions, and
-- utils/lsp.lua turns basedpyright's undefined-name diagnostics into ty's add-import fixes.
return {
  root_dir = require("utils.python").root_dir,

  settings = {
    ty = {
      diagnosticMode = "off",
    },
  },
}
