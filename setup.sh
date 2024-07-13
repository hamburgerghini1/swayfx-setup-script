#!/bin/bash
# My personal Linux install script
# This script is 99% made by AI using Cursor AI Editor, since I'm lazy and I don't know shit about scripting - for now lol

# Clone the repository
git clone https://github.com/hamburgerghini1/garuda_dotfiles_2023.git /tmp/garuda-dotfiles-2023
cd /tmp/garuda-dotfiles-2023

# Print a success message
echo "----------------------------------------"
echo "| Repository cloned successfully!      |"
echo "----------------------------------------"

# Detect package manager
if command -v apt-get &> /dev/null; then
    PACKAGE_MANAGER="apt-get"
elif command -v dnf &> /dev/null; then
    PACKAGE_MANAGER="dnf"
elif command -v pacman &> /dev/null; then
    PACKAGE_MANAGER="pacman"
elif command -v zypper &> /dev/null; then
    PACKAGE_MANAGER="zypper"
else
    echo "----------------------------------------"
    echo "| No supported package manager found!  |"
    echo "----------------------------------------"
    exit 1
fi

echo "----------------------------------------"
echo "| Detected package manager: $PACKAGE_MANAGER |"
echo "----------------------------------------"



echo "----------------------------------------"
echo "| Installing curl and wget...           |"
echo "----------------------------------------"
case "$PACKAGE_MANAGER" in
    apt-get)
        apt-get update
        apt-get install -y curl wget
        ;;
    dnf)
        dnf install -y curl wget
        ;;
    pacman)
        pacman -Syu --noconfirm curl wget
        ;;
    zypper)
        zypper install -y curl wget
        ;;
    *)
        echo "----------------------------------------"
        echo "| Unsupported package manager: $PACKAGE_MANAGER |"
        echo "----------------------------------------"
        exit 1
        ;;
esac
echo "----------------------------------------"
echo "| curl and wget installed successfully! |"
echo "----------------------------------------"

# Add RPM Fusion repository for Fedora
if [ "$PACKAGE_MANAGER" = "dnf" ]; then
    echo "----------------------------------------"
    echo "| Adding RPM Fusion repository for Fedora... |"
    echo "----------------------------------------"
    dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    echo "----------------------------------------"
    echo "| RPM Fusion repository added successfully! |"
    echo "----------------------------------------"
fi


# Detect if Nvidia GPU is present
if lspci | grep -i nvidia &> /dev/null; then
    echo "----------------------------------------"
    echo "| Nvidia GPU detected. Installing drivers... |"
    echo "----------------------------------------"
    case "$PACKAGE_MANAGER" in
        apt-get)
            apt-get update
            apt-get install -y nvidia-driver
            ;;
        dnf)
            dnf install -y akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda
            ;;
        pacman)
            pacman -Syu --noconfirm nvidia-dkms
            ;;
        zypper)
            zypper install -y nvidia-glG05
            ;;
        *)
            echo "----------------------------------------"
            echo "| Unsupported package manager: $PACKAGE_MANAGER |"
            echo "----------------------------------------"
            exit 1
            ;;
    esac
    echo "----------------------------------------"
    echo "| Nvidia drivers installed successfully! |"
    echo "----------------------------------------"
else
    echo "----------------------------------------"
    echo "| No Nvidia GPU detected.               |"
    echo "----------------------------------------"
fi

echo "----------------------------------------"
echo "| Installing flatpak and uninstalling snap if installed... |"
echo "----------------------------------------"

case "$PACKAGE_MANAGER" in
    apt-get)
        apt-get update
        apt-get install -y flatpak
        if dpkg -l | grep -q snapd; then
            apt-get remove --purge -y snapd
            apt-mark hold snapd
        fi
        ;;
    dnf)
        dnf install -y flatpak
        if rpm -q snapd; then
            dnf remove -y snapd
            dnf mark hold snapd
        fi
        ;;
    pacman)
        pacman -Syu --noconfirm flatpak
        if pacman -Qs snapd > /dev/null; then
            pacman -Rns --noconfirm snapd
            echo "snapd" | tee -a /etc/pacman.conf
        fi
        ;;
    zypper)
        zypper install -y flatpak
        if rpm -q snapd; then
            zypper remove -y snapd
            echo "snapd" | tee -a /etc/zypp/locks
        fi
        ;;
    *)
        echo "----------------------------------------"
        echo "| Unsupported package manager: $PACKAGE_MANAGER |"
        echo "----------------------------------------"
        exit 1
        ;;
esac

