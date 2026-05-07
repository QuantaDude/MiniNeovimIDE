#!/usr/bin/env bash
set -euo pipefail

# =========================================
# MiniNeovimIDE Bootstrap Installer
# =========================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

PREFIX_="$HOME/.local"
BIN="$PREFIX_/bin"

# =========================================
# Elevate Privileges
# =========================================

if [[ "$EUID" -ne 0 ]]; then
    echo "[*] Requesting sudo privileges..."
    exec sudo bash "$0" "$@"
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(eval echo "~$REAL_USER")"

# =========================================
# Gruvbox Theme
# =========================================

RED="\033[38;2;251;73;52m"
GREEN="\033[38;2;184;187;38m"
YELLOW="\033[38;2;250;189;47m"
BLUE="\033[38;2;131;165;152m"
PURPLE="\033[38;2;211;134;155m"
AQUA="\033[38;2;142;192;124m"
ORANGE="\033[38;2;254;128;25m"

BOLD="\033[1m"
RESET="\033[0m"

ok() {
    echo -e "${GREEN}${BOLD}[✔]${RESET} $1"
}

warn() {
    echo -e "${YELLOW}${BOLD}[⚠]${RESET} $1"
}

fail() {
    echo -e "${RED}${BOLD}[✘]${RESET} $1"
    exit 1
}

info() {
    echo -e "${BLUE}${BOLD}[➜]${RESET} $1"
}

section() {
    echo
    echo -e "${ORANGE}${BOLD}========================================${RESET}"
    echo -e "${ORANGE}${BOLD}$1${RESET}"
    echo -e "${ORANGE}${BOLD}========================================${RESET}"
}

have() {
    command -v "$1" >/dev/null 2>&1
}

# =========================================
# Banner
# =========================================

clear

echo -e "${ORANGE}${BOLD}"

cat << "EOF"

███╗   ███╗██╗███╗   ██╗██╗
████╗ ████║██║████╗  ██║██║
██╔████╔██║██║██╔██╗ ██║██║
██║╚██╔╝██║██║██║╚██╗██║██║
██║ ╚═╝ ██║██║██║ ╚████║██║
╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝

███╗   ██╗███████╗ ██████╗ 
████╗  ██║██╔════╝██╔═══██╗
██╔██╗ ██║█████╗  ██║   ██║
██║╚██╗██║██╔══╝  ██║   ██║
██║ ╚████║███████╗╚██████╔╝
╚═╝  ╚═══╝╚══════╝ ╚═════╝ 

██╗██████╗ ███████╗
██║██╔══██╗██╔════╝
██║██║  ██║█████╗  
██║██║  ██║██╔══╝  
██║██████╔╝███████╗
╚═╝╚═════╝ ╚══════╝

EOF

echo -e "${RESET}"

# =========================================
# Detect Arch Linux
# =========================================

section "Detecting System"

if ! command -v pacman >/dev/null 2>&1; then
    fail "This installer only supports Arch Linux based distros"
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${ID:-arch}"
else
    DISTRO="arch"
fi

ok "Detected Arch-based distro: $DISTRO"

# =========================================
# Refresh Database
# =========================================

section "Refreshing Pacman Database"

pacman -Sy --noconfirm

ok "Pacman database updated"

# =========================================
# Install Packages
# =========================================

install_packages() {
    section "Installing Official Repository Packages"

    PACMAN_PACKAGES=(
        git
        curl
        wget
        unzip
        tar
        gzip
        make
        gcc
        clang
        cmake
        ninja
        python
        python-pip
        nodejs
        npm
        lua
        luajit
        ripgrep
        fd
        neovim
        gdb
        lldb
        xclip
        wl-clipboard
        tree-sitter
    )

    pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

    ok "Official packages installed"

    # =========================================
    # npm Packages
    # =========================================

    section "Installing npm Packages"

    npm install -g \
        bash-language-server \
        pyright \
        typescript \
        typescript-language-server \
        prettier \
        tree-sitter-cli

    ok "npm packages installed"

    # =========================================
    # AUR Packages
    # =========================================

    AUR_PACKAGES=(
        lua-language-server
    )

    section "Checking AUR Helper"

    if command -v yay >/dev/null 2>&1; then
        ok "yay detected"

        section "Installing AUR Packages"

        sudo -u "$REAL_USER" yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

        ok "AUR packages installed"

    else
        warn "yay is not installed"
        echo
        echo "Install yay manually:"
        echo
        echo "    sudo pacman -S --needed git base-devel"
        echo "    git clone https://aur.archlinux.org/yay.git"
        echo "    cd yay"
        echo "    makepkg -si"
        echo
        warn "Re-run this installer after installing yay"
        exit 1
    fi
}

