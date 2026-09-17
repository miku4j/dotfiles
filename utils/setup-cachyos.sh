#!/usr/bin/env bash
# CachyOS desktop bootstrap.
#
# Automates a fresh CachyOS (Arch-based) desktop setup: Determinate Nix,
# system packages, AUR helper (yay), dotfiles, nvim, bash config and kanata.
# Idempotent: safe to re-run.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/miku4j/dotfiles/main/utils/setup-cachyos.sh | sudo bash -s -- --update
#   sudo ./utils/setup-cachyos.sh [--update] [--dry-run] [--skip-kanata] [--user <name>]
#
# Environment overrides:
#   DOTFILES_URL, NVIM_URL, GIT_NAME, GIT_EMAIL

set -euo pipefail

# === Config (env-overridable) ===
DOTFILES_URL="${DOTFILES_URL:-https://github.com/miku4j/dotfiles}"
NVIM_URL="${NVIM_URL:-https://github.com/miku4j/nvim}"
GIT_NAME="${GIT_NAME:-miku4j}"
GIT_EMAIL="${GIT_EMAIL:-ahmaddwi700@gmail.com}"
PACKAGES=(neovim tree-sitter-cli xsel wl-clipboard zip unzip dos2unix ripgrep github-cli fzf zoxide lazygit yazi tmux bat fuse3 base-devel git rate-mirrors wezterm ttf-jetbrains-mono-nerd docker docker-buildx docker-compose lazydocker chromium nodejs npm)

# === Flags ===
UPDATE=0
DRY_RUN=0
SKIP_KANATA=0
TARGET_USER=""

usage() {
  cat <<'EOF'
Usage: sudo ./setup-cachyos.sh [options]

Automates the CachyOS desktop setup (nix, packages, yay, dotfiles, kanata).

Options:
  --update          Run pacman -Syu first (default: no)
  --dry-run, -n     Print what would change without changing anything
  --skip-kanata     Do not install/configure kanata
  --user <name>     Target user (default: $SUDO_USER or uid-1000 user)
  -h, --help        Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --update) UPDATE=1 ;;
    --dry-run|-n) DRY_RUN=1 ;;
    --skip-kanata) SKIP_KANATA=1 ;;
    --user) TARGET_USER="${2:?--user requires a value}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

