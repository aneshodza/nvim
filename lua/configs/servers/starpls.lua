-- bazelisk rather than starpls' default `bazel`, which isn't installed; starpls
-- runs it for `bazel info` and to resolve external repos (@pypi//..., etc.).
return {
  cmd = { "starpls", "server", "--bazel_path=bazelisk" },
}
