# dotfiles

Personal configuration files for [Neovim](https://neovim.io/),
[Rio](https://github.com/raphamorim/rio) and [htop](https://htop.dev/).

| Directory | Installed to     | What it is                                      |
| --------- | ---------------- | ----------------------------------------------- |
| `nvim/`   | `~/.config/nvim` | Neovim setup: `lazy.nvim`, LSP, gruvbox, telescope |
| `rio/`    | `~/.config/rio`  | Rio terminal: padding, transparency, blur         |
| `htop/`   | `~/.config/htop` | htop meters and layout                            |

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

Either way, open `nvim` once afterwards so `lazy.nvim` can bootstrap the
plugins.

## Requirements

- macOS — Linux is not supported yet, the installer stops if it detects one
- [Homebrew](https://brew.sh/) — the installer aborts with instructions if it is missing

## Options

| Flag        | Description                                       |
| ----------- | ------------------------------------------------- |
| `--dry-run` | Print every action without changing anything      |
| `--no-deps` | Only copy the configs, skip the Homebrew packages |
| `--help`    | Show usage                                        |

Preview an installation before committing to it:

```sh
./install.sh --dry-run
```

## How it works

1. **Detects the OS.** macOS continues; Linux stops with a warning; anything
   else is rejected.
2. **Installs the dependencies** with Homebrew, skipping what is already there.
3. **Finds the configs** — next to the script when run from a clone, otherwise
   by cloning the repository into a temporary directory.
4. **Copies each directory** into `~/.config`.

### Idempotency

Running the installer twice is safe and the second run is a no-op. Each
configuration directory is compared against what is already in `~/.config`:

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

| Package                | Reason                                                               |
| ---------------------- | -------------------------------------------------------------------- |
| `neovim`               | The editor                                                             |
| `ripgrep`, `fd`        | Telescope `live_grep` and `find_files`                                 |
| `htop`                 | Process viewer                                                         |
| `git`, `curl`          | Used by `lazy.nvim` to fetch plugins, and to clone this repo           |
| `node`, `go`, `python` | Runtimes for the LSPs installed by Mason (`ts_ls`, `gopls`, `pylsp`)   |

Casks: `rio`.

## Updating

Configurations are **copied**, not symlinked, so editing `~/.config/nvim`
does not change this repository. Edit the files here and run `./install.sh`
again to apply them.

Note that `nvim/lazy-lock.json` is copied along with the rest, so re-running
the installer resets locally updated plugin versions back to the ones pinned in
this repository.
