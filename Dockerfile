
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
RUN pnpm build &&\
  pnpm prune --prod --config.ignore-scripts=true

FROM node:16-alpine as release
WORKDIR /app
COPY --from=build /app ./
EXPOSE 80
CMD npm run serve -- -p 80