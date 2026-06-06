# 番茄钟页面 Data Model

> 基于 `yike/番茄钟页面.md`，同步更新于 2026-06-03。

## 1. 现有模型可复用字段

### Event

当前前端 `Event` 模型已有：

| 字段 | 用途 |
|---|---|
| `id` | 番茄钟 session 关联事件 |
| `title` | 事件完整标题 |
| `summary` | 历史记录、事件箱卡片优先展示 |
| `purpose` | 历史记录弹窗/详情展示 |
| `status` | `inbox / arranged / completed` |
| `steps` | 计时页步骤列表 |
| `totalMinutes` | 未完成时展示预计耗时 |
| `completedAt` | 历史记录完成时间；为空时显示未完成 |
| `actualMinutes` | 番茄钟完成后的实际用时，建议新增 |

当前前端 DB 表 `events` 还有 `updated_at`，但 `Event` Dart 模型没有暴露该字段。番茄钟历史预览中的未完成记录优先使用 `pomodoro_sessions.updated_at` 作为“最近活动时间”，因为它是使用过番茄钟的 session 级时间；无需为了该场景强行把 `events.updated_at` 加入完整 `Event` 模型。

### StepItem

当前字段：

| 字段 | 用途 |
|---|---|
| `stepOrder` | 步骤序号 |
| `description` | 步骤文案，计时页可编辑并同步 |
| `estimatedMin` | 步骤预计用时 |

限制：

- Dart `StepItem` 没有 `id`
- 前端 `steps` 表有 `id`，但未映射到模型
- 如果需要精确记录某一步完成历史，建议补充 `StepItem.id`，或在番茄钟步骤记录里保存 `step_order + description_snapshot`

## 2. 现有后端模型

后端 `backend/models.py` 已有：

- `PomodoroSession`
- `Interruption`
- `Idea`

但前端本地 sqflite 目前没有对应表。真机前端测试和离线使用需要先补本地表。

## 3. 建议新增前端模型

### PomodoroSession

```dart
class PomodoroSession {
  int? id;
  int eventId;
  String startTime;
  String? endTime;
  String status; // running / paused / completed / canceled
  int durationSec;
  int? plannedMinutesSnapshot;
  int tomatoCount;
  String createdAt;
  String updatedAt;
}
```

字段说明：

| 字段 | 说明 |
|---|---|
| `eventId` | 关联事件 |
| `startTime` | 开始专注时间 |
| `endTime` | 结束时间 |
| `status` | session 状态 |
| `durationSec` | 实际专注时长；未完成 session 可继续累加 |
| `plannedMinutesSnapshot` | 开始时的预计耗时快照，避免事件后续修改影响历史 |
| `tomatoCount` | 实际生成的番茄数量 |
| `updatedAt` | 未完成 session 的历史展示时间；按真实时间继续计时时需要持续更新或在恢复时补算 |

计时恢复规则：

- 正在计时的未完成 session 从计时页返回后仍按真实时间继续累计。
- 页面重新进入时，根据 `startTime / updatedAt / durationSec / status` 恢复显示，不依赖页面常驻 tick 才增加时长。
- 暂停状态不继续累计，只保留当前 `durationSec`。

番茄数量规则：

```text
tomatoDurationSec = 25 * 60
tomatoCount = durationSec ~/ tomatoDurationSec
```

### PomodoroInterruption

```dart
class PomodoroInterruption {
  int? id;
  int sessionId;
  String reason;
  int elapsedSec;
  String createdAt;
  bool resolved;
  String? resolvedAt;
}
```

字段说明：

| 字段 | 说明 |
|---|---|
| `reason` | 打断缘由 |
| `elapsedSec` | 番茄钟进行到第几秒记录 |
| `createdAt` | 实际记录时间，用于右侧内容显示 |
| `resolved` | 是否已解决 |
| `resolvedAt` | 解决时间 |

### PomodoroIdea

```dart
class PomodoroIdea {
  int? id;
  int sessionId;
  String content;
  int elapsedSec;
  String createdAt;
  bool addedToInbox;
  int? inboxEventId;
}
```

字段说明：

| 字段 | 说明 |
|---|---|
| `content` | 想法内容 |
| `elapsedSec` | 番茄钟进行到第几秒记录 |
| `createdAt` | 实际记录时间 |
| `addedToInbox` | 是否已加入事件箱 |
| `inboxEventId` | 加入事件箱后创建的事件 id |

### IdeaToInboxDraft

用于结束专注后的单条想法入箱卡片，不直接持久化，保存时转换为 `Event` 和 `StepItem`。

```dart
class IdeaToInboxDraft {
  int ideaId;
  int orderIndex;
  String title;
  String purpose;
  List<StepItem> steps;
  bool shouldAddToInbox;
}
```

规则：

