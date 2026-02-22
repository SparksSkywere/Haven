#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# Haven — Cross-Platform Launcher (Linux / macOS)
# Usage: chmod +x start.sh && ./start.sh
# ═══════════════════════════════════════════════════════════
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

# ── Data directory (./data) ──────────────────────────────
HAVEN_DATA="${HAVEN_DATA_DIR:-$DIR/data}"
mkdir -p "$HAVEN_DATA"

echo ""
echo -e "${GREEN}${BOLD}  ========================================${NC}"
echo -e "${GREEN}${BOLD}       HAVEN — Private Chat Server${NC}"
echo -e "${GREEN}${BOLD}  ========================================${NC}"
echo ""

# ── Pre-read PORT from project .env so we kill the right process ──
HAVEN_PORT=3000
if [ -f "$HAVEN_DATA/.env" ]; then
    while IFS='=' read -r key value; do
        case "$key" in
            PORT) HAVEN_PORT="$value" ;;
        esac
    done < "$HAVEN_DATA/.env"
elif [ -f "$DIR/.env" ]; then
    while IFS='=' read -r key value; do
        case "$key" in
            PORT) HAVEN_PORT="$value" ;;
        esac
    done < "$DIR/.env"
fi

# ── Kill existing server on configured port ────────────────
if command -v lsof &> /dev/null && lsof -ti:"$HAVEN_PORT" &> /dev/null; then
    echo "  [!] Killing existing process on port $HAVEN_PORT..."
    lsof -ti:"$HAVEN_PORT" | xargs kill -9 2>/dev/null || true
    sleep 1
fi

# ── Network connectivity check ────────────────────────────
echo "  [*] Checking network connectivity..."
NETWORK_OK=0
if ping -c 1 -W 3 1.1.1.1 &> /dev/null; then
    NETWORK_OK=1
elif ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
    NETWORK_OK=1
fi

if [ "$NETWORK_OK" = "1" ]; then
    echo "  [OK] Internet connection available"
else
    echo -e "${YELLOW}  [!] WARNING: No internet connection detected.${NC}"
    echo "      Haven will work on your local network only."
    echo "      Remote access will not be available."
fi

# ── Detect LAN IP ──────────────────────────────────────────
LAN_IP="YOUR_LOCAL_IP"
if command -v hostname &> /dev/null && hostname -I &> /dev/null 2>&1; then
    LAN_IP=$(hostname -I | awk '{print $1}')
elif command -v ipconfig &> /dev/null; then
    LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "YOUR_LOCAL_IP")
elif command -v ip &> /dev/null; then
    LAN_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
fi

