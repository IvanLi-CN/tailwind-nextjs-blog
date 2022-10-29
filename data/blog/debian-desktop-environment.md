---
title: 在 PVE 宿主机上使用桌面环境
date: '2022-10-28'
tags: ['PVE', 'PVE', 'DE', '环境搭建', 'Debian']
draft: false
summary: 虽然 PVE 宿主机不应该安装乱七八糟的东西，但是我穷，为了物尽其用，为了在主力电脑翻车时有一个立即可用的备用环境，所以还是安装了基础的桌面环境。现在的 Linux 桌面环境越来越好了，我选择安装 KDE Plasma 作为桌面环境，并且默认关闭，按需启用。
images:
  [
    'https://pan.ivanli.cc/api/v3/file/source/2243/1200px-Kde_dragons.png?sign=yGZL9jYeVt53Ve43ddhHt_0EzVV2cW_WbxHc0dEcwWY%3D%3A0',
  ]
---

## 前言

过几天就是双十一了，或许是我去购物网站上看了下显卡价格吧，我的显卡当晚就闹情绪，不工作还引发宕机。虽然拔了显卡，我还能用核显开机，但是我懒呀，所以我花了一个晚上在 PVE 宿主机上搭了一个临时环境，用于日常娱乐（看番、听歌）和一般工作（敲代码）。还别说，我在一开始装 PVE 时，就预先装上了桌面环境，这就是预判呀！

现在 Linux 桌面环境已经非常好了，相比 17 年左右的体验，又上了一个新的台阶。不过，作为临时应急环境，倒也不会去装那些没啥用的国产软件，本着够用就好的原则，主要是以 Web App > Web > Linux Client 的顺序挑选软件。一般来说，我用到的也不多：

- **浏览器：Google Chrome**。主要是好用，能同步，还能远程桌面。

## 准备

首先应该拥有自己的账户，否则你将会发现自己无法登录桌面环境。因为桌面环境默认在登录时没有 `root` 用户选项。

### 创建账户：

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

## Google Chrome Browser

安装方式就是直接[官网下载](https://www.google.com/chrome/)。下载完成后双击打开安装。

或者通过命令行安装：

```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

sudo apt install ./google-chrome-stable_current_amd64.deb
```

安装过程中可能会出错，可以使用命令进行安装，然后根据提示修复问题。修复过程中可能会重启电脑。具体情况我没留意，下次遇到的话再补充，嘿嘿。

## VS Code

同样从官网下载安装：[Download Visual Studio Code - Mac, Linux, Windows](https://code.visualstudio.com/download)

### 同步问题

参考：[Visual Studio Code 中的设置同步](https://code.visualstudio.com/docs/editor/settings-sync#_linux)

我用的是 KDE Plasma，似乎[再等等](https://github.com/microsoft/vscode/issues/104319#issuecomment-1250089491)就能直接正常使用了，所以我先忍受同步问题吧。

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
    - { schema: flypy }
    - { schema: luna_pinyin }
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

我习惯使用 Mac OS 系统的快捷键，所以 [Kinto](https://github.com/rbreaves/kinto) 是我的不二之选。key

安装：

```bash
/bin/bash -c "$(wget -qO- https://raw.githubusercontent.com/rbreaves/kinto/HEAD/install/linux.sh || curl -fsSL https://raw.githubusercontent.com/rbreaves/kinto/HEAD/install/linux.sh)"
```

卸载：

```bash
/bin/bash <( wget -qO- https://raw.githubusercontent.com/rbreaves/kinto/HEAD/install/linux.sh || curl -fsSL https://raw.githubusercontent.com/rbreaves/kinto/HEAD/install/linux.sh ) -r
```
