#!/usr/bin/env bash
# ==============================================================================
# MINECRAFT CODESPACE CRON CONTROLLER (Local / Server)
# ==============================================================================
ACTION="${1:-auto}"
CODESPACE_NAME="urban-winner-wrgrpvg5v9j9c9r7j"
LOG_FILE="$HOME/projetos/minecraft_server/cron_schedule.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

case "$ACTION" in
    start)
        log ">>> [CRON] Iniciando Codespace e subindo serviços de Minecraft..."
        gh codespace ssh -c "$CODESPACE_NAME" -- "cd /workspaces/minecraft_server && ./manager.sh 1" >> "$LOG_FILE" 2>&1
        log ">>> [CRON] Servidor inicializado com sucesso."
        ;;
    stop)
        log ">>> [CRON] Encerrando serviços, gerando backup e desligando Codespace..."
        gh codespace ssh -c "$CODESPACE_NAME" -- "cd /workspaces/minecraft_server && ./manager.sh 4" >> "$LOG_FILE" 2>&1 || true
        gh codespace stop -c "$CODESPACE_NAME" >> "$LOG_FILE" 2>&1
        log ">>> [CRON] Codespace finalizado com sucesso."
        ;;
    *)
        echo "Uso: $0 {start|stop}"
        exit 1
        ;;
esac
