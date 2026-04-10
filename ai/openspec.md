## openspec规范

涉及到的规范文档：

```
openspec/changes/<变更名>/
├── proposal.md          # 为什么做、做什么
├── tasks.md             # 如何做（任务清单）
├── design.md            # 技术设计（可选）
└── specs/               # 规范增量
    └── <能力名>/
        └── spec.md
```

```
You: /opsx:propose add-dark-mode
AI:  Created openspec/changes/add-dark-mode/
     ✓ proposal.md  — why we're doing this, what's changing
     ✓ specs/       — requirements and scenarios
     ✓ design.md    — technical approach
     ✓ tasks.md     — implementation checklist
     Ready for implementation!

You: /opsx:apply
AI:  Implementing tasks...
     ✓ 1.1 Add theme context provider
     ✓ 1.2 Create toggle component
     ✓ 2.1 Add CSS variables
     ✓ 2.2 Wire up localStorage
     All tasks complete!

You: /opsx:archive
AI:  Archived to openspec/changes/archive/2025-01-23-add-dark-mode/
     Specs updated. Ready for the next feature.
```



### proposal.md

它的核心作用就是清晰地阐述“为什么要进行这次变更”和“这次变更具体会影响到哪些方面”。这个文件是 AI 和协作者理解变更意图的首要参考。

```markdown
## Why (为什么？)

## What Changes (变更内容)

## Impact （影响范围）

```

`design.md` 是一个可选但非常重要的文件。它不是一个简单的格式要求，而是一个**决策信号**——只有当变更足够复杂，需要提前进行技术决策时，才需要创建它，对于简单的功能添加或 Bug 修复，**应该跳过 `design.md` 文件**，以保持流程的轻量级。

#### 示例

```markdown
## Why

业务系统需要对敏感数据进行非对称加密传输与数字签名，现有代码中 RSA 操作散落各处，算法参数不统一，导致不同模块或不同平台生成的密文、签名无法互相验证。引入统一的 `RsaUtils` 工具类，锁定算法参数，确保任意平台生成的结果可互操作。

## What Changes

- 新增 `RsaUtils` 工具类，封装 RSA 密钥生成、加密、解密、签名、验签五项能力
- 所有操作锁定固定算法参数（密钥长度、填充方案、签名算法、编码格式），保证跨平台结果一致
- 密钥以 Base64 编码的 PKCS#8（私钥）/ X.509（公钥）标准格式输入输出，兼容 OpenSSL、各语言 SDK

## Capabilities

### New Capabilities

- `rsa-key-generation`：生成指定位长（默认 2048 位）的 RSA 密钥对，以标准格式输出
- `rsa-encrypt-decrypt`：使用公钥加密、私钥解密，填充方案锁定为 `RSA/ECB/OAEPWithSHA-256AndMGF1Padding`
- `rsa-sign-verify`：使用私钥签名、公钥验签，算法锁定为 `SHA256withRSA`

### Modified Capabilities

（无）

## Impact

- 新增工具类文件，不修改现有代码
- 依赖：Java 标准库 `java.security`（无需额外依赖）
- 运行时要求：Java 11+
- 跨平台一致性约束：
  - 密钥格式：PKCS#8 私钥 / X.509 公钥，Base64 编码（标准字母表，无换行）
  - 加密填充：`OAEPWithSHA-256AndMGF1Padding`（确定性哈希，避免 PKCS#1 v1.5 不一致风险）
  - 签名算法：`SHA256withRSA`（PKCS#1 v1.5 签名，各平台实现一致）
  - 字符编码：明文统一使用 UTF-8 转字节

```

### design.md

`design.md` 是 OpenSpec 变更提案中的**可选文件**，用于记录复杂变更的**技术设计决策**。它不是必需的，但当变更涉及重大架构调整、复杂技术选型或多个系统交互时，强烈建议创建。

**不需要创建的情况：**

- 简单的 CRUD 功能添加
- Bug 修复
- UI 文案调整
- 单模块内的小功能增强
- 配置参数调整

```markdown
## Context
[背景信息、当前状态、约束条件]

## Goals / Non-Goals
- **Goals**: [本次设计要达成的目标]
- **Non-Goals**: [明确不做什么，控制范围]

## Technical Decisions
### Decision 1: [技术决策名称]
- **选择**: [选择了什么]
- **理由**: [为什么这么选]
- **替代方案**: [考虑过但没选的方案及原因]

### Decision 2: [另一个决策]
...

## Architecture
[架构图描述、组件交互、数据流]

## Risks / Trade-offs
- **风险1**: [描述] → **缓解措施**: [如何处理]
- **权衡1**: [选择了A放弃了B] → **影响**: [带来的后果]

## Migration Plan
[迁移步骤、回滚策略、数据迁移方案]

## Open Questions
- [ ] 待解决问题1
- [ ] 待解决问题2
```

