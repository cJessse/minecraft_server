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
        log ">>> [CRON] Encerrando serviços (Graceful Shutdown), gerando backup e desligando Codespace..."
        gh codespace ssh -c "$CODESPACE_NAME" -- "cd /workspaces/minecraft_server && ./manager.sh stop-backup" >> "$LOG_FILE" 2>&1 || true
        gh codespace stop -c "$CODESPACE_NAME" >> "$LOG_FILE" 2>&1
        log ">>> [CRON] Codespace finalizado com sucesso."
        ;;
    save|sync)
        log ">>> [CRON] Forçando gravação e flush do mundo no disco..."
        gh codespace ssh -c "$CODESPACE_NAME" -- "cd /workspaces/minecraft_server && ./manager.sh save" >> "$LOG_FILE" 2>&1 || true
        log ">>> [CRON] Mundo sincronizado no disco."
        ;;
    heartbeat|keepalive|ping)
        STATE=$(gh codespace view -c "$CODESPACE_NAME" --json state --jq .state 2>/dev/null || echo "Unknown")
        if [ "$STATE" = "Available" ]; then
            log ">>> [HEARTBEAT] Renovando atividade e forçando sync de chunks no Codespace..."
            gh codespace ssh -c "$CODESPACE_NAME" -- "sync && cd /workspaces/minecraft_server && ./manager.sh status" >> "$LOG_FILE" 2>&1
            log ">>> [HEARTBEAT] Atividade renovada com sucesso (Idle timer resetado e disco sincronizado)."
        else
            log ">>> [HEARTBEAT] Codespace em estado '$STATE' durante a janela ativa! Reativando serviços..."
            gh codespace ssh -c "$CODESPACE_NAME" -- "cd /workspaces/minecraft_server && ./manager.sh start" >> "$LOG_FILE" 2>&1
            log ">>> [HEARTBEAT] Servidor e Codespace reativados com sucesso."
        fi
        ;;
    session|loop)
        DURATION_MINUTES="${2:-120}"
        INTERVAL_SECONDS=300
        TOTAL_SECONDS=$((DURATION_MINUTES * 60))
        ELAPSED=0

        log ">>> [SESSION] Iniciando sessão supervisionada de ${DURATION_MINUTES} minutos..."
        gh codespace ssh -c "$CODESPACE_NAME" -- "cd /workspaces/minecraft_server && ./manager.sh start" >> "$LOG_FILE" 2>&1

        while [ "$ELAPSED" -lt "$TOTAL_SECONDS" ]; do
            sleep "$INTERVAL_SECONDS"
            ELAPSED=$((ELAPSED + INTERVAL_SECONDS))
            REMAINING=$(( (TOTAL_SECONDS - ELAPSED) / 60 ))
            log ">>> [SESSION] Keepalive ativo (${REMAINING}m restantes)..."
            gh codespace ssh -c "$CODESPACE_NAME" -- "sync && cd /workspaces/minecraft_server && ./manager.sh status" >> "$LOG_FILE" 2>&1 || true
        done

        log ">>> [SESSION] Tempo de sessão esgotado (${DURATION_MINUTES}m). Encerrando..."
        gh codespace ssh -c "$CODESPACE_NAME" -- "cd /workspaces/minecraft_server && ./manager.sh stop-backup" >> "$LOG_FILE" 2>&1 || true
        gh codespace stop -c "$CODESPACE_NAME" >> "$LOG_FILE" 2>&1
        log ">>> [SESSION] Sessão finalizada com sucesso."
        ;;
    *)
        echo "Uso: $0 {start|stop|save|heartbeat|session [duracao_minutos]}"
        exit 1
        ;;
esac
