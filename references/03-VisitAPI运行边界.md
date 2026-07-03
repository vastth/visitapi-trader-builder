# 03 VisitAPI运行边界

## 任务加载边界

`sources/VisitAPI-main/Server/VisitApiQuestLoader.cs` 当前走的是原生 quest 注册链路。

结论：

- `db/quests/*.json` 必须按 SPT 原生 `Quest` 模型写
- VisitAPI 不提供一套可随意扩展字段的 quest JSON DTO

## Raid 对话边界

raid 内推荐：

- `accept:`
- `handover:`
- `complete:`

raid 内不应依赖：

- `@tasks`
- `@trade`
- `@services`

原因：

- 这些跳转本质更偏主菜单 trader 页面行为
- 作为 raid 主流程会带来 no-op 或行为不一致风险

## Trigger 解析与实际运行层不是一回事

源码层已确认：

- parser 能解析 `door`
- parser 能解析 `once`
- parser 能解析 `repeat`

但当前 raid 运行层的实际可靠边界应按下面理解：

- `door`
  - 可以写、能被 parser 识别
  - 但当前 raid 触发器不应当作“严格门型碰撞盒”来信任
- `once/repeat`
  - 可以写、能被 parser 识别
  - 但当前 raid trigger 不应当作“可靠的一次性持久控制”来设计关键流程

更保守的设计原则：

- raid 触发逻辑按“坐标 + 距离 + 视线角度提示”理解
- 需要唯一性或进度控制时，交给 quest 状态或对话分支控制，不要交给 raid trigger 自身

## 首次见面边界

- `first:` 适合做首次见面分支
- 主菜单 Talk 入口会直接进入常规根节点族，不会重放首次见面逻辑

## 战局是否暂停

源码中未见“打开对话后暂停 raid”这一层控制。

保守结论：

- 设计 raid 交互时，应按“战局继续流动”处理
- 不要假设玩家在对话期间绝对安全

## 背景资源边界

已确认支持：

- 静态图片背景
- 循环视频背景

未确认前不要随意扩展：

- 带音频的剧情视频
- 复杂脚本化镜头
- 需要精确同步任务动作的多媒体序列