1. **保持轻量**：只在必要时创建，不要过度设计
2. **聚焦决策**：记录"为什么"，而不是"怎么做"
3. **诚实评估**：明确列出风险和权衡
4. **保持更新**：如果设计变更，及时更新文档
5. **引用规范**：关联到 `spec.md` 中的具体需求

注意：`design.md` 的目的是**沟通复杂的技术决策**，而不是写详细的实现指南。

#### 示例

```markdown
## Context

项目使用 Java 11+，需要跨平台（不同 JVM 版本、不同语言 SDK、不同 AI 平台生成的代码）进行 RSA 加解密与签名互操作。核心约束：**相同输入在任意平台产生可互相验证的输出**。Java 标准库 `java.security` 已内置完整 RSA 支持，无需引入第三方加密库。

## Goals / Non-Goals

**Goals:**
- 锁定全部算法参数，保证跨平台输出可互操作
- 密钥以通用标准格式（PKCS#8 / X.509 + Base64）导入导出，兼容 OpenSSL、Python cryptography、Node.js crypto 等
- 提供密钥生成、加密、解密、签名、验签五个独立静态方法
- 工具类本身无状态，线程安全

**Non-Goals:**
- 不封装对称加密（AES 等）
- 不支持流式加密（大文件分块）
- 不提供密钥存储 / 密钥管理
- 不支持 PEM 文件头尾行解析（调用方负责去除 `-----BEGIN...-----` 行）

## Decisions

### 决策 1：加密填充方案 — `OAEPWithSHA-256AndMGF1Padding`

**选择**：`RSA/ECB/OAEPWithSHA-256AndMGF1Padding`，MGF1 哈希同为 SHA-256

**理由**：
- PKCS#1 v1.5（`RSA/ECB/PKCS1Padding`）存在 Bleichenbacher 攻击漏洞，且因填充随机字节长度在不同实现中可能有差异，互操作性较弱。
- OAEP 是当前推荐标准（NIST SP 800-131A），各主流语言均有成熟实现。
- **MGF1 哈希必须显式指定为 SHA-256**（Java 默认 MGF1 使用 SHA-1，与其他平台默认值不一致是常见跨平台失败原因）。

**跨平台参数对照：**

| 平台 | 对应参数 |
|---|---|
| Java | `OAEPWithSHA-256AndMGF1Padding` + `OAEPParameterSpec(SHA-256, MGF1, MGF1ParameterSpec.SHA256, ...)` |
| Python | `padding.OAEP(mgf=padding.MGF1(SHA256()), algorithm=SHA256())` |
| Node.js | `crypto.privateDecrypt({ key, oaepHash: 'sha256' }, ...)` |
| OpenSSL | `rsautl -oaep` (默认 SHA-1，需改用 `pkeyutl -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -pkeyopt rsa_mgf1_md:sha256`) |

**备选方案**：PKCS#1 v1.5 — 有安全漏洞，跨平台随机填充有细微差异，不选。

---

### 决策 2：签名算法 — `SHA256withRSA`

**选择**：`SHA256withRSA`（即 PKCS#1 v1.5 签名 + SHA-256 摘要）

**理由**：
- 签名场景中 PKCS#1 v1.5 签名（`RSASSA-PKCS1-v1_5`）与 PSS（`RSASSA-PSS`）均安全，但各平台对 PSS salt 长度默认值不统一，易导致验签失败。
- `SHA256withRSA` 是各平台（Java / Python / Node.js / Go / OpenSSL）实现最统一的签名算法，默认参数无歧义。

**备选方案**：`SHA256withRSA/PSS` — PSS salt 长度在不同平台默认值不同（Java 默认 -1 自适应，Python 默认等于摘要长度），跨平台需显式对齐，复杂度高，不选。

---

### 决策 3：密钥格式 — PKCS#8 私钥 / X.509 公钥 + 标准 Base64

**选择**：
- 私钥：`PKCS8EncodedKeySpec`（DER 编码后 Base64）
- 公钥：`X509EncodedKeySpec`（DER 编码后 Base64）
- Base64：标准字母表（`Base64.getEncoder()`），**不换行**，不使用 URL-safe 变体

**理由**：PKCS#8 / X.509 是 Java `KeyFactory` 的原生格式，也是 OpenSSL `pkcs8` / `pubkey` 命令的标准输出。PKCS#1 格式（仅含模数和指数）需要 BouncyCastle 等额外依赖才能在 Java 中解析，不选。

---

### 决策 4：密钥长度默认值 — 2048 位

**选择**：默认 2048 位，方法签名允许调用方指定（支持 2048 / 3072 / 4096）

**理由**：2048 位满足当前安全基线（NIST 至 2030 年前有效），性能合理；4096 位加解密耗时约为 2048 的 4 倍，适合高安全场景按需选择。

---

### 决策 5：`OAEPParameterSpec` 显式传入

**选择**：`Cipher.init()` 时显式传入 `OAEPParameterSpec`，指定 `mgfHash = SHA-256`

**理由**：Java 默认 `OAEPWithSHA-256AndMGF1Padding` 的 MGF1 内部哈希为 SHA-1（JDK 实现细节），不显式指定会导致与其他平台的互操作失败。这是跨平台 RSA-OAEP 最常见的坑。

## Risks / Trade-offs

- **[风险] OAEP 加密结果每次不同** → 这是 OAEP 的设计特性（随机种子），不影响解密正确性，但无法用于"比较两次加密结果是否相同"的场景 → 文档明确说明
- **[风险] 单次可加密明文长度有限** → RSA-2048 + OAEP-SHA256 最大明文为 190 字节；超长数据须分块或改用混合加密（RSA 加密 AES 密钥） → 工具类检测超长时抛出明确异常
- **[风险] JDK 版本差异** → JDK 8u161+ 已无加密长度限制（移除 JCE 无限强度限制），Java 11+ 无此问题 → 要求 Java 11+，文档注明
- **[权衡] 不支持 PEM 头尾** → 调用方需自行 strip，略增使用负担，但避免引入 PEM 解析复杂度和 BouncyCastle 依赖

```

