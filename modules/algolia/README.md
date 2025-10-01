## Composant ballerina algolia

Ce composant éxecute les indexation algolia périodique.

### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,
* cloner ce repo et se mettre sur la branche correspondant à l'environnement, 
* copier/coller le template de configuration ci-dessous dans un fichier Config.toml à la racine du repo, remplacer les valeur REPLACEME par les bonnes valeur ou switcher sur les bonnes valeur (pour les conf des composant intégrés: voir leur README, si besoin demander aux "bonnes personnes"),
* lancer "bal build" dedans pour vérifier que le projet compile bien,
* pour lancer le job depuis le repo: bal run

```
[conf]
appId = "REPLACEME"
apiKey = "REPLACEME"

# switch the proper option depending on the target env:
indexNames = {"offres": "dev_ELITE_OFFERS", "loyers": "dev_ELITE_LOYERS"}
## indexNames = {"offres": "prod_ELITE_OFFERS", "loyers": "prod_ELITE_LOYERS"}

# switch the proper option depending on the target env: dev/preprod: true, prod: false
dryRun = true
## dryRun = false

# switch the proper option depending on the target env:
[conf.indexNames]
offres = "dev_ELITE_OFFERS"
loyers = "dev_ELITE_LOYERS"

## [conf.indexNames]
## offres = "prod_ELITE_OFFERS"
## loyers = "prod_ELITE_LOYERS"

[job_patch.conf]
port = REPLACEME
```
