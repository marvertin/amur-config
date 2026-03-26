
Musí mít soubory taková oprávnění.
Ten vlastní 1883 je shodný s číslem protu, je to jejich konvence.

```
celkem 8
-rw-rw-r-- 1 martin rodina 209 21. úno 21.56 mosquitto.conf
-rw------- 1   1883   1883 384 21. úno 22.29 passwords
```


```
mosquitto_sub -h mqtt.veve -u ha -P HESLO  -t test/novy3 -v -d
martin@siven ~ % mosquitto_pub -h mqtt.veve -t test/novy3 -u destovka -P HESLO -m "funguje to" -r
```