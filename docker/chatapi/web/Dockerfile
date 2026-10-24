# Swagger UI (tools/swagger-ui-5.18.3.zip du dépôt) + routage vers l'API, dans un nginx.
FROM alpine:3.20 AS ui
RUN apk add --no-cache unzip
COPY apps/chatapi/srv_opportunity/tools/swagger-ui-5.18.3.zip /tmp/
RUN cd /tmp && unzip -q swagger-ui-5.18.3.zip && mv swagger-ui-5.18.3/dist /ui

FROM nginx:1.27-alpine
COPY --from=ui /ui /usr/share/nginx/html
COPY docker/chatapi/web/swagger-initializer.js /usr/share/nginx/html/swagger-initializer.js
COPY docker/chatapi/web/index.html /usr/share/nginx/html/index.html
COPY docker/chatapi/web/default.conf /etc/nginx/conf.d/default.conf
