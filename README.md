# dotfiles

Personal configuration files for [Neovim](https://neovim.io/),
[Rio](https://github.com/raphamorim/rio) and [htop](https://htop.dev/).

| Directory | Installed to      |
| --------- | ----------------- |
| `nvim/`   | `~/.config/nvim`  |
| `rio/`    | `~/.config/rio`   |
| `htop/`   | `~/.config/htop`  |

## Requirements

- macOS — Linux is not supported yet, the installer stops if it detects one
- [Homebrew](https://brew.sh/) — the installer aborts with instructions if it is missing

## Installation

```sh
git clone https://github.com/guiferpa/dotfiles.git
cd dotfiles
./install.sh
```

The script installs the dependencies and copies each configuration directory
into `~/.config`. Open `nvim` once afterwards so `lazy.nvim` can bootstrap the
plugins.

### Options

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

The installer is idempotent — running it twice is safe and the second run is a
no-op. For each configuration directory it compares the source with what is
already in `~/.config`:

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

| Package           | Reason                                                          |
| ----------------- | --------------------------------------------------------------- |
| `neovim`          | The editor                                                        |
| `ripgrep`, `fd`   | Telescope `live_grep` and `find_files`                            |
| `htop`            | Process viewer                                                    |
| `git`, `curl`     | Used by `lazy.nvim` to fetch plugins                              |
| `node`, `go`, `python` | Runtimes for the LSPs installed by Mason (`ts_ls`, `gopls`, `pylsp`) |

Casks: `rio`.

## Updating

Configurations are **copied**, not symlinked, so editing `~/.config/nvim`
does not change this repository. Edit the files here and run `./install.sh`
again to apply them.

Note that `nvim/lazy-lock.json` is copied along with the rest, so re-running
the installer resets locally updated plugin versions back to the ones pinned in
this repository.