- `title` 默认使用想法内容。
- `purpose` 可修改。
- `steps` 默认为空，不根据想法内容自动生成。
- 用户可以手动添加、编辑步骤，预计耗时沿用事件录入页的时间编辑逻辑。
- `shouldAddToInbox == true` 时创建 `status = inbox` 的事件，并回写 `PomodoroIdea.addedToInbox / inboxEventId`。
- 创建事件的默认字段只填 `title/summary`；如果用户在卡片中填写了目的、步骤、预计耗时，再一并写入。

### PomodoroStepRecord

```dart
class PomodoroStepRecord {
  int? id;
  int sessionId;
  int eventId;
  int stepOrder;
  String descriptionSnapshot;
  int estimatedMinSnapshot;
  String completedAt;
  int elapsedSec;
  int? durationSec;
}
```

用途：

- 记录步骤完成的具体时间
- 记录步骤完成时番茄钟已经进行了多久
- 记录该步骤实际耗时
- 5 秒内连续完成多个步骤时，`durationSec` 置空，不进行计时
- 跳步勾选完成步骤时，`durationSec` 置空，不进行计时

为什么保存快照：

- 事件步骤后续可能被编辑
- 仅靠 `stepOrder` 容易和历史记录不一致

### PomodoroEventEditLog

用于历史记录大卡片中编辑目的、步骤文本、步骤预计耗时时的审计记录。

```dart
class PomodoroEventEditLog {
  int? id;
  int eventId;
  int? sessionId;
  String targetType; // purpose / step_description / step_estimated_min
  int? stepOrder;
  String firstValue;
  String latestValue;
  String firstEditedAt;
  String lastEditedAt;
}
```

记录规则：

- 同一个 `eventId + sessionId + targetType + stepOrder` 只保留一条记录。
- 第一次编辑时写入 `firstValue / firstEditedAt`。
- 后续多次编辑只覆盖 `latestValue / lastEditedAt`。
- 打断和想法不支持编辑，因此不进入该表。

### TomatoIconAsset

自定义番茄图标属于 UI 资源，不需要 DB 表。

建议资产路径：

```text
frontend/assets/images/tomato_icon.png
```

素材要求：

- 优先透明背景 PNG 或 WebP。
- 建议正方形资源，512x512 或 1024x1024 都可。
- 如果素材已有背景，可以先作为静态 UI 资源接入，后续再按视觉效果裁切或去背景。

填充动画可以由 UI 组件根据当前番茄进度绘制，不进入数据模型。

## 4. 本地 SQLite 表建议

建议前端 DB 从 version 5 升到 version 6。

### events 新增字段

```sql
ALTER TABLE events ADD COLUMN actual_minutes INTEGER;
ALTER TABLE events ADD COLUMN tomato_count INTEGER NOT NULL DEFAULT 0;
```

用途：

- 事件未完成：展示预计耗时 `total_minutes / steps estimated`
- 事件通过番茄钟完成后：展示实际用时 `actual_minutes`
- 步骤仍保留预计用时
- `tomato_count` 缓存该事件累计获得的番茄数量，单个 session 按满 25 分钟向下取整累计

### pomodoro_sessions

```sql
CREATE TABLE pomodoro_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id INTEGER NOT NULL,
  start_time TEXT,
  end_time TEXT,
  status TEXT NOT NULL DEFAULT 'running',
  duration_sec INTEGER NOT NULL DEFAULT 0,
  planned_minutes_snapshot INTEGER,
  tomato_count INTEGER NOT NULL DEFAULT 0,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (event_id) REFERENCES events(id)
)
```

### pomodoro_interruptions

```sql
CREATE TABLE pomodoro_interruptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  reason TEXT DEFAULT '',
  elapsed_sec INTEGER NOT NULL DEFAULT 0,
  created_at TEXT,
  resolved INTEGER NOT NULL DEFAULT 0,
  resolved_at TEXT,
  FOREIGN KEY (session_id) REFERENCES pomodoro_sessions(id)
)
```

### pomodoro_ideas

```sql
CREATE TABLE pomodoro_ideas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  content TEXT DEFAULT '',
  elapsed_sec INTEGER NOT NULL DEFAULT 0,
  created_at TEXT,
  added_to_inbox INTEGER NOT NULL DEFAULT 0,
  inbox_event_id INTEGER,
  FOREIGN KEY (session_id) REFERENCES pomodoro_sessions(id)
)
```

### pomodoro_step_records

```sql
CREATE TABLE pomodoro_step_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  event_id INTEGER NOT NULL,
  step_order INTEGER NOT NULL,
  description_snapshot TEXT DEFAULT '',
  estimated_min_snapshot INTEGER DEFAULT 0,
  completed_at TEXT,
  elapsed_sec INTEGER NOT NULL DEFAULT 0,
  duration_sec INTEGER,
  FOREIGN KEY (session_id) REFERENCES pomodoro_sessions(id),
  FOREIGN KEY (event_id) REFERENCES events(id)
)
```

### pomodoro_event_edit_logs

