# ⛏️ Minecraft Server Template & Manager

Modelo pronto para instalação, gerenciamento e automação de servidores de Minecraft com **Crafty Controller 4**, túnel **Playit.gg** e rotina de backup em nuvem via **rclone**.

Compatível com **GitHub Codespaces**, **VPS (Ubuntu/Debian)** e **WSL / Linux Local**.

---

## 📦 Estrutura do Repositório

```text
minecraft_server/
├── setup.sh                  # Script de instalação e bootstrap automatizado
├── manager.sh                # Menu central para iniciar, parar, monitorar e fazer backup
├── config.env.example        # Modelo de variáveis de configuração do ambiente
├── .gitignore                # Regras de exclusão para mundos pesados, logs e binários
└── templates/
    ├── server.properties.template  # Configurações padrão do servidor de Minecraft
    ├── eula.txt                    # Aceite de EULA
    └── systemd/                    # Modelos de serviços systemd para VPS
        ├── crafty.service
        └── playit.service
```

---

## 🚀 Instalação Rápida (1 Comando)

Clone o repositório no seu novo ambiente (Codespace ou Linux):

```bash
git clone https://github.com/cJessse/minecraft_server.git
cd minecraft_server
chmod +x setup.sh manager.sh
./setup.sh
```

O `setup.sh` realizará automaticamente:
1. Instalação de dependências essenciais (`Java 21 OpenJDK`, `Python 3`, `pip`, `venv`, `rclone`).
2. Instalação e configuração do **Playit.gg**.
3. Download e configuração do **Crafty Controller 4** com ambiente virtual isolado.
4. Criação do arquivo de configuração `config.env`.

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
- **4) Parar Serviços + Backup:** Ideal antes de manutenções.
- **5) Parar Serviços + Backup + Desligar Máquina:** Encerra serviços, envia backup para a nuvem e suspende o Codespace / máquina para economizar recursos.
- **6) Ver Logs em tempo real:** Acompanhe os logs do Crafty, do Minecraft e do Playit.

---

## ☁️ Configuração de Backup na Nuvem (Google Drive)

Para habilitar backups no Google Drive:

1. No terminal do servidor, execute:
   ```bash
   rclone config
   ```
2. Crie um novo remote chamado **`drive`** escolhendo o tipo `drive` (Google Drive).
3. Ajuste `RCLONE_REMOTE="drive:Minecraft_Backups"` no seu `config.env`.
4. Os backups serão salvos localmente na pasta `backups/` e enviados para o Google Drive automaticamente.

---

## 🔒 Segurança e Boas Práticas

- O arquivo `config.env` contém suas preferências locais e não é versionado no Git.
- Mundos e arquivos de logs são ignorados pelo `.gitignore` para manter o repositório leve.