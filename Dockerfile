FROM node:16-alpine as base
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY pnpm-lock.yaml package.json ./
RUN npm i --location=global pnpm@7 &&\
  pnpm i &&\
  pnpm build
COPY . .

FROM node:16-alpine as release
WORKDIR /app
COPY --from=base /app ./
RUN pnpm build &&\
  pnpm prune --prod
EXPOSE 80
CMD pnpm serve -p 80