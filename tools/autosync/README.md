# Git Autosync

这个目录提供给 `visitapi-trader-builde` 仓库的本地自动同步脚本。

## 行为

- 监听仓库文件变化
- 自动执行 `git add -A`
- 自动执行 `git commit`
- 如果已经配置了 git remote，则继续自动 `git push`
- 如果还没有 remote，则只做本地自动提交

## 安装

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\autosync\install-autosync-task.ps1
```

安装后，任务计划会在用户登录时自动启动监听器。

## 立即启动

```powershell
Start-ScheduledTask -TaskName 'visitapi-trader-builde-autosync'
```

## 卸载

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\autosync\uninstall-autosync-task.ps1
```

## 日志

- 日志路径：`.autosync/watcher.log`
- `.autosync/` 已加入 `.gitignore`

## 远端

当前仓库如果没有配置 remote，需要先手动添加，例如：

```powershell
git remote add origin <你的仓库URL>
```

一旦 remote 存在，后续监听器会在每次自动提交后自动推送。
