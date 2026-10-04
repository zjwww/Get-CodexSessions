# Get-CodexSessions
# Script version: v1.6
# Version date: 2026-10-04
# File: Get-CodexSessions-v1.6.ps1

param(
    [switch]$IncludeInternal,

    # Optional:
    # Override the default Codex home directory.
    #
    # Windows default:
    #   C:\Users\<User>\.codex
    #
    # macOS default:
    #   /Users/<User>/.codex
    #
    # Example:
    #   .\Get-CodexSessions-v1.6.ps1 -CodexHome "D:\MyCodex"
    #
    #   ./Get-CodexSessions-v1.6.ps1 -CodexHome "/Users/me/.codex"
    #
    [string]$CodexHome,

    # Optional:
    # Suppress host-native progress display.
    #
    [switch]$NoProgress,

    # Optional display-only mode:
    # Render a terminal table and highlight standalone sessions.
    # This mode writes host text instead of pipeline objects.
    #
    [switch]$ColorOutput,

    # Columns and order used by -ColorOutput.
    # Alias: -Properties, -Columns
    #
    [Alias(
        "Properties",
        "Columns"
    )]
    [string[]]$Property = @(
        "DisplayTitle",
        "LastActive",
        "Created",
        "FirstModel",
        "FirstEffort",
        "LastModel",
        "LastEffort",
        "Project",
        "ProjectId",
        "ProjectPath"
    ),

    # Foreground color for standalone rows in -ColorOutput mode.
    #
    [System.ConsoleColor]$StandaloneColor =
        [System.ConsoleColor]::Yellow
)

# ======================================================================
# Get-CodexSessions-v1.6.ps1
# SPDX-License-Identifier: GPL-3.0-only
#
# Cross-platform read-only Codex session inspector.
#
# Supported:
#   - Windows PowerShell 5.1
#   - PowerShell 7.x on Windows
#   - PowerShell 7.x on macOS
#   - PowerShell 7.x on Linux (best effort)
#
# Reads:
#   <CodexHome>/session_index.jsonl
#   <CodexHome>/.codex-global-state.json
#   <CodexHome>/state_5.sqlite
#   <CodexHome>/sessions/.../rollout-*.jsonl
#
# This script DOES NOT modify:
#   - Codex sessions
#   - session_index.jsonl
#   - .codex-global-state.json
#   - state_5.sqlite
#   - rollout JSONL files
#   - Codex configuration
#
# Default behavior:
#   - hides codex-auto-review sessions
#   - hides guardian/subagent sessions
#   - hides child/internal sessions
#   - shows host-native progress while scanning rollout files
#   - sorts sessions by LastActive, newest first
#
# Use -IncludeInternal to include Codex internal sessions.
# Use -NoProgress to suppress the progress display.
# Use -ColorOutput for a display-only table with standalone rows colored.
# Use -Property to select and order columns in -ColorOutput mode.
# ======================================================================


# ----------------------------------------------------------------------
# Validate display-only parameters before scanning any rollout files.
# ----------------------------------------------------------------------

$SupportedOutputProperties = @(
    "Title",
    "DisplayTitle",
    "TitleSource",
    "Created",
    "LastActive",
    "SessionId",
    "FirstModel",
    "FirstEffort",
    "LastModel",
    "LastEffort",
    "LastModelRaw",
    "LastEffortRaw",
    "Project",
    "ProjectId",
    "ProjectPath",
    "ProjectSource",
    "CWD",
    "Source",
    "ParentThreadId",
    "IsInternal",
    "InternalReason",
    "FirstPrompt",
    "ParseErrors",
    "JsonlPath"
)


