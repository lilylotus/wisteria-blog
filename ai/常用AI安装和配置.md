---
title: "常用AI工具安装和配置"
subtitle: "常用AI工具安装和配置|AI基础"
description: "常用AI工具安装和配置"
date: 2026-06-09T13:00:00+08:00
lastmod: 2026-08-26T22:00:00+08:00
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

#### 离线安装

[Claude Code 安装包 github 链接](https://github.com/anthropics/claude-code/releases) 

Windows 二进制 exe 文件下载后解压到 `C:\Users\Administrator\.local\bin` 目录。

#### Linux

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

#### Windows CMD

```bash
curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd
```

#### npm

```bash
npm install -g @anthropic-ai/claude-code
```

初始化执行：

```bash
cd your-project
claude
```

### 禁用claude自动更新

全局配置文件禁用更新

Windows 路径，也就是 `C:\Users\你的用户名\.claude\settings.json` （没有就新建）

```bash
%USERPROFILE%\.claude\settings.json
```

写入禁用配置

```json
{
  "env": {
    "DISABLE_AUTOUPDATER": "1"
  }
}
```

注意：如果文件已经有其他配置内容，注意是在已有的 `env` 对象里追加这个键值，不要整个文件覆盖掉。

配置说明：

`DISABLE_AUTOUPDATER=1` 只会停止**后台自动检查更新**，`claude update` 和 `claude install` 这两个手动更新命令依然能正常用——这是官方推荐的默认做法，不完全锁死更新能力，只是不让它自己偷偷升级。

若是想彻底连手动更新都禁用掉锁死

```json
{
  "env": {
    "DISABLE_UPDATES": "1"
  }
}
```

验证是否生效，可以先跑一下，记下当前版本号，过一段时间再跑一次同样命令，如果版本号没变化，说明自动更新确实被关掉了。

```powershell
claude --version
```

### Claude Code跳过确认

Claude Code 提供几种不同强度的方式来跳过确认，按推荐程度排列：

#### 方式一：settings.json 全局允许 Bash（推荐，相对安全）

在 `~/.claude/settings.json`（全局生效）或项目内 `.claude/settings.json`：

```json
{
  "permissions": {
    "allow": [
      "Bash"
    ]
  }
}
```

所有 Bash 命令都不再询问，但 Edit、Write 等其它工具仍会走正常权限流程。如果想连文件编辑也一起放开：

```json
{
  "permissions": {
    "allow": [
      "Bash",
      "Edit",
      "Write"
    ]
  }
}
```

#### 方式二：设置 `defaultMode` 为 `acceptEdits`

```json
{
  "permissions": {
    "defaultMode": "acceptEdits"
  }
}
```

自动接受文件编辑操作，但 Bash 命令仍需确认（相对温和的自动化）。

#### 最后推荐

```json
{
  "permissions": {
    "allow": ["Bash"],
    "defaultMode": "acceptEdits"
  }
}
```

这样常用命令和文件编辑都不打断，真正危险的操作（比如 `git push --force`）可以额外加进 `ask` 或 `deny` 列表兜底。

### Claude Code约束规范CLAUDE.md

规范类约束（不是权限、也不是流程节点），应该和 OpenSpec 约束一样，写入 **`CLAUDE.md`**，但建议单独归类，不要和流程类约束混在一起，便于后续维护。

用户级 `~/.claude/CLAUDE.md` 与项目级 `CLAUDE.md` 的核心关系：**叠加合并，不是互斥覆盖**

两者不是"谁覆盖谁"的替代关系，而是**全部加载、内容拼接叠加**进上下文，同时生效。所有层级都会累加贡献内容，更具体的指令优先，项目级覆盖用户级（这里"覆盖"指的是**规则冲突时**项目级说了算，而不是项目级存在时用户级就不加载）。

完整层级结构（从全局到局部）

```
1. 企业托管策略（Managed Policy）  ← 最高优先级，个人无法覆盖
   /Library/Application Support/ClaudeCode/managed-settings.json (macOS)
   /etc/claude-code/managed-settings.json (Linux)

2. 用户级 CLAUDE.md
   ~/.claude/CLAUDE.md              ← 你个人所有项目通用的偏好

3. 项目级 CLAUDE.md
   <项目根目录>/CLAUDE.md            ← 团队共享，建议提交 git

4. 项目本地 CLAUDE.md
   <项目根目录>/CLAUDE.local.md     ← 个人在这个项目里的偏好，不提交

5. 子目录 CLAUDE.md
   <项目>/backend/CLAUDE.md         ← 按需加载，只在访问该目录文件时生效
```

| 规则                 | 说明                                                         |
| -------------------- | ------------------------------------------------------------ |
| **全部加载**         | 不管有几层，Claude Code 启动时会把能找到的 CLAUDE.md 全部读入并拼接 |
| **冲突时项目级优先** | < cite index="41-1">当用户级说用 4 空格缩进、项目级说用 2 空格缩进时，最终生效的是项目级的 2 空格。越贴近当前项目的规矩，越应该压过笼统的全局偏好 |
| **不冲突则都生效**   | 用户级说"用中文回复"，项目级没提这个 → 中文回复依然生效，两者是互补关系，不是二选一 |

#### 推荐结构

```
项目根目录/
├── CLAUDE.md                    # 主文件，引用其他规范文件
├── .claude/
│   └── rules/
│       ├── openspec-workflow.md # 之前的 OpenSpec 流程约束
│       └── spring-conventions.md # 本次的 SpringBoot 代码规范
```

#### 方式一：直接写入 `CLAUDE.md`（简单场景推荐）

```markdown
# 项目编码规范

## SpringBoot 接口约束

- **Controller** 保持薄：只做接口定义、`@Valid` 校验触发、调用 service，不写业务逻辑
- 接口 URL 使用**全路径**（如 `/api/v1/users`），不要用类级别 `@RequestMapping` 再拼方法级别路径
- Service 层负责业务逻辑，Controller 不直接操作 Repository/Mapper
- 统一使用 `ResponseEntity<R<T>>` 或项目统一的响应包装类返回结果
- 参数校验统一使用 `@Valid` + Bean Validation 注解，不在方法体内手写 if 校验

（继续补充团队约定的其他规范...）
```

#### 方式二：拆分为独立规范文件 + 引用（团队协作、规范较多时推荐）

`CLAUDE.md` 主文件里引用：

```markdown
# 项目说明

## 最高优先级工作流约束

任何编码规范都不能绕过 OpenSpec 人工确认流程。

即使用户要求直接修改代码，只要当前变更属于 OpenSpec 管理范围，也必须先检查 `proposal.md`、`design.md`、`tasks.md`。如果这些文档需要新增或修改，完成文档后必须停止，等待用户明确确认，禁止自动继续编码。

## SpringBoot编码规范
@.claude/rules/springboot-conventions.md

## OpenSpec 工作流
@.claude/rules/openspec-workflow.md
```

`@path/to/file.md`，支持相对路径和绝对路径，相对路径解析是相对于**当前 CLAUDE.md 所在目录**解析。

重要坑点：`@import` 语法支持 `~/` 路径，比如 `@~/.claude/team-preferences.md` 会解析到每个开发者自己的家目录，这会造成和用户级 `CLAUDE.md` 一样的"在我机器上能跑"的陷阱——已经创建过这个文件的老成员能正常工作，但从没创建过这个文件的新人，这个导入会静默解析为空。**所以团队共享的规范文件必须放在项目仓库内**（如 `.claude/rules/spring-conventions.md`），不要用 `~/` 家目录路径，否则新同事拉下代码后规范文件是空的还不会报错。

##### `.claude/rules/springboot-conventions.md`

~~~markdown
# SpringBoot 项目编码规范

## Controller 层规范

### 基本原则

- Controller 必须保持轻量、简洁。
- Controller 只负责：
  - 定义 HTTP 接口。
  - 接收和绑定请求参数。
  - 使用 `@Valid` 或 `@Validated` 触发参数校验。
  - 调用 Service / Application 层。
  - 返回接口响应结果。

- 禁止在 Controller 中编写业务逻辑。
- 禁止在 Controller 中直接访问数据库。
- 禁止 Controller 直接调用 Mapper、Repository、DAO。
- 禁止 Controller 直接操作 Redis、MQ、ES 等基础设施组件。
- 禁止在 Controller 中编写事务逻辑。
- 禁止在 Controller 中进行复杂的数据转换、状态流转、权限判断等业务处理。
- 所有业务逻辑必须放在 Service / Application 层。

### URL 路径
- 使用全路径注解（如 `@GetMapping("/api/v1/users/{id}")`）。
- 每个接口必须在方法级注解中直接声明完整 URL。
- 禁止使用类级别的 `@RequestMapping` 定义公共路径前缀。
- `@GetMapping`、`@PostMapping`、`@PutMapping`、`@PatchMapping`、`@DeleteMapping` 必须直接写完整接口路径。

### 职责边界
- 只做：接口定义、参数接收、`@Valid` 触发校验、调用 Service、返回结果
- 不做：业务逻辑判断、直接操作数据库、复杂数据转换（应在 Service 或 Converter 完成）

### 参数校验规范
- 统一用 `@Valid` + Bean Validation 注解，不手写 if 校验
- 校验失败统一由全局异常处理器（`@ControllerAdvice`）捕获处理，Controller 不写 try-catch
- 请求 DTO 优先使用 Jakarta Bean Validation。
- Spring Boot 3.x 使用 jakarta.validation.。
- @RequestBody DTO 默认使用 @Valid 触发校验。
- 需要分组校验或方法参数校验时使用 @Validated。
- 格式、长度、非空、范围等基础校验放在 DTO 中。
- 涉及数据库状态、业务规则、权限、唯一性等业务校验必须放在 Service 层。

### 返回值
- 统一使用项目响应包装类（如 `Result<T>` / `ApiResponse<T>`），不允许直接返回裸对象或 `ResponseEntity` 混用

### 依赖注入
- Controller 只允许注入 Service 层接口，禁止注入 Mapper/Repository

### 修改代码时的约束

当生成、修改或重构 Spring Boot Controller 时，必须遵守以下规则：
- 新增接口时，必须直接在方法级 Mapping 注解中写完整 URL。
- 不允许新增类级别 @RequestMapping。
- 如果 Controller 中存在业务逻辑，优先将其迁移到 Service / Application 层。
- 如果 Controller 直接调用 Mapper、Repository、DAO，应改为调用 Service。
- Controller 不负责事务控制。
- Controller 不负责业务状态判断。
- Controller 不负责复杂对象转换；复杂转换应放在合适的转换层、Assembler、Converter 或 Service 中。
- 修改已有代码时，应尽量遵循现有项目结构，但现有实现与本规范冲突时，以本规范为优先。
- 如果修改会导致较大范围的架构调整，应先说明影响范围，再进行修改。

### Springdoc 接口文档（条件规则）

当项目中存在 Springdoc / OpenAPI 相关依赖或配置时，新增或修改 Controller 接口必须同步维护接口文档描述。

**先检查项目依赖（pom.xml / build.gradle）中是否引入了 springdoc-openapi 相关依赖**，如果项目中存在以下任意情况，可视为已使用 Springdoc / OpenAPI：

- `springdoc-openapi-starter-webmvc-ui`
- `springdoc-openapi-starter-webflux-ui`
- `springdoc-openapi-ui`
- `io.swagger.v3.oas.annotations.*`
- 已存在 `@Operation`、`@Parameter`、`@Schema` 等 OpenAPI 注解
- 项目已有 Springdoc 相关配置

**如果项目存在 Springdoc / OpenAPI，新增或修改每个 Controller 接口时必须同步维护 `@Operation`、`@Parameter`、`@Schema` 等接口文档信息，确保接口描述、参数说明与实际实现一致。**

**如果项目存在 springdoc 依赖，则每个 Controller 接口方法必须补充以下文档注解：**

#### 类级别
- 使用 `@Tag(name = "xxx模块", description = "xxx模块接口")` 标注接口分组

#### 方法级别
- 使用 `@Operation(summary = "接口简述", description = "详细说明（可选）")` 描述接口用途
- 每个请求参数（`@RequestParam`、`@PathVariable`）使用 `@Parameter(description = "参数说明", required = true/false)` 标注
- 请求体参数（`@RequestBody`）对应的 DTO 类，字段上使用 `@Schema(description = "字段说明", example = "示例值")` 标注
- 返回值需在 `@Operation` 或方法注释中说明返回结构含义（如有多种响应状态，使用 `@ApiResponses` 补充说明不同状态码含义）

#### 示例

```java
@Tag(name = "用户管理", description = "用户信息增删改查接口")
@RestController
public class UserController {

    @Operation(summary = "根据ID查询用户", description = "根据用户ID查询用户详细信息")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "查询成功"),
        @ApiResponse(responseCode = "404", description = "用户不存在")
    })
    @GetMapping("/api/v1/users/{id}")
    public Result<UserVO> get(
        @Parameter(description = "用户ID", required = true) 
        @PathVariable Long id) {
        return Result.success(userService.get(id));
    }

    @Operation(summary = "创建用户")
    @PostMapping("/api/v1/users")
    public Result<UserVO> create(
        @Valid @RequestBody UserCreateRequest req) {
        return Result.success(userService.create(req));
    }
}

// DTO 字段文档
public class UserCreateRequest {
    @Schema(description = "用户名", example = "zhangsan", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank
    private String username;

    @Schema(description = "邮箱地址", example = "zhangsan@example.com")
    @Email
    private String email;
}
```

#### 强制要求
- ❌ 存在 springdoc 依赖但接口没有 `@Operation` / `@Tag` 注解 → 视为不合规，必须补充
- ❌ 参数含义不明确（如枚举值、格式要求）却没有用 `description` 说明 → 必须补充
- ✅ 如果项目未引入 springdoc 依赖，则跳过此项规则，不强制要求文档注解

#### 返回值
- 统一使用项目响应包装类（如 `Result<T>`），不允许直接返回裸对象

## Service 层
（补充规范）

## 统一响应格式
（补充规范）

~~~

##### `.claude/rules/openspec-workflow.md`

**工作流级约束**，优先级应该高于具体编码风格。还可以在 `CLAUDE.md` 文件开头再加一条总规则强化：

```markdown
## 强制要求
- 任何编码规范都不能绕过 OpenSpec 人工确认流程。
- 涉及编码、修改、重构、修复前，必须先读取并遵守 OpenSpec 工作流规范。
- 涉及 Java / Spring Boot 代码时，必须读取并遵守 Spring Boot 开发规范。
- 如果规则之间发生冲突，以 OpenSpec 工作流约束优先于编码风格约束。
- 即使用户要求直接修改代码，只要当前变更属于 OpenSpec 管理范围，也必须先检查 `proposal.md`、`design.md`、`tasks.md`。如果这些文档需要新增或修改，完成文档后必须停止，等待用户明确确认，禁止自动继续编码。
```

~~~markdown
## OpenSpec 规范流程

在进行任何编码、新增功能、修改代码、重构、修复缺陷之前，必须先检查项目中的 OpenSpec 规范流程文档。

需要重点检查文档： `proposal.md`/`design.md`/`tasks.md`

### 编码前检查要求

在开始编码或修改代码前，必须完成以下检查：

1. 检查当前需求是否存在对应的 OpenSpec 规范文档。
2. 检查 `proposal.md` 是否已经描述当前需求的目标、范围和变更内容。
3. 检查 `design.md` 是否与当前项目实际架构、代码结构、技术选型保持一致。
4. 检查 `tasks.md` 是否与当前准备执行的开发任务保持一致。
5. 检查 OpenSpec 文档描述与当前项目实际代码是否存在明显偏差。
6. 检查 `proposal.md`、`design.md`、`tasks.md` 三者之间是否相互一致。
7. 如果代码已经发生变化，需要判断 OpenSpec 文档是否已经同步更新。

如果发现 OpenSpec 文档缺失、内容不完整、相互冲突或与当前项目代码不一致：

* 禁止直接开始编码。
* 应先指出具体不一致之处。
* 应优先补充或修改对应的 OpenSpec 文档。
* 文档修改完成后，必须停止后续编码流程。

## OpenSpec 文档确认机制

OpenSpec 规范文档属于需要人工确认的开发依据。

当任意  `proposal.md`/`design.md`/`tasks.md` 文档被新建或修改后，必须等待用户手动确认。

在用户明确确认之前：

* 禁止根据 OpenSpec 文档自动开始编码。
* 禁止自动执行 `tasks.md` 中的任务。
* 禁止因为 `proposal.md`、`design.md`、`tasks.md` 已经完成就继续修改业务代码。
* 禁止自动进入下一阶段开发流程。
* 禁止将“文档已完成”视为“用户已批准执行”。

必须明确区分：

1. OpenSpec 文档编写阶段。
2. 用户人工确认阶段。
3. 编码执行阶段。

三个阶段禁止自动串联执行。

## 必须停止并等待确认的情况

完成 OpenSpec 文档编写或修改后，应立即停止，并向用户说明：

* 本次新增或修改了哪些 OpenSpec 文档。
* 文档中的主要设计方案。
* 与当前项目代码的同步情况。
* 是否存在风险、冲突或需要特别确认的内容。

然后等待用户明确给出类似以下指令：

* `确认`
* `确认执行`
* `可以开始编码`
* `按 tasks.md 执行`
* `开始实现`
* 其他明确表示批准进入编码阶段的指令

只有收到明确的人工确认后，才允许开始修改业务代码。

以下内容不能视为人工确认：

* 用户要求“先看看怎么改”。
* 用户要求“生成方案”。
* 用户要求“完善 proposal”。
* 用户要求“完善 design”。
* 用户要求“生成 tasks”。
* OpenSpec 文档已经成功生成。
* Codex 自己判断方案合理。
* Codex 自己认为任务已经足够明确。

## 禁止自动执行 OpenSpec Tasks

`tasks.md` 仅作为开发任务计划和执行依据，不代表已经获得执行授权。

即使 `tasks.md` 中已经列出了完整任务，例如：

```md
- [ ] 新增 UserService
- [ ] 新增用户创建接口
- [ ] 增加 DTO 参数校验
- [ ] 增加数据库迁移脚本
- [ ] 编写单元测试
```

也禁止在完成 `tasks.md` 后自动开始执行这些任务。

正确流程必须是：

```text
理解用户需求
    ↓
检查现有 OpenSpec 文档
    ↓
检查 OpenSpec 与当前项目代码是否一致
    ↓
新增 / 修改 proposal.md
    ↓
新增 / 修改 design.md
    ↓
新增 / 修改 tasks.md
    ↓
停止
    ↓
向用户汇报 OpenSpec 变更
    ↓
等待用户手动确认
    ↓
用户明确批准
    ↓
再次检查 OpenSpec 与项目当前状态
    ↓
按照已确认的 tasks.md 开始编码
```

禁止以下流程：

```text
需求
 ↓
生成 proposal.md
 ↓
生成 design.md
 ↓
生成 tasks.md
 ↓
自动开始编码
```

## 编码执行阶段要求

用户明确批准编码后，在真正修改代码之前仍需要再次检查：

1. `proposal.md` 是否仍然适用于当前需求。
2. `design.md` 是否仍然与当前代码结构一致。
3. `tasks.md` 是否仍然是最新版本。
4. 用户确认之后，项目代码是否发生了新的变化。
5. 是否存在其他人提交的代码导致设计或任务已经失效。

如果确认后项目状态发生明显变化，导致 OpenSpec 文档已经不同步：

* 暂停编码。
* 说明变化内容。
* 更新 OpenSpec 文档。
* 更新完成后再次等待人工确认。

禁止基于过期的 OpenSpec 文档继续开发。

## 修改范围约束

编码阶段只能执行已经人工确认的 OpenSpec 范围。

* 不得擅自扩大 `proposal.md` 定义的需求范围。
* 不得擅自修改 `design.md` 已确认的核心设计。
* 不得添加 `tasks.md` 未包含的大规模重构任务。
* 不得因为“顺便优化”而修改无关代码。
* 如果实现过程中发现必须改变设计，应停止编码并先更新 OpenSpec 文档。
* OpenSpec 文档变更后，必须重新等待用户确认。

## Codex 强制行为规则

当用户要求“实现”“修改”“开发”“修复”“重构”等代码变更时：

1. 首先检查 OpenSpec 文档。
2. 不允许直接开始修改代码。
3. OpenSpec 不完整时，先处理 OpenSpec。
4. OpenSpec 与代码不一致时，先同步 OpenSpec。
5. OpenSpec 文档发生修改后，立即停止。
6. 等待用户人工确认。
7. 没有明确确认时，绝不自动执行 `tasks.md`。
8. 只有人工确认后才能进入编码阶段。
9. 编码只能执行已确认范围内的任务。
10. 需要变更已确认设计时，重新进入 OpenSpec 文档阶段并再次等待确认。

### 核心原则

> OpenSpec 文档完成不等于允许编码。

> `tasks.md` 是任务计划，不是执行授权。

> OpenSpec 文档发生任何影响实现方案的修改后，必须由用户人工确认。

> Codex 禁止自行批准 OpenSpec，禁止自动从文档阶段进入编码阶段。

~~~

Claude Code 读取 `CLAUDE.md` 时，如果引用了外部文件路径，通常需要明确提示或使用 `@` 引用语法让其加载完整内容（不同版本行为略有差异，建议用 `/init` 或直接在对话中确认 Claude 是否已读取该文件）。

------

#### 生效范围对照

| 位置                        | 生效范围           | 是否建议提交 git           |
| --------------------------- | ------------------ | -------------------------- |
| `~/.claude/CLAUDE.md`       | 你本机所有项目     | 不提交（本机个人习惯）     |
| `<项目>/CLAUDE.md`          | 仅该项目，团队共享 | **建议提交**，团队统一规范 |
| `<项目>/.claude/rules/*.md` | 仅该项目，按需引用 | 建议提交                   |

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

### Claude Code 安装 Word 文档处理能力（docx Skill）指南

Claude Code 官方提供了处理 Word / Excel / PPT / PDF 文档的技能包（`document-skills`），其中 `docx` 部分专门用于创建、编辑、分析 Word 文档，支持目录、页眉页脚、表格、修订追踪、批注管理等专业排版能力。

安装方式分为两种：**插件市场安装（官方推荐）** 和 **离线手动安装**。若插件市场方式遇到问题（如 Windows 下常见的权限报错），可直接使用离线方式。

------

#### 方式一：插件市场安装（官方推荐）

##### 1. 添加官方 Skills 仓库为 marketplace

```
/plugin marketplace add anthropics/skills
```

##### 2. 安装 document-skills 插件

```
/plugin install document-skills@anthropic-agent-skills
```

> 注意格式：`插件名@marketplace名`，中间用 `@` 连接，不能有空格。

##### 3. 激活插件（如提示需要）

若安装完成后提示 `Run /reload-plugins to activate.`，执行：

```
/reload-plugins
```

##### 4. 验证安装

```
/plugin marketplace list   # 确认 anthropic-agent-skills 已注册
/plugin list               # 确认 document-skills 已安装
```

##### 方式一的常见报错与排查（Windows 环境高发）

###### 报错：`EPERM: operation not permitted, rename ...`

```
Error: Failed to finalize marketplace cache. Please manually delete the directory at
C:\Users\<用户名>\.claude\plugins\marketplaces\anthropic-agent-skills if it exists and try again.
```

**原因**：Claude Code 先将仓库克隆到临时目录，最后重命名为正式目录名时被 Windows 拒绝。常见诱因：杀毒软件/Defender 实时扫描锁定新文件、云同步软件（OneDrive等）监控冲突、Node.js 在 Windows 下的 rename 操作对权限更敏感。

**排查步骤**：

1. 完全退出所有 Claude Code 进程/窗口

2. 手动删除残留目录（PowerShell，非管理员即可尝试）：

   ```powershell
   Remove-Item -Recurse -Force "C:\Users\<用户名>\.claude\plugins\marketplaces\anthropic-agent-skills" -ErrorAction SilentlyContinueRemove-Item -Recurse -Force "C:\Users\<用户名>\.claude\plugins\marketplaces\anthropics-skills" -ErrorAction SilentlyContinue
   ```

3. 确认删除干净：

   ```powershell
   dir "C:\Users\<用户名>\.claude\plugins\marketplaces\"
   ```

4. 若普通删除失败，以管理员身份打开 PowerShell 强制处理：

   ```powershell
   takeown /f "C:\Users\<用户名>\.claude\plugins\marketplaces\anthropic-agent-skills" /r /d yicacls "C:\Users\<用户名>\.claude\plugins\marketplaces\anthropic-agent-skills" /grant Administrators:F /tRemove-Item -Recurse -Force "C:\Users\<用户名>\.claude\plugins\marketplaces\anthropic-agent-skills"
   ```

5. 重新执行 `/plugin marketplace add anthropics/skills`

**若重试多次仍反复出现同样报错**：说明问题不是残留目录，而是运行时实时冲突（安全软件/同步软件持续锁定新建文件），建议直接改用**方式二：离线安装**，无需再纠结这个问题。

------

#### 方式二：离线手动安装（绕开插件系统，最可靠）

原理：`/plugin install` 本质就是把仓库中的 Skill 文件夹放到 Claude Code 能扫描到的目录下。手动完成同样的操作即可达到相同效果，且不经过容易在 Windows 上出问题的 marketplace 自动重命名流程。

##### 1. 手动克隆官方仓库到临时目录

不要克隆到 `.claude` 目录内，避免触发同样的文件锁定问题：

```powershell
git clone https://github.com/anthropics/skills.git C:\temp\anthropic-skills
```

##### 2. 查看仓库内实际的 skill 目录结构

```powershell
dir C:\temp\anthropic-skills\skills
```

确认 `docx`（以及如需要的 `pdf`、`pptx`、`xlsx`）文件夹的准确名称。

##### 3. 创建个人 Skills 目录（如不存在）

```powershell
mkdir "C:\Users\<用户名>\.claude\skills" -Force
```

##### 4. 复制所需技能文件夹

```powershell
# 仅 Word 处理能力
Copy-Item -Recurse "C:\temp\anthropic-skills\skills\docx" "C:\Users\<用户名>\.claude\skills\docx"

# 如需一并安装 PDF / PPT / Excel 处理能力
Copy-Item -Recurse "C:\temp\anthropic-skills\skills\pdf"  "C:\Users\<用户名>\.claude\skills\pdf"
Copy-Item -Recurse "C:\temp\anthropic-skills\skills\pptx" "C:\Users\<用户名>\.claude\skills\pptx"
Copy-Item -Recurse "C:\temp\anthropic-skills\skills\xlsx" "C:\Users\<用户名>\.claude\skills\xlsx"
```

##### 5. 确认目录结构

```powershell
dir "C:\Users\<用户名>\.claude\skills"
```

每个技能文件夹下应包含一个 `SKILL.md` 文件（Claude Code 识别 Skill 的核心标识文件）。

##### 6. 重新打开 Claude Code 会话验证

个人 Skills 目录下的内容会被自动识别加载，无需额外命令，直接测试：

```
帮我创建一个测试用的 Word 文档，标题是"测试文档"
```

若能正常生成并提供 `.docx` 文件下载，说明安装成功。

------

#### 两种方式对比

| 对比项           | 方式一：插件市场安装                   | 方式二：离线手动安装                        |
| ---------------- | -------------------------------------- | ------------------------------------------- |
| 操作复杂度       | 低（两条命令）                         | 中（需手动克隆、复制）                      |
| Windows 权限问题 | 较易触发 EPERM 报错                    | 不涉及 marketplace 重命名逻辑，基本不受影响 |
| 后续更新         | `/plugin` 系统统一管理                 | 需手动 `git pull` 后重新复制覆盖            |
| 适用场景         | 网络环境正常、Windows 权限无异常的机器 | 插件市场方式反复失败时的可靠替代方案        |

------

#### 安装完成后的使用方式

无需记忆任何命令，直接用自然语言描述需求，Claude Code 会自动匹配并调用对应 Skill：

```
帮我生成一份项目验收报告，要求有目录、页眉页脚，导出成 Word

把这份文档里所有的"甲方"批量替换成"乙方"

检查这份合同文档里的修订记录，帮我总结审阅意见
```

##### docx Skill 支持的核心能力

- 创建 / 读取 / 编辑 `.docx` 文件
- 目录（TOC）自动生成
- 页眉页脚、表格、超链接、脚注
- 修订追踪（Track Changes）与批注管理
- 图片插入、多栏布局
- 旧版 `.doc` 转 `.docx`




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

### Codex约束规范

Codex 原生会自动读取 `~/codex/AGENTS.md` / `.codex/AGENTS.md` 

用户级文件列表

```markdown
~/.codex/
├── AGENTS.md
└── rules/
    ├── openspec-workflow.md
    └── springboot-preferences.md
```

`AGENTS.md` 保持很短：

```
# 全局开发规则

执行任务前，必须遵守以下规则文件：

- OpenSpec 工作流规范：`~/.codex/rules/openspec-workflow.md`
- Spring Boot 开发规范：`~/.codex/rules/springboot-preferences.md`

## 强制要求

- 涉及编码、修改、重构、修复前，必须先读取并遵守 OpenSpec 工作流规范。
- 涉及 Java / Spring Boot 代码时，必须读取并遵守 Spring Boot 开发规范。
- 如果规则之间发生冲突，以 OpenSpec 工作流约束优先于编码风格约束。
```

## 本地大模型安装

### ollama

[ollama 大模型部署工具官网](https://ollama.com/)， [ollama 下载链接](https://ollama.com/download)

#### ollama安装

ollama Windows 安装指定安装目录，在 ollama 下载好的安装软件 `OllamaSetup.exe` 目录执行下面命令。

```cmd
OllamaSetup.exe /DIR="D:\software\ollama"
```

[llm 开源大语言模型搜索链接](https://ollama.com/search)

#### ollama模型管理

下载指定版本模型

```cmd
# 只下载，不运行
ollama pull qwen3.5:4b

# 下载+直接运行(如果本地没有会自动先下载)
ollama run qwen3.5:9b
```

指定版本/参数规模的写法，模型名格式是 `模型名:标签`，标签通常代表参数规模或量化精度：

```bash
# 千问 4B参数版本
ollama pull qwen3.5:4b
```

查看本地已下载的模型

```bash
ollama list
```

删除不需要的模型(释放硬盘空间)

```bash
ollama rm qwen2.5:14b
```

ollama运行模型情况查询

```powershell
# 确认GPU能被正常识别
nvidia-smi

# 看当前ollama加载的模型运行在GPU还是CPU上
ollama ps

# NAME          ID              SIZE      PROCESSOR    CONTEXT    UNTIL
# qwen3.5:4b    2a654d98e6fb    3.1 GB    100% GPU     4096       3 minutes from now
```

