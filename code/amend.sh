#!/bin/bash

# 如果报错，无法找到 GitHub，但是又能访问外网，则执行本脚本

sudo sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'