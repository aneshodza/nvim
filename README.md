# nvim

My Neovim config. It began as a copy of the NvChad v2.0 starter and has moved a fair distance from it since.

NvChad is now pulled in as a plugin rather than vendored, so this repo only holds my own layer. The
confusing part is the version numbers: `NvChad/NvChad` is on branch `v2.5`, but it pins `NvChad/ui`
and `NvChad/base46` without a branch, and both of those default to `v3.0`. So `v2.5` is just the
entry point. There is no `v3.0` branch on `NvChad/NvChad` to switch to.

Tested on Neovim 0.11.1 and 0.12.5.

## Layout

```
init.lua              bootstrap, taken from the NvChad starter
lua/chadrc.lua        only the deltas from NvChad's defaults
lua/options.lua       what nvchad.options does not already set
lua/autocmds.lua      user commands, large-file guard, startup time
lua/mappings.lua      everything not already mapped upstream
lua/configs/          plugin opts, mostly deltas over nvchad.configs.*
lua/configs/servers/  one file per LSP server
lua/utils/            my own modules
scripts/              CI checks, not loaded at runtime
tests/fixtures/       small real projects the LSP jobs open
```

## Setting it up somewhere new

```sh
git clone git@github.com:aneshodza/nvim.git ~/.config/nvim
nvim                    # lazy installs everything on first start
```

Then inside Neovim:

```
:MasonInstallAll        # language servers and formatters
:checkhealth nvimrc     # what is still missing
```

`:checkhealth nvimrc` covers the things that live outside this repo: whether git, ripgrep, node,
dotnet, latexmk and python are on PATH, which mason packages have not been installed, and whether
basedpyright resolved the same interpreter as the project venv.

Two things it will flag that mason cannot fix for you. Solargraph is a Ruby gem, so it needs
`gem install solargraph`. Latexmk comes from a TeX distribution.

## Things worth knowing

`lua/configs/servers/` uses the filename as the server name. Dropping `gopls.lua` in there
configures and enables gopls, and that is the whole mechanism. The files have to be plain data with
no `on_attach` or `capabilities`, because `vim.lsp.config` merges name-level config over
nvim-lspconfig's own and would silently throw away its defaults. CI checks this.

Python runs two servers. Basedpyright does types and navigation. Pylsp is there only for rope's
auto-import index, which covers every package in the venv rather than only the ones something has
already imported. Every other pylsp plugin is switched off.

`<leader>uv` is a small uv toolset: `d` for the dependencies declared in this project and the
workspace root, `p` for which interpreter everything resolved to, `y` to sync and restart the
servers, `a` to audit, `t` for the dependency tree.

`:DuplicateKeybinds` lists keybinds that collide, either because a buffer-local map quietly shadows
a global one or because a short mapping has to wait out `timeoutlen` before it fires. Both had been
happening here for a long time without me noticing.

Startup time appears once the UI settles. Green under 100ms, amber to 250ms, red past that.

`lazy-lock.json` is committed on purpose, so a fresh clone gets the same plugin revisions.

## CI

Every push runs stylua for formatting, a smoke test against both Neovim versions, and four
per-language jobs. The smoke test boots the config and asserts the plugin set, the keymaps and the
pinned revisions are what they should be. The language jobs open a real fixture project each for
Python, TypeScript, Rust and Lua, then check that the right client attached, that a deliberate
error produced a diagnostic, and that a code action was offered.

All of it runs under `nvim -l`. That matters more than it sounds: `nvim --headless -u init.lua +qa`
exits 0 even when the config is broken, so it cannot gate anything.

To reproduce a CI check locally:

```sh
nvim --headless -l scripts/checkload.lua       # parses, invariants, unit checks
nvim --headless -l scripts/smoke.lua           # boots and asserts
nvim --headless -l scripts/lsp_smoke.lua rust  # one language end to end
nvim --headless -l scripts/dump.lua            # snapshot plugins, keymaps, servers
```

`scripts/dump.lua` also regenerates the golden keymap file that smoke compares against:

```sh
nvim --headless -l scripts/dump.lua \
  | awk '/^## keymaps/{f=1;next} /^## /{f=0} f && NF' > scripts/expected/keymaps.txt
```

## Testing a change without breaking the running config

```sh
git worktree add ~/.config/nvim-next -b some-branch
NVIM_APPNAME=nvim-next nvim
```

`NVIM_APPNAME` redirects the config, data, state and cache directories, so the two installs share
nothing and you can run them side by side.
