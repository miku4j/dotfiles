### Arch WSL (Official)
```bash

# sh
passwd
pacman -Syu sudo neovim
useradd -m -G wheel -s /bin/bash miku4j
passwd miku4j
EDITOR=nvim visudo # uncomment the wheel
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8 UTF-8" > /etc/locale.conf

# cmd
wsl --manage archlinux --set-default-user miku4j

# sh
sudo pacman -S rate-mirrors
rate-mirrors --protocol=https arch | sudo tee /etc/pacman.d/mirrorlist

sudo pacman -S fuse3 git base-devel xsel zip unzip ripgrep github-cli fzf zoxide lazygit yazi tmux bat dos2unix

curl -fsSL https://install.determinate.systems/nix | sh -s -- install

git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si
cd ~ && rm -rf yay-bin

git config --global user.name "miku4j"
git config --global user.email "ahmaddwi700@gmail.com"

git clone https://github.com/miku4j/dotfiles ~/repo/dotfiles

mkdir .config
ln -s $(pwd)/repo/dotfiles/.tmux.conf $(pwd)/.tmux.conf
ln -s ~/repo/dotfiles/yazi ~/.config/yazi
ln -s ~/repo/dotfiles/opencode ~/.config/opencode
mkdir -p ~/.config/wezterm && ln -s ~/repo/dotfiles/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua
mkdir -p ~/.pi/agent
ln -s ~/repo/dotfiles/pi/settings.json ~/.pi/agent/settings.json
ln -s ~/repo/dotfiles/pi/models.json ~/.pi/agent/models.json
ln -s ~/repo/dotfiles/pi/AGENTS.md ~/.pi/agent/AGENTS.md
ln -s ~/repo/dotfiles/pi/extensions ~/.pi/agent/extensions
echo "source ~/repo/dotfiles/.bashrc" >> ~/.bashrc

# for nvim
sudo pacman -S tree-sitter-cli
git clone https://github.com/miku4j/nvim ~/.config/nvim
nvim # to install the nvim deps

# docker
sudo pacman -S docker docker-compose lazydocker
sudo usermod -aG docker miku4j
sudo systemctl enable --now docker

gh auth login
```

### CachyOS (desktop, bash)
Fresh installs are automated by `utils/setup-cachyos.sh` (idempotent, run as root). It installs Determinate Nix, system packages, `yay`, Google Chrome, dotfiles/nvim, bash config and kanata.

```bash
# from the web (before the repo exists)
curl -fsSL https://raw.githubusercontent.com/miku4j/dotfiles/main/utils/setup-cachyos.sh | sudo bash -s -- --update

# or from an existing clone
sudo ./utils/setup-cachyos.sh [--update] [--skip-kanata] [--user <name>]
```

Manual leftovers afterwards: `gh auth login`, `opencode auth login`.
