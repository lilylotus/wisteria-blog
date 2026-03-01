
# k8s node server Docerfile
# node:22.3.0-alpine3.20
# node:lts-alpine3.18
FROM node:22.3.0-alpine3.20
COPY node-server.js /node/server.js
WORKDIR /node/
EXPOSE 8080
ENTRYPOINT ["node", "/node/server.js"]
