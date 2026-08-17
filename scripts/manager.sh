#!/usr/bin/env bash
# ==============================================================================
# MINECRAFT & CRAFTY CENTRAL MANAGER (GENERIC TEMPLATE)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# Carregar arquivo de configuração (procura em config/ ou na raiz)
if [ -f "$ROOT_DIR/config/config.env" ]; then
    # shellcheck disable=SC1091
    source "$ROOT_DIR/config/config.env"
elif [ -f "$ROOT_DIR/config.env" ]; then
    # shellcheck disable=SC1091
    source "$ROOT_DIR/config.env"
fi

# Variáveis com fallbacks inteligentes
WORKSPACE_DIR="${SERVER_ROOT_DIR:-$ROOT_DIR}"
CRAFTY_DIR="$WORKSPACE_DIR/minecraft/crafty"
BACKUP_DIR="$WORKSPACE_DIR/${BACKUP_DIR:-backups}"
REMOTE_DRIVE="${RCLONE_REMOTE:-drive:Minecraft_Backups}"
PLAYIT_SOCKET_DIR="${PLAYIT_SOCKET_DIR:-/tmp/playit}"
BACKUP_RETENTION_LOCAL="${BACKUP_RETENTION_LOCAL:-3}"
SERVER_MODE="${SERVER_MODE:-crafty}"

# Paleta de Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

status_services() {
    echo -e "\n══════════════════════════════════════════════════════"
    echo -e "             STATUS ATUAL DOS SERVIÇOS                 "
    echo -e "══════════════════════════════════════════════════════"

    # Crafty Controller
    if ps aux | grep -v grep | grep -q "python3 main.py"; then
        PID=$(ps aux | grep -v grep | grep "python3 main.py" | awk '{print $2}' | head -1)
        echo -e "  Crafty Controller:  ${GREEN}● ATIVO${NC} (PID: $PID)"
    else
        echo -e "  Crafty Controller:  ${RED}○ PARADO${NC}"
    fi

    # Playit
    if ps aux | grep -v grep | grep -q "playitd"; then
        PID=$(ps aux | grep -v grep | grep "playitd" | awk '{print $2}' | head -1)
        echo -e "  Playit.gg Tunnel:   ${GREEN}● ATIVO${NC} (PID: $PID)"
    else
        echo -e "  Playit.gg Tunnel:   ${RED}○ PARADO${NC}"
    fi

    # Servidor Minecraft (Processo Java)
    if ps aux | grep -v grep | grep -q "java"; then
        PID=$(ps aux | grep -v grep | grep "java" | awk '{print $2}' | head -1)
        echo -e "  Servidor Minecraft: ${GREEN}● ATIVO${NC} (PID: $PID)"
    else
        echo -e "  Servidor Minecraft: ${RED}○ PARADO${NC}"
    fi

    # Portas em escuta
    echo -e "\n  Portas em escuta:"
    if command -v ss &>/dev/null; then
        sudo ss -tulpn 2>/dev/null | grep -E '8443|25565' | awk '{print "    - " $1, $5}' || echo "    Nenhuma porta ativa detectada."
    elif command -v netstat &>/dev/null; then
        sudo netstat -tulpn 2>/dev/null | grep -E '8443|25565' | awk '{print "    - " $1, $4}' || echo "    Nenhuma porta ativa detectada."
    else
        echo "    (Instale net-tools ou iproute2 para checar portas)"
    fi
    echo -e "══════════════════════════════════════════════════════\n"
}