# =========================================
# Setup User Local Bin
# =========================================

setup_local_bin() {
    section "Setting Up ~/.local/bin"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.local/bin"

    SHELL_RC=""

    if [[ -f "$REAL_HOME/.bashrc" ]]; then
        SHELL_RC="$REAL_HOME/.bashrc"
    elif [[ -f "$REAL_HOME/.zshrc" ]]; then
        SHELL_RC="$REAL_HOME/.zshrc"
    fi

    if [[ -n "$SHELL_RC" ]]; then
        if ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC"; then
            echo '' >> "$SHELL_RC"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"

            ok "Added ~/.local/bin to PATH in $(basename "$SHELL_RC")"
        else
            ok "~/.local/bin already in PATH"
        fi
    else
        warn "No shell rc file found"
    fi
}

configure_neovim() {
    section "Configuring Neovim"

    CONFIG_DIR="$REAL_HOME/.config"
    NVIM_DIR="$CONFIG_DIR/nvim"

    sudo -u "$REAL_USER" mkdir -p "$CONFIG_DIR"

    echo
    read -rp "Enter nvim alias (nvim default): " NVIM_ALIAS

    NVIM_ALIAS="${NVIM_ALIAS:-nvim}"

    info "Selected alias: $NVIM_ALIAS"

    # =========================================
    # Create Alias
    # =========================================

    if [[ "$NVIM_ALIAS" != "nvim" ]]; then
        ln -sf "$(command -v nvim)" "/usr/local/bin/$NVIM_ALIAS"

        ok "Alias created: $NVIM_ALIAS -> nvim"
    else
        ok "Using default nvim command"
    fi

    # =========================================
    # Symlink Config
    # =========================================

if [[ -L "$NVIM_DIR" || -d "$NVIM_DIR" ]]; then
    warn "~/.config/nvim already exists"

    read -rp "Replace existing config? [y/N]: " REPLACE_NVIM

    if [[ "$REPLACE_NVIM" =~ ^[Yy]$ ]]; then
        sudo -u "$REAL_USER" rm -rf "$NVIM_DIR"
    else
        warn "Skipping Neovim config install"
        return
    fi
fi

sudo -u "$REAL_USER" mkdir -p "$NVIM_DIR"

info "Linking configuration files"

for item in "$SCRIPT_DIR"/*; do
    base="$(basename "$item")"

    if [[ "$base" == "$(basename "$0")" ]]; then
        continue
    fi

    sudo -u "$REAL_USER" ln -sf "$item" "$NVIM_DIR/$base"
done

    chown -R "$REAL_USER:$REAL_USER" "$NVIM_DIR"

    ok "Neovim config linked"
}
# =========================================
# Verify Installations
# =========================================

verify_tools() {
    section "Verifying Tools"

TOOLS=(
    git
    curl
    nvim
    node
    npm
    lua
    luajit
    clang
    clangd
    rg
    fd
    gdb
    lldb
)
    for tool in "${TOOLS[@]}"; do
        if have "$tool"; then
            ok "$tool detected"
        else
            fail "$tool missing"
        fi
    done
}

# =========================================
# Versions
# =========================================

show_versions() {
    section "Installed Versions"

    echo -e "${AQUA}Neovim:${RESET} $(nvim --version | head -n1)"
    echo -e "${AQUA}Node:${RESET} $(node --version)"
    echo -e "${AQUA}npm:${RESET} $(npm --version)"
    echo -e "${AQUA}Lua:${RESET} $(lua -v 2>&1)"
    echo -e "${AQUA}LuaJIT:${RESET} $(luajit -v 2>&1)"
    echo -e "${AQUA}clangd:${RESET} $(clangd --version | head -n1)"
    echo -e "${AQUA}gdb:${RESET} $(gdb --version | head -n1)"
}

# =========================================
# Main
# =========================================

section "Bootstrap Starting"

install_packages
setup_local_bin
verify_tools
configure_neovim
show_versions

echo

section "Bootstrap Complete"

ok "MiniNeovimIDE installed successfully"

info "Reboot your shell or run:"
echo
echo "    source ~/.bashrc"
echo
