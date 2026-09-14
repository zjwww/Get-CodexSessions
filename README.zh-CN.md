[English](README.md) | 简体中文

# Get-CodexSessions

一个跨平台 PowerShell 工具，用于检查本地 Codex 会话，并确认每个会话最初实际使用的模型。

## 为什么做这个工具

GPT-6 Astra 发布后，在 Codex 中把原先使用 GPT-5.6 系列模型的旧会话切换到新模型时，Codex 可能显示提示，说明切换现有会话所使用的模型可能会降低输出质量。这个实际场景带来了一个需要先确认的问题：在继续旧会话、切换模型或新建会话之前，如何知道该 Codex 会话最初实际使用的是哪个模型？

Get-CodexSessions 正是为查询本地 Codex 元数据中的这个信息而编写。以上内容仅说明本项目的开发动机和实际使用场景，并不表示所有模型切换都存在兼容性问题，也不表示所有切换模型的会话都会降低输出质量。

## 功能

脚本可以读取并显示：

- 会话标题和用于表格显示的短标题
- 会话创建时间和最后活动时间
- Session ID
- `FirstModel` 和 `FirstEffort`
- `LastModel` 和 `LastEffort`
- Project 和工作目录（`CWD`）
- 对应的 rollout JSONL 路径

这些信息可用于判断会话是否切换过模型或 Reasoning Effort、定位相应的 rollout 文件、列出某个 Project 下的会话，以及区分普通用户会话与 Codex 辅助线程。

脚本默认过滤 `codex-auto-review`、Guardian、Sub-agent、child thread，以及内部 review / approval thread 等 Codex 内部线程。需要检查这些线程时可使用 `-IncludeInternal`。

## 输出示例

### Windows

![Get-CodexSessions Windows 输出示例](sample-win.png)

### macOS

![Get-CodexSessions macOS 输出示例](sample-mac.png)

## 环境要求

| 平台 | PowerShell |
|---|---|
| Windows | Windows PowerShell 5.1 或 PowerShell 7.x |
| macOS | [PowerShell 7.x](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-macos) |
| Linux | 从代码设计上兼容 PowerShell 7.x，但目前不声明已在 Linux 实机测试 |

默认 Codex Home 在 Windows 上为 `C:\Users\<User>\.codex`，在 macOS 上为 `/Users/<User>/.codex`。脚本使用 `$HOME` 自动处理不同平台的用户目录。

## 已测试环境

- Windows：在 v1.0 发布过程中使用 Windows PowerShell 5.1 和 PowerShell 7.x 完成验证。
- macOS：已在 macOS Tahoe 26.2 + PowerShell 7.x 环境中实际测试通过。该测试结果仅代表这一已验证环境，不代表所有 macOS 版本都保证完全兼容。

## 安装

本项目不需要传统安装。下载 [Get-CodexSessions.ps1](Get-CodexSessions.ps1)，放到任意目录，然后使用受支持的 PowerShell 版本运行即可。

Windows 的执行策略设置可能影响从网络下载的 `.ps1` 文件。请遵循所在组织的安全策略；本项目不要求降低系统级执行策略。

## 快速开始

### 查看普通 Codex 会话

Windows：

```powershell
.\Get-CodexSessions.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

macOS：

```powershell
./Get-CodexSessions.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### 按标题关键字查找

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object { $_.Title -like "*VidzDown*" } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### 查看一个会话的完整信息

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object { $_.Title -like "*VidzDown*" } |
    Format-List *
```

### 查看 Codex 内部线程

```powershell
.\Get-CodexSessions.ps1 -IncludeInternal |
    Where-Object { $_.IsInternal } |
    Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

在 macOS 上，把命令开头的 `.\` 改为 `./` 即可，其余 PowerShell 管道语法相同。

## 完整使用方法

独立 Usage Guide 包含单关键字筛选、多关键字 OR / AND 筛选、Project、CWD 和 Session ID 筛选、排序、最近 N 个会话、模型或 Reasoning Effort 变化、按模型筛选、内部线程分析、自定义 Codex Home、CSV 导出、JSONL 路径查询、Windows Explorer 定位和 macOS Finder 定位。

- [完整中文使用说明](Get-CodexSessions-Usage-zh-CN.md)
- [Full usage guide in English](Get-CodexSessions-Usage-en.md)

## 工作原理

Get-CodexSessions 会读取以下本地 Codex 数据：

- `~/.codex/session_index.jsonl`：用于会话标题和部分线程元数据
- `~/.codex/state_5.sqlite`：系统存在 `sqlite3` 时，作为可选的会话标题补充来源
- `~/.codex/sessions/.../rollout-*.jsonl`：用于实际 `turn_context`、模型、Reasoning Effort、时间、工作目录及相关元数据

SQLite 会以明确的只读方式打开。如果系统没有 `sqlite3`，或可选的数据库查询失败，脚本仍会继续处理 session index 和 rollout 文件。

Codex 内部存储格式可能随着后续版本发生变化，因此未来的 Codex 更新可能需要同步更新解析逻辑。

## 安全性

Get-CodexSessions 是只读检查工具。它不会修改、删除、重命名或移动 Codex 会话、rollout JSONL、`session_index.jsonl`、`state_5.sqlite` 或 Codex 配置。

工具读取的本地会话元数据可能包含私人标题、提示词、路径和项目名称。分享或导出结果前请先检查内容。

## 兼容性

- Windows PowerShell 5.1
- Windows 上的 PowerShell 7.x
- macOS 上的 PowerShell 7.x
- 从代码设计上兼容 Linux 上的 PowerShell 7.x；v1.0 不声明 Linux 为已完成实机测试的环境

## 许可证

本项目采用 [GNU General Public License v3.0 only](LICENSE)（`GPL-3.0-only`）。
