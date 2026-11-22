# tchatapi en Docker — dev (cette VM) et prod (serveur OVH it-doc, https://chatapi.sitems.org)

Reprise de l'instance d'origine : VM VirtualBox `itdoc_srv` du vieux Mac (`ssh -p 2223 itdoc@192.168.1.29`),
dépôt `~/dev/bal_apps`, app `apps/chatapi/srv_opportunity` lancée par `bal run -- IT SchemedTalks/Empty.json`
(Ballerina 2201.13.2, port 9090, exposée en `www.sitems.org:16387`), Swagger UI statique servi à part
(`www.sitems.org:16386/chatAPI/dist/`, cible de la redirection Gandi de www.tchatapi.org).

## Architecture Docker
| Conteneur | Rôle |
|---|---|
| `chatapi_api` | jar Ballerina (build multi-étapes `docker/chatapi/Dockerfile`), cwd `/srv/app/srv_opportunity`, port 9090 interne |
| `chatapi_web` | nginx : Swagger UI (zip versionné `tools/swagger-ui-5.18.3.zip`) + routage des endpoints vers l'API, port 80 interne |

Hors git : `.env` (bloc `## chatapi conf` du `~/.profile` d'origine : `SALESFORCE_TEST_AUTH`, `OPENFLEX_TEST_AUTH`,
`SRV_OPPORTUNITY_TEST_AUTH`) et `docker/chatapi/Config.toml` (le `Config.toml` d'origine, `projectDir = "/srv/app"`,
clé OpenAI du module chatgpt incluse). Modèles : `.env.example`, `docker/chatapi/Config_template.toml`.
Le contrat OpenAPI servi par `/openapi_dev` est adapté au démarrage (`OPENAPI_SERVER`, `OPENAPI_PORT`) pour que
« Try it out » vise l'instance courante. Les réponses de scénarios (`./responses`) sont dans un volume.

## Dev
```bash
./run.sh start      # build + up : Swagger UI http://localhost:8090, API http://localhost:9090
./run.sh test       # joue le scénario d'exemple puis lit /schemed_talks_responses
./run.sh logs
```

## Prod — même convention qu'aiacms et odoo
| Variable | Valeur |
|---|---|
| Serveur | `deployer@135.125.75.39`, répertoire `/srv/bal_apps` |
| DNS | `chatapi.sitems.org` A → 135.125.75.39 (API Gandi, `odoo/scripts/dns-gandi.sh set chatapi`) |
| TLS | certbot `--standalone` avec arrêt bref d'itdoc_nginx (posé le 24/10/2026, expire 22/01/2027, renouvellement par le timer) |
| TLS, tchatapi.org | même procédure ; un certificat pour `tchatapi.org` et `www.tchatapi.org` (posé le 22/11/2026, expire 20/02/2027). Zone DNS chez Gandi : `@`, `www` et `*` en A vers le VPS |
| Vhost | `deploy/ovh/chatapi.conf` → dépôt it-doc/sitesv2 `docker/nginx/vhosts.d/chatapi.conf` (source de vérité ; deux exemplaires à tenir identiques, voir l'en-tête du fichier) et `/srv/sitesv2/docker/nginx/vhosts.d/` |
| Réseau | `chatapi_web` rejoint `edge_itdoc` sous l'alias `chatapi_web` ; `chatapi_api` reste interne |

Déploiement — modèle aiacms/odoo (clone + `git pull`). Une fois : la clé publique du serveur
(`~/.ssh/id_ed25519.pub` de deployer) est déclarée **Deploy key** (lecture seule) du dépôt GitHub
`sitedesc/bal_apps`, et `/srv/bal_apps` est un clone de `git@github.com:sitedesc/bal_apps.git` (sans sudo).
Puis, depuis cette VM, après commit : `./run.sh deploy` (push de main, `git pull --ff-only` + `up -d --build`
sur le serveur) ; `./run.sh deploy --secrets` pousse aussi `.env` et `docker/chatapi/Config.toml`, hors git.

Vérif : `curl -s https://chatapi.sitems.org/openapi_dev | head`, puis Swagger UI → `/schemed_talks` avec
l'exemple de `/schemed_talk_examples`, puis `/schemed_talks_responses`.

## Exploitation sur le serveur
```bash
cd /srv/bal_apps; DC='docker compose -f docker-compose.yml -f docker-compose.prod.yml'
$DC ps; $DC logs --tail=100 chatapi_api
```
