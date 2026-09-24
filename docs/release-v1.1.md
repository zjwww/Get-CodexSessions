# What's new

## English

- Adds overall rollout-file scanning progress through the standard PowerShell `Write-Progress` command.
- Keeps each host's native presentation: Windows PowerShell 5.1 uses Classic, while PowerShell 7.x uses its configured/default view, normally Minimal.
- Adds `-NoProgress` for automation and other non-interactive use.
- Calculates progress from the number of processed rollout files; parsing, filtering, sorting, and read-only behavior are unchanged.
- Controlled fixture tests passed on Windows PowerShell 5.1.26100.9444 and the Codex-bundled PowerShell 7.6.5 runtime. A live scan also completed on that bundled PowerShell 7 runtime. This release was not re-tested on macOS.

### Basic usage

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

### Find sessions by title

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

[Full usage guide in English](../Get-CodexSessions-Usage-en.md)
