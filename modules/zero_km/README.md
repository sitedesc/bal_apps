## Composant ballerina zero_km

Ce composant a été créé pour le ticket EA-427. Son rôle est de détecter les offres 0km nouvelles ou mise à jour et de broadcaster ces offres aux client (browser app front) qui se sont connectés à son service de broadcast (= les browser des client qui sont sur le site) :

* La détection des offres se fait à intervalles régulier paramétrables (quelques secondes par défaut);
* lorsqu'un (browser) client arrive sur le site, il se connecte, et la liste courantes des offres 0km lui sont envoyées, puis ensuite les mise à jour de celles-ci à intervalles régulier paramétrables);
* lorsqu'il quitte le site (ou n'effectue plus d'action depuis trop longtemps), ces mise à jour ne lui sont plus envoyées.
* le tkt EA-427 n'ayant pas encore de GO de réalisation, ce composant n'est actuellement qu'n PoC de ce scénario de broadcast qui envoi une fausse donnée au client (browser) connectés, celle-ci étant affichable dans une page de test;
* la détection régulière des offres est implémenter pat un Job Ballerina et le broadcasting par un service websocket.



### Déploiement et configuration

* Pré-requis: avoir installé Ballerina,

  
* cloner ce repo et se mettre sur la branche correspondant à l'environnement,



  
* copier/coller le template de configuration ci-dessous dans un fichier Config.toml à la racine du module,



  
* lancer "bal build" dedans pour vérifier que le projet compile bien,



  
* et pour lancer ce service de manière autonome: bal run (NB: ne pas le lancer s'il est déjà intégrer dans une app qui tourne)


<<<<

[websocket]
port = 21003


>>>>
