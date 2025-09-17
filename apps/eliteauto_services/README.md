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
Par défaut le composant se trouve dans le repertoire modules à la racine de bal_apps.
* pour un setup initial, il faut ensuite ouvrir les README de chacun de ces composant et vérifier que leur section "Déploiement et configuration" est bien exécutée sinon l'exécuter: par exemple, en vérifiant si les section de configuration à créer dans le Config.toml de cette app, le sont bien avec les bonnes valeur etc...
* lorsqu'on veut déployer un changement:
  * identifier dans la PR, le code bal_apps qui change et notamment les changement dans les README (rappel de la reco bal_apps: tout changement de de configuration d'un composant doit être documenté dans le README du composant);
  * effectuer les changement de conf ainsi identifiés (en base dans Config.toml, mais ça peut être aussi des changement adhoc, comme créer un repertoire ou un tunnel d'accès bdd...),
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