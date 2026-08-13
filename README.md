# dotfiles

Personal configuration files for [Neovim](https://neovim.io/),
[Rio](https://github.com/raphamorim/rio) and [htop](https://htop.dev/).

| Directory | Installed to               | What it is                                         |
| --------- | -------------------------- | -------------------------------------------------- |
| `nvim/`   | `~/.config/nvim`           | Neovim setup: `lazy.nvim`, LSP, Dracula, telescope |
| `rio/`    | `~/.config/rio`            | Rio terminal: Dracula, padding, transparency, blur |
| `htop/`   | `~/.config/htop`           | htop meters and layout                             |
| `zsh/`    | `~/.zshrc`, `~/.zshenv`    | Shell startup, including the asdf setup            |

## Quick install

No clone needed — run it straight from the network:

```sh
curl -fsSL https://raw.githubusercontent.com/guiferpa/dotfiles/main/install.sh | bash
```

The script clones the repository into a temporary directory, installs
everything and removes the clone on exit.

Flags go after `-s --`:

```sh
curl -fsSL https://raw.githubusercontent.com/guiferpa/dotfiles/main/install.sh | bash -s -- --dry-run
```

> Piping a remote script into `bash` runs code you have not read. Feel free to
> open the URL first, or use the clone below.

## Install from a clone

```sh
git clone https://github.com/guiferpa/dotfiles.git
cd dotfiles
./install.sh
```

Running from a checkout uses the configs sitting next to the script, so local
edits are applied without pushing them first.

Either way, open a new shell afterwards so the asdf shims land on `PATH`, and
open `nvim` once so `lazy.nvim` can bootstrap the plugins.

## Requirements

- macOS — Linux is not supported yet, the installer stops if it detects one
- [Homebrew](https://brew.sh/) — the installer aborts with instructions if it is missing

## Options

| Flag        | Description                                       |
| ----------- | ------------------------------------------------- |
| `--dry-run` | Print every action without changing anything      |
| `--no-deps` | Only copy the configs, skip Homebrew and the asdf plugins |
| `--help`    | Show usage                                        |

Preview an installation before committing to it:

```sh
./install.sh --dry-run
```

## How it works

1. **Detects the OS.** macOS continues; Linux stops with a warning; anything
   else is rejected.
2. **Installs the dependencies** with Homebrew, skipping what is already there.
3. **Registers the asdf plugins**, skipping the ones already added.
4. **Finds the configs** — next to the script when run from a clone, otherwise
   by cloning the repository into a temporary directory.
5. **Copies each directory** into `~/.config`, and the `zsh/` files into `~`.

### Idempotency

Running the installer twice is safe and the second run is a no-op. Each
configuration directory is compared against what is already in `~/.config`,
and each `zsh/` file against the one already in `~`:

- **missing** → copies it
- **identical** → reports `already up to date` and skips it, without writing anything
- **different** → moves the current one to `<name>.backup.<timestamp>`, then copies

Nothing is ever overwritten silently: whenever there is a difference to lose,
the existing directory is backed up first. Backups are only created when they
are actually needed, so repeated runs do not pile them up. A directory that is
a symlink from a previous symlink-based install is replaced by a real copy.

Homebrew packages are checked with `brew list` before being installed, so
already installed ones are left alone.

### Dependencies

Formulae:

| Package         | Reason                                                       |
| --------------- | ------------------------------------------------------------ |
| `neovim`        | The editor                                                   |
| `ripgrep`, `fd` | Telescope `live_grep` and `find_files`                       |
| `htop`          | Process viewer                                               |
| `git`, `curl`   | Used by `lazy.nvim` to fetch plugins, and to clone this repo |
| `asdf`          | Version manager for the language runtimes                    |
| `opencode`      | The AI agent Neovim drives — see below                       |

Casks:

| Package                         | Reason                                    |
| ------------------------------- | ----------------------------------------- |
| `rio`                           | The terminal                              |
| `font-jetbrains-mono-nerd-font` | The font Rio and Neovim are rendered with |

No language runtime is installed with Homebrew — see below. The one exception
arrives indirectly: the `opencode` formula depends on `node`, so Homebrew
installs one. It stays shadowed by the asdf shims and nothing here uses it.

## Theme

[Dracula](https://draculatheme.com/rio-terminal), applied in both places so the
terminal and the editor agree on every colour.

| Where           | File                             | What sets it                              |
| --------------- | -------------------------------- | ----------------------------------------- |
| Rio             | `rio/config.toml`                | `theme = "dracula"`                        |
| Rio palette     | `rio/themes/dracula.toml`        | The upstream `[colors]` table, vendored    |
| Neovim          | `nvim/lua/plugins/dracula.lua`   | `Mofiqul/dracula.nvim`                     |
| Neovim status   | `nvim/lua/plugins/lualine.lua`   | lualine's bundled `dracula` theme          |

Rio resolves `theme = "dracula"` against `~/.config/rio/themes/dracula.toml`.
The installer copies the whole `rio/` directory, so the palette lands there
with no extra step and nothing is downloaded at install time.

Two things to know before changing it:

- **The colorscheme has to be the same on both sides.** Rio paints the 16 ANSI
  colours that anything non-Neovim uses — `ls`, `git diff`, `htop`, the shell
  prompt. Neovim ignores them and paints from its own colorscheme. Changing one
  without the other leaves the terminal and the editor disagreeing.
- **`Mofiqul/dracula.nvim`, not upstream `dracula/vim`.** This config is built
  on treesitter, LSP semantic tokens, Telescope, Trouble and navic, and only
  the Lua port defines highlight groups for them. `dracula/vim` is vimscript and
  predates all of it, so those plugins would fall back to default groups.

`window.opacity = 0.6` in `rio/config.toml` is still in effect, so the desktop
shows through the Dracula background and washes out its contrast. Set it to
`1.0` if you want the palette at full strength. Neovim's `transparent_bg` is
deliberately off for the same reason — an opaque background painted inside
Neovim would cancel the terminal's transparency out.

## Font

[JetBrains Mono](https://github.com/JetBrains/JetBrainsMono), in the
[Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) patched build, at size 14.
Set once in `rio/config.toml`:

```toml
[fonts]
family = "JetBrainsMono Nerd Font Mono"
size = 14
```

That is also the Neovim font. Neovim has no font setting of its own — it draws
through the terminal, so there is nothing to configure on the `nvim/` side.

Three details worth keeping in mind when changing it:

- **Use the `Mono` variant.** Nerd Fonts ships three builds of every family,
  differing only in how the added icon glyphs are sized. `Mono` keeps them
  inside a single cell; `Propo` and the plain build let them run wider, which
  makes the icons in `oil` and `lualine` overlap the next column.
- **The patched build is not interchangeable with upstream.** `oil` and
  `lualine` draw their file icons through `mini.icons`
  (`nvim/lua/plugins/icons.lua`), which uses Nerd Font codepoints that upstream
  `JetBrains/JetBrainsMono` does not contain — with the plain font they render
  as tofu boxes.
- **Nerd Fonts 3.0 or newer is required, not just any patched build.**
  `mini.icons` draws mostly from the `nf-md-*` (Material Design) class, which
  version 3 moved out of the basic plane into `U+F0001`–`U+F1AF0`. Measured on
  the current install, 279 of its 380 glyphs — 73% — live up there, against 55
  of 322 for the `nvim-web-devicons` it replaced. A font patched with Nerd
  Fonts 2.x carries that class at the old `U+F500`–`U+FD46` addresses and
  almost every icon comes out blank. `JetBrainsMono Nerd Font Mono` at
  Nerd Fonts 3.5.0 covers all 380.
- **A monospaced font is not automatically a terminal font.** Coverage measured
  on the actual files:

  | Font                     | Codepoints | Box drawing | Blocks | Braille | Powerline | Icons |
  | ------------------------ | ---------: | ----------- | ------ | ------- | --------- | ----- |
  | JetBrainsMono Nerd Font  |     12 121 | 128/128     | 32/32  | 256/256 | 4/4       | ~8600 |
  | Chivo Mono               |        642 | 0/128       | 0/32   | 0/256   | 0/4       | 0     |
  | Azeret Mono              |        433 | 0/128       | 0/32   | 0/256   | 0/4       | 0     |

  Chivo Mono and Azeret Mono are text and display faces. With either of them,
  everything structural — window splits, Telescope and Trouble borders, htop
  meters, plugin spinners — falls back to whatever font Rio substitutes, at
  different metrics.

Patching in the icons adds only the private-use ranges, never missing Unicode,
so check a glyph before putting it in a config that draws it on every line.
`listchars` in `nvim/lua/options.lua` uses `⏎` rather than `↲` for that reason:
JetBrains Mono has no `↲` or `↵`.

## Language runtimes

Every runtime comes from [asdf](https://asdf-vm.com/), never from Homebrew.
Homebrew installs `asdf` itself and the build dependencies some plugins need,
and nothing else.

The installer registers these plugins:

| Plugin   | Source                                                |
| -------- | ----------------------------------------------------- |
| `nodejs` | `https://github.com/asdf-vm/asdf-nodejs.git`          |
| `golang` | `https://github.com/asdf-community/asdf-golang.git`   |
| `python` | `https://github.com/asdf-community/asdf-python.git`   |
| `rust`   | `https://github.com/code-lever/asdf-rust.git`         |

**Only the plugins.** No version is installed and `~/.tool-versions` is never
written by the installer, so nothing on the machine is pinned behind your back.
Versions are yours to pick:

```sh
asdf install nodejs 24.14.0     # install a version
asdf set nodejs 24.14.0         # pin it in ./.tool-versions, for this project
asdf set -u nodejs 24.14.0      # pin it in ~/.tool-versions, as the default
```

### PATH ordering

`zsh/zshrc` exports the asdf shims **after** every Homebrew path, and the block
is commented in place explaining why. Each `export PATH="<dir>:$PATH"` prepends
its directory, so the last export wins. Exporting the shims before
`/opt/homebrew/bin` makes Homebrew's `node`, `go` and `python3` shadow them:
asdf looks installed and configured, `asdf current` reports the right versions,
and the shell still runs the Homebrew binaries.

That is the state this repository migrated away from, so keep the asdf block at
the bottom of `zsh/zshrc`. Anything appended below it shadows the shims again.

Homebrew's `node`, `go` and `python` are left installed if they are already
there — they simply stop winning on `PATH`. Remove them with
`brew uninstall node go python` if you want, but check `brew uses --installed`
first, since other formulae may depend on them.

### Mason and the LSPs

Mason installs `ts_ls` and `pylsp` into whatever `node`/`python` is active, so
they live inside an asdf install directory. After changing a runtime version,
run `asdf reshim` and reinstall the affected servers from `:Mason`.

## AI agent

[opencode](https://opencode.ai/) runs as its own process and Neovim talks to it
over its HTTP API through
[`opencode.nvim`](https://github.com/nickjvandyke/opencode.nvim)
(`nvim/lua/plugins/opencode.lua`). There is no chat window inside Neovim: the
agent keeps its own TUI, and the plugin supplies the editor context and the
connection.

The server must be started with `--port` or nothing can reach it. The plugin
looks for one already running and only starts its own — a terminal split on the
right — when it finds none, so an `opencode --port` left open in another pane
is adopted instead of duplicated.

Mappings live under `,a`, since `,o` is oil's and `,c` clears the search
highlight. [`nvim/SHORTCUTS.md`](nvim/SHORTCUTS.md) is the full reference and
covers how to drive the agent; the short version:

| Key   | Action                                       |
| ----- | -------------------------------------------- |
| `,aa` | Ask about the cursor position or selection   |
| `,ab` | Ask about the whole buffer                   |
| `,ad` | Ask about diagnostics                        |
| `,as` | Select a prompt, command or server           |
| `,ao` | Operator: append a motion's range to a prompt |
| `,an` | New session                                  |
| `,ax` | Interrupt the session                        |
| `,au` | Scroll the agent's output up                 |
| `,ae` | Scroll the agent's output down                |

These are not the mappings the plugin's README suggests. `<C-a>` and `<C-x>`
are Vim's increment and decrement, `go` is a motion, and the proposed
`<S-C-u>`/`<S-C-d>` need a terminal that tells Ctrl-Shift apart from plain
Ctrl — Rio only does that with `use-kitty-keyboard-protocol`, which
`rio/config.toml` leaves off.

Run `:checkhealth opencode` after the first start.

### Credentials

opencode reads its provider keys from the environment, so they have to be set
somewhere every shell sees — including the non-interactive one behind the
`term://opencode --port` buffer. That means `zshenv`.

`zsh/zshenv` carries the full list as **commented-out placeholders**:
`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `OPENROUTER_API_KEY`, the Bedrock
`AWS_*` trio, the optional `OPENCODE_CONFIG` / `OPENCODE_CONFIG_DIR`, and
`OPENCODE_SERVER_USERNAME` / `OPENCODE_SERVER_PASSWORD` for a remote server.
Only the provider actually configured as the model needs a key.

**No real key goes in that file.** It is committed here and copied to
`~/.zshenv`, so anything written into it gets published. Real values go in
`~/.zshenv.local`, which the last lines of `zshenv` source if it exists and
which no part of this repository tracks:

```sh
touch ~/.zshenv.local && chmod 600 ~/.zshenv.local
echo 'export ANTHROPIC_API_KEY="…"' >> ~/.zshenv.local
```

## Updating

Configurations are **copied**, not symlinked, so editing `~/.config/nvim` or
`~/.zshrc` does not change this repository. Edit the files here and run
`./install.sh` again to apply them.

Note that `nvim/lazy-lock.json` is copied along with the rest, so re-running
the installer resets locally updated plugin versions back to the ones pinned in
this repository.
