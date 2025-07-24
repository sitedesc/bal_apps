## Composant ballerina fo_db

Cette librairie a été créé pour le ticket EA-437, afin de gérer les accès à la DB FO:

* expose une api d'accès à, et requètage SQL de, cette DB,
* est prévue pour contenir toutes la logique d'accès à cette DB afin de ne pas l'éparpiller/dupliquer dans les autres composant,
* permet l'évolution (prévue) vers une api orm via l'intgération du module "bal persist" en isolant déjà le code d'accès à cette DB dans un composant dédié (contrainte de bal persist).

 **NB: dans cette première version, les accès à cette DB se font par script bash, la version de mysql étant trop ancienne pour utiliser le package mysql standard de Ballerina. Cela sera résolu dans une prochaine version.**

### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,  
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* remplacer les REPLACEME dans le block Config.toml ci-dessous (NB: pour une bdd dans un docker local, sauf si on sait vraiment ce qu'on fait, mettre 127.0.0.1 et pas localhost);
```
[fo_db.credentials]<br>
host = "REPLACEME"<br>
user = "REPLACEME"<br>
password = "REPLACEME"<br>
database = "REPLACEME"    
```
* ajouter dans le fichier ~/.profile du compte bal_apps (= fichier exécuté à chaque ouverture de session du compte linux qui exécute une app ou un module bal_apps):
```
# set PATH of fo_db if it is there
if [ -d "$HOME/<path to bal_apps>/modules/fo_db/bin" ] ; then
    PATH="$HOME/<path to bal_apps>/modules/fo_db/bin:$PATH"
fi
```
* puis exécuter dans une console:
```
source ~/.profile
```