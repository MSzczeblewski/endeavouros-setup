#!/bin/bash

if [ "$(id -u)" = 0 ]; then
    echo ":: This script shouldn't be run as root."
    exit 1
fi

clear
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NONE='\033[0m'

# -----------------------------------------------------
# functions
# -----------------------------------------------------

# check if package is installed
_isInstalledPacman() {
    package="$1";
    check="$(sudo pacman -Qs --color always "${package}" | grep "local" | grep "${package} ")";
    if [ -n "${check}" ] ; then
        echo 0; #'0' means 'true' in Bash
        return; #true
    fi;
    echo 1; #'1' means 'false' in Bash
    return; #false
}

# install required packages
_installPackagesPacman() {
    toInstall=();
    for pkg; do
        if [[ $(_isInstalledPacman "${pkg}") == 0 ]]; then
            echo "${pkg} is already installed.";
            continue;
        fi;
        toInstall+=("${pkg}");
    done;
    if [[ "${toInstall[@]}" == "" ]] ; then
        # echo "All pacman packages are already installed.";
        return;
    fi;
    printf "Package not installed:\n%s\n" "${toInstall[@]}";
    sudo pacman --noconfirm -S "${toInstall[@]}";
}


# required packages for the installer
installer_packages=(
    "wget"
    "unzip"
    "gum"
    "figlet"
)

_copyDotfiles() {
    echo "TEST GOOD"
    cp -rfv ./config/.gtkrc-2.0 ./config/.Xresources ./config/.bashrc ./config/.zshrc ./config/.p10k.zsh ~/
    mkdir -p ~/.config/qBittorrent && cp -rf ./config/qbittorrent/qbittorrent.qbtheme ~/.config/qBittorrent
    cp -rfv ./config/alacritty ./config/dunst ./config/gtk-3.0 ./config/gtk-4.0 ./config/picom \
        ./config/kitty ./config/scripts ./config/Thunar ./config/wal ./config/waybar \
        ./config/wlogout ./config/fastfetch \
        ~/.config
    cp -rfv ./config/hypr/hypr* ~./config/hypr/
    rsync -av --exclude="monitor.conf" ./config/hypr/conf/ ~/.config/hypr/conf/
    #Only copy some configs. Don't want to overwrite monitors

    echo "TEST GOOD"
}

# Install or Update
_chooseMode() {
    echo -e "${PURPLE}"
    figlet "Choose Mode"
    echo -e "${NONE}"

    ACTION=$(gum choose "Install" "Copy dotfiles" "Quit")

    case $ACTION in
        "Install")
            echo "You chose to install dotfiles."
            # Continue the rest of the script after this case
            ;;
        "Copy dotfiles")
            echo "You chose to copy dotfiles."
            _copyDotfiles
            exit 0
            ;;
        "Quit")
            exit 1
            ;;
        *)
            echo "Invalid selection."
            exit 1
            ;;
    esac
}

# -----------------------------------------------------
# START HERE 
# -----------------------------------------------------
# -----------------------------------------------------
# synchronizing package databases
# -----------------------------------------------------
sudo pacman -Sy
echo

# -----------------------------------------------------
# install required packages
# -----------------------------------------------------
echo ":: Checking that required packages are installed..."
_installPackagesPacman "${installer_packages[@]}";
echo

# -----------------------------------------------------
# Install or Update 
# -----------------------------------------------------
_chooseMode

#if gum confirm "Have you checked the installation script before running?" ;then
#    echo
#    echo ":: Installing Hyprland and additional packages"
#    echo
#elif [ $? -eq 130 ]; then
#    exit 130
#else
#    echo
#    echo ":: Installation canceled."
#    exit;
#fi
#echo -e "${NONE}"

echo -e "${GREEN}"
cat <<"EOF"
 _   _                  _                 _
