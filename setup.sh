#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo."
    exit 1
fi


# Clone the repository
git clone https://github.com/hamburgerghini1/garuda_dotfiles_2023.git /tmp/garuda-dotfiles-2023
cd /tmp/garuda-dotfiles-2023

# Print a success message
echo "Repository cloned successfully!"

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
    echo "No supported package manager found!"
    exit 1
fi

echo "Detected package manager: $PACKAGE_MANAGER"

# Add RPM Fusion repository for Fedora
if [ "$PACKAGE_MANAGER" = "dnf" ]; then
    echo "Adding RPM Fusion repository for Fedora..."
    dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    echo "RPM Fusion repository added successfully!"
fi


# Detect if Nvidia GPU is present
if lspci | grep -i nvidia &> /dev/null; then
    echo "Nvidia GPU detected. Installing drivers..."
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
            echo "Unsupported package manager: $PACKAGE_MANAGER"
            exit 1
            ;;
    esac
    echo "Nvidia drivers installed successfully!"
else
    echo "No Nvidia GPU detected."
fi

echo "Installing flatpak and uninstalling snap if installed..."

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
        echo "Unsupported package manager: $PACKAGE_MANAGER"
        exit 1
        ;;
esac

echo "Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "Flatpak installed, Flathub repository added, and snapd handled successfully!"

echo "Installing paru on Arch and nala on Debian based distro..."

case "$PACKAGE_MANAGER" in
    pacman)
        echo "Detected Arch Linux. Installing paru and aliasing it to yay..."
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
        echo "Detected Debian-based distribution. Installing nala..."
        NALA_DEB_URL=$(curl -s https://api.github.com/repos/volitank/nala/releases/latest | grep "browser_download_url.*deb" | cut -d '"' -f 4)
        wget $NALA_DEB_URL -O nala_latest.deb
        dpkg -i nala_latest.deb
        apt-get install -f -y
        rm nala_latest.deb
        ;;
    *)
        echo "No additional package manager installation required for $PACKAGE_MANAGER."
        ;;
esac

echo "Additional package manager installation completed!"

echo "Installing build essential packages..."

case "$PACKAGE_MANAGER" in
    paru)
        echo "Detected Arch Linux. Installing base-devel..."
        paru -S --noconfirm --needed base-devel
        ;;
    apt-get)
        echo "Detected Debian-based distribution. Installing build-essential..."
        apt-get update
        apt-get install -y build-essential
        ;;
    zypper)
        echo "Detected openSUSE. Installing -devel pattern..."
        zypper install -t pattern devel_basis
        ;;
    *)
        echo "Unsupported package manager: $PACKAGE_MANAGER"
        exit 1
        ;;
esac

echo "Build essential packages installation completed!"

echo "Installing programs as flatpaks..."

FLATPAK_APPS=(
    "com.github.florp.florp"
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

echo "Flatpak programs installation completed!"

echo "Installing additional packages..."

case "$PACKAGE_MANAGER" in
    paru)
        echo "Installing packages for Arch Linux..."
        paru -S --noconfirm --needed swayfx mako wofi rofi swaync sway-interactive-screenshot waybar polkit-gnome wlroots swaync swayng swayidle swayr lxappearance noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-font-awesome ttf-ms-fonts autotiling fastfetch pw-volume
        ;;
    apt-get)
        echo "Installing packages for Debian-based distribution..."
        apt-get update
        apt-get install -y sway mako wofi rofi sway-notification-center sway-interactive-screenshot waybar policykit-1-gnome wlroots swaync swayng swayidle swayr lxappearance fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-font-awesome ttf-mscorefonts-installer autotiling fastfetch pulseaudio-utils
        ;;
    dnf)
        echo "Installing packages for Fedora..."
        dnf copr enable erikreider/SwayNotificationCenter
        dnf install -y sway mako wofi rofi sway-interactive-screenshot waybar polkit-gnome wlroots swaync swayng swayidle swayr lxappearance google-noto-sans-fonts google-noto-cjk-fonts google-noto-emoji-fonts fontawesome-fonts msttcore-fonts-installer autotiling fastfetch pulseaudio-utils
        ;;
    zypper)
        echo "Installing packages for openSUSE..."
        zypper install -y sway mako wofi rofi SwayNotificationCenter sway-interactive-screenshot waybar polkit-gnome wlroots swaync swayng swayidle swayr lxappearance noto-sans-fonts noto-sans-cjk-fonts noto-emoji-fonts fontawesome-fonts fetchmsttfonts autotiling fastfetch
        ;;
    *)
        echo "Unsupported package manager: $PACKAGE_MANAGER"
        exit 1
        ;;
esac

echo "Additional packages installation completed!"
