# 04 TPL检索规则

## 权威来源

优先顺序：

1. `indexes/item_tpl_index.jsonl`
2. `indexes/item_name_index_ch.json`
3. `indexes/item_name_index_en.json`
4. 本地已补全时，再查 `sources/server-csharp-4.0.13/.../SPT_Data/database/templates/items.json`

## 先分清 `_tpl` 和实例 `_id`

- `_tpl`
  - 模板 id
  - 写进 quest `target`
  - 写进奖励 `items[*]._tpl`
- `_id`
  - 某一条奖励实例、物品实例的唯一 id
  - 不能拿来当模板 id

## 检索建议

已知中文名时：

- 先查 `item_name_index_ch.json`

已知英文名时：

- 先查 `item_name_index_en.json`

已知 TPL 时：

- 直接查 `item_tpl_index.jsonl`

说明：

- git 同步版默认依赖 `indexes/`
- 大体积 `SPT_Data` 资产数据库通常不会随远端仓库同步

## 常用物品

- 卢布：`5449016a4bdc2d6f028b456f`
- BEAR 狗牌：`59f32bb586f774757e1e8442`
- USEC 狗牌：`59f32c3b86f77472a31742f0`

## zoneId 与地图

- 地图与撤离点摘要：`indexes/map_zone_index.json`
- 任务中真实出现过的 zoneId 样例：同文件 `zoneExamples`

规则：

- zoneId 不要猜
- 要么引用官方已有 zoneId
- 要么回查具体地图资源

## 生成前动作

1. 先确认目标物品 TPL
2. 再确认奖励物品 TPL
3. 最后跑 `validators/validate_tpl_refs.py`
