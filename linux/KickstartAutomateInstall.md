---
title: "Centos Kickstart 自动批量安装（PXE）"
subtitle: "Centos 自动批量安装"
description: "Centos Kickstart 自动批量安装（PXE）"
date: 2024-10-10T22:36:09+08:00
lastmod: 2024-10-10T22:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["Linux"]
categories: ["Linux"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1953.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---



# Kickstart 服务安装

[Kickstart 安装文档](https://docs.centos.org/en-US/centos/install-guide/Kickstart2/)

## 自动安装脚本

没有耐心详细看具体需要安装那些服务和如何配置的 TA 可以直接使用下面的安装执行脚本，一步到位安装完成。

> 注意：
>
> 1. 需要连网安装一些服务，yum 可以安装服务软件。
> 2. 需要挂载 Centos（7） iso 镜像，Vmware 虚拟机需要启动加载 Centos7 ISO 镜像。

参数说明：

|                   参数 | 说明                                                |
| ---------------------: | :-------------------------------------------------- |
|           DHCP_NETWORK | Kickstart服务器所在的网络                           |
|           DHCP_NETMASK | Kickstart服务器所在的网络掩码                       |
|        DHCP_NET_ROUTER | Kickstart服务器所在网络网关路由                     |
|     DHCP_NETWORK_RANGE | Kickstart服务器 DHCP 服务对客户端分配的 IP 地址范围 |
|   DHCP_PXE_NEXT_SERVER | Kickstart服务器所在 IP 地址                         |
|     DHCP_DOMAIN_SERVER | Kickstart服务器分配给客户端的网络 DNS 列表          |
| DHCP_NETWORK_BROADCAST | Kickstart服务器网络广播地址                         |

```bash
#!/bin/bash

# PXE DHCP 相关配置
DHCP_NETWORK=10.10.10.0
DHCP_NETMASK=255.255.255.0
DHCP_NET_ROUTER=10.10.10.2
DHCP_NETWORK_RANGE='10.10.10.200 10.10.10.240'
DHCP_PXE_NEXT_SERVER=10.10.10.12
DHCP_DOMAIN_SERVER=10.10.10.2,223.5.5.5
DHCP_NETWORK_BROADCAST=10.10.10.255

# PXE FTP/TFTP 相关配置参数
PXE_SERVER_ADDRESS=${DHCP_PXE_NEXT_SERVER}
PXE_FTP_BASE_DIR=/var/ftp/pub
PXE_TFTP_SUB_DIR=pxelinux
PXE_TFTP_BASE_DIR=/var/lib/tftpboot/${PXE_TFTP_SUB_DIR}

# ==========================================================================
# 安装、配置基础服务
systemctl stop firewalld.service && systemctl disable firewalld.service
setenforce 0

curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo

# 安装 TFTP 服务器
yum install -y tftp-server dhcp vsftpd xinetd syslinux
# 开启自启服务
systemctl enable vsftpd
systemctl enable dhcpd
systemctl enable tftp
systemctl enable xinetd

# 配置 tftp 服务
# vim /etc/xinetd.d/tftp
# disable     = yes 改为 no
sed -ri '/disable/s/yes/no/g' /etc/xinetd.d/tftp

# ==========================================================================
# DHCP 服务配置
# vim /etc/dhcp/dhcpd.conf
cat <<EOF > /etc/dhcp/dhcpd.conf
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;

option pxelinux.mtftp-ip code 1 = ip-address;
option pxelinux.mtftp-cport code 2 = unsigned integer 16;
option pxelinux.mtftp-sport code 3 = unsigned integer 16;
option pxelinux.mtftp-tmout code 4 = unsigned integer 8;
option pxelinux.mtftp-delay code 5 = unsigned integer 8;
option pxelinux.discovery-control code 6 = unsigned integer 8;
option pxelinux.discovery-mcast-addr code 7 = ip-address;

option arch code 93 = unsigned integer 16;

default-lease-time 600;
max-lease-time 7200;

ignore client-updates;
ddns-update-style interim;
allow bootp;
allow booting;
allow unknown-clients;
server-name pxelinux;

subnet ${DHCP_NETWORK} netmask ${DHCP_NETMASK} {
    option routers ${DHCP_NET_ROUTER};
    option subnet-mask ${DHCP_NETMASK};
    option domain-name-servers ${DHCP_DOMAIN_SERVER};
    option broadcast-address ${DHCP_NETWORK_BROADCAST};
    range ${DHCP_NETWORK_RANGE};

    class "pxeclients" {
        match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";

        if option arch = 00:07 {
            # for UEFI client 采用 shim 打包的 EFI 引导映象
            filename "${PXE_TFTP_SUB_DIR}/uefi/shim.efi";
        } else if option arch = 00:09 {
            # for UEFI client 采用 shim 打包的 EFI 引导映象
            filename "${PXE_TFTP_SUB_DIR}/uefi/shim.efi";
        } else {
            # for legacy client SYSLINUX 打包的 BIOS 引导映像
            filename "${PXE_TFTP_SUB_DIR}/pxelinux.0";
        }

        # 提供引导文件的服务器 IP 地址，即 tftp 服务器地址
        next-server ${DHCP_PXE_NEXT_SERVER};
    }
}

EOF

# 重启 DHCP 服务
systemctl restart dhcpd
systemctl restart vsftpd
systemctl restart tftp
systemctl restart xinetd

# ==========================================================================
# VSFTP 文件准备
mkdir -p ${PXE_FTP_BASE_DIR}/{centos7,centos8,ksdir,kernel,sh}
mount -o loop,ro /dev/sr0 ${PXE_FTP_BASE_DIR}/centos7

# pxe 安装配置
mkdir -p ${PXE_TFTP_BASE_DIR}/{centos7,centos8,uefi,pxelinux.cfg}
# 将 Centos7 引导镜像复制到 pxelinux 下
cp ${PXE_FTP_BASE_DIR}/centos7/images/pxeboot/{initrd.img,vmlinuz} ${PXE_TFTP_BASE_DIR}/centos7/

# legacy BIOS 安装 pxelinux.0
cp /usr/share/syslinux/{vesamenu.c32,menu.c32} ${PXE_TFTP_BASE_DIR}
cp /usr/share/syslinux/pxelinux.0 ${PXE_TFTP_BASE_DIR}

# UEFI
mkdir -p ${PXE_TFTP_BASE_DIR}/uefi/
SHIM_RPM_PATH=$(ls ${PXE_FTP_BASE_DIR}/centos7/Packages/shim-x64-*)
GRUB2_EFI_RPM_PATH=$(ls ${PXE_FTP_BASE_DIR}/centos7/Packages/grub2-efi-x64-*)
cp -pr ${SHIM_RPM_PATH} ${PXE_TFTP_BASE_DIR}/uefi/
cp -pr ${GRUB2_EFI_RPM_PATH} ${PXE_TFTP_BASE_DIR}/uefi/
# 解压安装包
PXE_TFTP_CURRENT_DIR=$(pwd)
cd ${PXE_TFTP_BASE_DIR}/uefi/
ls *.rpm | xargs -n1 -I{} sh -c "rpm2cpio {} | cpio -dimv"
# rpm2cpio shim-x64-15-8.el7.x86_64.rpm | cpio -dimv
# rpm2cpio grub2-efi-x64-2.02-0.86.el7.centos.x86_64.rpm | cpio -dimv
cp boot/efi/EFI/centos/{shim.efi,grubx64.efi} .
chmod 755 *.efi
rm -rf boot etc
rm -f *.rpm
cd ${PXE_TFTP_CURRENT_DIR}

# https://www.golinuxcloud.com/rhel-centos-8-kickstart-example-generator/
# https://docs.centos.org/en-US/8-docs/standard-install/assembly_custom-boot-options/
# https://docs.centos.org/en-US/8-docs/advanced-install/assembly_preparing-for-a-network-install/#configuring-a-tftp-server-for-bios-based-clients_preparing-for-a-network-install

# 添加配置文件
# vim /var/lib/tftpboot/pxelinux/uefi/grub.cfg
cat <<EOF > ${PXE_TFTP_BASE_DIR}/uefi/grub.cfg
set timeout=10
menuentry 'Centos 7 UEFI' {
  linuxefi ${PXE_TFTP_SUB_DIR}/centos7/vmlinuz ip=dhcp ks=ftp://${PXE_SERVER_ADDRESS}/pub/ksdir/anaconda-centos7-uefi.cfg
  initrdefi ${PXE_TFTP_SUB_DIR}/centos7/initrd.img
}
menuentry 'Centos 8 UEFI' {
  linuxefi ${PXE_TFTP_SUB_DIR}/centos8/vmlinuz ip=dhcp inst.ks=ftp://${PXE_SERVER_ADDRESS}/pub/ksdir/anaconda-centos8-uefi.cfg
  initrdefi ${PXE_TFTP_SUB_DIR}/centos8/initrd.img
}
EOF

chmod 644 ${PXE_TFTP_BASE_DIR}/uefi/grub.cfg

# pxe tftp bios 默认配置
# vim /var/lib/tftpboot/pxelinux/pxelinux.cfg/default
cat <<EOF > ${PXE_TFTP_BASE_DIR}/pxelinux.cfg/default
default vesamenu.c32
prompt 0
timeout 300
display boot.msg
menu title ###### PXE Boot Menu ######

label centos7bios
  menu label ^Install CentOS 7 BIOS
  kernel centos7/vmlinuz
  append initrd=centos7/initrd.img ip=dhcp ks=ftp://${PXE_SERVER_ADDRESS}/pub/ksdir/anaconda-centos7-bios.cfg
label centos8bios
  menu label ^Install CentOS 8 BIOS
  kernel centos8/vmlinuz
  append initrd=centos8/initrd.img ip=dhcp inst.ks=ftp://${PXE_SERVER_ADDRESS}/pub/ksdir/anaconda-centos8-bios.cfg
label local
  menu default
  menu label Boot from ^local drive
  localboot 0xffff
EOF
```

自动安装脚本详细说明：[准备 Kickstart 网络安装所需参考稳定](https://docs.centos.org/en-US/centos/install-guide/pxe-server/)

1. 安装所需的服务或软件包：tftp-server dhcp vsftpd xinetd syslinux

2. DHCP 服务端配置，指定 Kickstart 服务初始化网络安装启动镜像
3. Kickstart 网络安装引导配置， [基于 BIOS 引导模式](https://docs.centos.org/en-US/centos/install-guide/pxe-server/#sect-network-boot-setup-bios) / [基于 UEFI 引导模式](https://docs.centos.org/en-US/centos/install-guide/pxe-server/#sect-network-boot-setup-uefi)
4. 随后就是编写 Kickstart 自动安装配置文件， [Kickstart 自动安装配置脚本语法说明](https://docs.centos.org/en-US/centos/install-guide/Kickstart2/#sect-kickstart-syntax)， [Kickstart 语法参考](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-syntax)

ssh公钥、私钥配置：

- 私钥 id_rsa

```
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAySo4fJmrex56+KICq85FlCkqHm6t9cnUnlc4fIgxozCuaOL4
fsQY7+Y7jD8qQE6U2w6bJ6Gek42rrSxYPJRck6n7KCttKaDXIPxpd+UYd7l89LjE
VPlSEBrVs6DYm6+f/FWDMV02GDELn7FetiEcIrwCMGsIKfz8uP0T3Vu6IGvN/zmy
2ict0eqiCgHF+C7so1qdEJjhyFmVUjvYSjno7R1t0MPptXvy71K8eyWVuuYrnv8x
HBf7SILgFshzGBMje9MX7RZSC2SfLs8ath5g2Bb6vxiid73jAdwSC9XDysnZPlPo
tAtO8E+U7GnxLMGu+xYsr0WdDQ8ih2SGQ5zcBQIDAQABAoIBAEqvzkEUnMIdUvK0
0+ENuG+FyQl7dkLnKHWRVHuH5UX9cQOoITKPg+KtzDYJzZoKkuGxzpEsRD/sPW0S
JcB4JNb+KS2E0ga+nKC2lkHZYPgyed4yK1KRLpKkI+uJMGK9Fd0NsqPFQ6w/qV0k
8VEVgeizfOyVEHbmYr4b2CA7SiN2uXIewzEisC5YoepdqGjI5VFpg3Cc351ZVP9g
U1OXEIt3Zzod3QjzTmMfrhac5B0WwTOmUDLqapQV4YZiSAUer4tVpDYhr0WgLN6+
9xfTAQnN75UwQwVnt5sfyyYxJySguf6Ek50ycWh8xL9ByPqMLYJ/WpKN2H3KEcyn
uW7f9RECgYEA/ho79k07WlfHxR3rYrbfHQO93lVOoVRqrUi8uLVFTq7zGPgpesBK
HAC0Hv5BFW67PQPSK/UlTncUmKjQmT5PT9PJEwXJKW5VfCW3aj/1IxlFDemj8Jgn
B8cbmT63zz/mXkUV9/EnPB+rWctjxRA24H+ZaleJNyyH+7r2y2KJ8IcCgYEAyqrJ
PkxNPONL+g4jZ5swxcsj08snERWcpgqI5o7piGoaJIRhdb7xtbOt9plErXm3DKES
on4+6p0oMP7owmp3DsOMx8yZkb9yrrmuSlXRcaCHrGlibY1+5k9WZSB7tJjyOXS7
n9sxsSXshOchm+JpToRxN3xjGs1aQHEBTGFKbhMCgYB7a5KkV270up41iArEr74/
AYo/a3/9rFsEP8gqjyFSzncVMbQ0AyH75/uU8jn6hwY65Jg48aFlM0G1xIlNZY5w
X5XSv4StswGig09LNDWFDskTsOAIBF8wz+z/yg7Ng2QJddTt0RwVf+xieP/Ev9Nn
x5JkrI/hVKfYBT/KGdqWEQKBgQC0Bkci7pZBespXgc2TT7hgSlU14iR+uYrft0Xq
P5JUWaOFQo5sEEQXGldyUK0/x3mBX2b1Ll1m/FjiRNyvLfE6DRx1slnLrJsLd+bJ
IzgbzfQWg7oqBGFv5ZOh2tvoDWBFB1tO4V9fs4dIeyNQnCrc0yralcRW34jG61qy
5U0/PwKBgBC8JFvzkI+KEC5GoKg93RU/b0sxd2XtxgxtDJ9dwsdyvCPUAxRj8JJ2
hjW+unz0Yg0Qq6tms6cMvhX30iVYifxBy+F+taI93QlJpIy3AZClgkJH9opAWp0u
6jzxghSs+wWygCPPtv6X0OWhO+OLQHtR6idIQENVNuY0SHoUF6xs
-----END RSA PRIVATE KEY-----
```

- 公钥 id_rsa.pub

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDJKjh8mat7Hnr4ogKrzkWUKSoebq31ydSeVzh8iDGjMK5o4vh+xBjv5juMPypATpTbDpsnoZ6TjautLFg8lFyTqfsoK20poNcg/Gl35Rh3uXz0uMRU+VIQGtWzoNibr5/8VYMxXTYYMQufsV62IRwivAIwawgp/Py4/RPdW7oga83/ObLaJy3R6qIKAcX4LuyjWp0QmOHIWZVSO9hKOejtHW3Qw+m1e/LvUrx7JZW65iue/zEcF/tIguAWyHMYEyN70xftFlILZJ8uzxq2HmDYFvq/GKJ3veMB3BIL1cPKydk+U+i0C07wT5TsafEswa77FiyvRZ0NDyKHZIZDnNwF root@localhost.localdomain
```



## Kickstart 自动安装配置文件

### 基于 BIOS 系统引导的配置

```
#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512
# Use Network installation media
install
# Use text install
text
# Use network installation
# https://mirrors.aliyun.com/centos/7.9.2009/os/x86_64
url --url="ftp://10.10.10.12/pub/centos7"
# Run the Setup Agent on first boot
firstboot --enable
ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8 --addsupport=zh_CN.UTF-8

# Network information
network  --bootproto=dhcp --device=ens192 --ipv6=auto --activate
network  --hostname=localhost.localdomain

# Reboot after installation
reboot

# Root password
rootpw --iscrypted $6$L5vmBcP8ynEaNBOi$brrFxVIUtptUxl6JpxI7s8nE1oV3rFjZX038CrtkecVBYHKn.HLgZ9LyGxSkCxATfxE.AbXu0RfUsz1.QeKAO0
user --name=luck --password=$6$/fIzWr75/.gw7niA$Uw/xd9X.BpUcnDnkvP2YQCpXkaFnmz/aXkosNcVod/ACk9jAlbMpQandd8OnMxW4abZ4yozx9SOX/QVGDZQqu0 --iscrypted --gecos="luck"
# user -name=lily --password=lily --plaintext

# System services
services --enabled="chronyd"
# SELinux configuration
selinux --disabled
# Firewall configuration
firewall --disabled
# Do not configure the X Window System
skipx
# System timezone (ntp.aliyun.com)
timezone Asia/Shanghai --isUtc --ntpservers=ntp.aliyun.com

# System bootloader configuration
bootloader --boot-drive=sda
# Clear the Master Boot Record
zerombr
# Partition clearing information
# --none (default) - Do not remove any partitions.
clearpart --all --initlabel --drives=sda

# Disk partitioning information
part /boot --fstype="xfs" --ondisk=sda --size=300 --label=boot
part pv.252 --fstype="lvmpv" --ondisk=sda --size=1 --grow
volgroup vgcentos --pesize=4096 pv.252
logvol swap  --fstype="swap" --size=2048 --name=swap --vgname=vgcentos
logvol /  --fstype="xfs" --size=1 --grow --label="root" --name=root --vgname=vgcentos

%packages
@^minimal
@core
chrony
curl
wget

%end

%addon com_redhat_kdump --disable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

%post
# 这里是后置安装脚本，可以删除
mkdir -p /root/pxe/
touch /root/pxe/post-pxe.log
echo $(date "+%Y-%m-%d %H:%M:%S") "Start PXE Install" >> /root/pxe/post-pxe.log
wget -O /root/pxe/pxe.sh ftp://10.10.10.12/pub/sh/centos7-pxe-post.sh
echo $(date "+%Y-%m-%d %H:%M:%S") "Finish Download post install script" >> /root/pxe/post-pxe.log
cd /root/pxe/ && chmod +x pxe.sh && bash /root/pxe/pxe.sh
echo $(date "+%Y-%m-%d %H:%M:%S") "Finish PXE Install" >> /root/pxe/post-pxe.log

%end
```

### 基于 UEFI 系统引导的配置

```
#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512
# Use Network installation media
install
# Use text install
text
# Use network installation
# https://mirrors.aliyun.com/centos/7.9.2009/os/x86_64
url --url="ftp://10.10.10.12/pub/centos7"
# Run the Setup Agent on first boot
firstboot --enable
ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8 --addsupport=zh_CN.UTF-8

# Network information
network  --bootproto=dhcp --device=ens192 --ipv6=auto --activate
network  --hostname=localhost.localdomain

# Reboot after installation
reboot

# Root password
rootpw --iscrypted $6$u3UoiYRUzFQgTo4s$3.7qwrZmCtU.H78nOpXcrM4XgZHRfmHrwDLKPcsGR6NYO56L1TDWtZpf3vcAqBXbCb7xzjZ4.83nHszDF.AKG1
user --name=luck --password=$6$9n5odwW3DclrxlMJ$y06mLRL5qhYUiUx6bzAmd49O5dsLv38xBkbhXytBsByCnzi1dP9O.KqvOBZUxep8G5DA0VaIBOSfQi.S7vSbE1 --iscrypted --gecos="luck"

# System services
services --enabled="chronyd"
# SELinux configuration
selinux --disabled
# Firewall configuration
firewall --disabled
# Do not configure the X Window System
skipx
# System timezone (ntp.aliyun.com)
timezone Asia/Shanghai --isUtc --ntpservers=ntp.aliyun.com

# System bootloader configuration
bootloader --boot-drive=sda
# Clear the Master Boot Record
zerombr
# Partition clearing information
# --none (default) - Do not remove any partitions.
clearpart --all --initlabel --drives=sda

# Disk partitioning information
part /boot --fstype="xfs" --ondisk=sda --size=300 --label=boot
part /boot/efi --fstype="efi" --ondisk=sda --size=300 --fsoptions="umask=0077,shortname=winnt"
part pv.252 --fstype="lvmpv" --ondisk=sda --size=1 --grow
volgroup vgcentos --pesize=4096 pv.252
logvol swap  --fstype="swap" --size=2048 --name=swap --vgname=vgcentos
logvol /  --fstype="xfs" --size=1 --grow --label="root" --name=root --vgname=vgcentos

%packages
@^minimal
@core
chrony
curl
wget

%end

%addon com_redhat_kdump --disable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

%post
# 这里是后置安装脚本，可以删除
mkdir -p /root/pxe/
touch /root/pxe/post-pxe.log
echo $(date "+%Y-%m-%d %H:%M:%S") "Start PXE Install" >> /root/pxe/post-pxe.log
wget -O /root/pxe/pxe.sh ftp://10.10.10.12/pub/sh/centos7-pxe-post.sh
echo $(date "+%Y-%m-%d %H:%M:%S") "Finish Download post install script" >> /root/pxe/post-pxe.log
cd /root/pxe/ && chmod +x pxe.sh && bash /root/pxe/pxe.sh
echo $(date "+%Y-%m-%d %H:%M:%S") "Finish PXE Install" >> /root/pxe/post-pxe.log

%end
```

### 后置安装脚本，简单服务器优化

#### centos7-pxe-post.sh

```bash
#!/bin/bash

PXE_SERVER=10.10.10.12
PXE_DIR=/root/pxe/

mkdir -p ${PXE_DIR} && cd ${PXE_DIR}
wget -O network-pxe-post.sh ftp://${PXE_SERVER}/pub/sh/centos7-network-pxe-post.sh
wget -O network-pxe-containerd-post.sh ftp://${PXE_SERVER}/pub/sh/centos7-network-pxe-containerd-post.sh

bash network-pxe-post.sh
bash network-pxe-containerd-post.sh

```

#### centos7-network-pxe-post.sh

```bash
#!/bin/bash

PXE_SERVER=10.10.10.12
LOG_PATH=/root/pxe/network-post-pxe.log

# update environment
# shutdown firewalld and configure selinux
echo $(date "+%Y-%m-%d %H:%M:%S") "shutdown firewalld and configure selinux" >> ${LOG_PATH}

systemctl stop firewalld.service && systemctl disable firewalld.service
sed -ri '/^SELINUX=/s/^(.*)$/SELINUX=disabled/' /etc/selinux/config

echo $(date "+%Y-%m-%d %H:%M:%S") "update system kernel params" >> ${LOG_PATH}
cp -n /etc/sysctl.conf /etc/sysctl.conf.backup
cat /etc/sysctl.conf.backup > /etc/sysctl.conf
echo "user.max_user_namespaces=15000" >> /etc/sysctl.conf

# 更新内核网络参数
cat <<EOF | tee /etc/modules-load.d/optimize.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

# linux 内核配置参数
cat <<EOF > /etc/sysctl.d/optimize.conf
vm.overcommit_memory = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl -p /etc/sysctl.d/optimize.conf

# 修改 swap 虚拟内存的使用规则，设置为10 说明当内存使用量超过 90% 才会使用 swap 空间
echo "10" > /proc/sys/vm/swappiness

# 设置系统打开文件最大数
cp -n /etc/security/limits.conf /etc/security/limits.conf.backup
cat /etc/security/limits.conf.backup > /etc/security/limits.conf
cat >> /etc/security/limits.conf <<EOF
    * soft nofile 65535
    * hard nofile 65535
EOF

# 2. config repository
echo $(date "+%Y-%m-%d %H:%M:%S") "yum repository config" >> ${LOG_PATH}
cp -n /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
# curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.cloud.tencent.com/repo/epel-7.repo

# upgrade system
echo $(date "+%Y-%m-%d %H:%M:%S") "upgrade system" >> ${LOG_PATH}
yum clean all && yum makecache faste && yum upgrade -y

# 3. Install basic packags
echo $(date "+%Y-%m-%d %H:%M:%S") "Install basic packags" >> ${LOG_PATH}
yum install -y vim tree yum-utils iptables iptables-services iptables-utils firewalld net-tools
yum install -y epel-release && yum install -y htop
yum install -y openssh-server openssh-clients
# package ipset 网络工具
yum install -y ipset ipvsadm

sed -ri -e '/^#PermitRootLogin/s/#//' -e '/PermitRootLogin/s/no/yes/' /etc/ssh/sshd_config
sed -ri -e '/^#PubkeyAuthentication/s/#//' -e '/PubkeyAuthentication/s/no/yes/' /etc/ssh/sshd_config

systemctl stop postfix && systemctl disable postfix
iptables -F && iptables -X && iptables -Z

# 4. Vim config
echo $(date "+%Y-%m-%d %H:%M:%S") "vim config" >> ${LOG_PATH}

cp -n /etc/vimrc /etc/vimrc.backup
cat /etc/vimrc.backup > /etc/vimrc
cat <<EOF >> /etc/vimrc
syntax on
set tabstop=4
set autoindent
EOF

# 5. ssh config
echo $(date "+%Y-%m-%d %H:%M:%S") "ssh config" >> ${LOG_PATH}
mkdir -p /root/.ssh && chmod 700 /root/.ssh
wget -O /root/.ssh/authorized_keys ftp://${PXE_SERVER}/pub/sh/id_rsa.pub
chmod 600 /root/.ssh/authorized_keys

# 6. config timezone
echo $(date "+%Y-%m-%d %H:%M:%S") "config timezone" >> ${LOG_PATH}
timedatectl set-timezone Asia/Shanghai

# 7. Install laste kernel
# https://elrepo.org/linux/kernel/el7/x86_64/RPMS/
# https://mirrors.coreix.net/elrepo-archive-archive/kernel/el7/x86_64/RPMS/
# https://mirrors.coreix.net/elrepo-archive-archive/x86_64/
echo $(date "+%Y-%m-%d %H:%M:%S") "Install laste kernel" >> ${LOG_PATH}
KERNEL_DIR=/root/pxe/kernel/
mkdir -p ${KERNEL_DIR}
wget -P ${KERNEL_DIR} ftp://${PXE_SERVER}/pub/kernel/kernel-lt-5.4.278-1.el7.elrepo.x86_64.rpm
wget -P ${KERNEL_DIR} ftp://${PXE_SERVER}/pub/kernel/kernel-lt-devel-5.4.278-1.el7.elrepo.x86_64.rpm
yum install -y ${KERNEL_DIR}*.rpm
rm -rf ${KERNEL_DIR}

awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg >> ${LOG_PATH}

grub2-set-default 0 && grub2-mkconfig -o /etc/grub2.cfg
grubby --args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"

echo $(date "+%Y-%m-%d %H:%M:%S") "Finish PXE Install" >> ${LOG_PATH}

```

#### centos7-network-pxe-containerd-post.sh

[containerd 命令行接口交互项目](https://github.com/containerd/containerd/blob/main/docs/getting-started.md#interacting-with-containerd-via-cli)

- [nerdctl 安装包](https://github.com/containerd/nerdctl/tags)
- [cni-plugins 发布包](https://github.com/containernetworking/plugins/releases)
- [buildkit 镜像构建工具](https://github.com/moby/buildkit/releases)
- [crictl / critest工具](https://github.com/kubernetes-sigs/cri-tools/releases)

```bash
#!/bin/bash

PXE_FTP_HOST=10.10.10.12
PXE_CONTAINERD_DIR=/root/pxe/containerd/

rm -rf ${PXE_CONTAINERD_DIR}
mkdir -p ${PXE_CONTAINERD_DIR}
cd ${PXE_CONTAINERD_DIR}
wget ftp://${PXE_FTP_HOST}/pub/containerd/nerdctl-1.7.6-linux-amd64.tar.gz
wget ftp://${PXE_FTP_HOST}/pub/containerd/buildkit-v0.15.1.linux-amd64.tar.gz
wget ftp://${PXE_FTP_HOST}/pub/containerd/cni-plugins-linux-amd64-v1.5.1.tgz
wget ftp://${PXE_FTP_HOST}/pub/containerd/crictl-v1.30.0-linux-amd64.tar.gz
wget ftp://${PXE_FTP_HOST}/pub/containerd/critest-v1.30.0-linux-amd64.tar.gz

# 基本安装
# https://docs.docker.com/engine/install/centos/
# 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 安装指定版本
# yum list docker-ce.x86_64 --showduplicates | sort -r
yum install -y yum-utils device-mapper-persistent-data lvm2
yum install -y containerd.io

# =========================================
# containerd
# package ipset 网络工具
yum install -y ipset ipvsadm

# 更新内核网络参数
cat <<EOF | tee /etc/modules-load.d/optimize.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

# linux 内核配置参数
cat <<EOF > /etc/sysctl.d/optimize.conf
vm.overcommit_memory = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl -p /etc/sysctl.d/optimize.conf

# containerd 配置
containerd config default > /etc/containerd/config.toml

# 镜像加速
sed -i '/config_path/s/""/"\/etc\/containerd\/certs.d"/' /etc/containerd/config.toml
mkdir -p /etc/containerd/certs.d
mkdir -p /etc/containerd/certs.d/docker.io
cat <<EOF > /etc/containerd/certs.d/docker.io/hosts.toml
server = "https://docker.io"
[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]
[host."https://docker.nju.edu.cn"]
  capabilities = ["pull", "resolve"]
[host."https://docker.mirrors.sjtug.sjtu.edu.cn"]
  capabilities = ["pull", "resolve"]
EOF

# 使用 systemd 驱动
sed -i '/SystemdCgroup/s/false/true/' /etc/containerd/config.toml
#sed -i '/sandbox_image/s/registry.k8s.io\/pause:[0-9].[0-9]/registry.aliyuncs.com\/google_containers\/pause:3.9/' /etc/containerd/config.toml
# sed -i '/sandbox_image/s/".*"/"registry.aliyuncs.com\/google_containers\/pause:3.9"/' /etc/containerd/config.toml

# containerd 重新加载
systemctl daemon-reload && systemctl restart containerd
# 开机自启
systemctl enable containerd

# 配置 kubelet 使用 systemd 驱动
echo 'KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"' > /etc/sysconfig/kubelet

# ===========================================================
# nerdctl 工具
# https://github.com/containerd/containerd/blob/main/docs/getting-started.md#interacting-with-containerd-via-cli
# https://github.com/containerd/nerdctl/tags

mkdir nerdctl
tar -zxf $(ls nerdctl*.tar.gz) -C nerdctl
mv -f nerdctl/nerdctl /usr/local/bin/
rm -rf nerdctl

# test
# nerdctl run hello-world

# Container Network Interface
# https://github.com/containernetworking/plugins/releases

mkdir -p /opt/cni/bin/
tar -zxf $(ls cni-plugins-linux-*.tgz) -C /opt/cni/bin/

# ===========================================================
# buildkit 构建工具
# https://github.com/moby/buildkit/releases
mkdir buildkit
tar -zxf $(ls buildkit-*.tar.gz) -C buildkit
cp -n buildkit/bin/buildkit-cni-* /usr/local/bin/
cp -n buildkit/bin/buildctl buildkit/bin/buildkitd buildkit/bin/buildkit-runc /usr/local/bin/
rm -rf buildkit

cat <<EOF > /usr/lib/systemd/system/buildkitd.service
[Unit]
Description=BuildKit
After=network.target local-fs.target
Documentation=https://github.com/moby/buildkit

[Service]
#uncomment to enable the experimental sbservice (sandboxed) version of containerd/cri integration
#Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/buildkitd --oci-worker=true --containerd-worker=true

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start buildkitd
systemctl enable buildkitd

# ===========================================================
# crictl
# https://github.com/kubernetes-sigs/cri-tools/releases
tar -zxf $(ls crictl-*.tar.gz) -C /usr/local/bin/
tar -zxf $(ls critest-*.tar.gz) -C /usr/local/bin/

cat <<EOF > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
pull-image-on-create: false
EOF

```

