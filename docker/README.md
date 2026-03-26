# Docker infrastruktura (`/srv/docker`)

Tento repozitář obsahuje jednoduché self-hosted prostředí postavené na Docker Compose:

- `traefik/` – reverse proxy (Traefik)
- `unifi/` – UniFi Network Controller
- `homeassistant/` – Home Assistant
- `mqtt/` – MQTT broker (Eclipse Mosquitto)

Všechny služby používají externí Docker síť `veve`.

## Struktura

- `traefik/docker-compose.yaml`
  - Spouští `traefik:latest`
  - Publikuje porty:
    - `80` (HTTP)
    - `443` (HTTPS)
    - `8081` (Traefik dashboard, mapováno z interního `8080`)
  - Připojuje Docker socket pouze pro čtení (`/var/run/docker.sock:ro`)

- `unifi/docker-compose.yml`
  - Spouští `jacobalberty/unifi:latest`
  - Persistuje data do `unifi/data/` (mount `./data:/unifi`)
  - Obsahuje Traefik labels pro host `unifi.veve`
  - Publikuje porty potřebné pro UniFi (např. `8080`, `3478/udp`, `10001/udp`, `8843`, `8880`, `6789`)

- `unifi/data/`
  - Runtime/perzistentní data UniFi (DB, backupy, keystore, konfigurace)
  - Tato data jsou záměrně ignorována v Gitu

- `homeassistant/docker-compose.yml`
  - Spouští `ghcr.io/home-assistant/home-assistant:stable`
  - Připojuje se do sítě `veve`
  - Obsahuje Traefik labels pro host `ha.veve`
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
- Traefik má zapnuté Docker provider routování přes labels.
- UniFi web je vystaven přes Traefik na `https://unifi.veve`.
- Home Assistant je vystaven přes Traefik na `https://ha.veve`.
- MQTT broker je dostupný na `tcp://<IP_SERVERU>:1883` (a WS na `9001`).
- Pro Home Assistant za reverse proxy musí být v `homeassistant/config/configuration.yaml` nastaveno `http.use_x_forwarded_for` a `http.trusted_proxies`.

## Požadavky

- Docker Engine + Docker Compose plugin (`docker compose`)
- Otevřené porty na hostu:
  - Traefik: `80`, `443`, `8081`
  - UniFi: `8080`, `3478/udp`, `10001/udp`, `1900/udp`, `8843`, `8880`, `6789`
  - Home Assistant: `8123`
  - MQTT: `1883`, `9001`
- Externí Docker síť `veve`
- DNS záznam (nebo lokální override), aby `unifi.veve` mířilo na IP tohoto hostu

## První setup (síť + DNS)

1. Vytvoř externí síť (pokud ještě neexistuje):

```bash
docker network create veve
```

2. Ověř, že záznam `unifi.veve` ukazuje na správnou IP serveru.
  - V domácí síti typicky v lokálním DNS resolveru/routeru.
  - Pro rychlý test můžeš dočasně použít záznam v `/etc/hosts` na klientovi.
  - Přidej i DNS záznam `ha.veve` na IP tohoto serveru.

3. Spusť služby:

```bash
cd traefik && docker compose up -d
cd ../unifi && docker compose up -d
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
docker compose -f traefik/docker-compose.yaml logs -f
docker compose -f unifi/docker-compose.yml logs -f
docker compose -f mqtt/docker-compose.yml logs -f
docker compose -f homeassistant/docker-compose.yml logs -f
```

- Pokud nejde web, ověř DNS: `unifi.veve` musí resolve na server s tímto Docker stackem.
- Pokud nejde Home Assistant, ověř DNS `ha.veve` a logy Traefiku/Home Assistantu.
- Pokud nejde MQTT, ověř otevřený port `1883` a konfiguraci v `mqtt/config/mosquitto.conf`.

## Aktualizace

Aktualizace image a restart služeb:

```bash
cd traefik && docker compose pull && docker compose up -d
cd ../unifi && docker compose pull && docker compose up -d
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
  - `traefik/docker-compose.yaml` → `image: traefik:<verze>`
  - `unifi/docker-compose.yml` → `image: jacobalberty/unifi:<verze>`
  - `mqtt/docker-compose.yml` → `image: eclipse-mosquitto:<verze>`
  - `homeassistant/docker-compose.yml` → `image: ghcr.io/home-assistant/home-assistant:<verze>`

2. Znovu nasaď službu:

```bash
cd traefik && docker compose pull && docker compose up -d
cd ../unifi && docker compose pull && docker compose up -d
cd ../mqtt && docker compose pull && docker compose up -d
cd ../homeassistant && docker compose pull && docker compose up -d
```

3. Ověř stav kontejnerů a logy:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker compose -f traefik/docker-compose.yaml logs --tail=100
docker compose -f unifi/docker-compose.yml logs --tail=100
docker compose -f mqtt/docker-compose.yml logs --tail=100
docker compose -f homeassistant/docker-compose.yml logs --tail=100
```
