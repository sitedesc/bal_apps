## Composant ballerina java_bindings

Ce composant a été créé pour le ticket EA-442: 
* il contient la bindings des classes standard java utilisées dans les autres apps/modules,
* exemple : pour ajouter le bindings de la classe java.time.LocalDateTime
```
bal bindgen java.time.LocalDateTime

```
* puis l'utiliser: voir un exemple dans main.bal;
* pourallerina.toml:
```
[[package.modules]]
name = "java_bindings.java.time"
export = true

```



### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,
* copier/coller le template de configuration ci-dessous dans un fichier Config.toml à la racine du module et remplacer les valeur REPLACEME par les bonnes valeur (demander aux "bonnes personnes" ces valeur si besoin).

```
# reco: comment this line in prod environnement
[ballerina.log]
level = "DEBUG"

```