### spec.md

在 `changes/<变更名>/specs/` 中的 `spec.md` 使用**操作标记**来表示修改：

```markdown
## Purpose
[一段文字描述：这个能力是什么、为什么需要它]

## Requirements
### Requirement: [需求名称]
系统 SHALL/MUST [具体行为描述]

#### Scenario: [场景名称]
- **WHEN** [触发条件]
- **THEN** [预期结果]
- **AND** [额外条件]（可选）

### Requirement: [另一个需求]
...
```

关键规则

1. **`## Purpose`** - 必须有，至少 50 个字符
2. **`## Requirements`** - 必须有，且只能有一个
3. **`### Requirement:`** - 必须以这开头，冒号后跟需求名称
4. **`SHALL` 或 `MUST`** - 每个需求正文必须包含其中一个关键词
5. **`#### Scenario:`** - 每个需求至少有一个场景，必须以这开头
6. **`- **WHEN**` 和 `- **THEN**`** - 场景中必须包含这两个关键词

#### 示例

 `java-rsa-utils\specs\rsa-encrypt-decrypt\spec.md`

```markdown
## ADDED Requirements

### Requirement: RSA 公钥加密
`RsaUtils` SHALL 提供静态方法，使用 RSA 公钥对明文进行加密，返回 Base64 编码密文。

- 算法：`RSA/ECB/OAEPWithSHA-256AndMGF1Padding`
- MGF1 哈希：SHA-256（通过 `OAEPParameterSpec` 显式指定，不依赖 JDK 默认值）
- 明文编码：UTF-8
- 密文编码：Base64 标准字母表，无换行
- 最大明文长度（字节）：`(keySize / 8) - 2 * hashLen - 2`
  - RSA-2048 + SHA-256：190 字节
  - RSA-3072 + SHA-256：318 字节
  - RSA-4096 + SHA-256：446 字节

#### Scenario: 成功加密短字符串
- **WHEN** 调用 `RsaUtils.encrypt(plaintext, publicKeyBase64)`，明文 UTF-8 字节数不超过当前密钥允许的最大值
- **THEN** 返回非空 Base64 字符串，且每次调用结果不同（OAEP 随机性）

#### Scenario: 加密结果可被对应私钥解密还原
- **WHEN** 使用公钥加密明文后，再用对应私钥解密
- **THEN** 解密结果与原始明文完全一致

#### Scenario: 明文超出最大长度
- **WHEN** 明文 UTF-8 字节数超过当前密钥允许的最大值
- **THEN** 抛出 `RsaException`，消息说明最大允许长度

#### Scenario: 公钥格式非法
- **WHEN** 传入非法 Base64 字符串或非 RSA 公钥内容
- **THEN** 抛出 `RsaException`，包含原始异常作为 cause

---

### Requirement: RSA 私钥解密
`RsaUtils` SHALL 提供静态方法，使用 RSA 私钥对 Base64 密文进行解密，返回原始明文字符串。

- 算法与参数与加密端完全对称（`OAEPWithSHA-256AndMGF1Padding`，MGF1 SHA-256）
- 密文输入：Base64 标准编码字符串
- 明文输出：UTF-8 字符串

#### Scenario: 成功解密合法密文
- **WHEN** 调用 `RsaUtils.decrypt(cipherBase64, privateKeyBase64)`，密文由对应公钥加密
- **THEN** 返回与原始明文完全一致的字符串

#### Scenario: 跨平台密文可解密
- **WHEN** 密文由其他平台（Python / Node.js / OpenSSL）使用相同参数（OAEP SHA-256，MGF1 SHA-256）加密
- **THEN** `RsaUtils.decrypt()` 能正确解密还原明文

#### Scenario: 私钥与密文不匹配
- **WHEN** 使用与加密公钥不配对的私钥解密
- **THEN** 抛出 `RsaException`

#### Scenario: 密文被篡改
- **WHEN** 传入被修改过的 Base64 密文字符串
- **THEN** 抛出 `RsaException`，不返回任何部分结果

```

