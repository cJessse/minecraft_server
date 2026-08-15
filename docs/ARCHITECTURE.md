# 🏗️ Arquitetura do Servidor Minecraft

Este documento descreve os componentes, fluxo de dados e portas do modelo de servidor.

---

## 📐 Visão dos Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                 GitHub Codespace / VPS / Linux              │
│                                                             │
│  [ Jogadores ]                                              │
│       │                                                     │
│       ▼                                                     │
│  [ Playit.gg ] ──(Túnel Seguro)──► [ Minecraft 25565 ]      │
│                                           │                 │
│  [ Admin Web ] ──(HTTPS 8443)───► [ Crafty Controller 4 ]   │
│                                           │                 │
│  [ Sincronização Nuvem ] ◄────(rclone)────┴─ [ Backups ]    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔌 Portas e Serviços

| Serviço | Porta / Protocolo | Finalidade |
|---|---|---|
| **Minecraft Server** | `25565 / TCP` | Porta padrão do servidor Java |
| **Crafty Web UI** | `8443 / HTTPS` | Painel web para administração |
| **Playit Agent** | `Socket Unix` | Túnel para bypass de CGNAT e portas restritas |
| **rclone** | `HTTPS (Drive API)` | Sincronização de snapshots com a nuvem |

---

## 📁 Estrutura de Diretórios

- **`config/`**: Contém templates de configuração e variáveis de ambiente.
- **`scripts/`**: Lógica de automação de instalação (`setup.sh`) e gerenciamento (`manager.sh`).
- **`deployments/`**: Arquivos de serviço systemd para servidores Linux dedicados ou VPS.
- **`docs/`**: Documentação técnica detalhada.
