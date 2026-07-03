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

function Write-Status {
    param([string]$Message)
    Write-Host "[autosync] $Message"
}

function Invoke-Git {
    param(
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
    $result = Invoke-Git -Arguments @('status', '--porcelain', '--untracked-files=all')
    if ($result.ExitCode -ne 0) {
        throw "git status failed: $($result.Output)"
    }
    return $result.Output
}

function Get-RemoteName {
    $result = Invoke-Git -Arguments @('remote')
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
    $result = Invoke-Git -Arguments @('branch', '--show-current')
    if ($result.ExitCode -ne 0) {
        throw "git branch failed: $($result.Output)"
    }
    return $result.Output.Trim()
}

function Queue-Change {
    param([string]$Reason)

    $script:PendingReason = $Reason
    $script:LastEventAt = Get-Date
    Write-Status "change detected: $Reason"
}

function Test-PendingSyncReady {
    if ($script:SyncInProgress) {
        return $false
    }

    if ($script:LastEventAt -eq [datetime]::MinValue) {
        return $false
    }

    $age = (Get-Date) - $script:LastEventAt
    return $age.TotalSeconds -ge $DebounceSeconds
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
        Write-Status "change detected: $Reason"

        $add = Invoke-Git -Arguments @('add', '-A')
        if ($add.ExitCode -ne 0) {
            throw "git add failed: $($add.Output)"
        }

        $statusAfterAdd = Get-TrackedChanges
        if (-not $statusAfterAdd) {
            return
        }

        $commitMessage = "auto-sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $commit = Invoke-Git -Arguments @('commit', '-m', $commitMessage, '--no-verify')
        if ($commit.ExitCode -ne 0) {
            if ($commit.Output -match "nothing to commit") {
                return
            }
            throw "git commit failed: $($commit.Output)"
        }

        Write-Log "commit created: $commitMessage"
        Write-Status "commit created: $commitMessage"

        $remoteName = Get-RemoteName
        if (-not $remoteName) {
            Write-Log "no remote configured; local auto-commit only"
            Write-Status "no remote configured; local auto-commit only"
            return
        }

        $branchName = Get-BranchName
        if (-not $branchName) {
            throw "branch name is empty"
        }

        $push = Invoke-Git -Arguments @('push', '-u', $remoteName, $branchName)
        if ($push.ExitCode -ne 0) {
            throw "git push failed: $($push.Output)"
        }

        Write-Log "push completed: $remoteName/$branchName"
        Write-Status "push completed: $remoteName/$branchName"
    }
    catch {
        Write-Log "sync error: $($_.Exception.Message)"
        Write-Status "sync error: $($_.Exception.Message)"
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
    Write-Status "watcher already running for $RepoRoot"
    exit 0
}

Write-Log "watcher started for $RepoRoot"
Write-Status "watcher started for $RepoRoot"

try {
    Write-Status "polling for working tree changes every $DebounceSeconds seconds"
    while ($true) {
        $status = Get-TrackedChanges
        if ($status) {
            Queue-Change -Reason "working tree changes"
            Invoke-CommitAndPush -Reason $script:PendingReason
            $script:PendingReason = ""
            $script:LastEventAt = [datetime]::MinValue
        }

        Start-Sleep -Seconds $DebounceSeconds
    }
}
finally {
    $mutex.ReleaseMutex() | Out-Null
    $mutex.Dispose()
    Write-Log "watcher stopped"
    Write-Status "watcher stopped"
}

