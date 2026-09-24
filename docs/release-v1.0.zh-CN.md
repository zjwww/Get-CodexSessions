# What's new

## 简体中文

- Get-CodexSessions 首次正式发布。
- 列出本地 Codex 会话标题、创建时间、最后活动时间、项目信息、Session ID 和 rollout JSONL 路径。
- 显示每个会话最初及最近实际使用的模型和 Reasoning Effort。
- 默认过滤 Codex 内部线程，并提供 `-IncludeInternal` 供内部线程分析使用。
- 读取 `session_index.jsonl` 和 rollout JSONL；系统存在 `sqlite3` 时，可选择以只读方式从 SQLite 补充标题。
- 所有 Codex 数据访问均保持只读。
- 支持 Windows 上的 Windows PowerShell 5.1 和 PowerShell 7.x，以及 macOS 上的 PowerShell 7.x；macOS 环境已在 macOS Tahoe 26.2 上测试。

### 基本运行命令

#### Windows

```powershell
.\Get-CodexSessions.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

#### macOS

```powershell
./Get-CodexSessions.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### 按标题查找会话

#### Windows

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object { $_.Title -like "*SampleProject*" } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

#### macOS

```powershell
./Get-CodexSessions.ps1 |
    Where-Object { $_.Title -like "*SampleProject*" } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

[完整中文使用说明](../Get-CodexSessions-Usage-zh-CN.md)
