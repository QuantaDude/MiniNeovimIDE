#!/usr/bin/env bash
set -euo pipefail

# =========================================
# Neovim C++ IDE Bootstrap Installer (Arch Linux)
#
#   ./install.sh                 interactive
#   ./install.sh --yes           accept the defaults, no questions
#   ./install.sh --name nvim-cpp --cmd nvim-cpp
#   ./install.sh --sync          run `pacman -Syu` first (full upgrade)
#   ./install.sh --no-fonts      skip the Nerd Font packages
#   ./install.sh --no-prewarm    skip the headless first start (plugin clone)
#
# The config goes to ~/.config/<name> and is started through a small launcher
# (~/.local/bin/<cmd>) that sets NVIM_APPNAME=<name>, so it never touches an
# existing ~/.config/nvim. Other distros: scripts/install-deps.sh
# =========================================

SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname -- "$SCRIPT_PATH")"
SCRIPT_NAME="$(basename -- "$SCRIPT_PATH")"

APP_NAME="nvim-cpp"
LAUNCHER=""
ASSUME_YES=0
SYNC=0
FONTS=1
PREWARM=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --yes|-y)      ASSUME_YES=1 ;;
        --name)        APP_NAME="${2:?--name needs a value}"; shift ;;
        --cmd)         LAUNCHER="${2:?--cmd needs a value}"; shift ;;
        --sync)        SYNC=1 ;;
        --no-fonts)    FONTS=0 ;;
        --no-prewarm)  PREWARM=0 ;;
        -h|--help)     sed -n '3,17p' "$SCRIPT_PATH" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1 (see --help)" >&2; exit 2 ;;
    esac
    shift
done

# =========================================
# Elevate Privileges
# =========================================

if [[ "$EUID" -ne 0 ]]; then
    echo "[*] Requesting sudo privileges..."
    exec sudo bash "$SCRIPT_PATH" "$@"
fi

REAL_USER="${SUDO_USER:-$(id -un)}"
if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
else
    REAL_HOME="$HOME"
fi

# run a command as the real (non-root) user
as_user() {
    if [[ "$REAL_USER" == "root" ]]; then
        "$@"
    else
        sudo -u "$REAL_USER" -H "$@"
    fi
}

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

# ask "question" default  ->  echoes the answer (default when --yes or no tty)
ask() {
    local prompt="$1" default="$2" reply=""
    if [[ "$ASSUME_YES" -eq 1 || ! -t 0 ]]; then
        echo "$default"
        return
    fi
    read -rp "$prompt [$default]: " reply
    echo "${reply:-$default}"
}

confirm() { # confirm "question" y|n
    local answer
    answer="$(ask "$1" "$2")"
    [[ "$answer" =~ ^[Yy] ]]
}

# =========================================
# Banner
# =========================================

echo -e "${ORANGE}${BOLD}"

cat << "EOF"

 ██████╗                  ██╗ ██████╗ ███████╗
██╔════╝    ██╗     ██╗   ██║ ██╔══██╗██╔════╝
██║       ██████╗ ██████╗ ██║ ██║  ██║█████╗
██║       ╚═██╔═╝ ╚═██╔═╝ ██║ ██║  ██║██╔══╝
╚██████╗    ╚═╝     ╚═╝   ██║ ██████╔╝███████╗
 ╚═════╝                  ╚═╝ ╚═════╝ ╚══════╝

          N E O V I M   C + +   I D E

EOF

echo -e "${RESET}"

# =========================================
# Detect Arch Linux
# =========================================

section "Detecting System"

if ! have pacman; then
    fail "This installer only supports Arch Linux based distros (see scripts/install-deps.sh for others)"
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${ID:-arch}"
else
    DISTRO="arch"
fi

ok "Detected Arch-based distro: $DISTRO"

# =========================================
# Install Packages
# =========================================

# a package that may not exist in every repo setup: warn instead of failing
try_install() {
    local pkg
    for pkg in "$@"; do
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            if pacman -S --needed --noconfirm "$pkg"; then
                ok "$pkg installed"
            else
                warn "could not install $pkg"
            fi
        else
            warn "$pkg not found in the enabled repositories (skipped)"
        fi
    done
}

