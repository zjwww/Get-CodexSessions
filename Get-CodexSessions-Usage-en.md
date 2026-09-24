# Get-CodexSessions.ps1 Usage Guide (Windows / macOS)

## 1. Supported environments

| Platform | PowerShell | Status |
|---|---|---|
| Windows | Windows PowerShell 5.1 | Supported |
| Windows | PowerShell 7.x | Supported, recommended |
| macOS | PowerShell 7.x | Supported |
| Linux | PowerShell 7.x | Expected to work |

Default Codex data directories:

```text
Windows: C:\Users\<username>\.codex
macOS:   /Users/<username>/.codex
```

The script reads these sources in read-only mode:

```text
session_index.jsonl
state_5.sqlite        # Optional title source when sqlite3 is available
sessions/.../rollout-*.jsonl
```

The script does not modify Codex sessions, JSONL files, SQLite databases, or Codex configuration.

---

## 2. Parameters

| Parameter | Type | Default | Purpose |
|---|---|---|---|
| `-IncludeInternal` | Switch | Off | Also show internal Codex threads such as `codex-auto-review`, Guardian, Sub-agent, and child threads |
| `-CodexHome` | String | `$HOME/.codex` | Manually specify the Codex data directory |
| `-NoProgress` | Switch | Off | Suppress the host-native progress display while rollout files are scanned |

General syntax:

```powershell
./Get-CodexSessions.ps1 [-IncludeInternal] [-CodexHome <path>] [-NoProgress]
```

Typical Windows form:

```powershell
.\Get-CodexSessions.ps1
```

Typical macOS form:

```powershell
./Get-CodexSessions.ps1
```

---

## 3. Default behavior

Run directly:

```powershell
.\Get-CodexSessions.ps1
```

On macOS:

```powershell
./Get-CodexSessions.ps1
```

By default, the script:

- Shows normal user sessions only
- Filters out `codex-auto-review`
- Filters out Guardian / Sub-agent threads
- Filters out child threads
- Shows host-native overall progress while rollout files are scanned
- Sorts by `LastActive`, newest first

### Progress display

The script uses the standard PowerShell `Write-Progress` command without forcing a presentation style. Windows PowerShell 5.1 therefore uses its default Classic presentation, while PowerShell 7.x uses its configured/default presentation, normally Minimal.

The progress percentage is based on the number of rollout files processed. Because rollout files can have different sizes, it is an overall file-count indicator rather than an exact estimate of remaining time.

Suppress progress output for automation or other non-interactive use:

```powershell
.\Get-CodexSessions.ps1 -NoProgress
```

---

## 4. Recommended table view

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

Main fields:

| Field | Meaning |
|---|---|
| `DisplayTitle` | Shortened title for table display |
| `LastActive` | Last session activity time |
| `Created` | Session creation time |
| `FirstModel` | Model used at the beginning of the session |
| `FirstEffort` | Initial Reasoning Effort |
| `LastModel` | Most recently used model |
| `LastEffort` | Most recent Reasoning Effort |
| `Project` | Final directory component of CWD |

For title filtering, use the full `Title` field rather than the truncated `DisplayTitle` field.

---

## 5. Filter sessions by title keyword

Example: show titles containing `VidzDown`.

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object { $_.Title -like "*VidzDown*" } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

On macOS, use:

```powershell
./Get-CodexSessions.ps1
```

at the beginning instead.

`-like` is case-insensitive by default.

### Match any of several keywords

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.Title -like "*VidzDown*" -or
        $_.Title -like "*CopyMoveToMenu*"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### Require multiple keywords

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.Title -like "*CopyMoveToMenu*" -and
        $_.Title -like "*Release*"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

---

## 6. Show all details for a session

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object { $_.Title -like "*VidzDown2*" } |
    Format-List *
```

Possible fields include:

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

## 7. Find a specific Session ID

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.SessionId -eq "01a04de4-b4e8-7e41-b3e8-2605c078636c"
    } |
    Format-List *
```

---

