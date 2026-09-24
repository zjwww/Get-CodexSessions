# What's new

## English

- Initial public release of Get-CodexSessions.
- Lists local Codex session titles, creation times, last-active times, project information, session IDs, and rollout JSONL paths.
- Shows the first and most recently used model and reasoning effort for each session.
- Filters Codex internal threads by default and provides `-IncludeInternal` for internal-thread analysis.
- Uses `session_index.jsonl` and rollout JSONL data, with optional read-only SQLite title supplementation when `sqlite3` is available.
- Keeps all Codex data access read-only.
- Supports Windows PowerShell 5.1 and PowerShell 7.x on Windows, plus PowerShell 7.x on macOS. The macOS environment was tested on macOS Tahoe 26.2.

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
