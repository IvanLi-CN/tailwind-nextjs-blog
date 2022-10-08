FROM node:16-alpine as base
RUN apk add --no-cache libc6-compat
WORKDIR /app
RUN npm i --location=global pnpm@7
COPY pnpm-lock.yaml package.json ./
RUN pnpm i --frozen-lockfile

FROM base as release
WORKDIR /app
COPY . .
COPY --from=base /app ./
RUN pnpm build &&\
  pnpm prune --prod --config.ignore-scripts=true
EXPOSE 80
CMD pnpm serve -p 80