# Get-CodexSessions-v1.6.ps1 Usage Guide (Windows / macOS)

v1.6 was statically reviewed for macOS PowerShell 7 compatibility; native macOS runtime remains unverified. The historical macOS runtime test for v1.0 does not verify this version.

Longer commands below provide a **Multiline** form and an equivalent **Single line** form. A simple invocation containing only the script name is identical in both forms. Square and angle brackets in the parameter synopsis are notation and must not be run literally.

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
.codex-global-state.json # Saved project definitions and thread assignments
state_5.sqlite        # Optional titles and formal project assignments when sqlite3 is available
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
| `-ColorOutput` | Switch | Off | Render a display-only terminal table and color standalone-session rows |
| `-Property` | String array | Ten commonly used fields | Select and order columns in `-ColorOutput` mode; aliases: `-Properties`, `-Columns` |
| `-StandaloneColor` | `ConsoleColor` | `Yellow` | Select the standalone-row foreground color in `-ColorOutput` mode |

General syntax:

```text
./Get-CodexSessions-v1.6.ps1 [-IncludeInternal] [-CodexHome <path>] [-NoProgress] [-ColorOutput] [-Property <name[]>] [-StandaloneColor <color>]
```

Typical Windows form:

```powershell
.\Get-CodexSessions-v1.6.ps1
```

Typical macOS form:

```powershell
./Get-CodexSessions-v1.6.ps1
```

---

## 3. Default behavior

Run directly:

```powershell
.\Get-CodexSessions-v1.6.ps1
```

On macOS:

```powershell
./Get-CodexSessions-v1.6.ps1
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

For larger session stores, an in-memory compiled pre-scanner skips unrelated JSONL records before PowerShell parses the required metadata. It is read-only, has no external dependency, and automatically falls back to the standard PowerShell reader if compilation is unavailable.

Suppress progress output for automation or other non-interactive use:

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 `
    -NoProgress
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 -NoProgress
```

### Colored terminal view

Highlight complete standalone-session rows and select the displayed columns:

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 `
    -ColorOutput `
    -Property DisplayTitle, LastActive, Project, ProjectId, ProjectPath
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 -ColorOutput -Property DisplayTitle, LastActive, Project, ProjectId, ProjectPath
```

Choose another foreground color:

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 `
    -ColorOutput `
    -Property DisplayTitle, Project, ProjectPath `
    -StandaloneColor Magenta
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 -ColorOutput -Property DisplayTitle, Project, ProjectPath -StandaloneColor Magenta
```

`-ColorOutput` writes a terminal table through the current PowerShell host and does not emit session objects. Do not append `Format-Table`, `Where-Object`, `Sort-Object`, or export commands to that display-only invocation. Omit `-ColorOutput` whenever an object pipeline is required.

---

## 4. Recommended table view

### Windows

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### macOS

**Multiline**

```powershell
./Get-CodexSessions-v1.6.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**Single line**

```powershell
./Get-CodexSessions-v1.6.ps1 | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

Main fields:

| Field | Meaning |
|---|---|
| `DisplayTitle` | Shortened title for table display |
| `LastActive` | Last session activity time |
| `Created` | Session creation time |
| `FirstModel` | Model used at the beginning of the session |
| `FirstEffort` | Initial Reasoning Effort |
| `LastModel` | Most recently used model; ends with ` *` when it differs from `FirstModel` |
| `LastEffort` | Most recent Reasoning Effort; ends with ` *` when it differs from `FirstEffort` |
| `LastModelRaw` | Most recently used model without the change marker |
| `LastEffortRaw` | Most recent Reasoning Effort without the change marker |
| `Project` | Saved Codex project name, or `<Standalone Session>` when no formal assignment exists |
| `ProjectId` | Saved Codex project ID, or `<N/A>` for a standalone session |
| `ProjectPath` | Saved project root path, or the complete recorded `CWD` for a standalone session |
| `ProjectSource` | Project lookup source: `state_5.sqlite`, `global_state`, `standalone`, or `none` |
| `CWD` | Working directory recorded for the session |

For title filtering, use the full `Title` field rather than the truncated `DisplayTitle` field.

---

## 5. Filter sessions by title keyword

Example: show titles containing `SampleProject`.

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object { $_.Title -like "*SampleProject*" } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProject*" } | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

On macOS, use:

