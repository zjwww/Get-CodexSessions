# Get-CodexSessions-v1.6.ps1 使用说明（Windows / macOS）

v1.6 已静态复核 macOS PowerShell 7 兼容性；尚未进行 macOS 实机运行验证。v1.0 的 macOS 历史实测不能作为本版本的实测证明。

以下较长命令同时提供**多行写法**和等价的**单行写法**。只有脚本名、不带参数的简单调用在两种写法中相同。参数总览中的方括号和尖括号仅为语法说明，不能原样执行。

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
.codex-global-state.json # 保存的项目定义和会话归属关系
state_5.sqlite        # 系统存在 sqlite3 时，补充标题和正式项目归属
sessions/.../rollout-*.jsonl
```

脚本不会修改 Codex 会话、JSONL、SQLite 数据库或配置。

---

## 2. 参数

| 参数 | 类型 | 默认 | 作用 |
|---|---|---|---|
| `-IncludeInternal` | Switch | 关闭 | 同时显示 `codex-auto-review`、Guardian、Sub-agent、child thread 等内部线程 |
| `-CodexHome` | String | `$HOME/.codex` | 手工指定 Codex 数据目录 |
| `-NoProgress` | Switch | 关闭 | 扫描 rollout 文件时关闭宿主原生进度显示 |
| `-ColorOutput` | Switch | 关闭 | 渲染纯显示终端表格，并给独立会话整行着色 |
| `-Property` | 字符串数组 | 十个常用字段 | 选择并排列 `-ColorOutput` 模式中的列；别名：`-Properties`、`-Columns` |
| `-StandaloneColor` | `ConsoleColor` | `Yellow` | 选择 `-ColorOutput` 模式中独立会话行的前景色 |

通用形式：

```text
./Get-CodexSessions-v1.6.ps1 [-IncludeInternal] [-CodexHome <路径>] [-NoProgress] [-ColorOutput] [-Property <名称[]>] [-StandaloneColor <颜色>]
```

Windows 常用：

```powershell
.\Get-CodexSessions-v1.6.ps1
```

macOS 常用：

```powershell
./Get-CodexSessions-v1.6.ps1
```

---

## 3. 默认行为

直接运行：

```powershell
.\Get-CodexSessions-v1.6.ps1
```

macOS：

```powershell
./Get-CodexSessions-v1.6.ps1
```

默认会：

- 只显示正常用户会话
- 排除 `codex-auto-review`
- 排除 Guardian / Sub-agent
- 排除 child thread
- 扫描 rollout 文件时显示宿主原生的整体进度
- 按 `LastActive` 从新到旧排序

### 进度显示

脚本只调用 PowerShell 标准 `Write-Progress` 命令，不强制指定显示样式。因此，Windows PowerShell 5.1 使用默认 Classic 样式，PowerShell 7.x 使用自身已配置或默认的样式，通常为 Minimal。

进度百分比根据已处理的 rollout 文件数量计算。由于不同 rollout 文件的大小可能不同，它表示总体文件数量进度，并不是精确的剩余时间估计。

会话数据较大时，内存中编译的预扫描器会先跳过无关 JSONL 记录，再由 PowerShell 解析所需元数据。该优化只读、不依赖外部组件；如果当前环境不允许编译，则会自动回退到标准 PowerShell 读取方式。

自动化或其他非交互场景可关闭进度显示：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 `
    -NoProgress
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 -NoProgress
```

### 彩色终端视图

突出显示完整的独立会话行，并选择需要显示的列：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 `
    -ColorOutput `
    -Property DisplayTitle, LastActive, Project, ProjectId, ProjectPath
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 -ColorOutput -Property DisplayTitle, LastActive, Project, ProjectId, ProjectPath
```

选择其他前景色：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 `
    -ColorOutput `
    -Property DisplayTitle, Project, ProjectPath `
    -StandaloneColor Magenta
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 -ColorOutput -Property DisplayTitle, Project, ProjectPath -StandaloneColor Magenta
```

`-ColorOutput` 通过当前 PowerShell 宿主写出终端表格，不再输出会话对象。不要在这条纯显示命令后继续连接 `Format-Table`、`Where-Object`、`Sort-Object` 或导出命令；需要对象管道时不要使用 `-ColorOutput`。

---

## 4. 推荐表格视图

### Windows

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### macOS

**多行写法**

```powershell
./Get-CodexSessions-v1.6.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**单行写法**

```powershell
./Get-CodexSessions-v1.6.ps1 | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

主要字段：

