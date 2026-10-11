---
title: "Proxmox(pve)直通"
subtitle: "Proxmox硬盘直通和核显直通"
description: "Proxmox硬盘直通和核显直通配置说明"
date: 2026-10-07T21:00:00+08:00
lastmod: 2026-10-07T21:00:00+08:00
draft: false

authors: ["yzx"]
tags: ["Proxmox"]
categories: ["Proxmox"]
series: []

featuredImage: "https://www.nihility.cn/files/images/20261004_151823.jpg"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# PVE9直通

PVE 9 直通与映射配置（JMB585 硬盘直通 / 硬盘映射 / 核显直通）

## 环境

| 项目 | 内容 |
|---|---|
| 宿主机 | Proxmox VE 9，内核 7.0.2-6-pve，Intel N150（Alder Lake-N），GRUB 引导 |
| 虚拟机 | VM 101（fnos2，飞牛 OS），q35 + OVMF，4 核 4G |
| SATA 扩展卡 | JMB585（JMB58x AHCI），`01:00.0`，ID `197b:0585`，独占 IOMMU group 13，PCIe 3.0 x1（约 1GB/s，由主板根端口 `00:1c.0` 限制） |
| 核显 | `00:02.0`，ID `8086:46d4`，独占 IOMMU group 0 |
| 板载 SATA | `00:17.0`，挂 Kingston 240G（PVE 系统盘），不参与直通 |

## 方案总览

| 需求 | 方案 | 本机结果 |
|---|---|---|
| 给 VM 整块 SATA 控制器（真 HBA） | 第一章：PCI 直通 JMB585 | 成功，复位稳定，VM 内可读真实 SMART |
| 只给 VM 几块物理盘 | 第二章：硬盘映射 | 可用，作为直通不稳定时的备选 |
| 给 VM 核显转码 | 第三章：核显整块直通 | 成功，需在飞牛内延迟加载 i915 |

先说结论：同一个插槽下，ASM1166（旧固件）做直通会因总线复位后链路重训失败而掉线，换成 JMB585 后复位约 0.1 秒完成，无任何错误。所以做直通优先选 JMB585。

---

## 第一章 硬盘直通（PCI 直通 JMB585）

### 1.1 前置条件

1. BIOS 开启 VT-d。
2. 确认 IOMMU 已生效（有分组即可）：

```bash
find /sys/kernel/iommu_groups/ -type l | sort -V
```

3. 目标设备最好独占一个 IOMMU 组（本机 `01:00.0` 独占 group 13）。
4. 识别设备与 ID：

```bash
lspci -nn | grep -i -E "jmicron|jmb|sata"
# 01:00.0 SATA controller [0106]: JMicron Technology Corp. JMB58x AHCI SATA controller [197b:0585]
# 00:17.0 SATA controller [0106]: Intel Corporation Alder Lake-N SATA AHCI Controller [8086:54d3]
# 00:02.0 VGA compatible controller [0300]: Intel Corporation Alder Lake-N [Intel Graphics] [8086:46d4]
```

### 1.2 如果之前用过盘映射，先清理

盘换成控制器直通后，宿主机看不到这些盘，旧映射要摘掉（只改配置，不动盘上数据）：

```bash
qm shutdown 101
qm set 101 --delete scsi2,scsi3,scsi4,scsi5,scsi6
```

### 1.3 配置 vfio，让它在开机时抢占

不要覆盖掉已有设备的 ID（本机核显已在用），把多个 ID 用逗号写在一起：

- `8086:46d4` 核显
- `197b:0585` stata控制器

核显配置

```bash
# 核显
softdep i915 pre: vfio-pci
softdep xe pre: vfio-pci
# 硬盘卡控制器
softdep ahci pre: vfio-pci

# 共享：所有要直通的设备 ID 写在这一行 options vfio-pci ids=
cat > /etc/modprobe.d/vfio.conf <<'EOF'
options vfio-pci ids=8086:46d4,197b:0585
softdep i915 pre: vfio-pci
softdep xe pre: vfio-pci
softdep ahci pre: vfio-pci
EOF

update-initramfs -u -k all
lsinitramfs /boot/initrd.img-$(uname -r) | grep vfio.conf      # 必须有输出
```

