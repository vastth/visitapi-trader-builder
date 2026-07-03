[CmdletBinding()]
param(
    [string]$RemoteHost = "100.124.60.38",
    [string]$RemoteRoot = "C:\Game\EFT 4",
    [switch]$SkipLocal,
    [switch]$SkipRemote,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$files = @(
    [PSCustomObject]@{
        Name = "fence-proof-of-work.json"
        SourcePath = Join-Path $scriptDir "fence-proof-of-work.json"
        LocalTarget = "D:\EFT 4\SPT\user\mods\VisitAPI-Server\db\quests\fence-proof-of-work.json"
        RemoteTarget = $null
    },
    [PSCustomObject]@{
        Name = "ch.json"
        SourcePath = Join-Path $scriptDir "ch.json"
        LocalTarget = "D:\EFT 4\SPT\user\mods\VisitAPI-Server\db\locales\ch.json"
        RemoteTarget = $null
    },
    [PSCustomObject]@{
        Name = "579dc571d53a0658a154fbec.dlg"
        SourcePath = Join-Path $scriptDir "579dc571d53a0658a154fbec.dlg"
        LocalTarget = "D:\EFT 4\BepInEx\config\VisitAPI\579dc571d53a0658a154fbec.dlg"
        RemoteTarget = Join-Path $RemoteRoot "BepInEx\config\VisitAPI\579dc571d53a0658a154fbec.dlg"
    }
)

function Assert-SourceFiles {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Items
    )

    foreach ($item in $Items) {
        if (-not (Test-Path -LiteralPath $item.SourcePath)) {
            throw "Source file not found: $($item.SourcePath)"
        }
    }
}

function Copy-ToLocalTarget {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Item,
        [switch]$Simulate
    )

    $targetDir = Split-Path -Parent $Item.LocalTarget
    if ($Simulate) {
        Write-Host "[DRY RUN] Local copy: $($Item.SourcePath) -> $($Item.LocalTarget)"
        return
    }

    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    Copy-Item -LiteralPath $Item.SourcePath -Destination $Item.LocalTarget -Force
    Write-Host "[OK] Local installed: $($Item.LocalTarget)"
}

function Convert-ToRemoteUncPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        [Parameter(Mandatory = $true)]
        [string]$DrivePath
    )

    $driveLetter = $DrivePath.Substring(0, 1).ToLowerInvariant()
    $subPath = $DrivePath.Substring(2).TrimStart("\")
    return "\\{0}\{1}$\{2}" -f $HostName, $driveLetter, $subPath
}

function Copy-ToRemoteTarget {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Item,
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        [switch]$Simulate
    )

    if ([string]::IsNullOrWhiteSpace($Item.RemoteTarget)) {
        return
    }

    $uncTarget = Convert-ToRemoteUncPath -HostName $HostName -DrivePath $Item.RemoteTarget

    if ($Simulate) {
        Write-Host "[DRY RUN] Remote copy over Tailscale path: $($Item.SourcePath) -> $uncTarget"
        return
    }

    $targetDir = Split-Path -Parent $uncTarget
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    Copy-Item -LiteralPath $Item.SourcePath -Destination $uncTarget -Force
    Write-Host "[OK] Remote installed: $uncTarget"
}

try {
    Assert-SourceFiles -Items $files

    if (-not (Get-Command tailscale -ErrorAction SilentlyContinue)) {
        throw "tailscale.exe was not found in PATH."
    }

    if (-not $SkipRemote) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Tailscale connectivity check: tailscale ping $RemoteHost"
        }
        else {
            & tailscale ping $RemoteHost
            if ($LASTEXITCODE -ne 0) {
                throw "tailscale ping failed for $RemoteHost."
            }
        }
    }

    Write-Host "Source directory: $scriptDir"
    Write-Host "Remote host: $RemoteHost"
    if (-not $SkipLocal) {
        Write-Host "Deploying files to local Zeus instance..."
        foreach ($file in $files) {
            Copy-ToLocalTarget -Item $file -Simulate:$DryRun
        }
    }
    else {
        Write-Host "Skipping local Zeus deployment."
    }

    if (-not $SkipRemote) {
        Write-Host "Deploying files to remote MSI instance over the Tailscale network..."
        foreach ($file in $files) {
            Copy-ToRemoteTarget -Item $file -HostName $RemoteHost -Simulate:$DryRun
        }
    }
    else {
        Write-Host "Skipping remote MSI deployment."
    }

    if ($DryRun) {
        Write-Host "Dry run finished. No files were changed."
    }
    else {
        Write-Host "Deployment finished successfully."
    }
}
catch {
    Write-Error $_
    exit 1
}

exit 0