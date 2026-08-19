#!/usr/bin/env bash
# ==============================================================================
# MINECRAFT CODESPACE CRON CONTROLLER (Local / Server)
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"

if [ -f "$ROOT_DIR/config/config.env" ]; then
    # shellcheck disable=SC1091
    source "$ROOT_DIR/config/config.env"
fi

ACTION="${1:-auto}"
# Permite definir no config.env ou autodetecta pelo repositório atual via gh CLI
CODESPACE_NAME="${CODESPACE_NAME:-$(gh codespace list --json name,repository --jq '.[] | select(.repository | endswith("/minecraft_server")) | .name' 2>/dev/null | head -n1)}"
LOG_FILE="${LOG_FILE:-$ROOT_DIR/cron_schedule.log}"

if [ -z "$CODESPACE_NAME" ]; then
    CODESPACE_NAME="$(gh codespace list --json name --jq '.[0].name' 2>/dev/null || true)"
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

case "$ACTION" in
    start)
        log ">>> [CRON] Iniciando Codespace e subindo serviços de Minecraft..."
        gh codespace ssh -c "$CODESPACE_NAME" -- "cd /workspaces/minecraft_server && ./manager.sh start" >> "$LOG_FILE" 2>&1
        log ">>> [CRON] Servidor inicializado com sucesso."
        ;;
    stop)
        log ">>> [CRON] Encerrando serviços, gerando backup e desligando Codespace..."
        gh codespace ssh -c "$CODESPACE_NAME" -- "cd /workspaces/minecraft_server && ./manager.sh stop-backup" >> "$LOG_FILE" 2>&1 || true
        gh codespace stop -c "$CODESPACE_NAME" >> "$LOG_FILE" 2>&1
        log ">>> [CRON] Codespace finalizado com sucesso."
        ;;
    heartbeat|keepalive|ping)
        STATE=$(gh codespace view -c "$CODESPACE_NAME" --json state --jq .state 2>/dev/null || echo "Unknown")
        if [ "$STATE" = "Available" ]; then
            log ">>> [HEARTBEAT] Renovando atividade no Codespace..."
            gh codespace ssh -c "$CODESPACE_NAME" -- "echo keepalive > /dev/null" >> "$LOG_FILE" 2>&1
            log ">>> [HEARTBEAT] Atividade renovada com sucesso (Idle timer resetado)."
        else
            log ">>> [HEARTBEAT] Codespace em estado '$STATE', nenhum keepalive necessário."
        fi
        ;;
    *)
        echo "Uso: $0 {start|stop|heartbeat}"
        exit 1
        ;;
esac
