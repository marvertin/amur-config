# Docker infrastruktura (`/srv/docker`)

Tento repozitář obsahuje jednoduché self-hosted prostředí postavené na Docker Compose:

- `traefik/` – reverse proxy (Traefik)
- `unifi/` – UniFi Network Controller

Obě služby používají externí Docker síť `veve`.

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
  - Obsahuje Traefik labels pro host `unifi.home.arpa`
  - Publikuje porty potřebné pro UniFi (např. `8080`, `3478/udp`, `10001/udp`, `8843`, `8880`, `6789`)

- `unifi/data/`
  - Runtime/perzistentní data UniFi (DB, backupy, keystore, konfigurace)
  - Tato data jsou záměrně ignorována v Gitu

- `.gitignore`
  - Ignoruje runtime data (`unifi/data/`, logy, run adresáře, dočasné soubory)
  - Verzuje pouze infrastrukturu (compose a konfigurační soubory)

## Poznámky k provozu

- Síť `veve` musí existovat jako externí Docker network.
- Traefik má zapnuté Docker provider routování přes labels.
- UniFi web je vystaven přes Traefik na `https://unifi.home.arpa`.

## Požadavky

- Docker Engine + Docker Compose plugin (`docker compose`)
- Otevřené porty na hostu pro Traefik (`80`, `443`, `8081`) a UniFi (`8080`, `3478/udp`, `10001/udp`, `1900/udp`, `8843`, `8880`, `6789`)
- Externí Docker síť `veve`
- DNS záznam (nebo lokální override), aby `unifi.home.arpa` mířilo na IP tohoto hostu

## První setup (síť + DNS)

1. Vytvoř externí síť (pokud ještě neexistuje):

```bash
docker network create veve
```

2. Ověř, že záznam `unifi.home.arpa` ukazuje na správnou IP serveru.
  - V domácí síti typicky v lokálním DNS resolveru/routeru.
  - Pro rychlý test můžeš dočasně použít záznam v `/etc/hosts` na klientovi.

3. Spusť služby:

```bash
cd traefik && docker compose up -d
cd ../unifi && docker compose up -d
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
```

- Pokud nejde web, ověř DNS: `unifi.home.arpa` musí resolve na server s tímto Docker stackem.

## Aktualizace

Aktualizace image a restart služeb:

```bash
cd traefik && docker compose pull && docker compose up -d
cd ../unifi && docker compose pull && docker compose up -d
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

2. Znovu nasaď službu:

```bash
cd traefik && docker compose pull && docker compose up -d
cd ../unifi && docker compose pull && docker compose up -d
```

3. Ověř stav kontejnerů a logy:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker compose -f traefik/docker-compose.yaml logs --tail=100
docker compose -f unifi/docker-compose.yml logs --tail=100
```
