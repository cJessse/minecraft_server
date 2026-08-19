#!/usr/bin/env bash
# ==============================================================================
# MINECRAFT SERVER ANTI-LAG & EXPLORATION OPTIMIZER
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Carregar arquivo de configuração se existir
if [ -f "$ROOT_DIR/config/config.env" ]; then
    # shellcheck disable=SC1091
    source "$ROOT_DIR/config/config.env"
fi

WORKSPACE_DIR="${SERVER_ROOT_DIR:-$ROOT_DIR}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}      MINECRAFT SERVER ANTI-LAG & TPS OPTIMIZER       ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}\n"

# 1. Localizar instâncias e arquivos server.properties
SEARCH_PATHS=(
    "$WORKSPACE_DIR/minecraft/crafty/crafty-4/servers"
    "$WORKSPACE_DIR/servers"
    "$WORKSPACE_DIR"
)

PROPERTIES_FILES=()
for path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        while IFS= read -r -d '' file; do
            PROPERTIES_FILES+=("$file")
        done < <(find "$path" -maxdepth 3 -name "server.properties" -print0 2>/dev/null)
    fi
done

set_property() {
    local file="$1"
    local key="$2"
    local val="$3"
    if grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$file"
    else
        echo "${key}=${val}" >> "$file"
    fi
}

if [ ${#PROPERTIES_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}[!] Nenhum arquivo 'server.properties' ativo encontrado.${NC}"
    echo -e "    O template padrão em config/templates foi otimizado para novas instâncias."
else
    echo -e "Encontrado(s) ${#PROPERTIES_FILES[@]} arquivo(s) server.properties para otimização:"
    for prop in "${PROPERTIES_FILES[@]}"; do
        echo -e "\n${BLUE}Otimizando:${NC} ${CYAN}$prop${NC}"
        cp "$prop" "${prop}.bak_$(date +%Y%m%d_%H%M%S)"
        
        # Aplicar parâmetros de baixo lag
        set_property "$prop" "view-distance" "7"
        set_property "$prop" "simulation-distance" "5"
        set_property "$prop" "sync-chunk-writes" "false"
        set_property "$prop" "network-compression-threshold" "512"
        set_property "$prop" "entity-broadcast-range-percentage" "80"
        
        echo -e "  ${GREEN}✓ view-distance=7${NC} (reduz carga de chunks em exploração)"
        echo -e "  ${GREEN}✓ simulation-distance=5${NC} (mantém IA/mobs leves)"
        echo -e "  ${GREEN}✓ sync-chunk-writes=false${NC} (escrita assíncrona no disco)"
        echo -e "  ${GREEN}✓ network-compression-threshold=512${NC} (otimização de pacotes de rede)"
        echo -e "  ${GREEN}✓ entity-broadcast-range-percentage=80${NC} (reduz sincronização de mobs distantes)"

        # Otimizar configurações PaperMC se presentes no mesmo diretório
        SERVER_DIR="$(dirname "$prop")"
        CONFIG_DIR="$SERVER_DIR/config"
        
        if [ -d "$CONFIG_DIR" ] && [ -f "$ROOT_DIR/config/templates/paper-world-defaults.yml" ]; then
            echo -e "  ${BLUE}Aplicando otimizações do PaperMC...${NC}"
            cp "$ROOT_DIR/config/templates/paper-world-defaults.yml" "$CONFIG_DIR/paper-world-defaults.yml"
            echo -e "  ${GREEN}✓ config/paper-world-defaults.yml aplicado.${NC}"
        fi

        if [ -f "$ROOT_DIR/config/templates/spigot.yml.template" ]; then
            echo -e "  ${BLUE}Aplicando otimizações do Spigot...${NC}"
            cp "$ROOT_DIR/config/templates/spigot.yml.template" "$SERVER_DIR/spigot.yml"
            echo -e "  ${GREEN}✓ spigot.yml aplicado.${NC}"
        fi
    done
fi

# 2. Exibir Aikar's Flags recomendadas para inicialização
echo -e "\n${CYAN}──────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}Flags JVM Aikar Recomendadas (Para 4GB - 6GB de RAM):${NC}"
echo -e "${CYAN}──────────────────────────────────────────────────────${NC}"
echo -e "Ao iniciar o jar diretamente ou configurar no Crafty:"
echo -e "${GREEN}java -Xms4G -Xmx4G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -jar server.jar --nogui${NC}"

# 3. Instruções para Pré-geração de Chunks (Chunky)
echo -e "\n${CYAN}──────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}Dica de Exploração (Elimina lag em voo/cavalo):${NC}"
echo -e "${CYAN}──────────────────────────────────────────────────────${NC}"
echo -e "Para pré-gerar o mapa sem lag para os jogadores:"
echo -e "1. Baixe o plugin Chunky no Crafty Controller (ou pasta plugins/)."
echo -e "2. No console do servidor, execute:"
echo -e "   ${CYAN}chunky radius 4000${NC}  (define raio de 4.000 blocos em volta do spawn)"
echo -e "   ${CYAN}chunky start${NC}        (inicia a geração em segundo plano)"
echo -e "\n${GREEN}✓ Otimizações aplicadas e preparadas com sucesso!${NC}\n"
