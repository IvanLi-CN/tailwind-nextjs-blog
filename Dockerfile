FROM node:16-alpine as base
WORKDIR /app
COPY package-lock.json package.json ./
RUN npm ci --no-audit
COPY . .

FROM node:16-alpine as release
WORKDIR /app
COPY --from=base /app ./
RUN npm run build &&\
  npm prune --omit dev
EXPOSE 80
CMD npm run serve -- --port 80