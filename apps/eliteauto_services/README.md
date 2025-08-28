## Service App ballerina eliteauto_services

Cette service app execute des composant backend de la plateforme EliteAuto:
* [update customer dispo](../../modules/update_customer_dispo/README.md): ce composant calcul un statut de dispo client d'un véhicule à partir d'autres données de dispo,
* [sync fo quotations](../../modules/sync_fo_quotations/README.md): ce composant transmet les nouveaux devis du site au BO.
* [check disk space](../../modules/check_disk_space/README.md): ce composant indique tous les jour via une notif teams, la place disque consommée du BO.
* [check funding offers](../../modules/check_funding_offers/README.md): ce composant détecte les offres bloquées en état de simulation de financement, calcule le nombre de jours écoulés depuis leur blocage et génère un rapport détaillé pour le suivi.

### Déploiement et configuration

Exécuter les déploiement et configurations décrit dans les README des composant de cette app.
Les jobs sont tous activés par défaut.
Si l'on veut en désactiver certains, les ajouter dans les disabledJobs comme ceci:
```
[conf]
## disables sync_fo_quotation and update_customer_dispo module/jobs:
disabledJobs = ["SyncFoQuotationJob", "UpdateCustomerDispoJob"]
```
(voir la liste de tous les jobs dans main.bal)