# ── Detect public IP (if online) ──────────────────────────
PUBLIC_IP="YOUR_PUBLIC_IP"
if [ "$NETWORK_OK" = "1" ]; then
    if command -v curl &> /dev/null; then
        PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "YOUR_PUBLIC_IP")
    elif command -v wget &> /dev/null; then
        PUBLIC_IP=$(wget -qO- --timeout=5 https://api.ipify.org 2>/dev/null || echo "YOUR_PUBLIC_IP")
    fi
    if [ "$PUBLIC_IP" != "YOUR_PUBLIC_IP" ]; then
        echo "  [OK] Public IP: $PUBLIC_IP"
    else
        echo "  [!] Could not detect public IP"
    fi
fi

# ── Port availability check ───────────────────────────────
echo "  [*] Checking port $HAVEN_PORT availability..."
if command -v lsof &> /dev/null && lsof -ti:"$HAVEN_PORT" &> /dev/null; then
    echo -e "${YELLOW}  [!] WARNING: Port $HAVEN_PORT is still in use by another process.${NC}"
    echo "      Haven may fail to start. Check for conflicting services."
elif command -v ss &> /dev/null && ss -tlnp 2>/dev/null | grep -q ":$HAVEN_PORT "; then
    echo -e "${YELLOW}  [!] WARNING: Port $HAVEN_PORT is still in use by another process.${NC}"
    echo "      Haven may fail to start. Check for conflicting services."
else
    echo "  [OK] Port $HAVEN_PORT is available"
fi

# ── Check Node.js ──────────────────────────────────────────
if ! command -v node &> /dev/null; then
    echo -e "${RED}  [ERROR] Node.js is not installed.${NC}"
    echo "  Install it from https://nodejs.org or:"
    echo "    Ubuntu/Debian:  sudo apt install nodejs npm"
    echo "    macOS (brew):   brew install node"
    echo "    Fedora:         sudo dnf install nodejs"
    echo "    Arch:           sudo pacman -S nodejs npm"
    exit 1
fi

NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
echo "  [OK] Node.js $(node -v) detected"

if [ "$NODE_VER" -lt 18 ]; then
    echo -e "${YELLOW}  [!] Node.js 18+ recommended. You have v${NODE_VER}.${NC}"
fi

# Warn if Node major version is too new (native modules won't have prebuilts)
if [ "$NODE_VER" -ge 24 ]; then
    echo -e "${YELLOW}"
    echo "  [!] WARNING: Node.js v${NODE_VER} detected. Haven requires Node 18-22."
    echo "      Native modules like better-sqlite3 may not have prebuilt"
    echo "      binaries yet, causing build failures."
    echo ""
    echo "      Please install Node.js 22 LTS from https://nodejs.org"
    echo -e "${NC}"
    exit 1
fi

# ── Install / update dependencies ──────────────────────────
echo "  [*] Checking dependencies..."
npm install --no-audit --no-fund 2>&1
echo "  [OK] Dependencies ready"
echo ""

# ── Sync .env into data directory ──────────────────────────
# Priority: project-dir .env → existing data-dir .env → .env.example
if [ -f "$DIR/.env" ]; then
    echo "  [*] Found .env in project directory — copying to $HAVEN_DATA"
    cp -f "$DIR/.env" "$HAVEN_DATA/.env"
elif [ ! -f "$HAVEN_DATA/.env" ]; then
    if [ -f "$DIR/.env.example" ]; then
        echo "  [*] Creating .env in $HAVEN_DATA from template..."
        cp "$DIR/.env.example" "$HAVEN_DATA/.env"
    fi
    echo -e "${YELLOW}  [!] IMPORTANT: Edit $HAVEN_DATA/.env and change your settings before going live!${NC}"
    echo ""
fi

# ── Read PORT, HOST and FORCE_HTTP from .env ──────────────
HAVEN_PORT=3000
HAVEN_HOST=""
FORCE_HTTP="false"
if [ -f "$HAVEN_DATA/.env" ]; then
    while IFS='=' read -r key value; do
        case "$key" in
            PORT) HAVEN_PORT="$value" ;;
            HOST) HAVEN_HOST="$value" ;;
            FORCE_HTTP) FORCE_HTTP="$value" ;;
        esac
    done < "$HAVEN_DATA/.env"
fi
# 0.0.0.0 means all interfaces so localhost works; a specific IP must be used directly
HAVEN_ADDR="localhost"
if [ -n "$HAVEN_HOST" ] && [ "$HAVEN_HOST" != "0.0.0.0" ]; then
    HAVEN_ADDR="$HAVEN_HOST"
fi
echo "  [OK] Using port $HAVEN_PORT  (host: $HAVEN_ADDR)"

# ── Generate SSL certs in data directory if missing ────────
if [ "$FORCE_HTTP" = "true" ]; then
    echo "  [*] FORCE_HTTP=true — skipping SSL certificate generation"
    echo ""
