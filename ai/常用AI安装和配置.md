---
title: "常用AI工具安装和配置"
subtitle: "常用AI工具安装和配置|AI基础"
description: "常用AI工具安装和配置"
date: 2026-06-09T13:00:00+08:00
lastmod: 2026-07-07T20:00:00+08:00
draft: false

authors: ["yzx"]
tags: ["AI", "OpenSpec","Claude Code"]
categories: ["AI"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2681.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# 常用AI工具安装和配置

## OpenSpec

[OpenSpec](https://github.com/Fission-AI/OpenSpec/) 是一个面向 AI 辅助开发的“规范驱动开发（Spec-Driven Development, SDD）”项目框架。

它的核心思想是：先写清楚“要做什么”（需求和设计规格【Spec】），再让 AI 或开发者根据规范去实现代码。这样可以减少需求歧义、提升协作效率，并让 AI 生成的代码更稳定、可维护。

简单描述就是：OpenSpec 就是用结构化规范来驱动 AI 编码、文档生成和项目协作。

### OpenSpec安装

参考

- [A lightweight spec-driven framework](https://openspec.dev/)
- [OpenSpec github](https://github.com/Fission-AI/OpenSpec/)

注意：需要 [Node.js](https://nodejs.org/en/download) 20.19.0+ 版本

[NVM](https://github.com/nvm-sh/nvm/releases) 安装（NVM：Node 版本管理器），[NVM 下载链接](https://www.nvmnode.com/guide/download.html)

```bash
# 1. 安装 node 指定版本
nvm install <version> [arch]
nvm install 24.18.0

# 2. 卸载 node 指定版本
nvm uninstall <version>
nvm uninstall 24.18.0

# 3. 使用指定 node 版本
nvm use <version>
nvm use 24.18.0

# 4. 查看 node 版本列表
nvm list / nvm ls

# 5. 查看远程支持版本
nvm list available
```

npm 全局安装 OpenSpec：

```bash
npm install -g @fission-ai/openspec@latest
```

初始化使用：

```bash
cd your-project
openspec init
```

后面的执行命令不用死记，后面用 AI 工具可以直接让 AI 执行 OpenSpec 规范流程处理。

## Claude Code

**Claude Code** 是由 [Anthropic](https://www.anthropic.com?utm_source=chatgpt.com) 推出的一个 AI 编程工具，它将 Claude 大语言模型直接集成到终端（CLI）中，让开发者能够通过自然语言完成代码开发、修改、调试、测试和项目维护工作。

Claude Code 的定位：AI 软件工程师 + 命令行工具

### Claude Code 安装

- [Claude Code 官方安装文档](https://code.claude.com/docs/en/overview#get-started)
- [Claude Code 桌面版工具下载链接](https://claude.com/download)

注意：中国区有地域限制，需要出国。

Linux：

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Windows CMD：

```bash
curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd
```

npm：

```bash
npm install -g @anthropic-ai/claude-code
```

初始化执行：

```bash
cd your-project
claude
```

### Claude HUD插件安装

[claude hud命令行插件](https://github.com/jarrodwatts/claude-hud)：在输入框下展示上下文使用情况、活动工具、正在运行的代理和待办事项进度。

安装命令

```bash
# 1. Add the marketplace
/plugin marketplace add jarrodwatts/claude-hud

# 2. Install the plugin /  reload plugins
/plugin install claude-hud
/reload-plugins

# 3.  Configure the statusline
/claude-hud:setup
```

### Claude Code前端设计插件安装

[Anthropic 官方开源的 frontend-design skill](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md)

告诉模型在生成 UI 时应该遵循什么原则、避免什么陷阱。

Skill 装好之后，它会自动注入设计原则，但你的提示词越具体，输出质量越高。

```bash
/plugin install frontend-design@claude-plugins-official
```

使用示例

```bash
使用 frontend-design skill，创建一个4A管理的首页。
```

### Claude Code SKILL创建

`skill-creator` 插件安装

```bash
/plugin install skill-creator@claude-plugins-official
/reload-plugins

# 列出插件列表
/plugin list
```

创建 skill，示例：创建 Java 编码规范（java-code-style）

```bash
/skill-creator 创建Java代码规范skill
1. 禁用tab缩进，使用4个空格缩进
2. if/else/when/while/case/方法换行前用大括号
3. 类、方法、字段属性需要添加注释说明，复杂代码需添加行注释说明
4. 方法、类字段属性使用小驼峰命名，静态变量使用大写带下划线命名
5. 行长度到140字符需换行
6. 方法参数多于2个需要换行
7. Java代码必须使用UTF-8编码格式
8. 项目中有.editorconfig文件优先以此文件编码规范执行
```

`%USER_HOME%\.claude\skills\java-code-style\SKILL.md`

~~~markdown
---
name: java-code-style
description: 应用该开发者个人的 Java 代码风格规范——4 空格缩进（禁用 tab）、if/else/while/for/switch/方法采用 K&R 风格大括号、类/方法/字段必须有注释、方法与字段使用小驼峰命名、静态变量使用大写下划线命名、行宽换行、方法参数超过 2 个需换行、以及 UTF-8 源码编码。只要是在编写新的 Java（.java）代码、编辑/重构已有 Java 代码，或对 Java 代码做风格审查，都应使用本 skill——即使用户只是说"加个方法"或"写个类"而没有明确提到风格规范。如果目标项目存在 .editorconfig 文件，其设置优先于本 skill 中的默认规则。
---

# Java 代码风格规范

这是这位开发者对 Java 源码的一贯要求，整理在这里是为了让 Claude 不必每个文件都被重新提醒一遍。只要是你在编写或改动 `.java` 代码——新建类、加方法、重构，或做一次风格检查——都应遵循以下规则，不管用户是否明确提到"风格"或"格式化"。

## 0. 先检查是否存在 `.editorconfig`

在套用下面的默认规则之前，先查看项目根目录（或所编辑文件的任一上级目录）是否有 `.editorconfig`。凡是它定义了的项——`indent_style`、`indent_size`、`max_line_length`、`charset` 等——**都以它为准**。本 skill 中的规则只是项目自身没有明确约定时的兜底默认值，并不是要覆盖项目自己文档化的规范。

例如：如果 `.editorconfig` 设置了 `max_line_length = 120`，那么在该项目中就按 120 换行，即使下面第 5 条的默认值是 140。

## 1. 缩进：4 个空格，禁用 tab

Java 源码中不允许出现 `\t` 字符，每一级缩进都是 4 个实际的空格。这纯粹是为了在不同编辑器间保持一致的显示效果——tab 在不同配置下宽度不同，正是这一点导致代码评审时的 diff 错位、难以对齐。

## 2. 大括号风格（K&R / "埃及"风格）

左大括号跟在引出它的语句后面、写在同一行——绝不能另起一行——并且每一个 `if`、`else`、`while`、`for`、`switch` 以及方法体都必须使用大括号，哪怕内部只有一条语句也不能省略。省略单行语句的大括号，正是"给 if 加了第二条语句结果它却悄悄跑到块外面去了"这类经典 bug 的成因。

```java
// 推荐写法
if (user.isActive()) {
    activate(user);
} else if (user.isPending()) {
    queue(user);
} else {
    reject(user);
}

for (Order order : orders) {
    process(order);
}

switch (status) {
    case ACTIVE: {
        handleActive();
        break;
    }
    default: {
        handleUnknown();
        break;
    }
}

public void activate(User user) {
    user.setActive(true);
}
```

```java
// 避免：大括号另起一行
if (user.isActive())
{
    activate(user);
}

// 避免：单行语句省略大括号
if (user.isActive())
    activate(user);
```

## 3. 类、方法、字段都要加注释

public 及包内可见的类、方法、字段都需要一句简短的说明性注释——不是把名字重复一遍，而是说明它的作用或存在的原因。琐碎的私有局部变量不需要注释，但方法体内任何不直观的逻辑（一个精妙的计算、一个临时绕过方案、一个必须保证的顺序约束）都应在关键处加上行内 `//` 注释说明。

```java
/**
 * 负责协调订单履约流程：锁定库存、完成支付扣款，并在一个事务内安排发货。
 */
public class OrderFulfillmentService {

    /** 订单被升级为人工review之前允许的最大重试次数。 */
    private static final int MAX_RETRIES = 3;

    /** 为订单锁定库存；若任一商品库存不足则抛出异常。 */
    public void reserveStock(Order order) {
        // 按价格从高到低排序，让高价值商品优先失败，
        // 避免先锁定了低价值商品之后还要额外回滚。
        order.getItems().sort(Comparator.comparing(Item::getPrice).reversed());
        ...
    }
}
```

不需要把注释写成繁文缛节——大多数成员一行 `/** ... */` 就足够了。多行说明留给类本身，或者真正不直观的复杂逻辑。

## 4. 命名规范

- 方法、字段、参数、局部变量：使用小驼峰命名 `camelCase`（例如 `orderTotal`、`calculateShipping`）。
- 静态变量（无论是否为常量）：使用大写下划线命名 `UPPER_SNAKE_CASE`（例如 `MAX_RETRIES`、`DEFAULT_TIMEOUT_MS`）。
- 类和接口沿用 Java 标准的大驼峰命名 `PascalCase`——这是默认约定，不在此开发者的自定义范围内。

## 5. 行长度达到 140 字符需换行

如果一行超过 140 字符，就需要换行——通常在运算符之后、链式调用的 `.` 之前，或参数之间断开——并将续行多缩进一级，使其在视觉上与下一条语句区分开来。（别忘了第 0 条：如果项目自己的 `.editorconfig` 定义了 `max_line_length`，以它为准，而不是这里的 140 默认值。）

## 6. 方法参数多于 2 个需要换行

方法参数为 0～2 个时保持在同一行。一旦方法参数达到 3 个或以上，每个参数单独占一行、缩进一级，这样长方法签名不会淹没在一大堆文字里，参数变更时的 diff 也能保持简洁。

```java
// 2 个参数：写在一行即可
public void transfer(Account from, Account to) { ... }

// 3 个及以上参数：每2个参数单独一行
public void transfer(
        Account from, Account to,
        BigDecimal amount, Currency currency) {
    ...
}
```

这条规则同样适用于方法/构造函数的声明，以及参数超过 2 个、换行有助于可读性的调用点。

## 7. 源码编码：UTF-8

Java 源文件必须以 UTF-8 编码保存，没有例外——Java 的默认平台编码因操作系统而异，依赖它正是中文、日文、emoji 等非 ASCII 字符串字面量和注释在生产环境中出现乱码的根本原因。新建 `.java` 文件时，要显式保存为 UTF-8，不要依赖编辑器的默认设置。

~~~

### Cloude Code agent创建

OpenSpec规范agent创建

```bash
创建子agent，当所有编码实现完成后更新OpenSpec规范propose.md/design.md/task.md文档，没有OpenSpec则创建一个新的
```

前后端子agent创建

```
创建2个子agent，agents文档使用中文编写
一个为Vue3前端编码：项目使用TypeScript，UI 组件库选Element Plus，状态管理用Pinia，前端目录frontend
一个为后端Java/Spring Boot项目编码：在项目backend后端目录下使用Java 21/Spring Boot 3.5实现编码
```

### Claude Code配置

Claude Code 配置文件（可以支持国内阿里百炼等AI语言模型接入），也可以直接使用 Claude Code 

- 全局配置：`~/.claude/settings.json`
- 项目配置：`project/.claude/settings.json`

阿里云百炼 Token Plan 团队版：

```json
{
    "env": {
        "ANTHROPIC_AUTH_TOKEN": "YOUR_API_KEY",
        "ANTHROPIC_BASE_URL": "https://token-plan.cn-beijing.maas.aliyuncs.com/apps/anthropic",
        "ANTHROPIC_MODEL": "qwen3.7-max",
        "ANTHROPIC_DEFAULT_HAIKU_MODEL": "qwen3.6-flash",
        "ANTHROPIC_DEFAULT_SONNET_MODEL": "qwen3.7-max",
        "ANTHROPIC_DEFAULT_OPUS_MODEL": "qwen3.7-max",
        "CLAUDE_CODE_SUBAGENT_MODEL": "qwen3.7-max"
    }
}
```

## Codex

- [Codex 桌面版下载链接](https://openai.com/zh-Hans-CN/codex/)

**Codex** 是 OpenAI 推出的 AI Agent（智能代理）产品，最初是一个专门用于代码生成的模型，如今已经发展成能够执行实际工作的智能助手。它不仅能写代码，还能操作文件、运行工作流、生成文档、处理数据等任务。