### tasks.md

`tasks.md` 使用 **Markdown 任务列表**格式，每个任务以 `- [ ]` 开头。

```markdown
## 1. [阶段名称]
- [ ] 1.1 [具体任务描述]
- [ ] 1.2 [具体任务描述]
  - [ ] 1.2.1 [子任务（可选）]
- [ ] 1.3 [具体任务描述]

## 2. [另一个阶段]
- [ ] 2.1 [具体任务描述]
- [ ] 2.2 [具体任务描述]

## 3. 测试与验证
- [ ] 3.1 [测试任务]
- [ ] 3.2 [文档更新]

## 4. 部署与发布
- [ ] 4.1 [部署任务]
```

#### 示例

```markdown
## 1. 异常与数据类

- [ ] 1.1 创建 `RsaException`（受检异常），包含 message 和 cause 构造器
- [ ] 1.2 创建 `RsaKeyPair` 不可变值对象，private final 字段 `publicKey` / `privateKey`，通过 `getPublicKey()` / `getPrivateKey()` 访问，无 setter

## 2. 密钥工具方法

- [ ] 2.1 实现 `RsaUtils.generateKeyPair()` — 默认 2048 位，返回 `RsaKeyPair`；`NoSuchAlgorithmException` 包装为 `RsaException`
- [ ] 2.2 实现 `RsaUtils.generateKeyPair(int keySize)` — 支持 2048 / 3072 / 4096，非法值抛 `IllegalArgumentException`；`NoSuchAlgorithmException` 包装为 `RsaException`
- [ ] 2.3 实现**公开** `RsaUtils.loadPublicKey(String base64)` — X.509 Base64 → `PublicKey`，格式非法或非 RSA 公钥时抛 `RsaException`
- [ ] 2.4 实现**公开** `RsaUtils.loadPrivateKey(String base64)` — PKCS#8 Base64 → `PrivateKey`，格式非法或非 RSA 私钥时抛 `RsaException`

## 3. 加密 / 解密

- [ ] 3.1 实现 `RsaUtils.encrypt(String plaintext, String publicKeyBase64)` — `OAEPWithSHA-256AndMGF1Padding`，显式传入 `OAEPParameterSpec`（MGF1 SHA-256），明文超长抛 `RsaException`
- [ ] 3.2 实现 `RsaUtils.decrypt(String cipherBase64, String privateKeyBase64)` — 与加密端参数完全对称，失败抛 `RsaException`

## 4. 签名 / 验签

- [ ] 4.1 实现 `RsaUtils.sign(String data, String privateKeyBase64)` — `SHA256withRSA`，返回 Base64 签名，失败抛 `RsaException`
- [ ] 4.2 实现 `RsaUtils.verify(String data, String signatureBase64, String publicKeyBase64)` — 验签失败返回 `false`，格式非法抛 `RsaException`

## 5. 合规性检查

- [ ] 5.1 检查所有 Java 文件符合 `.editorconfig` 规范（UTF-8、LF 行尾、4 空格缩进、120 字符行宽、文件末尾换行）
- [ ] 5.2 检查所有类有 Javadoc 类注释，所有 public 方法有 Javadoc 方法注释（含 `@param` / `@return` / `@throws`）
- [ ] 5.3 检查关键实现处（OAEP 参数、MGF1 哈希指定、确定性签名说明）有内联注释

```