start_services() {
    echo -e "\n>>> Iniciando serviços..."

    # 1. Iniciar Playit daemon
    if [ "${ENABLE_PLAYIT:-true}" = "true" ]; then
        echo -n "Iniciando Playit daemon... "
        sudo mkdir -p /run/playit "$PLAYIT_SOCKET_DIR" 2>/dev/null || true
        sudo ln -sf "$PLAYIT_SOCKET_DIR/playitd.sock" /run/playit/playitd.sock 2>/dev/null || true
        if ! pgrep -f "playitd" > /dev/null; then
            if command -v playitd &> /dev/null; then
                sudo playitd --socket-path "$PLAYIT_SOCKET_DIR/playitd.sock" > /tmp/playit.log 2>&1 &
                sleep 2
                echo -e "${GREEN}OK${NC}"
            else
                echo -e "${RED}playitd não encontrado! Execute ./scripts/setup.sh primeiro.${NC}"
            fi
        else
            echo -e "${YELLOW}Já em execução${NC}"
        fi
    fi

    # 2. Iniciar Crafty Controller
    if [ "$SERVER_MODE" = "crafty" ]; then
        echo -n "Iniciando Crafty Controller... "
        if ! pgrep -f "python3 main.py" > /dev/null; then
            if [ -d "$CRAFTY_DIR/.venv" ] && [ -d "$CRAFTY_DIR/crafty-4" ]; then
                cd "$CRAFTY_DIR"
                # shellcheck disable=SC1091
                source .venv/bin/activate
                cd crafty-4
                nohup python3 main.py --daemon > "$CRAFTY_DIR/crafty_daemon.log" 2>&1 &
                cd "$ROOT_DIR"
                echo -e "${GREEN}OK${NC}"
            else
                echo -e "${RED}Ambiente do Crafty não encontrado. Execute ./scripts/setup.sh!${NC}"
            fi
        else
            echo -e "${YELLOW}Já em execução${NC}"
        fi
    fi

    # 3. Aguardar inicialização e verificar subida do Servidor Minecraft (Java / Portas)
    echo -n "Aguardando inicialização do servidor Minecraft..."
    for i in $(seq 1 15); do
        if ps aux | grep -v grep | grep -q "java"; then
            echo -e " ${GREEN}✓ Servidor Minecraft (Java) ATIVO!${NC}"
            break
        fi
        sleep 1
        echo -n "."
    done

    if ! ps aux | grep -v grep | grep -q "java"; then
        echo -e " ${YELLOW}(Crafty iniciado; aguardando autostart do mundo no painel...)${NC}"
    fi

    echo -e "✓ Painel Crafty: ${CYAN}https://localhost:8443${NC}"
    echo -e "✓ Porta Minecraft: ${CYAN}25565${NC}"
}

stop_services() {
    echo -e "\n>>> Encerrando todos os serviços..."

    # Minecraft Java
    if ps aux | grep -v grep | grep -q "java"; then
        echo -n "Parando servidor Minecraft (Java)... "
        pkill -f "java" || true
        echo -e "${GREEN}OK${NC}"
    fi

    # Crafty Controller
    if ps aux | grep -v grep | grep -q "python3 main.py"; then
        echo -n "Parando Crafty Controller... "
        pkill -f "python3 main.py" || true
        echo -e "${GREEN}OK${NC}"
    fi

    # Playit.gg
    if ps aux | grep -v grep | grep -q "playitd"; then
        echo -n "Parando Playit.gg... "
        sudo pkill -f "playitd" || true
        echo -e "${GREEN}OK${NC}"
    fi

    sleep 2
    echo -e "✓ Todos os serviços foram finalizados e as portas liberadas!"
}

backup_world() {
    echo -e "\n>>> Executando rotina de backup do mundo..."
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/minecraft_world_${TIMESTAMP}.tar.gz"

    echo "Localizando dados do mundo..."
    TARGET_DIR=""
    if [ -d "$WORKSPACE_DIR/minecraft/crafty/crafty-4/servers" ]; then
        SERVER_INSTANCE=$(find "$WORKSPACE_DIR/minecraft/crafty/crafty-4/servers" -mindepth 1 -maxdepth 1 -type d | head -1)
        if [ -n "$SERVER_INSTANCE" ] && [ -d "$SERVER_INSTANCE/world" ]; then
            TARGET_DIR="$SERVER_INSTANCE/world"
        fi
    fi

    if [ -z "$TARGET_DIR" ] && [ -d "$WORKSPACE_DIR/world" ]; then
        TARGET_DIR="$WORKSPACE_DIR/world"
    fi

    if [ -n "$TARGET_DIR" ] && [ -d "$TARGET_DIR" ]; then
        PARENT_DIR=$(dirname "$TARGET_DIR")
        BASE_NAME=$(basename "$TARGET_DIR")
        tar -czf "$BACKUP_FILE" -C "$PARENT_DIR" "$BASE_NAME"
        SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo -e "✓ Backup gerado: ${CYAN}$BACKUP_FILE${NC} ($SIZE)"
    else
        echo -e "${YELLOW}Nenhuma pasta 'world' encontrada ainda para backup.${NC}"
        return 0
    fi

    # Sincronização via rclone
    if command -v rclone &> /dev/null && [ -n "$REMOTE_DRIVE" ]; then
        REMOTE_NAME=$(echo "$REMOTE_DRIVE" | cut -d: -f1)
        if rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
            echo "Enviando para a nuvem ($REMOTE_DRIVE)..."
            rclone mkdir "$REMOTE_DRIVE" 2>/dev/null || true
            rclone copy "$BACKUP_FILE" "$REMOTE_DRIVE" --progress
            echo -e "${GREEN}✓ Sincronizado com o armazenamento em nuvem!${NC}"
        else
            echo -e "${YELLOW}Aviso: Remote '${REMOTE_NAME}:' não autenticado no rclone. Backup salvo localmente.${NC}"
        fi
    fi

    # Limpeza de backups antigos locais
    echo "Limpando backups locais antigos (mantendo os últimos $BACKUP_RETENTION_LOCAL)..."
    # shellcheck disable=SC2012
    ls -dt "$BACKUP_DIR"/minecraft_world_*.tar.gz 2>/dev/null | tail -n "+$((BACKUP_RETENTION_LOCAL + 1))" | xargs -r rm -- 2>/dev/null || true
}

