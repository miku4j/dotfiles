alias la="ls -a"
alias ll="ls -l"
alias lla="ls -la"
alias t="tmux"
alias v="lazygit"
alias n="nvim"

export VISUAL=nvim
export EDITOR="$VISUAL"
export PAGER=bat

PATH=$PATH:~/.local/bin

HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000

eval "$(zoxide init bash)"
eval "$(fzf --bash)"
eval "$(mise activate bash)"

PS1="$PS1\n> "

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