注意：

- 不要屏蔽整个 `ahci` 模块，板载 SATA 上还有系统盘；用 `softdep ahci pre: vfio-pci` 让 vfio 先加载。
- `update-initramfs` 不能省，否则重启后 `ahci` 会先接管卡，宿主机识别一遍盘，再被切给 VM。

### 1.4 添加到虚拟机

VM 需为 q35 + OVMF。本机 `hostpci0` 已被核显占用，所以硬盘卡用 `hostpci1`：

```bash
# 添加硬盘控制器直通
qm set 101 -hostpci1 0000:01:00.0,pcie=1,rombar=0
qm config 101 | grep hostpci
```

### 1.5 断电重启并验证（先不要启动 VM）

```bash
shutdown -h now        # 拔电源等 30 秒再开机
```

开机后：

```bash
lspci -nnk -s 01:00.0       # Kernel driver in use: vfio-pci
dmesg | grep "0000:01:00.0" # 不应出现 "ahci 0000:01:00.0" 的探测行
lsblk -o NAME,SIZE,MODEL    # 只剩系统盘，机械盘消失是正常的
```

### 1.6 启动 VM 并监控复位

另开窗口：

```bash
dmesg -w | grep -E "0000:01:00.0|pcieport"
```

然后 `qm start 101`。

- **正常**：`resetting` → `reset done`，每次约 0.1 秒（本机实测三次均如此），无 `retraining failed`。
- **异常**：`broken device, retraining non-functional downstream link`、`Data Link Layer Link Active not set`、`device inaccessible`，说明链路复位后没恢复，退回第二章的盘映射。

### 1.7 在飞牛里验证

```bash
lspci | grep -i -E "jmicron|sata"
dmesg | grep -i ahci
lsblk -o NAME,SIZE,MODEL,SERIAL
cat /proc/mdstat
lsblk -f
```

本机实测结果：

- `ahci 0000:02:00.0: 5/5 ports implemented`，6 Gbps，端口数准确，无幽灵端口。
- 5 块物理盘全部出现，序列号是真实序列号（不再是 `drive-scsiN`）。
- 原有存储池（md 阵列、NTFS 分区）自动识别并挂载，数据完好。
- 飞牛里可直接读真实 SMART、温度。

飞牛提示“初始化/格式化”时不要点，先确认数据。

### 1.8 注意事项

1. JMB585 只有 5 个端口，本机刚好 5 块盘。
2. 卡只协商 PCIe x1（约 1GB/s），机械盘够用，全 SATA SSD 才会成为瓶颈。
3. 直通后宿主机看不到这些盘，不要在宿主机上挂载。
4. 没有 FLR 的卡，VM 建议“关机再开机”，不要用“重启”。
5. 直通后 SMART 在 VM 里查看：

```bash
smartctl -a /dev/sdX
smartctl -t long /dev/sdX      # 长测约两小时
```

重点看 `Reallocated_Sector_Ct`、`Current_Pending_Sector`、`Offline_Uncorrectable`、`UDMA_CRC_Error_Count`。

6. NTFS 盘接近写满时，Linux 下写入容易出问题，要留出空间。单盘卷没有冗余，重要数据另做备份。

### 1.9 附：ASM1166 的失败记录（供对比）

- 旧固件虚报端口：`30/32 ports implemented (port mask 0xffffff3f)`，开机多扫 24 个幽灵端口。
- 无可靠 FLR；VM 启动时对根端口 `00:1c.0` 做总线复位，链路重训失败：

```bash
pcieport 0000:00:1c.0: broken device, retraining non-functional downstream link at 2.5GT/s
pcieport 0000:00:1c.0: retraining failed
pcieport 0000:00:1c.0: Data Link Layer Link Active not set in 100 msec
vfio-pci 0000:01:00.0: Unable to change power state from D0 to D3hot, device inaccessible
```

