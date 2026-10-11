#!/usr/bin/env bash
# ============================================================
#  Axiom Zeta Sentinel TEAMS - One-Click Installer (macOS/Linux)
#
#  Run: ./install-teams.sh
#
#  What it does:
#    1. Checks for Python 3.10+ and Rust
#    2. Builds the Rust extension (maturin)
#    3. Installs Python dependencies
#    4. Generates a secure API key
#    5. Launches the Sentinel gateway
#
#  First run takes 10-20 minutes (mostly compiling Rust).
#  Every launch after that is instant.
# ============================================================
set -euo pipefail

DRIVE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$DRIVE/teams"

echo ""
echo "============================================================"
echo "  AXIOM ZETA SENTINEL TEAMS - One-Click Installer"
echo "============================================================"
echo ""
echo "  First run takes 10-20 minutes (compiling + installing)."
echo "  It runs unattended - walk away and come back."
echo ""

# ── Step 0: Python ──────────────────────────────────────────
echo "[0/4] Checking Python..."
if ! command -v python3 &>/dev/null; then
    echo "  ERROR: Python 3.10+ is not installed."
    exit 1
fi
python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" || {
    echo "  ERROR: Python 3.10 or newer is required."
    exit 1
}
echo "  Python found: $(python3 --version 2>&1)"

# ── Step 1: Rust ────────────────────────────────────────────
echo ""
echo "[1/4] Checking Rust..."
if ! command -v cargo &>/dev/null; then
    echo "  Rust not found - installing (internet required)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
fi
echo "  Rust found: $(cargo --version 2>&1)"

# ── Step 2: Build + Install ─────────────────────────────────
echo ""
echo "[2/4] Building Sentinel (this is the long step)..."
cd "$APP_DIR"

if [[ ! -d ".venv" ]]; then
    python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate

echo "  Installing build tools..."
pip install -q -U pip maturin

if [[ -d "rust" ]]; then
    echo "  Compiling Rust extension (5-15 minutes)..."
    ( cd rust && maturin develop --release )
fi

echo "  Installing Python dependencies..."
[[ -f "requirements-dev.txt" ]] && pip install -q -r requirements-dev.txt
pip install -q -e .

# ── Step 3: API Key ─────────────────────────────────────────
echo ""
echo "[3/4] Setting up API key..."
if [[ ! -f ".env" ]]; then
    python3 -c "import secrets; print('GATEWAY_API_KEY=' + secrets.token_urlsafe(32))" > .env
    echo "  Generated secure API key in .env"
else
    echo "  Using existing .env"
fi

# ── Step 4: Launch ──────────────────────────────────────────
echo ""
echo "[4/4] Launching Sentinel TEAMS..."
echo ""
echo "============================================================"
echo "  SENTINEL TEAMS IS RUNNING"
echo ""
echo "  API: http://localhost:8000"
echo "  Health: http://localhost:8000/v1/health"
echo ""
KEY=$(grep GATEWAY_API_KEY .env | cut -d= -f2)
echo "  Your API key: $KEY"
echo "  (Save this - you'll need it for API requests)"
echo ""
echo "  Example:"
echo "  curl -X POST http://localhost:8000/v1/stabilize \\"
echo "    -H \"X-API-Key: \$KEY\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"tenant_id\":\"acme\",\"text\":\"hello\"}'"
echo "============================================================"
echo ""
export GATEWAY_API_KEY="$KEY"
exec .venv/bin/uvicorn gateway.main:app --port 8000
