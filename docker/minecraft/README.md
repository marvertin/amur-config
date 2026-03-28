# Minecraft server v Dockeru

Tato slozka spousti Java Minecraft server pomoci image `itzg/minecraft-server`.

## Co je nastavene

- Image: `itzg/minecraft-server:java25`
- Typ serveru: `VANILLA`
- Verze: `LATEST`
- RAM pro JVM: `4G`
- Port: `25565/tcp`
- Data sveta a konfigurace: `./data`

Poznamka: aktualni vanilla verze `26.1` vyzaduje Java 25 runtime.

## Spusteni

```bash
cd /srv/docker/minecraft
docker compose up -d
```

## Prvni start

- Pri prvnim startu se v `./data` vygeneruji vsechny soubory serveru.
- EULA je potvrzena pres `EULA=TRUE` v compose souboru.

## Zakladni sprava

Logy serveru:

```bash
cd /srv/docker/minecraft
docker compose logs -f
```

Zastaveni serveru:

```bash
cd /srv/docker/minecraft
docker compose down
```

Aktualizace image:

```bash
cd /srv/docker/minecraft
docker compose pull
docker compose up -d
```

## Volitelne upravy

- Zmena RAM: uprav `MEMORY=4G`
- Zmena typu serveru: uprav `TYPE=VANILLA` (napr. `PAPER`, `FABRIC`, `FORGE`)
- Zmena verze Minecraftu: uprav `VERSION=LATEST` (napr. `1.21.1`)
