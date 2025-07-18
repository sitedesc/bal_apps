## Composant ballerina sync_fo_quotations

Ce composant a été créé pour le ticket EA-437, et transmettre les nouveaux devis créés via le site au BO:

* Récupère tous les devis enregistrés dans la bdd du site en statut de transmission "TODO",  
* les soumet par API au BO,
* sur retour OK du BO les passe en statut de transmission "DONE",
* sur retour non OK, envoi une alerte dans le channel teams des alerte EliteAuto et les passe en statut de transmission "ERREUR".


### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,  
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* copier/coller le template de configuration ci-dessous dans un fichier Config.toml à la racine du module et remplacer les valeur REPLACEME par les bonnes valeur (demander aux "bonnes personnes" ces valeur si besoin),
* lancer "bal build" dedans pour vérifier que le projet compile bien,
* pour lancer le job: bal run
* NB:
    * si dryRun vaut true, les devis ne sont pas soumis au BO (c'est donc un mode de test de base de la logique d'accès en lecture à ces devis).

  






  




<<<<



    [algolia]
    appId = "REPLACEME"
    apiKey = "REPLACEME"
    indexName = "REPLACEME"
    
    [customerDispo]
    dryRun = true
    dryRunNotify = true
    
    [teams]
    webhookUrl = "REPLACEME"
    channelId = "REPLACEME"
    apiKey = "REPLACEME"
    

>>>>
