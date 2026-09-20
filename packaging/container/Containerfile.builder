FROM node:lts-alpine3.23

WORKDIR /app

ENV PATH=/app/node_modules/.bin:$PATH
ENV CHOKIDAR_USEPOLLING=true

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["rm -f /tmp/.builder_ready && npm install && npm run build-riot && npm run build-stylus && touch /tmp/.builder_ready && npm-watch"]