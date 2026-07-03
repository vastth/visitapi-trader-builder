param(
    [string]$RepoRoot = "D:\EFT 4\MOD-CREAT\visitapi-trader-builde",
    [string]$TaskName = "visitapi-trader-builde-autosync"
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WatcherScript = Join-Path $ScriptDir "watch-git-sync.ps1"

if (-not (Test-Path -LiteralPath $WatcherScript)) {
    throw "watcher script not found: $WatcherScript"
}

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WatcherScript`" -RepoRoot `"$RepoRoot`""

$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Watch $RepoRoot and auto commit/push git changes"

Write-Host "Installed scheduled task: $TaskName"
Write-Host "Repo: $RepoRoot"
Write-Host "Watcher: $WatcherScript"
Write-Host "Run this once to start now:"
Write-Host "Start-ScheduledTask -TaskName '$TaskName'"

