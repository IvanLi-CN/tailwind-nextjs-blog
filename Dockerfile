FROM node:16-alpine as base
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package-lock.json package.json ./
RUN curl -f https://get.pnpm.io/v6.16.js | node - add --global pnpm@7 &&\
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