if (-not $ColorOutput) {

    if (
        $PSBoundParameters.ContainsKey(
            "Property"
        ) -or
        $PSBoundParameters.ContainsKey(
            "StandaloneColor"
        )
    ) {

        Write-Error (
            "-Property and -StandaloneColor require -ColorOutput. " +
            "Without -ColorOutput, select columns with Format-Table."
        )

        exit 2
    }
}
else {

    if (
        $null -eq $Property -or
        $Property.Count -eq 0
    ) {

        Write-Error (
            "-Property must contain at least one output property."
        )

        exit 2
    }


    $resolvedProperties =
        New-Object `
            System.Collections.Generic.List[string]

    $seenProperties = @{}


    foreach ($propertyName in $Property) {

        $canonicalProperty =
            $SupportedOutputProperties |
            Where-Object {
                $_ -ieq $propertyName
            } |
            Select-Object -First 1


        if (
            [string]::IsNullOrWhiteSpace(
                [string]$canonicalProperty
            )
        ) {

            Write-Error (
                "Unknown output property: {0}. Available properties: {1}" -f
                $propertyName,
                ($SupportedOutputProperties -join ", ")
            )

            exit 2
        }


        $propertyKey =
            $canonicalProperty.ToLowerInvariant()


        if ($seenProperties.ContainsKey($propertyKey)) {

            Write-Error (
                "Duplicate output property: {0}" -f
                $canonicalProperty
            )

            exit 2
        }


        $seenProperties[$propertyKey] = $true

        $resolvedProperties.Add(
            $canonicalProperty
        )
    }


    $Property =
        $resolvedProperties.ToArray()
}


# ----------------------------------------------------------------------
# Resolve Codex home directory
#
# $HOME is cross-platform:
#
# Windows:
#   C:\Users\<User>
#
# macOS:
#   /Users/<User>
#
# Linux:
#   /home/<User>
# ----------------------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($CodexHome)) {

    if ([string]::IsNullOrWhiteSpace([string]$HOME)) {
        Write-Error "Cannot determine the user home directory."
        exit 1
    }

    $CodexHome = Join-Path $HOME ".codex"
}


# Normalize user-supplied path.
#
# This also allows:
#   ~
#   relative paths
#   Windows paths
#   Unix/macOS paths

try {
    $CodexHome =
        $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
            $CodexHome
        )
}
catch {
    Write-Error ("Invalid Codex home path: {0}" -f $CodexHome)
    exit 1
}


$SessionsPath = Join-Path $CodexHome "sessions"
$IndexPath    = Join-Path $CodexHome "session_index.jsonl"
$GlobalStatePath = Join-Path $CodexHome ".codex-global-state.json"
$StateDbPath  = Join-Path $CodexHome "state_5.sqlite"


if (-not (Test-Path -LiteralPath $SessionsPath -PathType Container)) {

    Write-Error (
        "Codex sessions directory not found: {0}" -f $SessionsPath
    )

    exit 1
}


# ======================================================================
# Helper functions
# ======================================================================


function Convert-ToLocalDateTime {

    param(
        [string]$Timestamp
    )

    if ([string]::IsNullOrWhiteSpace($Timestamp)) {
        return $null
    }

    try {
        return ([DateTimeOffset]::Parse($Timestamp)).LocalDateTime
    }
    catch {
        return $null
    }
}


function Get-PropertyValue {

    param(
        $Object,
        [string]$PropertyName
    )

    if ($null -eq $Object) {
        return $null
    }

    $property = $Object.PSObject.Properties[$PropertyName]

    if ($null -ne $property) {
        return $property.Value
    }

    return $null
}


function Find-PropertyRecursive {

    param(
        $Object,
        [string]$PropertyName,
        [int]$Depth = 0
    )

    if ($null -eq $Object -or $Depth -gt 8) {
        return $null
    }

    if ($Object -is [string]) {
        return $null
    }

    $direct = $Object.PSObject.Properties[$PropertyName]

    if ($null -ne $direct) {
        return $direct.Value
    }

    foreach ($property in $Object.PSObject.Properties) {

        $value = $property.Value

        if ($null -eq $value) {
            continue
        }

        if ($value -is [string]) {
            continue
        }

        if ($value -is [System.Collections.IEnumerable]) {

            foreach ($item in $value) {

                if ($item -is [string]) {
                    continue
                }

                $found = Find-PropertyRecursive `
                    -Object $item `
                    -PropertyName $PropertyName `
                    -Depth ($Depth + 1)

                if ($null -ne $found) {
                    return $found
                }
            }

            continue
        }

        $found = Find-PropertyRecursive `
            -Object $value `
            -PropertyName $PropertyName `
            -Depth ($Depth + 1)

        if ($null -ne $found) {
            return $found
        }
    }

    return $null
}


function Convert-SourceToString {

    param(
        $Source
    )

    if ($null -eq $Source) {
        return $null
    }

    if ($Source -is [string]) {
        return $Source
    }

    try {
        return (
            $Source |
            ConvertTo-Json -Compress -Depth 8
        )
    }
    catch {
        return [string]$Source
    }
}


function Get-DisplayText {

    param(
        [string]$Text,
        [int]$MaxLength = 52
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return "(Untitled)"
    }

    $singleLine = ($Text -replace '\s+', ' ').Trim()

    if ($singleLine.Length -le $MaxLength) {
        return $singleLine
    }

    return (
        $singleLine.Substring(
            0,
            $MaxLength - 3
        ) + "..."
    )
}


function Convert-ToTableText {

    param(
        $Value
    )

    if ($null -eq $Value) {
        return ""
    }


    if ($Value -is [System.DateTime]) {

        return $Value.ToString(
            "G",
            [System.Globalization.CultureInfo]::CurrentCulture
        )
    }


    if ($Value -is [System.DateTimeOffset]) {

        return $Value.ToString(
            "G",
            [System.Globalization.CultureInfo]::CurrentCulture
        )
    }


    $text = [string]$Value


    if ([string]::IsNullOrEmpty($text)) {
        return ""
    }


    return (
        ($text -replace '\s+', ' ').Trim()
    )
}


function Get-ConsoleTextWidth {

    param(
        [string]$Text
    )

    if ([string]::IsNullOrEmpty($Text)) {
        return 0
    }


    $width = 0


    for ($index = 0; $index -lt $Text.Length; $index++) {

        $character = $Text[$index]


        if (
            [char]::IsHighSurrogate($character) -and
            $index + 1 -lt $Text.Length -and
            [char]::IsLowSurrogate($Text[$index + 1])
        ) {

            $width += 2
            $index++
            continue
        }


        $category =
            [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory(
                [string]$character,
                0
            )


        if (
            $category -eq
                [System.Globalization.UnicodeCategory]::NonSpacingMark -or
            $category -eq
                [System.Globalization.UnicodeCategory]::EnclosingMark -or
            $category -eq
                [System.Globalization.UnicodeCategory]::Format
        ) {

            continue
        }


        $codePoint = [int]$character

        $isWide =
            ($codePoint -ge 0x1100 -and $codePoint -le 0x115F) -or
            $codePoint -eq 0x2329 -or
            $codePoint -eq 0x232A -or
            ($codePoint -ge 0x2E80 -and $codePoint -le 0xA4CF) -or
            ($codePoint -ge 0xAC00 -and $codePoint -le 0xD7A3) -or
            ($codePoint -ge 0xF900 -and $codePoint -le 0xFAFF) -or
            ($codePoint -ge 0xFE10 -and $codePoint -le 0xFE19) -or
            ($codePoint -ge 0xFE30 -and $codePoint -le 0xFE6F) -or
            ($codePoint -ge 0xFF00 -and $codePoint -le 0xFF60) -or
            ($codePoint -ge 0xFFE0 -and $codePoint -le 0xFFE6)


        if ($isWide) {
            $width += 2
        }
        else {
            $width++
        }
    }


    return $width
}


function Limit-ConsoleText {

    param(
        [string]$Text,
        [int]$Width
    )

    if ($Width -le 0) {
        return ""
    }


    if (
        (Get-ConsoleTextWidth $Text) -le
        $Width
    ) {

        return $Text
    }


    if ($Width -le 3) {
        return ("." * $Width)
    }


    $contentWidth = $Width - 3
    $currentWidth = 0
    $builder =
        New-Object `
            System.Text.StringBuilder


    for ($index = 0; $index -lt $Text.Length; $index++) {

        $segment = [string]$Text[$index]


        if (
            [char]::IsHighSurrogate($Text[$index]) -and
            $index + 1 -lt $Text.Length -and
            [char]::IsLowSurrogate($Text[$index + 1])
        ) {

            $segment += [string]$Text[$index + 1]
            $index++
        }


        $segmentWidth =
            Get-ConsoleTextWidth `
                $segment


        if (
            $currentWidth + $segmentWidth -gt
            $contentWidth
        ) {

            break
        }


        $null = $builder.Append($segment)
        $currentWidth += $segmentWidth
    }


    return ($builder.ToString() + "...")
}


function Format-ConsoleTableCell {

    param(
        [string]$Text,
        [int]$Width
    )

    $limitedText =
        Limit-ConsoleText `
            -Text $Text `
            -Width $Width

    $padding =
        $Width -
        (Get-ConsoleTextWidth $limitedText)


    if ($padding -lt 0) {
        $padding = 0
    }


    return (
        $limitedText +
        (" " * $padding)
    )
}


function Get-ColorTableColumnCap {

    param(
        [string]$PropertyName
    )

    switch ($PropertyName) {

        "Title"          { return 52 }
        "DisplayTitle"   { return 52 }
        "Created"        { return 22 }
        "LastActive"     { return 22 }
        "SessionId"      { return 36 }
        "FirstModel"     { return 22 }
        "FirstEffort"    { return 16 }
        "LastModel"      { return 22 }
        "LastEffort"     { return 16 }
        "LastModelRaw"   { return 22 }
        "LastEffortRaw"  { return 16 }
        "Project"        { return 32 }
        "ProjectId"      { return 36 }
        "ProjectPath"    { return 60 }
        "ProjectSource"  { return 18 }
        "CWD"            { return 60 }
        "Source"         { return 28 }
        "ParentThreadId" { return 36 }
        "InternalReason" { return 32 }
        "FirstPrompt"    { return 60 }
        "JsonlPath"      { return 60 }

        default           { return 28 }
    }
}


function Write-ColorSessionTable {

    param(
        [object[]]$InputObject,
        [string[]]$Properties,
        [System.ConsoleColor]$HighlightColor
    )

    if (
        $null -eq $InputObject -or
        $InputObject.Count -eq 0
    ) {

        Write-Host "No Codex sessions found."
        return
    }


    $columnWidths = @{}


    foreach ($propertyName in $Properties) {

        $maximumWidth =
            Get-ConsoleTextWidth `
                $propertyName


        foreach ($item in $InputObject) {

            $text =
                Convert-ToTableText `
                    $item.PSObject.Properties[
                        $propertyName
                    ].Value

            $textWidth =
                Get-ConsoleTextWidth `
                    $text


            if ($textWidth -gt $maximumWidth) {
                $maximumWidth = $textWidth
            }
        }


        $columnCap =
            Get-ColorTableColumnCap `
                $propertyName

        $columnWidths[$propertyName] =
            [Math]::Max(
                (Get-ConsoleTextWidth $propertyName),
                [Math]::Min(
                    $maximumWidth,
                    $columnCap
                )
            )
    }


    $headerParts = @(

        foreach ($propertyName in $Properties) {

            Format-ConsoleTableCell `
                -Text $propertyName `
                -Width $columnWidths[$propertyName]
        }
    )


    $separatorParts = @(

        foreach ($propertyName in $Properties) {

            "-" * $columnWidths[$propertyName]
        }
    )


    Write-Host ($headerParts -join "  ")
    Write-Host ($separatorParts -join "  ")


    foreach ($item in $InputObject) {

        $rowParts = @(

            foreach ($propertyName in $Properties) {

                $text =
                    Convert-ToTableText `
                        $item.PSObject.Properties[
                            $propertyName
                        ].Value

                Format-ConsoleTableCell `
                    -Text $text `
                    -Width $columnWidths[$propertyName]
            }
        )


        $rowText =
            $rowParts -join "  "


        if ($item.ProjectSource -eq "standalone") {

            Write-Host `
                $rowText `
                -ForegroundColor $HighlightColor
        }
        else {

            Write-Host $rowText
        }
    }
}