## skill规范

Skill（技能）是一种可复用的 AI 工作流，将专业的指令、知识和工具打包在一起，让 AI 能够像专家一样完成特定领域的任务。

一个标准的 Skill 目录结构如下

```
your-skill-name/
├── SKILL.md                    # [核心] AI 执行指令与触发规则
├── README.md                   # [可选] 给人看的说明文档
├── LICENSE                     # [可选] 开源许可证（如 MIT）
│
├── agents/                     # UI 展示层（可选）
│   └── openai.yaml             # 技能在界面上的名称、简介和图标
│
├── references/                 # 知识库（按需加载）
│   └── *.md                    # 详细风格指南或领域知识
│
└── scripts/                    # 工具层（确定性执行）
    └── *.py                    # 校验脚本、处理脚本等
```

Skill 可以存放在以下位置

| 位置                           | 用途             |
| :----------------------------- | :--------------- |
| `.github/skills/<skill-name>/` | 团队共享（推荐） |
| `~/.copilot/skills/`           | 个人跨项目使用   |
| `.claude/skills/`              | Claude 兼容格式  |
| `.agents/skills/`              | 通用 Agent 格式  |

### skill示例

示例：Java编辑规范

`.claude\skills\java-editorconfig\SKILL.md`

#### 英文版示例

~~~markdown
---
name: java-editorconfig
description: Enforce .editorconfig formatting rules on all Java source files. Use when writing, editing, or reviewing Java code to ensure compliance with project style rules.
license: MIT
metadata:
  author: project
  version: "1.0"
---

Enforce `.editorconfig` rules on Java source files.

---

## Rules (from `.editorconfig`)

These rules apply to **all files** (`[*]`), including `*.java`:

| Rule | Value |
|---|---|
| `charset` | `utf-8` |
| `end_of_line` | `lf` |
| `indent_style` | `space` |
| `indent_size` | `4` |
| `tab_width` | `4` |
| `insert_final_newline` | `true` |
| `max_line_length` | `120` |

---

## When This Skill Applies

Invoke this skill **automatically** whenever you:
- Write a new Java file
- Edit an existing Java file
- Review or audit Java source files for style

---

## Enforcement Rules

### 1. Charset — UTF-8
- All Java files must be saved in UTF-8 encoding.
- When writing file content, do not use non-UTF-8 byte sequences.
- If the user supplies source with non-UTF-8 characters, flag them and ask for clarification.

### 2. Line Endings — LF only (`\n`)
- Every line must end with `\n` (Unix LF), never `\r\n` (Windows CRLF) or `\r` (old Mac CR).
- When writing Java files with the Write or Edit tool, ensure all line endings are LF.
- **Do not** use `\r\n` in any string written to a `.java` file, even on Windows.

### 3. Indentation — 4 spaces, no tabs
- Use **4 spaces** per indent level. Never use tab characters (`\t`) for indentation.
- This applies to:
  - Class bodies
  - Method bodies
  - Control-flow blocks (`if`, `for`, `while`, `switch`, `try`)
  - Annotations on separate lines
  - Continuation lines (see rule 7)
- Nested levels multiply: depth 1 = 4 spaces, depth 2 = 8 spaces, etc.

### 4. Final Newline
- Every Java file must end with exactly **one newline character** (`\n`) after the last line.
- Do not leave the file with no trailing newline or with multiple blank lines at the end.

### 5. Maximum Line Length — 120 characters
- No line may exceed **120 characters** (including indentation).
- When a line would exceed 120 characters, break it using one of these strategies:

  **Method calls / chained calls** — break before `.`:
  ```java
  result = someObject
          .methodOne(arg1, arg2)
          .methodTwo(arg3);
  ```

  **Method parameters** — align with opening parenthesis, or use 8-space continuation indent:
  ```java
  public void someMethod(
          String parameterOne,
          String parameterTwo,
          int parameterThree) {
  ```

  **String concatenation** — break after `+`:
  ```java
  String message = "This is a very long string that " +
          "wraps onto the next line.";
  ```

  **Binary/ternary expressions** — break before operator:
  ```java
  boolean result = conditionOne
          && conditionTwo
          && conditionThree;
  ```

  **Import statements** — never wrap; reorganize into static/non-static groups instead.

