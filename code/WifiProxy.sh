#!/bin/bash
# 这个文件的作用是把 WSL 的网络同我本地主机的网络代理连接在一起，便于让 Linux 连接上外网。注意要手动，不要执行脚本。
export http_proxy="http://172.25.80.1:7890"
export https_proxy="http://172.25.80.1:7890"