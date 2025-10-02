## Composant ballerina offer_tracking

Ce composant a été créé pour le ticket EA-457 : 

Mise en place du suivi et de l'historisation quotidienne du processus de publication des offres (nouvelles, mises à jour, publiées, vendues, quarantaine), 
avec génération de rapports par lots et notifications Teams, planifiées chaque jour à 02:00.


### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,  
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* remplacer les REPLACEME dans le block Config.toml ci-dessous
```
[ballerina.log]
level = "DEBUG"

[job_patch.conf]
port = 9988

[bo_db.conf]
host = "REPLACEME"
user = "REPLACEME"
password = "REPLACEME"
database = "REPLACEME"
 
[teams.conf]
webhookUrl = "REPLACEME"
channelId = "REPLACEME"
apiKey = "REPLACEME"

[offer_tracking.conf.conf]
hour = REPLACEME
minutes = REPLACEME
seconds = REPLACEME
```
_Si on ne sait pas oû trouver les valeur, demander aux "gens qui savent"._

* exécuter les procédures de déploiement et configuration des README des composant intégrés : ces composant sont déclarés dans les section "dependency" du fichier Ballerina.toml.