## 8. Show all sessions for a Project

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.Project -eq "yt-dlp_Extension"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort -AutoSize
```

Match the full CWD instead:

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.CWD -like "*yt-dlp_Extension*"
    } |
    Format-Table DisplayTitle, LastActive, CWD, FirstModel, LastModel -AutoSize
```

---

## 9. Show only the most recent N sessions

Latest 10 sessions:

```powershell
.\Get-CodexSessions.ps1 |
    Select-Object -First 10 |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

Because the script already sorts by `LastActive` descending, these are the 10 most recently used normal sessions.

---

## 10. Sorting

### Last activity: newest → oldest

```powershell
.\Get-CodexSessions.ps1 |
    Sort-Object LastActive -Descending |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

### Last activity: oldest → newest

```powershell
.\Get-CodexSessions.ps1 |
    Sort-Object LastActive |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

### Creation time: newest → oldest

```powershell
.\Get-CodexSessions.ps1 |
    Sort-Object Created -Descending |
    Format-Table DisplayTitle, Created, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

---

## 11. Show sessions that switched models

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.FirstModel -ne $_.LastModel
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, LastModel, Project -AutoSize
```

---

## 12. Show sessions whose Reasoning Effort changed

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.FirstEffort -ne $_.LastEffort
    } |
    Format-Table DisplayTitle, LastActive, FirstEffort, LastEffort, FirstModel, LastModel -AutoSize
```

---

## 13. Filter by model

Example: sessions that started with `gpt-5.6-sol`.

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.FirstModel -eq "gpt-5.6-sol"
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

Example: sessions that started with `gpt-6-astra`.

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.FirstModel -eq "gpt-6-astra"
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

---

## 14. Show Codex internal sessions

Show all sessions:

```powershell
.\Get-CodexSessions.ps1 -IncludeInternal
```

Show internal sessions only:

```powershell
.\Get-CodexSessions.ps1 -IncludeInternal |
    Where-Object { $_.IsInternal } |
    Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

Show full details for a `codex-auto-review` thread:

```powershell
.\Get-CodexSessions.ps1 -IncludeInternal |
    Where-Object {
        $_.FirstModel -eq "codex-auto-review"
    } |
    Select-Object -First 1 |
    Format-List *
```

---

## 15. Use a custom Codex data directory

### Windows

```powershell
.\Get-CodexSessions.ps1 -CodexHome "D:\CodexData\.codex"
```

### macOS

```powershell
./Get-CodexSessions.ps1 -CodexHome "/Users/yourname/CodexData/.codex"
```

Combine with `-IncludeInternal`:

```powershell
./Get-CodexSessions.ps1 `
    -CodexHome "/Users/yourname/.codex" `
    -IncludeInternal
```

---

## 16. Export to CSV

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

Export selected fields only:

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

Exporting creates a new CSV file but does not modify the original Codex data.

---

## 17. Get the JSONL file path

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.Title -like "*VidzDown2*"
    } |
    Select-Object Title, JsonlPath
```

Return only the path string:

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object {
        $_.Title -like "*VidzDown2*"
    } |
    Select-Object -ExpandProperty JsonlPath
```

---

## 18. Open the folder containing the JSONL file

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

## 19. Main Windows / macOS differences

| Windows | macOS |
|---|---|
| `.\Get-CodexSessions.ps1` | `./Get-CodexSessions.ps1` |
| `$HOME` → `C:\Users\User` | `$HOME` → `/Users/User` |
| `sqlite3.exe` / `sqlite3` | `sqlite3` |
| `explorer.exe` | `open` |

The script already handles the platform-specific default Codex Home and path differences.

---

## 20. Four most useful commands to remember

### Show all normal sessions

```powershell
.\Get-CodexSessions.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### Search by title

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object { $_.Title -like "*VidzDown*" } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### Show all details for a matching session

```powershell
.\Get-CodexSessions.ps1 |
    Where-Object { $_.Title -like "*VidzDown*" } |
    Format-List *
```

### Inspect Codex internal threads

```powershell
.\Get-CodexSessions.ps1 -IncludeInternal |
    Where-Object { $_.IsInternal } |
    Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

On macOS, replace the initial `.\` with `./`. All other PowerShell pipeline and filtering syntax stays the same.
