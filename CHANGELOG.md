# Changelog

This document records published releases and subsequent local development versions of Get-CodexSessions. Dates for local iterations follow the recorded UTC calendar date. A version marked **Local development** has not been published as a GitHub Release.

## [v1.6] - 2026-10-04

**Status:** [Published GitHub Release](https://github.com/zjwww/Get-CodexSessions/releases/tag/v1.6); current script: [`Get-CodexSessions-v1.6.ps1`](Get-CodexSessions-v1.6.ps1)

### Changed

- `LastModel` now ends with ` *` when both model values exist and it differs from `FirstModel`.
- `LastEffort` now ends with ` *` when both effort values exist and it differs from `FirstEffort`.
- Added `LastModelRaw` and `LastEffortRaw` so exact unmarked values remain available for filtering and export.
- Added the raw fields to the selectable `-ColorOutput` property list.

### Formal release scope

v1.6 also publishes the changes developed locally in v1.2–v1.5: formal project metadata lookup, large-store pre-scanning with a fallback, standalone-session markers, a configurable colored terminal table, and a versioned script filename. v1.2–v1.5 are not published as separate scripts, tags, or Releases; their actual development history is retained below.

### Validation

The following local development validation was recorded before the formal release:

- Parsed and executed successfully with Windows PowerShell 5.1 and the Codex-bundled PowerShell 7.6.5 runtime.
- Both engines returned 53 normal sessions with zero reported parse-error rows.
- The test data contained 1 marked model change and 16 marked reasoning-effort changes; every marker matched its corresponding raw-value comparison.
- After restoring `LastModel` and `LastEffort` from the raw fields and excluding the two newly added fields, the complete PowerShell 7 JSON output matched v1.5 exactly.
- The colored view displayed change markers, accepted both raw fields, retained standalone-row coloring, and emitted no session objects.
- Statically reviewed for macOS PowerShell 7 compatibility; native macOS runtime remains unverified. The v1.6 changes add only portable string comparison, formatting, and output properties, with no new platform-specific command or API dependency.

### Formal release review — 2026-10-04

- Script parsing and synthetic-fixture regression passed on Windows PowerShell 5.1.26100.9444 and the Codex-bundled PowerShell 7.6.5 runtime.
- Covered changed and unchanged models/efforts, absent values, raw fields, default object pipelines, internal-thread filtering, formal and standalone project fields, column aliases, foreground colors, progress reaching 100%, and completion events.
- A fixture exceeding 32 MiB exercised the compiled pre-scanner and the pure-PowerShell fallback when Add-Type was unavailable. Session and global-state processing also worked without sqlite3 installed. All synthetic input file hashes remained unchanged.
- Both engines verified exit codes 0 for success, 1 for a missing data path, and 2 for invalid display parameters; executable code blocks in both languages passed syntax checks.
- Usage Guide multiline/single-line examples were compared on synthetic data; Windows Explorer and macOS Finder opening commands received syntax checks only.
- Static review covered all cumulative changes: paths and $HOME, optional sqlite3 discovery and -readonly queries, portable .NET/Add-Type APIs, UTF-8, CRLF, Write-Host/Write-Progress, and object pipelines. No new Windows-only script dependency was found.
- Statically reviewed for macOS PowerShell 7 compatibility; native macOS runtime remains unverified. Historical macOS runtime evidence belongs to v1.0 only.

## [v1.5] - 2026-10-04

**Status:** Local development; retained script: `Get-CodexSessions-v1.5.ps1` (retained locally only; excluded from the public repository and Releases)

### Added

- Added the optional display-only `-ColorOutput` terminal table.
- Standalone-session rows use a configurable foreground color without changing the default object output.
- Added `-Property` (aliases: `-Properties`, `-Columns`) to select and order colored-table columns.
- Added `-StandaloneColor`, defaulting to `Yellow`.
- Added an explicit version header and versioned script filenames.
- Added independent English and Simplified Chinese changelogs.

### Compatibility

- Default invocation still returns the same structured objects for `Format-Table`, filtering, sorting, and export pipelines.
- The colored view is terminal-only and intentionally emits no session objects.

### Validation

- Parsed and executed successfully with Windows PowerShell 5.1 and the Codex-bundled PowerShell 7.6.5 runtime.
- On the test machine, both engines returned 53 normal sessions, including 21 standalone sessions, with zero reported parse errors.
- PowerShell 7 default-object output matched v1.4 exactly in JSON comparison.
- The colored view, property aliases, custom foreground color, display-only output behavior, and invalid-property error path were exercised.
- The v1.5 changes were not re-tested on macOS.

## [v1.4] - 2026-10-04

**Status:** Local development; retained script: `Get-CodexSessions-v1.4.ps1` (retained locally only; excluded from the public repository and Releases)

### Changed

- Sessions without a formal Project ID are identified as standalone sessions.
- Standalone sessions now use `<Standalone Session>` for `Project`, `<N/A>` for `ProjectId`, and their complete recorded `CWD` for `ProjectPath`.
- Added `standalone` as the corresponding `ProjectSource` value.
- Formal project assignments remain unchanged.

## [v1.3] - 2026-10-03

**Status:** Historical local iteration; no separate script snapshot was retained before the version-file policy began.

### Performance

- Added an in-memory compiled pre-scanner for larger session stores so unrelated JSONL records are skipped before PowerShell deserialization.
- Preserved a pure-PowerShell fallback for small stores, constrained environments, or per-file scanner failures.
- Reduced the measured full scan of the test machine's approximately 3.5 GB session store from about 167 seconds to about 7 seconds on PowerShell 7.
- Kept parsing read-only and preserved the structured output.

## [v1.2] - 2026-10-03

**Status:** Historical local iteration; no separate script snapshot was retained before the version-file policy began.

### Added

- Added formal Project assignment lookup from `state_5.sqlite` and `.codex-global-state.json` when available.
- Added `ProjectId`, `ProjectPath`, and `ProjectSource` output fields.
- Changed `Project` to prefer the saved Codex project name while retaining a working-directory fallback at that stage.
- Kept SQLite access explicitly read-only and preserved fallback behavior when optional metadata is unavailable.

## [v1.1] - 2026-09-24

**Status:** [Published GitHub Release](https://github.com/zjwww/Get-CodexSessions/releases/tag/v1.1); Latest at the time this changelog was created.

### Added

- Added overall rollout-file scanning progress through the standard PowerShell `Write-Progress` command.
- Added `-NoProgress` for automation and other non-interactive scenarios.
- Preserved each PowerShell host's native progress presentation, including Classic on Windows PowerShell 5.1 and the configured/default view on PowerShell 7.

### Validation

- Validated on Windows PowerShell 5.1 and the Codex-bundled PowerShell 7.6.5 runtime.
- This release was not re-tested on macOS; the macOS Tahoe 26.2 and PowerShell 7.x runtime evidence belongs to v1.0 only and does not verify v1.1.

## [v1.0] - 2026-09-14

**Status:** [Published GitHub Release](https://github.com/zjwww/Get-CodexSessions/releases/tag/v1.0)

### Initial release

- Added read-only inspection of local Codex sessions.
- Reported titles, creation and last-active times, Session IDs, working directories, Project display values, and rollout JSONL paths.
- Reported the first and most recently observed model and reasoning effort.
- Filtered Codex internal helper threads by default and added `-IncludeInternal` for internal-thread analysis.
- Read `session_index.jsonl` and rollout JSONL data, with optional read-only SQLite title supplementation.
- Supported Windows PowerShell 5.1 and PowerShell 7.x on Windows and macOS.
- Documented successful testing on macOS Tahoe 26.2 with PowerShell 7.x.
- Adopted the GNU General Public License v3.0 only (`GPL-3.0-only`).
