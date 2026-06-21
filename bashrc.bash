source ~/repo/dotfiles/utils/prompt_git_commit.sh
source ~/repo/dotfiles/utils/prompt_ts_type.sh
source ~/repo/dotfiles/utils/copy_green_ps1.sh
source ~/repo/dotfiles/utils/yazi.sh

alias la="ls -a"
alias ll="ls -l"
alias lla="ls -la"
alias t="tmux"
alias v="lazygit"
alias n="nvim"
alias rgctags="rg --files | ctags -R --links=no -L -"

alias dr="docker run --rm -v .:/app -w /app -it --network host" # [D]ocker [R]un
alias drp="docker run -v .:/app -w /app -it --network host" # [D]ocker [R]un [P]ersistent

export VISUAL=nvim
export EDITOR="$VISUAL"

PATH=$PATH:/usr/local/bin
PATH=$PATH:~/.local/bin
PATH=/home/linuxbrew/.linuxbrew/bin:$PATH

HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

if [ -f "$(command -v fzf)" ]; then
  eval "$(fzf --bash)"

  # Ctrl+G - rg live-grep via fzf, copies file path to clipboard via xsel
  fzf-live-grep() {
    local file
    file=$(rg --line-number --column --no-heading --smart-case . 2>/dev/null |
      fzf --ansi \
          --delimiter=: \
          --preview='printf "\033[1;36m%s\033[0m\n\n" "{1}" && bat --style=numbers --color=always --highlight-line={2} {1}' \
          --preview-window='right:60%:wrap,+{2},~2' \
          --bind='enter:become(echo {1}:{2})' \
          --bind='alt-enter:become(echo $(realpath {1}):{2})' \
          --bind='alt-c:execute(code --goto {1}:{2})+abort')
    if [[ -n "$file" ]]; then
      printf '%s' "$file" | xsel -ib
    fi
  }

  bind -x '"\C-g": fzf-live-grep'
fi

if [ -f "$(command -v zoxide)" ]; then
  eval "$(zoxide init bash)"
fi

if [ -f "$(command -v fnm)" ]; then
  eval "$(fnm env --use-on-cd --shell bash)"
fi

if [ -f "$(command -v pyenv)" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init - bash)"
fi

PS1="$PS1\n> "
