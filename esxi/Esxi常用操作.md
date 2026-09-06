## Esxi直通SATA控制器

需要注意的是，如果你把主板的 SATA 控制器做了直通，那么意味着你的Esxi 系统只能安装在U盘或者 NVME 硬盘上，如果 Esxi 系统的硬盘也刚好接在主板的 SATA 控制器上则无法直通。

### 查看SATA控制器

注意：可以现在 Esxi 硬件上先搜索 `AHCI` 查看支持的 SATA 控制器。

远程 Esxi SSH ，查看直通 SATA控制器代码命令

```bash
lspci -v | grep "Class 0106" -B 1
```

如果正常，应该可以看到类似如下的返回内容

```
[root@localhost:~] lspci -v | grep "Class 0106" -B 1
0000:00:17.0 Mass storage controller SATA controller: Intel Corporation Comet Lake SATA AHCI Controller 
         Class 0106: 8086:06d2
```

这个就是你的主板的 SATA 控制器了，如果看到这个代表已经成功一半。

### 修改passthru.map

使用编辑器（vim）打开 `/etc/vmware/passthru.map`，然后在文件的末尾增加如下内容

`vi /etc/vmware/passthru.map`

```
#Intel Corporation Comet Lake SATA AHCI Controller 
8086   06d2    d3d0    false
```

其中，8086 是 PCIE 设备的供应商ID，06d2 是 PCIE 设备的设备ID，这两个参数在第二步中获取，不要填写错误，d3d0 和 false 则直接复制即可。

### 重启服务器，修改直通

重新引导服务器后，即可在硬件页面看到 SATA 控制器从灰色变成了黑色，只是这个时候直通是禁用的，点击菜单的“切换直通“，把设备改为直通，然后再次重启服务器即可

sudo -i
apt update
apt install open-vm-tools


iscsicpl

diskmgmt.msc

slmgr /xpr

slmgr /dlv