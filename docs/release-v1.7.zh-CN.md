# What's new

## 简体中文

- 从最初及最后一个可用的 `thread_settings_applied` 事件新增 `FirstServiceTier` 和 `LastServiceTier`，保留原始 service tier 字符串。
- 新增 `FirstSpeedMode` 和 `LastSpeedMode`：`priority`/`fast` 映射为 `Fast`，`default` 映射为 `Standard`，`ultrafast` 映射为 `Ultrafast`，`flex` 映射为 `Flex`；缺失或无法识别的 tier 映射为 `Unknown`。
- 彩色默认表格和推荐表格示例新增 `LastSpeedMode`。四个新增字段均可用于结构化对象输出，也都可作为彩色表格的可选列。
- 大型数据编译扫描器保留已应用的设置事件，标准 PowerShell 读取器继续作为自动回退路径。Codex 数据访问保持只读。
- 同步双语字段说明，并提供筛选“最后记录速度模式为 `Fast`”的多行/单行示例。

“最后”表示该会话 rollout 中最后一个可用的设置，不是当前全局配置。Fast 不统一标为固定的速度倍率。

已在 Windows PowerShell 5.1.26100.9444 和 Codex 内置 PowerShell 7.6.5 运行时通过语法解析及合成数据回归，覆盖 tier 切换、缺失/未知值、JSON 空白、Raw 字段、对象/彩色输出、进度及大型扫描回退。以下单行命令已在两种引擎中使用合成数据复核。

已静态复核 macOS PowerShell 7 兼容性；尚未进行 macOS 实机运行验证。历史 macOS 实测证据仅属于 v1.0。Linux 仍为尽力支持，本次未做实机测试。

### 基本运行命令

Windows（PowerShell 5.1 或 7.x）：

对象表格：

```powershell
.\Get-CodexSessions-v1.7.ps1 | Format-Table DisplayTitle, Project, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, LastSpeedMode, Project -AutoSize
```

彩色表格（独立会话行显示为黄色）：

```powershell
.\Get-CodexSessions-v1.7.ps1 -ColorOutput -Property DisplayTitle, Project, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, LastSpeedMode -StandaloneColor Yellow
```

macOS（PowerShell 7.x）：

对象表格：

```powershell
./Get-CodexSessions-v1.7.ps1 | Format-Table DisplayTitle, Project, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, LastSpeedMode, Project -AutoSize
```

彩色表格（独立会话行显示为黄色）：

```powershell
./Get-CodexSessions-v1.7.ps1 -ColorOutput -Property DisplayTitle, Project, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, LastSpeedMode -StandaloneColor Yellow
```

[完整中文使用说明](../Get-CodexSessions-Usage-zh-CN.md)