| 字段 | 含义 |
|---|---|
| `DisplayTitle` | 为表格显示截短后的会话标题 |
| `LastActive` | 最后一次活动时间 |
| `Created` | 会话创建时间 |
| `FirstModel` | 会话最开始实际使用的模型 |
| `FirstEffort` | 最开始的 Reasoning Effort |
| `LastModel` | 最近一次实际使用的模型；与 `FirstModel` 不同时在末尾添加 ` *` |
| `LastEffort` | 最近一次 Reasoning Effort；与 `FirstEffort` 不同时在末尾添加 ` *` |
| `LastModelRaw` | 不带变化标记的最近模型原始值 |
| `LastEffortRaw` | 不带变化标记的最近 Reasoning Effort 原始值 |
| `Project` | 保存的 Codex 项目名称；没有正式归属时为 `<Standalone Session>` |
| `ProjectId` | 保存的 Codex Project ID；独立会话为 `<N/A>` |
| `ProjectPath` | 保存的项目根路径；独立会话为其记录的完整 `CWD` |
| `ProjectSource` | 项目归属来源：`state_5.sqlite`、`global_state`、`standalone` 或 `none` |
| `CWD` | 会话记录的工作目录 |

筛选标题时建议使用完整的 `Title`，不要使用可能被截断的 `DisplayTitle`。

---

## 5. 按标题关键字过滤

例如只看标题包含 `SampleProject` 的会话：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object { $_.Title -like "*SampleProject*" } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProject*" } | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

macOS 把开头改为：

```powershell
./Get-CodexSessions-v1.6.ps1
```

`-like` 默认不区分英文大小写。

### 匹配任意一个关键字

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProject*" -or
        $_.Title -like "*SampleProjectArchive*"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProject*" -or $_.Title -like "*SampleProjectArchive*" } | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### 同时包含多个关键字

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProjectArchive*" -and
        $_.Title -like "*Release*"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" -and $_.Title -like "*Release*" } | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

---

## 6. 查看某个会话的全部信息

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object { $_.Title -like "*SampleProjectArchive*" } |
    Format-List *
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" } | Format-List *
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
LastModelRaw
LastEffortRaw
Project
ProjectId
ProjectPath
ProjectSource
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

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.SessionId -eq "01234567-89ab-cdef-0123-456789abcdef"
    } |
    Format-List *
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.SessionId -eq "01234567-89ab-cdef-0123-456789abcdef" } | Format-List *
```

---

## 8. 查看某个 Project 的所有会话

存在正式项目归属时，`Project` 使用 Codex 中保存的项目名称。没有正式项目归属的会话，其 `Project`、`ProjectId` 和 `ProjectPath` 分别使用 `<Standalone Session>`、`<N/A>` 和会话记录的完整 `CWD`。

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Project -eq "SampleProject"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Project -eq "SampleProject" } | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort -AutoSize
```

也可以按保存的 Project ID 精确匹配：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.ProjectId -eq "01234567-89ab-cdef-0123-456789abcdef"
    } |
    Format-Table DisplayTitle, LastActive, Project, ProjectPath -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.ProjectId -eq "01234567-89ab-cdef-0123-456789abcdef" } | Format-Table DisplayTitle, LastActive, Project, ProjectPath -AutoSize
```

按完整 CWD 模糊匹配：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.CWD -like "*SampleProject*"
    } |
    Format-Table DisplayTitle, LastActive, CWD, FirstModel, LastModel -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.CWD -like "*SampleProject*" } | Format-Table DisplayTitle, LastActive, CWD, FirstModel, LastModel -AutoSize
```

---

## 9. 只看最近 N 个会话

最近 10 个：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Select-Object -First 10 |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Select-Object -First 10 | Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

由于脚本默认已按 `LastActive` 降序排序，因此这里就是最近使用的 10 个正常会话。

---

## 10. 排序

### 按最后活动时间：新 → 旧

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Sort-Object LastActive -Descending |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Sort-Object LastActive -Descending | Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

### 按最后活动时间：旧 → 新

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Sort-Object LastActive |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Sort-Object LastActive | Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

### 按创建时间：新 → 旧

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Sort-Object Created -Descending |
    Format-Table DisplayTitle, Created, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Sort-Object Created -Descending | Format-Table DisplayTitle, Created, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

---

## 11. 查找中途切换过模型的会话

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.FirstModel -ne $_.LastModelRaw
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, LastModel, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.FirstModel -ne $_.LastModelRaw } | Format-Table DisplayTitle, LastActive, FirstModel, LastModel, Project -AutoSize
```

---

## 12. 查找 Reasoning Effort 改变过的会话

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.FirstEffort -ne $_.LastEffortRaw
    } |
    Format-Table DisplayTitle, LastActive, FirstEffort, LastEffort, FirstModel, LastModel -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.FirstEffort -ne $_.LastEffortRaw } | Format-Table DisplayTitle, LastActive, FirstEffort, LastEffort, FirstModel, LastModel -AutoSize
```

---

## 13. 按模型过滤

