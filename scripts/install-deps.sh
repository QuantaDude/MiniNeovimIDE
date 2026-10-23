#!/usr/bin/env bash
# Installs the external tools this Neovim config expects (C++ toolchain, clangd,
# CMake, debuggers, ripgrep, ...). Plugins are NOT handled here: Neovim clones
# them itself on first start (vim.pack).
#
#   scripts/install-deps.sh            install with the detected package manager
#   scripts/install-deps.sh --dry-run  only print what would be run
#
# Neovim >= 0.12 is required; most distros ship an older one, so see
# https://github.com/neovim/neovim/releases if `nvim --version` is too old.
set -euo pipefail

DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

run() {
  echo "+ $*"
  [[ $DRY -eq 1 ]] || "$@"
}

SUDO=""
if [[ $EUID -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

if command -v pacman >/dev/null 2>&1; then
  run $SUDO pacman -S --needed --noconfirm \
    git curl unzip make gcc clang cmake ninja gdb lldb ripgrep fd neovim \
    tree-sitter-cli perf
elif command -v apt-get >/dev/null 2>&1; then
  run $SUDO apt-get update
  run $SUDO apt-get install -y \
    git curl unzip make build-essential gcc g++ clang clangd clang-format \
    cmake ninja-build gdb lldb ripgrep fd-find neovim linux-perf
  echo "note: Debian/Ubuntu ship 'fdfind'; add 'ln -s \$(which fdfind) ~/.local/bin/fd' if wanted."
  echo "note: tree-sitter CLI: 'npm i -g tree-sitter-cli' or 'cargo install tree-sitter-cli'."
elif command -v dnf >/dev/null 2>&1; then
  run $SUDO dnf install -y \
    git curl unzip make gcc gcc-c++ clang clang-tools-extra cmake ninja-build \
    gdb lldb ripgrep fd-find neovim perf
  echo "note: tree-sitter CLI: 'npm i -g tree-sitter-cli' or 'cargo install tree-sitter-cli'."
elif command -v zypper >/dev/null 2>&1; then
  run $SUDO zypper install -y \
    git curl unzip make gcc gcc-c++ clang clang-tools cmake ninja gdb lldb \
    ripgrep fd neovim perf
elif command -v apk >/dev/null 2>&1; then
  run $SUDO apk add \
    git curl unzip make gcc g++ clang clang-extra-tools cmake samurai gdb lldb \
    ripgrep fd neovim perf
elif command -v brew >/dev/null 2>&1; then
  run brew install git curl unzip make llvm cmake ninja gdb lldb ripgrep fd neovim tree-sitter
  echo "note: with Homebrew LLVM, put \$(brew --prefix llvm)/bin on PATH for clangd / clang-format."
else
  echo "No supported package manager found (pacman, apt, dnf, zypper, apk, brew)." >&2
  echo "Install by hand: git curl unzip make gcc clang clangd clang-format cmake ninja gdb lldb ripgrep fd neovim tree-sitter-cli perf" >&2
  exit 1
fi

echo
echo "Optional: lldb-dap (debug adapter) ships with LLVM/lldb; lua-language-server improves editing this config."
echo "Font: use a Nerd Font in your terminal (https://www.nerdfonts.com) or icons will show as boxes."
