# ⛏️ Minecraft Server Template & Manager

Modelo pronto para instalação, gerenciamento e automação de servidores de Minecraft com **Crafty Controller 4**, túnel **Playit.gg**, persistência anti-lag com **PaperMC** e rotina de backup em nuvem via **rclone**.

Totalmente compatível com **GitHub Codespaces**, **VPS (Ubuntu/Debian)** e **WSL / Linux Local**.

---

## 📦 Estrutura do Repositório

```text
minecraft_server/
├── setup.sh                  # Atalho raiz para scripts/setup.sh
├── manager.sh                # Atalho raiz para scripts/manager.sh
├── auto_schedule.sh          # Controlador e keepalive/heartbeat para Codespaces
├── .devcontainer/            # Configuração do ambiente e timeouts para Codespaces
│   └── devcontainer.json
├── .gitignore                # Regras de exclusão para mundos, logs e binários
├── .github/
│   └── workflows/
│       └── scheduler.yml     # Fluxo de agendamento automático via GitHub Actions
├── config/
│   ├── config.env.example    # Modelo de variáveis de configuração do ambiente
│   └── templates/            # Templates padrão (server.properties, paper, spigot, eula)
│       ├── eula.txt
│       ├── paper-world-defaults.yml
│       ├── server-icon.png
│       ├── server.properties.template
│       └── spigot.yml.template
├── scripts/
│   ├── setup.sh              # Script de instalação e bootstrap automatizado
│   ├── manager.sh            # Menu central e comandos CLI para gerenciar serviços
│   ├── optimize_server.sh    # Script de otimização anti-lag e TPS para instâncias
│   ├── rcon.py               # Utilitário RCON para envio de comandos seguros ao Minecraft
│   └── watchdog.sh           # Watchdog de autosave contínuo (60s flush) e auto-shutdown
├── deployments/
│   └── systemd/              # Modelos de serviços systemd para VPS/Linux
│       ├── crafty.service
│       └── playit.service
└── docs/
    ├── ARCHITECTURE.md       # Visão geral da arquitetura e portas
    ├── BACKUP_GUIDE.md       # Guia passo a passo de backup com Google Drive
    └── PERFORMANCE_GUIDE.md  # Guia de otimização de TPS, chunks e flags de JVM
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

### 1. Menu Interativo

Para abrir o menu interativo:

```bash
./manager.sh
```

#### Funcionalidades do Menu:
- **1) Iniciar Servidor & Serviços:** Inicializa o túnel Playit, o painel Web do Crafty na porta `8443` e o watchdog de autosave.
- **2) Parar todos os serviços:** Finaliza de forma limpa os processos (com RCON `stop` e flush no disco), liberando as portas com segurança.
- **3) Fazer Backup e Sincronizar na Nuvem:** Compacta os dados do mundo e sincroniza com o Google Drive / nuvem via `rclone`.
- **4) Parar Serviços + Backup Geral:** Encerra serviços e realiza backup em sequência (ideal antes de manutenções).
- **5) Parar Serviços + Backup + Desligar/Suspender Máquina:** Encerra serviços, envia backup para a nuvem e suspende o Codespace / máquina para economizar recursos.
- **6) Sincronizar/Salvar mundo no disco agora:** Força gravação imediata de todos os chunks (`save-all flush` via RCON + `sync` do SO).
- **7) Ver Logs em tempo real:** Acompanhe os logs do Crafty, do Minecraft e do Playit.
- **8) Aplicar Otimizações Anti-Lag em Todas as Instâncias:** Aplica parâmetros de alta performance no `server.properties`, PaperMC e Spigot (view-distance, simulation-distance, async sync, etc.).
- **0) Sair:** Fecha o menu.

---

### 2. Execução via Linha de Comando (Headless / Scripts)

O `manager.sh` pode ser executado diretamente com argumentos de linha de comando para automação:

```bash
./manager.sh start           # Inicia serviços, aplica otimizações e sobe watchdog
./manager.sh stop            # Encerramento seguro (save-all flush + stop gracioso)
./manager.sh save            # Gravação forçada imediata (save-all flush + sync)
./manager.sh backup          # Gera snapshot .tar.gz e envia para a nuvem
./manager.sh stop-backup     # Encerra serviços e executa backup
./manager.sh shutdown        # Encerra serviços, faz backup e desliga a máquina/Codespace
./manager.sh optimize        # Aplica configurações anti-lag nas instâncias
./manager.sh status          # Exibe status detalhado dos serviços e portas
./manager.sh cmd <comando>   # Envia comando ao console do Minecraft via RCON
```

---

## ⏰ Automação em Nuvem & GitHub Codespaces

O repositório conta com arquitetura desenhada para operar em **GitHub Codespaces** de forma econômica e supervisionada.

### Agendamento via GitHub Actions (`.github/workflows/scheduler.yml`)
* **Janela Ativa de Jogo:** De Segunda a Sexta, das **11:45 às 13:45 BRT** (14:45 às 16:45 UTC).
* **Supervisão Contínua (Keepalive):** A cada 5 minutos, a rotina renova a sessão SSH para resetar o idle timeout do Codespace e executa `save-all flush` para impedir perda de progresso de blocos/chunks.
* **Gatilho Fixo de Desligamento (13:45 BRT):** Às 13:45 BRT, o workflow aciona o `stop-backup`, envia o snapshot para o Google Drive e desliga o Codespace automaticamente.

### Controlador Local / Supervisor (`auto_schedule.sh`)
Permite gerenciar sessões supervisionadas manualmente a partir do terminal:

```bash
./auto_schedule.sh session 120    # Inicia sessão com monitoramento de até 120 minutos
./auto_schedule.sh start          # Sobe o Codespace e inicializa serviços
./auto_schedule.sh stop           # Executa stop-backup e desliga o Codespace
./auto_schedule.sh save           # Força save-all flush remoto no Codespace
./auto_schedule.sh heartbeat      # Verifica estado e reativa serviços se necessário
```

---

## ⚙️ Configurações do Ambiente (`config/config.env`)

Copie o arquivo de exemplo e customize conforme necessário:

```bash
cp config/config.env.example config/config.env
```

| Variável | Padrão | Descrição |
|---|---|---|
| `SERVER_MODE` | `crafty` | Modo de operação: `crafty` (painel Web) ou `standalone` (Java direto). |
| `MINECRAFT_PORT` | `25565` | Porta TCP do servidor de Minecraft. |
| `CRAFTY_PORT` | `8443` | Porta HTTPS do painel Web do Crafty Controller 4. |
| `ENABLE_PLAYIT` | `true` | Ativa o túnel Playit.gg para acesso externo sem abrir portas. |
| `BACKUP_DIR` | `backups` | Diretório local para armazenamento de snapshots `.tar.gz`. |
| `RCLONE_REMOTE` | `drive:Minecraft_Backups` | Caminho do controle remoto no rclone (ex: Google Drive). |
| `AUTO_SHUTDOWN_ENABLED`| `true` | Habilita desligamento automático no horário programado. |
| `AUTO_SHUTDOWN_TIME` | `13:45` | Horário fixo de encerramento da sessão supervisionada. |
| `AUTO_SHUTDOWN_TZ` | `America/Sao_Paulo` | Fuso horário de referência para o agendamento. |
| `CODESPACE_NAME` | *(vazio)* | Nome do Codespace alvo (autodetectado se vazio). |

---

## 📖 Documentação Adicional

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Visão técnica da infraestrutura, fluxo de conexões e portas.
- [docs/PERFORMANCE_GUIDE.md](docs/PERFORMANCE_GUIDE.md) — Guia de anti-lag, flags de JVM Aikar e pré-geração de chunks com Chunky.
- [docs/BACKUP_GUIDE.md](docs/BACKUP_GUIDE.md) — Passo a passo de configuração do Google Drive com `rclone`.