- 之后 VM 里读到全 ff（`type 7f class 0xffffff`），设备被忽略；宿主机只有断电才能恢复。
- 清空 `reset_method`、`disable_idle_d3=1`、`rombar=0`、关 ASPM 都不能解决。
- 同一个插槽换 JMB585 后问题消失，说明根因在 ASM1166 卡（旧固件）。

---

## 第二章 硬盘映射（按盘映射）

宿主机用 ahci 驱动整张卡，物理硬盘以 `/dev/disk/by-id/...` 路径映射给 VM。不涉及 PCI 复位，稳定，适合直通不可靠的卡（如 ASM1166），也适合只想给 VM 几块盘。

### 2.1 前置：宿主机必须能看到盘，vfio 不能抢卡

```bash
lspci -nnk -s 01:00.0                 # Kernel driver in use: ahci
ls -l /dev/disk/by-id | grep ata      # 能看到全部物理盘
```

如果曾配置过直通，需要清理：

```bash
qm set <vmid> --delete hostpci1
mv /etc/modprobe.d/vfio.conf /root/vfio.conf.bak    # 或只去掉卡的 ID 和 ahci 的 softdep
update-initramfs -u -k all
lsinitramfs /boot/initrd.img-$(uname -r) | grep vfio.conf
shutdown -h now                                       # 断电 30 秒再开机
```

注意：本机核显仍需要 vfio，所以不要直接删 `vfio.conf`，只去掉卡的 ID（`ids=` 只留 `8086:46d4`）和 `softdep ahci pre: vfio-pci` 那行。

### 2.2 映射命令

使用整盘路径（不带 `-part`）并带 `serial=`；槽位避开已占用的（本机 scsi0/scsi1 是 VM 的虚拟盘）：

```bash
qm set 101 -scsi2 /dev/disk/by-id/ata-WDC_WD20EFRX-68EUZN0_WD-WCC4M2DVNXSC,serial=WD-WCC4M2DVNXSC
qm set 101 -scsi3 /dev/disk/by-id/ata-WDC_WD20EFRX-68EUZN0_WD-WCC4M7XR924U,serial=WD-WCC4M7XR924U
qm set 101 -scsi4 /dev/disk/by-id/ata-ST4000VN008-2DR166_ZDHADCEW,serial=ZDHADCEW
qm set 101 -scsi5 /dev/disk/by-id/ata-ST2000DM006-2DM164_Z4ZB122A,serial=Z4ZB122A
qm set 101 -scsi6 /dev/disk/by-id/ata-ST1000DM003-1SB10C_S9A05BM0,serial=S9A05BM0
```

`scsihw: virtio-scsi-single` 即可。映射前先确认 VM 配置里没有残留的 `hostpci`（卡不能同时被映射和直通）。

### 2.3 取消映射

```bash
qm shutdown 101
qm set 101 --delete scsi2,scsi3,scsi4,scsi5,scsi6
qm config 101 | grep scsi
```

`--delete` 只摘配置，不动盘上数据。取消前建议先在 VM 里停用对应存储。

### 2.4 取舍与注意事项

| 项 | 说明 |
|---|---|
| 数据安全 | 映射不会格式化；盘上有旧分区，VM 提示“初始化/格式化”时不要点 |
| 寿命 | 对硬盘寿命无影响，读写落在同一块物理盘 |
| SMART | VM 里看不到真实 SMART、温度，需在宿主机用 `smartctl` 查看 |
| 休眠 | 由宿主机管理，VM 里设置的休眠通常不生效 |
| 独占 | 映射的盘只给 VM 用，宿主机不要挂载或写入（用 `lsblk -o NAME,MOUNTPOINT` 检查） |
| 稳定性 | 宿主机和 VM 重启都安全，不再触发总线复位 |
| 路径 | 用 `/dev/disk/by-id`，不要用 `/dev/sdX`（盘符会变） |

