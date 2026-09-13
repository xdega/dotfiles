#!/usr/bin/env bash
#
# install_deps.sh — installs everything these dotfiles assume is present:
#   Homebrew, GNU Stow, Warp, Vim, nvm (+ Node/npm), pi, oh-my-zsh, vim-plug,
#   and the shared command-line tools used for iOS and Supabase development.
#
# Safe to re-run: every step checks whether its target is already installed
# before doing anything.

set -euo pipefail

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
skip()  { printf '\033[1;30m  - already present, skipping:\033[0m %s\n' "$*"; }

# --- Homebrew ---------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Put brew on PATH for the rest of this script (Apple Silicon vs Intel prefix).
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  skip "Homebrew"
fi

# --- GNU Stow ----------------------------------------------------------------
if ! command -v stow >/dev/null 2>&1; then
  info "Installing GNU Stow"
  brew install stow
else
  skip "GNU Stow"
fi

# --- Warp ----------------------------------------------------------------
if ! brew list --cask warp >/dev/null 2>&1 && [ ! -d "/Applications/Warp.app" ]; then
  info "Installing Warp"
  brew install --cask warp
else
  skip "Warp"
fi

# --- Vim -----------------------------------------------------------------
if ! command -v vim >/dev/null 2>&1; then
  info "Installing Vim"
  brew install vim
else
  skip "Vim"
fi

# --- Development command-line tools ----------------------------------------
for tool in gh jq swiftformat swiftlint xcodegen; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    info "Installing $tool"
    brew install "$tool"
  else
    skip "$tool"
  fi
done

if ! brew list --cask docker-desktop >/dev/null 2>&1 \
  && [ ! -d "/Applications/Docker.app" ]; then
  info "Installing Docker Desktop"
  brew install --cask docker-desktop
else
  skip "Docker Desktop"
fi

# Supabase releases independently of projects that may pin an older CLI.
# Install the global CLI for convenience; projects should use their documented
# npx fallback whenever this version differs from their required version.
if ! command -v supabase >/dev/null 2>&1; then
  info "Installing Supabase CLI"
  brew install supabase/tap/supabase
else
  skip "Supabase CLI"
fi

# --- oh-my-zsh -------------------------------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing oh-my-zsh"
  # --unattended: don't drop into a new shell or prompt for anything.
  # KEEP_ZSHRC=yes: the installer would otherwise overwrite ~/.zshrc; stow
  # manages that file, so keep whatever is currently there and let the
  # stow step below replace it with the symlinked version.
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  skip "oh-my-zsh"
fi

# --- nvm, Node, npm ----------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  info "Installing nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash
else
  skip "nvm"
fi
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
if command -v nvm >/dev/null 2>&1; then
  if ! nvm ls --no-colors default >/dev/null 2>&1; then
    info "Installing latest LTS Node (+ npm) via nvm"
    nvm install --lts
    nvm alias default 'lts/*'
  else
    skip "Node/npm (default nvm alias already set)"
  fi
fi

# --- pi ----------------------------------------------------------------------
if ! command -v pi >/dev/null 2>&1; then
  info "Installing pi"
  curl -fsSL https://pi.dev/install.sh | sh
else
  skip "pi"
fi

# --- vim-plug ------------------------------------------------------------
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  info "Installing vim-plug"
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
else
  skip "vim-plug"
fi

info "All automated dependencies installed."
info "Manual setup may still be required for Xcode/iOS runtimes, Docker's first launch, and tool authentication."
