---
title: "Debian网络PXE批量安装"
subtitle: "Debian PXE 批量安装"
description: "Debian PXE 网络批量安装所需服务安装和配置"
date: 2026-03-09T13:00:00+08:00
lastmod: 2026-03-09T13:00:00+08:00
draft: false

authors: ["yzx"]
tags: ["Linux", "Debian"]
categories: ["Linux"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2630.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# Debian PXE 网络批量安装

## 所需服务安装和配置

### 配置固定 IP 地址

传统配置：/etc/network/interfaces

```bash
# The loopback network interface
auto lo
iface lo inet loopback

#allow-hotplug ens32
#iface ens32 inet dhcp

# The primary network interface
auto ens32
iface ens32 inet static
    address 192.168.99.30
    netmask 255.255.255.0
    gateway 192.168.99.1
    dns-nameservers 223.5.5.5 114.114.114.114
```

若是 DNS 配置 `/etc/resolv.conf` 未生效，需要手动配置或安装 `resolvconf` 包：
手动配置 `/etc/resolv.conf`

```bash
domain localdomain
nameserver 192.168.99.2
```

在 Debian 系统中，`/etc/network/interfaces` 里的 `dns-*` 配置项，默认是由 resolvconf 这个服务负责翻译并写入 `/etc/resolv.conf` 的。
安装 `resolvconf` 包

```bash
apt-get install -y resolvconf
# 启用 resolvconf 服务并开机自启
systemctl enable --now resolvconf
# 重启 resolvconf 服务
systemctl restart resolvconf
```

重启网络服务

```bash
systemctl restart networking
```

### DHCP 服务安装和配置

#### 安装 DHCP 服务

安装 DHCP 服务 `isc-dhcp-server` 包

```bash
apt-get install -y isc-dhcp-server

systemctl enable --now isc-dhcp-server
```

启动报错指定网卡名称

```bash
# 编辑 /etc/default/isc-dhcp-server 文件，指定网卡名称
INTERFACESv4="ens32"
INTERFACESv6=""
```

查看 DHCP 启动日志

```bash
# 查看 isc-dhcp-server 服务的所有日志
sudo journalctl -u isc-dhcp-server
# 实时滚动查看最新日志（类似 tail -f）
sudo journalctl -u isc-dhcp-server -f
# 查看最后 50 行日志
sudo journalctl -u isc-dhcp-server -n 50
# 配置文件语法检查
dhcpd -t
```

#### 配置 DHCP PXE 服务

编辑 DHCP 配置文件 `/etc/dhcp/dhcpd.conf`

```bash
log-facility local7;

option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;

subnet 192.168.99.0 netmask 255.255.255.0 {
    range 192.168.99.100 192.168.99.200;
    option subnet-mask 255.255.255.0;
    option routers 192.168.99.2;
    option domain-name-servers 223.5.5.5;

    # TFTP 服务器地址
    next-server 192.168.99.30;
    # 根据架构类型分发启动文件
    if option architecture-type = 00:07 {
        # EFI x86-64
        filename "efi/bootx64.efi";
    } elsif option architecture-type = 00:09 {
        # EFI x86-64 (备用标识)
        filename "efi/bootx64.efi";
    } else {
        # Legacy BIOS
        filename "bios/pxelinux.0";
    }
    # TFTP服务器IP
    #next-server 192.168.99.30;
    # PXE启动文件
    #filename "pxelinux.0";
}
```

重启 DHCP 服务

```bash
systemctl restart isc-dhcp-server
```

### Nginx 安装和配置

#### 安装 Nginx 服务

```bash
apt-get install -y nginx squashfs-tools
```

#### Nginx 配置

```
mkdir -p /srv/www/{preseed,debian12,debian13}
```

[debian12.13.0 网络安装 ISO 下载链接](https://cdimage.debian.org/cdimage/archive/12.13.0/amd64/iso-cd/debian-12.13.0-amd64-netinst.iso)

[debian13.2.0 网络安装 ISO 下载链接](https://cdimage.debian.org/cdimage/archive/13.2.0/amd64/iso-cd/debian-13.2.0-amd64-netinst.iso)

```bash
cat > /etc/nginx/conf.d/debian-pxe.conf << EOF
server {
    listen 8080 default_server;
    listen [::]:8080 default_server;
    
    server_name _;
    
    # Preseed配置文件
    location /preseed {
        alias /srv/www/preseed;
        autoindex on;
    }
    
    # Debian 12 (bookworm)
    location /debian12/ {
        alias /srv/www/debian12/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
	# === dists 和 pool 路径（解决安装程序的路径请求） ===
    # dists/stable -> bookworm/dists
    location /debian12/dists/stable/ {
        alias /srv/www/debian12/dists/bookworm/;
        autoindex on;
    }
    
    # Debian 13 (trixie)
    location /debian13/ {
        alias /srv/www/debian13/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
    location /debian13/dists/stable/ {
        alias /srv/www/debian13/dists/bookworm/;
        autoindex on;
    }
    
    # 健康检查
    location /health {
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
EOF
```

### TFTP 服务安装和配置

#### 安装 TFTP 服务

安装 TFTP 服务 `tftpd-hpa` 包

```bash
apt-get install -y tftpd-hpa
systemctl enable tftpd-hpa
systemctl start tftpd-hpa
```

#### 配置 TFTP 服务

编辑 TFTP 配置文件 `/etc/default/tftpd-hpa`

```bash
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
```

#### 配置 TFTP 目录结构和引导文件

TFTP 目录结构

```
/srv/tftp/
├── efi/
│   ├── bootx64.efi           # UEFI启动文件
│   ├── grubx64.efi           # GRUB EFI
│   ├── grub.cfg              # GRUB配置
│   └── grub/                 # GRUB模块
│       ├── efi_gop.mod
│       ├── efi_uga.mod
│       └── ...
├── bios/
│   ├── pxelinux.0            # Legacy BIOS启动文件
│   ├── lpxelinux.0           # 支持HTTP的版本
│   ├── menu.c32
│   ├── ldlinux.c32
│   ├── libutil.c32
│   └── pxelinux.cfg/
│       └── default           # Legacy BIOS菜单
├── debian/
│   ├── vmlinuz               # 内核
│   ├── initrd.gz             # 初始化镜像
│   └── ...
└── preseed.cfg
```

创建 TFTP 目录结构

```bash
mkdir -p /srv/tftp/{bios,efi,debian}
chown -R tftp:tftp /srv/tftp
```

下载 debian 网络 PXE 安装内核

```bash
cd /srv/tftp/debian
wget http://mirrors.ustc.edu.cn/debian/dists/stable/main/installer-amd64/current/images/netboot/netboot.tar.gz
tar -xzf netboot.tar.gz

# debian 12 - bookworm
wget https://mirrors.ustc.edu.cn/debian/dists/bookworm/main/installer-amd64/current/images/netboot/netboot.tar.gz

# debian 13 - trixie
wget https://mirrors.ustc.edu.cn/debian/dists/trixie/main/installer-amd64/current/images/netboot/netboot.tar.gz
```

##### BIOS 模式

bios 目录下放置 Legacy BIOS 启动文件

```bash
cp /srv/tftp/debian/{pxelinux.0,ldlinux.c32,splash.png} /srv/tftp/bios/
cp /srv/tftp/debian/debian-installer/amd64/boot-screens/{vesamenu.c32,libcom32.c32,libutil.c32} /srv/tftp/bios/

mkdir -p /srv/tftp/bios/debian13
# default -> debian12
cp /srv/tftp/debian/debian-installer/amd64/{linux,initrd.gz} /srv/tftp/bios/

mkdir -p /srv/tftp/bios/pxelinux.cfg
touch /srv/tftp/bios/pxelinux.cfg/default
```

`bios/pxelinux.cfg/default` 文件内容

```bash
# /srv/tftp/bios/pxelinux.cfg/default
PROMPT 0
TIMEOUT 50
default vesamenu.c32

MENU TITLE PXE Boot Menu
MENU BACKGROUND splash.png

LABEL debian12
    MENU default
    MENU LABEL ^Automated Debian 12 Install
    KERNEL linux
    APPEND initrd=initrd.gz url=http://192.168.99.30/preseed/preseed-debian12-bios.cfg interface=auto auto=true priority=critical DEBCONF_DEBUG=5
LABEL debian13
    MENU LABEL ^Automated Debian 13 Install
    KERNEL linux
    APPEND initrd=initrd.gz url=http://192.168.99.30/preseed/preseed-debian13-bios.cfg interface=auto auto=true priority=critical DEBCONF_DEBUG=5
LABEL local
    menu label ^Boot from Local Disk
    localboot 0
    timeout 50
```

##### EFI 模式



## Debian preseed 文件配置

### BIOS 模式 preseed 文件

#### Debian 12

`/srv/www/preseed/preseed-debian12-bios.cfg` 配置文件编辑

```
# vim /srv/www/preseed/preseed-debian12-bios.cfg
# 设置非交互模式和关键优先级
d-i debconf debconf/priority select critical
d-i debconf debconf/frontend select noninteractive

# ==================== 禁用CD-ROM检测 ====================
d-i cdrom-detect/cdrom_mounted boolean true
d-i cdrom-detect/try-hd boolean true
d-i cdrom-detect/hd-mount boolean true
d-i apt-setup/cdrom/set-first boolean false
d-i apt-setup/cdrom/set-double boolean false
d-i apt-setup/cdrom/set-failed boolean false

# ==================== 本地化设置 ====================
d-i debian-installer/language string en
d-i debian-installer/country string CN
d-i debian-installer/locale string en_US.UTF-8
d-i localechooser/supported-locales multiselect en_US.UTF-8, zh_CN.UTF-8

# 键盘布局
d-i keyboard-configuration/xkb-keymap select us
d-i keyboard-configuration/variant select us

# ==================== 网络设置 ====================
d-i netcfg/choose_interface select auto
d-i netcfg/dhcp_timeout string 60
d-i netcfg/get_hostname string debian
d-i netcfg/get_domain string localdomain
d-i netcfg/wireless_show_essids select manual

# ==================== 镜像源设置 ====================
d-i mirror/protocol string http
d-i mirror/country string manual
d-i mirror/http/hostname string 10.10.10.30:8080
d-i mirror/http/directory string /debian12/
d-i mirror/http/proxy string
# -> http://10.10.10.30:8080/debian12/dists/stable/Release

# 跳过镜像选择对话框
d-i mirror/skip-question boolean true
# 强制使用手动配置的镜像
d-i mirror/choose_manual_mirror boolean true
d-i mirror/http/mirror string http://10.10.10.30:8080/debian12/

# === 跳过镜像相关所有问题 ===
d-i apt-setup/use_mirror boolean true
d-i apt-setup/enable-source-repositories boolean false
d-i apt-setup/non-free boolean false
d-i apt-setup/contrib boolean false

#d-i mirror/country string manual
#d-i mirror/http/hostname string deb.debian.org
#d-i mirror/http/hostname string mirrors.ustc.edu.cn
#d-i mirror/http/directory string /debian/
#d-i mirror/http/proxy string

# 指定 Debian 版本为 13 (trixie) / 12 (bookworm)
d-i mirror/suite string bookworm
#d-i mirror/suite string trixie

# ==================== 时区和时钟 ====================
d-i clock-setup/utc boolean true
d-i time/zone string Asia/Shanghai
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string ntp.aliyun.com

# 分区
d-i partman-auto/method string lvm
# 选择要分区的磁盘
d-i partman-auto/disk string /dev/sda
# 使用整个磁盘
d-i partman-auto-lvm/guided_size string max
# 使用 XFS 文件系统（默认）
d-i partman/default_filesystem string xfs
# 使用 MSDOS 分区表格式（MBR）
d-i partman-partitioning/choose_label string msdos

# 自定义服务器分区
# 分区方案名称 :: \
#     最小大小 优先大小 最大大小 文件系统类型 \
#         标志{ } \
#         方法{ 方法 } 格式化{ } \
#         使用文件系统{ } 文件系统{ 文件系统类型 } \
#         挂载点{ 挂载点 } \
#     . \
# 自定义分区方案：boot 500MB, swap 2GB, / 剩余全部
d-i partman-auto/expert_recipe string \
    lvm :: \
        500 500 500 ext4 \
            $primary{ } $bootable{ } \
            method{ format } format{ } \
            use_filesystem{ } filesystem{ ext4 } \
            mountpoint{ /boot } \
        . \
        2048 2048 2048 linux-swap \
            $lvmok{ } \
            method{ swap } format{ } \
        . \
        100% 100% 100% xfs \
            $lvmok{ } \
            method{ format } format{ } \
            use_filesystem{ } filesystem{ xfs } \
            mountpoint{ / } \
        .

# 删除现有分区和 LVM
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-lvm/confirm boolean true

# 清空磁盘分区表
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true

# ==================== 用户账户 ====================
# Root用户
d-i passwd/root-login boolean true
d-i passwd/root-password password luck
d-i passwd/root-password-again password luck

# 普通用户（可选）
d-i passwd/user-fullname string luck
d-i passwd/username string luck
d-i passwd/user-password password luck
d-i passwd/user-password-again password luck
d-i passwd/user-uid string 1000

# ==================== 软件包安装 ====================
# 禁用流行度调查
popularity-contest popularity-contest/participate boolean false
d-i apt-setup/services-select multiselect security, updates
d-i apt-setup/security_host string security.debian.org

# 软件包选择
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string openssh-server vim curl wget sudo net-tools
d-i pkgsel/upgrade select full-upgrade
d-i pkgsel/update-policy select none
d-i pkgsel/updatedb boolean true

# ==================== GRUB引导器 ====================
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string /dev/sda

# ==================== 完成安装 ====================
d-i finish-install/reboot_in_progress note
d-i cdrom-detect/eject boolean true

# === 跳过所有交互 ===
# 不显示任何问题
d-i debian-installer/quiet boolean true
d-i debian-installer/splash boolean false
# 关闭所有弹窗和交互
d-i mirror/suite string stable
```

### Debian 12 EFI 模式 preseed 文件

```
# === 分区配置（EFI + GPT + LVM + XFS） ===
# 使用 GPT 分区表（EFI 必需）
d-i partman-partitioning/choose_label select gpt
d-i partman-partitioning/default_label select gpt

# 自动分区
d-i partman-auto/method string lvm
d-i partman-auto/disk string /dev/sda

# 自定义分区方案：EFI ESP + LVM
d-i partman-auto/expert_recipe string \
    efi-lvm :: \
        # EFI 系统分区（ESP）- 300MB
        300 300 300 vfat \
            $primary{ } $bootable{ } \
            method{ format } format{ } \
            use_filesystem{ } filesystem{ vfat } \
            mountpoint{ /boot/efi } \
            options{ fat=32 } \
            label{ efi } \
        . \
        # /boot 分区 - 500MB（物理分区，不在 LVM 中）
        500 500 500 ext4 \
            $primary{ } \
            method{ format } format{ } \
            use_filesystem{ } filesystem{ ext4 } \
            mountpoint{ /boot } \
            label{ boot } \
        . \
        # Swap 分区 - 2GB（LVM 逻辑卷）
        2048 2048 2048 linux-swap \
            $lvmok{ } \
            in_vg{ debian-vg } \
            lv_name{ swap } \
            method{ swap } format{ } \
        . \
        # 根分区 - 剩余全部（LVM 逻辑卷）
        100% 100% 100% xfs \
            $lvmok{ } \
            in_vg{ debian-vg } \
            lv_name{ root } \
            method{ format } format{ } \
            use_filesystem{ } filesystem{ xfs } \
            mountpoint{ / } \
            label{ root } \
        .

# 分区管理
d-i partman-auto-lvm/guided_size string max
d-i partman-lvm/confirm boolean true
d-i partman-lvm/device_remove_lvm boolean true
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# === 引导加载器配置（EFI GRUB） ===
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string /dev/sda
d-i grub-installer/force-efi-extra-removable boolean true
d-i grub-installer/efi-installation-entries boolean true
```
