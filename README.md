# ⛏️ Minecraft Server Template & Manager

Modelo pronto para instalação, gerenciamento e automação de servidores de Minecraft com **Crafty Controller 4**, túnel **Playit.gg** e rotina de backup em nuvem via **rclone**.

Compatível com **GitHub Codespaces**, **VPS (Ubuntu/Debian)** e **WSL / Linux Local**.

---

## 📦 Estrutura do Repositório

```text
minecraft_server/
├── setup.sh                  # Atalho raiz para scripts/setup.sh
├── manager.sh                # Atalho raiz para scripts/manager.sh
├── .gitignore                # Regras de exclusão para mundos pesados, logs e binários
├── config/
│   ├── config.env.example    # Modelo de variáveis de configuração do ambiente
│   └── templates/            # Templates padrão (server.properties, eula.txt)
├── scripts/
│   ├── setup.sh              # Script de instalação e bootstrap automatizado
│   ├── manager.sh            # Menu central para iniciar, parar e gerenciar
│   └── optimize_server.sh    # Script de otimização anti-lag e TPS para instâncias
├── auto_schedule.sh          # Controlador e keepalive/heartbeat para Codespaces
├── .github/
│   └── workflows/
│       └── scheduler.yml     # Fluxo de agendamento automático via GitHub Actions
├── deployments/
│   └── systemd/              # Modelos de serviços systemd para VPS/Linux
│       ├── crafty.service
│       └── playit.service
└── docs/
    ├── ARCHITECTURE.md       # Visão geral da arquitetura e portas
    └── BACKUP_GUIDE.md       # Guia passo a passo de backup com Google Drive
```

---

## 🚀 Instalação Rápida (1 Comando)

Clone o repositório no seu novo ambiente (Codespace ou Linux):

```bash
git clone https://github.com/cJessse/minecraft_server.git
cd minecraft_server
chmod +x setup.sh manager.sh scripts/*.sh
./setup.sh
```

O `setup.sh` realizará automaticamente:
1. Instalação de dependências essenciais (`Java 21 OpenJDK`, `Python 3`, `pip`, `venv`, `rclone`).
2. Instalação e configuração do **Playit.gg**.
3. Download e configuração do **Crafty Controller 4** com ambiente virtual isolado.
4. Criação do arquivo de configuração `config/config.env`.

---

## 🎮 Gerenciamento do Servidor (`manager.sh`)

Para abrir o menu interativo:

```bash
./manager.sh
```

### Funcionalidades do Menu:
- **1) Iniciar Servidor & Serviços:** Inicializa o túnel Playit e o painel Web do Crafty na porta `8443`.
- **2) Parar todos os serviços:** Finaliza de forma limpa processos do Java, Crafty e Playit, liberando as portas.
- **3) Fazer Backup e Sincronizar na Nuvem:** Compacta os dados do mundo e sincroniza com o Google Drive / nuvem via `rclone`.
- **4) Parar Serviços + Backup Geral:** Ideal antes de manutenções.
- **5) Parar Serviços + Backup + Desligar/Suspender Máquina:** Encerra serviços, envia backup para a nuvem e suspende o Codespace / máquina para economizar recursos.
- **6) Ver Logs em tempo real:** Acompanhe os logs do Crafty, do Minecraft e do Playit.
- **7) Aplicar Otimizações Anti-Lag:** Aplica parâmetros de alta performance no `server.properties` (view-distance, simulation-distance, async sync, etc.).

---

## 📖 Mais Informações

- Consulte [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) para detalhes técnicos da infraestrutura.
- Consulte [docs/BACKUP_GUIDE.md](docs/BACKUP_GUIDE.md) para configurar o Google Drive com rclone.