例如只看最开始使用 `gpt-5.6-sol` 的会话：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.FirstModel -eq "gpt-5.6-sol"
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.FirstModel -eq "gpt-5.6-sol" } | Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

例如 `gpt-6-astra`：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.FirstModel -eq "gpt-6-astra"
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.FirstModel -eq "gpt-6-astra" } | Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

---

## 14. 显示 Codex 内部会话

显示全部会话：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 `
    -IncludeInternal
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal
```

只显示内部线程：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal |
    Where-Object { $_.IsInternal } |
    Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal | Where-Object { $_.IsInternal } | Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

查看某个 `codex-auto-review` 内部会话的完整信息：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal |
    Where-Object {
        $_.FirstModel -eq "codex-auto-review"
    } |
    Select-Object -First 1 |
    Format-List *
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal | Where-Object { $_.FirstModel -eq "codex-auto-review" } | Select-Object -First 1 | Format-List *
```

---

## 15. 自定义 Codex 数据目录

### Windows

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 `
    -CodexHome "D:\CodexData\.codex"
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 -CodexHome "D:\CodexData\.codex"
```

### macOS

**多行写法**

```powershell
./Get-CodexSessions-v1.6.ps1 `
    -CodexHome "/Users/yourname/CodexData/.codex"
```

**单行写法**

```powershell
./Get-CodexSessions-v1.6.ps1 -CodexHome "/Users/yourname/CodexData/.codex"
```

和 `-IncludeInternal` 组合：

**多行写法**

```powershell
./Get-CodexSessions-v1.6.ps1 `
    -CodexHome "/Users/yourname/.codex" `
    -IncludeInternal
```

**单行写法**

```powershell
./Get-CodexSessions-v1.6.ps1 -CodexHome "/Users/yourname/.codex" -IncludeInternal
```

---

## 16. 导出 CSV

### Windows

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Export-Csv `
        -Path ".\CodexSessions.csv" `
        -NoTypeInformation `
        -Encoding UTF8
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Export-Csv -Path ".\CodexSessions.csv" -NoTypeInformation -Encoding UTF8
```

### macOS

**多行写法**

```powershell
./Get-CodexSessions-v1.6.ps1 |
    Export-Csv `
        -Path "./CodexSessions.csv" `
        -NoTypeInformation `
        -Encoding UTF8
```

**单行写法**

```powershell
./Get-CodexSessions-v1.6.ps1 | Export-Csv -Path "./CodexSessions.csv" -NoTypeInformation -Encoding UTF8
```

只导出指定字段：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
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

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Select-Object Title, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project, SessionId, JsonlPath | Export-Csv ".\CodexSessions.csv" -NoTypeInformation -Encoding UTF8
```

导出 CSV 只会新建 CSV 文件，不会修改 Codex 原始数据。

---

## 17. 取得 JSONL 文件路径

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProjectArchive*"
    } |
    Select-Object Title, JsonlPath
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" } | Select-Object Title, JsonlPath
```

只取得路径字符串：

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProjectArchive*"
    } |
    Select-Object -ExpandProperty JsonlPath
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" } | Select-Object -ExpandProperty JsonlPath
```

---

## 18. 直接打开 JSONL 所在目录

### Windows

**多行写法**

```powershell
$session = .\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProjectArchive*"
    } |
    Select-Object -First 1

explorer.exe (Split-Path $session.JsonlPath)
```

**单行写法**

```powershell
$session = .\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" } | Select-Object -First 1; explorer.exe (Split-Path $session.JsonlPath)
```

### macOS

**多行写法**

```powershell
$session = ./Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProjectArchive*"
    } |
    Select-Object -First 1

open (Split-Path $session.JsonlPath)
```

**单行写法**

```powershell
$session = ./Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" } | Select-Object -First 1; open (Split-Path $session.JsonlPath)
```

---

## 19. Windows / macOS 主要差异

| Windows | macOS |
|---|---|
| `.\Get-CodexSessions-v1.6.ps1` | `./Get-CodexSessions-v1.6.ps1` |
| `$HOME` → `C:\Users\User` | `$HOME` → `/Users/User` |
| `sqlite3.exe` / `sqlite3` | `sqlite3` |
| `explorer.exe` | `open` |

脚本内部已经自动处理默认 Codex Home 和路径差异。

---

## 20. 最推荐记住的 4 条命令

### 查看全部正常会话

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### 按标题搜索

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object { $_.Title -like "*SampleProject*" } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProject*" } | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### 查看某个会话全部信息

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object { $_.Title -like "*SampleProject*" } |
    Format-List *
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProject*" } | Format-List *
```

### 查看 Codex 内部线程

**多行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal |
    Where-Object { $_.IsInternal } |
    Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

**单行写法**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal | Where-Object { $_.IsInternal } | Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

macOS 下把命令开头的 `.\` 改成 `./` 即可，其余 PowerShell 管道与筛选语法相同。
