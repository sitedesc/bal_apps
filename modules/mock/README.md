## Composant ballerina mock

Ce composant a été créé pour le ticket EA-432: il mock l'appel à une route post:
* il permet donc de remplacer l'appel à la vraie route (pour des besoin de test en général),
* utilisation:
  * configurer le port d'écoute

### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* copier/coller le template de configuration ci-dessous dans un fichier Config.toml à la racine du module et remplacer les valeur REPLACEME par les bonnes valeur (demander aux "bonnes personnes" ces valeur si besoin),

```

[ballerina.log]
# reco: comment this line in prod environnement
level = "DEBUG"

[mockConf]
port = REPLACEME
```
* lancer "bal build" à la racine de ce module pour vérifier que le projet compile bien,
* pour lancer le composant: bal run