function Read-JsonFileShared {

    param(
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $stream = $null
    $reader = $null

    try {

        $stream = [System.IO.File]::Open(
            $Path,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite
        )

        $reader = [System.IO.StreamReader]::new(
            $stream,
            [System.Text.Encoding]::UTF8,
            $true
        )

        $json = $reader.ReadToEnd()

        if ([string]::IsNullOrWhiteSpace($json)) {
            return $null
        }

        return ($json | ConvertFrom-Json)
    }
    catch {
        return $null
    }
    finally {

        if ($null -ne $reader) {
            $reader.Dispose()
        }
        elseif ($null -ne $stream) {
            $stream.Dispose()
        }
    }
}


# ======================================================================
# Read session_index.jsonl
#
# session_index.jsonl is append-style.
#
# If the same Session ID appears more than once, the later thread_name
# replaces the earlier one.
# ======================================================================


$IndexTitles = @{}


if (Test-Path -LiteralPath $IndexPath -PathType Leaf) {

    $stream = $null
    $reader = $null

    try {

        $stream = [System.IO.File]::Open(
            $IndexPath,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite
        )

        $reader = [System.IO.StreamReader]::new(
            $stream,
            [System.Text.Encoding]::UTF8,
            $true
        )


        while (($line = $reader.ReadLine()) -ne $null) {

            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            try {
                $entry = $line | ConvertFrom-Json
            }
            catch {
                continue
            }


            $id =
                Get-PropertyValue `
                    $entry `
                    "id"

            $threadName =
                Get-PropertyValue `
                    $entry `
                    "thread_name"


            if (
                -not [string]::IsNullOrWhiteSpace([string]$id) -and
                -not [string]::IsNullOrWhiteSpace([string]$threadName)
            ) {

                $IndexTitles[[string]$id] =
                    [string]$threadName
            }
        }
    }
    catch {

        Write-Warning (
            "Cannot read session index: {0}" -f $IndexPath
        )
    }
    finally {

        if ($null -ne $reader) {

            $reader.Dispose()
        }
        elseif ($null -ne $stream) {

            $stream.Dispose()
        }
    }
}


# ======================================================================
# Optional project lookup from .codex-global-state.json
#
# Codex Desktop may store the active thread-to-project assignment here
# even when threads.project_id in state_5.sqlite is empty during a schema
# migration. Project definitions contain the user-visible name and one or
# more root paths.
#
# This source is read only. If it is unavailable or has a different
# schema, SQLite and CWD fallback processing continue normally.
# ======================================================================


$GlobalProjects       = @{}
$GlobalThreadProjects = @{}

$GlobalState =
    Read-JsonFileShared `
        -Path $GlobalStatePath


if ($null -ne $GlobalState) {

    $localProjects =
        Get-PropertyValue `
            $GlobalState `
            "local-projects"


    if ($null -ne $localProjects) {

        foreach ($projectProperty in $localProjects.PSObject.Properties) {

            $projectId = [string]$projectProperty.Name
            $project   = $projectProperty.Value


            if (
                [string]::IsNullOrWhiteSpace($projectId) -or
                $null -eq $project
            ) {

                continue
            }


            $projectName =
                Get-PropertyValue `
                    $project `
                    "name"

            $rootPaths =
                Get-PropertyValue `
                    $project `
                    "rootPaths"

            $projectPath = $null


            foreach ($rootPath in @($rootPaths)) {

                if (
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$rootPath
                    )
                ) {

                    $projectPath = [string]$rootPath
                    break
                }
            }


            $GlobalProjects[$projectId] =
                [PSCustomObject]@{
                    ProjectId   = $projectId
                    ProjectName = [string]$projectName
                    ProjectPath = $projectPath
                }
        }
    }


    $threadAssignments =
        Get-PropertyValue `
            $GlobalState `
            "thread-project-assignments"


    if ($null -ne $threadAssignments) {

        foreach ($assignmentProperty in $threadAssignments.PSObject.Properties) {

            $threadId  = [string]$assignmentProperty.Name
            $assignment = $assignmentProperty.Value


            if ([string]::IsNullOrWhiteSpace($threadId)) {
                continue
            }


            if ($assignment -is [string]) {

                $projectId = [string]$assignment
            }
            else {

                $projectId =
                    Get-PropertyValue `
                        $assignment `
                        "projectId"
            }


            if (
                -not [string]::IsNullOrWhiteSpace(
                    [string]$projectId
                )
            ) {

                $GlobalThreadProjects[$threadId] =
                    [string]$projectId
            }
        }
    }
}


# ======================================================================
# Optional read-only lookup from state_5.sqlite
#
# Cross-platform sqlite lookup:
#
# Windows:
#   sqlite3.exe
#
# macOS / Linux:
#   sqlite3
#
# PowerShell normally resolves sqlite3.exe automatically when using
# "sqlite3" on Windows, so "sqlite3" is checked first.
#
# This is optional. If sqlite3 is unavailable, rollout/session_index
# processing continues normally.
#
# SQLite is explicitly opened with -readonly.
# ======================================================================


$StateTitles   = @{}
$StateProjects = @{}


if (Test-Path -LiteralPath $StateDbPath -PathType Leaf) {

    $sqliteCommand =
        Get-Command `
            "sqlite3" `
            -CommandType Application `
            -ErrorAction SilentlyContinue


    if ($null -eq $sqliteCommand) {

        $sqliteCommand =
            Get-Command `
                "sqlite3.exe" `
                -CommandType Application `
                -ErrorAction SilentlyContinue
    }


    if ($null -ne $sqliteCommand) {

        $sql = @"
SELECT
    id,
    replace(
        replace(
            replace(
                COALESCE(title, ''),
                char(9),
                ' '
            ),
            char(10),
            ' '
        ),
        char(13),
        ' '
    )
FROM threads
WHERE title IS NOT NULL
  AND title <> '';
"@


        try {

            $sqlitePath = $sqliteCommand.Path

            if (
                [string]::IsNullOrWhiteSpace(
                    [string]$sqlitePath
                )
            ) {

                $sqlitePath = $sqliteCommand.Source
            }


            $rows = & $sqlitePath `
                -readonly `
                -separator "`t" `
                $StateDbPath `
                $sql `
                2>$null


            foreach ($row in $rows) {

                if ([string]::IsNullOrWhiteSpace($row)) {
                    continue
                }


                $parts = $row -split "`t", 2


                if ($parts.Count -ne 2) {
                    continue
                }


                $id    = $parts[0]
                $title = $parts[1]


                if (
                    -not [string]::IsNullOrWhiteSpace($id) -and
                    -not [string]::IsNullOrWhiteSpace($title)
                ) {

                    $StateTitles[$id] = $title
                }
            }


            $projectSql = @"
SELECT
    t.id,
    t.project_id,
    replace(
        replace(
            replace(
                COALESCE(p.name, ''),
                char(9),
                ' '
            ),
            char(10),
            ' '
        ),
        char(13),
        ' '
    ),
    replace(
        replace(
            replace(
                COALESCE(
                    (
                        SELECT path
                        FROM project_roots
                        WHERE project_id = p.id
                        ORDER BY position
                        LIMIT 1
                    ),
                    ''
                ),
                char(9),
                ' '
            ),
            char(10),
            ' '
        ),
        char(13),
        ' '
    ),
    COALESCE(
        (
            SELECT key
            FROM project_idempotency_keys
            WHERE project_id = p.id
            ORDER BY created_at_ms
            LIMIT 1
        ),
        ''
    )
FROM threads AS t
LEFT JOIN projects AS p
    ON p.id = t.project_id
WHERE t.project_id IS NOT NULL
  AND t.project_id <> ''
  AND p.id IS NOT NULL;
"@


            $projectRows = & $sqlitePath `
                -readonly `
                -separator "`t" `
                $StateDbPath `
                $projectSql `
                2>$null


            foreach ($row in $projectRows) {

                if ([string]::IsNullOrWhiteSpace($row)) {
                    continue
                }


                $parts = $row -split "`t", 5


                if ($parts.Count -ne 5) {
                    continue
                }


                $threadId     = $parts[0]
                $coreProjectId = $parts[1]
                $projectName  = $parts[2]
                $projectPath  = $parts[3]
                $legacyProjectId = $parts[4]


                if (
                    [string]::IsNullOrWhiteSpace($threadId) -or
                    [string]::IsNullOrWhiteSpace($coreProjectId)
                ) {

                    continue
                }


                if (
                    [string]::IsNullOrWhiteSpace(
                        [string]$legacyProjectId
                    )
                ) {

                    $projectId = $coreProjectId
                }
                else {

                    $projectId = $legacyProjectId
                }


                $StateProjects[$threadId] =
                    [PSCustomObject]@{
                        ProjectId   = $projectId
                        ProjectName = $projectName
                        ProjectPath = $projectPath
                    }
            }
        }
        catch {

            # Optional source only.
            #
            # Failure here does not affect:
            #   - session_index.jsonl
            #   - rollout scanning
            #
            # No warning is emitted because some Codex versions or
            # sqlite environments may not expose this database/schema.
        }
    }
}