echo "----------------------------------------"
echo "| Adding Flathub repository...          |"
echo "----------------------------------------"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "----------------------------------------"
echo "| Flatpak installed, Flathub repository added, and snapd handled successfully! |"
echo "----------------------------------------"

echo "----------------------------------------"
echo "| Installing paru on Arch and nala on Debian based distro... |"
echo "----------------------------------------"

case "$PACKAGE_MANAGER" in
    pacman)
        echo "----------------------------------------"
        echo "| Detected Arch Linux. Installing paru and aliasing it to yay... |"
        echo "----------------------------------------"
        pacman -S --noconfirm --needed base-devel
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm
        cd ..
        rm -rf paru
        echo "alias yay='paru'" >> ~/.bashrc
        source ~/.bashrc
        ;;
    apt-get)
        echo "----------------------------------------"
        echo "| Detected Debian-based distribution. Installing nala... |"
        echo "----------------------------------------"
        NALA_DEB_URL=$(curl -s https://gitlab.com/api/v4/projects/volian%2Fnala/releases | grep -oP '(?<="direct_asset_url":")[^"]*\.deb' | head -n 1)
        wget $NALA_DEB_URL -O nala_latest.deb
        dpkg -i nala_latest.deb
        apt-get install -f -y
        rm nala_latest.deb
        ;;
    *)
        echo "----------------------------------------"
        echo "| No additional package manager installation required for $PACKAGE_MANAGER. |"
        echo "----------------------------------------"
        ;;
esac

echo "----------------------------------------"
echo "| Additional package manager installation completed! |"
echo "----------------------------------------"

echo "----------------------------------------"
echo "| Installing build essential packages... |"
echo "----------------------------------------"

case "$PACKAGE_MANAGER" in
    paru)
        echo "----------------------------------------"
        echo "| Detected Arch Linux. Installing base-devel... |"
        echo "----------------------------------------"
        paru -S --noconfirm --needed base-devel
        ;;
    apt-get)
        echo "----------------------------------------"
        echo "| Detected Debian-based distribution. Installing build-essential... |"
        echo "----------------------------------------"
        apt-get update
        apt-get install -y build-essential
        ;;
    zypper)
        echo "----------------------------------------"
        echo "| Detected openSUSE. Installing -devel pattern... |"
        echo "----------------------------------------"
        zypper install -t pattern devel_basis
        ;;
    *)
        echo "----------------------------------------"
        echo "| Unsupported package manager: $PACKAGE_MANAGER |"
        echo "----------------------------------------"
        exit 1
        ;;
esac

echo "----------------------------------------"
echo "| Build essential packages installation completed! |"
echo "----------------------------------------"

echo "----------------------------------------"
echo "| Installing programs as flatpaks...    |"
echo "----------------------------------------"

FLATPAK_APPS=(
    "one.ablaze.floorp"
    "com.spotify.Client"
    "dev.alextren.Spotube"
    "net.davidotek.pupgui2"
    "com.protonplus.ProtonPlus"
    "io.github.shiftey.Desktop"
    "com.usebottles.bottles"
    "net.lutris.Lutris"
    "com.xivlauncher.ffxivlauncher"
    "com.github.wwmm.easyeffects"
    "com.obsproject.Studio"
    "org.gimp.GIMP"
    "org.kde.kdenlive"
    "it.mijorus.gearlever"
    "com.github.tchx84.Flatseal"
    "io.lmms.LMMS"
    "org.ardour.Ardour"
    "org.audacityteam.Audacity"
)

for app in "${FLATPAK_APPS[@]}"; do
    flatpak install -y flathub "$app"
done

echo "----------------------------------------"
echo "| Flatpak programs installation completed! |"
echo "----------------------------------------"

echo "----------------------------------------"
echo "| Installing additional packages...     |"
echo "----------------------------------------"

