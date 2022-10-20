---
title: 搭建日常使用的 Arch Linux
date: '2022-10-17'
tags: ['Arch Linux', '环境搭建', 'VPS']
draft: false
summary: 有了上次快速安装步骤后，接下来就是使用这个环境了。要使用环境，首先需要做一些初始化操作。我的步骤适合我，但不一定适合你，只是记录和参考。
images:
  [
    'https://pan.ivanli.cc/api/v3/file/source/2238/archlinux-logo-light.png?sign=bWxqFFy3RUDT5UsWb4UD5byt-_L4h79wede3runRKFc%3D%3A0',
  ]
---

## Docker

登录私有仓库，以便拉取镜像。

```zsh
docker login -u="ivan+hk_nat" docker-registry.ivanli.cc
```