log()  { printf '\033[1;34m[setup]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ ok ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
run()  { if [[ "$DRY_RUN" -eq 1 ]]; then log "[dry] $*"; else "$@"; fi; }

# === Root + user resolution ===
if [[ $EUID -ne 0 ]]; then
  echo "error: run as root (e.g. sudo ./setup-cachyos.sh)" >&2
  exit 1
fi

if [[ -z "$TARGET_USER" ]]; then
  if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    TARGET_USER="$SUDO_USER"
  else
    TARGET_USER="$(getent passwd | awk -F: '$3>=1000 && $3<60000 {print $1; exit}')"
  fi
fi

if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  echo "error: could not determine target user (use --user <name>)" >&2
  exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [[ -z "$TARGET_HOME" ]]; then
  echo "error: no such user: $TARGET_USER" >&2
  exit 1
fi
REPO_DIR="$TARGET_HOME/repo/dotfiles"

as_user() { runuser -u "$TARGET_USER" -- bash -c "$1"; }
as_user_run() { if [[ "$DRY_RUN" -eq 1 ]]; then log "[dry] (as $TARGET_USER) $1"; else runuser -u "$TARGET_USER" -- bash -c "$1"; fi; }

# === Steps ===

install_nix() {
  if [[ -x /nix/var/nix/profiles/default/bin/nix ]]; then
    ok "Determinate Nix already installed"
  else
    log "Installing Determinate Nix..."
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "[dry] curl -fsSL https://install.determinate.systems/nix | sh -s -- install linux --no-confirm"
    else
      curl -fsSL https://install.determinate.systems/nix | sh -s -- install linux --no-confirm
    fi
  fi
  # The installer runs as root, so it modifies root's shells only.
  # Wire the target user's shells to the nix profile instead.
  local bashrc="$TARGET_HOME/.bashrc"
  if grep -qF "# >>> cachyos-setup: nix >>>" "$bashrc" 2>/dev/null; then
    ok "bashrc already loads nix"
  else
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "[dry] append nix block to $bashrc"
    else
      cat >> "$bashrc" <<'EOF'

# >>> cachyos-setup: nix >>>
# nix (determinate)
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
# <<< cachyos-setup: nix <<<
EOF
    fi
    ok "bashrc now loads nix"
  fi
}

update_system() {
  log "Running pacman -Syu..."
  run pacman -Syu --noconfirm
}

install_packages() {
  log "Installing system packages..."
  run pacman -S --needed --noconfirm "${PACKAGES[@]}"
  ok "system packages installed"
}

setup_docker() {
  log "Setting up docker..."
  run systemctl enable docker.service >/dev/null 2>&1 || true
  if systemctl is-active docker.service >/dev/null 2>&1; then
    ok "docker running"
  else
    run systemctl start docker.service 2>/dev/null || warn "docker failed to start; check: journalctl -u docker"
  fi
  if id -nG "$TARGET_USER" 2>/dev/null | grep -qw docker; then
    ok "$TARGET_USER already in docker group"
  else
    run usermod -aG docker "$TARGET_USER"
    warn "added $TARGET_USER to docker group; re-login to apply"
  fi
}

setup_git() {
  if [[ -n "$(as_user 'git config --global user.name' 2>/dev/null || true)" ]]; then
    ok "git config already set"
  else
    as_user_run "git config --global user.name \"$GIT_NAME\""
    as_user_run "git config --global user.email \"$GIT_EMAIL\""
    ok "git config set ($GIT_NAME <$GIT_EMAIL>)"
  fi
}

clone_dotfiles() {
  if [[ -d "$REPO_DIR/.git" ]]; then
    ok "dotfiles already cloned"
  else
    log "Cloning dotfiles..."
    as_user_run "mkdir -p \"$TARGET_HOME/repo\" && git clone \"$DOTFILES_URL\" \"$REPO_DIR\""
    ok "dotfiles cloned"
  fi
}

clone_nvim() {
  local nvim_dir="$TARGET_HOME/.config/nvim"
  if [[ -d "$nvim_dir/.git" ]]; then
    ok "nvim config already cloned"
  else
    log "Cloning nvim config..."
    as_user_run "git clone \"$NVIM_URL\" \"$nvim_dir\""
    ok "nvim config cloned"
  fi
}

install_aur_pkg() {
  local pkg="$1" bin="$2"
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$pkg already installed"
    return 0
  fi
  log "Installing $pkg from AUR (builds as $TARGET_USER)..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry] build $pkg with makepkg as $TARGET_USER + pacman -U"
    return 0
  fi
  as_user_run 'mkdir -p "$HOME/.cache/cachyos-setup"'
  local builddir
  builddir="$(runuser -u "$TARGET_USER" -- bash -c 'mktemp -d "$HOME/.cache/cachyos-setup/'"$pkg"'.XXXXXX')"
  runuser -u "$TARGET_USER" -- bash -c "cd '$builddir' && git clone https://aur.archlinux.org/$pkg.git . && makepkg -s --noconfirm"
  local pkgfile
  pkgfile="$(ls "$builddir"/*.pkg.tar.zst 2>/dev/null | head -1)"
  if [[ -z "$pkgfile" ]]; then
    echo "error: no built package found for $pkg in $builddir" >&2
    exit 1
  fi
  run pacman -U --noconfirm "$pkgfile"
  run rm -rf "$builddir"
  ok "$pkg installed"
}

setup_symlinks() {
  log "Setting up symlinks..."
  as_user_run "ln -sfn \"$REPO_DIR/.tmux.conf\" \"$TARGET_HOME/.tmux.conf\""
  for link in yazi opencode; do
    local target="$TARGET_HOME/.config/$link"
    if [[ -e "$target" && ! -L "$target" ]]; then
      warn "removing existing directory $target"
      run rm -rf "$target"
    fi
    as_user_run "ln -sfn \"$REPO_DIR/$link\" \"$target\""
  done
  as_user_run 'mkdir -p "$HOME/.config/wezterm"'
  as_user_run "ln -sfn \"$REPO_DIR/wezterm/wezterm.lua\" \"$TARGET_HOME/.config/wezterm/wezterm.lua\""
  ok "symlinks created"
}

setup_bashrc() {
  local line="source $REPO_DIR/.bashrc"
  if grep -qF "repo/dotfiles/.bashrc" "$TARGET_HOME/.bashrc" 2>/dev/null; then
    ok "bashrc already sources dotfiles"
  else
    as_user_run "echo \"$line\" >> \"\$HOME/.bashrc\""
    ok "bashrc now sources dotfiles"
  fi
  # ponytail: chsh only, no fish cleanup — delete ~/.config/fish manually if you hate it
  if [[ "$(getent passwd "$TARGET_USER" | cut -d: -f7)" != */bash ]]; then
    log "Setting bash as default shell for $TARGET_USER..."
    run chsh -s /bin/bash "$TARGET_USER"
    ok "default shell is now bash"
  else
    ok "default shell already bash"
  fi
}

setup_kanata() {
  if [[ "$SKIP_KANATA" -eq 1 ]]; then
    log "Skipping kanata (--skip-kanata)"
    return 0
  fi
  log "Setting up kanata..."
  install_aur_pkg kanata-bin kanata
  as_user_run 'mkdir -p "$HOME/.local/bin" && ln -sfn /usr/bin/kanata "$HOME/.local/bin/kanata"'
  # Generate the service from the repo template, fixing the hardcoded home path.
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry] write /etc/systemd/system/kanata.service from $REPO_DIR/kanata.service (home=$TARGET_HOME)"
  else
    sed "s|/home/miku4j|$TARGET_HOME|g" "$REPO_DIR/kanata.service" > /etc/systemd/system/kanata.service
  fi
  run systemctl daemon-reload
  run systemctl enable kanata >/dev/null 2>&1 || true
  if systemctl is-active kanata >/dev/null 2>&1; then
    ok "kanata running"
  else
    run systemctl start kanata 2>/dev/null || warn "kanata failed to start; check: journalctl -u kanata"
  fi
}

