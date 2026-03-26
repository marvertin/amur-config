# Cloudflared tunnel dokumentace (reprodukovatelna)

Tento dokument je vycisteny vystup z `instalace.log` a `instalace2.log` bez slepych pokusu, preklepu a opakovanych kroku.

## 1) Co bylo realne provedeno

1. Byl pridan Cloudflare APT klic.
2. Byl pridan Cloudflared APT repozitar (pro Debian bookworm).
3. Byl nainstalovan balicek `cloudflared` (verze 2026.3.0).
4. Probehlo prihlaseni do Cloudflare uctu (`cloudflared tunnel login`) a vznikl soubor `~/.cloudflared/cert.pem`.
5. Byl vytvoren tunnel `vehema` s ID `0ba85e56-87df-4f81-a23d-61c1a8a20b26`.
6. Byl vytvoren DNS zaznam `ha.vehema.cz` smerovany do tunelu `vehema`.
7. Byl pouzit credentials soubor tunelu pod nazvem `~/.cloudflared/vehema-tunnel.json`.
8. Tunnel konfigurace je ulozena v souboru `/srv/cloudflared/config.yml`.
9. Byl nainstalovan systemd service (`cloudflared service install`), sluzba byla spustena a povolena po rebootu.

## 2) Aktualni stav konfigurace

Soubor `/srv/cloudflared/config.yml`:

- tunnel: vehema
- credentials-file: /home/martin/.cloudflared/vehema-tunnel.json
- ingress:
  - hostname: ha.vehema.cz -> service: http://localhost:8123
  - fallback: http_status:404

## 3) Reprodukovatelny postup

### A. Zprovozneni cloudflared (system + tunnel + service)

1. Priprav klic a repozitar:

   ```bash
   sudo mkdir -p --mode=0755 /usr/share/keyrings
   curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
   echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared bookworm main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
   ```

2. Instalace balicku:

   ```bash
   sudo apt update
   sudo apt install -y cloudflared
   ```

3. Prihlaseni do Cloudflare a vytvoreni tunelu:

   ```bash
   cloudflared tunnel login
   cloudflared tunnel create vehema
   ```

4. Vytvor adresar s konfiguraci a vytvor soubor `/srv/cloudflared/config.yml`:

   ```bash
   mkdir -p /srv/cloudflared
   ```

   Obsah configu:

   ```yaml
   tunnel: vehema
   credentials-file: /home/martin/.cloudflared/vehema-tunnel.json

   ingress:
     - hostname: ha.vehema.cz
       service: http://localhost:8123

     - service: http_status:404
   ```

5. Pokud je credentials JSON po `tunnel create` pod UUID nazvem, prejmenuj ho na stabilni jmeno:

   ```bash
   mv ~/.cloudflared/<TUNNEL_UUID>.json ~/.cloudflared/vehema-tunnel.json
   ```

6. Pro service instalaci dej config i do standardni cesty:

   ```bash
   sudo mkdir -p /etc/cloudflared
   sudo ln -sf /srv/cloudflared/config.yml /etc/cloudflared/config.yml
   ```

7. Nainstaluj a zapni systemd sluzbu:

   ```bash
   sudo cloudflared service install
   sudo systemctl enable --now cloudflared
   systemctl status cloudflared
   ```

### B. Registrace Home Assistantu do tunelu

Tato cast oddeluje kroky specificke pro Home Assistant.

1. DNS registrace hostu Home Assistantu do existujiciho tunelu:

   ```bash
   cloudflared tunnel route dns vehema ha.vehema.cz
   ```

2. Ingress mapovani v `/srv/cloudflared/config.yml` musi obsahovat:

   ```yaml
   - hostname: ha.vehema.cz
     service: http://localhost:8123
   ```

3. Home Assistant musi duverovat proxy hlavicce (uz je nastaveno v `/srv/docker/homeassistant/config/configuration.yaml`):

   ```yaml
   http:
     use_x_forwarded_for: true
     trusted_proxies:
       - 172.20.0.0/16
   ```

4. Po zmene konfigurace restartuj sluzby:

   ```bash
   sudo systemctl restart cloudflared
   docker compose -f /srv/docker/homeassistant/docker-compose.yml restart homeassistant
   ```

5. Otestuj pristup:

   ```text
   https://ha.vehema.cz
   ```

### C. Jak pridat dalsi servery/sluzby

Postup je vzdy stejny:

1. Vyber hostname, napr. `grafana.vehema.cz`.
2. Pridej DNS route do stejneho tunelu:

   ```bash
   cloudflared tunnel route dns vehema grafana.vehema.cz
   ```

3. Pridej dalsi ingress pravidlo NAD fallback radek `http_status:404`:

   ```yaml
   - hostname: grafana.vehema.cz
     service: http://localhost:3000
   ```

4. Restartuj cloudflared:

   ```bash
   sudo systemctl restart cloudflared
   ```

5. Otestuj URL v prohlizeci.

Poznamky:

- Kazdy novy server/sluzba = novy hostname + novy ingress blok.
- `http_status:404` musi zustat jako posledni pravidlo.
- Pokud sluzba bezi v Dockeru, pouzij port dostupny z hostitele, nebo interne docker DNS jmeno a sit (podle topologie).

## 4) Provoz a kontrola

Zakladni diagnostika:

- Stav sluzby: `systemctl status cloudflared`
- Logy sluzby: `journalctl -u cloudflared -f`
- Seznam tunelu: `cloudflared tunnel list`

Bezpecnost:

- Soubory `~/.cloudflared/cert.pem` a `~/.cloudflared/*.json` jsou citlive a nesmi se sdilet.
- Nikdy nevkladej jejich obsah do repozitare.
