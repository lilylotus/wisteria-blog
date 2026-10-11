---
title: "VMware Esxi8 安装"
subtitle: "Esxi 8 安装"
description: "VMware vsphere 8 安装 / VMware Esxi 8 安装"
date: 2024-09-11T00:59:09+08:00
lastmod: 2024-09-11T00:59:09+08:00
draft: false

authors: ["yzx"]
tags: ["Esxi"]
categories: ["VMware"]
series: []

featuredImage: "https://www.nihility.cn/files/images/esxi8/img_1699.png"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---


## VMware Vsphere (Esxi) 安装

这里安装的是 esxi 8 版本，大多数步骤都是直接下一步在下一步。

![esxi8-install-01.png](https://www.nihility.cn/files/images/esxi8/esxi-install-01.png)

![esxi8-install-02.png](https://www.nihility.cn/files/images/esxi8/esxi-install-02.png)

![esxi8-install-03.png](https://www.nihility.cn/files/images/esxi8/esxi-install-03.png)

![esxi8-install-04.png](https://www.nihility.cn/files/images/esxi8/esxi-install-04.png)

![esxi8-install-05.png](https://www.nihility.cn/files/images/esxi8/esxi-install-05.png)

![esxi8-install-06.png](https://www.nihility.cn/files/images/esxi8/esxi-install-06.png)

![esxi8-install-07.png](https://www.nihility.cn/files/images/esxi8/esxi-install-07.png)

![esxi8-install-08.png](https://www.nihility.cn/files/images/esxi8/esxi-install-08.png)

输入密码，需要满足密码复杂度：

- 默认情况下，在创建密码时，必须至少包括以下四类字符中三类字符的组合：小写字母、大写字母、数字和特殊字符（如下划线或短划线）。
- 默认情况下，密码长度至少为 7 个字符，且小于 40 个字符。

![esxi8-install-09.png](https://www.nihility.cn/files/images/esxi8/esxi-install-09.png)

![esxi8-install-10.png](https://www.nihility.cn/files/images/esxi8/esxi-install-10.png)

选择安装 esxi 系统的盘符。

![esxi8-install-11.png](https://www.nihility.cn/files/images/esxi8/esxi-install-11.png)

![esxi8-install-12.png](https://www.nihility.cn/files/images/esxi8/esxi-install-12.png)

![esxi8-install-13.png](https://www.nihility.cn/files/images/esxi8/esxi-install-13.png)

![esxi8-install-14.png](https://www.nihility.cn/files/images/esxi8/esxi-install-14.png)

## Esxi 配置

经过一小段时间的等待，Esxi 安装完成，重启后到开机界面，此界面显示默认的 web 访问地址，但是作为服务器 IP 访问地址大都是固定 IP，所有还需进入管理界面，进一步调整。

esxi 各个版本的配置大体都是一致的。

- 按 F2 输入安装是配置的密码，进入配置页面。

![esxi8-install-15.png](https://www.nihility.cn/files/images/esxi8/esxi-install-15.png)

开始配置访问 IP ，此处会修改为固定 IP 地址。

![esxi8-install-16.png](https://www.nihility.cn/files/images/esxi8/esxi-install-16.png)

![esxi8-install-17.png](https://www.nihility.cn/files/images/esxi8/esxi-install-17.png)

选择那个网卡作为 Esxi 服务器的管理网口。

![esxi8-install-18.png](https://www.nihility.cn/files/images/esxi8/esxi-install-18.png)

配置 Esxi 服务器固定 IP 地址（此处为 IPv4 配置项）， IPv6 可以默认或者关闭。

![esxi8-install-19.png](https://www.nihility.cn/files/images/esxi8/esxi-install-19.png)

配置 Esxi 服务器为静态 IP 地址，地址为当前网络可访问的 IP 地址。

![esxi8-install-20.png](https://www.nihility.cn/files/images/esxi8/esxi-install-20.png)

![esxi8-install-21.png](https://www.nihility.cn/files/images/esxi8/esxi-install-21.png)

![esxi8-install-22.png](https://www.nihility.cn/files/images/esxi8/esxi-install-22.png)

配置完成后，就可以在 web 端通过浏览器访问 Esxi 提供的服务，此处做了域名映射，按照上面静态 IP 地址配置，此处访问地址为  https://10.10.66.1 

- 访问用户名默认为 **root**
- 访问用户名对应密码为安装流程中输入的密码

![esxi8-install-23.png](https://www.nihility.cn/files/images/esxi8/esxi-install-23.png)

登录成功后就进入 Esxi Web 端管理界面，界面展示还是一如既往的沉稳大气。

![esxi8-install-24.png](https://www.nihility.cn/files/images/esxi8/esxi-install-24.png)

配置 Esxi License 授权码，这个可以去网上搜索，大都是可以直接使用的，这里提供当时可用的授权码，仅供个人测试使用：

- ESXi 8： HG00K-03H8K-48929-8K1NP-3LUJ4

![esxi8-install-25.png](https://www.nihility.cn/files/images/esxi8/esxi-install-25.png)

配置 NTP 网络时间服务器，这里使用阿里提供的 NTP 服务地址 ：ntp.aliyun.com

![esxi8-install-26.png](https://www.nihility.cn/files/images/esxi8/esxi-install-26.png)

![esxi8-install-31.png](https://www.nihility.cn/files/images/esxi8/esxi-install-31.png)

![esxi8-setup-05.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-05.png)

开启 esxi 启动后自动启用指定虚拟机。

![esxi8-install-27.png](https://www.nihility.cn/files/images/esxi8/esxi-install-27.png)

### 网络配置

物理网卡列表

![esxi8-install-28.png](https://www.nihility.cn/files/images/esxi8/esxi-install-28.png)

虚拟交换机列表

添加虚拟交换机和物理网卡口绑定起来，物理网卡可以通过网线关联外部网络设备。

还可以不绑定任何物理网卡口但仅能内部虚拟机使用，无法通过网线连通外部设备。

![esxi8-install-29.png](https://www.nihility.cn/files/images/esxi8/esxi-install-29.png)

端口组列表，端口组类似与路由器

添加端口组和指定虚拟交换机绑定起来。

![esxi8-install-30.png](https://www.nihility.cn/files/images/esxi8/esxi-install-30.png)

添加存储，若是除了刚才安装系统的磁盘还有额外的磁盘，可以添加新的存储。

![esxi8-setup-08.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-08.png)

![esxi8-setup-09.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-09.png)

![esxi8-setup-10.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-10.png)

![esxi8-setup-11.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-11.png)

![esxi8-setup-12.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-12.png)

有了存储，就可以往指定存储中上传文件，指定文件管理操作。

![esxi8-setup-13.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-13.png)

### 创建虚拟机

若是玩过 VMware Workstation Pro ，就和在上面创建虚拟机一致。
这里简单创建一个 Centos7 系统虚拟机。

![esxi8-setup-14.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-14.png)

![esxi8-setup-15.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-15.png)

![esxi8-setup-16.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-16.png)

![esxi8-setup-17.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-17.png)

![esxi8-setup-18.png](https://www.nihility.cn/files/images/esxi8/esxi-setup-18.png)



## VMware vCenter 安装



![vsca-install-01.png](https://www.nihility.cn/files/images/esxi8/vsca-install-01.png)

![vsca-install-02.png](https://www.nihility.cn/files/images/esxi8/vsca-install-02.png)

![vsca-install-03.png](https://www.nihility.cn/files/images/esxi8/vsca-install-03.png)

![vsca-install-04.png](https://www.nihility.cn/files/images/esxi8/vsca-install-04.png)

这里把 vCenter 安装到 Esxi 服务器中作为一个虚拟机的存在。

这里推荐直接使用 Esxi 服务器的 IP 地址，方式域名解析问题。

![vsca-install-05.png](https://www.nihility.cn/files/images/esxi8/vsca-install-05.png)

![vsca-install-06.png](https://www.nihility.cn/files/images/esxi8/vsca-install-06.png)

![vsca-install-07.png](https://www.nihility.cn/files/images/esxi8/vsca-install-07.png)

![vsca-install-08.png](https://www.nihility.cn/files/images/esxi8/vsca-install-08.png)

![vsca-install-09.png](https://www.nihility.cn/files/images/esxi8/vsca-install-09.png)

![vsca-install-10.png](https://www.nihility.cn/files/images/esxi8/vsca-install-10.png)

这里的 FQDN 为 vCenter 的访问域名，后面可以在主机 hosts 中添加 IP 地址到此域名映射。

IP 地址为 vCenter 主机所在 IP 地址。

![vsca-install-11.png](https://www.nihility.cn/files/images/esxi8/vsca-install-11.png)

![vsca-install-12.png](https://www.nihility.cn/files/images/esxi8/vsca-install-12.png)

![vsca-install-13.png](https://www.nihility.cn/files/images/esxi8/vsca-install-13.png)

![vsca-install-14.png](https://www.nihility.cn/files/images/esxi8/vsca-install-14.png)

![vsca-install-15.png](https://www.nihility.cn/files/images/esxi8/vsca-install-15.png)

![vsca-install-16.png](https://www.nihility.cn/files/images/esxi8/vsca-install-16.png)

![vsca-install-17.png](https://www.nihility.cn/files/images/esxi8/vsca-install-17.png)

![vsca-install-18.png](https://www.nihility.cn/files/images/esxi8/vsca-install-18.png)

![vsca-install-19.png](https://www.nihility.cn/files/images/esxi8/vsca-install-19.png)

![vsca-install-20.png](https://www.nihility.cn/files/images/esxi8/vsca-install-20.png)

![vsca-install-21.png](https://www.nihility.cn/files/images/esxi8/vsca-install-21.png)

![vsca-install-22.png](https://www.nihility.cn/files/images/esxi8/vsca-install-22.png)

![vsca-install-23.png](https://www.nihility.cn/files/images/esxi8/vsca-install-23.png)

### vCenter 配置

![vsca-setup-01.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-01.png)

![vsca-setup-02.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-02.png)

![vsca-setup-03.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-03.png)

![vsca-setup-04.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-04.png)

![vsca-setup-05.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-05.png)

![vsca-setup-06.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-06.png)

![vsca-setup-07.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-07.png)

![vsca-setup-08.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-08.png)

![vsca-setup-09.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-09.png)

![vsca-setup-10.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-10.png)

![vsca-setup-11.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-11.png)

![vsca-setup-12.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-12.png)

![vsca-setup-13.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-13.png)

![vsca-setup-14.png](https://www.nihility.cn/files/images/esxi8/vsca-setup-14.png)