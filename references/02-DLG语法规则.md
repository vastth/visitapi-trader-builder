# 02 DLG语法规则

## 头部

常见头部：

```dlg
trader: 579dc571d53a0658a154fbec "Fence"
start: root
first: first_meeting
quest proof = 69f1ce000000000000000001
trigger: raid bigmap (310.1499, -1.9962151, -175.2366) dist 3 radius 1.2 repeat "Talk to Fence"
```

规则：

- `.dlg` 文件名必须等于 trader id
- `trader:` 的 id 必须与文件名一致
- `start:` 是常规入口
- `first:` 是首次见面入口
- `quest 别名 = questId` 用于 `accept:` / `handover:` / `complete:`

## 节点与选项

```dlg
<root> bg: FenceBackGround.png
You made it this far. / 你能走到这里。
- Show me the work. / 给我活。 -> work
- I'm leaving. / 我走了。 -> @close
```

规则：

- `<node>` 定义节点
- 节点名只能跳到已存在节点或特殊目标
- 一条普通台词可直接中英并排写
- 想双语就自己在正文里中英并排写；VisitAPI 不会自动翻译正文

## 特殊跳转

- `@close`
- `@tasks`
- `@trade`
- `@services`

其中：

- 主菜单里这些跳转能用
- raid 内不要把它们当主流程

更稳的写法是拆两个根节点：

- `root_out_raid`
- `root_raid`

## 任务动作

```dlg
- Fine. / 行。 -> root | accept: proof
- Here's the tag. / 狗牌在这。 -> root | handover: proof
- Pay me. / 付钱。 -> root | complete: proof
```

规则：

- `accept:` 接任务
- `handover:` 打开上交流程
- `complete:` 提交完成
- raid 内任务闭环优先用这三个动作

## 背景资源

已从 VisitAPI 文档与源码确认：

- 节点头支持 `bg: 文件名`
- 旁白行支持 `| bg: 文件名`
- 支持图片：`.png .jpg .jpeg`
- 支持循环视频：`.mp4 .webm .m4v .mov`
- 纯文件名默认从 `BepInEx/config/VisitAPI/backgrounds/` 读取

## 触发

常见 raid trigger：

```dlg
trigger: raid bigmap (310.1499, -1.9962151, -175.2366) dist 3 radius 1.2 repeat "Talk to Fence"
```

参数含义：

- `raid <map>`
- `(x, y, z)`
- `dist`
- `radius`
- `once|repeat`
- `door 宽x高[x转角]`
- `"提示文字"`

但是否“完全可靠”要看 `references/03-VisitAPI运行边界.md`。