install_packages() {
    section "Installing Packages"

    if [[ "$SYNC" -eq 1 ]]; then
        info "Full system upgrade (--sync)"
        pacman -Syu --noconfirm
    fi

    # Core toolchain + everything the config shells out to.
    # clang ships clangd and clang-format; lldb ships lldb-dap.
    PACMAN_PACKAGES=(
        git
        curl
        tar
        gzip
        base-devel
        gcc
        clang
        cmake
        ninja
        gdb
        lldb
        perf
        ripgrep
        fd
        neovim
        tree-sitter-cli
        xclip
        wl-clipboard
    )

    if ! pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"; then
        warn "pacman failed - the package database may be out of date"
        fail "Run: sudo pacman -Syu   (or re-run this installer with --sync)"
    fi

    ok "Official packages installed"

    # Nice to have: editing this very config
    try_install lua-language-server

    if [[ "$FONTS" -eq 1 ]]; then
        section "Installing Nerd Font Symbols"
        # icon fallback for any terminal font, plus a complete patched font
        try_install ttf-nerd-fonts-symbols ttf-jetbrains-mono-nerd
        have fc-cache && fc-cache -f >/dev/null 2>&1 || true
        info "Select a Nerd Font (e.g. JetBrainsMono Nerd Font) in your terminal settings"
    else
        warn "Skipping fonts - you need a Nerd Font in the terminal or icons show as boxes"
    fi
}

# =========================================
# Setup User Local Bin
# =========================================

setup_local_bin() {
    section "Setting Up ~/.local/bin"

    as_user mkdir -p "$REAL_HOME/.local/bin"

    local rc_files=()
    [[ -f "$REAL_HOME/.bashrc" ]] && rc_files+=("$REAL_HOME/.bashrc")
    [[ -f "$REAL_HOME/.zshrc"  ]] && rc_files+=("$REAL_HOME/.zshrc")

    if [[ "${#rc_files[@]}" -eq 0 && -f "$REAL_HOME/.config/fish/config.fish" ]]; then
        if ! grep -q '.local/bin' "$REAL_HOME/.config/fish/config.fish"; then
            echo 'fish_add_path $HOME/.local/bin' >> "$REAL_HOME/.config/fish/config.fish"
            ok "Added ~/.local/bin to PATH in config.fish"
        else
            ok "~/.local/bin already in PATH (fish)"
        fi
        return
    fi

    if [[ "${#rc_files[@]}" -eq 0 ]]; then
        warn "No shell rc file found - add ~/.local/bin to PATH yourself"
        return
    fi

    local rc
    for rc in "${rc_files[@]}"; do
        if ! grep -q '\.local/bin' "$rc"; then
            {
                echo ''
                echo 'export PATH="$HOME/.local/bin:$PATH"'
            } >> "$rc"
            ok "Added ~/.local/bin to PATH in $(basename "$rc")"
        else
            ok "~/.local/bin already in PATH ($(basename "$rc"))"
        fi
    done
}

# =========================================
# Configure Neovim
# =========================================

