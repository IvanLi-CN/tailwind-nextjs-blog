FROM node:16-alpine as base
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package-lock.json package.json ./
RUN npm ci --no-audit --legacy-peer-deps
COPY . .

FROM node:16-alpine as release
WORKDIR /app
COPY --from=base /app ./
RUN npm run build &&\
  npm prune --omit dev --legacy-peer-deps
EXPOSE 80
CMD npm run serve -- --port 80