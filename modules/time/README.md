## Composant ballerina time

Cette librairie a été créé pour le ticket EA-442, afin de compléter l'API Ballerina standard des gestion des dates (année, mois, jour) et horaires (heure, minutes, secondes d'un jour donné).

Elle expose aujourd'hui une fonction "at" de calcul de la date civile de la prochaine horaire définie par des valeur heure, minutes, secondes. Cette date est donnée dans la time zone configurée au niveau de l'OS executant cette fonction.

Afin de faire ce calcul de date, cette librarie dépend du composant d'intégration des classes standard java java_bindings, et intègre la classe standard java ZonedDateTime.

### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,  
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* exécuter les procédures de déploiement et configuration des README des composant intégrés : ces composant sont déclarés dans les section "dependency" du fichier Ballerina.toml.