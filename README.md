### arch wsl
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

sudo pacman -S fuse3 less git base-devel dua-cli xsel zip unzip ripgrep github-cli fzf zoxide lazygit yazi tmux
git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si
cd ~ && rm -rf yay-bin

git config --global user.name "miku4j"
git config --global user.email "ahmaddwi700@gmail.com"
git clone https://github.com/ahmaddynugroho/dotfiles ~/repo/dotfiles
git clone https://github.com/ahmaddynugroho/nvim ~/.config/nvim
ln -s $(pwd)/repo/dotfiles/.tmux.conf $(pwd)/.tmux.conf
ln -s ~/repo/dotfiles/yazi ~/.config/yazi
ln -s ~/repo/dotfiles/opencode ~/.config/opencode
echo "source ~/repo/dotfiles/bashrc.bash" >> ~/.bashrc

gh auth login
```

### ubuntu wsl (brew)
```bash
sudo apt update
sudo add-apt-repository universe # for libfuse2 for running .appimage
sudo apt install libfuse2 build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev # libssl etc is for pyenv

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo >> /home/miku4j/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/miku4j/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

brew install gcc

brew install xsel zip unzip rg gh bat fzf zoxide lazygit fnm nvim yazi tmux pyenv fd

fnm i 22
fnm default 22

pyenv install 3.10
pyenv global 3.10

python -m pip install aider-install
aider-install

gh auth login

git config --global user.name "miku4j"
git config --global user.email "ahmaddwi700@gmail.com"
git clone https://github.com/ahmaddynugroho/dotfiles ~/repo/dotfiles
git clone https://github.com/ahmaddynugroho/nvim ~/.config/nvim

ln -s $(pwd)/repo/dotfiles/.tmux.conf $(pwd)/.tmux.conf
echo "source ~/repo/dotfiles/bashrc.bash" >> ~/.bashrc
cp ~/repo/dotfiles/.aider.conf.yml ~
```

### fedora wsl

```bash
# install utilities
dnf install tmux fzf zoxide nvim ripgrep bat xsel gh python3-pip podman

sudo dnf copr enable atim/lazygit -y
sudo dnf install lazygit

curl -fsSL https://fnm.vercel.app/install | bash
fnm i 22

dnf copr enable lihaohong/yazi
dnf install yazi

python -m pip install aider-install
aider-install

# setup
gh auth login
git config --global user.name "miku4j"
git config --global user.email "ahmaddwi700@gmail.com"
git clone https://github.com/ahmaddynugroho/dotfiles ~/repo/dotfiles
git clone https://github.com/ahmaddynugroho/nvim ~/.config/nvim

ln -s $(pwd)/repo/dotfiles/.tmux.conf $(pwd)/.tmux.conf
echo "source ~/repo/dotfiles/bashrc.bash" >> ~/.bashrc
```

### Fedora KDE (DO NOT USE GNOME)
```bash
# install kanata
# https://github.com/jtroo/kanata/releases
mkdir ~/.local/bin
curl -Lo ~/.local/bin/kanata https://github.com/jtroo/kanata/releases/download/v1.8.1/kanata
chmod 755 ~/.local/bin/kanata

# install utilities
dnf install fzf zoxide nvim ripgrep bat xsel gh python3-pip

sudo dnf copr enable atim/lazygit -y
sudo dnf install lazygit

curl -fsSL https://fnm.vercel.app/install | bash
fnm i 22

bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"

python -m pip install aider-install
aider-install

# setup
gh auth login
git config --global user.name "miku4j"
git config --global user.email "ahmaddwi700@gmail.com"
git clone https://github.com/ahmaddynugroho/dotfiles ~/repo/dotfiles
git clone https://github.com/ahmaddynugroho/nvim ~/.config/nvim

ln -s $(pwd)/repo/dotfiles/.tmux.conf $(pwd)/.tmux.conf
ln -s $(pwd)/repo/dotfiles/.wezterm.lua $(pwd)/.wezterm.lua
echo "source ~/repo/dotfiles/bashrc.bash" >> ~/.bashrc

cp ~/repo/dotfiles/kanata.service /etc/systemd/system/
sudo systemctl enable kanata
sudo systemctl start kanata

mkdir -p ~/.local/share/fonts
curl -Lo ~/.local/share/fonts/firacode.tar.xz https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.tar.xz
tar xvf ~/.local/share/fonts/firacode.tar.xz -C ~/.local/share/fonts
rm ~/.local/share/fonts/firacode.tar.xz

```

### Ubuntu WSL

```bash
# install kanata
# https://github.com/jtroo/kanata/releases

# dependencies
sudo apt update
sudo add-apt-repository universe # for libfuse2 for running .appimage
sudo apt install xsel zip unzip libfuse2 build-essential ripgrep gh bat

# setup git
gh auth login
git config --global user.name "ahmaddynugroho"
git config --global user.email "ahmaddwi700@gmail.com"

# install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# install zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# install lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin

# setup fnm for neovim dependencies
curl -fsSL https://fnm.vercel.app/install | bash
fnm install 22

# get neovim from https://github.com/neovim/neovim/releases/
git clone https://github.com/ahmaddynugroho/nvim ~/.config/nvim

# get lf from https://github.com/gokcehan/lf/releases

# setup dotfile
cd ~
mkdir repo
cd repo
git clone https://github.com/ahmaddynugroho/dotfiles
cd ~
ln -s $(pwd)/repo/dotfiles/.tmux.conf $(pwd)/.tmux.conf
echo "source ~/repo/dotfiles/bashrc.bash" >> ~/.bashrc
```