case "$PACKAGE_MANAGER" in
    paru)
        echo "----------------------------------------"
        echo "| Installing packages for Arch Linux... |"
        echo "----------------------------------------"
        paru -S --noconfirm --needed swayfx mako wofi rofi swaync waybar polkit-gnome wlroots swaync swaybg swayidle swayr lxappearance noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-font-awesome ttf-ms-fonts autotiling fastfetch pw-volume
        ;;
    apt-get)
        echo "----------------------------------------"
        echo "| Installing packages for Debian-based distribution... |"
        echo "----------------------------------------"
        apt-get update
        apt-get install -y software-properties-common wget
        add-apt-repository ppa:swaywm/sway
        add-apt-repository ppa:agornostal/swaync
        add-apt-repository ppa:snwh/ppa
        apt-get update
        apt-get install -y sway mako wofi rofi sway-notification-center waybar policykit-1-gnome wlroots swaync swaybg swayidle swayr lxappearance fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-font-awesome ttf-mscorefonts-installer pulseaudio-utils
        wget -O fastfetch.deb https://github.com/LinusDierheimer/fastfetch/releases/latest/download/fastfetch_amd64.deb
        apt-get install -y ./fastfetch.deb
        ;;
    dnf)
        echo "----------------------------------------"
        echo "| Installing packages for Fedora...     |"
        echo "----------------------------------------"
        dnf copr enable erikreider/SwayNotificationCenter
        dnf install -y sway mako wofi rofi waybar polkit-gnome wlroots swaync swaybg swayidle swayr lxappearance google-noto-sans-fonts google-noto-cjk-fonts google-noto-emoji-fonts fontawesome-fonts msttcore-fonts-installer autotiling fastfetch pulseaudio-utils
        ;;
    zypper)
        echo "----------------------------------------"
        echo "| Installing packages for openSUSE...   |"
        echo "----------------------------------------"
        zypper install -y sway mako wofi rofi SwayNotificationCenter waybar polkit-gnome wlroots swaync swaybg swayidle swayr lxappearance noto-sans-fonts noto-sans-cjk-fonts noto-emoji-fonts fontawesome-fonts fetchmsttfonts autotiling fastfetch
        ;;
    *)
        echo "----------------------------------------"
        echo "| Unsupported package manager: $PACKAGE_MANAGER |"
        echo "----------------------------------------"
        exit 1
        ;;
esac

echo "----------------------------------------"
echo "| Additional packages installation completed! |"
echo "----------------------------------------"

if [ ! -f papirus-kolorizer.sh ]; then
    wget https://github.com/hamburgerghini1/swayfx-setup-script/blob/main/papirus-kolorizer.sh -O papirus-kolorizer.sh
fi

chmod +x papirus-kolorizer.sh
./papirus-kolorizer.sh

if [ $? -eq 0 ]; then
    echo "----------------------------------------"
    echo "| Papirus icons installed successfully! |"
    echo "----------------------------------------"
else
    echo "----------------------------------------"
    echo "| Failed to install Papirus icons.      |"
    echo "----------------------------------------"
fi

echo "----------------------------------------"
echo "| Installing Mullvad VPN...             |"
echo "----------------------------------------"

# Install Mullvad VPN
case "$PACKAGE_MANAGER" in
    apt-get)
        echo "----------------------------------------"
        echo "| Detected Debian-based distribution. Adding Mullvad VPN repository and installing... |"
        echo "----------------------------------------"
        # Download the Mullvad signing key
        sudo curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc
        # Add the Mullvad repository server to apt
        echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$( dpkg --print-architecture )] https://repository.mullvad.net/deb/stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mullvad.list
        # Install the package
        sudo apt update
        sudo apt install -y mullvad-vpn
        ;;
    dnf)
        echo "----------------------------------------"
        echo "| Detected Fedora. Adding Mullvad VPN repository and installing... |"
        echo "----------------------------------------"
        # Add the Mullvad repository server to dnf
        sudo dnf config-manager --add-repo https://repository.mullvad.net/rpm/stable/mullvad.repo
        # Install the package
        sudo dnf install -y mullvad-vpn
        ;;
    pacman)
        echo "----------------------------------------"
        echo "| Detected Arch Linux. Installing mullvad-vpn-bin from AUR... |"
        echo "----------------------------------------"
        paru -S --noconfirm mullvad-vpn-bin
        ;;
    *)
        echo "----------------------------------------"
        echo "| Unsupported package manager: $PACKAGE_MANAGER |"
        echo "----------------------------------------"
        exit 1
        ;;
esac

echo "----------------------------------------"
echo "| Mullvad VPN installation completed!   |"
echo "----------------------------------------"

# Check for dnf5 and alias it to dnf if available
echo "----------------------------------------"
echo "| Checking for dnf5 and aliasing it to dnf if available... |"
echo "----------------------------------------"

case "$PACKAGE_MANAGER" in
    dnf)
        echo "----------------------------------------"
        echo "| Detected Fedora. Attempting to install dnf5... |"
        echo "----------------------------------------"
        if sudo dnf install -y dnf5; then
            echo "alias dnf='dnf5'" >> ~/.bashrc
            source ~/.bashrc
            echo "----------------------------------------"
            echo "| dnf5 installed and aliased to dnf successfully! |"
            echo "----------------------------------------"
        else
            echo "----------------------------------------"
            echo "| Failed to install dnf5. Please check your repository settings or try again later. |"
            echo "----------------------------------------"
            exit 1
        fi
        ;;
    *)
        echo "----------------------------------------"
        echo "| No dnf5 installation required for $PACKAGE_MANAGER. |"
        echo "----------------------------------------"
        ;;
