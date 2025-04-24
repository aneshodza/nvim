local function start_jdtls()
  local root_dir = require("jdtls.setup").find_root { "src" }

  if not root_dir then
    return
  end

  local config = {
    root_dir = root_dir,

    cmd = {
      "/opt/homebrew/opt/openjdk/bin/java",

      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Dlog.protocol=true",
      "-Dlog.level=ALL",
      "-Xmx1g",
      "--add-modules=ALL-SYSTEM",
      "--add-opens",
      "java.base/java.util=ALL-UNNAMED",
      "--add-opens",
      "java.base/java.lang=ALL-UNNAMED",

      "-jar",
      "/Users/anes/jdt-language-server-1.19.0-202301090450/plugins/org.eclipse.equinox.launcher_1.6.400.v20210924-0641.jar",

      "-configuration",
      "/Users/anes/jdt-language-server-1.19.0-202301090450/config_mac",

      "-data",
      root_dir,

      -- See `data directory configuration` section in the README
      -- '-data', '/path/to/unique/per/project/workspace/folder'
    },

    settings = {
      java = {},
    },

    init_options = {
      bundles = {},
    },
  }

  require("jdtls").start_or_attach(config)
end

start_jdtls()
