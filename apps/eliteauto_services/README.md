## Service App ballerina eliteauto_services

Pré-requis: cette "service app" est une bal_apps, c'est à dire qu'elle suit les recommandation du [README bal_apps](../../README.md), donc sa lecture est un pré-requis.

Cette service app execute des composant backend de la plateforme EliteAuto:
* [algolia](../../modules/algolia/README.md): ce composant exécute les mises à jour des indexes algolia,
* [sync fo quotations](../../modules/sync_fo_quotations/README.md): ce composant transmet les nouveaux devis du site au BO.
* [check disk space](../../modules/check_disk_space/README.md): ce composant indique tous les jour via une notif teams, la place disque consommée du BO.
* [check funding offers](../../modules/check_funding_offers/README.md): ce composant détecte les offres bloquées en état de simulation de financement, calcule le nombre de jours écoulés depuis leur blocage et génère un rapport détaillé pour le suivi.

### Déploiement et configuration

L'exécution de cette app en prod est gérée par les script de run et stop d'une app décrit dans le README bal_apps.

Ces script son crontabés: crontab -l liste donc les commandes de start et stop en crontab avec le fichier de log dans lequel les traces sont loguées.

En dev et preprod elle est lancée au besoin via bal run.

Avant tout déploiement, il faut stoper l'app pendant qu'elle ne fait rien: faire "tail -f" du fichier de log pour vérifier qu'elle ne fait rien : pas d'indexation en cours, de push de devis... puis lancer manuellement la commande de stop de la crontab.

Pour un setup initial, il faut exécuter les déploiement et configurations décrit dans les README des composant de cette app:
* lister tous les composant intégrés dans cette app, de l'organisation "cosmobilis" qui se trouvent sous ce format dans Ballerina.toml:
```
[[dependency]]
org = "cosmobilis"
name = "<nom_du_composant>"
version = "0.1.0"
repository = "local"

```
Par défaut ces composant se trouve dans le repertoire bal_apps/modules.
* pour un setup initial, il faut ensuite ouvrir les README de chacun de ces composant et vérifier que leur section "Déploiement et configuration" est bien exécutée (sinon le faire): 
  * si une section de variables de configuration est indiquée à créer dans le README, le vérifier sinon le faire,
  * si le README indique de créer un repertoire ou un tunnel..., e vérifier sinon le faire,
  * etc...
* lorsqu'on veut déployer un changement:
  * après avoir effectuer le process git de review/merge de la PR dans la branche cible et avoir push celle-ci, faire un git pull de celle-ci dans l'env cible,
    * NB: le processus de compilation/run de ballerina fait que des fichier Dependencies.toml (qui jouent le rôle des composer.lock PHP) sont potentiellement régénérés,
    * donc le clone cible peut avoir de telle fichier non commités: le supprimer en faisant un git checkout de ces fichier avant de faire le git pull,
    * la gestion de ces fichier sera simplifiée dans une prochaine version de cette procédure,
  * identifier dans la PR, le code bal_apps qui change et notamment les changement dans les README (rappel de la reco bal_apps: tout changement de de configuration d'un composant doit être documenté dans le README du composant);
  * effectuer les changement de conf ainsi identifiés,
  * puis lancer le local_publish.sh comme décrit dans le README bal_apps,
  * puis lancer l'app en lançant manuellemnt la commande de start de la crontab.

  #### Activation/Désactivation des jobs

Les jobs sont tous activés par défaut, sauf UpdateCustomerDispoJob qui est désactivé depuis le déploiement de EA-456 qui le remplace par le job d'indexation algolia (UpdateCustomerDispoJob est conservé pour le moment en cas de rollback de EA-456 et donc de ce job d'indexation algolia).

Si l'on veut en désactiver certains, les ajouter dans les disabledJobs comme ceci:
```
[conf]
## disables sync_fo_quotation and update_customer_dispo module/jobs:
disabledJobs = ["SyncFoQuotationJob", "UpdateCustomerDispoJob"]
```
(voir la liste de tous les jobs dans main.bal)