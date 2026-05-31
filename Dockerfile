FROM nodered/node-red:4.0.2

USER node-red

RUN npm install \
    node-red-node-mysql@3.0.0 \
    node-red-dashboard@3.6.6 \
    @node-red-contrib-themes/theme-collection \
    && npm cache clean --force

COPY docker/entrypoint.sh /entrypoint.sh
USER root
RUN apk add --no-cache su-exec && chmod +x /entrypoint.sh

ENV TZ=America/Santiago

USER root
ENTRYPOINT ["/entrypoint.sh"]
