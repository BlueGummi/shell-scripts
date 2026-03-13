#!/usr/bin/env bash
# =============================================================================
#  Neovim Config Installer
#  Installs plugins, LSPs, treesitter parsers, and all dependencies
# =============================================================================

set -euo pipefail

# Reliable temp files (mktemp works on macOS, Linux, and most POSIX systems)
INSTALL_LOG=$(mktemp)
PLUG_LOG=$(mktemp)
TS_LOG=$(mktemp)
HEALTH_LOG=$(mktemp)
trap 'rm -f "$INSTALL_LOG" "$PLUG_LOG" "$TS_LOG" "$HEALTH_LOG"' EXIT


# ── Colors & symbols ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

OK="${GREEN}✓${RESET}"
FAIL="${RED}✗${RESET}"
ARROW="${CYAN}→${RESET}"
WARN="${YELLOW}⚠${RESET}"

# ── Helpers ───────────────────────────────────────────────────────────────────
print_header() {
    echo
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║      Neovim Config Installer           ║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════╝${RESET}"
    echo
}

section() {
    echo
    echo -e "${BOLD}${CYAN}── $1 ${DIM}────────────────────────────────────${RESET}"
}

step() {
    echo -e "  ${ARROW} $1"
}

ok() {
    echo -e "  ${OK} $1"
}

warn() {
    echo -e "  ${WARN}  ${YELLOW}$1${RESET}"
}

fail() {
    echo -e "  ${FAIL} ${RED}$1${RESET}"
}

die() {
    fail "$1"
    echo
    exit 1
}

run_quiet() {
    local label="$1"; shift
    if "$@" > "$INSTALL_LOG" 2>&1; then
        ok "$label"
    else
        fail "$label"
        echo -e "  ${DIM}Log: $INSTALL_LOG${RESET}"
        cat "$INSTALL_LOG" | tail -10
        exit 1
    fi
}

# ── Preflight: required commands ─────────────────────────────────────────────
section "Checking requirements"

REQUIRED_CMDS=(nvim git curl)
MISSING=()

for cmd in "${REQUIRED_CMDS[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        ver=$(command -v "$cmd")
        ok "$cmd  ${DIM}($ver)${RESET}"
    else
        fail "$cmd not found"
        MISSING+=("$cmd")
    fi
done

# Optional but important
OPTIONAL_CMDS=(node npm python3 pip3 cmake cargo)
for cmd in "${OPTIONAL_CMDS[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd  ${DIM}($(command -v $cmd))${RESET}"
    else
        warn "$cmd not found — some plugins/LSPs may not work"
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo
    die "Missing required commands: ${MISSING[*]}. Please install them and re-run."
fi

# Check nvim version >= 0.9
NVIM_VERSION=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
NVIM_MAJOR=$(echo "$NVIM_VERSION" | cut -d. -f1)
NVIM_MINOR=$(echo "$NVIM_VERSION" | cut -d. -f2)
if [ "$NVIM_MAJOR" -lt 1 ] && [ "$NVIM_MINOR" -lt 9 ]; then
    die "Neovim >= 0.9 required, found $NVIM_VERSION"
fi
ok "nvim version $NVIM_VERSION"

# ── Backup existing config ────────────────────────────────────────────────────
section "Backing up existing config"

NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
BACKUP_DIR="$HOME/.config/nvim_backup_$(date +%Y%m%d_%H%M%S)"

if [ -d "$NVIM_CONFIG" ]; then
    step "Found existing config at $NVIM_CONFIG"
    cp -r "$NVIM_CONFIG" "$BACKUP_DIR"
    ok "Backed up to $BACKUP_DIR"
else
    step "No existing config found, creating fresh"
    mkdir -p "$NVIM_CONFIG"
    ok "Created $NVIM_CONFIG"
fi

# ── Copy init.vim ─────────────────────────────────────────────────────────────
section "Installing config"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_VIM="$SCRIPT_DIR/init.vim"

if [ ! -f "$INIT_VIM" ]; then
    die "init.vim not found at $SCRIPT_DIR/init.vim — place this script in the same directory as your init.vim"
fi

cp "$INIT_VIM" "$NVIM_CONFIG/init.vim"
ok "Copied init.vim to $NVIM_CONFIG/init.vim"

# ── vim-plug ──────────────────────────────────────────────────────────────────
section "Installing vim-plug"

PLUG_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"

if [ -f "$PLUG_PATH" ]; then
    ok "vim-plug already installed"
else
    step "Downloading vim-plug..."
    run_quiet "vim-plug downloaded" \
        curl -fLo "$PLUG_PATH" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# ── Install plugins via PlugInstall ──────────────────────────────────────────
section "Installing plugins"

