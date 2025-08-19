## Composant check_disk_space

Ce job a été créé pour le ticket EA-442, afin de vérifier la place disk restante dans un serveur:

* il s'exécute tous les jour à une horaire configurable (cf ci-dessous), et retourne les sorties standard et erreur de la

### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,  
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* remplacer les REPLACEME dans le block Config.toml ci-dessous
```
[ballerina.log]
# reco: comment this line in prod environnement
level = "DEBUG"

[conf]
server = "REPLACEME"
hour = REPLACEME
minutes = REPLACEME
seconds = REPLACEME
```
_Si on ne sait pas oû trouver les valeur, demander aux "gens qui savent"._

* exécuter les procédures de déploiement et configuration des README des composant intégrés : ces composant sont déclarés dans les section "dependency" du fichier Ballerina.toml.