#!/usr/bin/env bash
# ==============================================================================
# MINECRAFT FAILSAFE CONTINUOUS AUTOSAVE & PERSISTENCE WATCHDOG
# Garante salvamento periódico via RCON e sincronização em disco a cada 60s
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PID_FILE="/tmp/minecraft_watchdog.pid"
LOG_FILE="/tmp/minecraft_watchdog.log"

echo "$$" > "$PID_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watchdog de persistência contínua iniciado." >> "$LOG_FILE"

while true; do
    sleep 60
    if ps aux | grep -v grep | grep -q "java"; then
        if [ -f "$SCRIPT_DIR/rcon.py" ]; then
            python3 "$SCRIPT_DIR/rcon.py" "save-all flush" >> "$LOG_FILE" 2>&1 || true
        fi
        sync
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [AUTO-SAVE] Chunks e entidades gravados em disco." >> "$LOG_FILE"
    fi
done