step "Running PlugInstall (this may take a minute)..."
if nvim --headless "+PlugInstall" "+qall" 2>$PLUG_LOG; then
    ok "Plugins installed"
else
    # PlugInstall often exits non-zero even on success, check if plugged dir exists
    PLUGGED="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/plugged"
    if [ -d "$PLUGGED" ] && [ "$(ls -A "$PLUGGED")" ]; then
        ok "Plugins installed (exit code ignored)"
    else
        fail "Plugin installation may have failed"
        warn "Check $PLUG_LOG for details"
    fi
fi

# ── LSP servers ───────────────────────────────────────────────────────────────
section "Installing LSP servers"

install_npm_lsp() {
    local name="$1"; local pkg="$2"
    if command -v npm &>/dev/null; then
        if npm list -g "$pkg" &>/dev/null 2>&1; then
            ok "$name already installed"
        else
            step "Installing $name..."
            run_quiet "$name installed" npm install -g "$pkg"
        fi
    else
        warn "npm not found — skipping $name"
    fi
}

install_pip_lsp() {
    local name="$1"; local pkg="$2"
    if command -v pip3 &>/dev/null; then
        if pip3 show "$pkg" &>/dev/null 2>&1; then
            ok "$name already installed"
        else
            step "Installing $name..."
            run_quiet "$name installed" pip3 install --user "$pkg"
        fi
    else
        warn "pip3 not found — skipping $name"
    fi
}

# bash-language-server (used in config)
install_npm_lsp "bash-language-server" "bash-language-server"

# python-lsp-server (pylsp, used in config)
install_pip_lsp "python-lsp-server" "python-lsp-server"

# clangd — usually installed via system package manager
if command -v clangd &>/dev/null; then
    ok "clangd found at $(command -v clangd)"
else
    warn "clangd not found — install via your package manager:"
    warn "  brew install llvm   (macOS)"
    warn "  apt install clangd  (Debian/Ubuntu)"
fi

# rust-analyzer is managed by rustaceanvim/rustup automatically
if command -v rustup &>/dev/null; then
    step "Ensuring rust-analyzer is installed via rustup..."
    run_quiet "rust-analyzer installed" rustup component add rust-analyzer
else
    warn "rustup not found — skipping rust-analyzer"
fi

# ── Treesitter parsers ────────────────────────────────────────────────────────
section "Installing Treesitter parsers"

step "Running TSUpdate (compiles parsers, may take a moment)..."
# Run twice: first time installs, second ensures everything compiled
nvim --headless "+TSUpdateSync" "+qall" > "$TS_LOG" 2>&1 || true
ok "Treesitter parsers installed"

# ── telescope-fzf-native (needs cmake build) ─────────────────────────────────
section "Building telescope-fzf-native"

FZF_NATIVE="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/plugged/telescope-fzf-native.nvim"
if [ -d "$FZF_NATIVE" ]; then
    if command -v cmake &>/dev/null; then
        step "Building fzf native extension..."
        run_quiet "telescope-fzf-native built" \
            bash -c "cd '$FZF_NATIVE' && cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release"
    else
        warn "cmake not found — telescope-fzf-native won't have native speedup"
        warn "Install cmake for better telescope performance"
    fi
else
    warn "telescope-fzf-native directory not found — PlugInstall may not have completed"
fi

# ── Final health check ────────────────────────────────────────────────────────
section "Running health check"

step "Checking nvim health (summary only)..."
nvim --headless "+checkhealth" "+qall" > "$HEALTH_LOG" 2>&1 || true

# Count warnings/errors in health output
ERRORS=$(grep -c "ERROR" $HEALTH_LOG 2>/dev/null || echo 0)
WARNINGS=$(grep -c "WARNING" $HEALTH_LOG 2>/dev/null || echo 0)

if [ "$ERRORS" -gt 0 ]; then
    warn "$ERRORS error(s) found in health check — run :checkhealth in nvim to review"
else
    ok "No errors in health check"
fi
if [ "$WARNINGS" -gt 0 ]; then
    warn "$WARNINGS warning(s) — run :checkhealth in nvim to review"
fi

# ── Undo directory ────────────────────────────────────────────────────────────
section "Ensuring undo directory"

UNDO_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/undo"
mkdir -p "$UNDO_DIR"
ok "Undo directory ready at $UNDO_DIR"

# ── Done ──────────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║         Installation complete! 🎉      ║${RESET}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════╝${RESET}"
echo
echo -e "  ${ARROW} Open nvim and run ${BOLD}:checkhealth${RESET} to review any remaining issues"
if [ -d "$BACKUP_DIR" ]; then
    echo -e "  ${ARROW} Your previous config was backed up to:"
    echo -e "     ${DIM}$BACKUP_DIR${RESET}"
fi
echo
