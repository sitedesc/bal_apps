## Composant ballerina sync_fo_quotations

Ce composant a été créé pour le ticket EA-437: il transmet les nouveaux devis créés via le site au BO:
* Récupère tous les devis enregistrés dans la bdd du site en statut de transmission "TODO",  à partir du 10 juillet 2025 (date à partir de laquelle l'erreur http 503 de l'ancien code était systématique),
* les soumet par API au BO,
* sur retour OK du BO les passe en statut de transmission "DONE",
* sur retour non OK, envoi une alerte (loguée) dans le channel teams des alertes EliteAuto, et les passe en statut de transmission "ERREUR",
* une deuxième passe sur les devis en erreur est faite: elle vérifie si le devis est présent dans la db du BO, et si c'est le cas passe le statut de transmission à DONE: cela gère les cas d'erreur non critique car le devis a bien été transmis malgrè l'erreur: un cas typique est un timeout lors de la transmission du devis.


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

* exécuter les procédures de déploiement des composant intègré [fo_db](../../modules/fo_db/README.md), ... ces composant sont indiqués dans les section Dependency du fichier Ballerina.toml,

* lancer "bal build" à la racine de ce module pour vérifier que le projet compile bien,
* pour lancer le job: bal run

