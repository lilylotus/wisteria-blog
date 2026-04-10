---
title: "Debian网络PXE批量安装"
subtitle: "Debian PXE 批量安装"
description: "Debian PXE 网络批量安装所需服务安装和配置"
date: 2026-03-09T13:00:00+08:00
lastmod: 2026-03-18T23:00:00+08:00
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
journalctl -u isc-dhcp-server
# 实时滚动查看最新日志（类似 tail -f）
journalctl -u isc-dhcp-server -f
# 查看最后 50 行日志
journalctl -u isc-dhcp-server -n 50
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
        filename "debian-installer/amd64/bootnetx64.efi";
    } elsif option architecture-type = 00:09 {
        # EFI x86-64 (备用标识)
        filename "debian-installer/amd64/bootnetx64.efi";
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

    # Debian 13 (trixie)
    location /debian13/ {
        alias /srv/www/debian13/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
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
systemctl restart tftpd-hpa

journalctl -u tftpd-hpa -f
```

#### 配置 TFTP 服务

编辑 TFTP 配置文件 `/etc/default/tftpd-hpa`

```bash
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure -l"
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
│   ├── vesamenu.c32
│   ├── ldlinux.c32
│   ├── libutil.c32
│   ├── vmlinuz               # 内核
│   ├── initrd.gz             # 初始化镜像
│   └── pxelinux.cfg/
│       └── default           # Legacy BIOS菜单
├── debian/
│   ├── ...                   # netboot.iso
│   ├── initrd.gz             # 初始化镜像
```

创建 TFTP 目录结构

```bash
mkdir -p /srv/tftp/{bios,efi,debian}
chown -R tftp:tftp /srv/tftp
```

启动加载器关系

```
BIOS PXE   → pxelinux.0
UEFI PXE   → bootnetx64.efi
SecureBoot → shimx64.efi
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
# pxelinux.0 → ldlinux.c32 → pxelinux.cfg → kernel
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

```bash
cp -a /srv/tftp/debian/debian-installer/ /srv/tftp/
```

`grub.cfg`  GRUB 配置文件

```bash
# vim /srv/tftp/debian-installer/amd64/grub/grub.cfg
set default=0
set timeout=5

menuentry "Automated Debian 12 Install" {
  linux /debian-installer/amd64/linux auto=true priority=critical url=http://10.10.10.30:8080/preseed/preseed-debian12-efi.cfg
  initrd /debian-installer/amd64/initrd.gz
}

menuentry "Automated Debian 13 Install" {
  linux /debian-installer/amd64/linux auto=true priority=critical url=http://10.10.10.30:8080/preseed/preseed-debian13-efi.cfg
  initrd /debian-installer/amd64/initrd.gz
}

menuentry "Boot from local hard disk (default EFI)" {
    exit
}
```

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
#d-i mirror/protocol string http
#d-i mirror/country string manual
#d-i mirror/http/hostname string 10.10.10.30:8080
#d-i mirror/http/directory string /debian12/
#d-i mirror/http/proxy string
# -> http://10.10.10.30:8080/debian12/dists/stable/Release

# 跳过镜像选择对话框
d-i mirror/skip-question boolean true

d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
#d-i mirror/http/hostname string mirrors.ustc.edu.cn
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

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
```

#### Debian 13

`/srv/www/preseed/preseed-debian13-bios.cfg` 配置文件编辑

```
# vim /srv/www/preseed/preseed-debian13-bios.cfg
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
#d-i mirror/protocol string http
#d-i mirror/country string manual
#d-i mirror/http/hostname string 10.10.10.30:8080
#d-i mirror/http/directory string /debian12/
#d-i mirror/http/proxy string
# -> http://10.10.10.30:8080/debian12/dists/stable/Release

# 跳过镜像选择对话框
d-i mirror/skip-question boolean true

d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
#d-i mirror/http/hostname string mirrors.ustc.edu.cn
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

# 指定 Debian 版本为 13 (trixie) / 12 (bookworm)
#d-i mirror/suite string bookworm
d-i mirror/suite string trixie

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
```

### EFI 模式 preseed 文件

#### Debian 12

```
# vim /srv/www/preseed/preseed-debian12-efi.cfg
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
#d-i mirror/protocol string http
#d-i mirror/country string manual
#d-i mirror/http/hostname string 10.10.10.30:8080
#d-i mirror/http/directory string /debian12/
#d-i mirror/http/proxy string
# -> http://10.10.10.30:8080/debian12/dists/stable/Release

# 跳过镜像选择对话框
d-i mirror/skip-question boolean true

d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
#d-i mirror/http/hostname string mirrors.ustc.edu.cn
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

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
# msdos - 使用 MSDOS 分区表格式（MBR）
# gpt - GUID Partition Table（现代分区表，支持 EFI/UEFI 和大于 2TB 磁盘）
d-i partman-partitioning/choose_label string gpt

# 自定义服务器分区
# 分区方案名称 :: \
#     最小大小 优先大小 最大大小 文件系统类型 \
#         标志{ } \
#         方法{ 方法 } 格式化{ } \
#         使用文件系统{ } 文件系统{ 文件系统类型 } \
#         挂载点{ 挂载点 } \
#     . \
# $lvmok{ } 不是文件系统类型，也不是大小，它只是告诉 installer：“这个分区可以加入卷组 (VG) 并创建逻辑卷 (LV)”。
# 自定义分区方案：boot 500MB, swap 2GB, / 剩余全部
d-i partman-auto/expert_recipe string \
    lvm :: \
       512 512 512 fat32 \
            $primary{ } $bootable{ } \
            method{ efi } format{ } \
            mountpoint{ /boot/efi } label{ efi } \
        . \
        512 512 512 ext4 \
            $primary{ } \
            method{ format } format{ } \
            use_filesystem{ } filesystem{ ext4 } \
            mountpoint{ /boot } \
        . \
        2048 2048 2048 linux-swap \
            method{ swap } format{ } \
        . \
        100% 100% -1 xfs \
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
d-i partman/confirm_write_new_label boolean true
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
```

#### Debian 13

```
# vim /srv/www/preseed/preseed-debian13-efi.cfg
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
#d-i mirror/protocol string http
#d-i mirror/country string manual
#d-i mirror/http/hostname string 10.10.10.30:8080
#d-i mirror/http/directory string /debian12/
#d-i mirror/http/proxy string
# -> http://10.10.10.30:8080/debian12/dists/stable/Release

# 跳过镜像选择对话框
d-i mirror/skip-question boolean true

d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
#d-i mirror/http/hostname string mirrors.ustc.edu.cn
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

# 指定 Debian 版本为 13 (trixie) / 12 (bookworm)
#d-i mirror/suite string bookworm
d-i mirror/suite string trixie

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
# msdos - 使用 MSDOS 分区表格式（MBR）
# gpt - GUID Partition Table（现代分区表，支持 EFI/UEFI 和大于 2TB 磁盘）
d-i partman-partitioning/choose_label string gpt

# 自定义服务器分区
# 分区方案名称 :: \
#     最小大小 优先大小 最大大小 文件系统类型 \
#         标志{ } \
#         方法{ 方法 } 格式化{ } \
#         使用文件系统{ } 文件系统{ 文件系统类型 } \
#         挂载点{ 挂载点 } \
#     . \
# $lvmok{ } 不是文件系统类型，也不是大小，它只是告诉 installer：“这个分区可以加入卷组 (VG) 并创建逻辑卷 (LV)”。
# 自定义分区方案：boot 500MB, swap 2GB, / 剩余全部
d-i partman-auto/expert_recipe string \
    lvm :: \
       512 512 512 fat32 \
            $primary{ } $bootable{ } \
            method{ efi } format{ } \
            mountpoint{ /boot/efi } label{ efi } \
        . \
        512 512 512 ext4 \
            $primary{ } \
            method{ format } format{ } \
            use_filesystem{ } filesystem{ ext4 } \
            mountpoint{ /boot } \
        . \
        2048 2048 2048 linux-swap \
            method{ swap } format{ } \
        . \
        100% 100% -1 xfs \
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
d-i partman/confirm_write_new_label boolean true
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
```

### 安装完成系统优化

#### 安装完成后执行脚本

```
# 安装完成后执行的命令（包含服务器优化脚本自动执行）
d-i preseed/late_command string \
    in-target usermod -aG sudo luck; \
    in-target systemctl enable ssh; \
    in-target mkdir -p /root/scripts; \
    in-target curl -fsSL http://192.168.99.30:8080/preseed/optimize-server-pxe.sh -o /root/scripts/optimize-server-pxe.sh ; \
    in-target chmod +x /root/scripts/optimize-server-pxe.sh; \
    in-target bash /root/scripts/optimize-server-pxe.sh;
    
# /target 标识在安装的系统内部
#    echo "安装完成！" > /target/etc/motd; \  
#    echo "正在配置服务器优化脚本..." >> /target/etc/motd; \
```

#### 系统参数优化

`server-optimization.sh`

```bash
#!/bin/bash

# vim server-optimization.sh
LOG_FILE="/var/log/server-optimization.log"

# 内核参数优化
echo "1. 内核/etc/modules-load.d/server-optimization.conf参数优化" | tee -a "$LOG_FILE"

cat > /etc/modules-load.d/server-optimization.conf << 'EOF'
# Kubernetes 必需模块
br_netfilter
overlay

# 网络相关
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

# 立即加载模块
modprobe br_netfilter 2> /dev/null
modprobe overlay 2> /dev/null
modprobe ip_vs 2> /dev/null

echo "2. /etc/sysctl.d/server-optimization.conf参数优化" | tee -a "$LOG_FILE"
# Kubernetes 专用内核参数
cat > /etc/sysctl.d/server-optimization.conf << 'EOF'
# ============ Kubernetes 必需参数 ============
# 启用 iptables 对 bridge 的处理（Kubernetes 必需）
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
# 启用 IP 转发（Kubernetes 必需）
net.ipv4.ip_forward = 1
# 不限制用户命名空间
user.max_user_namespaces = 15000
EOF

sysctl -p /etc/sysctl.d/server-optimization.conf

echo "3. 禁用 Swap" | tee -a "$LOG_FILE"
# 禁用 Swap（Kubernetes 必需）
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

echo "4. /etc/security/limits.d/server-optimization.conf参数优化" | tee -a "$LOG_FILE"
cat > /etc/security/limits.d/server-optimization.conf << 'EOF'
# 所有用户的文件描述符限制
* soft nofile 1048576
* hard nofile 1048576

# 所有用户的进程数限制
* soft nproc 1048576
* hard nproc 1048576
EOF

echo "5. SSH优化" | tee -a "$LOG_FILE"
# 禁止 root 密码登录（允许密钥登录）
sed -i 's/^#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
# 限制登录尝试
sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
# 禁用空密码
sed -i 's/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
# 启用密钥认证
sed -i 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

echo "6. apt-get安装软件" | tee -a "$LOG_FILE"
apt-get update
apt-get install -y resolvconf tree

```

#### Docker安装

`docker-install.sh`

```bash
#!/bin/bash

# vim docker-install.sh
set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]"
cd ${SCRIPT_DIR}

# 颜色定义
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

old_packages=("docker" "docker-engine" "docker.io" "docker-doc" "docker-compose" "docker-compose-v2" "podman-docker" "containerd" "runc" )
# 检查是否有已安装的包
installed=false
for pkg in "${old_packages[@]}"; do
    if dpkg -l "$pkg" &>/dev/null; then
        installed=true
        break
    fi
done

if $installed; then
    log_info "检测到旧版本 Docker，正在卸载..."
    apt-get remove -y "${old_packages[@]}" 2>/dev/null || true
    apt-get autoremove -y
    log_info "旧版本卸载完成"
else
    log_info "未检测到旧版本 Docker"
fi

log_info "更新软件包索引..."
apt-get update -y

log_info "安装必要依赖..."
apt-get install -y apt-transport-https ca-certificates curl gnupg gnupg2 lsb-release
log_info "依赖包安装完成"

log_info "添加 Docker GPG Key"
log_info "使用阿里云镜像源..."

# 添加阿里云 Docker GPG key
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 添加阿里云 Docker 仓库
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
# 更新软件包索引
log_info "更新软件包索引..."
apt-get update -qq

# 查看可用版本
log_info "可用的 Docker 版本:"
apt-cache madison docker-ce | head -5

# 安装 Docker
DOCKER_VERSION=5:29.2.1-1~debian.13~trixie
if [[ -n "$DOCKER_VERSION" ]]; then
    log_info "安装指定版本: $DOCKER_VERSION"
    apt-get install -y docker-ce="$DOCKER_VERSION" docker-ce-cli="$DOCKER_VERSION" containerd.io docker-buildx-plugin docker-compose-plugin
else
    log_info "安装最新版本..."
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

log_info "Docker 安装完成"

log_info "配置 Docker"
    
# 创建配置目录
mkdir -p /etc/docker

cat > /etc/docker/daemon.json << EOF
{
    "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn", "https://docker.m.daocloud.io", "https://docker.1panel.live", "https://hub.rat.dev" ],
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {"max-size": "100m","max-file": "3"},
    "storage-driver": "overlay2"
}
EOF

