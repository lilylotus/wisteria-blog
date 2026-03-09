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

featuredImage: "https://www.nihility.cn/files/images/IMG_2488.JPG"
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
apt-get install -y nginx
```

#### Nginx 配置

```bash
cat > /etc/nginx/conf.d/debian-pxe.conf << EOF
server {
    listen 8080 default_server;
    listen [::]:8080 default_server;
    
    server_name _;
    
    # Preseed配置文件
    location /preseed {
        alias /srv/www/preseed;
        default_type text/plain;
    }
    
    # Debian安装文件
    location /debian12 {
        alias /srv/www/debian12;
        autoindex on;
    }
    
    location /debian13 {
        alias /srv/www/debian13;
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
```

##### BIOS 模式

bios 目录下放置 Legacy BIOS 启动文件

```bash
cp /srv/tftp/debian/{pxelinux.0,ldlinux.c32,splash.png} /srv/tftp/bios/
cp /srv/tftp/debian/debian-installer/amd64/boot-screens/{vesamenu.c32,libcom32.c32,libutil.c32} /srv/tftp/bios/
cp /srv/tftp/debian/debian-installer/amd64/{linux,initrd.gz} /srv/tftp/bios/

mkdir -p /srv/tftp/bios/pxelinux.cfg
touch /srv/tftp/bios/pxelinux.cfg/default

mkdir -p /srv/tftp/bios/preseed
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

### Debian 12 BIOS 模式 preseed 文件

```
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
# d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/hostname string 192.168.99.30
d-i mirror/http/port string 8080
d-i mirror/http/directory string /debian12
d-i mirror/http/proxy string
d-i mirror/suite string stable

# ==================== 时区和时钟 ====================
d-i clock-setup/utc boolean true
d-i time/zone string Asia/Shanghai
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string ntp.aliyun.com

# 分区
# 强制使用GPT（UEFI）或MSDOS（BIOS） gpt / msdos
d-i partman/default_filesystem string xfs

# 安装xfsprogs包
d-i pkgsel/include string xfsprogs

# 分区方法选择LVM
d-i partman-auto/method string lvm
d-i partman-auto/disk string /dev/sda
d-i partman-auto-lvm/guided_size string max

# LVM卷组名称
d-i partman-auto-lvm/new_vg_name string vg_system

# 确认LVM分区
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-lvm/device_remove_lvm boolean true

# 删除原有分区
d-i partman-md/device_remove_md boolean true
d-i partman-auto/purge_lvm_from_device boolean true

# 始终创建新分区表
d-i partman-partitioning/new_label boolean true
d-i partman-partitioning/choose_label string msdos

# 确认分区
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# This makes partman automatically partition without confirmation.
d-i partman-md/confirm boolean true
d-i partman/active_partition_warn boolean false
d-i partman-auto/confirm boolean true

# 自定义服务器分区
# 分区方案名称 :: \
#     最小大小 优先大小 最大大小 文件系统类型 \
#         标志{ } \
#         方法{ 方法 } 格式化{ } \
#         使用文件系统{ } 文件系统{ 文件系统类型 } \
#         挂载点{ 挂载点 } \
#     . \
d-i partman-auto/expert_recipe string \
    lvm-xfs-server :: \
    # /boot 分区 (ext4，不能使用 XFS 作为 /boot)
    1024 1 1024 ext4 \
        $primary{ } $bootable{ } \
        method{ format } format{ } \
        use_filesystem{ } filesystem{ ext4 } \
        mountpoint{ /boot } \
    . \
    # LVM物理卷（使用剩余所有空间）
    100% 2000 -1 lvm \
        $defaultignore{ } \
        $lvmok{ } \
        method{ lvm } \
        vg_name{ vg_system } \
    . \
    # Swap分区 (2GB)
    2048 1024 2048 linux-swap \
        $lvmok{ } \
        in_vg{ vg_system } \
        lv_name{ lv_swap } \
        method{ swap } format{ } \
    . \
    # 根分区 / 剩余空间 (XFS)
    10240 1024 -1 xfs \
        $lvmok{ } \
        in_vg{ vg_system } \
        lv_name{ lv_root } \
        method{ format } format{ } \
        use_filesystem{ } filesystem{ xfs } \
        mountpoint{ / } \
    . \

# ==================== 用户账户 ====================
# Root用户
d-i passwd/root-login boolean true
d-i passwd/root-password password luck
d-i passwd/root-password-again password luck

# 普通用户（可选）
d-i passwd/make-user boolean false
d-i passwd/user-fullname string luck
d-i passwd/username string luck
d-i passwd/user-password password luck
d-i passwd/user-password-again password luck

# ==================== 软件包安装 ====================
# 禁用流行度调查
popularity-contest popularity-contest/participate boolean false
d-i apt-setup/services-select multiselect security, updates
d-i apt-setup/security_host string security.debian.org

# 软件包选择
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string openssh-server vim net-tools curl wget
d-i pkgsel/upgrade select full-upgrade
d-i pkgsel/update-policy select none
d-i pkgsel/updatedb boolean true

# ==================== GRUB引导器 ====================
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string default
d-i grub-installer/skip boolean false

# ==================== 完成安装 ====================
d-i finish-install/keep-consoles boolean true
d-i finish-install/reboot_in_progress note
d-i cdrom-detect/eject boolean false
d-i debian-installer/exit/poweroff boolean false
d-i debian-installer/exit/halt boolean false
d-i debian-installer/exit/ask boolean false
```

### Debian 12 EFI 模式 preseed 文件

```
```
