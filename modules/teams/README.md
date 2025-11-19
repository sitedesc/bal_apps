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

On peut surdéfinir cette configuration en positionnant la variable d'environnement TEAMS_AUTH:
```
export TEAMS_AUTH='{"webhookUrl": "REPLACEME", "channelId": "REPLACEME", "apiKey":"REPLACEME"}'
```

_Si on ne sait pas oû trouver les valeur, demander aux "gens qui savent"._

### Test

Un test auto est dispo:
* il envoie une notification via un webhook AWS à configurer dans tests/Config.toml,
* et une via un webhook Microsoft à configurer dans la variable d'environnement TEST_MS_TEAMS_AUTH,
  * NB: si une variable TEAMS_AUTH est positionnée lorsqu'on lance ce test, celle-ci sera écrasée par la valeur de TEST_MS_TEAMS_AUTH.

Ce test se lance à la racine du module comme ceci:
```
export TEST_MS_TEAMS_AUTH='{"webhookUrl": "REPLACEME", "channelId": "REPLACEME", "apiKey":"REPLACEME"}'
bal test
```
