#!/usr/bin/env bash
set -euo pipefail

# =============================
# Config
# =============================
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

PREFIX="$HOME/.local"
BIN="$PREFIX/bin"
LIB="$PREFIX/lib"
OPT="/opt"
NVIM_ARCHIVE="$SCRIPT_DIR/nvim-linux-x86_64.tar.gz"
NVIM_DIR="$OPT/neovim-nightly"

mkdir -p "$BIN" "$LIB"
export PATH="$BIN:$PATH"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

ok()   { echo -e "${GREEN}✔${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✘${NC} $1"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# =============================
# Git
# =============================
install_git() {
  if have git; then ok "git already installed"; return; fi
  warn "git not found — attempting install"

  if have apt; then
    sudo apt update && sudo apt install -y git
  elif have pacman; then
    sudo pacman -S --noconfirm git
  else
    fail "No supported package manager found for git"
  fi

  have git || fail "git install failed"
  ok "git installed"
}

# =============================
# nvm + Node.js (latest LTS)
# =============================
install_nvm() {
  if [ -d "$HOME/.nvm" ]; then
    ok "nvm already installed"
  else
    warn "Installing nvm"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi

  # shellcheck disable=SC1090
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] || fail "nvm.sh not found"
  . "$NVM_DIR/nvm.sh"

  if have node && have npm; then
    ok "node already installed via nvm"
    return
  fi

  warn "Installing latest Node.js LTS via nvm"
  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'

  have node || fail "node install failed"
  have npm || fail "npm install failed"

  ok "Node.js installed: $(node --version)"
}

# =============================
# npm tools
# =============================
install_npm_tools() {
  have npm || fail "npm not found"
  npm install -g typescript typescript-language-server pyright prettier
  ok "npm tools installed"
}

# =============================
# Lua + LuaJIT
# =============================
install_lua() {
  if have lua && have luajit; then ok "lua & luajit already installed"; return; fi

  warn "Installing Lua 5.4"
  cd /tmp
  curl -R -O https://www.lua.org/ftp/lua-5.4.6.tar.gz
  tar zxf lua-5.4.6.tar.gz
  cd lua-5.4.6
  make linux test
  make INSTALL_TOP="$PREFIX" install
  ok "lua installed"

  warn "Installing LuaJIT"
  cd /tmp
  git clone https://github.com/LuaJIT/LuaJIT.git
  cd LuaJIT
  make
  make PREFIX="$PREFIX" install
  ok "luajit installed"
}

# =============================
# Lua language server
# =============================
install_lua_ls() {
  if have lua-language-server; then ok "lua-language-server already installed"; return; fi
  warn "Installing lua-language-server"

  cd "$LIB"
  git clone https://github.com/LuaLS/lua-language-server.git
  cd lua-language-server
  ./make.sh
  ln -sf "$LIB/lua-language-server/bin/lua-language-server" "$BIN/lua-language-server"

  have lua-language-server || fail "lua-language-server install failed"
  ok "lua-language-server installed"
}

# =============================
# clangd (GitHub)
# =============================
install_clangd() {
  if have clangd; then
    ok "clangd already installed"
    return
  fi

  VERSION="21.1.8"
  ARCHIVE="clangd-linux-${VERSION}.zip"
  URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${VERSION}/${ARCHIVE}"

  LLVM_DIR="$PREFIX/llvm"
  TARGET_DIR="$LLVM_DIR/clangd-${VERSION}"

  warn "Installing clangd ${VERSION}"
  mkdir -p "$LLVM_DIR"

  TMP="$(mktemp -d)"
  curl -L "$URL" -o "$TMP/$ARCHIVE"
  unzip -q "$TMP/$ARCHIVE" -d "$TMP"

  # The zip extracts to clangd_<version>/
  SRC_DIR="$TMP/clangd_${VERSION}"

  if [ ! -d "$SRC_DIR/bin" ]; then
    fail "Unexpected clangd archive layout"
  fi

  rm -rf "$TARGET_DIR"
  mv "$SRC_DIR" "$TARGET_DIR"

  ln -sf "$TARGET_DIR/bin/clangd" "$BIN/clangd"

  rm -rf "$TMP"

  have clangd || fail "clangd install failed"
  ok "clangd installed ($(clangd --version | head -n1))"
}

# =============================
# ripgrep
# =============================
install_rg() {
  if have rg; then ok "ripgrep already installed"; return; fi
  warn "Installing ripgrep"

  cd /tmp
  curl -LO https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep-13.0.0-x86_64-unknown-linux-musl.tar.gz
  tar xf ripgrep-*.tar.gz
  cp ripgrep-*/rg "$BIN"

  have rg || fail "ripgrep install failed"
  ok "ripgrep installed"
}

# =============================
# Neovim nightly
# =============================
install_nvim() {
  [[ -f "$NVIM_ARCHIVE" ]] || fail "Missing $NVIM_ARCHIVE"

  warn "Installing Neovim nightly"
  TMP=$(mktemp -d)
  tar -xzf "$NVIM_ARCHIVE" -C "$TMP"

  sudo rm -rf "$NVIM_DIR"
  sudo mv "$TMP/nvim-linux-x86_64" "$NVIM_DIR"
  sudo ln -sf "$NVIM_DIR/bin/nvim" /usr/local/bin/nvim

  nvim --version | head -n1
  ok "Neovim installed"
}

# =============================
# Run
# =============================
install_git
install_nvm
install_npm_tools
install_lua
install_lua_ls
install_clangd
install_rg
install_nvim

echo
ok "Bootstrap complete"
echo "Ensure ~/.local/bin is in PATH"

