require "nvchad.options"

local o = vim.o

-- nvchad.options sets mouse = "a"; this overrides it back off
o.mouse = ""
o.guicursor = ""

-- nvchad.options does not set relativenumber
o.relativenumber = true

-- 'language messages' raises E197 on a machine where the locale has not been
-- generated, which would be an uncaught error at startup. LANG/LC_ALL are
-- deliberately not set: they would leak into every subprocess nvim spawns,
-- including every language server.
pcall(vim.cmd.language, "messages", "en_US.UTF-8")
o.langmenu = "en_US.UTF-8"
