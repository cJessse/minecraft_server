#!/usr/bin/env bash
# ==============================================================================
# MINECRAFT SERVER TEMPLATE - BOOTSTRAP & INSTALLER
# ==============================================================================
set -e

# Determinar o diretório raiz do repositório
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}       INSTALADOR & PREPARADOR DO MODELO DE SERVIDOR MINECRAFT     ${NC}"
echo -e "${BLUE}==================================================================${NC}"

# 1. Configurar config.env
if [ ! -f "config/config.env" ] && [ ! -f "config.env" ]; then
    echo -e "${YELLOW}[1/5] Criando config/config.env a partir do template...${NC}"
    mkdir -p config
    cp config/config.env.example config/config.env
    echo -e "${GREEN}✓ config/config.env criado!${NC}"
else
    echo -e "${GREEN}✓ Arquivo config.env já existente.${NC}"
fi

# 2. Atualizar pacotes do sistema
echo -e "\n${YELLOW}[2/5] Verificando dependências do sistema (apt)...${NC}"
if command -v apt-get &> /dev/null; then
    sudo apt-get update -y
    sudo apt-get install -y \
        openjdk-21-jre-headless \
        python3 \
        python3-pip \
        python3-venv \
        curl \
        wget \
        tar \
        net-tools \
        rclone \
        gnupg \
        lsb-release
    echo -e "${GREEN}✓ Dependências base instaladas.${NC}"
else
    echo -e "${YELLOW}Aviso: Gerenciador apt-get não encontrado. Certifique-se de ter Java 21, Python 3 e rclone instalados manualmente.${NC}"
fi

# 3. Instalar Playit.gg
echo -e "\n${YELLOW}[3/5] Verificando Playit.gg CLI...${NC}"
if ! command -v playitd &> /dev/null; then
    echo "Instalando playitd..."
    curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | sudo tee /etc/apt/sources.list.d/playit-cloud.list
    sudo apt-get update -y
    sudo apt-get install -y playit || {
        echo -e "${YELLOW}Instalação via repositório falhou. Baixando binário direto...${NC}"
        sudo curl -Lo /usr/bin/playitd https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-amd64
        sudo chmod +x /usr/bin/playitd
    }
    echo -e "${GREEN}✓ Playit.gg instalado com sucesso!${NC}"
else
    echo -e "${GREEN}✓ Playit.gg já está instalado.${NC}"
fi

# 4. Configurar Crafty Controller 4
echo -e "\n${YELLOW}[4/5] Configurando Crafty Controller 4...${NC}"
mkdir -p minecraft/crafty
mkdir -p backups

if [ ! -d "minecraft/crafty/crafty-4" ]; then
    echo "Clonando repositório oficial do Crafty 4..."
    cd minecraft/crafty
    git clone https://gitlab.com/crafty-controller/crafty-4.git crafty-4
    cd crafty-4
    git checkout tags/v4.4.7 2>/dev/null || git checkout master 2>/dev/null || true
    cd "$ROOT_DIR"
fi

# Configurar venv Python para o Crafty
if [ ! -d "minecraft/crafty/.venv" ]; then
    echo "Criando ambiente virtual Python para o Crafty..."
    python3 -m venv minecraft/crafty/.venv
    # shellcheck disable=SC1091
    source minecraft/crafty/.venv/bin/activate
    pip install --upgrade pip
    if [ -f "minecraft/crafty/crafty-4/requirements.txt" ]; then
        pip install -r minecraft/crafty/crafty-4/requirements.txt
    fi
    deactivate
    echo -e "${GREEN}✓ Ambiente virtual do Crafty configurado.${NC}"
else
    echo -e "${GREEN}✓ Ambiente virtual do Crafty já configurado.${NC}"
fi

# 5. Permissões de Execução
echo -e "\n${YELLOW}[5/5] Ajustando permissões de execução dos scripts...${NC}"
chmod +x "$ROOT_DIR/scripts/"*.sh "$ROOT_DIR/"*.sh 2>/dev/null || true

echo -e "\n${GREEN}==================================================================${NC}"
echo -e "${GREEN}       ✓ INSTALAÇÃO E CONFIGURAÇÃO CONCLUÍDAS COM SUCESSO!         ${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo -e "Para iniciar e gerenciar o servidor, execute:"
echo -e "  ${BLUE}./manager.sh${NC}\n"
