# 更新日志

本文档记录 Get-CodexSessions 已发布版本及其后的本地开发版本。本地迭代日期采用记录中的 UTC 日历日期。标记为**本地开发版**的版本尚未发布为 GitHub Release。

## [v1.6] - 2026-10-04

**状态：** [正式 GitHub Release](https://github.com/zjwww/Get-CodexSessions/releases/tag/v1.6)；当前脚本：[`Get-CodexSessions-v1.6.ps1`](Get-CodexSessions-v1.6.ps1)

### 变更

- 当两个模型值都存在且 `LastModel` 与 `FirstModel` 不同时，在 `LastModel` 末尾添加 ` *`。
- 当两个 Effort 值都存在且 `LastEffort` 与 `FirstEffort` 不同时，在 `LastEffort` 末尾添加 ` *`。
- 新增 `LastModelRaw` 和 `LastEffortRaw`，为精确筛选和导出保留不带标记的原始值。
- 彩色输出模式的可选字段列表同步支持两个 Raw 字段。

### 正式发布范围

本次 v1.6 正式发布同时包含此前 v1.2–v1.5 本地迭代的改动：正式项目元数据查询、带回退路径的大型数据预扫描、独立会话标记、可配置彩色终端表格及版本化脚本名。v1.2–v1.5 不单独提交脚本、打标签或创建 Release；下方保留其真实更新历史。

### 验证

以下为正式发布前保留的本地开发验证记录：

- 已使用 Windows PowerShell 5.1 和 Codex 内置 PowerShell 7.6.5 运行时完成语法解析和实际执行验证。
- 两种引擎均返回 53 个普通会话，报告的解析错误行数为 0。
- 测试数据包含 1 个模型变化标记和 16 个 Reasoning Effort 变化标记；全部标记均与对应 Raw 值的比较结果一致。
- 使用 Raw 字段还原 `LastModel` 和 `LastEffort` 并排除两个新增字段后，PowerShell 7 完整 JSON 输出与 v1.5 完全一致。
- 彩色视图可以显示变化标记、选择两个 Raw 字段、保留独立会话行着色，并且不输出会话对象。
- 已静态复核 macOS PowerShell 7 兼容性；尚未进行 macOS 实机运行验证。v1.6 只新增跨平台的字符串比较、格式化和输出字段，没有引入新的平台专属命令或 API 依赖。

### 正式发布复核 — 2026-10-04

- Windows PowerShell 5.1.26100.9444 和 Codex 内置 PowerShell 7.6.5：脚本解析及合成数据回归通过。
- 覆盖变化与不变的模型/Effort、缺失值、Raw 字段、默认对象管道、内部线程过滤、正式项目和独立会话字段、列别名、前景色、进度 100% 与完成事件。
- 大于 32 MiB 的夹具验证了编译预扫描器，以及 Add-Type 不可用时的纯 PowerShell 回退；sqlite3 未安装时仍能读取会话和 global state。全部合成输入文件哈希保持不变。
- 两种引擎均验证了成功退出码 0、路径失败退出码 1 和显示参数失败退出码 2；双语文档可执行代码块均通过语法检查。
- Usage Guide 多行/单行示例在合成数据上对比；Windows Explorer / macOS Finder 打开命令仅做语法检查。
- 静态复核覆盖全部累计改动的路径和 $HOME、可选 sqlite3 发现与 -readonly 查询、跨平台 .NET/Add-Type API、UTF-8、CRLF、Write-Host/Write-Progress 和对象管道。未发现新增的 Windows 专属脚本依赖。
- 已静态复核 macOS PowerShell 7 兼容性；尚未进行 macOS 实机运行验证。历史 macOS 实测证据仅属于 v1.0。

## [v1.5] - 2026-10-04

**状态：** 本地开发版；已保留脚本：`Get-CodexSessions-v1.5.ps1`（仅保留在本机，不随公开仓库或 Release 发布）

### 新增

- 新增可选的纯显示终端表格 `-ColorOutput`。
- 独立会话行使用可配置的前景色，同时不改变默认对象输出。
- 新增 `-Property`（别名：`-Properties`、`-Columns`），用于选择和排列彩色表格中的列。
- 新增 `-StandaloneColor`，默认值为 `Yellow`。
- 在脚本头部加入明确版本信息，并开始使用带版本号的脚本文件名。
- 新增相互独立的英文和简体中文更新日志。

### 兼容性

- 默认调用仍返回相同的结构化对象，可继续用于 `Format-Table`、筛选、排序和导出管道。
- 彩色视图仅用于终端显示，按设计不输出会话对象。

### 验证

- 已使用 Windows PowerShell 5.1 和 Codex 内置 PowerShell 7.6.5 运行时完成语法解析及实际执行验证。
- 在测试机器上，两种引擎均返回 53 个普通会话，其中 21 个为独立会话，报告的解析错误数为 0。
- PowerShell 7 默认对象输出与 v1.4 的 JSON 对比完全一致。
- 已验证彩色视图、参数别名、自定义前景色、纯显示输出行为和无效字段报错路径。
- v1.5 的改动尚未重新进行 macOS 实机测试。

## [v1.4] - 2026-10-04

**状态：** 本地开发版；已保留脚本：`Get-CodexSessions-v1.4.ps1`（仅保留在本机，不随公开仓库或 Release 发布）

### 变更

- 将没有正式 Project ID 的会话识别为独立会话。
- 独立会话的 `Project` 使用 `<Standalone Session>`，`ProjectId` 使用 `<N/A>`，`ProjectPath` 使用会话记录的完整 `CWD`。
- 新增对应的 `ProjectSource` 值 `standalone`。
- 正式项目归属信息保持不变。

## [v1.3] - 2026-10-03

**状态：** 历史本地迭代；当时尚未开始版本文件保留策略，因此没有单独保存脚本快照。

### 性能

- 会话数据较大时使用内存中编译的预扫描器，在 PowerShell 反序列化之前跳过无关 JSONL 记录。
- 小型数据集、受限环境或单文件预扫描失败时，保留纯 PowerShell 自动回退路径。
- 在测试机器约 3.5 GB 的完整会话数据上，PowerShell 7 实测耗时由约 167 秒降至约 7 秒。
- 保持只读解析和原有结构化输出。

## [v1.2] - 2026-10-03

**状态：** 历史本地迭代；当时尚未开始版本文件保留策略，因此没有单独保存脚本快照。

### 新增

- 如可用，从 `state_5.sqlite` 和 `.codex-global-state.json` 读取正式 Project 归属信息。
- 新增 `ProjectId`、`ProjectPath` 和 `ProjectSource` 输出字段。
- `Project` 开始优先显示 Codex 保存的项目名称；在当时版本中仍保留工作目录回退方式。
- SQLite 访问保持明确只读；可选元数据不可用时继续使用回退逻辑。

## [v1.1] - 2026-09-24

**状态：** [已发布 GitHub Release](https://github.com/zjwww/Get-CodexSessions/releases/tag/v1.1)；创建本更新日志时仍为 Latest。

### 新增

- 通过 PowerShell 标准 `Write-Progress` 显示 rollout 文件整体扫描进度。
- 新增 `-NoProgress`，用于自动化和其他非交互场景。
- 保留不同 PowerShell 宿主的原生进度样式，包括 Windows PowerShell 5.1 的 Classic，以及 PowerShell 7 已配置或默认的样式。

### 验证

- 已使用 Windows PowerShell 5.1 和 Codex 内置 PowerShell 7.6.5 运行时完成验证。
- 本版本没有重新进行 macOS 实机测试；macOS Tahoe 26.2 与 PowerShell 7.x 的实测证据仅属于 v1.0，不代表 v1.1 已完成实机验证。

## [v1.0] - 2026-09-14

**状态：** [已发布 GitHub Release](https://github.com/zjwww/Get-CodexSessions/releases/tag/v1.0)

### 首次发布

- 新增对本地 Codex 会话的只读检查。
- 输出标题、创建时间、最后活动时间、Session ID、工作目录、Project 显示值和 rollout JSONL 路径。
- 输出最早和最近观察到的模型及 Reasoning Effort。
- 默认过滤 Codex 内部辅助线程，并提供 `-IncludeInternal` 用于内部线程分析。
- 读取 `session_index.jsonl` 和 rollout JSONL，并可选地使用只读 SQLite 补充标题。
- 支持 Windows PowerShell 5.1，以及 Windows 和 macOS 上的 PowerShell 7.x。
- 记录已在 macOS Tahoe 26.2 与 PowerShell 7.x 环境中完成实际测试。
- 采用 GNU General Public License v3.0 only（`GPL-3.0-only`）。
