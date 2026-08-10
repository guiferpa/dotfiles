#!/usr/bin/env bash
#
# dotfiles installer
#
# Copies the configs from this repository into ~/.config and installs the
# dependencies they need. macOS only for now.
#
# Can be run from a checkout or straight from the network, in which case it
# clones the repository into a temporary directory first.

set -euo pipefail

REPO_URL="https://github.com/guiferpa/dotfiles.git"

# Empty when the script is piped into bash (there is no file on disk).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd || true)"

DOTFILES_DIR=""
CLONE_DIR=""
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_SUFFIX="backup.$(date +%Y%m%d%H%M%S)"

INSTALL_DEPS=1
DRY_RUN=0

# Configs shipped by this repo. Each one is copied to $CONFIG_DIR/<name>.
CONFIGS=(nvim rio htop)

# Files copied straight into $HOME: zsh reads its startup files from the home
# directory, so they cannot live under $CONFIG_DIR.
# Format: "<path in this repo>:<path relative to $HOME>"
HOME_FILES=(zsh/zshrc:.zshrc zsh/zshenv:.zshenv)

# Homebrew formulae:
#   neovim            the editor itself
#   ripgrep, fd       telescope live_grep / find_files
#   htop              process viewer
#   git, curl         lazy.nvim plugin manager
#   asdf              version manager for the language runtimes
#
# Language runtimes are deliberately absent from this list: node, go, python
# and rust are managed by asdf, never by Homebrew. See ASDF_PLUGINS below.
BREW_FORMULAE=(neovim ripgrep fd htop git curl asdf)

# Homebrew casks
BREW_CASKS=(rio)

# asdf plugins to register, as "<name> <git url>".
#
# Only the plugins are added. No version is installed and ~/.tool-versions is
# never written, so each project decides its own versions through its local
# .tool-versions and `asdf install` is run by hand when needed.
ASDF_PLUGINS=(
  "nodejs https://github.com/asdf-vm/asdf-nodejs.git"
  "golang https://github.com/asdf-community/asdf-golang.git"
  "python https://github.com/asdf-community/asdf-python.git"
  "rust https://github.com/code-lever/asdf-rust.git"
)

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
RESET=$'\033[0m'

info()  { printf '%s==>%s %s\n' "$BLUE" "$RESET" "$1"; }
ok()    { printf '%s  ok%s %s\n' "$GREEN" "$RESET" "$1"; }
warn()  { printf '%swarn%s %s\n' "$YELLOW" "$RESET" "$1" >&2; }
error() { printf '%s err%s %s\n' "$RED" "$RESET" "$1" >&2; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '     [dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

usage() {
  cat <<'EOF'
dotfiles installer

Copies the configs from this repository into ~/.config and installs the
dependencies they need. macOS only for now.

Usage:
  ./install.sh              install everything
  ./install.sh --no-deps    only copy the configs
  ./install.sh --dry-run    show what would happen, change nothing
  ./install.sh --help       show this message

Without a checkout, run it straight from the network:
  curl -fsSL https://raw.githubusercontent.com/guiferpa/dotfiles/main/install.sh | bash
EOF
}

cleanup() {
  if [ -n "$CLONE_DIR" ] && [ -d "$CLONE_DIR" ]; then
    rm -rf "$CLONE_DIR"
  fi
}
trap cleanup EXIT

# Finds the configs next to the script, or clones the repository when the
# script was piped into bash and there is nothing on disk to copy from.
resolve_dotfiles() {
  if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/${CONFIGS[0]}" ]; then
    DOTFILES_DIR="$SCRIPT_DIR"
    info "using checkout at $DOTFILES_DIR"
    return
  fi

  if ! command -v git >/dev/null 2>&1; then
    error "git is required to download the configs but was not found."
    error "Install it with: brew install git"
    exit 1
  fi

  CLONE_DIR="$(mktemp -d)"
  info "no checkout found, cloning $REPO_URL"
  # Runs even on --dry-run: it only writes to a temporary directory, and
  # without it there would be nothing to compare against.
  git clone --depth 1 --quiet "$REPO_URL" "$CLONE_DIR"
  DOTFILES_DIR="$CLONE_DIR"
  ok "cloned to $DOTFILES_DIR (removed when the script exits)"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-deps) INSTALL_DEPS=0 ;;
      --dry-run) DRY_RUN=1 ;;
      -h|--help) usage; exit 0 ;;
      *) error "unknown option: $1"; usage; exit 1 ;;
    esac
    shift
  done
}