宿主机监控 SMART：

```bash
apt install smartmontools
smartctl -a /dev/disk/by-id/ata-...
smartctl -t short|long /dev/disk/by-id/ata-...
```

### 2.5 直通与映射怎么选

| | PCI 直通 | 硬盘映射 |
|---|---|---|
| VM 内 SMART/温度 | 有 | 无 |
| 盘休眠 | VM 控制 | 宿主机控制 |
| 对卡的要求 | 复位必须可靠 | 无 |
| 风险 | 卡掉线需断电 | 低 |
| 适用 | JMB585 等复位正常的卡 | ASM1166 旧固件等不稳定的卡 |

---

## 第三章 核显直通（Intel Alder Lake-N → 飞牛）

### 3.1 影响

- 整块直通后，宿主机失去核显，接显示器将没有 PVE 控制台输出，只能用网页或 SSH 管理。
- VM 保留虚拟显卡（不设 `x-vga=1`），PVE 网页控制台仍可用，核显只负责转码/计算。
- GVT-g 不支持 Alder Lake-N（仅第 5–9 代）；多 VM 共享只能走 SR-IOV（`i915-sriov-dkms`），对 PVE 7.0 内核的适配未确认，只有一个 VM 用核显时不建议。

### 3.2 宿主机配置

1. 确认设备与分组（以实际输出为准，本机是 `8086:46d4`，不是常见的 46d1）：

```bash
$ lspci -nn -s 00:02.0
# 00:02.0 VGA compatible controller [0300]: Intel Corporation Alder Lake-N [Intel Graphics] [8086:46d4]

$ find /sys/kernel/iommu_groups/ -type l | sort -V | grep "0000:00:02.0"
# /sys/kernel/iommu_groups/0/devices/0000:00:02.0
# /sys/kernel/iommu_groups/14/devices/0000:02:00.0
# 核显独占 group 0，可以直通
```

2. vfio 配置（与硬盘卡的 ID 写在同一行，见 1.3）

```bash
cat > /etc/modprobe.d/vfio.conf <<'EOF'
options vfio-pci ids=8086:46d4
softdep i915 pre: vfio-pci
softdep xe pre: vfio-pci
EOF
```

并确保 initramfs 加载 vfio 模块后重建：

```bash
grep -q '^vfio_pci' /etc/initramfs-tools/modules || cat >> /etc/initramfs-tools/modules <<'EOF'
vfio
vfio_iommu_type1
vfio_pci
EOF

update-initramfs -u -k all
lsinitramfs /boot/initrd.img-$(uname -r) | grep vfio.conf
reboot
```

3. 验证：

```bash
lspci -nnk -s 00:02.0       # Kernel driver in use: vfio-pci
```

4. 添加到 VM（先关机；q35 + OVMF）：

```bash
qm set 101 -hostpci0 0000:00:02.0,pcie=1,rombar=0
qm start 101
```

- `rombar=0` 用来避开 `Invalid PCI ROM header signature` 告警。
- `qm start` 输出 `OpRegion detected on Intel display 46d4` 只是信息提示，不是错误。

### 3.3 飞牛内的关键处理：延迟加载 i915

问题现象：带核显开机，noVNC 黑屏、SSH 和网页都连不上；不带核显启动正常。

处理方法：先让飞牛开机时不自动加载 i915，进系统后再加载。

1. 不带核显启动飞牛（`qm set 101 --delete hostpci0`），在飞牛里：

```bash
echo "blacklist i915" > /etc/modprobe.d/blacklist-i915.conf
poweroff
```

2. 宿主机重新加上核显启动，飞牛能正常进系统，`lspci` 能看到 Intel 核显。
3. 手动加载验证：

```bash
modprobe i915
ls /dev/dri
dmesg | grep -i -E "i915|drm"
```

成功的关键日志：

