#!/usr/bin/env bash
# ==============================================================================
# MINECRAFT SERVER ANTI-LAG OPTIMIZATION SCRIPT
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
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}      MINECRAFT SERVER ANTI-LAG & TPS OPTIMIZER       ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}\n"

# 1. Localizar arquivos server.properties
SEARCH_PATHS=(
    "$WORKSPACE_DIR/minecraft/crafty/crafty-4/servers"
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

if [ ${#PROPERTIES_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}Nenhum arquivo 'server.properties' encontrado para otimizar.${NC}"
else
    echo -e "Encontrado(s) ${#PROPERTIES_FILES[@]} arquivo(s) server.properties para otimização:"
    
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

    for prop in "${PROPERTIES_FILES[@]}"; do
        echo -e "\nOtimizando: ${CYAN}$prop${NC}"
        cp "$prop" "${prop}.bak_$(date +%Y%m%d_%H%M%S)"
        
        # Aplicar parâmetros de baixo lag
        set_property "$prop" "view-distance" "7"
        set_property "$prop" "simulation-distance" "5"
        set_property "$prop" "sync-chunk-writes" "false"
        set_property "$prop" "network-compression-threshold" "512"
        set_property "$prop" "entity-broadcast-range-percentage" "80"
        
        echo -e "  ${GREEN}✓ view-distance=7${NC} (reduz carga de chunks por jogador)"
        echo -e "  ${GREEN}✓ simulation-distance=5${NC} (foca processamento de IA/mobs próximos)"
        echo -e "  ${GREEN}✓ sync-chunk-writes=false${NC} (escrita assíncrona no disco)"
        echo -e "  ${GREEN}✓ network-compression-threshold=512${NC} (otimização de pacotes de rede)"
        echo -e "  ${GREEN}✓ entity-broadcast-range-percentage=80${NC} (reduz sincronização de mobs distantes)"
    done
fi

echo -e "\n${GREEN}✓ Otimizações aplicadas com sucesso!${NC}\n"