shutdown_environment() {
    echo -e "\n>>> Encerrando o ambiente..."
    read -rp "Tem certeza que deseja suspender/desligar a máquina? (s/N): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        echo -e "Desligando em 3 segundos..."
        sleep 2
        # Detectar se está no GitHub Codespaces
        if [ -n "$CODESPACE_NAME" ] && command -v gh &> /dev/null; then
            gh codespace stop -c "$CODESPACE_NAME" || true
        fi
        sudo shutdown -h now 2>/dev/null || exit 0
    else
        echo -e "Operação cancelada."
    fi
}

view_logs() {
    echo -e "\nEscolha o log para visualizar:"
    echo "1) Crafty Controller Log"
    echo "2) Minecraft Server Log"
    echo "3) Playit.gg Tunnel Log"
    echo "4) Voltar"
    read -rp "Opção: " log_opt

    case $log_opt in
        1) tail -n 50 -f "$CRAFTY_DIR/crafty.log" 2>/dev/null || tail -n 50 -f "$CRAFTY_DIR/crafty_daemon.log" 2>/dev/null || echo "Log não encontrado." ;;
        2) 
            MC_LOG=$(find "$WORKSPACE_DIR" -name "latest.log" 2>/dev/null | head -1)
            if [ -n "$MC_LOG" ]; then
                tail -n 50 -f "$MC_LOG"
            else
                echo "Arquivo latest.log do Minecraft não encontrado."
            fi
            ;;
        3) tail -n 50 -f /tmp/playit.log 2>/dev/null || echo "Log do Playit não encontrado." ;;
        *) return ;;
    esac
}

# Suporte a argumentos de linha de comando não interativos (CI/CD, Cron, Actions)
if [ -n "$1" ]; then
    case "$1" in
        1|start|iniciar)
            start_services
            status_services
            exit 0
            ;;
        2|stop|parar)
            stop_services
            status_services
            exit 0
            ;;
        3|backup)
            backup_world
            exit 0
            ;;
        4|stop-backup)
            stop_services
            backup_world
            exit 0
            ;;
        5|shutdown)
            stop_services
            backup_world
            shutdown_environment
            exit 0
            ;;
        optimize|otimizar)
            if [ -f "$SCRIPT_DIR/optimize_server.sh" ]; then
                bash "$SCRIPT_DIR/optimize_server.sh"
            fi
            exit 0
            ;;
        status)
            status_services
            exit 0
            ;;
        *)
            echo "Uso: $0 [start|stop|backup|stop-backup|shutdown|optimize|status]"
            exit 1
            ;;
    esac
fi

# Loop do Menu Principal Interativo
while true; do
    status_services
    echo -e "O que deseja fazer?"
    echo "1) Iniciar Servidor & Serviços (Crafty + Playit)"
    echo "2) Parar todos os serviços"
    echo "3) Fazer Backup e Sincronizar na Nuvem"
    echo "4) Parar Serviços + Backup Geral"
    echo "5) Parar Serviços + Backup + Desligar/Suspender Máquina"
    echo "6) Ver Logs em tempo real"
    echo "7) Aplicar Otimizações Anti-Lag (server.properties)"
    echo "0) Sair"
    echo "------------------------------------------------------"
    read -rp "Digite a opção [0-7]: " option

    case $option in
        1) start_services ;;
        2) stop_services ;;
        3) backup_world ;;
        4)
            stop_services
            backup_world
            ;;
        5)
            stop_services
            backup_world
            shutdown_environment
            ;;
        6) view_logs ;;
        7)
            if [ -f "$SCRIPT_DIR/optimize_server.sh" ]; then
                bash "$SCRIPT_DIR/optimize_server.sh"
            fi
            ;;
        0) echo "Até logo!"; exit 0 ;;
        *) echo -e "${RED}Opção inválida!${NC}" ;;
    esac
    echo ""
    read -rp "Pressione [Enter] para continuar..."
done