```powershell
./Get-CodexSessions-v1.6.ps1
```

at the beginning instead.

`-like` is case-insensitive by default.

### Match any of several keywords

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProject*" -or
        $_.Title -like "*SampleProjectArchive*"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProject*" -or $_.Title -like "*SampleProjectArchive*" } | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### Require multiple keywords

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProjectArchive*" -and
        $_.Title -like "*Release*"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" -and $_.Title -like "*Release*" } | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

---

## 6. Show all details for a session

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object { $_.Title -like "*SampleProjectArchive*" } |
    Format-List *
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" } | Format-List *
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

## 7. Find a specific Session ID

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.SessionId -eq "01234567-89ab-cdef-0123-456789abcdef"
    } |
    Format-List *
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.SessionId -eq "01234567-89ab-cdef-0123-456789abcdef" } | Format-List *
```

---

## 8. Show all sessions for a Project

`Project` uses the saved Codex project name when a formal assignment is available. A session without a formal project assignment uses `<Standalone Session>`, `<N/A>`, and its complete recorded `CWD` for `Project`, `ProjectId`, and `ProjectPath`, respectively.

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Project -eq "SampleProject"
    } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Project -eq "SampleProject" } | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort -AutoSize
```

Match an exact saved Project ID instead:

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.ProjectId -eq "01234567-89ab-cdef-0123-456789abcdef"
    } |
    Format-Table DisplayTitle, LastActive, Project, ProjectPath -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.ProjectId -eq "01234567-89ab-cdef-0123-456789abcdef" } | Format-Table DisplayTitle, LastActive, Project, ProjectPath -AutoSize
```

Match the full CWD instead:

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.CWD -like "*SampleProject*"
    } |
    Format-Table DisplayTitle, LastActive, CWD, FirstModel, LastModel -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.CWD -like "*SampleProject*" } | Format-Table DisplayTitle, LastActive, CWD, FirstModel, LastModel -AutoSize
```

---

## 9. Show only the most recent N sessions

Latest 10 sessions:

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Select-Object -First 10 |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Select-Object -First 10 | Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

Because the script already sorts by `LastActive` descending, these are the 10 most recently used normal sessions.

---

## 10. Sorting

### Last activity: newest → oldest

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Sort-Object LastActive -Descending |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Sort-Object LastActive -Descending | Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

### Last activity: oldest → newest

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Sort-Object LastActive |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Sort-Object LastActive | Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

### Creation time: newest → oldest

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Sort-Object Created -Descending |
    Format-Table DisplayTitle, Created, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Sort-Object Created -Descending | Format-Table DisplayTitle, Created, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

---

## 11. Show sessions that switched models

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.FirstModel -ne $_.LastModelRaw
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, LastModel, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.FirstModel -ne $_.LastModelRaw } | Format-Table DisplayTitle, LastActive, FirstModel, LastModel, Project -AutoSize
```

---

## 12. Show sessions whose Reasoning Effort changed

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.FirstEffort -ne $_.LastEffortRaw
    } |
    Format-Table DisplayTitle, LastActive, FirstEffort, LastEffort, FirstModel, LastModel -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.FirstEffort -ne $_.LastEffortRaw } | Format-Table DisplayTitle, LastActive, FirstEffort, LastEffort, FirstModel, LastModel -AutoSize
```

---

## 13. Filter by model

Example: sessions that started with `gpt-5.6-sol`.

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.FirstModel -eq "gpt-5.6-sol"
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.FirstModel -eq "gpt-5.6-sol" } | Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

Example: sessions that started with `gpt-6-astra`.

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.FirstModel -eq "gpt-6-astra"
    } |
    Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.FirstModel -eq "gpt-6-astra" } | Format-Table DisplayTitle, LastActive, FirstModel, FirstEffort, Project -AutoSize
```

---

## 14. Show Codex internal sessions

Show all sessions:

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 `
    -IncludeInternal
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal
```

Show internal sessions only:

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal |
    Where-Object { $_.IsInternal } |
    Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal | Where-Object { $_.IsInternal } | Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

Show full details for a `codex-auto-review` thread:

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal |
    Where-Object {
        $_.FirstModel -eq "codex-auto-review"
    } |
    Select-Object -First 1 |
    Format-List *
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal | Where-Object { $_.FirstModel -eq "codex-auto-review" } | Select-Object -First 1 | Format-List *
```

