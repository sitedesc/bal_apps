## Composant ballerina fo_db

Cette librairie a été créé pour le ticket EA-456, afin de gérer les accès à la DB POSTGRES:

* expose une api d'accès à, et requètage SQL de, cette DB,
* est prévue pour contenir toutes la logique d'accès à cette DB afin de ne pas l'éparpiller/dupliquer dans les autres composant,
* permet l'évolution (prévue) vers une api orm via l'intgération du module "bal persist" en isolant déjà le code d'accès à cette DB dans un composant dédié (contrainte de bal persist).

### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,  
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* remplacer les REPLACEME dans le block Config.toml ci-dessous (NB: pour une bdd dans un docker local ou via une conf de tunnel standard, sauf si on sait vraiment ce qu'on fait, mettre 127.0.0.1 et pas localhost);
```
[postgres_db.conf]
host = "REPLACEME"
user = "REPLACEME"
password = "REPLACEME"
database = "REPLACEME"
port = "REPLACEME"
```
#### Accès à la DB postgres

Cette DB est déployée dans un serveur Postgres OVH accessible via le serveur Symfony OVH.

Pour y accéder il faut créer un tunnel via ce serveur OVH: deux solutions:
- en lançant le tunnel via une commande (pour des test ponctuel):
```
/usr/bin/sshpass -p '<srv_app.password>' /usr/bin/autossh -M 0 -N \
   -L <postgres_db.conf.port>:<srv_postgres>:20184 \
   -o StrictHostKeyChecking=no <srv_app.user>@<srv_app.host>
```
Il faut donc avoir installé sshpass et autossh (par exemple via apt install).

- en paramétrant cette commande dans systemd (pour un accès permanent comme en prod):
  - créer le fichier de paramétrage systemd  /etc/systemd/system/pg-tunnel.service:
```
[Unit]
Description=SSH tunnel to OVH PostgreSQL
After=network.target

[Service]
User=ubuntu
ExecStart=//usr/bin/sshpass -p '<srv_app.password>' /usr/bin/autossh -M 0 -N \
   -L <postgres_db.conf.port>:<srv_postgres>:20184 \
   -o StrictHostKeyChecking=no <srv_app.user>@<srv_app.host>
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```
NB: il faut créer ce fichier en tant que root.
  - activer ce paramétrage:
  ```
  sudo systemctl daemon-reload
  sudo systemctl enable pg-tunnel
  sudo systemctl start pg-tunnel
  ```
  - tester qu'il est bien actif:
```
ubuntu@ip-10-124-74-64:~$ systemctl status pg-tunnel
● pg-tunnel.service - SSH tunnel to OVH PostgreSQL
     Loaded: loaded (/etc/systemd/system/pg-tunnel.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2025-09-16 22:01:48 CEST; 17h ago
     ...
```
  - tester l'accès à la DB
```
ubuntu@...:~$ psql -h localhost -p <postgres_db.conf.port> -U <postgres_db.conf.user>  -d <postgres_db.conf.database>
Password for user <postgres_db.conf.user>: 
psql (14.19 (Ubuntu 14.19-0ubuntu0.22.04.1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

...=> 

```