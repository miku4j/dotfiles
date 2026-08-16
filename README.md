### Arch WSL
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

curl https://mise.run | sh

git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si
cd ~ && rm -rf yay-bin

git config --global user.name "miku4j"
git config --global user.email "ahmaddwi700@gmail.com"

git clone https://github.com/miku4j/dotfiles ~/repo/dotfiles

ln -s $(pwd)/repo/dotfiles/.tmux.conf $(pwd)/.tmux.conf
ln -s ~/repo/dotfiles/yazi ~/.config/yazi
ln -s ~/repo/dotfiles/opencode ~/.config/opencode
echo "source ~/repo/dotfiles/.bashrc" >> ~/.bashrc

# for nvim
git clone https://github.com/miku4j/nvim ~/.config/nvim
mise use -g tree-sitter node go

# docker
sudo pacman -S docker docker-compose lazydocker
sudo usermod -aG docker miku4j

gh auth login
```