# ======================================================================
# Scan rollout JSONL files
# ======================================================================


$RolloutFiles = @(
    Get-ChildItem `
        -LiteralPath $SessionsPath `
        -Recurse `
        -File `
        -Filter "rollout-*.jsonl"
)


$TotalRolloutBytes =
    ($RolloutFiles | Measure-Object -Property Length -Sum).Sum

if ($null -eq $TotalRolloutBytes) {
    $TotalRolloutBytes = 0
}


# ======================================================================
# Optional compiled rollout pre-scanner
#
# Crossing the PowerShell runtime once per JSONL record is expensive for
# multi-gigabyte session stores, especially in PowerShell 7. For larger
# stores, compile a small in-memory scanner that returns only the records
# needed by this report:
#
#   - session_meta
#   - turn_context
#   - event_msg / user_message
#   - unknown records that require the compatibility parser
#
# No file is modified. If Add-Type is unavailable (for example, under a
# constrained language policy), the normal PowerShell reader is used.
# Small stores skip compilation because its startup cost is not useful.
# ======================================================================


$FastScannerAvailable = $false


if ($TotalRolloutBytes -ge 32MB) {

    if (
        $null -eq (
            "CodexSessionRolloutScannerV1" -as [type]
        )
    ) {

        try {

            $null = Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

public sealed class CodexSessionRolloutScanResultV1
{
    public readonly List<string> RelevantLines;
    public readonly List<string> NonSortableTimestamps;
    public string SortableLastTimestamp;
    public int ParseErrors;

    public CodexSessionRolloutScanResultV1()
    {
        RelevantLines = new List<string>();
        NonSortableTimestamps = new List<string>();
    }
}

public static class CodexSessionRolloutScannerV1
{
    private const int PrefixLimit = 1024;

    private static readonly Regex TimestampRegex = new Regex(
        "\"timestamp\"\\s*:\\s*\"([^\"]+)\"",
        RegexOptions.Compiled | RegexOptions.CultureInvariant
    );

    private static readonly Regex TypeRegex = new Regex(
        "\"type\"\\s*:\\s*\"([^\"]+)\"",
        RegexOptions.Compiled | RegexOptions.CultureInvariant
    );

    private static readonly Regex UserMessageRegex = new Regex(
        "\"type\"\\s*:\\s*\"user_message\"",
        RegexOptions.Compiled | RegexOptions.CultureInvariant
    );

    private static string ExtractCompactString(
        string text,
        string marker,
        int searchLength
    )
    {
        int boundedLength = Math.Min(text.Length, searchLength);
        int start = text.IndexOf(
            marker,
            0,
            boundedLength,
            StringComparison.Ordinal
        );

        if (start < 0)
        {
            return null;
        }

        start += marker.Length;
        int end = text.IndexOf('"', start);

        if (end <= start)
        {
            return null;
        }

        return text.Substring(start, end - start);
    }

    private static bool IsSortableUtcTimestamp(string value)
    {
        return
            value != null &&
            value.Length == 24 &&
            value[4] == '-' &&
            value[7] == '-' &&
            value[10] == 'T' &&
            value[13] == ':' &&
            value[16] == ':' &&
            value[19] == '.' &&
            value[23] == 'Z';
    }

    public static CodexSessionRolloutScanResultV1 Scan(string path)
    {
        CodexSessionRolloutScanResultV1 result =
            new CodexSessionRolloutScanResultV1();

        using (
            FileStream stream = new FileStream(
                path,
                FileMode.Open,
                FileAccess.Read,
                FileShare.ReadWrite
            )
        )
        using (
            StreamReader reader = new StreamReader(
                stream,
                Encoding.UTF8,
                true
            )
        )
        {
            string line;

            while ((line = reader.ReadLine()) != null)
            {
                if (String.IsNullOrWhiteSpace(line))
                {
                    continue;
                }

                int prefixLength = Math.Min(line.Length, PrefixLimit);
                string prefix = line.Substring(0, prefixLength);

                string timestamp = ExtractCompactString(
                    prefix,
                    "\"timestamp\":\"",
                    prefixLength
                );

                if (timestamp == null)
                {
                    Match timestampMatch = TimestampRegex.Match(prefix);

                    if (timestampMatch.Success)
                    {
                        timestamp = timestampMatch.Groups[1].Value;
                    }
                }

                if (IsSortableUtcTimestamp(timestamp))
                {
                    if (
                        result.SortableLastTimestamp == null ||
                        String.CompareOrdinal(
                            timestamp,
                            result.SortableLastTimestamp
                        ) > 0
                    )
                    {
                        result.SortableLastTimestamp = timestamp;
                    }
                }
                else if (!String.IsNullOrWhiteSpace(timestamp))
                {
                    result.NonSortableTimestamps.Add(timestamp);
                }

                bool compactType = true;
                string type = ExtractCompactString(
                    prefix,
                    "\"type\":\"",
                    prefixLength
                );

                if (type == null)
                {
                    compactType = false;
                    Match typeMatch = TypeRegex.Match(prefix);

                    if (typeMatch.Success)
                    {
                        type = typeMatch.Groups[1].Value;
                    }
                }

                bool isUserMessage = false;

                if (String.Equals(type, "event_msg", StringComparison.Ordinal))
                {
                    if (compactType)
                    {
                        isUserMessage = prefix.IndexOf(
                            "\"type\":\"user_message\"",
                            StringComparison.Ordinal
                        ) >= 0;
                    }
                    else
                    {
                        isUserMessage = UserMessageRegex.IsMatch(prefix);
                    }
                }

                if (
                    type == null ||
                    String.Equals(type, "session_meta", StringComparison.Ordinal) ||
                    String.Equals(type, "turn_context", StringComparison.Ordinal) ||
                    isUserMessage
                )
                {
                    result.RelevantLines.Add(line);
                    continue;
                }

                if (
                    line.Length < 2 ||
                    line[0] != '{' ||
                    line[line.Length - 1] != '}'
                )
                {
                    result.ParseErrors++;
                }
            }
        }

        return result;
    }
}
'@ -Language CSharp -ErrorAction Stop
        }
        catch {

            # Optional optimization only.
            # The standard PowerShell reader remains fully functional.
        }
    }


    if (
        $null -ne (
            "CodexSessionRolloutScannerV1" -as [type]
        )
    ) {

        $FastScannerAvailable = $true
    }
}


