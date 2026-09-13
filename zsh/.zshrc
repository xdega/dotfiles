# =========================
# Homebrew (FIRST)
# =========================
eval "$(/Users/liam/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"

# =========================
# Ruby (rbenv)
# =========================
export RBENV_ROOT="$HOME/.rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

# =========================
# Python (pyenv)
# =========================
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# =========================
# Oh My Zsh
# =========================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# =========================
# Aliases & Functions
# =========================
alias dev="cd ~/Development"

function githubUserInfo() {
  curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $1" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/user
}

# =========================
# Flutter
# =========================
export PATH="$PATH:/Users/liam/Development/Scripts/flutter/bin"
export PATH="$PATH:$HOME/.pub-cache/bin"

# =========================
# Bun
# =========================
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# =========================
# NVM
# =========================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# =========================
# PI Coding Agent Alias
# =========================
_pi_quote_wrap() {
  if [[ $BUFFER == ,\ * ]]; then
    local instruction=${BUFFER#, }
    BUFFER="pi ${(qq)instruction}"
  fi
  zle .accept-line
}
zle -N accept-line _pi_quote_wrap
