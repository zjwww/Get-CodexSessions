# What's new

## English

- Adds `FirstServiceTier` and `LastServiceTier` from the first and last usable recorded `thread_settings_applied` events, preserving the raw service-tier strings.
- Adds `FirstSpeedMode` and `LastSpeedMode`: `priority`/`fast` maps to `Fast`, `default` to `Standard`, `ultrafast` to `Ultrafast`, and `flex` to `Flex`; missing or unrecognized tiers map to `Unknown`.
- Adds `LastSpeedMode` to the default colored table and recommended table examples. All four new fields are available in structured-object output and as selectable colored-table columns.
- Keeps applied settings records in the compiled scanner for larger stores, with the standard PowerShell reader retained as the automatic fallback. Codex data access remains read-only.
- Adds matching bilingual field documentation and multiline/single-line examples for finding sessions whose last recorded speed mode is `Fast`.

"Last" means the last usable setting recorded in that session's rollout, rather than the current global configuration. Fast is not assigned a fixed speed multiplier.

Script parsing and synthetic regression passed on Windows PowerShell 5.1.26100.9444 and the Codex-bundled PowerShell 7.6.5 runtime, covering tier transitions, missing/unknown values, JSON whitespace, raw fields, object/color output, progress, and large-store scanner fallback. The single-line commands below were checked with both engines on synthetic data.

Statically reviewed for macOS PowerShell 7 compatibility; native macOS runtime remains unverified. Historical native macOS evidence belongs to v1.0 only. Linux remains best effort and was not tested for this release.

### Basic usage

Windows (PowerShell 5.1 or 7.x):

Object table:

```powershell
.\Get-CodexSessions-v1.7.ps1 | Format-Table DisplayTitle, Project, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, LastSpeedMode, Project -AutoSize
```

Colored table (standalone rows in yellow):

```powershell
.\Get-CodexSessions-v1.7.ps1 -ColorOutput -Property DisplayTitle, Project, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, LastSpeedMode -StandaloneColor Yellow
```

macOS (PowerShell 7.x):

Object table:

```powershell
./Get-CodexSessions-v1.7.ps1 | Format-Table DisplayTitle, Project, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, LastSpeedMode, Project -AutoSize
```

Colored table (standalone rows in yellow):

```powershell
./Get-CodexSessions-v1.7.ps1 -ColorOutput -Property DisplayTitle, Project, LastActive, Created, FirstModel, FirstEffort, LastModel, LastEffort, LastSpeedMode -StandaloneColor Yellow
```

[Full usage guide in English](../Get-CodexSessions-Usage-en.md)
