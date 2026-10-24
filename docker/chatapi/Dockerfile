# tchatapi (apps/chatapi/srv_opportunity) — image multi-étapes.
# Étape 1 : compilation Ballerina (modules locaux publiés dans le repository local, puis bal build).
# Étape 2 : exécution Java 21 seule (le jar Ballerina embarque ses dépendances, connecteur MySQL compris).
ARG BAL_VERSION=2201.13.2
FROM ballerina/ballerina:${BAL_VERSION} AS build
USER ballerina
WORKDIR /home/ballerina/bal_apps
# Ballerina Central est parfois très lent : délais longs, tentatives multiples, et cache des paquets
# téléchargés conservé d'un build à l'autre (montage cache BuildKit) pour ne plus en dépendre.
RUN mkdir -p /home/ballerina/.ballerina/repositories/local /home/ballerina/.ballerina/repositories/central.ballerina.io && printf '[central]\nconnectTimeout = 120\nreadTimeout = 600\nwriteTimeout = 120\ncallTimeout = 0\nmaxRetries = 5\n' > /home/ballerina/.ballerina/Settings.toml
# Modules locaux, dans l'ordre des dépendances : java_bindings <- time ; chatgpt
COPY --chown=ballerina:ballerina java_bindings ./java_bindings
COPY --chown=ballerina:ballerina modules/time ./modules/time
COPY --chown=ballerina:ballerina modules/chatgpt ./modules/chatgpt
RUN --mount=type=cache,target=/home/ballerina/.ballerina/repositories/central.ballerina.io,uid=100,gid=1000 \
    for m in java_bindings modules/time modules/chatgpt; do \
      echo "== publication locale de $m" && cd /home/ballerina/bal_apps/$m && rm -rf target \
      && for try in 1 2 3; do bal pack && break || { echo "bal pack: tentative $try échouée"; sleep 20; }; done \
      && bal push --repository=local; done
# L'application : seules les sources nécessaires à la compilation, pour que les scénarios
# (SchemedTalks/, yaml, Config_template…) ne déclenchent pas de recompilation.
COPY --chown=ballerina:ballerina apps/chatapi/srv_opportunity/Ballerina.toml apps/chatapi/srv_opportunity/Dependencies.toml apps/chatapi/srv_opportunity/*.bal ./apps/chatapi/srv_opportunity/
COPY --chown=ballerina:ballerina apps/chatapi/srv_opportunity/lib ./apps/chatapi/srv_opportunity/lib
RUN --mount=type=cache,target=/home/ballerina/.ballerina/repositories/central.ballerina.io,uid=100,gid=1000 \
    cd apps/chatapi/srv_opportunity && for try in 1 2 3; do bal build && break || { echo "bal build: tentative $try échouée"; sleep 20; }; done && test -f target/bin/srv_opportunity.jar

FROM eclipse-temurin:21-jre
RUN useradd -r -u 10001 -d /srv/app -s /usr/sbin/nologin app
WORKDIR /srv/app
# projectDir = /srv/app (Config.toml) ; cwd = /srv/app/srv_opportunity (chemins ./SchemedTalks, ./responses, ./*.yaml)
COPY --chown=app:app apps/chatapi /srv/app
COPY --from=build --chown=app:app /home/ballerina/bal_apps/apps/chatapi/srv_opportunity/target/bin/srv_opportunity.jar /srv/app/srv_opportunity/srv_opportunity.jar
COPY --chown=app:app docker/chatapi/entrypoint.sh /srv/app/entrypoint.sh
RUN rm -rf /srv/app/srv_opportunity/target /srv/app/srv_opportunity/Config.toml /srv/app/srv_opportunity/responses && mkdir -p /srv/app/srv_opportunity/responses && chmod +x /srv/app/entrypoint.sh && chown -R app:app /srv/app
USER app
WORKDIR /srv/app/srv_opportunity
EXPOSE 9090
ENV OPENAPI_SERVER=http://localhost OPENAPI_PORT=9090 JAVA_OPTS="-Xms256m -Xmx1024m"
ENTRYPOINT ["/srv/app/entrypoint.sh"]
# Mêmes arguments que sur itdoc_srv : bal run -- IT SchemedTalks/Empty.json
CMD ["IT", "SchemedTalks/Empty.json"]
