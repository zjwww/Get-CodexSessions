# Repository Instructions

These instructions apply to the entire Get-CodexSessions repository.

## Script version updates

- Never overwrite an existing versioned script. Create a new `Get-CodexSessions-vX.Y.ps1` file and retain the previous versioned file.
- Update the version header inside the new script, both changelogs, current README and usage-guide commands, and `SHA256SUMS.txt`.
- Preserve the default structured-object output unless a requested change explicitly requires otherwise.

## Required compatibility checks

For every script version update, complete all applicable checks before reporting the version as finished:

1. Parse the script with Windows PowerShell 5.1 and PowerShell 7.x.
2. Run the relevant Windows regression checks with both supported engines when available.
3. Perform a static compatibility review for macOS with PowerShell 7.x, even when no Mac is available.
4. Review all newly added or changed code for:
   - Windows-only commands, executables, registry access, Win32 APIs, and path assumptions.
   - Cross-platform use of `$HOME`, `Join-Path`, directory separators, and executable discovery.
   - External command availability and a safe fallback when an optional dependency such as `sqlite3` is missing.
   - Cross-platform .NET and `Add-Type` APIs.
   - Console behavior, including `Write-Progress`, `Write-Host`, colors, redirection, and object-pipeline behavior.
   - UTF-8 handling, line endings, and PowerShell syntax supported by the declared runtime versions.
5. Record the macOS static-review result in both `CHANGELOG.md` and `CHANGELOG.zh-CN.md` for that version.

## macOS verification boundary

- A static compatibility review is not a native macOS runtime test.
- Never describe a version as "tested on macOS" unless that exact version was actually executed on a Mac.
- When native testing was not performed, state: "Statically reviewed for macOS PowerShell 7 compatibility; native macOS runtime remains unverified," or the equivalent Simplified Chinese wording.
- When native testing is performed, record the macOS version, PowerShell version, commands or scenarios exercised, and results in both changelogs.
- Keep earlier macOS test evidence attributed to the version that was actually tested; do not automatically carry it forward as proof for a newer version.

## GitHub operation routing

- All GitHub write operations for this project must be performed in the chat titled **Get-CodexSessions 脚本 GitHub 发布与更新**. This includes release commits, pushes, tags, Releases, release assets, and remote Issue/PR writes.
- Other chats may analyze the repository and perform local development, but must not perform these GitHub write operations unless the user explicitly designates a different chat.
- Ordinary read-only checks of GitHub state are permitted in other chats. A read-only check is not authorization to publish or change remote state.
- Routing does not grant publication authorization. Obtain the user's authorization for the intended write scope; existing explicit authorization remains valid within that scope.