| | | |_   _ _ __  _ __| | __ _ _ __   __| |
| |_| | | | | '_ \| '__| |/ _` | '_ \ / _` |
|  _  | |_| | |_) | |  | | (_| | | | | (_| |
|_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|
       |___/|_|

EOF
echo -e "${NONE}"

echo "What is the resolution and refresh rate of your monitor?"
echo "Answare in the following format eg. 3440x1440@144"
resolution=$(gum input --placeholder "Resolution and refresh rate...")
echo "Resolution and refresh rate: ${resolution}"

if gum confirm "Are you using Nvidia GPU?" ;then
    nvidia=true
    echo
    echo ":: Nvidia GPU is not officially supported by Hyprland. If you face any problems, please check Hyprland Wiki"
    echo ":: https://wiki.hyprland.org/Nvidia/"
    echo
    if gum confirm "Continue?" ;then
        echo
        echo ":: Starting the installation"
        echo
    elif [ $? -eq 130 ]; then
        exit 130
    else
        echo
        echo ":: Installation canceled."
        exit;
    fi
else
    nvidia=false
fi

# make yay faster - do not use compression
sudo sed -i "s/PKGEXT=.*/PKGEXT='.pkg.tar'/g" /etc/makepkg.conf
sudo sed -i "s/SRCEXT=.*/SRCEXT='.src.tar'/g" /etc/makepkg.conf

# -----------------------------------------------------
# core packages
# -----------------------------------------------------

echo -e "${GREEN}"
figlet "CorePackages"
echo -e "${NONE}"

# packages
sudo pacman -Sy hyprland waybar rofi-wayland dunst hyprpaper hyprlock hypridle xdg-desktop-portal-hyprland sddm \
                alacritty kitty vim zsh picom qt5-wayland qt6-wayland cliphist \
                thunar gvfs thunar-volman tumbler thunar-archive-plugin ark \
                network-manager-applet blueman brightnessctl \
                slurp grim xclip swappy \
                ttf-font-awesome otf-font-awesome ttf-fira-sans ttf-fira-code   \
                ttf-firacode-nerd gnome-themes-extra gtk-engine-murrine nwg-look \
                openssh tree \
                --noconfirm
yay -S wlogout waypaper qogir-gtk-theme qogir-icon-theme --noconfirm

# oh my zsh
sh -c "$(wget https://install.ohmyz.sh -O -) --unattended"
chsh -s $(which zsh)
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/themes/powerlevel10k


# -----------------------------------------------------
# development
# -----------------------------------------------------

if gum confirm "Do you need development setup?" ;then
  # git
  echo -e "${GREEN}"
  figlet "Git"
  echo -e "${NONE}"
  git_name=$(gum input --placeholder "Enter git name...")
  echo "Name: ${git_name}"
  git_email=$(gum input --placeholder "Enter git email...")
  echo "Email: ${git_email}"
  git config --global user.name "${git_name}"
  git config --global user.email "${git_email}"
  git config --global pull.ff only
  ssh-keygen

  # java
#  echo -e "${GREEN}"
#  figlet "Java"
#  echo -e "${NONE}"
#  sudo pacman -Sy jre21-openjdk jdk21-openjdk maven --noconfirm
#  yay -S google-java-format intellij-idea-ultimate-edition --noconfirm
#
#  # python
#  echo -e "${GREEN}"
#  figlet "Python"
#  echo -e "${NONE}"
#  sudo pacman -Sy python-pip --noconfirm
#  yay -S pycharm-professional --noconfirm

  # haskell
  # echo -e "${GREEN}"
  # figlet "Haskell"
  # echo -e "${NONE}"
  # curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
  # yay -S hlint-bin --noconfirm

  # mysql
#  echo -e "${GREEN}"
#  figlet "Mysql"
#  echo -e "${NONE}"
#  sudo pacman -Sy mariadb --noconfirm
#  sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
#  sudo systemctl enable --now mariadb
#  sudo mysql_secure_installation
#  sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';"

  # postgres
#  echo -e "${GREEN}"
#  figlet "Postgres"
#  echo -e "${NONE}"
#  sudo pacman -Sy postgresql --noconfirm
#  sudo su - postgres -c "initdb -D '/var/lib/postgres/data'"
#  sudo systemctl enable --now postgresql
#  sudo psql -U postgres -c "ALTER USER postgres PASSWORD 'root';"
#
#  # redis
#  echo -e "${GREEN}"
#  figlet "Redis"
#  echo -e "${NONE}"
#  sudo pacman -Sy redis --noconfirm
#  sudo systemctl enable --now redis
#  redis-cli config set requirepass root
#
#  # node
#  echo -e "${GREEN}"
#  figlet "Node"
#  echo -e "${NONE}"
#  yay -S nvm --noconfirm
#  source /usr/share/nvm/init-nvm.sh
#  nvm install --lts
#
#  # docker
#  echo -e "${GREEN}"
#  figlet "Docker"
#  echo -e "${NONE}"
#  sudo pacman -Sy docker --noconfirm
#  sudo systemctl enable --now docker.service
#  sudo usermod -aG docker $USER
#  sudo pacman -Sy docker-compose --noconfirm
#
#  # vscode
#  echo -e "${GREEN}"
#  figlet "VSCode"
#  echo -e "${NONE}"
#  sudo pacman -Sy gnome-keyring --noconfirm
#  yay -S visual-studio-code-bin --noconfirm
#
#  # rest client
#  yay -S insomnia-bin --noconfirm
#
  # neovim
  echo -e "${GREEN}"
  figlet "Neovim"
  echo -e "${NONE}"
  sudo pacman -Sy neovim fzf ripgrep fd --noconfirm
  git clone https://github.com/MSzczeblewski/kickstart.nvim.git ~./config/nvim
fi

# -----------------------------------------------------
# apps
# -----------------------------------------------------

# gui apps
echo -e "${GREEN}"
figlet "GUI Apps"
echo -e "${NONE}"
sudo pacman -Sy okular feh gwenview mpv qbittorrent bitwarden qalculate-gtk veracrypt --noconfirm
yay -S onlyoffice-bin brave-bin zen-browser-bin ventoy-bin unified-remote-server webcord --noconfirm

# return default browser to firefox from brave
unset BROWSER
xdg-settings set default-web-browser firefox.desktop

# terminal utils
echo -e "${GREEN}"
figlet "TerminalUtils"
echo -e "${NONE}"
sudo pacman -Sy tmux yazi fastfetch htop --noconfirm


# -----------------------------------------------------
# configs and themes
# -----------------------------------------------------

# dotfiles
echo -e "${GREEN}"
figlet "Dotfiles"
echo -e "${NONE}"

if $nvidia ;then
    echo \
"# -----------------------------------------------------
# Environment Variables
# -----------------------------------------------------

# https://wiki.hyprland.org/Nvidia/
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = ELECTRON_OZONE_PLATFORM_HINT,auto

cursor {
    no_hardware_cursors = true
}" > ./config/hypr/conf/environment.conf
fi

echo \
"# -----------------------------------------------------
# Monitor Setup
# -----------------------------------------------------

monitor=,${resolution},auto,1" > ./config/hypr/conf/monitor.conf

cp -rf ./config/.gtkrc-2.0 ./config/.Xresources ./config/.bashrc ./config/.zshrc ./config/.p10k.zsh ~/
mkdir -p ~/.config/qBittorrent && cp -rf ./config/qbittorrent/qbittorrent.qbtheme ~/.config/qBittorrent
cp -rf ./config/alacritty ./config/dunst ./config/gtk-3.0 ./config/gtk-4.0 ./config/hypr ./config/picom \
    ./config/kitty ./config/scripts ./config/Thunar ./config/wal ./config/waybar \
    ./config/wlogout ./config/fastfetch \
    ~/.config

# rofi
echo -e "${GREEN}"
figlet "Rofi"
echo -e "${NONE}"
git clone --depth=1 https://github.com/adi1090x/rofi.git ~/rofi
cd ~/rofi
chmod +x setup.sh
sh setup.sh
cd -
rm -rf ~/rofi

# sddm
echo -e "${GREEN}"
figlet "SDDM"
echo -e "${NONE}"
sudo systemctl enable sddm
sudo git clone https://github.com/keyitdev/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf

# wallpapers and screenshots
echo -e "${GREEN}"
figlet "WallpapersScreenshots"
echo -e "${NONE}"
mkdir ~/Pictures/screenshots
cp -r wallpapers/** ~/Pictures

# system configs
echo -e "${GREEN}"
figlet "SystemConfigs"
echo -e "${NONE}"
sudo systemctl enable bluetooth
sudo systemctl enable fstrim.timer

# swapfile
echo -e "${GREEN}"
figlet "Swapfile"
echo -e "${NONE}"
sudo mkswap -U clear --size 8G --file /swapfile
sudo swapon /swapfile
echo "/swapfile				  swap		 swap	 defaults   0 0" | sudo tee -a /etc/fstab


# -----------------------------------------------------
# kernel and drivers
# -----------------------------------------------------

# zen kernel
echo -e "${GREEN}"
figlet "ZenKernel"
echo -e "${NONE}"
#sudo pacman -Sy linux-zen linux-zen-headers --noconfirm
sudo pacman -Sy linux linux-firmware --noconfirm
sudo grub-mkconfig -o /boot/grub/grub.cfg

# nvidia drivers
if $nvidia ;then
    echo -e "${GREEN}"
    figlet "Nvidia"
    echo -e "${NONE}"
    sudo pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings libva-nvidia-driver mkinitcpio
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    sudo sed -i "s/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g" /etc/mkinitcpio.conf
    echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee -a /etc/modprobe.d/nvidia.conf
    sudo mkinitcpio -P
fi

# cleanup
echo -e "${GREEN}"
figlet "Cleanup"
echo -e "${NONE}"
sudo pacman -Rns $(pacman -Qtdq) --noconfirm
yay -Sc --noconfirm

echo -e "${GREEN}"
figlet "Done"
echo -e "${NONE}"

echo
echo "DONE! Please reboot your system!"
