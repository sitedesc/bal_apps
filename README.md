# Repository de services d'application Ballerina

Ce repository gère le développement et déploiement de services d'application [Ballerina](http://www.ballerina.io) via une architecture à composant (ou package en langage Ballerina).
 
Son repertoire "apps" contient un répertoire par service d'application déployable dans divers plateformes cibles (docker n'est pas supporté aujourd'hui, seulement des VM linux AWS ).

Un service d'application est prévu pour:
- exposer un ou plusieurs services constitués de un ou plusieurs endpoints: en base HTTP/REST/JSON et WebSocket/HTTP/REST/JSON (les autres protocoles supportés par Ballerina sont possibles aussi),
- exécuter des clients d'intégration d'application et services partenaires,
- gérer des jobs schedulés nativement intégrés aux clients et services (via des variables communes, etc...),
- gérer des commandes console,
- valider et transformer des données complexes et volumineuses entre sources de données hétérogènes: db, endpoints, document structurés, ...,
- intégrer des agent IA,
- intégrer des processus métier (workflow, bpm ...),
- intégrer les caches et gestionnaire de messages du marché,
- supporter les standard d'authentification et de gestion d'identité (oAuth2,IAM,...),
- réutiliser le code entre ces divers types d'exécution via une gestion de packages, dépendances, version, environnement, repository de package public, privés et locaux, etc...,
- être intégré à une CI/CD (github, gitlab...),
- gérer nativement la non concurrence des executions d'un job schédulé,
- gérer nativement le multi-threading d'exécution des request et du code thread safe,
- proposer une base croissante de connecteur à divers services, solutions et composant "main stream": google, github, aws, azure, salesforce, jira, power bi, open ai, redis, kafka, rabbit mq, ...

Le repertoire "modules" contient un repertoire par composant réutilisable dans les services d'applications.<br>
Un tel composant est déployé comme un package Ballerina dans ceux-ci, via le "local package repository" intégré nativement dans Ballerina (pas besoin de configurer un outil tiers pour ça):
- pour créer un package:
```
cd modules;
bal new <my_package_name>;
cd my_package_name;
touch README.md
```
Puis modifier dans Ballerina.toml:
```
org = "cosmobilis"
```
Puis lancer le script à la racine du repo de publication local des packages:
```
./local_publish.sh
```
Puis, pour utiliser my_package_name dans une app, rajouter sa dépendance dans le fichier Ballerina.toml de l'app:
```
[[dependency]]
org = "cosmobilis"
name = "my_package_name"
version = "0.1.0"
repository = "local"
```
NB: les versions doivent concorder:
- la version 0.1.0 dans cette dépendance veut dire que l'app dépend de la version la plus récente du package, supérieure ou égale à la version 0.1.0;
- donc s'il la version la plus récente publiée du package est une 0.0.9, le build de l'app fera une erreur car aucune version valable du package ne sera trouvée par le gestionnaire de dépendance.


## Déploiement d'une app

Une app se déploie en clonant ce repo dans l'environnement cible.<br>
NB: un module est également déployable via un tel clonage: on peut donc exécuter les commandes consoles, tâches planifiées et services d'un module en mode standalone (c'est à dire non intégrés dans une app).

## Gestion des configuration

Le fichier de configuration d'une app ou d'un module est un fichier Config.toml non commité;<br>
on peut gérer ce fichier par environnement comme ceci:
- créer un fichier à la racine de l'app/du module Config.app.&lt;env&gt;.toml avec &lt;env&gt; valant dev, preprod ou prod;
- on peut commiter ce fichier, mais il ne doit contenir que des valeur commitables (donc pas de valeur secretes);
- ensuite on peut soit recopier à la main  ce fichier dans l'env cible en Config.toml, soit lancer le script à la racine de ce repo:
```
./generate_config.sh <app_or_module_name> <env> modules|apps
```
Ce script:
- concatène le fichier à la racine de ce repo Config.shared.&lt;env&gt;.toml au fichier Config.app.&lt;env&gt;.toml de l'app/du module et créer le fichier Config.toml de l'app/du module avec ces contenus concaténés.<br>
_(NB: le 3eme paramètre doit valoir apps pour une app et modules pour un module);_
- s'il existe un fichier à la racine de ce repo Secrets.shared.&lt;env&gt;, il le concatène aussi;
- s'il existe un fichier à la racine de ce repo Secrets.shared.&lt;env&gt;.toml, il le concatène aussi;
- s'il existe un fichier Secrets.app.&lt;env&gt;.toml dans l'app/le module, il le concatène aussi.

Les fichier de conf "shared" permettent de gérer de variables de configuration communes à toutes les apps/modules par environnement, et éviter ainsi les duplication de variables de conf.

NB: une variable de conf myConfVar dans le fichier Config.toml d'un module, doit être préfixée par le nom du module dans le Config.toml d'une app qui utilise ce module.<br>

NB: si une variable de conf est définie dans le Config.toml, mais n'est pas utilisée, Ballerina petera une erreur et ne compilera pas l'app/le module. Il faut donc supprimer du Config.toml les éventuelles variables récupérées automatiquement de shared, mais non utilisées.

Exemple: le module update_customer_dispo définit une variable de type record définie comme ceci:
```
[customerDispo]
dryRun = true
dryRunNotify = true
```
Et dans l'app eliteauto_services qui utilise ce package, elle est definie comme cela:
```
[update_customer_dispo.customerDispo]
dryRun = true
dryRunNotify = true
```
Ce préfixe permet donc d'utiliser deux packages qui ont des noms de variables identiques... et on voit donc à cette occasion qu'une app doit définir les valeur de conf de ces packages, donc : il faut décrire dans le README des packages (mais aussi des apps), comment les variables de conf du package/de l'app doivent être définies.

NB: les variables secretes doivent aussi être décrites dans les README.