```
Initialized i915 1.6.0 for 0000:01:00.0 on minor 1
GT0: HuC: authenticated for all workloads
GT0: GUC: submission enabled
```

以下几行是没接显示器、没有 ROM 导致的，可忽略：

```
Failed to find VBIOS tables (VBT)
failed to retrieve link info, disabling eDP
Cannot find any crtc or sizes
```

4. 配置开机延迟加载（黑名单保留）：

```bash
cat > /etc/systemd/system/load-i915.service <<'EOF'
[Unit]
Description=Load i915 after boot
After=multi-user.target network-online.target

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 20
ExecStart=/sbin/modprobe i915

[Install]
WantedBy=multi-user.target
EOF
systemctl enable load-i915.service
```

重启飞牛后 `ls /dev/dri` 出现 `card0`（虚拟显卡）、`card1`（核显）、`renderD128`，本机实测成功。

说明：开机卡死的确切原因日志里没有直接证据，我的判断是 i915 在系统早期自动加载与直通核显的初始化冲突，延迟加载后恢复，这是推测。

### 3.4 启用硬件转码

飞牛的影视、相册等应用设置里开启硬件转码，选择 `/dev/dri/renderD128`。验证：

```bash
cat /sys/class/drm/card1/gt/gt0/rps_cur_freq_mhz     # 转码时频率会升高
vainfo                                                # 可选，能列出 H264/HEVC 说明 Quick Sync 可用
```

### 3.5 注意事项

1. 带核显时 noVNC 黑屏是正常的，飞牛加载 i915 后控制台切到了没接显示器的核显；用 `qm status 101` 和 SSH/网页判断 VM 是否正常。
2. 核显有 FLR，复位约 0.1 秒完成，VM 可以放心重启。
3. 恢复宿主机使用核显：去掉 `vfio.conf` 中核显的 ID 和 softdep、去掉 initramfs-tools/modules 的 vfio 行、重建 initramfs、移除 `hostpci0`、重启。

---

## 第四章 问题排查速查

### 4.1 硬盘直通

| 现象 | 原因 / 处理 |
|---|---|
| 开机日志里有 `ahci 0000:01:00.0` 探测行 | vfio 没先抢占：检查 `vfio.conf`（ids、softdep）及 `lsinitramfs ... \| grep vfio.conf`，重建 initramfs，断电重启 |
| `lspci -nnk` 显示 `vfio-pci` 但不确定是否成功 | VM 启动后 PVE 也会临时切到 vfio-pci，要看开机 dmesg 里有无 ahci 探测 |
| VM 里 `type 7f class 0xffffff` / `unknown header type 7f` | 卡复位后无响应：宿主机断电；换卡 |
| `retraining failed`、`Data Link Layer Link Active not set` | 总线复位后链路没起来，非配置问题，换卡或改用盘映射 |
| `Unable to change power state ... device inaccessible` | 卡已掉线，只有断电能恢复 |
| 大量 `vfio_bar_restore` | 复位后 BAR 恢复的日志，单独出现不一定是失败，以 VM 内是否识别为准 |
| VM 里 `ahci 0000:00:1f.2`、1.5 Gbps | 这是 q35 虚拟的 ICH9 SATA，不是直通卡；用 `lspci -nn` 找 `197b:0585` |
| 宿主机和 VM 提示符不同（`root@pve` / `root@luck`） | 先看提示符再判断输出属于哪边 |
| 飞牛提示初始化/格式化 | 先别点，核对盘上分区与数据 |

### 4.2 硬盘映射

| 现象 | 原因 / 处理 |
|---|---|
| 盘从宿主机消失 | VM 配置里还有 `hostpci`，或 `vfio.conf` 残留导致 vfio 抢卡；清理并重建 initramfs，断电重启 |
| `qm start` 报 `Device or resource busy` | 盘被宿主机挂载：`lsblk -o NAME,MOUNTPOINT` 检查并 `umount` |
| 启动后找不到盘 | by-id 路径变化或卡未被 ahci 识别：`ls -l /dev/disk/by-id \| grep ata` |
| `cannot delete 'hostpci0' - not set` | 已经删除过，无需处理 |

