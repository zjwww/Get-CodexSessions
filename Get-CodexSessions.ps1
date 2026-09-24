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
    #   .\Get-CodexSessions.ps1 -CodexHome "D:\MyCodex"
    #
    #   ./Get-CodexSessions.ps1 -CodexHome "/Users/me/.codex"
    #
    [string]$CodexHome,

    # Optional:
    # Suppress host-native progress display.
    #
    [switch]$NoProgress
)

# ======================================================================
# Get-CodexSessions.ps1
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
#   <CodexHome>/state_5.sqlite
#   <CodexHome>/sessions/.../rollout-*.jsonl
#
# This script DOES NOT modify:
#   - Codex sessions
#   - session_index.jsonl
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
# ======================================================================


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


$StateTitles = @{}


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


    try {

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


        while (($line = $reader.ReadLine()) -ne $null) {

            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }


            try {

                $obj = $line | ConvertFrom-Json
            }
            catch {

                $ParseErrors++
                continue
            }


            # ----------------------------------------------------------
            # Timestamp
            # ----------------------------------------------------------

            $lineTimestamp =
                Get-PropertyValue `
                    $obj `
                    "timestamp"


            if (
                -not [string]::IsNullOrWhiteSpace(
                    [string]$lineTimestamp
                )
            ) {

                $parsedTime =
                    Convert-ToLocalDateTime `
                        $lineTimestamp


                if ($null -ne $parsedTime) {

                    if (
                        $null -eq $LastActive -or
                        $parsedTime -gt $LastActive
                    ) {

                        $LastActive = $parsedTime
                    }
                }
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
            "Cannot read rollout: {0}" -f $filePath
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
    # Project name
    #
    # Works with:
    #
    # Windows:
    #   C:\Project\Example
    #
    # macOS/Linux:
    #   /Users/me/Project/Example
    # ==================================================================

    $Project = $null


    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$CWD
        )
    ) {

        try {

            $trimmedCwd =
                ([string]$CWD).TrimEnd(
                    [char[]]@(
                        '\',
                        '/'
                    )
                )


            $Project =
                Split-Path `
                    $trimmedCwd `
                    -Leaf
        }
        catch {

            $Project = $null
        }
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
            $LastModel

        LastEffort =
            $LastEffort


        Project =
            $Project

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

$Results |
    Sort-Object `
        LastActive `
        -Descending