check_os() {
  local os
  os="$(uname -s)"

  case "$os" in
    Darwin)
      info "macOS detected ($(uname -m))"
      ;;
    Linux)
      error "Linux is not supported yet."
      error "This installer only handles macOS (Darwin) at the moment."
      exit 1
      ;;
    *)
      error "Unsupported operating system: $os"
      exit 1
      ;;
  esac
}

check_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    ok "homebrew found at $(command -v brew)"
    return 0
  fi

  error "Homebrew is not installed."
  error 'Install it first with:'
  error '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
}

install_deps() {
  info "installing dependencies"

  local pkg
  for pkg in "${BREW_FORMULAE[@]}"; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
      ok "$pkg already installed"
    else
      info "brew install $pkg"
      run brew install "$pkg"
    fi
  done

  for pkg in "${BREW_CASKS[@]}"; do
    if brew list --cask "$pkg" >/dev/null 2>&1; then
      ok "$pkg already installed"
    else
      info "brew install --cask $pkg"
      run brew install --cask "$pkg"
    fi
  done
}

install_asdf_plugins() {
  info "registering asdf plugins"

  if ! command -v asdf >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
      warn "asdf is not on PATH (it would have been installed above), skipping plugins"
      return 0
    fi
    error "asdf was installed but is not on PATH, cannot add the plugins."
    error "Open a new shell and run this script again."
    exit 1
  fi

  local installed entry name url
  installed="$(asdf plugin list 2>/dev/null || true)"

  for entry in "${ASDF_PLUGINS[@]}"; do
    name="${entry%% *}"
    url="${entry#* }"

    if printf '%s\n' "$installed" | grep -qx "$name"; then
      ok "asdf plugin $name already added"
    else
      info "asdf plugin add $name"
      run asdf plugin add "$name" "$url"
    fi
  done

  info "no runtime version is installed: use 'asdf install <plugin> <version>'"
}

# Returns 0 when $2 is already an exact copy of the directory $1.
config_is_current() {
  local src="$1" dest="$2"

  # A symlink is not a copy: a previous symlink-based install must be replaced.
  [ -L "$dest" ] && return 1
  [ -d "$dest" ] || return 1

  diff -r "$src" "$dest" >/dev/null 2>&1
}

install_configs() {
  info "copying configs to $CONFIG_DIR"

  run mkdir -p "$CONFIG_DIR"

  local name src dest
  for name in "${CONFIGS[@]}"; do
    src="$DOTFILES_DIR/$name"
    dest="$CONFIG_DIR/$name"

    if [ ! -d "$src" ]; then
      warn "$name not found in $DOTFILES_DIR, skipping"
      continue
    fi

    if config_is_current "$src" "$dest"; then
      ok "$name already up to date"
      continue
    fi

    # Only back up when there is something different to lose.
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      info "backing up $dest -> $dest.$BACKUP_SUFFIX"
      run mv "$dest" "$dest.$BACKUP_SUFFIX"
    fi

    run cp -R "$src" "$dest"
    ok "$name -> $dest"
  done
}

install_home_files() {
  info "copying shell files to $HOME"

  local entry src dest
  for entry in "${HOME_FILES[@]}"; do
    src="$DOTFILES_DIR/${entry%%:*}"
    dest="$HOME/${entry##*:}"

    if [ ! -f "$src" ]; then
      warn "${entry%%:*} not found in $DOTFILES_DIR, skipping"
      continue
    fi

    # A symlink is not a copy, so it must be replaced even when it resolves to
    # an identical file.
    if [ ! -L "$dest" ] && cmp -s "$src" "$dest"; then
      ok "${entry##*:} already up to date"
      continue
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
      info "backing up $dest -> $dest.$BACKUP_SUFFIX"
      run mv "$dest" "$dest.$BACKUP_SUFFIX"
    fi

    run cp "$src" "$dest"
    ok "${entry%%:*} -> $dest"
  done
}

main() {
  parse_args "$@"

  [ "$DRY_RUN" -eq 1 ] && warn "dry-run: no changes will be made"

  check_os

  # Dependencies come first so that git is available to resolve_dotfiles.
  if [ "$INSTALL_DEPS" -eq 1 ]; then
    check_homebrew
    install_deps
    install_asdf_plugins
  else
    info "skipping dependencies (--no-deps)"
  fi

  resolve_dotfiles
  install_configs
  install_home_files

  info "done"
  info "open a new shell to pick up the asdf shims"
  info "open nvim once to let lazy.nvim bootstrap the plugins"
}

main "$@"
