---
title: 在 PVE 宿主机上使用桌面环境
date: '2022-10-28'
tags: ['PVE', 'PVE', 'DE', '环境搭建', 'Debian']
draft: false
summary: 虽然 PVE 宿主机不应该安装乱七八糟的东西，但是我穷，为了物尽其用，为了在主力电脑翻车时有一个立即可用的备用环境，所以还是安装了基础的桌面环境。现在的 Linux 桌面环境越来越好了，我选择安装 KDE Plasma 作为桌面环境，并且默认关闭，按需启用。
images: ['https://pan.ivanli.cc/api/v3/file/source/2243/1200px-Kde_dragons.png?sign=yGZL9jYeVt53Ve43ddhHt_0EzVV2cW_WbxHc0dEcwWY%3D%3A0']
---

## 准备

首先应该拥有自己的账户，否则你将会发现自己无法登录桌面环境。因为桌面环境默认在登录时没有 `root` 用户选项。

### 创建账户：

useradd -m ivan
passwd ivan
usermod -aG wheel ivan
给刚刚创建的账户分配一个具有 sudo 权限的账户

EDITOR=vim visudo
找到 %wheel ALL=(ALL: ALL) ALL 这行，取消这行的注释。

现在，你自己的账号具有 sudo 权限了。

### 生成 SSH 密钥

2022 年，应该生成 `ed25519` 算法的密钥：

```bash
ssh-keygen -t ed25519
```

## 启用和禁用桌面环境

**使用 `root` 账户执行下面的命令！**

查看当前的默认目标：

```bash
systemctl get-default
```

临时禁用图形界面：

```bash
init 3
```

临时启用图形界面：

```bash
init 5
```

永久禁用图形界面：重启生效：

```bash
systemctl set-default multi-user.target
```

永久启用图形界面，重启生效：

```bash
systemctl set-default graphical.target
```

## 中文输入法

我使用 iBus + Rime + 小鹤音形.
执行以下命令安装 iBus + Rime：

```bash
sudo apt install ibus ibus-rime
```

接下来配置小鹤音形方案。
访问[小鹤的网盘](http://flypy.ysepan.com/)下载小鹤音形的挂接文件，小狼毫、鼠须管的都可以。
下载完成后解压出来，把压缩文件里的 `rime` 目录复制到 `/home/ivan/.config/ibus/rime`：

```bash
# 如果你没有 unzip，通过下面命令安装：
# sudo apt install unzip

cd ~/Downloads
unzip '小鹤音形“鼠须管”for macOS.zip'
cd '小鹤音形Rime平台鼠须管for macOS'
cp -r ./rime ~/.config/ibus/rime
```

创建 `~/.config/ibus/rime/default.custom.yaml` 文件，并设为以下内容：

```yaml
patch:
  schema_list:
    - {schema: flypy}
    - {schema: luna_pinyin}
```

参考：[分享我的输入法配置 （Rime 小狼豪 + 小鹤音形） - 炒饭之道](https://itx.ink/2018/11/21/SHARE_MY_RIME/)

配置 iBus 环境变量：

```bash
cat >> ~/.zshrc <<EOF

# ibus
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus
EOF
```

启动 ibus

```bash
ibus-setup
```

在打开的 GUI 中添加中文输入法，找到 Rime 并添加输入法：

![rime](https://pan.ivanli.cc/api/v3/file/source/2241/Screen%20Capture_select-area_20221028225457.png?sign=XVrl7rPk4Gd7QRFBCCDGruB2L7V1bvxDpK9-v9pC0Nc%3D%3A0)

现在，新打开的软件应该能使用输入法了。像 Chrome 这类，关闭后还需要手动杀死进程后再打开才能使用。最简单的方法就是重启电脑啦~

## 快捷键

我习惯使用 Mac OS 系统的快捷键，所以 [Kinto](https://github.com/rbreaves/kinto) 是我的不二之选。

安装：

```bash
/bin/bash -c "$(wget -qO- https://raw.githubusercontent.com/rbreaves/kinto/HEAD/install/linux.sh || curl -fsSL https://raw.githubusercontent.com/rbreaves/kinto/HEAD/install/linux.sh)"
```

卸载：

```bash
/bin/bash <( wget -qO- https://raw.githubusercontent.com/rbreaves/kinto/HEAD/install/linux.sh || curl -fsSL https://raw.githubusercontent.com/rbreaves/kinto/HEAD/install/linux.sh ) -r
```

