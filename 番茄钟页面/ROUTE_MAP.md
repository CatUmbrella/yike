# 番茄钟页面 Route Map

> 基于 `yike/番茄钟页面.md`，同步更新于 2026-06-03。

## 1. 路由总览

```text
HomePage (main.dart)
└─ IndexedStack Tab 1
   └─ PomodoroHomePage
      ├─ push -> EventInputScreen              # 主页复用添加按钮
      ├─ push -> PomodoroTimerPage
      └─ push -> PomodoroHistoryPage
          └─ dialog -> HistorySessionDialog

EventDetailScreen
└─ push -> PomodoroTimerPage

PomodoroTimerPage
├─ dialog -> InterruptionInputDialog
├─ dialog -> IdeaInputDialog
├─ dialog -> EndFocusConfirmDialog
└─ dialog -> IdeaToInboxCardDialog[]          # 结束后按想法顺序逐张弹出
```

## 2. 当前入口

| 入口 | 当前状态 | 目标 |
|---|---|---|
| 底部导航“番茄钟” | `HomePage` 中 `const PomodoroPage()` | 替换为 `PomodoroHomePage` |
| 事件详情页底部按钮 | 只弹出“番茄钟功能即将上线” | push `PomodoroTimerPage(eventId)` |
| 番茄钟主页添加按钮 | 尚未实现 | 复用主页添加按钮交互，push `EventInputScreen` |

## 3. 路由定义建议

不强制使用命名路由。MVP 可以继续使用 `Navigator.push` + `MaterialPageRoute`，降低改动量。

### PomodoroHomePage

```dart
const PomodoroHomePage()
```

位置：

- `HomePage` 的 `IndexedStack` 第 2 个页面

返回：

- Tab 页面，不返回值

### EventInputScreen

入口：

- 番茄钟主页复用的添加按钮

返回：

- `bool changed`

返回处理：

```text
if changed == true:
  PomodoroHomeController.load()
```

### PomodoroTimerPage

```dart
PomodoroTimerPage(
  eventId: int,
  source: PomodoroStartSource,
)
```

参数：

| 参数 | 类型 | 说明 |
|---|---|---|
| `eventId` | `int` | 必填，当前要专注的事件 |
| `source` | `PomodoroStartSource` | `home` 或 `eventDetail`，用于返回策略和刷新来源 |
| `sessionId` | `int?` | 可选，用于恢复未完成 session |

返回：

```dart
PomodoroSessionResult(
  changed: bool,
  eventCompleted: bool,
  ideasCreated: int,
)
```

MVP 可以先返回 `bool changed`。

### PomodoroHistoryPage

```dart
const PomodoroHistoryPage()
```

入口：

- 主页历史记录组件右上角“查看全部>”

返回：

- 不返回值

内部交互：

```text
PomodoroHistoryPage
  -> 选择年月
  -> 刷新当前月份历史记录
  -> 输入名称/日期关键词
  -> 过滤当前历史记录列表
  -> 点击历史事件卡片
  -> show HistorySessionDialog
```

## 4. 弹窗路由

### InterruptionInputDialog

触发：

- 计时页打断板块左侧竖排“+打断”

输入：

- `sessionId`
- `elapsedSeconds`

输出：

- `InterruptionDraft?`

MVP：

- 可以只弹占位符
- controller 接口保留 `addInterruption(reason)`

### IdeaInputDialog

触发：

- 计时页想法板块左侧竖排“+想法”

输入：

- `sessionId`
- `elapsedSeconds`

输出：

- `IdeaDraft?`

MVP：

- 可以只弹占位符
- controller 接口保留 `addIdea(content)`

### EndFocusConfirmDialog

触发：

- 计时页点击“结束专注”

输出：

- `confirmEnd: bool`

确认后流程：

```text
pause timer
show EndFocusConfirmDialog
if cancel -> resume previous state
if confirm -> finish session -> show IdeaToInboxCardDialog[] if there are ideas
```

### IdeaToInboxCardDialog

触发：

- session 结束后，如果存在未加入事件箱的想法，按产生顺序逐条弹出

输入：

- `ideaId`
- `ideaContent`
- `orderIndex`

展示与编辑：

- 序号
- 以想法内容作为默认标题
- 可修改目的
- 可添加、编辑步骤
- 可编辑步骤预计耗时
- 底部选择是否加入事件箱

输出：

- `IdeaToInboxDecision`
- 选择加入时创建 inbox 事件，并回写 idea 的 `added_to_inbox / inbox_event_id`
- 选择跳过时只记录该 idea 已处理或保持未加入状态，避免反复弹出由 controller 决定

