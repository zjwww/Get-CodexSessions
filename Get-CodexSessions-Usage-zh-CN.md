# Get-CodexSessions.ps1 使用说明（Windows / macOS）

## 1. 支持环境

| 平台 | PowerShell | 支持情况 |
|---|---|---|
| Windows | Windows PowerShell 5.1 | 支持 |
| Windows | PowerShell 7.x | 支持，推荐 |
| macOS | PowerShell 7.x | 支持 |
| Linux | PowerShell 7.x | 理论上支持 |

默认 Codex 数据目录：

```text
Windows: C:\Users\<用户名>\.codex
macOS:   /Users/<用户名>/.codex
```

脚本会只读读取：

```text
session_index.jsonl
state_5.sqlite        # 系统存在 sqlite3 时，作为标题补充来源
sessions/.../rollout-*.jsonl
```

脚本不会修改 Codex 会话、JSONL、SQLite 数据库或配置。

---

## 2. 参数

| 参数 | 类型 | 默认 | 作用 |
|---|---|---|---|
| `-IncludeInternal` | Switch | 关闭 | 同时显示 `codex-auto-review`、Guardian、Sub-agent、child thread 等内部线程 |
| `-CodexHome` | String | `$HOME/.codex` | 手工指定 Codex 数据目录 |

通用形式：

```powershell
./Get-CodexSessions.ps1 [-IncludeInternal] [-CodexHome <路径>]
```

Windows 常用：

```powershell
.\Get-CodexSessions.ps1
```

macOS 常用：

```powershell
./Get-CodexSessions.ps1
```

---

## 3. 默认行为

直接运行：

```powershell
.\Get-CodexSessions.ps1
```

macOS：

```powershell
./Get-CodexSessions.ps1
```

默认会：

- 只显示正常用户会话
- 排除 `codex-auto-review`
- 排除 Guardian / Sub-agent
- 排除 child thread
- 按 `LastActive` 从新到旧排序

---

## 4. 推荐表格视图

### Windows

```powershell
.\Get-CodexSessions.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### macOS

```powershell
./Get-CodexSessions.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

主要字段：

| 字段 | 含义 |
|---|---|
| `DisplayTitle` | 为表格显示截短后的会话标题 |
| `LastActive` | 最后一次活动时间 |
| `Created` | 会话创建时间 |
| `FirstModel` | 会话最开始实际使用的模型 |
| `FirstEffort` | 最开始的 Reasoning Effort |
| `LastModel` | 最近一次实际使用的模型 |
| `LastEffort` | 最近一次 Reasoning Effort |
| `Project` | CWD 最后一级目录 |

筛选标题时建议使用完整的 `Title`，不要使用可能被截断的 `DisplayTitle`。

---

## 5. 按标题关键字过滤

例如只看标题包含 `VidzDown` 的会话：

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object { $_.Title -like "*VidzDown*" } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

macOS 把开头改为：

```powershell
./Get-CodexSessions.ps1
```

`-like` 默认不区分英文大小写。

### 匹配任意一个关键字

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.Title -like "*VidzDown*" -or
        $_.Title -like "*CopyMoveToMenu*"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### 同时包含多个关键字

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.Title -like "*CopyMoveToMenu*" -and
        $_.Title -like "*发布*"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

---

## 6. 查看某个会话的全部信息

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object { $_.Title -like "*VidzDown2*" } |
    Format-List *
```

可查看：

```text
Title
DisplayTitle
TitleSource
Created
LastActive
SessionId
FirstModel
FirstEffort
LastModel
LastEffort
Project
CWD
Source
ParentThreadId
IsInternal
InternalReason
FirstPrompt
ParseErrors
JsonlPath
```

---

## 7. 按 Session ID 精确查找

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.SessionId -eq "01a04de4-b4e8-7e41-b3e8-2605c078636c"
    } |
    Format-List *
```

---

## 8. 查看某个 Project 的所有会话

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.Project -eq "yt-dlp_Extension"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort -AutoSize
```

按完整 CWD 模糊匹配：

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.CWD -like "*yt-dlp_Extension*"
    } |
    Format-Table DisplayTitle, LastActive, CWD, FirstModel, LastModel -AutoSize
```

---

## 9. 只看最近 N 个会话

最近 10 个：

```powershell
.\Get-CodexSessions.ps1 |
    Select-Object -First 10 |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

由于脚本默认已按 `LastActive` 降序排序，因此这里就是最近使用的 10 个正常会话。

---

## 10. 排序

### 按最后活动时间：新 → 旧

```powershell
.\Get-CodexSessions.ps1 |
    Sort-Object LastActive -Descending |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

