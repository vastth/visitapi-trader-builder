param(
    [string]$RepoRoot = "D:\EFT 4\MOD-CREAT\visitapi-trader-builde",
    [int]$DebounceSeconds = 4
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$StateDir = Join-Path $RepoRoot ".autosync"
$LogPath = Join-Path $StateDir "watcher.log"
$RepoName = Split-Path -Leaf $RepoRoot
$script:SyncInProgress = $false
$script:PendingReason = ""
$script:LastEventAt = [datetime]::MinValue

New-Item -ItemType Directory -Force -Path $StateDir | Out-Null

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $LogPath -Value "[$timestamp] $Message" -Encoding UTF8
}

function Invoke-Git {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    $output = & git -C $RepoRoot @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = ($output -join [Environment]::NewLine).Trim()
    }
}

function Get-TrackedChanges {
    $result = Invoke-Git status --porcelain --untracked-files=all
    if ($result.ExitCode -ne 0) {
        throw "git status failed: $($result.Output)"
    }
    return $result.Output
}

function Get-RemoteName {
    $result = Invoke-Git remote
    if ($result.ExitCode -ne 0) {
        throw "git remote failed: $($result.Output)"
    }
    $lines = @($result.Output -split "`r?`n" | Where-Object { $_.Trim() })
    if ($lines.Count -gt 0) {
        return $lines[0].Trim()
    }
    return $null
}

function Get-BranchName {
    $result = Invoke-Git branch --show-current
    if ($result.ExitCode -ne 0) {
        throw "git branch failed: $($result.Output)"
    }
    return $result.Output.Trim()
}

function Invoke-CommitAndPush {
    param([string]$Reason)

    if ($script:SyncInProgress) {
        return
    }

    $script:SyncInProgress = $true
    try {
        Start-Sleep -Seconds $DebounceSeconds

        $status = Get-TrackedChanges
        if (-not $status) {
            return
        }

        Write-Log "change detected: $Reason"

        $add = Invoke-Git add -A
        if ($add.ExitCode -ne 0) {
            throw "git add failed: $($add.Output)"
        }

        $statusAfterAdd = Get-TrackedChanges
        if (-not $statusAfterAdd) {
            return
        }

        $commitMessage = "auto-sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $commit = Invoke-Git commit -m $commitMessage --no-verify
        if ($commit.ExitCode -ne 0) {
            if ($commit.Output -match "nothing to commit") {
                return
            }
            throw "git commit failed: $($commit.Output)"
        }

        Write-Log "commit created: $commitMessage"

        $remoteName = Get-RemoteName
        if (-not $remoteName) {
            Write-Log "no remote configured; local auto-commit only"
            return
        }

        $branchName = Get-BranchName
        if (-not $branchName) {
            throw "branch name is empty"
        }

        $push = Invoke-Git push -u $remoteName $branchName
        if ($push.ExitCode -ne 0) {
            throw "git push failed: $($push.Output)"
        }

        Write-Log "push completed: $remoteName/$branchName"
    }
    catch {
        Write-Log "sync error: $($_.Exception.Message)"
    }
    finally {
        $script:SyncInProgress = $false
    }
}

function Test-IgnoredPath {
    param([string]$FullPath)

    if (-not $FullPath) {
        return $true
    }

    $full = [System.IO.Path]::GetFullPath($FullPath)
    if ($full.StartsWith((Join-Path $RepoRoot ".git"), [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    if ($full.StartsWith($StateDir, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    return $false
}

$mutexName = "visitapi-autosync-" + ([BitConverter]::ToString(
    [System.Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($RepoRoot))
).Replace("-", "").ToLowerInvariant())

$mutex = New-Object System.Threading.Mutex($false, $mutexName)
if (-not $mutex.WaitOne(0, $false)) {
    Write-Log "watcher already running for $RepoRoot"
    exit 0
}

Write-Log "watcher started for $RepoRoot"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $RepoRoot
$watcher.Filter = "*"
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, DirectoryName, LastWrite, CreationTime, Size'
$watcher.EnableRaisingEvents = $true

$timer = New-Object System.Timers.Timer
$timer.Interval = $DebounceSeconds * 1000
$timer.AutoReset = $false

$enqueueAction = {
    $path = $Event.SourceEventArgs.FullPath
    if (Test-IgnoredPath $path) {
        return
    }
    $script:PendingReason = "{0}: {1}" -f $Event.SourceEventArgs.ChangeType, $path
    $script:LastEventAt = Get-Date
    $timer.Stop()
    $timer.Start()
}

$timerAction = {
    if ($script:SyncInProgress) {
        return
    }
    $age = (Get-Date) - $script:LastEventAt
    if ($age.TotalSeconds -lt $DebounceSeconds) {
        return
    }
    Invoke-CommitAndPush -Reason $script:PendingReason
}

$subscriptions = @(
    (Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $enqueueAction),
    (Register-ObjectEvent -InputObject $watcher -EventName Created -Action $enqueueAction),
    (Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $enqueueAction),
    (Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $enqueueAction),
    (Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action $timerAction)
)

try {
    while ($true) {
        Wait-Event -Timeout 5 | Out-Null
    }
}
finally {
    foreach ($subscription in $subscriptions) {
        Unregister-Event -SubscriptionId $subscription.Id -ErrorAction SilentlyContinue
        Remove-Job -Id $subscription.Id -Force -ErrorAction SilentlyContinue
    }
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    $timer.Stop()
    $timer.Dispose()
    $mutex.ReleaseMutex() | Out-Null
    $mutex.Dispose()
    Write-Log "watcher stopped"
}

