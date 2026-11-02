-- Lint on; eval diagnostics off, since tilt configs read std.extVar and import
-- generated files (worktree-port-offsets.json) that eval can't resolve.
return {
  settings = {
    enable_lint_diagnostics = true,
    enable_eval_diagnostics = false,
  },
}
