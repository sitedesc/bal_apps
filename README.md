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
_NB: pour publier un seul package: cd dans son répertoire, puis : bal pack; bal push --repository local...il est conseillé de faire un alias: alias pub='bal pack; bal push --repository local' et de lancer l'alias_

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

Pré-requis: avoir déployé Ballerina: voir la section dédiée plus bas.

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
Ce script (qui sert surtout pour initialiser ou ré-initialiser la conf d'une app/module):
- concatène le fichier à la racine de ce repo Config.shared.&lt;env&gt;.toml au fichier Config.app.&lt;env&gt;.toml de l'app/du module et créer le fichier Config.toml de l'app/du module avec ces contenus concaténés.<br>
_(NB: le 3eme paramètre doit valoir apps pour une app et modules pour un module);_

- s'il existe un fichier à la racine de ce repo Secrets.shared.&lt;env&gt;.toml, il le concatène aussi;
- s'il existe un fichier Secrets.app.&lt;env&gt;.toml dans l'app/le module, il le concatène aussi.

Les fichier de conf "shared" permettent de gérer de variables de configuration communes à toutes les apps/modules par environnement, et éviter ainsi les duplication de variables de conf.
Ce mécanisme  induit une contrainte, mais qui est aussi une pratique structurante recomandée dans la doc ballerina:
* on ne peut pas définir de manière safe, des variables de conf de type simple comme:
```
myConfVar = "myVaue"
```
* car lorsqu'on agglomère de telles variables avec des variables de type record comme cela:
```
[conf]
myVar = "myVaue"
```
* cela produit potentiellement un fichier de conf final comme cela:
```
[conf]
myVar = "myVaue"

myConfVar = "myVaue"
```
* et alors myConfVar est compris comme un field du record conf et la compile du code (qui contient des occurences "myConfVar") plante.

NB: une variable de conf myConfVar dans le fichier Config.toml d'un module, doit être préfixée par le nom du module dans le Config.toml d'une app qui utilise ce module.<br>


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

NB: si une variable de conf est définie dans le Config.toml, mais n'est pas utilisée dans le code, Ballerina petera une erreur et ne compilera pas l'app/le module. Il faut donc supprimer du Config.toml les éventuelles variables récupérées automatiquement de shared, mais non utilisées.

## Lancement d'une app

Si l'app (ou le module) est constitué d'un seul script exécuté à la main: cd dans son repertoire puis "bal run".

Si cela ne convient pas, se référer à [la CLI Ballerina](https://ballerina.io/learn/cli-commands/) qui indique les diverses manière de compiler/exécuter un script.

Dans la cas de services et/ou jobs planifiés (donc des exécution qui ne rendent pas la main), il est recommandé de lancer l'app/module avec le script run_app.sh qui permet:

* une gestion simple du start/stop de l'app/module via la crontab,
* une gestion basique des logs:

Exemple:

```
## stops ballerina services app every day at 01:12
12 1 * * * /home/ubuntu/bal_apps/stop_ballerina_app.sh sync_fo_quotations.jar >> /home/ubuntu/bal_apps_logs/sync_fo_quotations.log 2>&1
## starts ballerina services app every day at 01:15 : this daily start/stop avoids potential long term growing ressources consumption
15 1 * * * nohup /home/ubuntu/bal_apps/run_app.sh /home/ubuntu /home/ubuntu/bal_apps/modules/sync_fo_quotations /home/ubuntu/bal_apps_logs/sync_fo_quotations.log >> /home/ubuntu//bal_apps_logs/sync_fo_quotations.log 2>&1 &
## reset log file every 3 month
3 0 1 1,4,7,10 * rm -f /home/ubuntu/bal_apps_logs/sync_fo_quotations.log
```

Dans l'exemple de crontab ci-dessus:
* ce repo est déployé dans /home/ubuntu/bal_apps,
* le module lancé est sync_fo_quotations,
* il est lancé toutes les nuit à 01:15 via la commande:
```
15 1 * * * nohup /home/ubuntu/bal_apps/run_app.sh /home/ubuntu /home/ubuntu/bal_apps/modules/sync_fo_quotations /home/ubuntu/bal_apps_logs/sync_fo_quotations.log >> /home/ubuntu//bal_apps_logs/sync_fo_quotations.log 2>&1 &
```
* cette commande:
  * lance le module via le script run_app.sh qui prend en paramètre:
    * le repertoire du compte linux executant l'app : /home/ubuntu dans cet exemple,
    * le repertoire du module à lancer: /home/ubuntu/bal_apps/modules/sync_fo_quotations,
    * le fichier de log dans lequel les sorties standard et erreur de ce module sont redirigées,
* et les sorties standard et erreur de cette commande sont aussi redirigées dans ce même fichier,
* NB: cette commande est lancée avec nohup et en backgound vie le &, pour ne pas bloquer la crontab;
* l'app/module est stopé toutes les nuits à 01:12 via le script stop_ballerina_app.sh
  * ce script prend en paramètre l'archive jar de l'app/module: sync_fo_quotations.jar,
  * en effet: cette archive est le résultat de la compilation ballerina de l'app/module, et c'est elle qui est exécutée par la JVM (ou "java") intégrée à ballerina => ballerina intègre la commande java "jps" (utilisées dans ce script) qui permet de stoper l'exécution d'une app/module à partir de son jar;
  * redémarrer ainsi l'app/module évite d'éventuel pb de conso croissante de ressources système sur le long terme, et garantit aussi qu'on maintient le star/stop d'une app dans le temps pour éviter le syndrome bien connus des vieux site web: "ne pas stoper le serveur sous peine qu'il ne redémarre pas!"
  * enfin le fichier de log est rester tous les trois mois... on peut aussi mettre en place un mécanisme d'archivage plus sophistiqué si besoin...

## Architecture d'exécution et mutualisation

Pour des raison évidente d'optimisation des ressource/performances, on utilise Ballerina tel que ses concepteur l'ont prévu:
* on ne lance pas des apps ou modules indépendemment les uns des autres car cela induit autant d'exécution d'instances de ballerina que d'apps et modules, ce qui est consommateur de ressource alors que ballerina permet de tout exécuter dans une seule instance;
* il existe trois type d'exécution:
  * des services: en ballerina c'est un objet "service",
  * des tâches plannifiés ou jobs: en ballerina ce sont des objet Job du package task,
  * des script manuel: en ballerina c'est une fonction main() dans un script;
* ces trois élement du langage ne sont que des déclencheur (ou triggers) du type d'exécution correspondant: ils n'ont pas vocation à contenir de l'algorithmique d'exécution, juste à appeler les "points d'entrée" (objet, fonction...) qui contiennent/aggègent l'algorithmique d'exécution; 
* les apps sont faites pour :
  * aggréger l'ensemble des triggers d'exécution des services, tâches plannifiées, et script manuel qui doivent s'exécuter pour une (ou plusieurs) plateforme(s) cible(s);
  * dépendre des élément de code qui contiennent les points d'entrées qui doivent être appelées dans ces trigger;
  * si ces points d'entrées contiennent une algorithmique executées par plusieurs apps, alors ils doivent être dans un package partagé, sinon dans des script de l'app;
* donc on respecte cette règle de mutualisation systématique dans ce monorepo ballerina:
  * s'il faut, pour une nouvelle plateforme cible, exécuter trois jobs d'une app A, et deux services d'une app B:
    * on ne déploie pas, ni n'exécute indépendement les apps A et B dans la plateforme cible (= double conso de ressources), mais:
    * on mutualise les points d'entrée des trois jobs et des deux services dans des packages réutilisables, on refactor les apps A et B pour qu'elles en dépendent, et on crée la nouvelle app C qui en dépend également.
* _NB: les script manuel impliquent forcément un lancment (ponctuel) d'une instance ballerina dédiée à leur execution: on peut les exécuter soit via une app soit directement depuis un module._


## Déploiement de Ballerina

### Déploiement initiale

Sur un poste de dev voir [cette doc](https://ballerina.io/downloads/installation-options/). L'option d'install debian sur un poste Ubuntu est recommandée, mais attention:

**Ballerina ne propose pas encore de package fonctionnant sur un OS (linux à minima), avec un processeur ARM (comme la VM AWS du BO EliteAuto).**

Il faut faire cette procédure pour un ubuntu avec processeur ARM:

* l'installer via son archive zip dont le lien de téléchargement est dispo dans [cette section](https://ballerina.io/downloads/installation-options/#install-via-the-ballerina-language-zip-file):
* exemple à date de dernière mise à jour de cette procédure:
  * wget https://dist.ballerina.io/downloads/2201.12.7/ballerina-2201.12.7-swan-lake.zip
* la dézipper dans un repertoire:
  * unzip ballerina-2201.12.7-swan-lake.zip -d distrib
* ajouter dans ~/.profile son repertoire bin dans le PATH:
```
## ballerina
if [ -d "$HOME/bal/distrib/ballerina-2201.12.7-swan-lake/bin" ] ; then
    PATH="$HOME/bal/distrib/ballerina-2201.12.7-swan-lake/bin:$PATH"
fi
```
* puis installer sdkman pour gérer la version de java compatible avec Ballerina:
```
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```
* vérifier qu'il fonctionne
```
sdk version
SDKMAN!
script: 5.19.0
native: 0.7.4 (linux aarch64)

```
* installer la version java compatible avec la version Ballerina déployée qui est indiquée dans [cette section](https://ballerina.io/downloads/installation-options/#install-via-the-ballerina-language-zip-file):
* exemple si c'est la 21: lancer:
```
sdk list java
```
  * et chercher une version 21.0.x-tem (= Temurin JDK 21.0.x), puis l'installer et en faire la version par défaut (pour le compte linux courant seulement):
```
sdk install java 21.0.7-tem
sdk default java 21.0.7-tem
source "$HOME/.sdkman/bin/sdkman-init.sh"
```
* puis la vérifier via:
```
java -version
openjdk version "21.0.7" 2025-04-15 LTS
OpenJDK Runtime Environment Temurin-21.0.7+6 (build 21.0.7+6-LTS)
OpenJDK 64-Bit Server VM Temurin-21.0.7+6 (build 21.0.7+6-LTS, mixed mode, sharing)
```
* ... et si ça n'y est pas déjà, rajouter cela dans le ~/.profile:
```
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
```
* puis le recharger:
```
source ~/.profile
```

### Mise à jour

Ballerina propose une commande "bal dist update" pour cela, mais idem que pour le déploiement initial: elle ne fonctionne pas encore pour les os ARM (linux à minima).

Mais il est relativement simple de le faire à la main:
* télécharger la distrib zip de la nouvelle version dont le lien de téléchargement est dispo dans [cette section](https://ballerina.io/downloads/installation-options/#install-via-the-ballerina-language-zip-file);
* cd dans le repertoire oû la précédente version a été installée (cf section "Déploiement initial" ci-avant);
* mettre à jour dans ~/.profile son repertoire bin dans le PATH:
```
## ballerina
if [ -d "$HOME/bal/distrib/ballerina-XXXX.XX.X-XXX/bin" ] ; then
    PATH="$HOME/bal/distrib/ballerina-XXXX.XX.X-XXX/bin:$PATH"
fi
```
* puis le recharger:
```
source ~/.profile
```