### 按最后活动时间：旧 → 新

```powershell
.\Get-CodexSessions.ps1 |
    Sort-Object LastActive |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

### 按创建时间：新 → 旧

```powershell
.\Get-CodexSessions.ps1 |
    Sort-Object Created -Descending |
    Format-Table DisplayTitle, Created, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

---

## 11. 查找中途切换过模型的会话

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.FirstModel -ne $_.LastModel
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, LastModel, Project -AutoSize
```

---

## 12. 查找 Reasoning Effort 改变过的会话

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.FirstEffort -ne $_.LastEffort
    } |
    Format-Table DisplayTitle, LastActive, FirstEffort, LastEffort, FirstModel, LastModel -AutoSize
```

---

## 13. 按模型过滤

例如只看最开始使用 `gpt-5.6-sol` 的会话：

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.FirstModel -eq "gpt-5.6-sol"
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

例如 `gpt-6-astra`：

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.FirstModel -eq "gpt-6-astra"
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

---

## 14. 显示 Codex 内部会话

显示全部会话：

```powershell
.\Get-CodexSessions.ps1 -IncludeInternal
```

只显示内部线程：

```powershell
.\Get-CodexSessions.ps1 -IncludeInternal |
    Where-Object { $_.IsInternal } |
    Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

查看某个 `codex-auto-review` 内部会话的完整信息：

```powershell
.\Get-CodexSessions.ps1 -IncludeInternal |
    Where-Object {
        $_.FirstModel -eq "codex-auto-review"
    } |
    Select-Object -First 1 |
    Format-List *
```

---

## 15. 自定义 Codex 数据目录

### Windows

```powershell
.\Get-CodexSessions.ps1 -CodexHome "D:\CodexData\.codex"
```

### macOS

```powershell
./Get-CodexSessions.ps1 -CodexHome "/Users/yourname/CodexData/.codex"
```

和 `-IncludeInternal` 组合：

```powershell
./Get-CodexSessions.ps1 `
    -CodexHome "/Users/yourname/.codex" `
    -IncludeInternal
```

---

## 16. 导出 CSV

### Windows

```powershell
.\Get-CodexSessions.ps1 |
    Export-Csv `
        -Path ".\CodexSessions.csv" `
        -NoTypeInformation `
        -Encoding UTF8
```

### macOS

```powershell
./Get-CodexSessions.ps1 |
    Export-Csv `
        -Path "./CodexSessions.csv" `
        -NoTypeInformation `
        -Encoding UTF8
```

只导出指定字段：

```powershell
.\Get-CodexSessions.ps1 |
    Select-Object `
        Title,
        LastActive,
        Created,
        FirstModel,
        FirstEffort,
        LastModel,
        LastEffort,
        Project,
        SessionId,
        JsonlPath |
    Export-Csv `
        ".\CodexSessions.csv" `
        -NoTypeInformation `
        -Encoding UTF8
```

导出 CSV 只会新建 CSV 文件，不会修改 Codex 原始数据。

---

## 17. 取得 JSONL 文件路径

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.Title -like "*VidzDown2*"
    } |
    Select-Object Title, JsonlPath
```

只取得路径字符串：

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.Title -like "*VidzDown2*"
    } |
    Select-Object -ExpandProperty JsonlPath
```

---

## 18. 直接打开 JSONL 所在目录

### Windows

```powershell
$session = .\Get-CodexSessions.ps1 |
    Where-Object {
        $_.Title -like "*VidzDown2*"
    } |
    Select-Object -First 1

explorer.exe (Split-Path $session.JsonlPath)
```

### macOS

```powershell
$session = ./Get-CodexSessions.ps1 |
    Where-Object {
        $_.Title -like "*VidzDown2*"
    } |
    Select-Object -First 1

open (Split-Path $session.JsonlPath)
```

---

## 19. Windows / macOS 主要差异

| Windows | macOS |
|---|---|
| `.\Get-CodexSessions.ps1` | `./Get-CodexSessions.ps1` |
| `$HOME` → `C:\Users\User` | `$HOME` → `/Users/User` |
| `sqlite3.exe` / `sqlite3` | `sqlite3` |
| `explorer.exe` | `open` |

脚本内部已经自动处理默认 Codex Home 和路径差异。

---

## 20. 最推荐记住的 4 条命令

### 查看全部正常会话

```powershell
.\Get-CodexSessions.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### 按标题搜索

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object { $_.Title -like "*VidzDown*" } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### 查看某个会话全部信息

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

macOS 下把命令开头的 `.\` 改成 `./` 即可，其余 PowerShell 管道与筛选语法相同。