流程：

```text
for idea in session.ideas where added_to_inbox == false:
  show IdeaToInboxCardDialog(idea)
  if shouldAdd:
    create inbox event from edited draft
after all ideas handled:
  pop PomodoroTimerPage with changed=true
```

### HistorySessionDialog

触发：

- 历史记录详细页点击某条历史记录

展示：

- 事件 summary/title
- 完成/未完成状态
- 预计耗时
- 事件目的
- 事件步骤和每一步预计耗时
- 实际专注时长
- 番茄数量
- 打断数量、具体打断原因和时间
- 想法数量、具体想法和时间
- 底部黑色关闭按钮

编辑：

- 目的有内容时显示并允许编辑
- 步骤文本允许编辑
- 步骤预计耗时允许编辑
- 打断和想法不支持编辑

保存：

- 产生编辑时写回事件/步骤
- 后台记录首次内容、最后一次内容、最后修改时间

## 5. 主流程

### 从番茄钟主页开始

```text
进入 PomodoroHomePage
  -> load recent sessions
  -> load candidate events
  -> 用户勾选事件
  -> 事件胶囊变深蓝
  -> 开始番茄钟组件变蓝并显示选中事件标题
  -> 点击开始
  -> push PomodoroTimerPage(eventId, source: home)
  -> 创建或恢复 session
  -> 开始/继续计时
```

### 从番茄钟主页添加事件

```text
PomodoroHomePage
  -> 点击可拖拽添加按钮
  -> push EventInputScreen
  -> pop changed=true
  -> PomodoroHomeController.load()
```

### 从事件详情页开始

```text
进入 EventDetailScreen
  -> 点击底部“进入番茄钟”
  -> 如果 event.id != null
  -> push PomodoroTimerPage(eventId, source: eventDetail)
  -> 创建或恢复 session
  -> 开始/继续计时
  -> 返回详情页时，如果事件完成或步骤更新，详情页刷新
```

### 计时页记录打断/想法

```text
PomodoroTimerPage
  -> 点击 +打断 / +想法
  -> 弹出占位输入弹窗
  -> 保存记录内容、created_at、elapsed_sec
  -> 右侧滚动内容区域追加记录
```

### 计时页完成步骤

```text
PomodoroTimerPage
  -> 点击步骤 checkbox
  -> 记录 completed_at、elapsed_sec、duration_sec
  -> 文本划线并变灰
  -> 如果 5 秒内连续完成多个步骤：不记录 duration_sec
  -> 如果跳步勾选完成：不记录 duration_sec
  -> 如果全部步骤完成：event.status = completed，写 completed_at
```

### 结束专注

```text
PomodoroTimerPage
  -> 点击“结束专注”
  -> EndFocusConfirmDialog
  -> finish session
  -> 写入 duration_sec/end_time/status
  -> 如果所有步骤已完成：写 event.status=completed / completed_at / actual duration
  -> 如果有想法：按顺序弹出 IdeaToInboxCardDialog
  -> 全部想法处理完毕
  -> pop with changed=true
```

### 查看历史记录

```text
PomodoroHomePage
  -> 点击“查看全部>”
  -> push PomodoroHistoryPage
  -> 默认加载本月历史记录
  -> 按今天 / 昨天 / x日 分组
  -> 点击历史事件卡片
  -> show HistorySessionDialog
  -> 如编辑目的或步骤：保存事件变更和编辑记录
```

## 6. 返回策略

| 页面 | 返回行为 |
|---|---|
| PomodoroHomePage | Tab 页面，无返回 |
| PomodoroTimerPage 正在计时 | 允许返回，未完成 session 保留，并按真实时间继续累计 |
| PomodoroTimerPage 已暂停 | 允许返回，未完成 session 保留 |
| PomodoroHistoryPage | 普通 pop |
| 弹窗 | 点击取消或蒙层按具体弹窗规则 |

## 7. 已确认规则

- 单个番茄固定为 25 分钟。
- 未完成 session 允许保留，且从计时页返回后仍按真实时间继续累计。
- 事件完成规则为所有步骤全部勾选完成。
- 步骤耗时记录阈值为 5 秒；5 秒内连续完成多个步骤或跳步勾选完成时，不记录步骤耗时。
- 想法加入事件箱时默认只创建 `title/summary` 基础事件，不自动生成步骤；用户在卡片里手动添加的目的、步骤和预计耗时需要写入。
- 历史详情弹窗编辑目的、步骤、步骤预计耗时后，同步原事件数据。
