---
name: visitapi-trader-builder-zh
description: 用于在 VisitAPI + SPT 4.0.13 环境中规划、生成、校验商人对话、战局遭遇、任务、任务本地化与任务解锁货架。构建任何 quest JSON 前，必须先查看 Quest.cs 作为权威模型。
---

# VisitAPI Trader Builder ZH

这是一个给本地 Codex 和网页版 GPT 共用的 VisitAPI 开发资料包。

目标不是保留全量源码讲解，而是把“做商人 / 做任务 / 做对话”真正需要的权威事实压缩成一套稳定结构，降低模型在低上下文下写错 quest JSON、写错 `.dlg`、写错 TPL、漏 locale key 的概率。

## 版本边界

- VisitAPI：`0.4`
- SPT：`4.0.13`
- 任务模型权威：`sources/server-csharp-4.0.13/Libraries/SPTarkov.Server.Core/Models/Eft/Common/Tables/Quest.cs`
- VisitAPI 任务加载权威：`sources/VisitAPI-main/Server/VisitApiQuestLoader.cs`
- VisitAPI 货架注入权威：`sources/VisitAPI-main/Server/VisitApiAssortInjector.cs`

Git 同步版说明：

- 远端仓库默认不携带大体积 `SPT_Data` 资产数据库与 `Testing` 目录。
- 需要全量物品、地图、locale 检索时，优先使用 `indexes/`。
- 若本地需要做更深的源码 / 数据核对，再自行补全 `sources/server-csharp-4.0.13/Libraries/SPTarkov.Server.Assets/SPT_Data/`。

## 目录使用顺序

1. 先读 `references/01-任务结构规则.md`
2. 再读 `references/02-DLG语法规则.md`
3. 涉及战局触发与行为边界时读 `references/03-VisitAPI运行边界.md`
4. 涉及物品、奖励、上交目标时读 `references/04-TPL检索规则.md`
5. 生成前读 `references/05-常见错误清单.md`
6. 查机器索引时读 `indexes/`
7. 复用模板时读 `templates/`
8. 参考可运行闭环时读 `examples/`
9. 当前开发中的文件放在 `workspace/`

## 强制规则

1. `db/quests/*.json` 必须按原生 `Quest` 模型写，不要臆造 VisitAPI 专用 quest DTO。
2. 判断 quest 字段是否合法时，以 `Quest.cs` 为准，不以“看起来合理”或旧社区样例为准。
3. `VisitAPI-main/Server/VisitApiQuestLoader.cs` 当前是把 quest 文件反序列化为 `Dictionary<string, Quest>` 后注册，所以 quest JSON 必须严格贴合 SPT 模型。
4. `HandoverItem` 条件用 `target`，不要写 `items` 或 `categories`。
5. Raid 内接任务、交任务、完成任务，优先用 `accept:` / `handover:` / `complete:`，不要把 raid 流程建立在 `@tasks` 上。
6. 生成任务文件前必须运行 `validators/` 中至少三类校验：
   - quest 结构校验
   - TPL 引用校验
   - locale key 校验
7. 需要 zoneId、撤离点、商品树、复杂奖励时，不要猜，必须回查 `sources/` 或 `indexes/`。

## 已确认的 VisitAPI 关键边界

- `.dlg` 正文不会自动双语；想双语就自己在正文里中英并排写。
- VisitAPI 自己生成的按钮与系统提示会跟随游戏语言。
- 背景支持图片与循环视频，详见 `references/02-DLG语法规则.md`。
- Raid trigger 的 `door`、`once`、`repeat` 能被 parser 解析，但当前 raid 运行层不能把它们当作完全可靠的门碰撞盒 / 一次性控制。

## 标准工作流

1. 明确目标：纯对话、战局遭遇、对话接交任务、任务解锁货架，还是混合。
2. 先收集要素：商人 ID、地图、坐标、交互提示、触发方式、任务类型、上交 / 击杀 / 到达目标、奖励、语言、素材。
3. 从 `templates/` 选最接近的模板。
4. 用 `indexes/` 确认 trader id、TPL、地图、zoneId、locale key 规则。
5. 对照 `examples/` 生成实际文件。
6. 运行 `validators/`。
7. 需要进一步证明时，回查 `sources/VisitAPI-main/` 与 `sources/server-csharp-4.0.13/`。

## 禁止事项

- 不要把 Git LFS 指针文件当成真实 `items.json` 使用。
- 不要把实例物品 `_id` 当成模板 `_tpl` 写进任务目标或奖励。
- 不要假设 raid 内 `@trade` / `@tasks` / `@services` 等同主菜单行为。
- 不要未经核对就宣称某个 `zoneId`、撤离点名、assort 结构一定可用。
- 不要省略 quest locale 必填 key。

## 本包定位

- 适合：基础商人对话、VisitAPI 战局遭遇、简单上交任务、基础击杀任务、基础到达任务、简单奖励、基础 quest-locked assort。
- 不承诺零风险：复杂多阶段 CounterCreator、精细 zoneId 放置、多条件链式任务、复杂整枪 assort 解锁。此类内容必须结合实际日志和进游戏测试。