### 4.3 核显直通

| 现象 | 原因 / 处理 |
|---|---|
| `OpRegion detected on Intel display` | 信息提示，忽略 |
| `Invalid PCI ROM header ... got 0xffff` | 读 ROM 失败，加 `rombar=0` |
| 宿主机接显示器没输出 | 核显已被 vfio 占走，正常 |
| 带核显后 VM 黑屏、SSH 连不上 | 飞牛开机自动加载 i915 卡住；按 3.3 屏蔽并延迟加载 |
| 飞牛里看不到核显 | 去掉 `pcie=1`：`qm set 101 -hostpci0 0000:00:02.0,rombar=0` |
| 有核显无 `/dev/dri/card1` | 手动 `modprobe i915`，看 `dmesg \| grep -i -E "i915\|drm"` |
| 手动加载 i915 卡死 | 尝试 `modprobe i915 enable_guc=0` 或 `force_probe=46d4` |
| 宿主机 `DMAR ... fault` | DMA 越界，需保留日志进一步分析 |
| noVNC 黑屏 | 可能是 VM 没起来，也可能是控制台切到核显；`qm status 101` + SSH 判断 |
| `qm guest cmd ... VM 101 is not running` | VM 是停止状态，黑屏是没起来，`qm start 101` 看报错 |

### 4.4 VM 启动与引导

- 引导顺序 `boot: order=scsi0;ide2;net0`，系统装好后弹出 ISO：`qm set 101 --ide2 none,media=cdrom`。
- 系统没装完整会卡在 UEFI/黑屏：挂回 ISO 重装，**安装目标盘选 20G 的 `scsi0`，不要选物理盘**。
- UEFI 标志出现时连按 `Esc` 能进设置界面，说明虚拟显卡正常，问题在引导。

---

## 第五章 日常运维要点

1. 改完 vfio/modprobe 配置必须 `update-initramfs -u -k all`，并用 `lsinitramfs` 确认。
2. 多个直通设备的 ID 写在同一个 `options vfio-pci ids=` 里，用逗号分隔，不要覆盖已有 ID。
3. 直通设备掉线后，只有断电（拔电源 30 秒）才能复位，单纯 reboot 不够。
4. 不要把宿主机系统盘接在要直通的卡上。
5. 直通后在 VM 里查看 SMART；映射模式在宿主机查看 SMART。重要数据必须另有备份，SMART 正常不等于不会坏。
6. `/etc/modules` 已过时，推荐 `/etc/modules-load.d/*.conf`，但真正保证 vfio 先于 ahci/i915 的是 initramfs 中的 `softdep`。
7. 相关文件速查：

| 文件 | 作用 |
|---|---|
| `/etc/default/grub` | 内核参数（改后 `update-grub`） |
| `/etc/modprobe.d/vfio.conf` | vfio 绑定设备 ID 与 softdep |
| `/etc/initramfs-tools/modules` | initramfs 中加载的模块 |
| `/etc/pve/qemu-server/<vmid>.conf` | VM 配置（`qm config <vmid>`） |
| 飞牛 `/etc/modprobe.d/blacklist-i915.conf` | 阻止开机早期自动加载 i915 |
| 飞牛 `/etc/systemd/system/load-i915.service` | 开机后延迟加载 i915 |

## 第六章 本机最终方案

- 硬盘：JMB585（`197b:0585`）PCI 直通给 VM 101，`hostpci1: 0000:01:00.0,pcie=1,rombar=0`，5 块物理盘在飞牛内以真实序列号出现，存储池完好。
- 核显：`hostpci0: 0000:00:02.0,pcie=1,rombar=0`，飞牛内延迟加载 i915，`/dev/dri/card1` 与 `renderD128` 可用。
- 备选：直通不稳定时回退到第二章的硬盘映射。