### 6. No Trailing Whitespace
- Lines must not end with spaces or tabs before the line ending.

### 7. Continuation Line Indent
- Continuation lines (lines that are the logical continuation of the previous line) use **8 spaces** (double indent) to distinguish them from block-level indentation.

---

## Validation Checklist

Before finalising any Java file, verify:

- [ ] No tab characters anywhere in the file (`\t`)
- [ ] Every line uses 4-space indentation per level
- [ ] No line exceeds 120 characters
- [ ] All line endings are LF (`\n`), not CRLF
- [ ] File ends with exactly one `\n`
- [ ] No trailing whitespace on any line

---

## Common Violations to Avoid

```java
// WRONG — tab indentation
public class Foo {
	void bar() {   // <-- tab character
	}
}

// CORRECT — 4 spaces
public class Foo {
    void bar() {
    }
}
```

```java
// WRONG — line > 120 chars (no wrap)
public ResponseEntity<SomeVeryLongTypeName> handleSomethingWithAVeryLongMethodName(HttpServletRequest request, SomeDto dto) {

// CORRECT — wrapped
public ResponseEntity<SomeVeryLongTypeName> handleSomethingWithAVeryLongMethodName(
        HttpServletRequest request, SomeDto dto) {
```

```java
// WRONG — missing final newline (file ends here with no \n)
}
// CORRECT — file ends with \n after the closing brace
}
```

---

## Integration with Write / Edit Tools

When using the **Write** tool to create a Java file:
- Compose the content string with `\n` line endings only.
- Ensure the content string ends with `\n`.
- Count characters per line before writing; reformat any line > 120 chars.

When using the **Edit** tool to modify a Java file:
- Apply the same rules to both `old_string` and `new_string`.
- Do not introduce tabs or CRLF in the replacement.
- If the surrounding context has violations, fix them within the edited block; do not silently propagate violations.

---

## Reporting Violations

When auditing an existing file and violations are found, report them in this format:

```
editorconfig violations in src/main/java/com/example/Foo.java:
  Line 12: tab indentation (use 4 spaces)
  Line 47: line length 134 > 120
  EOF: missing final newline
```

Then offer to fix them automatically unless the user asked for report-only mode.

~~~

#### 中文示例

~~~markdown
---
name: java-editorconfig
description: 对所有 Java 源文件强制执行 .editorconfig 格式规范及注释规范（类注释、方法注释、关键实现内联注释）。编写、编辑或审查 Java 代码时使用，确保符合项目风格规则。
license: MIT
metadata:
  author: project
  version: "1.1"
---

对 Java 源文件强制执行 `.editorconfig` 规范。

---

## 规则来源（`.editorconfig`）

以下规则适用于**所有文件**（`[*]`），包括 `*.java`：

| 规则 | 值 |
|---|---|
| `charset` | `utf-8` |
| `end_of_line` | `lf` |
| `indent_style` | `space` |
| `indent_size` | `4` |
| `tab_width` | `4` |
| `insert_final_newline` | `true` |
| `max_line_length` | `120` |

---

## 适用时机

以下情况**自动**应用本 skill：
- 新建 Java 文件
- 编辑已有 Java 文件
- 审查或检查 Java 源文件风格

---

## 强制规则

### 1. 字符集 — UTF-8
- 所有 Java 文件必须以 UTF-8 编码保存。
- 写入文件内容时，不得使用非 UTF-8 字节序列。
- 若用户提供的源码含有非 UTF-8 字符，应标记并请用户确认。

### 2. 行尾 — 仅使用 LF（`\n`）
- 每行必须以 `\n`（Unix LF）结尾，禁止使用 `\r\n`（Windows CRLF）或 `\r`（旧版 Mac CR）。
- 使用 Write 或 Edit 工具写入 Java 文件时，确保所有行尾为 LF。
- 即使在 Windows 环境下，写入 `.java` 文件的任何字符串中**不得**出现 `\r\n`。

### 3. 缩进 — 4 个空格，禁止使用 Tab
- 每个缩进层级使用 **4 个空格**，禁止使用 Tab 字符（`\t`）进行缩进。
- 适用范围：
  - 类体
  - 方法体
  - 控制流块（`if`、`for`、`while`、`switch`、`try`）
  - 独立成行的注解
  - 续行（见规则 7）
