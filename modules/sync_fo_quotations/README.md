## Composant ballerina sync_fo_quotations

Ce composant a été créé pour le ticket EA-437: il transmet les nouveaux devis créés via le site au BO:
* Récupère tous les devis enregistrés dans la bdd du site en statut de transmission "TODO",  à partir du 10 juillet 2025 (date à partir de laquelle l'erreur http 503 de l'ancien code était systématique),
* les soumet par API au BO,
* sur retour OK du BO les passe en statut de transmission "DONE",
* sur retour non OK, envoi une alerte (loguée) dans le channel teams des alertes EliteAuto, et les passe en statut de transmission "ERREUR".


### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* copier/coller le template de configuration ci-dessous dans un fichier Config.toml à la racine du module et remplacer les valeur REPLACEME par les bonnes valeur (demander aux "bonnes personnes" ces valeur si besoin),
* exécuter la procédure de déploiement du composant intègré [fo_db](../../modules/fo_db/README.md),
* lancer "bal build" dedans pour vérifier que le projet compile bien,
* pour lancer le job, depuis son clone lancer: bal run


<<<<

\# comment this line in prod environnement<br>
ballerina.log.level = "DEBUG"

boApiUrl = "REPLACEME"<br>
boApiSecret = "REPLACEME"

[teams]<br>
webhookUrl = "REPLACEME"<br>
channelId = "REPLACEME"<br>
apiKey = "REPLACEME"

[fo_db.credentials]<br>
host = "REPLACEME"<br>
user = "REPLACEME"<br>
password = "REPLACEME"<br>
database = "REPLACEME"

>>>>
