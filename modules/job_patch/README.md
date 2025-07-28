## Composant ballerina mock

Ce composant a été créé pour le ticket EA-432: 
* il crée un service non utilisé pour contourner un bug du module de gestion de tâche planifiée de ballerina qui termine au lieu de rester live après avoir exécuté un job,
* le fait de dépendre de ce package lance ce service et ainsi l'exécution via "bal run" reste live.

### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* copier/coller le template de configuration ci-dessous dans un fichier Config.toml à la racine du module et remplacer les valeur REPLACEME par les bonnes valeur (demander aux "bonnes personnes" ces valeur si besoin).

```
# reco: comment this line in prod environnement
[ballerina.log]
level = "DEBUG"

[conf]
port = REPLACEME

```
