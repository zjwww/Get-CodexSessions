# What's new

## English

Changes since the previous formal release, v1.1:

- Adds formal Project lookup from optional Codex SQLite and global-state metadata, with `ProjectId`, `ProjectPath`, and `ProjectSource` fields.
- Identifies standalone sessions with `<Standalone Session>`, `<N/A>`, and the complete recorded `CWD`; formal project assignments retain their saved metadata.
- Speeds up larger session stores with an in-memory compiled pre-scanner and an automatic pure-PowerShell fallback. All Codex data access remains read-only.
- Adds the display-only `-ColorOutput` table, `-Property` column selection (aliases `-Properties` and `-Columns`), and `-StandaloneColor`, defaulting to yellow for standalone rows. Default invocation continues to return structured objects.
- Appends ` *` to `LastModel` or `LastEffort` when both compared values exist and differ. `LastModelRaw` and `LastEffortRaw` retain unmarked values for exact filtering and export.
- Publishes the versioned script `Get-CodexSessions-v1.6.ps1`, matching bilingual changelogs and expanded Usage Guides with equivalent multiline and single-line examples. The v1.2–v1.5 local iterations have no separate public script, tag, Release, or asset.

Validation passed on Windows PowerShell 5.1.26100.9444 and the Codex-bundled PowerShell 7.6.5 runtime: parsing, synthetic session regression, compiled scanning and compiler-unavailable fallback, missing optional sqlite3 fallback, object/display output, colors, progress, and exit codes. Guide command forms were compared on synthetic data; Explorer/Finder commands were parsed only.

Statically reviewed for macOS PowerShell 7 compatibility; native macOS runtime remains unverified. The historical native macOS test applies to v1.0 only. Linux remains best effort and was not tested for this release.

### Basic usage

Windows (PowerShell 5.1 or 7.x):

Object table:

```powershell
.\Get-CodexSessions-v1.6.ps1 | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project, ProjectId, ProjectPath -AutoSize
```

Colored table (standalone rows in yellow):

```powershell
.\Get-CodexSessions-v1.6.ps1 -ColorOutput -Property DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project, ProjectId, ProjectPath -StandaloneColor Yellow
```

macOS (PowerShell 7.x):

Object table:

```powershell
./Get-CodexSessions-v1.6.ps1 | Format-Table DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project, ProjectId, ProjectPath -AutoSize
```

Colored table (standalone rows in yellow):

```powershell
./Get-CodexSessions-v1.6.ps1 -ColorOutput -Property DisplayTitle, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, Project, ProjectId, ProjectPath -StandaloneColor Yellow
```

[Full usage guide in English](../Get-CodexSessions-Usage-en.md)
