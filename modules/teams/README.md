## Composant ballerina teams

Ce composant a été créé pour le ticket EA-442, afin d'exposer une proxy API à teams. Il expose aujourd'hui une fonction d'envoi de notification teams.


### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,  
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* remplacer les REPLACEME dans le block Config.toml ci-dessous:
```
[conf]
webhookUrl = "REPLACEME"
channelId = "REPLACEME"
apiKey = "REPLACEME"
```
_Si on ne sait pas oû trouver les valeur, demander aux "gens qui savent"._
