#!/usr/bin/env bash

# Vytvoří (nebo přepíše) MQTT uživatele v souboru passwords uvnitř kontejneru.
# Použití: ./vytvor-uzivatele.sh <uzivatel>

if [ -z "$1" ]; then
	echo "Chyba: nezadané uživatelské jméno."
	echo "Použití: $0 <uzivatel>"
	exit 1
fi

if docker exec mqtt test -f /mosquitto/config/passwords; then
	docker exec -it mqtt mosquitto_passwd /mosquitto/config/passwords "$1"
else
	docker exec -it mqtt mosquitto_passwd -c /mosquitto/config/passwords "$1"
fi