$TotalRolloutFiles  = $RolloutFiles.Count
$CurrentRolloutFile = 0
$ProgressActivity   = "Scanning Codex sessions"


$Results = foreach ($rolloutFile in $RolloutFiles) {

    $CurrentRolloutFile++


    if (
        -not $NoProgress -and
        $TotalRolloutFiles -gt 0
    ) {

        $PercentComplete =
            [int][Math]::Floor(
                (
                    $CurrentRolloutFile /
                    [double]$TotalRolloutFiles
                ) * 100
            )


        Write-Progress `
            -Activity $ProgressActivity `
            -Status (
                "Reading rollout file {0} of {1}" -f
                $CurrentRolloutFile,
                $TotalRolloutFiles
            ) `
            -PercentComplete $PercentComplete
    }

    $filePath = $rolloutFile.FullName


    $SessionId      = $null

    $Created        = $null
    $LastActive     = $null
    $SortableLastActiveTimestamp = $null

    $CWD            = $null

    $FirstPrompt    = $null

    $FirstModel     = $null
    $LastModel      = $null

    $FirstEffort    = $null
    $LastEffort     = $null

    $Source         = $null
    $ParentThreadId = $null

    $ParseErrors    = 0


    $stream = $null
    $reader = $null
    $fastScan = $null
    $fastLineIndex = 0


    try {

        if ($FastScannerAvailable) {

            try {

                $fastScan =
                    [CodexSessionRolloutScannerV1]::Scan(
                        $filePath
                    )
            }
            catch {

                # The compiled scanner is an optional optimization.
                # Fall back to the standard PowerShell reader for this
                # file if its read fails for any reason.

                $fastScan = $null
            }
        }


        if ($null -ne $fastScan) {

            if (
                -not [string]::IsNullOrWhiteSpace(
                    [string]$fastScan.SortableLastTimestamp
                )
            ) {

                $SortableLastActiveTimestamp =
                    [string]$fastScan.SortableLastTimestamp
            }


            foreach (
                $nonSortableTimestamp in
                $fastScan.NonSortableTimestamps
            ) {

                $parsedTime =
                    Convert-ToLocalDateTime `
                        $nonSortableTimestamp


                if (
                    $null -ne $parsedTime -and
                    (
                        $null -eq $LastActive -or
                        $parsedTime -gt $LastActive
                    )
                ) {

                    $LastActive =
                        $parsedTime
                }
            }


            $ParseErrors +=
                [int]$fastScan.ParseErrors
        }
        else {

            # Open in read-only mode while allowing Codex to continue
            # reading/writing the same rollout file.

            $stream = [System.IO.File]::Open(
                $filePath,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::ReadWrite
            )


            $reader = [System.IO.StreamReader]::new(
                $stream,
                [System.Text.Encoding]::UTF8,
                $true
            )
        }


        while ($true) {

            if ($null -ne $fastScan) {

                if (
                    $fastLineIndex -ge
                    $fastScan.RelevantLines.Count
                ) {

                    break
                }


                $line =
                    $fastScan.RelevantLines[$fastLineIndex]

                $fastLineIndex++
            }
            else {

                $line = $reader.ReadLine()


                if ($null -eq $line) {

                    break
                }
            }

            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }


            # ----------------------------------------------------------
            # Fast line pre-scan
            #
            # Rollout files can contain very large response/tool records.
            # Only session_meta, turn_context and the first user event are
            # needed for this report, so unrelated records are not fully
            # deserialized with ConvertFrom-Json.
            #
            # timestamp and top-level type appear near the beginning of
            # Codex JSONL records. The regular-expression fallback keeps
            # compatibility with JSON that contains optional whitespace.
            # ----------------------------------------------------------

            $prefixLength =
                [Math]::Min(
                    $line.Length,
                    1024
                )

            $linePrefix =
                $line.Substring(
                    0,
                    $prefixLength
                )


            $lineTimestamp = $null
            $timestampMarker = '"timestamp":"'

            $timestampStart =
                $linePrefix.IndexOf(
                    $timestampMarker,
                    [StringComparison]::Ordinal
                )


            if ($timestampStart -ge 0) {

                $timestampStart +=
                    $timestampMarker.Length

                $timestampEnd =
                    $linePrefix.IndexOf(
                        '"',
                        $timestampStart
                    )


                if ($timestampEnd -gt $timestampStart) {

                    $lineTimestamp =
                        $linePrefix.Substring(
                            $timestampStart,
                            $timestampEnd - $timestampStart
                        )
                }
            }
            else {

                $timestampMatch =
                    [regex]::Match(
                        $linePrefix,
                        '"timestamp"\s*:\s*"([^"]+)"'
                    )


                if ($timestampMatch.Success) {

                    $lineTimestamp =
                        $timestampMatch.Groups[1].Value
                }
            }


            if (
                -not [string]::IsNullOrWhiteSpace(
                    [string]$lineTimestamp
                )
            ) {

                $hasSortableUtcFormat =
                    $lineTimestamp.Length -eq 24 -and
                    $lineTimestamp[4]  -eq '-' -and
                    $lineTimestamp[7]  -eq '-' -and
                    $lineTimestamp[10] -eq 'T' -and
                    $lineTimestamp[13] -eq ':' -and
                    $lineTimestamp[16] -eq ':' -and
                    $lineTimestamp[19] -eq '.' -and
                    $lineTimestamp[23] -eq 'Z'


                if ($hasSortableUtcFormat) {

                    if (
                        [string]::IsNullOrWhiteSpace(
                            [string]$SortableLastActiveTimestamp
                        ) -or
                        [string]::CompareOrdinal(
                            $lineTimestamp,
                            $SortableLastActiveTimestamp
                        ) -gt 0
                    ) {

                        $SortableLastActiveTimestamp =
                            $lineTimestamp
                    }
                }
                else {

                    # Preserve compatibility with any future timestamp
                    # representation that is not fixed-width UTC.

                    $parsedTime =
                        Convert-ToLocalDateTime `
                            $lineTimestamp


                    if (
                        $null -ne $parsedTime -and
                        (
                            $null -eq $LastActive -or
                            $parsedTime -gt $LastActive
                        )
                    ) {

                        $LastActive =
                            $parsedTime
                    }
                }
            }


            $lineType = $null
            $typeMarker = '"type":"'

            $typeStart =
                $linePrefix.IndexOf(
                    $typeMarker,
                    [StringComparison]::Ordinal
                )


            if ($typeStart -ge 0) {

                $typeStart +=
                    $typeMarker.Length

                $typeEnd =
                    $linePrefix.IndexOf(
                        '"',
                        $typeStart
                    )


                if ($typeEnd -gt $typeStart) {

                    $lineType =
                        $linePrefix.Substring(
                            $typeStart,
                            $typeEnd - $typeStart
                        )
                }
            }
            else {

                $typeMatch =
                    [regex]::Match(
                        $linePrefix,
                        '"type"\s*:\s*"([^"]+)"'
                    )


                if ($typeMatch.Success) {

                    $lineType =
                        $typeMatch.Groups[1].Value
                }
            }


            # ----------------------------------------------------------
            # Fast turn_context fields
            #
            # model and effort are JSON string scalars. Extracting them
            # directly avoids deserializing the large instruction blocks
            # that can also be stored in every turn_context record.
            # Full JSON parsing remains the fallback for an unfamiliar
            # or malformed representation.
            # ----------------------------------------------------------

            if (
                $lineType -eq "turn_context" -and
                $line[0] -eq '{' -and
                $line[$line.Length - 1] -eq '}'
            ) {

                $fastModel = $null
                $modelMarker = '"model":"'

                $modelStart =
                    $line.IndexOf(
                        $modelMarker,
                        [StringComparison]::Ordinal
                    )


                if ($modelStart -ge 0) {

                    $modelStart +=
                        $modelMarker.Length

                    $modelEnd =
                        $line.IndexOf(
                            '"',
                            $modelStart
                        )


                    if ($modelEnd -gt $modelStart) {

                        $fastModel =
                            $line.Substring(
                                $modelStart,
                                $modelEnd - $modelStart
                            )
                    }
                }


                $fastEffort = $null
                $effortMarker = '"effort":"'

                $effortStart =
                    $line.IndexOf(
                        $effortMarker,
                        [StringComparison]::Ordinal
                    )


                if ($effortStart -lt 0) {

                    $effortMarker =
                        '"reasoning_effort":"'

                    $effortStart =
                        $line.IndexOf(
                            $effortMarker,
                            [StringComparison]::Ordinal
                        )
                }


                if ($effortStart -ge 0) {

                    $effortStart +=
                        $effortMarker.Length

                    $effortEnd =
                        $line.IndexOf(
                            '"',
                            $effortStart
                        )


                    if ($effortEnd -gt $effortStart) {

                        $fastEffort =
                            $line.Substring(
                                $effortStart,
                                $effortEnd - $effortStart
                            )
                    }
                }


                if (
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$fastModel
                    ) -and
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$fastEffort
                    )
                ) {

                    if (
                        [string]::IsNullOrWhiteSpace(
                            [string]$FirstModel
                        )
                    ) {

                        $FirstModel =
                            $fastModel
                    }


                    $LastModel =
                        $fastModel


                    if (
                        [string]::IsNullOrWhiteSpace(
                            [string]$FirstEffort
                        )
                    ) {

                        $FirstEffort =
                            $fastEffort
                    }


                    $LastEffort =
                        $fastEffort

                    continue
                }
            }


            $isUserMessageEvent = $false


            if (
                $lineType -eq "event_msg" -and
                [string]::IsNullOrWhiteSpace(
                    [string]$FirstPrompt
                )
            ) {

                $isUserMessageEvent =
                    $linePrefix.IndexOf(
                        '"type":"user_message"',
                        [StringComparison]::Ordinal
                    ) -ge 0


                if (
                    -not $isUserMessageEvent -and
                    $typeStart -lt 0
                ) {

                    $isUserMessageEvent =
                        [regex]::IsMatch(
                            $linePrefix,
                            '"type"\s*:\s*"user_message"'
                        )
                }
            }


            $requiresJson =
                [string]::IsNullOrWhiteSpace(
                    [string]$lineType
                ) -or
                $lineType -eq "session_meta" -or
                $lineType -eq "turn_context" -or
                $isUserMessageEvent


            if (-not $requiresJson) {

                # A partially written final record usually lacks its
                # closing brace. Preserve useful parse-error reporting
                # without deserializing every unrelated JSON object.

                if (
                    $line[0] -ne '{' -or
                    $line[$line.Length - 1] -ne '}'
                ) {

                    $ParseErrors++
                }

                continue
            }


            try {

                $obj = $line | ConvertFrom-Json
            }
            catch {

                $ParseErrors++
                continue
            }


            if (
                [string]::IsNullOrWhiteSpace(
                    [string]$lineTimestamp
                )
            ) {

                $lineTimestamp =
                    Get-PropertyValue `
                        $obj `
                        "timestamp"
            }


            $type =
                Get-PropertyValue `
                    $obj `
                    "type"


            $payload =
                Get-PropertyValue `
                    $obj `
                    "payload"


            # ----------------------------------------------------------
            # session_meta
            #
            # Read:
            #   - Session ID
            #   - Created
            #   - CWD
            #   - Source
            #   - Parent thread
            # ----------------------------------------------------------

            if (
                $type -eq "session_meta" -and
                $null -ne $payload
            ) {

                if ($null -eq $Created) {

                    $Created =
                        Convert-ToLocalDateTime `
                            $lineTimestamp
                }


                $payloadMeta =
                    Get-PropertyValue `
                        $payload `
                        "meta"


                # ------------------------------------------------------
                # Session ID
                # ------------------------------------------------------

                if (
                    [string]::IsNullOrWhiteSpace(
                        [string]$SessionId
                    )
                ) {

                    $SessionId =
                        Get-PropertyValue `
                            $payload `
                            "id"


                    if (
                        [string]::IsNullOrWhiteSpace(
                            [string]$SessionId
                        )
                    ) {

                        $SessionId =
                            Get-PropertyValue `
                                $payload `
                                "session_id"
                    }


                    if (
                        [string]::IsNullOrWhiteSpace(
                            [string]$SessionId
                        ) -and
                        $null -ne $payloadMeta
                    ) {

                        $SessionId =
                            Get-PropertyValue `
                                $payloadMeta `
                                "id"
                    }


                    if (
                        [string]::IsNullOrWhiteSpace(
                            [string]$SessionId
                        ) -and
                        $null -ne $payloadMeta
                    ) {

                        $SessionId =
                            Get-PropertyValue `
                                $payloadMeta `
                                "session_id"
                    }
                }


                # ------------------------------------------------------
                # CWD
                # ------------------------------------------------------

                if (
                    [string]::IsNullOrWhiteSpace(
                        [string]$CWD
                    )
                ) {

                    $CWD =
                        Get-PropertyValue `
                            $payload `
                            "cwd"


                    if (
                        [string]::IsNullOrWhiteSpace(
                            [string]$CWD
                        ) -and
                        $null -ne $payloadMeta
                    ) {

                        $CWD =
                            Get-PropertyValue `
                                $payloadMeta `
                                "cwd"
                    }
                }


                # ------------------------------------------------------
                # Source
                # ------------------------------------------------------

                if (
                    [string]::IsNullOrWhiteSpace(
                        [string]$Source
                    )
                ) {

                    $sourceObject =
                        Get-PropertyValue `
                            $payload `
                            "source"


                    if (
                        $null -eq $sourceObject -and
                        $null -ne $payloadMeta
                    ) {

                        $sourceObject =
                            Get-PropertyValue `
                                $payloadMeta `
                                "source"
                    }


                    $Source =
                        Convert-SourceToString `
                            $sourceObject
                }


                # ------------------------------------------------------
                # Parent thread
                # ------------------------------------------------------

                if (
                    [string]::IsNullOrWhiteSpace(
                        [string]$ParentThreadId
                    )
                ) {

                    $ParentThreadId =
                        Find-PropertyRecursive `
                            -Object $payload `
                            -PropertyName "parent_thread_id"
                }


                continue
            }


            # ----------------------------------------------------------
            # First real user message
            # ----------------------------------------------------------

            if (
                [string]::IsNullOrWhiteSpace(
                    [string]$FirstPrompt
                ) -and
                $type -eq "event_msg" -and
                $null -ne $payload
            ) {

                $payloadType =
                    Get-PropertyValue `
                        $payload `
                        "type"


                if ($payloadType -eq "user_message") {

                    $message =
                        Get-PropertyValue `
                            $payload `
                            "message"


                    if (
                        -not [string]::IsNullOrWhiteSpace(
                            [string]$message
                        )
                    ) {

                        $FirstPrompt =
                            [string]$message
                    }
                }
            }


            # ----------------------------------------------------------
            # turn_context
            #
            # This is used for:
            #   - actual model
            #   - reasoning effort
            #
            # FirstModel / FirstEffort:
            #   first observed turn_context
            #
            # LastModel / LastEffort:
            #   latest observed turn_context
            # ----------------------------------------------------------

            if (
                $type -eq "turn_context" -and
                $null -ne $payload
            ) {

                # ------------------------------------------------------
                # Model
                # ------------------------------------------------------

                $model =
                    Get-PropertyValue `
                        $payload `
                        "model"


                if (
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$model
                    )
                ) {

                    if (
                        [string]::IsNullOrWhiteSpace(
                            [string]$FirstModel
                        )
                    ) {

                        $FirstModel =
                            [string]$model
                    }


                    $LastModel =
                        [string]$model
                }


                # ------------------------------------------------------
                # Reasoning Effort
                # ------------------------------------------------------

                $effort =
                    Get-PropertyValue `
                        $payload `
                        "effort"


                if (
                    [string]::IsNullOrWhiteSpace(
                        [string]$effort
                    )
                ) {

                    $collaborationMode =
                        Get-PropertyValue `
                            $payload `
                            "collaboration_mode"


                    if ($null -ne $collaborationMode) {

                        $settings =
                            Get-PropertyValue `
                                $collaborationMode `
                                "settings"


                        if ($null -ne $settings) {

                            $effort =
                                Get-PropertyValue `
                                    $settings `
                                    "reasoning_effort"
                        }
                    }
                }


                if (
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$effort
                    )
                ) {

                    if (
                        [string]::IsNullOrWhiteSpace(
                            [string]$FirstEffort
                        )
                    ) {

                        $FirstEffort =
                            [string]$effort
                    }


                    $LastEffort =
                        [string]$effort
                }
            }
        }
    }
    catch {

        Write-Warning (
            "Cannot read rollout: {0} (line {1}: {2})" -f
            $filePath,
            $_.InvocationInfo.ScriptLineNumber,
            $_.Exception.Message
        )

        continue
    }
    finally {

        if ($null -ne $reader) {

            $reader.Dispose()
        }
        elseif ($null -ne $stream) {

            $stream.Dispose()
        }
    }


    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$SortableLastActiveTimestamp
        )
    ) {

        $sortableLastActive =
            Convert-ToLocalDateTime `
                $SortableLastActiveTimestamp


        if (
            $null -ne $sortableLastActive -and
            (
                $null -eq $LastActive -or
                $sortableLastActive -gt $LastActive
            )
        ) {

            $LastActive =
                $sortableLastActive
        }
    }


    # ==================================================================
    # Session ID fallback from rollout filename
    # ==================================================================

    if (
        [string]::IsNullOrWhiteSpace(
            [string]$SessionId
        )
    ) {

        if (
            $rolloutFile.BaseName -match
            '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$'
        ) {

            $SessionId =
                $Matches[1]
        }
    }


    # ==================================================================
    # Time fallback
    #
    # Normally Codex JSONL timestamps are used.
    #
    # File-system timestamps are only used if JSONL timestamps could not
    # be obtained.
    # ==================================================================

    if ($null -eq $Created) {

        $Created =
            $rolloutFile.CreationTime
    }


    if ($null -eq $LastActive) {

        $LastActive =
            $rolloutFile.LastWriteTime
    }


    # ==================================================================
    # Exact title lookup
    #
    # Priority:
    #
    #   1. session_index.jsonl
    #   2. state_5.sqlite
    #   3. (Untitled)
    #
    # FirstPrompt is deliberately NOT treated as the exact Codex title.
    # ==================================================================

    $Title       = "(Untitled)"
    $TitleSource = "none"


    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$SessionId
        ) -and
        $IndexTitles.ContainsKey(
            [string]$SessionId
        )
    ) {

        $Title =
            $IndexTitles[
                [string]$SessionId
            ]

        $TitleSource =
            "session_index"
    }
    elseif (
        -not [string]::IsNullOrWhiteSpace(
            [string]$SessionId
        ) -and
        $StateTitles.ContainsKey(
            [string]$SessionId
        )
    ) {

        $Title =
            $StateTitles[
                [string]$SessionId
            ]

        $TitleSource =
            "state_5.sqlite"
    }


    # ==================================================================
    # Project assignment
    #
    # Priority:
    #
    #   1. state_5.sqlite threads.project_id
    #   2. .codex-global-state.json thread-project-assignments
    #   3. standalone-session marker plus the full CWD
    #
    # The global-state fallback is required by Codex Desktop versions
    # whose project migration leaves threads.project_id empty while the
    # UI still has valid thread-to-project assignments.
    # ==================================================================

    $Project       = $null
    $ProjectId     = $null
    $ProjectPath   = $null
    $ProjectSource = "none"


    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$SessionId
        ) -and
        $StateProjects.ContainsKey(
            [string]$SessionId
        )
    ) {

        $projectRecord =
            $StateProjects[
                [string]$SessionId
            ]

        $Project =
            $projectRecord.ProjectName

        $ProjectId =
            $projectRecord.ProjectId

        $ProjectPath =
            $projectRecord.ProjectPath

        $ProjectSource =
            "state_5.sqlite"
    }
    elseif (
        -not [string]::IsNullOrWhiteSpace(
            [string]$SessionId
        ) -and
        $GlobalThreadProjects.ContainsKey(
            [string]$SessionId
        )
    ) {

        $ProjectId =
            $GlobalThreadProjects[
                [string]$SessionId
            ]

        $ProjectSource =
            "global_state"


        if (
            $GlobalProjects.ContainsKey(
                [string]$ProjectId
            )
        ) {

            $projectRecord =
                $GlobalProjects[
                    [string]$ProjectId
                ]

            $Project =
                $projectRecord.ProjectName

            $ProjectPath =
                $projectRecord.ProjectPath
        }
    }


    if (
        [string]::IsNullOrWhiteSpace(
            [string]$Project
        ) -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$ProjectPath
        )
    ) {

        try {

            $trimmedProjectPath =
                ([string]$ProjectPath).TrimEnd(
                    [char[]]@(
                        '\',
                        '/'
                    )
                )

            $Project =
                ($trimmedProjectPath -split '[\\/]')[-1]
        }
        catch {

            $Project = $null
        }
    }


    if (
        [string]::IsNullOrWhiteSpace(
            [string]$Project
        ) -and
        [string]::IsNullOrWhiteSpace(
            [string]$ProjectId
        ) -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$CWD
        )
    ) {

        $Project =
            "<Standalone Session>"

        $ProjectId =
            "<N/A>"

        $ProjectPath =
            [string]$CWD

        $ProjectSource =
            "standalone"
    }


    # ==================================================================
    # Detect Codex internal sessions
    # ==================================================================

    $InternalReasons =
        New-Object `
            System.Collections.Generic.List[string]


    # codex-auto-review

    if (
        $FirstModel -eq "codex-auto-review" -or
        $LastModel -eq "codex-auto-review"
    ) {

        $InternalReasons.Add(
            "codex-auto-review"
        )
    }


    # Guardian / Sub-agent source

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$Source
        ) -and
        $Source -match '(?i)subagent|guardian'
    ) {

        $InternalReasons.Add(
            "subagent/guardian"
        )
    }


    # Child thread

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$ParentThreadId
        )
    ) {

        $InternalReasons.Add(
            "child-thread"
        )
    }


    # Approval/review prompt

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$FirstPrompt
        ) -and
        $FirstPrompt -match
        '(?i)^The following is the Codex agent history whose request action you are assessing'
    ) {

        $InternalReasons.Add(
            "approval-review"
        )
    }


    $IsInternal =
        ($InternalReasons.Count -gt 0)


    if (
        -not $IncludeInternal -and
        $IsInternal
    ) {

        continue
    }


    # ==================================================================
    # Output values
    #
    # Keep raw last values available for exact filtering and export.
    # Decorate the display-facing LastModel / LastEffort values only when
    # both values exist and the first and last values differ.
    # ==================================================================

    $LastModelDisplay = $LastModel
    $LastEffortDisplay = $LastEffort


    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$FirstModel
        ) -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$LastModel
        ) -and
        $FirstModel -ne $LastModel
    ) {

        $LastModelDisplay =
            "{0} *" -f $LastModel
    }


    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$FirstEffort
        ) -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$LastEffort
        ) -and
        $FirstEffort -ne $LastEffort
    ) {

        $LastEffortDisplay =
            "{0} *" -f $LastEffort
    }


    # ==================================================================
    # Output object
    # ==================================================================

    [PSCustomObject]@{

        Title =
            $Title

        DisplayTitle =
            Get-DisplayText `
                $Title

        TitleSource =
            $TitleSource


        Created =
            $Created

        LastActive =
            $LastActive


        SessionId =
            $SessionId


        FirstModel =
            $FirstModel

        FirstEffort =
            $FirstEffort


        LastModel =
            $LastModelDisplay

        LastEffort =
            $LastEffortDisplay

        LastModelRaw =
            $LastModel

        LastEffortRaw =
            $LastEffort


        Project =
            $Project

        ProjectId =
            $ProjectId

        ProjectPath =
            $ProjectPath

        ProjectSource =
            $ProjectSource

        CWD =
            $CWD


        Source =
            $Source

        ParentThreadId =
            $ParentThreadId


        IsInternal =
            $IsInternal

        InternalReason =
            ($InternalReasons -join ", ")


        FirstPrompt =
            $FirstPrompt


        ParseErrors =
            $ParseErrors

        JsonlPath =
            $filePath
    }
}

if (-not $NoProgress) {

    Write-Progress `
        -Activity $ProgressActivity `
        -Completed
}


# ======================================================================
# Default sorting:
#
# LastActive newest -> oldest
# ======================================================================

$SortedResults = @(

    $Results |
        Sort-Object `
            LastActive `
            -Descending
)


if ($ColorOutput) {

    Write-ColorSessionTable `
        -InputObject $SortedResults `
        -Properties $Property `
        -HighlightColor $StandaloneColor
}
else {

    $SortedResults
}