```sql
CREATE TABLE pomodoro_event_edit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id INTEGER NOT NULL,
  session_id INTEGER,
  target_type TEXT NOT NULL,
  step_order INTEGER,
  first_value TEXT DEFAULT '',
  latest_value TEXT DEFAULT '',
  first_edited_at TEXT,
  last_edited_at TEXT,
  UNIQUE(event_id, session_id, target_type, step_order),
  FOREIGN KEY (event_id) REFERENCES events(id),
  FOREIGN KEY (session_id) REFERENCES pomodoro_sessions(id)
)
```

## 5. Event 实际用时适配

前端模型建议：

```dart
int? actualMinutes;

int get displayTotalMinutes =>
  status == 'completed' && actualMinutes != null
    ? actualMinutes!
    : totalMinutes;
```

不建议直接覆盖 `total_minutes`：

- `total_minutes` 当前代表手动调整或 AI 返回的预计总耗时
- 覆盖后会丢失原预计耗时
- 详情页和历史页可能同时需要“预计”和“实际”

## 6. 查询模型

### 主页历史预览

返回最近 2-3 条：

```dart
class PomodoroHistoryPreviewItem {
  int sessionId;
  int eventId;
  String title;
  String displayTime;
  int tomatoCount;
  bool eventCompleted;
}
```

字段规则：

```text
title = event.summary -> event.title -> '(无标题)'
eventCompleted = event.completed_at != null && event.completed_at.isNotEmpty
displayTime = eventCompleted ? event.completed_at : session.updated_at
```

番茄显示：

```text
tomatoCount <= 3: 显示最多三个自定义番茄图标
tomatoCount > 3: 显示 “番茄×N”
```

### 历史记录详细页列表

默认查询本月所有使用过番茄钟的事件，按日期分组。

```dart
class PomodoroHistorySection {
  String title; // 今天 / 昨天 / x日
  List<PomodoroHistoryListItem> items;
}

class PomodoroHistoryListItem {
  int sessionId;
  int eventId;
  String title;
  bool completed;
  String displayDateTime;
  int interruptionCount;
  int ideaCount;
  int tomatoCount;
}
```

列表规则：

```text
默认月份 = 当前月份
分组顺序 = 今天 -> 昨天 -> 之前日期倒序
之前日期标题 = x日，不写月份
title = event.summary -> event.title -> '(无标题)'
completed = event.completed_at != null && event.completed_at.isNotEmpty
```

名称/日期检索可以作为 repository projection 上的过滤参数：

```dart
class PomodoroHistoryQuery {
  int year;
  int month;
  String keyword;
}
```

### 历史记录详情弹窗

```dart
class PomodoroHistoryDetail {
  Event event;
  PomodoroSession session;
  List<StepItem> editableSteps;
  List<PomodoroInterruption> interruptions;
  List<PomodoroIdea> ideas;
  List<PomodoroEventEditLog> editLogs;
}
```

展示规则：

- 标题区显示事件标题、完成状态、预计耗时。
- 目的有内容时显示，并允许编辑。
- 步骤和每一步预计耗时允许编辑。
- 完成后显示实际用时和番茄个数。
- 打断和想法只读，展示内容和时间。

### 主页事件箱

候选事件：

- `status != completed`
- `deleted_at IS NULL`
- 不使用四象限颜色
- 默认胶囊颜色为浅蓝色
- 选中后胶囊背景变深蓝色

排序策略：

```text
1. 优先显示点击加号新建的时间胶囊
2. 再显示今天的事件，从早到晚
3. 剩余事件按照创建时间降序
```

```dart
class PomodoroSelectableEvent {
  Event event;
  bool selected;
}
```

### 计时页任务快照

```dart
class PomodoroTaskSnapshot {
  Event event;
  PomodoroSession session;
  List<PomodoroInterruption> interruptions;
  List<PomodoroIdea> ideas;
  List<PomodoroStepRecord> stepRecords;
}
```

## 7. 状态枚举

```dart
enum PomodoroTimerStatus {
  idle,
  running,
  paused,
  finishing,
  completed,
}
```

DB 中建议使用字符串：

- `running`
- `paused`
- `completed`
- `canceled`

## 8. 已确认规则

- 单个番茄固定为 25 分钟。
- 未完成 session 允许恢复继续。
- 从计时页返回后，未完成 session 按真实时间继续计时。（从计时页退出之后，未完成 session 一直保持计时）
- 事件只有在所有步骤都勾选完成后才标记为 `completed`。
- 结束专注但步骤未全部完成时，不标记事件为 `completed`。
- 5 秒内连续完成多个步骤或跳步勾选完成时，不记录步骤耗时。
- 想法加入事件箱时按顺序逐条弹出卡片，默认只用想法内容创建 `title/summary` 基础事件；不自动生成步骤。
- 历史详情弹窗中的目的、步骤、步骤预计耗时可编辑，编辑记录保留首次内容和最后一次内容。
- 历史详情弹窗中的编辑同步原事件数据。
