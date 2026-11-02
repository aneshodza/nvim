return {
  settings = {
    gopls = {
      -- bazel's convenience symlinks at the repo root point into the whole
      -- build output; gopls would otherwise walk all of it
      directoryFilters = { "-**/node_modules", "-bazel-bin", "-bazel-out", "-bazel-testlogs", "-bazel-dj2" },
    },
  },
}
