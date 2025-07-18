## Composant ballerina fo_db

Cette librairie a été créé pour le ticket EA-437, afin de gérer les accès à la DB FO:

* expose une api d'accès à et requètage SQL de, cette DB,
* est prévue pour contenir toutes la logique d'accès à cette DB afin de ne pas l'éparpiller/dupliquer dans les autres composant,
* permet l'évolution (prévue) vers une api orm via l'intgération du module "bal persist" en isolant déjà le code d'accès à cette DB dans un composant dédié (contrainte de bal persist).

### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,  
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* copier/coller le template de configuration ci-dessous dans le fichier Config.toml de l'app/module intégrant cette librairie et remplacer les valeur REPLACEME par les bonnes valeur (demander aux "bonnes personnes" ces valeur si besoin).

```

[credentials]
host = "REPLACEME";
user = "REPLACEME";
password = "REPLACEME";
database = "REPLACEME"; 

```
