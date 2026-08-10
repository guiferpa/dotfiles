#!/usr/bin/env bash
#
# dotfiles installer
#
# Copies the configs from this repository into ~/.config and installs the
# dependencies they need. macOS only for now.
#
# Usage:
#   ./install.sh              # install everything
#   ./install.sh --no-deps    # only copy the configs
#   ./install.sh --dry-run    # show what would happen, change nothing

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_SUFFIX="backup.$(date +%Y%m%d%H%M%S)"

INSTALL_DEPS=1
DRY_RUN=0

# Configs shipped by this repo. Each one is copied to $CONFIG_DIR/<name>.
CONFIGS=(nvim rio htop)

# Homebrew formulae:
#   neovim            the editor itself
#   ripgrep, fd       telescope live_grep / find_files
#   htop              process viewer
#   git, curl         lazy.nvim plugin manager
#   node, go, python  runtimes for the LSPs installed by Mason
#                     (ts_ls, gopls, pylsp; lua_ls and clojure_lsp ship binaries)
BREW_FORMULAE=(neovim ripgrep fd htop git curl node go python)

# Homebrew casks
BREW_CASKS=(rio)

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
EOF
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

main() {
  parse_args "$@"

  info "dotfiles: $DOTFILES_DIR"
  [ "$DRY_RUN" -eq 1 ] && warn "dry-run: no changes will be made"

  check_os

  if [ "$INSTALL_DEPS" -eq 1 ]; then
    check_homebrew
    install_deps
  else
    info "skipping dependencies (--no-deps)"
  fi

  install_configs

  info "done"
  info "open nvim once to let lazy.nvim bootstrap the plugins"
}

main "$@"