---

## 15. Use a custom Codex data directory

### Windows

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 `
    -CodexHome "D:\CodexData\.codex"
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 -CodexHome "D:\CodexData\.codex"
```

### macOS

**Multiline**

```powershell
./Get-CodexSessions-v1.6.ps1 `
    -CodexHome "/Users/yourname/CodexData/.codex"
```

**Single line**

```powershell
./Get-CodexSessions-v1.6.ps1 -CodexHome "/Users/yourname/CodexData/.codex"
```

Combine with `-IncludeInternal`:

**Multiline**

```powershell
./Get-CodexSessions-v1.6.ps1 `
    -CodexHome "/Users/yourname/.codex" `
    -IncludeInternal
```

**Single line**

```powershell
./Get-CodexSessions-v1.6.ps1 -CodexHome "/Users/yourname/.codex" -IncludeInternal
```

---

## 16. Export to CSV

### Windows

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Export-Csv `
        -Path ".\CodexSessions.csv" `
        -NoTypeInformation `
        -Encoding UTF8
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Export-Csv -Path ".\CodexSessions.csv" -NoTypeInformation -Encoding UTF8
```

### macOS

**Multiline**

```powershell
./Get-CodexSessions-v1.6.ps1 |
    Export-Csv `
        -Path "./CodexSessions.csv" `
        -NoTypeInformation `
        -Encoding UTF8
```

**Single line**

```powershell
./Get-CodexSessions-v1.6.ps1 | Export-Csv -Path "./CodexSessions.csv" -NoTypeInformation -Encoding UTF8
```

Export selected fields only:

**Multiline**

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

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Select-Object Title, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project, SessionId, JsonlPath | Export-Csv ".\CodexSessions.csv" -NoTypeInformation -Encoding UTF8
```

Exporting creates a new CSV file but does not modify the original Codex data.

---

## 17. Get the JSONL file path

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProjectArchive*"
    } |
    Select-Object Title, JsonlPath
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" } | Select-Object Title, JsonlPath
```

Return only the path string:

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProjectArchive*"
    } |
    Select-Object -ExpandProperty JsonlPath
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" } | Select-Object -ExpandProperty JsonlPath
```

---

## 18. Open the folder containing the JSONL file

### Windows

**Multiline**

```powershell
$session = .\Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProjectArchive*"
    } |
    Select-Object -First 1

explorer.exe (Split-Path $session.JsonlPath)
```

**Single line**

```powershell
$session = .\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" } | Select-Object -First 1; explorer.exe (Split-Path $session.JsonlPath)
```

### macOS

**Multiline**

```powershell
$session = ./Get-CodexSessions-v1.6.ps1 |
    Where-Object {
        $_.Title -like "*SampleProjectArchive*"
    } |
    Select-Object -First 1

open (Split-Path $session.JsonlPath)
```

**Single line**

```powershell
$session = ./Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProjectArchive*" } | Select-Object -First 1; open (Split-Path $session.JsonlPath)
```

---

## 19. Main Windows / macOS differences

| Windows | macOS |
|---|---|
| `.\Get-CodexSessions-v1.6.ps1` | `./Get-CodexSessions-v1.6.ps1` |
| `$HOME` → `C:\Users\User` | `$HOME` → `/Users/User` |
| `sqlite3.exe` / `sqlite3` | `sqlite3` |
| `explorer.exe` | `open` |

The script already handles the platform-specific default Codex Home and path differences.

---

## 20. Four most useful commands to remember

### Show all normal sessions

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### Search by title

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object { $_.Title -like "*SampleProject*" } |
    Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProject*" } | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project -AutoSize
```

### Show all details for a matching session

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 |
    Where-Object { $_.Title -like "*SampleProject*" } |
    Format-List *
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 | Where-Object { $_.Title -like "*SampleProject*" } | Format-List *
```

### Inspect Codex internal threads

**Multiline**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal |
    Where-Object { $_.IsInternal } |
    Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

**Single line**

```powershell
.\Get-CodexSessions-v1.6.ps1 -IncludeInternal | Where-Object { $_.IsInternal } | Format-Table DisplayTitle, LastActive, FirstModel, InternalReason, Project -AutoSize
```

On macOS, replace the initial `.\` with `./`. All other PowerShell pipeline and filtering syntax stays the same.