# 重载 systemd
systemctl daemon-reload
systemctl restart docker

usermod -aG docker luck
```

#### containerd安装

[nerdctl 下载链接](https://github.com/containerd/nerdctl/releases) 、[buildkit 下载链接](https://github.com/moby/buildkit/releases)、[cni-plugins 下载链接](https://github.com/containernetworking/plugins/releases)、[cri-tools 下载链接](https://github.com/kubernetes-sigs/cri-tools/releases)

```bash
#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]"
cd ${SCRIPT_DIR}

wget -c https://github.com/containerd/nerdctl/releases/download/v2.2.1/nerdctl-2.2.1-linux-amd64.tar.gz
wget -c https://github.com/moby/buildkit/releases/download/v0.28.0/buildkit-v0.28.0.linux-amd64.tar.gz
wget -c https://github.com/containernetworking/plugins/releases/download/v1.9.1/cni-plugins-linux-amd64-v1.9.1.tgz
wget -c https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.35.0/crictl-v1.35.0-linux-amd64.tar.gz
wget -c https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.35.0/critest-v1.35.0-linux-amd64.tar.gz
```

```bash
#!/bin/bash
# containerd-install.sh
SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]"
cd ${SCRIPT_DIR}

DOWNLOAD_URL_PREFIX=http://192.168.99.30:8080/preseed

