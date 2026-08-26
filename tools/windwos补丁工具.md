---
title: "windows补丁工具"
subtitle: "windows补丁工具|windows激活工具"
description: "windows补丁工具|windows激活工具"
date: 2025-01-15T00:36:09+08:00
lastmod: 2025-01-15T00:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["Tools"]
categories: []
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1272.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# Windows

## Windows下载

Windows 版本说明：

- 《企业版》、《教育版》、《商业版》一般属于批量授权版，也称大客户版，缩写VOL或VL。
- 《消费者版本》、《多版本》中没有带VOL或VL字样一般属于零售版。

[Windows 原版操作系统 + Office 下载链接 更新速度快（山已几子木）](https://msdn.sjjzm.com/win11.html)

[Windows + Office https://hellowindows.cn/](https://hellowindows.cn/)

[Windows + Office https://www.xitongku.com/](https://www.xitongku.com/)

## 补丁工具

[windows 激活工具下载链接 github](https://github.com/zbezj/HEU_KMS_Activator/tags)

### 命令激活

**注意：** 是使用 PowerShell 执行命令而不是 CMD 终端执行命令。

查询系统激活状态

```powershell
slmgr.vbs -xpr
```

一行命令激活，在终端选项中，选择 `[1] HWID ` 激活 Windows，选择 `[2] Ohook` 激活 Office。

```powershell
irm https://get.activated.win | iex
```

### 软件激活

[HEU_KMS_Activator](https://github.com/zbezj/HEU_KMS_Activator/tags) 软件激活。（懒截图，自行尝试）。

[HEU_KMS_Activator 自搭建下载链接，资源有限静心下载](https://www.nihility.cn/files/tools/HEU_KMS_Activator_v42.3.2.rar)

## Windows安全

Windows Defender 移除，Microsoft Defender Antivirus Service  会占用 CPU 导致系统使用卡顿。

[windows-defender-remover 工具下载链接](https://github.com/ionuttbara/windows-defender-remover/tags)

[windows-defender-remover 自搭建下载链接，资源有限静心下载](https://www.nihility.cn/files/tools/DefenderRemover-v12.8.2.zip)

## Windows自动更新

[Windows Update Blocker 下载链接](https://www.sordum.org/downloads/?st-windows-update-blocker)

[windows-update-blocker 自搭建下载链接，资源有限静心下载](https://www.nihility.cn/files/tools/Wub-Windows-Update-Blocker.zip)