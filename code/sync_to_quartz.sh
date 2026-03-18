#!/bin/bash

# 本文件的作用是为了解决 quartz 运行在 WSL Linux 系统，而我的 obsidian 运行在 Windows 上的矛盾。该文件会自动将我本地的库备份到 Linux 系统上。
# 配置路径
VAULT_SRC="/mnt/d/Obsidian_Web/Web/"
VAULt_DST="/home/vqs88/quartz/content/"

# 同步命令
rsync -av --delete \
    "$VAULT_SRC/" \
    "$VAULt_DST/" \
    --exclude=".obsidian/" \
    --exclude=".trash/" \
    --exclude="*.tmp"

echo "同步完成: $(date)"

# 因为我已经建立了服务器上的挂载，所以可以通过 npx quartz sync 直接同步到网页上哦。
# 具体教程，详见 https://quartz.jzhao.xyz/setting-up-your-GitHub-repository 
# 账号: neoVqs88
# token: 我放在home下面