- 层级叠加：深度 1 = 4 空格，深度 2 = 8 空格，以此类推。

### 4. 文件末尾换行
- 每个 Java 文件最后一行之后必须有且仅有**一个换行符**（`\n`）。
- 不得缺少末尾换行，也不得在文件末尾留有多个空行。

### 5. 最大行长度 — 120 字符
- 任何一行（含缩进）不得超过 **120 个字符**。
- 若某行将超过 120 字符，按以下策略换行：

  **方法调用 / 链式调用** — 在 `.` 前换行：
  ```java
  result = someObject
          .methodOne(arg1, arg2)
          .methodTwo(arg3);
  ```

  **方法参数** — 使用 8 空格续行缩进：
  ```java
  public void someMethod(
          String parameterOne,
          String parameterTwo,
          int parameterThree) {
  ```

  **字符串拼接** — 在 `+` 后换行：
  ```java
  String message = "这是一段很长的字符串，" +
          "换行到下一行继续。";
  ```

  **二元 / 三元表达式** — 在运算符前换行：
  ```java
  boolean result = conditionOne
          && conditionTwo
          && conditionThree;
  ```

  **import 语句** — 不得换行；应将 static import 与普通 import 分组整理。

### 6. 行尾不得有多余空白
- 每行在行尾符之前不得有空格或 Tab。

### 7. 续行缩进
- 续行（逻辑上属于上一行的延续）使用 **8 个空格**（双倍缩进），以区别于块级缩进。

---

## 注释规范

### 8. 类注释（Javadoc）— 强制

每个 `class`、`interface`、`enum`、`record` 声明之前**必须**有 Javadoc 块注释（`/** ... */`）。

**必须包含：**
- 一句话功能描述（第一段，句尾加句号）
- 若该类有外部依赖或使用约束，用 `<p>` 段落补充说明

**可选标签（有则写）：**
- `@param <T>` — 泛型类型参数说明
- `@see` — 关联类或方法

```java
// 错误 — 无类注释
public class HttpClients {
    ...
}

// 正确
/**
 * HTTP 客户端工具类，封装 {@link java.net.http.HttpClient}，提供同步请求方法。
 * <p>
 * 线程安全；{@link #setObjectMapper} 应仅在应用启动阶段调用。
 */
public class HttpClients {
    ...
}
```

---

### 9. 方法注释（Javadoc）— 强制

每个 `public` 和 `protected` 方法声明之前**必须**有 Javadoc 块注释。`private` 方法若逻辑复杂也应添加。

**必须包含：**
- 一句话功能描述（第一段）

**必须按需包含（有对应元素则不可省略）：**
- `@param <name>` — 每个参数的含义及约束（如"不得为 null"）
- `@return` — 返回值含义；返回 `void` 时省略
- `@throws <ExceptionType>` — 每个受检异常的触发条件

```java
// 错误 — 无方法注释
public static <T> T get(String url, Class<T> responseType) throws HttpClientException {
    ...
}

// 正确
/**
 * 向指定 URL 发送 HTTP GET 请求，将响应体反序列化为目标类型。
 *
 * @param url          请求地址，不得为 null
 * @param responseType 响应体目标类型，不得为 null；使用 {@code Void.class} 忽略响应体
 * @param <T>          响应体类型
 * @return 反序列化后的响应对象；目标类型为 {@code Void} 时返回 null
 * @throws HttpNetworkException  网络连接失败或超时
 * @throws HttpResponseException HTTP 状态码非 2xx
 * @throws HttpParseException    响应体 JSON 解析失败
 */
public static <T> T get(String url, Class<T> responseType) throws HttpClientException {
    ...
}
```

**重载方法：** 若多个重载方法功能相同，可在最完整的重载上写完整 Javadoc，其余重载用 `{@code see #methodName(...)}` 简述差异即可，但**不得完全省略**注释块。

---

### 10. 关键实现内联注释 — 强制

以下场景**必须**添加行内注释（`//`）或块注释（`/* */`），解释"为什么"而非"是什么"：

| 场景 | 说明 |
|---|---|
| 异常捕获与包装 | 说明捕获原因及包装目的 |
| 非 2xx 状态码判断边界 | 说明判断逻辑（如为何是 `< 200 \|\| >= 300`） |
| 线程安全临界区 | 说明 `volatile`、`synchronized` 或单例初始化的意图 |
| 默认值 / 魔法数字 | 说明来源或业务含义 |
| 处理 null 或空值的特殊分支 | 说明为何此处需要特判 |
| 复杂算法或非直觉逻辑 | 解释思路，必要时标注参考来源 |