elif [ ! -f "$HAVEN_DATA/certs/cert.pem" ]; then
    echo "  [*] Generating self-signed SSL certificate..."
    mkdir -p "$HAVEN_DATA/certs"

    if ! command -v openssl &> /dev/null; then
        echo "  [!] OpenSSL not found — skipping cert generation."
        echo "      Haven will run in HTTP mode. See GUIDE.md for details."
        echo "      To enable HTTPS, install OpenSSL or provide certs manually."
    else
        LOCAL_IP="$LAN_IP"

        openssl req -x509 -newkey rsa:2048 \
            -keyout "$HAVEN_DATA/certs/key.pem" -out "$HAVEN_DATA/certs/cert.pem" \
            -days 3650 -nodes -subj "/CN=Haven" \
            -addext "subjectAltName=IP:127.0.0.1,IP:${LOCAL_IP},DNS:localhost" \
            2>/dev/null

        if [ -f "$HAVEN_DATA/certs/cert.pem" ]; then
            echo "  [OK] SSL cert generated (covers ${LOCAL_IP})"
        else
            echo "  [!] SSL certificate generation failed."
            echo "      Haven will run in HTTP mode. See GUIDE.md for details."
        fi
    fi
    echo ""
fi

echo "  [*] Data directory: $HAVEN_DATA"
echo "  [*] Starting Haven server..."
echo ""

# ── Start server ───────────────────────────────────────────
HAVEN_QUIET=1 node server.js &
SERVER_PID=$!

# Wait for server to be ready
for i in $(seq 1 15); do
    sleep 1
    if curl -sk "https://${HAVEN_ADDR}:${HAVEN_PORT}/api/health" &> /dev/null || \
       curl -sk "http://${HAVEN_ADDR}:${HAVEN_PORT}/api/health" &> /dev/null; then
        break
    fi
    if [ $i -eq 15 ]; then
        echo -e "${RED}  [ERROR] Server failed to start after 15 seconds.${NC}"
        kill $SERVER_PID 2>/dev/null || true
        exit 1
    fi
done

# ── Detect protocol ───────────────────────────────────────
HAVEN_PROTO="http"
if [ "$FORCE_HTTP" = "true" ]; then
    HAVEN_PROTO="http"
elif [ -f "$HAVEN_DATA/certs/cert.pem" ] && [ -f "$HAVEN_DATA/certs/key.pem" ]; then
    HAVEN_PROTO="https"
fi

echo ""
if [ "$HAVEN_PROTO" = "https" ]; then
    echo -e "${GREEN}${BOLD}  ========================================${NC}"
    echo -e "${GREEN}${BOLD}    Haven is LIVE on port ${HAVEN_PORT} (HTTPS)${NC}"
    echo -e "${GREEN}${BOLD}  ========================================${NC}"
    echo ""
    echo "  Local:   https://${HAVEN_ADDR}:${HAVEN_PORT}"
    echo "  LAN:     https://${LAN_IP}:${HAVEN_PORT}"
    echo "  Remote:  https://${PUBLIC_IP}:${HAVEN_PORT}"
    echo ""
    echo "  First time? Browser will show a certificate warning."
    echo "  Click 'Advanced' then 'Proceed' (self-signed cert)."
else
    echo -e "${GREEN}${BOLD}  ========================================${NC}"
    echo -e "${GREEN}${BOLD}    Haven is LIVE on port ${HAVEN_PORT} (HTTP)${NC}"
    echo -e "${GREEN}${BOLD}  ========================================${NC}"
    echo ""
    echo "  Local:   http://${HAVEN_ADDR}:${HAVEN_PORT}"
    echo "  LAN:     http://${LAN_IP}:${HAVEN_PORT}"
    echo "  Remote:  http://${PUBLIC_IP}:${HAVEN_PORT}"
    echo ""
    echo "  NOTE: Running without SSL. Voice chat and"
    echo "  remote connections work best with HTTPS."
    echo "  See GUIDE.md for how to enable HTTPS."
fi
echo ""

# ── Open browser (platform-specific) ──────────────────────
if command -v xdg-open &> /dev/null; then
    xdg-open "${HAVEN_PROTO}://${HAVEN_ADDR}:${HAVEN_PORT}" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "${HAVEN_PROTO}://${HAVEN_ADDR}:${HAVEN_PORT}" 2>/dev/null &
fi

echo "  Press Ctrl+C to stop the server."
echo ""

# Keep alive — clean shutdown on Ctrl+C
trap "echo ''; echo '  Shutting down Haven...'; kill $SERVER_PID 2>/dev/null; exit 0" INT TERM
wait $SERVER_PID
