## Composant ballerina check_funding_offers

Ce composant a été créé pour le ticket EA-440 : il détecte les offres bloquées en état de simulation de financement (ETAT_OFFRE_STOCK_ATTENTE_FO = 12) :
* interroge régulièrement la base de données pour identifier les offres restées bloquées dans cet état,
* calcule, pour chaque offre, le nombre de jours écoulés depuis son passage en état 12,
* génère un rapport listant les offres concernées avec les informations nécessaires au suivi (identifiants, dates, statut, durée d’attente, etc.).


### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* copier/coller le template de configuration ci-dessous dans un fichier Config.toml à la racine du module et remplacer les valeur REPLACEME par les bonnes valeur (voir les README des composant intégrés et/ou demander aux "bonnes personnes" ces valeur si besoin),

```
\# reco: comment this line in prod environnement<br>
ballerina.log.level = "DEBUG"

[conf]
# in dev and preprod the url should be equal the one of a running /modules/mock service and the secret : "unused:unused"
boApiUrl = "REPLACEME"
boApiSecret = "REPLACEME"

[job_patch.conf]
port = REPLACEME

[teams]
webhookUrl = "REPLACEME"
channelId = "REPLACEME"
apiKey = "REPLACEME"

[fo_db.credentials]
host = "REPLACEME"
user = "REPLACEME"
password = "REPLACEME"
database = "REPLACEME"
```

* ajouter dans le fichier ~/.profile du compte bal_apps (= fichier exécuté à chaque ouverture de session du compte linux qui exécute une app ou un module bal_apps):
```
# set PATH of check_funding_offers if it is there
if [ -d "$HOME/<path to bal_apps>/modules/check_funding_offers/bin" ] ; then
    PATH="$HOME/<path to bal_apps>/modules/check_funding_offers/bin:$PATH"
fi
```
* puis exécuter dans une console:
```
source ~/.profile
```

* lancer "bal build" à la racine de ce module pour vérifier que le projet compile bien,
* pour lancer le job: bal run