```java
// 错误 — 无注释，意图不明
if (statusCode < 200 || statusCode >= 300) {
    throw new HttpResponseException(statusCode, rawBody);
}

// 正确 — 说明判断依据
// HTTP 2xx 范围为 200–299；其余状态码（含 1xx、3xx、4xx、5xx）均视为错误
if (statusCode < 200 || statusCode >= 300) {
    throw new HttpResponseException(statusCode, rawBody);
}

// 错误 — volatile 意图不明
private static volatile ObjectMapper objectMapper = new ObjectMapper();

// 正确 — 说明 volatile 的作用
// volatile 保证 setObjectMapper() 的写入对所有线程立即可见
private static volatile ObjectMapper objectMapper = new ObjectMapper();
```

**注释语言：** 与项目主语言一致（本项目为中文）。
**禁止无意义注释：** 不得写仅复述代码字面意思的注释（如 `// 返回结果` 对应 `return result;`）。

---

## 检查清单

完成任何 Java 文件后，核对以下各项：

**格式规范（.editorconfig）**
- [ ] 文件中无 Tab 字符（`\t`）
- [ ] 每个缩进层级使用 4 个空格
- [ ] 所有行不超过 120 字符
- [ ] 所有行尾为 LF（`\n`），非 CRLF
- [ ] 文件末尾有且仅有一个 `\n`
- [ ] 所有行尾无多余空白

**注释规范**
- [ ] 每个 `class` / `interface` / `enum` / `record` 有 Javadoc 块注释，含一句话功能描述
- [ ] 每个 `public` / `protected` 方法有 Javadoc 块注释，含 `@param`、`@return`、`@throws`（按需）
- [ ] 复杂 `private` 方法有 Javadoc 块注释
- [ ] 异常捕获与包装处有内联注释说明原因
- [ ] 非直觉的判断条件（状态码边界、null 特判等）有内联注释说明依据
- [ ] `volatile`、`synchronized` 等并发关键字旁有注释说明意图
- [ ] 魔法数字 / 默认值旁有注释说明含义
- [ ] 无仅复述代码字面意思的无意义注释

---

## 常见错误示例

```java
// 错误 — 使用 Tab 缩进
public class Foo {
	void bar() {   // <-- Tab 字符
	}
}

// 正确 — 4 个空格
public class Foo {
    void bar() {
    }
}
```

```java
// 错误 — 行超过 120 字符（未换行）
public ResponseEntity<SomeVeryLongTypeName> handleSomethingWithAVeryLongMethodName(HttpServletRequest request, SomeDto dto) {

// 正确 — 已换行
public ResponseEntity<SomeVeryLongTypeName> handleSomethingWithAVeryLongMethodName(
        HttpServletRequest request, SomeDto dto) {
```

```java
// 错误 — 文件末尾无换行符
}
// 正确 — 右花括号后有 \n
}
```

---

## 与 Write / Edit 工具的集成

使用 **Write** 工具创建 Java 文件时：
- 内容字符串中只使用 `\n` 作为行尾。
- 确保内容字符串以 `\n` 结尾。
- 写入前统计每行字符数，超过 120 字符的行须先重新格式化。

使用 **Edit** 工具修改 Java 文件时：
- 对 `old_string` 和 `new_string` 均应用上述规则。
- 替换内容中不得引入 Tab 或 CRLF。
- 若周围上下文存在违规，应在编辑块内一并修正，不得静默传播违规。

---

## 违规报告格式

审查已有文件发现违规时，按以下格式报告（格式违规与注释违规分组输出）：

```
违规报告：src/main/java/com/example/Foo.java

[格式违规]
  第 12 行：Tab 缩进（应使用 4 个空格）
  第 47 行：行长 134 > 120
  文件末尾：缺少换行符

[注释违规]
  第 3 行：类 Foo 缺少 Javadoc 类注释
  第 15 行：public 方法 doSomething() 缺少 Javadoc 注释
  第 28 行：方法 doSomething() 的 @throws IOException 缺少说明
  第 42 行：异常捕获块缺少内联注释说明包装原因
  第 67 行：魔法数字 30 缺少注释说明含义
```

报告后，除非用户要求仅报告不修改，否则主动提出自动修复。

~~~

