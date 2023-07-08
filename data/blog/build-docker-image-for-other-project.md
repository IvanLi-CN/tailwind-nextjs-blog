---
title: 使用 Github Actions 为其他项目构建 Docker Image
date: '2023-07-09'
tags: ['Github Actions', 'CI/CD', 'Docker']
draft: false
summary: 使用 Github Actions，为自己喜爱的 Github 开源项目，快速、独立、自动化地构建 Docker 镜像，并推送到 ghcr (GitHub Container Registry)。
images: ['https://minio.ivanli.cc/ivan-public/uPic/2023/DZhPx7.jpg']
---

## 背景

这两天搞起了自动追番，使用了 [AutoBangumi](https://github.com/EstrellaXD/Auto_Bangumi/tree/main) 及其部署文档使用的方案组了个套件。感觉还不错，使用 Plex 播放，也让我的 iPad 终于能好好当个播放器了。

其中就包括一个 qBittorrent 程序，自带的 Web UI 很工具化，不是很漂亮，也不是很好用。所以我就找了第三方的，正好它没有单独的 Docker image，所以我就做个自动化构建吧。

本来想在自建的 Gitea Actions 运行的，不过想了想，这个丢 Github 上跑比较合适，反正源头都在 Github 上。之前也有注意到做同样事情的库，但是一直想不起来是什么项目，就没找到……那作业没得抄，只能自己写了。

对了，我选择的 qBittorrent Web UI 是 [VueTorrent](https://github.com/WDaan/VueTorrent)。

## 方案

方案很简单，将目标项目作为 Git Submodule 放在我们的构建 Repo 中。然后分为两步：

1. 使用定时任务，每天检查最新发布的版本。将最新版本拉到项目中并提交。
2. 使用 push 触发器，将新版本构建成 Docker image 并推送到 ghcr (GitHub Container Registry)。

项目地址在这：[IvanLi-CN/vue-torrent-docker: Automatically build VueTorrent Docker images](https://github.com/IvanLi-CN/vue-torrent-docker)

## 实施

下面就是流水帐了。实施这个方案的话，我是先做第二步。因为我当时需要一个 Docker image 来替换原始方案。在文章里，为了流程顺畅，就按上帝视角，用正常的顺序来编写吧。毕竟不是教程，就不循序渐进了。

### 定时检查上游更新

Github Actions 支持使用 Cron 来创建一个定时任务。
所以触发 Action 的问题轻松解决。

```yaml
on:
  schedule:
    - cron: '0 2 * * *'
```

那么第二步就是获取上游最新的发布版本了。
上游使用 “Github Releases” 发布版本：

![Github Releases for VueTorrent](https://minio.ivanli.cc/ivan-public/uPic/2023/bHrczD.png)

所以这里使用了 [git-get-release-action](https://github.com/marketplace/actions/git-get-release-action)，获取最新的版本号和 commitish hash。
其中版本号就是 tag name，而 commit-ish hash 就是平常使用的 commit hash 了。

```yaml
- name: git-get-release-action
  id: git-get-release
  uses: cardinalby/git-get-release-action@1.2.4
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  with:
    repo: WDaan/VueTorrent
    latest: true
```

这里提供了几个参数：

- `GITHUB_TOKEN` 是自动注入的，我们将这个变量作为环境变量提供给 git-get-release-action 就行，缺少这个变量，这个步骤会报错。
- 我们通过 `repo` 提供了上游的仓库名称 “WDaan/VueTorrent”，这个仓库在 Github 上，所以可以直接这么简写。
- 因为只需要获取最新的发布版本，所以提供了 `latest` 为 `true`。

这一步骤会有两个关键的输出：

- `tag_name` 是我们想要的最新版本的版本号，因为他的 git tag 写的就是版本号，例如现在的 `v1.6.0`。
- `current_commitish` 就顾名思义了，接下来就是要用他作为当前 commit 的唯一标记。

我们有了最新版本的 commit-ish 值，那就要有上次构建 Docker image 时用的 commit-ish 值。

```yaml
- name: Get current commitish
  id: get-current-commitish
  run: |
    cd vue-torrent
    echo "Current commitish: $(git rev-parse HEAD)"
    echo "::set-output name=current_commitish::$(git rev-parse HEAD)"
```

这里直接进入子模块的目录里，使用 `git rev-parse HEAD` 命令获取当前 repo 使用的上游的 commit-ish。
因为我们每次构建镜像前，都会先更新子模块的 commit 位置，所以这里就是上次发布镜像时的 commit-ish 了。

再因为我们一直是单调地往按时间往更新的构建，所以不需要比较 commit 的新旧，只要不一样，就是要构建新的镜像。
所以我们这一步，就直接比较最新的 commit 和现在的 commit 是否一直：

```yaml
- name: Compare versions
  id: compare
  run: |
  echo "Current version: ${{ steps.git-get-release.outputs.tag_name }}"
  echo "::set-output name=should_update::${{ steps.git-get-release.outputs.target_commitish != steps.get-current-commitish.outputs.current_commitish }}"
```

下面就是重要的三个步骤了，一更新子模块，二提交更新，三打标签。

#### 更新子模块

```yaml
- name: Update
  if: steps.compare.outputs.should_update == 'true'
  working-directory: ./vue-torrent
  run: |
    git fetch --depth=1 origin ${{ steps.git-get-release.outputs.tag_name }}
    git checkout -b ${{ steps.git-get-release.outputs.tag_name }} ${{ steps.git-get-release.outputs.target_commitish }}
    git reset --hard HEAD
```

_这里使用了 `working-directory` 更改执行目录到子模块中，用 `cd` 进去应该也一样。_

因为之前检出存储库时是只检出最新的那个 commit，所以需使用 `git fetch` 将我们需要的那个 commit 拉到运行环境中，否则会报形如 `fatal: Could not parse object '6ab00a179b9509ef162a14862fb828c78144caff'.` 的错误。

之后使用 `git checkout -b` 将目标的 commit 拉到新的分支上。

最后，将当前的位置设到 HEAD，即目标 commit。

后两步应该是可以直接改成 `git reset --hard ${{ steps.git-get-release.outputs.target_commitish }}`，不过我没试过，仅供参考。

#### 提交更新

```yaml
- name: Commit changes
  if: steps.compare.outputs.should_update == 'true'
  run: |
    git diff
    git config user.name "GitHub Actionss"
    git config user.email "bot@noreply.github.com"
    git add .
    git commit -m "Update to ${{ steps.git-get-release.outputs.tag_name }}"
    git push origin ${{ github.ref_name }}
```

这就没什么好说的了，需要注意的一点就是权限问题。因为我们是 push 到当前的 repo 上，所以可以直接使用自动注入的 `GITHUB_TOKEN`，不过需要在 repo 的设置页面更改下权限：

![Github Actions Permissions Setting](https://minio.ivanli.cc/ivan-public/uPic/2023/QPvf6R.png)

选择 “Read and write permissions"，这样就能写入当前的 repo。

#### 打标签

```yaml
- name: Tag
  if: steps.compare.outputs.should_update == 'true'
  run: |
    git tag ${{ steps.git-get-release.outputs.tag_name }}
    git push origin ${{ steps.git-get-release.outputs.tag_name }}
```

目的就是后面构建镜像时，能方便地从这里取到版本号。

### 构建镜像

这个就比较简单了，代码在这：

[Action](https://github.com/IvanLi-CN/vue-torrent-docker/blob/7439b89cb87bb4627d87f0445e8c1fc39ed89f78/.github/workflows/auto-build.yaml)

[Dockerfile](https://github.com/IvanLi-CN/vue-torrent-docker/blob/7439b89cb87bb4627d87f0445e8c1fc39ed89f78/.github/workflows/auto-build.yaml)

因为直接做成子模块了，流程就简单很多了，只要检出代码时将子模块一并检出，之后直接构建 Docker 镜像就行。

我也不知道有没有人用，只构建了 x86 的自用。

## 最后

分享一下我现在用的追番的 Docker Compose 吧：

`docker-compose.yaml`

```yaml
version: '3.2'
services:
  caddy:
    container_name: caddy
    ports:
      - ${QB_PORT}:80
    networks:
      - auto_bangumi
    restart: unless-stopped
    volumes:
      - ./caddy:/etc/caddy
    image: caddy:2
  vuetorrent:
    container_name: vuetorrent
    expose:
      - 3000
    networks:
      - auto_bangumi
    restart: unless-stopped
    image: ghcr.io/ivanli-cn/vue-torrent:main
  qbittorrent:
    container_name: qBittorrent
    environment:
      - TZ=Asia/Shanghai
      - TemPath=/downloads
      - SavePath=/downloads
      - PGID=${GID}
      - PUID=${UID}
      - WEBUI_PORT=8080
    volumes:
      - qb_config:/config
      - ${DOWNLOAD_PATH}:/downloads
    ports:
      - 6881:6881
      - 6881:6881/udp
    networks:
      - auto_bangumi
    restart: unless-stopped
    image: superng6/qbittorrent:latest

  auto_bangumi:
    container_name: AutoBangumi
    environment:
      - TZ=Asia/Shanghai
      - PGID=${GID}
      - PUID=${UID}
      - AB_DOWNLOADER_HOST=qbittorrent:${QB_PORT}
    networks:
      - auto_bangumi
    volumes:
      - ./auto_bangumi/config:/app/config
      - ./auto_bangumi/data:/app/data
    ports:
      - 7892:7892
    dns:
      - 8.8.8.8
      - 223.5.5.5
    restart: unless-stopped
    image: estrellaxd/auto_bangumi:latest
    depends_on:
      - qbittorrent

  plex:
    container_name: Plex
    environment:
      - TZ=Asia/Shanghai
      - PUID=${UID}
      - PGID=${GID}
      - VERSION=docker
      - PLEX_CLAIM=${PLEX_CLAIM}
    networks:
      - auto_bangumi
    ports:
      - 32400:32400
    volumes:
      - plex_config:/config
      - ${DOWNLOAD_PATH}/Bangumi:/tv
    restart: unless-stopped
    image: lscr.io/linuxserver/plex:latest

networks:
  auto_bangumi:

volumes:
  qb_config:
    external: false
  plex_config:
    external: false
```

`caddy/Caddyfile`

```Caddyfile
:80 {
  reverse_proxy /api/* qbittorrent:8080
  reverse_proxy /* vuetorrent:3000
}
```

`.env`

```bash
QB_PORT=8080
DOWNLOAD_PATH=/home/ivan/downloads
UID=1000
GID=1000

PLEX_CLAIM=claim-DwbcewEB7j3pmNotG_eT
```
