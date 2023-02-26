
FROM node:16-alpine as base
RUN npm i --location=global pnpm@7

FROM base as deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY pnpm-lock.yaml package.json ./
RUN pnpm i

FROM deps as build
WORKDIR /app
COPY . .
COPY --from=deps /app ./
RUN pnpm build

FROM node:16-alpine as release
WORKDIR /app
COPY --from=build /app ./
RUN pnpm prune --prod --config.ignore-scripts=true
EXPOSE 80
CMD npm run serve -- -p 80

FROM build as export
WORKDIR /app
RUN npm run export

FROM alpine:latest as upload
RUN apk add lftp
WORKDIR /app
COPY --from=export /app/out ./
CMD lftp -u "${FTP_ACCOUNT},${FTP_PASSWORD}" "${FTP_HOST}" -e 'set ftp:ssl-allow off && set use-feat no && mirror -R . ./WEB && exit'