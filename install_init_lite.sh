#!/usr/bin/env bash
# =============================================================================
#  Neovim Lite Config Installer
# =============================================================================

set -euo pipefail

INSTALL_LOG=$(mktemp)
PLUG_LOG=$(mktemp)
TS_LOG=$(mktemp)
HEALTH_LOG=$(mktemp)
trap 'rm -f "$INSTALL_LOG" "$PLUG_LOG" "$TS_LOG" "$HEALTH_LOG"' EXIT

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
OK="${GREEN}✓${RESET}"; FAIL="${RED}✗${RESET}"; ARROW="${CYAN}→${RESET}"; WARN="${YELLOW}⚠${RESET}"

print_header() {
    echo
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║    Neovim Lite Config Installer        ║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════╝${RESET}"
    echo
}
section() { echo; echo -e "${BOLD}${CYAN}── $1 ${DIM}────────────────────────────────────${RESET}"; }
step()    { echo -e "  ${ARROW} $1"; }
ok()      { echo -e "  ${OK} $1"; }
warn()    { echo -e "  ${WARN}  ${YELLOW}$1${RESET}"; }
fail()    { echo -e "  ${FAIL} ${RED}$1${RESET}"; }
die()     { fail "$1"; echo; exit 1; }

run_quiet() {
    local label="$1"; shift
    if "$@" > "$INSTALL_LOG" 2>&1; then
        ok "$label"
    else
        fail "$label"
        echo -e "  ${DIM}Last 10 lines of output:${RESET}"
        tail -10 "$INSTALL_LOG" 2>/dev/null || true
        exit 1
    fi
}

# ── Preflight ─────────────────────────────────────────────────────────────────
print_header
section "Checking requirements"

MISSING=()
for cmd in nvim git curl; do
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd  ${DIM}($(command -v $cmd))${RESET}"
    else
        fail "$cmd not found"
        MISSING+=("$cmd")
    fi
done

[ ${#MISSING[@]} -gt 0 ] && die "Missing required commands: ${MISSING[*]}"

# Check nvim >= 0.9
NVIM_VER=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
NVIM_MAJ=$(echo "$NVIM_VER" | cut -d. -f1)
NVIM_MIN=$(echo "$NVIM_VER" | cut -d. -f2)
if [ "$NVIM_MAJ" -lt 1 ] && [ "$NVIM_MIN" -lt 9 ]; then
    die "Neovim >= 0.9 required, found $NVIM_VER"
fi
ok "nvim $NVIM_VER"

# Optional
for cmd in node npm python3 pip3 cargo clangd; do
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd  ${DIM}($(command -v $cmd))${RESET}"
    else
        warn "$cmd not found — some LSP features may not work"
    fi
done

# ── Backup ────────────────────────────────────────────────────────────────────
section "Backing up existing config"

NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
BACKUP_DIR="$HOME/.config/nvim_backup_$(date +%Y%m%d_%H%M%S)"

if [ -d "$NVIM_CONFIG" ]; then
    cp -r "$NVIM_CONFIG" "$BACKUP_DIR"
    ok "Backed up existing config to $BACKUP_DIR"
else
    mkdir -p "$NVIM_CONFIG"
    ok "Created $NVIM_CONFIG"
fi

# ── Copy config ───────────────────────────────────────────────────────────────
section "Installing config"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_VIM="$SCRIPT_DIR/init_lite.vim"

[ -f "$INIT_VIM" ] || die "init_lite.vim not found at $SCRIPT_DIR — place this script next to init_lite.vim"

cp "$INIT_VIM" "$NVIM_CONFIG/init.vim"
ok "Copied init_lite.vim → $NVIM_CONFIG/init.vim"

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

# ── Plugins ───────────────────────────────────────────────────────────────────
section "Installing plugins"

step "Running PlugInstall..."
nvim --headless "+PlugInstall" "+qall" > "$PLUG_LOG" 2>&1 || true

PLUGGED="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/plugged"
if [ -d "$PLUGGED" ] && [ "$(ls -A "$PLUGGED" 2>/dev/null)" ]; then
    ok "Plugins installed"
else
    warn "Plugin dir looks empty — check $PLUG_LOG"
fi

# ── LSP servers ───────────────────────────────────────────────────────────────
section "Installing LSP servers"

if command -v npm &>/dev/null; then
    if npm list -g bash-language-server &>/dev/null 2>&1; then
        ok "bash-language-server already installed"
    else
        run_quiet "bash-language-server" npm install -g bash-language-server
    fi
else
    warn "npm not found — skipping bash-language-server"
fi

if command -v pip3 &>/dev/null; then
    if pip3 show python-lsp-server &>/dev/null 2>&1; then
        ok "python-lsp-server already installed"
    else
        run_quiet "python-lsp-server (pylsp)" pip3 install --user python-lsp-server
    fi
else
    warn "pip3 not found — skipping pylsp"
fi

if command -v clangd &>/dev/null; then
    ok "clangd found at $(command -v clangd)"
else
    warn "clangd not found — install via package manager:"
    warn "  brew install llvm       (macOS)"
    warn "  apt install clangd      (Debian/Ubuntu)"
    warn "  pacman -S clang         (Arch)"
fi

if command -v rustup &>/dev/null; then
    run_quiet "rust-analyzer" rustup component add rust-analyzer
else
    warn "rustup not found — skipping rust-analyzer"
fi

# ── Treesitter ────────────────────────────────────────────────────────────────
section "Installing Treesitter parsers"

step "Running TSUpdateSync (compiles parsers)..."
nvim --headless "+TSUpdateSync" "+qall" > "$TS_LOG" 2>&1 || true
ok "Treesitter parsers installed"

# ── Undo dir ──────────────────────────────────────────────────────────────────
section "Ensuring undo directory"
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/undo"
ok "Undo directory ready"

# ── Health check ──────────────────────────────────────────────────────────────
section "Running health check"

nvim --headless "+checkhealth" "+qall" > "$HEALTH_LOG" 2>&1 || true
ERRORS=$(grep -c "ERROR"   "$HEALTH_LOG" 2>/dev/null || echo 0)
WARNS=$(grep  -c "WARNING" "$HEALTH_LOG" 2>/dev/null || echo 0)

[ "$ERRORS" -gt 0 ] && warn "$ERRORS error(s) — run :checkhealth in nvim to review" || ok "No errors in health check"
[ "$WARNS"  -gt 0 ] && warn "$WARNS warning(s) — run :checkhealth in nvim to review"

# ── Done ──────────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║       Installation complete! 🎉        ║${RESET}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════╝${RESET}"
echo
echo -e "  ${ARROW} Run ${BOLD}:checkhealth${RESET} inside nvim to review any warnings"
[ -d "$BACKUP_DIR" ] && echo -e "  ${ARROW} Previous config backed up to ${DIM}$BACKUP_DIR${RESET}"
echo
