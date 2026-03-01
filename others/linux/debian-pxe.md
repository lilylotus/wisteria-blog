
### dhcp

```bash
# /etc/dhcp/dhcpd.conf
subnet 192.168.99.0 netmask 255.255.255.0 {
    range 192.168.99.100 192.168.99.200;
    option subnet-mask 255.255.255.0;
    option routers 192.168.99.2;
    option domain-name-servers 114.114.114.114;
    
    # PXE配置
    class "pxeclients" {
        match if substring(option vendor-class-identifier, 0, 9) = "PXEClient";
        next-server 192.168.99.8;  # TFTP服务器IP
        filename "pxelinux.0";     # BIOS引导文件
        # filename "bootx64.efi";   # UEFI引导文件
    }
}

# 配置绑定网卡
vim /etc/default/isc-dhcp-server
INTERFACESv4="ens32"
# INTERFACESv6=""

# 启用DHCP服务
sudo systemctl enable isc-dhcp-server
sudo systemctl restart isc-dhcp-server
```

### tftp

```bash
# /etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure --ipv4"

# 创建目录结构
sudo mkdir -p /srv/tftp/{bios,uefi}
sudo chown -R tftp:tftp /srv/tftp

# 复制PXE引导文件
mount /dev/sr0 /mnt

cp /usr/lib/PXELINUX/pxelinux.0 /srv/tftp/
cp /mnt/isolinux/{ldlinux.c32,libcom32.c32,libutil.c32,vesamenu.c32} /srv/tftp/

mkdir -p /srv/tftp/debian/boot/
cp /mnt/install.amd/vmlinuz /srv/tftp/debian/boot/
cp /mnt/install.amd/initrd.gz /srv/tftp/debian/boot/

# 创建引导菜单目录
sudo mkdir -p /srv/tftp/pxelinux.cfg

systemctl restart tftpd-hpa
```

```bash
# /srv/tftp/pxelinux.cfg/default
DEFAULT vesamenu.c32
PROMPT 0
TIMEOUT 50
ONTIMEOUT auto

MENU TITLE PXE Boot Menu
MENU BACKGROUND splash.png

LABEL auto
    MENU LABEL ^Automated Debian Install
    KERNEL debian/boot/vmlinuz
    APPEND initrd=debian/boot/initrd.gz url=http://192.168.99.10/preseed/auto.cfg auto=true priority=critical vga=788 --- quiet

LABEL manual
    MENU LABEL ^Manual Debian Install
    KERNEL debian/boot/vmlinuz
    APPEND initrd=debian/boot/initrd.gz

MENU SEPARATOR

LABEL local
    MENU LABEL Boot from ^Local disk
    LOCALBOOT 0

# UEFI配置文件
# /srv/tftp/uefi/grub.cfg
set timeout=5
menuentry "Automated Debian Install (UEFI)" {
    linuxefi debian/boot/vmlinuz auto=true priority=critical url=http://192.168.1.10:8080/preseed/auto.cfg
    initrdefi debian/boot/initrd.gz
}
```

### nginx

```bash
# 使用Nginx提供安装源
sudo mkdir -p /srv/http/{debian,preseed}
mount /dev/sr0 /srv/http/debian/

# Nginx配置
# /etc/nginx/conf.d/pxe.conf
server {
    listen 8080;
    server_name pxe-server;
    root /srv/http;
    
    location /debian/ {
        alias /srv/debian/;
        autoindex on;
    }
    
    location /preseed/ {
        alias /srv/http/preseed/;
        autoindex on;
    }
}
```

