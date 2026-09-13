#!/usr/bin/env bash
#
# install.sh — one-shot bootstrap for these dotfiles.
#
#   1. Installs shell/editor dependencies and shared development tooling —
#      see scripts/install_deps.sh.
#   2. Backs up any existing dotfiles that would conflict, then symlinks
#      every package into $HOME via GNU Stow — see scripts/stow_link.sh.
#   3. Installs Vim plugins headlessly via vim-plug.
#
# Safe to re-run any time (e.g. after `git pull`) — every step is
# idempotent.
#
# Usage:
#   ./install.sh              # install deps + stow everything
#   ./install.sh --no-deps    # skip dependency installation, just (re)stow
#   ./install.sh vim zsh      # only stow specific packages (deps still run
#                              # unless --no-deps is also given)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

info() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

SKIP_DEPS=0
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--no-deps" ]; then
    SKIP_DEPS=1
  else
    ARGS+=("$arg")
  fi
done

if [ "$SKIP_DEPS" = 0 ]; then
  info "Step 1/3: installing dependencies"
  ./scripts/install_deps.sh
else
  info "Step 1/3: skipped (--no-deps)"
fi

info "Step 2/3: linking dotfiles with GNU Stow"
./scripts/stow_link.sh "${ARGS[@]}"

info "Step 3/3: installing Vim plugins"
if command -v vim >/dev/null 2>&1 && [ -f "$HOME/.vimrc" ]; then
  vim +PlugInstall +qall || info "Vim plugin install failed or was skipped — run ':PlugInstall' manually inside vim."
else
  info "Vim/.vimrc not found yet — run ':PlugInstall' manually inside vim after this finishes."
fi

info "All set. Restart your terminal (or open a new Warp tab) to pick everything up."
