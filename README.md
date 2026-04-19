# Markdown Mindmap Clipboard

一个基于 Swift + NSPasteboard 的 macOS 工具，用于将 Markdown 层级列表转换为真正带有父子结构的富文本剪贴板内容，从而可以直接粘贴到导图软件、文档软件、笔记软件中，并保留节点层级。

---

# 背景

很多导图软件、富文本编辑器、知识管理软件都支持通过剪贴板粘贴树状结构。

例如下面这种 Markdown：

```markdown
- 数据库设计模式
    - 邻接表
    - 闭包表
    - 物化路径
- 动态字段方案
    - EAV
    - JSON扩展
```

理论上粘贴后应该变成：

- 数据库设计模式
    - 邻接表
    - 闭包表
    - 物化路径
- 动态字段方案
    - EAV
    - JSON扩展

但在实际使用中，常见方案都会遇到问题：

- `pbcopy` 只能复制纯文本
- `textutil -convert rtf` 会把嵌套列表压平成同级节点
- `osascript` 写 HTML clipboard 时，有些软件会把整个网页当成一个节点
- 浏览器复制虽然能成功，但无法完全自动化

最终结果就是：

- 节点能拆分
- 但父子层级丢失
- 导图软件里全变成同级节点

这个项目就是为了解决这个问题。

---

# 它解决了什么问题

这个工具主要解决：

1. Markdown 缩进列表无法正确保留父子结构
2. `textutil -> RTF` 导致嵌套列表压平
3. 导图软件无法正确识别普通剪贴板文本
4. 希望全命令行完成，不依赖浏览器复制
5. 希望同时兼容：
   - 导图软件
   - 富文本编辑器
   - 文档软件
   - 笔记软件

它的核心思路不是“复制文本”，而是“写结构化剪贴板”。

---

# 核心思路

整体流程如下：

```text
Markdown / 缩进文本
-> Swift 内置解析器（逐行扫描缩进）
-> HTML <ul><li> 嵌套结构
-> Swift NSPasteboard
-> 写入 html / plain text / rtf 三种 flavor
-> 导图软件自动选择最合适的数据类型
```

相比传统方案：

```text
Markdown
-> textutil
-> RTF
-> 导图软件
```

本项目最大的区别在于：

- 不依赖 `pandoc`
- 不依赖 `textutil`
- 不依赖浏览器复制
- 不依赖 AppleScript 古老的 HTML data blob
- 直接通过 `NSPasteboard` 写入 HTML flavor

这样很多导图软件就可以正确识别真正的嵌套 `<ul><li>` 结构，而不是简单的项目符号。

---

# 工作原理

Swift 工具会：

1. 从 stdin 或当前剪贴板读取 Markdown / 纯文本
2. 将缩进列表转换成真正嵌套的 HTML `<ul><li>`
3. 同时准备：
   - HTML
   - Plain Text
   - RTF（可选，生成失败时会自动降级）
4. 写入 macOS 剪贴板
5. 目标软件会自动选择最适合自己的 flavor

通常：

- 支持 HTML 的软件会读取 `.html`
- 不支持 HTML 的软件会读取 `.rtf`
- 最差也能退回 `.string`

---

# 为什么不用 textutil

很多人第一反应会想到：

```bash
pbpaste | pandoc -f markdown -t html | textutil -convert rtf | pbcopy
```

但实际测试发现：

- HTML 中已经有正确嵌套的 `<ul><li>`
- 经过 `textutil -> rtf` 后，嵌套列表被压平
- 导图软件只能识别出一堆同级 bullet

所以 `textutil` 更适合普通富文本，不适合复杂树状结构。

---

# 适用场景

这个工具特别适合以下场景：

- 导图软件节点批量导入
- 将 Markdown 大纲快速转成树状结构
- 将 AI 输出内容直接粘贴进脑图
- 将项目清单、任务拆分、知识结构导入思维导图
- 将数据库设计、系统架构、流程节点快速导入导图工具
- 将飞书、Notion、Obsidian、Markdown 笔记转换为脑图节点

例如：

```markdown
- PDM BOM同步
    - 获取根节点配置
    - DFS展开子件
    - 过滤空物料编码
    - 校验ERP是否存在
    - 校验版本号
    - 上传BOM
```

可以直接粘贴成：

```text
PDM BOM同步
├── 获取根节点配置
├── DFS展开子件
├── 过滤空物料编码
├── 校验ERP是否存在
├── 校验版本号
└── 上传BOM
```

---

# 安装依赖

只需要：

- Swift（macOS 自带）

确认 Swift 可用：

```bash
swift --version
```

---

# 编译

```bash
make build
```

`Makefile` 会自动：

- 使用当前 macOS SDK
- 显式指定最小部署目标（默认 `macOS 14.0`）
- 使用仓库内的 module cache，避免某些环境下的系统缓存权限问题

如果你想手动编译，也建议显式指定 target，而不是直接使用最简单的 `swiftc -O`：

```bash
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
swiftc -O \
  -sdk "$SDKROOT" \
  -target "$(uname -m)-apple-macosx14.0" \
  mindclip.swift -o mindclip
```

---

# 安装

编译完成后运行：

```bash
make install
```

会自动将二进制安装到 `~/.local/bin/mindclip`。

如果你之前已经装过旧版本，尤其是曾在更高版本 macOS / SDK 上编译过旧二进制，请重新执行一次 `make install` 覆盖 `~/.local/bin/mindclip`，否则可能出现：

```text
built for macOS 15.0 which is newer than running OS
```