configure_neovim() {
    section "Configuring Neovim"

    echo
    APP_NAME="$(ask "Config name (NVIM_APPNAME, lives in ~/.config/<name>)" "$APP_NAME")"
    LAUNCHER="${LAUNCHER:-$(ask "Command to start it" "$APP_NAME")}"

    if [[ ! "$APP_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
        fail "Invalid config name: $APP_NAME"
    fi
    if [[ ! "$LAUNCHER" =~ ^[A-Za-z0-9._-]+$ ]]; then
        fail "Invalid command name: $LAUNCHER"
    fi

    CONFIG_DIR="$REAL_HOME/.config"
    NVIM_DIR="$CONFIG_DIR/$APP_NAME"
    BIN_DIR="$REAL_HOME/.local/bin"

    info "Config:   $NVIM_DIR"
    info "Launcher: $BIN_DIR/$LAUNCHER"

    as_user mkdir -p "$CONFIG_DIR" "$BIN_DIR"

    # =========================================
    # Launcher (replaces the old plain symlink alias)
    # =========================================

    local launcher_path="$BIN_DIR/$LAUNCHER"
    local nvim_bin
    nvim_bin="$(command -v nvim)"

    if [[ "$LAUNCHER" == "nvim" ]]; then
        # a launcher called "nvim" in ~/.local/bin would shadow the real binary
        if [[ "$APP_NAME" == "nvim" ]]; then
            info "Config name is 'nvim' - no launcher needed"
        else
            fail "The command can't be 'nvim' for a config named '$APP_NAME' (pick another --cmd)"
        fi
        LAUNCHER=""
    elif [[ -e "$launcher_path" || -L "$launcher_path" ]] \
        && ! grep -q "NVIM_APPNAME=.\?$APP_NAME" "$launcher_path" 2>/dev/null \
        && ! confirm "$launcher_path exists. Replace it?" n; then
        warn "Keeping existing $launcher_path"
        LAUNCHER=""
    fi

    if [[ -n "$LAUNCHER" ]]; then
        as_user tee "$launcher_path" >/dev/null <<EOF
#!/usr/bin/env bash
# Starts Neovim with the "$APP_NAME" configuration (~/.config/$APP_NAME)
export NVIM_APPNAME="$APP_NAME"
exec "$nvim_bin" "\$@"
EOF
        as_user chmod +x "$launcher_path"
        ok "Launcher created: $LAUNCHER -> nvim (NVIM_APPNAME=$APP_NAME)"
    fi

    # =========================================
    # Link Config
    # =========================================

    if [[ -L "$NVIM_DIR" || -d "$NVIM_DIR" ]]; then
        warn "$NVIM_DIR already exists"

        if confirm "Replace it? (the old one is kept as a timestamped backup)" n; then
            BACKUP="$NVIM_DIR.bak-$(date +%Y%m%d-%H%M%S)"
            as_user mv "$NVIM_DIR" "$BACKUP"
            ok "Old config moved to $BACKUP"
        else
            warn "Skipping Neovim config install"
            return
        fi
    fi

    as_user mkdir -p "$NVIM_DIR"

    info "Linking configuration files"

    local item base
    for item in "$SCRIPT_DIR"/* "$SCRIPT_DIR"/.[!.]*; do
        [[ -e "$item" ]] || continue
        base="$(basename "$item")"

        case "$base" in
            "$SCRIPT_NAME"|.git|.gitignore|nvim-pack-lock.json) continue ;;
        esac

        as_user ln -sfn "$item" "$NVIM_DIR/$base"
    done

    chown -R "$REAL_USER:$(id -gn "$REAL_USER")" "$NVIM_DIR"

    ok "Neovim config linked"
}

# =========================================
# Verify Installations
# =========================================

verify_tools() {
    section "Verifying Tools"

    # the IDE does not work without these
    REQUIRED=(
        git
        curl
        nvim
        gcc
        clang
        clangd
        clang-format
        cmake
        ninja
        rg
        gdb
        lldb
        tree-sitter
    )
    # features degrade gracefully without these
    OPTIONAL=(
        fd
        lldb-dap
        perf
        lua-language-server
    )

    local tool
    for tool in "${REQUIRED[@]}"; do
        if have "$tool"; then
            ok "$tool detected"
        else
            fail "$tool missing"
        fi
    done

    for tool in "${OPTIONAL[@]}"; do
        if have "$tool"; then
            ok "$tool detected"
        else
            warn "$tool missing (optional)"
        fi
    done

    # config needs Neovim >= 0.12 (vim.pack)
    local ver major minor
    ver="$(nvim --version | head -n1 | sed -E 's/^NVIM v([0-9]+)\.([0-9]+).*/\1 \2/')"
    read -r major minor <<<"$ver"
    if [[ "${major:-0}" -eq 0 && "${minor:-0}" -lt 12 ]]; then
        warn "Neovim $major.$minor found, but this config needs 0.12 or newer"
        warn "Update your system (pacman -Syu) or install neovim-nightly-bin / neovim-git from the AUR"
    else
        ok "Neovim version is new enough ($major.$minor)"
    fi
}

# =========================================
# First start: clone plugins
# =========================================

prewarm() {
    [[ "$PREWARM" -eq 1 && -d "${NVIM_DIR:-}" ]] || return 0

    section "First Start (cloning plugins)"

    if ! confirm "Run a headless first start now to clone the plugins?" y; then
        info "Skipped - the first normal start will do it"
        return 0
    fi

    if as_user env NVIM_APPNAME="$APP_NAME" timeout 600 nvim --headless "+sleep 2" "+qa" >/dev/null 2>&1; then
        ok "Plugins installed"
    else
        warn "Headless start did not finish cleanly - open the editor once and let it run"
    fi
}

# =========================================
# Versions
# =========================================

show_versions() {
    section "Installed Versions"

    echo -e "${AQUA}Neovim:${RESET} $(nvim --version | head -n1)"
    echo -e "${AQUA}clangd:${RESET} $(clangd --version | head -n1)"
    echo -e "${AQUA}clang:${RESET} $(clang --version | head -n1)"
    echo -e "${AQUA}CMake:${RESET} $(cmake --version | head -n1)"
    echo -e "${AQUA}gdb:${RESET} $(gdb --version | head -n1)"
    have lldb-dap && echo -e "${AQUA}lldb-dap:${RESET} $(lldb-dap --version 2>&1 | head -n1)"
    return 0
}

# =========================================
# Main
# =========================================

section "Bootstrap Starting"

install_packages
setup_local_bin
verify_tools
configure_neovim
prewarm
show_versions

echo

section "Bootstrap Complete"

ok "Neovim C++ IDE installed successfully"

echo
info "Reload your shell, then start it with:"
echo
echo "    source ~/.bashrc"
echo "    ${LAUNCHER:-NVIM_APPNAME=$APP_NAME nvim}"
echo
info "First start compiles the theme cache and tree-sitter parsers - give it a moment."
info "Inside the editor: <Space>? shows every key, :IdeDoctor checks the toolchain."
echo
