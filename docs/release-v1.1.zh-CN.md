# What's new

## 简体中文

- 通过 PowerShell 标准 `Write-Progress` 命令显示 rollout 文件扫描的整体进度。
- 保留宿主自身的显示方式：Windows PowerShell 5.1 使用 Classic，PowerShell 7.x 使用其已配置或默认的样式，通常为 Minimal。
- 新增 `-NoProgress`，供自动化和其他非交互场景关闭进度显示。
- 进度根据已处理的 rollout 文件数量计算；解析、过滤、排序和只读行为均未改变。
- 受控夹具测试已在 Windows PowerShell 5.1.26100.9444 和 Codex 内置的 PowerShell 7.6.5 运行时通过，并在该内置 PowerShell 7 运行时完成了一次真实扫描。本版未重新进行 macOS 实机测试。

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