summary() {
  echo
  log "Setup complete! Remaining manual steps:"
  echo "  - gh auth login          (GitHub auth, interactive)"
  echo "  - opencode auth login    (opencode provider auth, if used)"
  echo
  log "Verification:"
  as_user 'for c in nvim lazygit yazi tmux bat fzf zoxide gh rg yay nix wezterm wl-copy docker; do command -v "$c" >/dev/null 2>&1 && echo "  ok: $c"; done' || true
  echo "  docker: $(systemctl is-active docker.service 2>/dev/null || echo missing) / buildx: $(docker buildx version 2>/dev/null || echo missing)"
  echo "  symlinks:"
  ls -la "$TARGET_HOME/.tmux.conf" "$TARGET_HOME/.config/yazi" "$TARGET_HOME/.config/opencode" "$TARGET_HOME/.config/wezterm/wezterm.lua" 2>/dev/null || true
  echo "  shell: $(getent passwd "$TARGET_USER" | cut -d: -f7)"
  if [[ "$SKIP_KANATA" -eq 0 ]]; then
    echo "  kanata: $(systemctl is-active kanata 2>/dev/null || echo missing)"
  fi
}

main() {
  log "Target user: $TARGET_USER ($TARGET_HOME)"
  [[ "$DRY_RUN" -eq 1 ]] && log "DRY RUN: no changes will be made"
  install_nix
  [[ "$UPDATE" -eq 1 ]] && update_system
  install_packages
  setup_docker
  setup_git
  clone_dotfiles
  clone_nvim
  install_aur_pkg yay-bin yay
  install_aur_pkg google-chrome google-chrome-stable
  setup_symlinks
  setup_bashrc
  setup_kanata
  summary
}

main
