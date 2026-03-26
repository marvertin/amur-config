# Docker infrastruktura (`/srv/docker`)

Tento repozitář obsahuje self-hosted prostředí postavené na Docker Compose:

- `unifi/` – UniFi Network Controller
- `homeassistant/` – Home Assistant
- `mqtt/` – MQTT broker (Eclipse Mosquitto)

Služby `unifi` a `mqtt` používají externí Docker síť `veve`. Home Assistant běží v host síti.

## Struktura

- `unifi/docker-compose.yml`
  - Spouští `jacobalberty/unifi:latest`
  - Persistuje data do `unifi/data/` (mount `./data:/unifi`)
  - Publikuje porty potřebné pro UniFi (`8080`, `8443`, `3478/udp`, `10001/udp`, `1900/udp`, `8843`, `8880`, `6789`)

- `unifi/data/`
  - Runtime/perzistentní data UniFi (DB, backupy, keystore, konfigurace)
  - Tato data jsou záměrně ignorována v Gitu

- `homeassistant/docker-compose.yml`
  - Spouští `ghcr.io/home-assistant/home-assistant:stable`
  - Běží v `network_mode: host`
  - Persistuje konfiguraci do `homeassistant/config/`

- `mqtt/docker-compose.yml`
  - Spouští `eclipse-mosquitto:2`
  - Publikuje porty `1883` (MQTT) a `9001` (WebSocket MQTT)
  - Persistuje data do `mqtt/data/` a logy do `mqtt/log/`

- `mqtt/config/mosquitto.conf`
  - Základní konfigurace brokeru
  - Aktuálně `allow_anonymous true` (vhodné jen pro důvěryhodnou LAN)

- `.gitignore`
  - Ignoruje runtime data (`unifi/data/`, `homeassistant/config/`, `mqtt/data/`, `mqtt/log/`, logy, run adresáře, dočasné soubory)
  - Verzuje pouze infrastrukturu (compose a konfigurační soubory)

## Poznámky k provozu

- Síť `veve` musí existovat jako externí Docker network.
- UniFi web je dostupný přímo na `https://<IP_SERVERU>:8443`.
- Home Assistant je dostupný přímo na `http://<IP_SERVERU>:8123`.
- MQTT broker je dostupný na `tcp://<IP_SERVERU>:1883` (a WS na `9001`).

## Požadavky

- Docker Engine + Docker Compose plugin (`docker compose`)
- Otevřené porty na hostu:
  - UniFi: `8080`, `8443`, `3478/udp`, `10001/udp`, `1900/udp`, `8843`, `8880`, `6789`
  - Home Assistant: `8123`
  - MQTT: `1883`, `9001`
- Externí Docker síť `veve`

## První setup

1. Vytvoř externí síť (pokud ještě neexistuje):

```bash
docker network create veve
```

2. Spusť služby:

```bash
cd unifi && docker compose up -d
cd ../mqtt && docker compose up -d
cd ../homeassistant && docker compose up -d
```

## Troubleshooting

- Zkontroluj běh kontejnerů:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

- Ověř existenci sítě:

```bash
docker network ls | grep veve
```

- Sleduj logy při problémech:

```bash
docker compose -f unifi/docker-compose.yml logs -f
docker compose -f mqtt/docker-compose.yml logs -f
docker compose -f homeassistant/docker-compose.yml logs -f
```

- Pokud nejde Home Assistant, ověř dostupnost na `http://<IP_SERVERU>:8123` a logy kontejneru.
- Pokud nejde MQTT, ověř otevřený port `1883` a konfiguraci v `mqtt/config/mosquitto.conf`.

## Aktualizace

Aktualizace image a restart služeb:

```bash
cd unifi && docker compose pull && docker compose up -d
cd ../mqtt && docker compose pull && docker compose up -d
cd ../homeassistant && docker compose pull && docker compose up -d
```

Volitelně můžeš po aktualizaci odstranit nepoužívané image:

```bash
docker image prune -f
```

## Rollback

Pokud po aktualizaci nastane problém, vrať se na konkrétní image tag:

1. Uprav image ve compose souboru na známou funkční verzi (místo `latest`):
  - `unifi/docker-compose.yml` → `image: jacobalberty/unifi:<verze>`
  - `mqtt/docker-compose.yml` → `image: eclipse-mosquitto:<verze>`
  - `homeassistant/docker-compose.yml` → `image: ghcr.io/home-assistant/home-assistant:<verze>`

2. Znovu nasaď službu:

```bash
cd unifi && docker compose pull && docker compose up -d
cd ../mqtt && docker compose pull && docker compose up -d
cd ../homeassistant && docker compose pull && docker compose up -d
```

3. Ověř stav kontejnerů a logy:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker compose -f unifi/docker-compose.yml logs --tail=100
docker compose -f mqtt/docker-compose.yml logs --tail=100
docker compose -f homeassistant/docker-compose.yml logs --tail=100
```