esac

# Zsh and Oh My Zsh install.
echo "----------------------------------------"
echo "| Installing zsh...                     |"
echo "----------------------------------------"
case "$PACKAGE_MANAGER" in
    apt-get)
        sudo apt-get update
        sudo apt-get install -y zsh
        ;;
    dnf)
        sudo dnf install -y zsh
        ;;
    pacman)
        sudo pacman -Syu --noconfirm zsh
        ;;
    zypper)
        sudo zypper install -y zsh
        ;;
    *)
        echo "----------------------------------------"
        echo "| Unsupported package manager: $PACKAGE_MANAGER |"
        echo "----------------------------------------"
        exit 1
        ;;
esac

echo "----------------------------------------"
echo "| zsh installation completed!           |"
echo "----------------------------------------"

echo "----------------------------------------"
echo "| Installing oh-my-zsh...               |"
echo "----------------------------------------"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "----------------------------------------"
echo "| oh-my-zsh installation completed!     |"
echo "----------------------------------------"

echo "----------------------------------------"
echo "| Cloning mybash repo by Chris Titus Tech...          |"
echo "----------------------------------------"
git clone https://github.com/christitustech/mybash.git /tmp/mybash
cd /tmp/mybash

echo "----------------------------------------"
echo "| Running setup.sh from mybash repo...  |"
echo "----------------------------------------"
chmod +x setup.sh
./setup.sh

echo "----------------------------------------"
echo "| mybash setup completed!               |"
echo "----------------------------------------"

echo "----------------------------------------"
echo "| Copying .bashrc to home directory...  |"
echo "----------------------------------------"
cp /tmp/mybash/.bashrc ~/

echo "----------------------------------------"
echo "| .bashrc has been updated!             |"
echo "----------------------------------------"

echo "----------------------------------------"
echo "| Cloning Top-5-Bootloader-Themes repo by Chris Titus Tech... |"
echo "----------------------------------------"
git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes.git /tmp/Top-5-Bootloader-Themes
cd /tmp/Top-5-Bootloader-Themes

echo "----------------------------------------"
echo "| Running install.sh from Top-5-Bootloader-Themes repo... |"
echo "----------------------------------------"
chmod +x install.sh
./install.sh

echo "----------------------------------------"
echo "| Top-5-Bootloader-Themes setup completed! |"
echo "----------------------------------------"

echo "----------------------------------------"
echo "| Installing distrobox, podman, and docker... |"
echo "----------------------------------------"
case "$PACKAGE_MANAGER" in
    apt-get)
        apt-get update
        apt-get install -y distrobox podman docker.io
        ;;
    dnf)
        dnf install -y distrobox podman docker
        ;;
    zypper)
        zypper install -y distrobox podman docker
        ;;
esac

echo "----------------------------------------"
echo "| distrobox, podman, and docker installation completed! |"
echo "----------------------------------------"

if [ "$PACKAGE_MANAGER" != "pacman" ]; then
    echo "----------------------------------------"
    echo "| Creating Arch Linux distrobox container... |"
    echo "----------------------------------------"
    distrobox-create --name arch-container --image docker.io/library/archlinux:latest

    echo "----------------------------------------"
    echo "| Arch Linux distrobox container created successfully! |"
    echo "----------------------------------------"
else
    echo "----------------------------------------"
    echo "| Skipping Arch Linux distrobox container creation as the system is already using Arch Linux. |"
    echo "----------------------------------------"
fi

echo "----------------------------------------"
echo "| Entering Arch Linux distrobox container and updating... |"
echo "----------------------------------------"
distrobox-enter --name arch-container --command "sudo pacman -Syu --noconfirm"

echo "----------------------------------------"
echo "| Arch Linux distrobox container updated successfully! |"
echo "----------------------------------------"

echo "----------------------------------------"
echo "| Installing VMWare Workstation Pro using AUR in the Arch Linux distrobox... |"
echo "----------------------------------------"
distrobox-enter --name arch-container --command "sudo pacman -S --noconfirm base-devel git"
distrobox-enter --name arch-container --command "git clone https://aur.archlinux.org/yay.git /tmp/yay"
distrobox-enter --name arch-container --command "cd /tmp/yay && makepkg -si --noconfirm"
distrobox-enter --name arch-container --command "yay -S --noconfirm vmware-workstation"

echo "----------------------------------------"
echo "| VMWare Workstation Pro installation completed successfully! |"
echo "----------------------------------------"

