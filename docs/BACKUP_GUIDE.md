# 💾 Guia de Configuração de Backups com Google Drive (rclone)

Este guia ensina a configurar a sincronização de backups automáticos para o Google Drive utilizando o `rclone`.

---

## 1. Configurando o rclone

No terminal do servidor ou Codespace, execute:

```bash
rclone config
```

Siga os passos interativos:
1. Digite `n` (New remote).
2. Digite o nome: **`drive`**.
3. Escolha o número correspondente a **`Google Drive`** (geralmente opção `18` ou `drive`).
4. Deixe `client_id` e `client_secret` em branco (pressione Enter).
5. Escolha o escopo de acesso total: **`1`** (`drive`).
6. Se estiver em um ambiente sem navegador gráfico (como Codespace), utilize a autenticação via token/device URL conforme instruído na tela.

---

## 2. Definindo a Pasta no `config/config.env`

Edite `config/config.env` e confirme a variável:

```bash
RCLONE_REMOTE="drive:Minecraft_Backups"
BACKUP_RETENTION_LOCAL=3
```

---

## 3. Disparando Backups

- Pelo menu interativo do `manager.sh`, escolha a opção **`3) Fazer Backup e Sincronizar na Nuvem`**.
- Ou ao encerrar o servidor, use a opção **`5) Parar Serviços + Backup + Desligar/Suspender Máquina`**.
