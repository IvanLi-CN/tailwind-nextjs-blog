FROM node:16-alpine as base
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY pnpm-lock.yaml package.json ./
RUN npm i --location=global pnpm@7 &&\
  pnpm i
COPY . .
RUN pnpm build &&\
  pnpm prune --prod

FROM node:16-alpine as release
WORKDIR /app
COPY --from=base /app ./
EXPOSE 80
CMD pnpm serve -p 80