# containerd install
apt-get update -y 
apt-get install -y ca-certificates curl gnupg lsb-release

#mkdir -p /etc/apt/keyrings
#curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
#echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://mirrors.aliyun.com/docker-ce/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# apt-cache madison containerd
apt-get update -y
apt-get install -y containerd.io

apt-get install -y ipset ipvsadm

# containerd 配置
mkdir -p /etc/containerd/
containerd config default > /etc/containerd/config.toml
sed -i "/config_path/s/      config_path = ''/      config_path = '\/etc\/containerd\/certs.d'/" /etc/containerd/config.toml
sed -i '/SystemdCgroup/s/false/true/' /etc/containerd/config.toml
mkdir -p /etc/containerd/certs.d/docker.io

cat <<EOF > /etc/containerd/certs.d/docker.io/hosts.toml
server = "https://docker.io"
[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]
[host."https://docker.mirrors.ustc.edu.cn"]
  capabilities = ["pull", "resolve"]
[host."https://docker.mirrors.sjtug.sjtu.edu.cn"]
  capabilities = ["pull", "resolve"]
EOF

systemctl daemon-reload && systemctl restart containerd
systemctl enable containerd

wget -c ${DOWNLOAD_URL_PREFIX}/nerdctl-2.2.1-linux-amd64.tar.gz
wget -c ${DOWNLOAD_URL_PREFIX}/buildkit-v0.28.0.linux-amd64.tar.gz
wget -c ${DOWNLOAD_URL_PREFIX}/cni-plugins-linux-amd64-v1.9.1.tgz
wget -c ${DOWNLOAD_URL_PREFIX}/crictl-v1.35.0-linux-amd64.tar.gz
wget -c ${DOWNLOAD_URL_PREFIX}/critest-v1.35.0-linux-amd64.tar.gz

