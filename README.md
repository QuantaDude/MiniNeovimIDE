# Neovim C++ IDE

Neovim 0.12+ config, plugins via `vim.pack`, C++ first (clangd, CMake, DAP,
perf).

## Install

```sh
scripts/install-deps.sh --dry-run   # see what it would install
scripts/install-deps.sh             # clangd, cmake, ninja, gdb/lldb, ripgrep, ...
```

Use a **Nerd Font** in the terminal, otherwise icons render as boxes. First start
clones the plugins and compiles the theme cache (a few seconds); `:checkhealth`
and `:IdeDoctor` show anything missing.

## What was added

| Area | What you get |
|---|---|
| Dashboard | Project / Toolchain / Actions / Recent panels, opens on `nvim` with no args, `:Dashboard` or `<leader>ud`. Hotkeys are shown next to each item; digits `1-6` open recent files, `A-C` recent projects. Mouse works. |
| Theme | NvChad's **base46** themes with NvChad's picker (`<leader>ut`). The choice is saved by rewriting `theme = "..."` in `lua/chadrc.lua`. `<leader>uC` still opens the plain `:colorscheme` picker (the old one); picking a plain scheme there switches back to it until you pick a base46 theme again. |
| Completion | **nvim-cmp** with NvChad's `atom` window/format (change `ui.cmp.style` in `chadrc.lua`), LuaSnip + friendly-snippets, plus curated C++/C/CMake snippets in `lua/snippets/`. The previous native completion stays as a fallback if nvim-cmp is missing. |
| which-key | Popup for `<leader>`, `g`, `z`, `[`, `]`. Groups are defined in `lua/ide/whichkey.lua`. |
| Cheatsheet | `<leader>?` / `:NvCheatsheet`: NvChad's grid, filled from your real keymaps, grouped like which-key. |
| Colors | NvChad **colorify** swatches next to `#rrggbb`; `<leader>uc` / `<leader>us` open minty's picker / shades (replaces ccc). |
| UI | mini.statusline (LSP, CMake build type/target, recording), mini.tabline, mini.notify (shows clangd indexing), `vim.ui.select` through mini.pick. |
| LSP | Code actions, rename, call hierarchy, signature help while typing, inlay-hint toggle, diagnostic icons, hover/diagnostic popup on idle, lua_ls when installed. |
| Editing | Persistent terminals, buffer management, block insert/append, word-prefix/suffix helpers, window resizing, comment maps. |
| Git | `<leader>gl` log, `<leader>gc` commit, `<leader>gh` commit/history under cursor (mini.git). |

## Keys worth knowing

`<leader>` is Space.

| Keys | Action |
|---|---|
| `<leader>ff` `fg` `fb` `fo` `fw` | files, live grep, buffers, recent, word under cursor |
| `<leader>fk` `fc` `fl` `fm` | keymaps, commands, buffer lines, marks |
| `<leader>ca` `cA` `rn` `ci` `co` | code action, source action, rename, incoming/outgoing calls |
| `<leader>ut` / `uC` | NvChad theme picker / plain colorscheme picker |
| `<leader>uc` `us` | color picker / shades |
| `<leader>uh` `uH` `uf` | toggle inlay hints / hover-on-idle / format-on-save |
| `<leader>un` `uN` `uU` `uD` | dismiss notifications / history / update plugins / toolchain doctor |
| `<leader>tt` `tf` `<A-t>` | bottom terminal, floating terminal, toggle terminal |
| `<leader>bw` `bW` `bc` `bo` `ba` | save, save all, close buffer, close others, close all (safe) |
| `<leader>v` `h` `q` `Q` | vsplit, split, quit window, quit all |
| Snippet triggers (type, then `<Tab>`) | `main`, `guard`, `cls`, `rule5`, `tmpl`, `concept`, `lam`, `gtest`, ... (see `lua/snippets/cpp.lua`) |

The full, current list is always `<leader>?`.

## Behaviours to be aware of

- **Hover on idle** is on by default (diagnostic of the line, else LSP docs).
  Turn it off with `<leader>uH` or `vim.g.ide_autohover = false`.
- **Theme persistence**: `lua/chadrc.lua` must contain the theme name quoted
  exactly once (`theme = "catppuccin"`); the picker edits that line.
- **Plugin updates** recompile the theme cache automatically (`PackChanged`).
- Tree-sitter parsers are handled as in the original config (unchanged).
- Delete `~/.local/share/nvim/base46/` to force a theme cache rebuild.

## Layout of the config 

```
init.lua                  (only additive lines)
colors/base46.lua         :colorscheme base46
lua/chadrc.lua            theme, cmp style, colorify, cheatsheet options
lua/snippets/             cpp.lua c.lua cmake.lua
lua/ide/pack_extra.lua    new plugins
lua/ide/base46.lua        theme compile/load/pick glue
lua/ide/completion.lua    nvim-cmp + LuaSnip
lua/ide/whichkey.lua      groups + setup
lua/ide/cheatsheet.lua    cheatsheet from live keymaps
lua/ide/dashboard.lua     start screen
lua/ide/project.lua       project / toolchain detection used by the dashboard + statusline
lua/ide/ui.lua            statusline, tabline, notify, colorify, extra pickers
lua/ide/lspx.lua          LSP extras
lua/ide/editing.lua       buffers, windows, text helpers
lua/ide/terminal.lua      terminals
scripts/install-deps.sh   system dependencies
```

Small edits to existing files: `init.lua` (loads the new modules),
`lua/ide/lsp.lua` (native completion steps aside when nvim-cmp is active) and
`lua/ide/theme.lua` (old picker kept as `pick_colorscheme`, `pick()` now opens
NvChad's).
