# ⚡ Guia de Performance, Exploração & Anti-Lag

Este guia orienta como manter o servidor cravado em **20 TPS** no **GitHub Codespaces** (ou VPS modesta) com múltiplos jogadores explorando simultaneamente.

---

## 🎯 1. Software Recomendado: PaperMC (ou Purpur)

Para servidores multiplayer com foco em exploração sem mods de cliente:
- **PaperMC** processa chunks, iluminação e salvamento de forma assíncrona em segundo plano, aproveitando todos os núcleos da CPU do Codespace.
- Mantém **100% de compatibilidade** com jogadores usando o client Vanilla padrão.

---

## 🚀 2. Aplicação das Otimizações

Você pode aplicar as otimizações automáticas executando:

```bash
./manager.sh
# Escolha a opção 7) Aplicar Otimizações Anti-Lag
```
ou diretamente via terminal:
```bash
./scripts/optimize_server.sh
```

### O que o script configura:
- `server.properties`: `view-distance=7`, `simulation-distance=5`, `sync-chunk-writes=false`, `network-compression-threshold=512`.
- `config/paper-world-defaults.yml`: Redução de colisões de entidades excessivas (`max-entity-collisions: 4`), otimização de explosões, intervalos inteligentes de auto-save de chunks.
- `spigot.yml`: Ranges de tracking e ativação de mobs ajustados para multiplayer fluido.

---

## ☕ 3. Flags de JVM Aikar (Garbage Collection Otimizado)

Ao configurar a inicialização no **Crafty Controller** ou via linha de comando (para 4GB a 6GB de RAM):

```bash
java -Xms4G -Xmx4G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -jar server.jar --nogui
```

---

## 🗺️ 4. Pré-geração de Chunks (Chunky) — *Essencial para Exploração*

A maior causa de travamentos em novos mundos é a geração de terreno novo em tempo real quando 2 ou mais jogadores correm ou voam em direções opostas.

### Como pré-gerar:
1. Instale o plugin **Chunky** no PaperMC (disponível na aba de plugins do Crafty ou via SpigotMC/Modrinth).
2. No console do servidor (ou no jogo como OP), execute:
   ```text
   chunky radius 4000
   chunky start
   ```
3. O Chunky gerará um raio de 4.000 blocos ao redor do spawn. Quando os jogadores forem explorar, o Codespace apenas lerá o terreno do SSD instantaneamente com **0% de esforço na CPU**.