# nerdctl
mkdir nerdctl
tar -zxf $(ls nerdctl*.tar.gz) -C nerdctl
mv -f nerdctl/nerdctl /usr/local/bin/
rm -rf nerdctl

# cni
mkdir -p /opt/cni/bin/
tar -zxf $(ls cni-plugins-linux-*.tgz) -C /opt/cni/bin/

# crictl
tar -zxf $(ls crictl-*.tar.gz) -C /usr/local/bin/
tar -zxf $(ls critest-*.tar.gz) -C /usr/local/bin/

cat <<EOF > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
pull-image-on-create: false
EOF

# buildkit
mkdir buildkit
tar -zxf $(ls buildkit-*.tar.gz) -C buildkit
rm -f buildkit/bin/buildkit-qemu-*
cp -np buildkit/bin/* /usr/local/bin/
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
ExecStart=/usr/local/bin/buildkitd --oci-worker=false --containerd-worker=true

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

mkdir -p /etc/buildkit/
cat <<EOF > /etc/buildkit/buildkitd.toml
[registry."docker.io"]
  mirrors = ["https://docker.mirrors.ustc.edu.cn", "https://docker.m.daocloud.io"]
EOF

systemctl daemon-reload && systemctl start buildkitd && systemctl enable buildkitd

```

#### kubectl安装

```bash
apt-get install -y apt-transport-https ca-certificates curl gnupg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
chmod 644 /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
```

