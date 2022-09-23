---
title: 使用 Verdaccio 自建 Node 存储库
date: '2022-09-23'
tags: ['Verdaccio', 'Self-Hosted', 'Docker', 'Caddy', 'registry', 'Node.js']
draft: false
summary: 作为靠着 JavaScript 生态吃饭的 Web 开发者，自建一个 Node regsitry 是很有必要的，我这次继续选择 Verdaccio 来搭建存储库。这次使用 Docker Compose 部署 Verdaccio，并将 Caddy 用于反向代理该服务。
---

## 为何自建存储库？

平常开发项目时，会抽出一些可复用的逻辑封装成 package。如果别人用得上，就可以发布到公开存储库中，比如 NPM，但有些没必要的或者是不可公开的，就需要有私有库了。自建私有库是一个比较好的方案，毕竟至少人手一个服务器不是？四舍五入就是不要钱，白送呐！

再说了，要是遇到了上游 package 有缺陷，无论是自己提了 PR，还是上游已有修复代码，如果想要方便地使用并且与他人共享已修复的 package，使用自建的存储库也是很方便的。

更重要的一点是，Verdaccio 能作为任何仓库的代理。这样我们可以将本地的远程存储库设为 Verdaccio，然后 Verdaccio 上游设为 `https://registry.npmjs.org` (这也是缺省值)，就能得到一个带有缓存的反向代理了，很适合国内的网络环境（bushi)。

接着，就能解锁另一个功能了，假设我们修复了 `axios` 的一个缺陷，我们可以继续使用 `axios` 作为包名发布到 `Verdaccio` 中，这样再拉到的依赖就是我们修复的版本了。当然，版本号应当保持不变。之后上游合并了你的代码后，官方发包后版本号会增加。本地项目更新依赖后就能获取到官方更新的版本了，从而实现了”无感“的效果。

## 如何自建存储库

已有环境：
  - Docker, Docker Compose
  - Caddy (in Docker)
    - 网络：`caddy`

新增：
  - Verdaccio

接下来使用 Docker Compose 部署 Verdaccio，并将其加入到 `caddy` 网络中，之后配置 Caddy，使其反向代理 Verdaccio。

### 使用 Docker Compose 部署

创建文件 `docker-compose.yml`：

```yml {9,16-17} showLineNumbers
version: "3,16-17"

networks:
  caddy:
    external: true # 目前我的 caddy 在其他 compose 中

services:
  verdaccio:
    image: verdaccio/verdaccio:5.x-next
    container_name: verdaccio
    restart: unless-stopped
    networks:
      - caddy
    expose:
      - 4873
#   environment:
#     VERDACCIO_PUBLIC_URL: "https://node-registry.ivanli.cc"
    volumes:
      - ./verdaccio:/verdaccio/conf
      - verdaccio-storage-data:/verdaccio/storage
      - verdaccio-plugins-data:/verdaccio/plugins

volumes:
  verdaccio-storage-data:
  verdaccio-plugins-data:
```

上面第 9 行可以看到，我现在（2022年09月22日）是使用不是正式版本，因为当前的正式版有个缺陷，就是无法正确读取到反向代理提供的 `X-Forwarded-Proto`，这有可能导致访问问题。如果使用正式版本，需要加上第 17 行的环境变量。

**不要启动 compose**，因为你还没有配置文件。当然启动了也没关系，无伤大雅。

### 创建 Verdaccio 配置文件

因为前面将配置文件目录 `verdaccio/conf` 设为了 `verdaccio`，所以：
创建配置文件 `verdaccio/config.yaml`：
```zsh {1,2} showLineNumbers
storage: /verdaccio/storage
plugins: /verdaccio/plugins

auth:
  htpasswd:
    file: ./htpasswd
    algorithm: bcrypt
    rounds: 10
uplinks:
  npmjs:
    url: https://registry.npmjs.org/
packages:
  "@*/*":
    access: $all
    publish: $authenticated
    proxy: npmjs
  "**":
    proxy: npmjs
    publish: $authenticated
    access: $all
log: { type: stdout, format: pretty, level: http }

web:
  enable: true
  title: "Ivan's Node Package Registry"
  logo: logo.png
  scope:
```

第一、二行对应 compose 文件的第 19、20 行。

### htpasswd

使用 [.htpasswd](https://en.wikipedia.org/wiki/.htpasswd) 配置账号密码。

因为我们使用了 `bcrypt` 算法保存密码，所以可以借助 [Bcrypt-Generator.com](https://bcrypt-generator.com/) 生成保存的密码。

创建文件：`verdaccio/htpasswd`:
```htpasswd
admin:$2a$12$9xxxxxxxxxxxxxxlO.slh2k2
```

### 配置 Caddy

```Caddyfile
http://node-registry.ivanli.cc, https://node-registry.ivanli.cc {
  encode zstd gzip
  reverse_proxy verdaccio:4873 {
    // trusted_proxies 172.0.0.0/8 192.168.31.0/24
  }
}
```

结合[官方文档关于反向代理的说明](https://verdaccio.org/docs/reverse-proxy/)，Caddy 默认会传递 `Host` 和 `X-Forwarded-Proto` 字段。所以不需要像 Nginx 和 Apache 一样配置那么多东西。

第四行可选，因为我是多重代理，这个 Caddy 下游还有反向代理服务，所以需要使用 `trusted_proxies` 指令。_([参考](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#defaults))_

### 启动

大工告成，启动 compose：

```bash
docker compose up -d
```

助你成功！

## 使用

### 配置默认远程仓库地址

[Using a private registry | Verdaccio](https://verdaccio.org/docs/cli-registry/)

### 发布与撤销发布

```bash
npm publish --registry="https://node-registry.ivanli.cc"

npm unpublish -f --registry="https://node-registry.ivanli.cc"
```
