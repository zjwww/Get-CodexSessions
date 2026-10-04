# What's new

## 简体中文

相对于上一正式版本 v1.1 的变更：

- 从可选的 Codex SQLite 和 global state 元数据查询正式 Project 归属，新增 `ProjectId`、`ProjectPath` 和 `ProjectSource` 字段。
- 独立会话使用 `<Standalone Session>`、`<N/A>` 和完整的已记录 `CWD`；正式项目归属保留其保存的元数据。
- 大型会话数据使用内存中编译的预扫描器提升扫描速度，并自动回退到纯 PowerShell 读取方式。所有 Codex 数据访问仍保持只读。
- 新增纯显示表格 `-ColorOutput`、`-Property` 列选择（别名 `-Properties` 和 `-Columns`）及 `-StandaloneColor`，独立会话行默认显示为黄色。默认调用继续返回结构化对象。
- 当比较的两个值都存在且不同时，在 `LastModel` 或 `LastEffort` 末尾添加 ` *`。`LastModelRaw` 和 `LastEffortRaw` 保留无标记原始值，供精确筛选和导出。
- 正式发布版本化脚本 `Get-CodexSessions-v1.6.ps1`、对应双语更新日志及扩展的完整 Usage Guide，并提供等价的多行/单行命令。v1.2–v1.5 本地迭代不单独公开脚本、标签、Release 或资产。

已在 Windows PowerShell 5.1.26100.9444 和 Codex 内置 PowerShell 7.6.5 运行时通过验证：语法解析、合成会话回归、编译扫描及编译器不可用时的回退、缺少可选 sqlite3 时的回退、对象/显示输出、颜色、进度和退出码。Usage Guide 命令的两种写法已在合成数据上对比；Explorer/Finder 命令仅做语法检查。

已静态复核 macOS PowerShell 7 兼容性；尚未进行 macOS 实机运行验证。历史 macOS 实测仅适用于 v1.0。Linux 仍为尽力支持，本次未做实机测试。

### 基本运行命令

Windows（PowerShell 5.1 或 7.x）：

对象表格：

```powershell
.\Get-CodexSessions-v1.6.ps1 | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project, ProjectId, ProjectPath -AutoSize
```

彩色表格（独立会话行显示为黄色）：

```powershell
.\Get-CodexSessions-v1.6.ps1 -ColorOutput -Property DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project, ProjectId, ProjectPath -StandaloneColor Yellow
```

macOS（PowerShell 7.x）：

对象表格：

```powershell
./Get-CodexSessions-v1.6.ps1 | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project, ProjectId, ProjectPath -AutoSize
```

彩色表格（独立会话行显示为黄色）：

```powershell
./Get-CodexSessions-v1.6.ps1 -ColorOutput -Property DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project, ProjectId, ProjectPath -StandaloneColor Yellow
```

[完整中文使用说明](../Get-CodexSessions-Usage-zh-CN.md)
