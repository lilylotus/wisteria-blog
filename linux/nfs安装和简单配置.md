---
title: "NFS安装和简单配置说明"
subtitle: "NFS安装和简单配置说明"
description: "NFS安装和简单配置说明"
date: 2025-03-18T22:33:53+08:00
lastmod: 2025-03-18T22:33:53+08:00
draft: false

authors: ["yzx"]
tags: ["Linux"]
categories: []
series: []

featuredImage: "https://www.nihility.cn/files/images/IQDQ3974.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# NFS 安装和简单配置

## NFS服务简介

摘抄自 [Wiki NFS 简介](https://zh.wikipedia.org/wiki/%E7%BD%91%E7%BB%9C%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F) 部分说明

网络文件系统（Network File System，缩写 NFS）是一种[分布式文件系统](https://zh.wikipedia.org/wiki/%E5%88%86%E6%95%A3%E5%BC%8F%E6%AA%94%E6%A1%88%E7%B3%BB%E7%B5%B1)，力求客户端主机可以访问服务器端文件，并且其过程与访问本地存储时一样，它由Sun微系统（已被甲骨文公司收购）开发，于1984年发布。

NFS 服务可以挂载远程主机的共享目录到本地，就像操作本地磁 盘一样，非常方便的操作远程文件。

它基于[开放网络运算远程过程调用](https://zh.wikipedia.org/wiki/開放網路運算遠端程序呼叫)（ONC RPC）系统：一个开放、标准的 [RFC](https://zh.wikipedia.org/wiki/RFC) 系统，任何人或组织都可以依据标准实现它。

## NFS服务端

下面在 Centos7 中安装 NFS 服务。

根据官网说明 [Chapter 8. Network File System (NFS) - Red Hat Customer Portal](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/ch-nfs)，CentOS 7.4 以后，支持 NFS v4.2 不需要 rpcbind 了，但是如果客户端只支持 NFC v3 则需要 rpcbind 这个服务。

### 安装 NFS 服务

```bash
yum install -y nfs-utils
```

> 注意：只安装 nfs-utils 即可，rpcbind 属于它的依赖，也会安装上。
>

### NFS 服务配置

> 小贴士：Centos7 nfs 服务文件 `/usr/lib/systemd/system/nfs.service` 链接 `/usr/lib/systemd/system/nfs-server.service` 服务文件。
>
> 注意： NFS 依赖 rpcbind 服务，nfs 服务默认端口 **2049/(tcp/udp/sctp)** ， rpcbind 服务默认端口 **111/(tcp/udp)**

设置 NFS 服务开机自启

```bash
systemctl enable nfs
# systemctl enable nfs-server
```

启动 nfs 服务

```bash
systemctl start nfs
```

防火墙打开 nfs 服务

```bash
firewall-cmd --zone=public --permanent --add-service={rpc-bind,mountd,nfs}
firewall-cmd --reload

# 或者开放端口
firewall-cmd --zone=public --permanent --add-port=2049/tcp
firewall-cmd --zone=public --permanent --add-port=2049/udp
firewall-cmd --reload
```

### NFS 服务端共享目录配置

NFS 共享目录配置文件 `/etc/exports`

添加共享目录配置

```
/server/nfs 192.168.99.0/24(rw,sync,all_squash,subtree_check)
# 以 nfsnobody 创建文件，但不能删除

/server/nfs 192.168.99.0/24(rw,sync,root_squash,subtree_check) [推荐]
# 以访问账户创建文件，仅能编辑、删除本账户文件
```

- `/data/`：共享目录位置
- `192.168.0.0/24`：允许使用此资源的客户端 IP 范围，`*` 表示所有即无客户端限制
- `rw`：权限设置，可读可写
- `sync`：数据同步写入磁盘
- `root_squash`：当 root 账号访问时映射为 NFS 服务端匿名账户（nobody），普通账户映射为普通账户
- `no_root_squash`: 允许远程 root 用户访问共享目录，拥有 root 权限（不推荐，不安全）
- `no_all_squash`: 保留客户端用户的 UID 和 GID
- `all_squash`：不管客户端使用什么账户访问，均映射为 NFS 服务器匿名账户（nobody），推荐
- `subtree_check`：服务端会验证客户端创建的文件所在挂载点是否已经变更

配置完成后重启 nfs 服务让配置生效或执行刷新配置命令。

```bash
# 重启 nfs 服务
systemctl restart nfs

# 刷新配置，让其立即生效，执行如下命令
exportfs -a
```

验证 nfs 服务配置是否生效

```bash
$ showmount -e localhost

Export list for localhost:
/server/nfs 192.168.99.0/24
```

下面客户端就可以使用 nfs 服务提供的共享目录。

## NFS客户端

### NFS 客户端安装

和 nfs 服务安装一致。

```bash
yum install -y nfs-utils
```

### NFS 客户端配置

nfs 客户端仅需使用 rpcbind 服务

> 注意：客户端不需要打开防火墙，因为客户端时发出请求方，网络能连接到服务端即可。客户端也不需要开启 NFS 服务，因为不共享目录。

### 客户端连接 NFS 服务

检测 nfs 服务端共享目录是否能用

```bash
$ showmount -e 192.168.99.90

Export list for 192.168.99.90:
/server/nfs 192.168.99.0/24
```

创建客户端挂载目录

```bash
mkdir -p /data/share/nfs
```

挂载 nfs 服务共享目录

```bash
mount -t nfs 192.168.99.90:/data/nfs/ /data/share/nfs
```

> NFS 默认 UDP 协议挂载，为了提高 NFS 的稳定性，可以使用 TCP 协议挂载，那么客户端挂载命令可使用如下命令：
>
> `mount -o proto=tcp,nolock -t nfs 192.168.1.1:/data/share /data/share`

自动挂载写入自启挂载配置文件 `/etc/fstab`

```
192.168.99.90:/data/nfs /data/share/nfs nfs defaults 0 0

# 采用 tcp 协议挂载
192.168.99.90:/data/nfs /data/nfs/share nfs proto=tcp,noatime,nodiratime,nolock,intr 0 0
```

