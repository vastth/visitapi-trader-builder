# MANIFEST

更新时间：`2026-07-03`

## 版本

- VisitAPI：`0.4`
- SPT：`4.0.13`
- 资料包名称：`visitapi-trader-builder-zh`

## 目标

为网页版 GPT 与本地 Codex 提供一套可直接引用的 VisitAPI 权威资料包，重点覆盖：

- 商人 `.dlg` 对话
- 战局 / 藏身处交互点
- 原生 Quest JSON
- quest locale
- quest-locked assort
- TPL 检索
- 生成前校验

## 原始来源

### `sources/VisitAPI-main/`

来源：`D:\EFT 4\MOD-CREAT\VisitAPI-0.4\VisitAPI-main.zip` 解压结果。

用途：

- `README.md`
- `docs/DLG_FORMAT.zh-CN.md`
- `Server/VisitApiQuestLoader.cs`
- `Server/VisitApiAssortInjector.cs`
- `Client/Dialog/*`
- `Client/Quest/*`
- `Client/Raid/*`

### `sources/server-csharp-4.0.13/`

来源：

1. `D:\EFT 4\MOD-CREAT\VisitAPI-0.4\server-csharp-4.0.13.zip` 解压结果
2. 用本机真实 SPT 资料库补全 `Libraries/SPTarkov.Server.Assets/SPT_Data/database`

本机补全来源：

- `D:\EFT 4\SPT\SPT_Data\database`

原因：

- 压缩包内数据库资源存在 Git LFS 指针风险，不能直接拿来做全量 TPL 检索。
- 为保证 `items.json / quests.json / locales / traders / locations` 可直接查用，已用本机真实 SPT 数据库完成补全。

Git 同步版附加说明：

- 为避免远端仓库体积过大，`sources/server-csharp-4.0.13/Libraries/SPTarkov.Server.Assets/SPT_Data/` 与 `sources/server-csharp-4.0.13/Testing/` 作为本地大文件目录处理，不进入 git。
- 远端仓库依赖 `indexes/` 提供 TPL、地图、任务样例与 locale 检索能力。
- 需要全量资产数据库时，应在本地从真实 SPT 安装补齐，不应指望 git 仓库内自带。

## 目录清单

- `SKILL.md`
  - 总说明、使用顺序、强制规则、禁止事项
- `MANIFEST.md`
  - 当前文件清单与来源说明
- `sources/`
  - 权威原始来源，只读
- `references/`
  - 给人读的短规则文档
- `indexes/`
  - 给模型高效读取的机器索引
- `templates/`
  - 可直接复用的起手模板
- `validators/`
  - 生成前校验脚本
- `examples/`
  - 已整理的样例与官方摘录
- `workspace/`
  - 当前正在开发或测试中的任务
- `agents/openai.yaml`
  - 保留给本地 Codex skill 识别使用；网页版 GPT 可忽略

## 索引说明

- `item_tpl_index.jsonl`
  - 全量物品模板索引，按行 JSON，适合按需读取
- `item_name_index_ch.json`
  - 中文名到 TPL 的反查表
- `item_name_index_en.json`
  - 英文名到 TPL 的反查表
- `official_quest_examples.json`
  - 官方任务条件与奖励样例摘要
- `trader_index.json`
  - 商人摘要索引
- `map_zone_index.json`
  - 地图、撤离点、zoneId 样例摘要
- `locale_key_index.json`
  - quest locale 必填 key 与核心全局 key 摘要

## 校验器说明

- `validate_quest_json.py`
  - 检查 quest 顶层字段、条件字段、奖励字段、`_id/templateId`
- `validate_dlg.py`
  - 检查节点跳转是否存在
- `validate_tpl_refs.py`
  - 检查任务目标和奖励中的 TPL 是否存在
- `validate_locale_keys.py`
  - 检查 quest locale 必填 key 与 handover condition locale key

## 说明

- 本包优先服务“稳定生成正确文件”，不是全量百科。
- 若未来升级到新 SPT 版本，必须重新核对 `Quest.cs`、`Reward.cs`、`Item.cs`、VisitAPI 源码与所有索引。