安装后请确认 `~/.local/bin` 已加入 `PATH`，否则系统找不到命令。在 `~/.zshrc` 或 `~/.bashrc` 中添加：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

然后重新加载：

```bash
source ~/.zshrc
```

---

# 使用方式

最推荐的方式：

```bash
pbpaste | ./mindclip
```

也可以：

```bash
cat demo.md | ./mindclip
```

如果当前不是通过管道传入内容，而是直接运行：

```bash
./mindclip
```

程序会自动读取当前剪贴板里的纯文本内容进行转换。

然后直接去导图软件中粘贴。

---

# 示例

## 快速体验（使用 demo.md）

仓库自带了一份 `demo.md`，内容是"数据库表设计模式分类"，包含多达 4 层嵌套结构，可以直接用来测试效果。

**第一步：编译**

```bash
make build
```

**第二步：转换并写入剪贴板**

```bash
cat demo.md | ./mindclip
```

成功后 stderr 会输出：

```
ok: HTML/plain text/RTF 已写入剪贴板
```

如果当前环境无法生成 RTF，也可能输出：

```
ok: HTML/plain text 已写入剪贴板
```

然后切换到 MindNode（或其他导图软件），直接 `⌘V` 粘贴即可。

**粘贴后的节点结构（节选）：**

```text
基础业务实体类
├── 用户表
├── 订单表
├── 产品表
├── ...
└── 典型特征
    ├── 一张表代表一个业务实体
    ├── 字段固定
    ├── 结构清晰
    └── 最符合第三范式

层级 / 树结构类
├── 邻接表
│   ├── 写入简单
│   ├── 查询递归复杂
│   ├── 适合层级不深
│   └── 常见字段
│       ├── id
│       └── parent_id
├── 闭包表
│   ├── 查询所有祖先、后代、层级很快
│   ├── 适合 BOM、权限、菜单、多级审批
│   ├── 写入复杂、占空间
│   └── 常见字段
│       ├── ancestor_id
│       ├── descendant_id
│       └── depth
├── 路径枚举表
├── Nested Set 左右值模型
└── 图边表

动态字段类
├── 稀疏表 / EAV 表
├── JSON 扩展字段表
├── 宽表
└── 扩展表

... （共 10 个顶级分类，约 60+ 子节点）
```

`demo.md` 完整包含以下 10 个顶级分类：

| 分类 | 代表模式 |
|------|---------|
| 基础业务实体类 | 用户表、订单表、BOM表 |
| 层级 / 树结构类 | 邻接表、闭包表、Nested Set |
| 动态字段类 | EAV、JSON扩展、宽表 |
| 配置 / 枚举类 | 字典表、配置表、映射表 |
| 分析统计类 | 事实表、维度表、星型模型 |
| 历史审计类 | 日志表、审计表、快照表 |
| 高性能 / 缓存类 | 冗余汇总表、队列表、中间表 |
| 多态扩展类 | STI、CTI、多态关联表 |
| 权限与关系类 | 中间表、权限表、XRef |
| 时态与版本类 | 时态表、SCD、Data Vault |

## 最小示例

输入：

```markdown
- 数据库设计模式
    - 邻接表
    - 闭包表
    - 物化路径
- 动态字段方案
    - EAV
    - JSON扩展
```

导图软件中的结果：

```text
数据库设计模式
├── 邻接表
├── 闭包表
└── 物化路径

动态字段方案
├── EAV
└── JSON扩展
```

---

# PopClip 插件

仓库内置了 `MindClip.popclipext`，可以在选中文本后一键调用 mindclip。

**安装：**

双击 `MindClip.popclipext` 文件夹，PopClip 会自动识别并安装。

**使用：**

1. 在任意应用中选中 Markdown 列表文本
2. 点击 PopClip 工具栏中的 MindClip 按钮
3. 层级结构写入剪贴板，直接粘贴到导图软件

> 需要先将 `mindclip` 二进制安装到 `~/.local/bin/mindclip`。

---

# 后续可扩展方向

未来可以继续增强：

- 已支持：未通过管道传入内容时，自动从剪贴板读取 Markdown / 纯文本
- 支持 `--stdin`
- 支持 `--file`
- 支持 `--debug`
- 支持 `--no-rtf`
- 支持输出调试 HTML 到 `/tmp/mindmap.html`
- 支持自动清洗 `<p>` 标签
- 支持导图软件兼容模式
- 支持导出 OPML
- 支持导出 FreeMind / XMind 格式

---

# 已知限制

1. 某些软件可能优先读取 `.rtf`
2. 某些软件可能优先读取 `.string`
3. 少数软件只认浏览器复制来源的 HTML
4. 如果输入 Markdown 缩进不规范，可能导致层级错误
5. `pandoc` 不同版本输出 HTML 细节可能略有差异
6. 某些受限环境中，`NSAttributedString` 的 HTML -> RTF 转换可能失败，此时程序会自动退回为 HTML + Plain Text

---

# 回滚方案

如果某个软件仍然无法识别 NSPasteboard 写入的 HTML，可以退回浏览器复制方案：

```bash
pbpaste | pandoc -f markdown -t html -s > /tmp/mindmap.html
open /tmp/mindmap.html
```

然后：

1. 浏览器打开 HTML
2. 全选
3. 复制
4. 粘贴到目标软件

---

# 项目价值

这个项目本质上不是“复制文本”的工具，而是“结构化剪贴板”的工具。

它解决的是：

- Markdown 层级结构
- 富文本剪贴板
- 导图软件兼容性
- HTML / RTF / Plain Text 多 flavor 投递

对于重度使用 Markdown、导图、知识管理、系统设计、项目拆解的人来说，它会非常有用。
