# tchatapi (apps/chatapi/srv_opportunity) — image multi-étapes.
# Étape 1 : compilation Ballerina (modules locaux publiés dans le repository local, puis bal build).
# Étape 2 : exécution Java 21 seule (le jar Ballerina embarque ses dépendances, connecteur MySQL compris).
ARG BAL_VERSION=2201.13.2
FROM ballerina/ballerina:${BAL_VERSION} AS build
USER ballerina
WORKDIR /home/ballerina/bal_apps
# Modules locaux, dans l'ordre des dépendances : java_bindings <- time ; chatgpt
COPY --chown=ballerina:ballerina java_bindings ./java_bindings
COPY --chown=ballerina:ballerina modules/time ./modules/time
COPY --chown=ballerina:ballerina modules/chatgpt ./modules/chatgpt
RUN for m in java_bindings modules/time modules/chatgpt; do \
      echo "== publication locale de $m" && cd /home/ballerina/bal_apps/$m && rm -rf target \
      && bal pack && bal push --repository=local; done
# L'application
COPY --chown=ballerina:ballerina apps/chatapi ./apps/chatapi
RUN cd apps/chatapi/srv_opportunity && rm -rf target responses/* Config.toml && bal build

FROM eclipse-temurin:21-jre
RUN useradd -r -u 10001 -d /srv/app -s /usr/sbin/nologin app
WORKDIR /srv/app
# projectDir = /srv/app (Config.toml) ; cwd = /srv/app/srv_opportunity (chemins ./SchemedTalks, ./responses, ./*.yaml)
COPY --from=build --chown=app:app /home/ballerina/bal_apps/apps/chatapi /srv/app
COPY --from=build --chown=app:app /home/ballerina/bal_apps/apps/chatapi/srv_opportunity/target/bin/srv_opportunity.jar /srv/app/srv_opportunity/srv_opportunity.jar
COPY --chown=app:app docker/chatapi/entrypoint.sh /srv/app/entrypoint.sh
RUN rm -rf /srv/app/srv_opportunity/target && mkdir -p /srv/app/srv_opportunity/responses && chmod +x /srv/app/entrypoint.sh && chown -R app:app /srv/app
USER app
WORKDIR /srv/app/srv_opportunity
EXPOSE 9090
ENV OPENAPI_SERVER=http://localhost OPENAPI_PORT=9090 JAVA_OPTS="-Xms256m -Xmx1024m"
ENTRYPOINT ["/srv/app/entrypoint.sh"]
# Mêmes arguments que sur itdoc_srv : bal run -- IT SchemedTalks/Empty.json
CMD ["IT", "SchemedTalks/Empty.json"]
