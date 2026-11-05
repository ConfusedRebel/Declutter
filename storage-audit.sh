#!/usr/bin/env bash

set -u

section() {
    printf '\n\n========== %s ==========\n' "$1"
}

cmd() {
    echo "\$ $*"
    "$@" 2>&1 || true
}

section "SYSTEM"
cmd uname -a
cmd cat /etc/os-release

echo
echo "Session:"
echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-unknown}"
echo "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-unknown}"
echo "DESKTOP_SESSION=${DESKTOP_SESSION:-unknown}"

section "DISK USAGE"
cmd df -h /

section "EXPLICITLY INSTALLED PACKAGES"
cmd pacman -Qqe

section "EXPLICIT OFFICIAL REPOSITORY PACKAGES"
cmd pacman -Qqen

section "EXPLICIT FOREIGN / AUR / LOCAL PACKAGES"
cmd pacman -Qqem

section "ORPHANED PACKAGES"
orphans="$(pacman -Qdtq 2>/dev/null || true)"

if [[ -n "$orphans" ]]; then
    echo "$orphans"
else
    echo "No orphaned packages."
fi

section "OPTIONAL DEPENDENCIES INSTALLED"
pacman -Qq | while read -r pkg; do
    pacman -Qi "$pkg" 2>/dev/null |
        awk '
        /^Name            :/ {name=$3}
        /^Optional Deps   :/ && $0 !~ /None/ {
            print "\n" name ":"
            sub(/^Optional Deps   : /,"")
            print
        }'
done

section "LARGEST INSTALLED PACKAGES"
pacman -Qi 2>/dev/null |
awk '
    /^Name            :/ {
        name=$3
    }

    /^Installed Size  :/ {
        size=$4
        unit=$5

        if (unit == "KiB")
            mb=size/1024
        else if (unit == "MiB")
            mb=size
        else if (unit == "GiB")
            mb=size*1024
        else
            mb=0

        printf "%.2f MB\t%s\n", mb, name
    }
' |
sort -nr |
head -40

section "PACMAN CACHE SIZE"
cmd du -sh /var/cache/pacman/pkg

echo
echo "Cached package files:"
find /var/cache/pacman/pkg \
    -maxdepth 1 \
    -type f \
    -name '*.pkg.tar.*' 2>/dev/null |
wc -l

section "USER CACHE SIZE"
cmd du -sh "$HOME/.cache"

echo
echo "Largest directories in ~/.cache:"
du -h -d 1 "$HOME/.cache" 2>/dev/null |
sort -hr |
head -20

section "HOME DIRECTORY LARGE ITEMS"
du -h -d 1 "$HOME" 2>/dev/null |
sort -hr |
head -25

section "LOCAL USER DATA"
for dir in \
    "$HOME/.local/share" \
    "$HOME/.local/state" \
    "$HOME/.local/bin"
do
    if [[ -e "$dir" ]]; then
        echo
        echo "--- $dir ---"
        du -h -d 1 "$dir" 2>/dev/null |
            sort -hr |
            head -20
    fi
done

section "/USR/LOCAL"
if [[ -d /usr/local ]]; then
    cmd du -sh /usr/local

    echo
    echo "Files in /usr/local/bin:"
    find /usr/local/bin \
        -maxdepth 1 \
        -type f \
        -printf '%f\n' 2>/dev/null |
        sort
fi

section "USER LOCAL BIN"
if [[ -d "$HOME/.local/bin" ]]; then
    find "$HOME/.local/bin" \
        -maxdepth 1 \
        -type f \
        -printf '%f\n' 2>/dev/null |
        sort
else
    echo "~/.local/bin does not exist."
fi

section "FLATPAK"
if command -v flatpak >/dev/null; then
    cmd flatpak list
else
    echo "Flatpak not installed."
fi

section "SYSTEMD ENABLED SERVICES"
cmd systemctl list-unit-files --state=enabled --no-pager

section "SYSTEMD RUNNING SERVICES"
cmd systemctl list-units \
    --type=service \
    --state=running \
    --no-pager

section "FAILED SYSTEMD UNITS"
cmd systemctl --failed --no-pager

section "USER SYSTEMD ENABLED SERVICES"
cmd systemctl --user list-unit-files \
    --state=enabled \
    --no-pager

section "DISPLAY MANAGERS"
for dm in sddm gdm lightdm greetd ly; do
    if pacman -Q "$dm" >/dev/null 2>&1; then
        echo "$dm installed"
        systemctl is-enabled "$dm" 2>/dev/null || true
        systemctl is-active "$dm" 2>/dev/null || true
    fi
done

section "DESKTOP / WAYLAND / X11 COMPONENTS"
for pkg in \
    hyprland \
    sway \
    i3-wm \
    plasma-desktop \
    gnome-shell \
    xfce4-session \
    xorg-server \
    xorg-xwayland \
    sddm \
    greetd \
    waybar \
    wofi \
    rofi \
    quickshell \
    swaync \
    dunst
do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
        pacman -Q "$pkg"
    fi
done

section "AUDIO COMPONENTS"
for pkg in \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    pulseaudio \
    jack2
do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
        pacman -Q "$pkg"
    fi
done

section "NETWORK COMPONENTS"
for pkg in \
    networkmanager \
    iwd \
    wpa_supplicant \
    dhcpcd \
    systemd-resolvconf \
    openresolv
do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
        pacman -Q "$pkg"
    fi
done

section "DEVELOPMENT STACKS"
for pkg in \
    gcc \
    clang \
    llvm \
    lld \
    rust \
    cargo \
    go \
    nodejs \
    nodejs-lts-krypton \
    npm \
    yarn \
    pnpm \
    python \
    python-pip \
    jdk21-openjdk \
    maven \
    gradle \
    android-studio \
    docker \
    podman \
    postgresql
do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
        pacman -Q "$pkg"
    fi
done

section "AI / GPU STACK"
for pkg in \
    llama-cpp \
    ggml-vulkan \
    vulkan-intel \
    vulkan-radeon \
    vulkan-nouveau \
    intel-media-driver \
    libva-intel-driver \
    intel-gpu-tools
do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
        pacman -Q "$pkg"
    fi
done

section "OLD PACKAGE CONFIG FILES"
echo "Pacnew / Pacsave files:"
find /etc \
    \( -name '*.pacnew' -o -name '*.pacsave' \) \
    2>/dev/null

section "JOURNAL SIZE"
cmd journalctl --disk-usage

section "BROKEN SYMLINKS IN HOME"
find "$HOME" \
    -xtype l \
    -print 2>/dev/null |
head -100

section "AUR BUILD CACHE"
for dir in \
    "$HOME/.cache/yay" \
    "$HOME/.cache/paru"
do
    if [[ -d "$dir" ]]; then
        cmd du -sh "$dir"
    fi
done

section "END"
echo "Audit complete."
