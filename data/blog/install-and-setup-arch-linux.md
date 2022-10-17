---
title: 安装并配置 Arch Linux
date: '2022-10-17'
tags: ['Arch Linux', '环境搭建‘, 'VPS']
draft: false
summary: 又到了新装 Arch Linux 的日子了。这次又是温故而知新的机会，把之前写的笔记稍微整理了一下，在这里记录下教徒搭窝的备忘录。
images: ['https://pan.ivanli.cc/api/v3/file/source/2238/archlinux-logo-light.png?sign=bWxqFFy3RUDT5UsWb4UD5byt-_L4h79wede3runRKFc%3D%3A0']
---

## 起势

首先，通过 SSH 以 `root` 用户连接服务器，然后修改 `root` 密码：

```bash
passwd
# 输入两次你的新密码
```

## 重装系统

为了避免 IDC 提供的系统镜像有加料、后门、老旧等问题，拿到服务器后第一件事是重装系统。 Arch Linux 是我的第一选择。

借助 felixonmars 的 [vps2arch](https://github.com/felixonmars/vps2arch)，我们可以将绝大多数的 Linux 系统转换成 Arch Linux 🎉。

```bash
wget https://felixc.at/vps2arch
chmod +x vps2arch
./vps2arch
```

等待几分钟就完成了。如果是中国大陆境内的机子，建议全局代理或使用自定义的系统镜像源。可以从[这个网站](https://archlinux.org/mirrorlist/?country=HK&protocol=https&use_mirror_status=on)获取镜像地址。地址上有查询参数，可以根据自己需要修改。

如果系统装不上，可以在 IDC 面板上重装其他系统后再试，推荐使用 Debian。

脚本执行完成后，按脚本提示执行下面的命令重启设备，密码将被保留：

```bash
sync ; reboot -f
```

重启时，SSH 会断开连接。因为新系统的 SSH 主机指纹会变化，所以需要忘记旧指纹：

```bash
ssh-keygen -R <remote-host>

# example
ssh-keygen -R '[20.20.20.20]:20000'
```

之后重新连接 SSH。

## 基本配置

设置主机名：

```bash
sudo hostnamectl set-hostname arch.example.com
```

启用 pacman 并行下载：

- 编辑 `/etc/pacman.conf`
- 取消 `ParallelDownloads` 前的注释，值为并行下载数

## 常用环境安装

我的常用环境如下：

- 一个自己的账户
- Git
- Yay
- Zsh
- Docker
- TailScale

### 创建账户

安装 `sudo`：

```bash
pacman -Sy sudo
```

创建账户：

```bash
useradd -m ivan
passwd ivan
usermod -aG wheel ivan
```

给刚刚创建的账户分配一个具有 sudo 权限的账户

```bash
EDITOR=vim visudo
```

找到 `%wheel ALL=(ALL: ALL) ALL` 这行，取消这行的注释。

现在，你自己的账号具有 sudo 权限了，接下来切换到自己的账户连接终端吧。

### Git

需要手动安装：

```bash
sudo pacman -S git
```

### Zsh

[Zsh](https://wiki.archlinux.org/title/zsh) 是一个不错的终端外壳（Shell)。

使用 `pacman` 安装：

```bash
sudo pacman -S zsh
```

如果你想执行交互式的初始化配置，可以输入下面命令进入 zsh 并开始初始化配置，否则不要执行下面的命令：

```bash
zsh
```

接下来安装我常用的插件：

```zsh
sh -c "$(curl -fsSL https://git.io/zinit-install)"

echo 'zinit load zsh-users/zsh-syntax-highlighting
zinit load zsh-users/zsh-autosuggestions
zinit load  ael-code/zsh-colored-man-pages
zinit load agkozak/zsh-z
zinit ice depth=1; zinit light romkatv/powerlevel10k' >> ~/.zshrc
```

#### zsh-z

一个快速跳转目录的插件。

避免优先匹配到子目录，在 `.zshrc` 中添加如下行：

```zsh
# zsh-z
ZSHZ_UNCOMMON=1
ZSHZ_TRAILING_SLASH=1
```

#### History

配置历史记录，在 `.zshrc` 中添加如下行：

```zsh
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=1000
setopt INC_APPEND_HISTORY_TIME
```

详细配置参考：[Better zsh history | SoberKoder](https://www.soberkoder.com/better-zsh-history/)
文档：[zsh: 16 Options](https://zsh.sourceforge.io/Doc/Release/Options.html)

### Docker

安装 Docker 和 Docker Compose 也很简单：

```zsh
sudo pacman -S docker docker-compose
# 启动
sudo systemctl start docker
# 启用
sudo systemctl enable docker
# 添加当前用户到 docker 组
sudo usermod -aG docker $USER
# log in to a new group
newgrp docker
```

## 安全配置

### 禁用 SSH 密码登录

修改 `/etc/ssh/sshd_config`，找到 `PasswordAuthentication`，改为 `no`。
然后重启：

```zsh
sudo systemctl restart sshd
```

### 使用 Fail2Ban

安装：

```zsh
sudo pacman -S fail2ban
```

复制配置文件：

```zsh
sudo cp /etc/fail2ban/jail.{conf,local}
```

编辑配置文件，找到 `[sshd]` 块，并添加 `enabled=true`，(**不是解除注释**)：

```zsh
sudo vim /etc/fail2ban/jail.local
```

```text
[sshd]
enabled = true
```

启动 fail2ban

```zsh
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
```

查看状态：

```zsh
sudo fail2ban-client status
```

## 写在最后

大功告成，现在又拥有了一个崭新的 Arch Linux 系统了。后面有机会的话，我得把这些配置脚本化，不然天天配也是有点蠢，哈哈。
