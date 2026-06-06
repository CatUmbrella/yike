# 番茄钟页面 Project Map

> 基于 `yike/番茄钟页面.md`，同步更新于 2026-06-03。
> 本文只描述番茄钟模块架构，不包含具体实现代码。

## 1. 模块范围

番茄钟模块包含：

- 1 个主页面：番茄钟主页
- 2 个子页面：番茄钟计时页面、历史记录详细页
- 5 个弹窗/浮层：记录打断、记录想法、结束专注确认、想法加入事件箱确认、历史记录卡片弹窗

## 2. 当前代码位置

当前项目中番茄钟仍是占位页：

| 文件 | 当前职责 | 状态 |
|---|---|---|
| `frontend/lib/screens/pomodoro_page.dart` | `PomodoroPage` 占位页面 | 待重构 |
| `frontend/lib/main.dart` | 底部导航第 2 个 Tab 挂载 `PomodoroPage` | 可复用 |
| `frontend/lib/screens/event_detail/widgets/event_detail_pomodoro.dart` | 详情页底部番茄钟入口，目前只弹 SnackBar | 待接路由 |

## 3. 建议目录结构

建议将当前 `frontend/lib/screens/pomodoro_page.dart` 改为薄导出层，具体代码放入 `frontend/lib/screens/pomodoro/`。

```text
frontend/lib/screens/
├─ pomodoro_page.dart                         # 薄导出层，export pomodoro/pomodoro_home_page.dart
└─ pomodoro/
   ├─ pomodoro_home_page.dart                 # 番茄钟主页
   ├─ pomodoro_timer_page.dart                # 番茄钟计时页面
   ├─ pomodoro_history_page.dart              # 历史记录详细页
   │
   ├─ pomodoro_home_controller.dart           # 主页状态：历史预览、事件箱、选中事件
   ├─ pomodoro_timer_controller.dart          # 计时状态：running/paused、打断、想法、步骤完成
   ├─ pomodoro_history_controller.dart        # 历史页列表加载
   │
   ├─ pomodoro_models.dart                    # 前端展示模型/DTO
   ├─ pomodoro_repository.dart                # 本地 DB 访问边界
   ├─ pomodoro_constants.dart                 # 25min 番茄时长、状态常量、布局常量
   ├─ pomodoro_style.dart                     # 番茄钟模块设计 Token
   │
   ├─ widgets/
   │  ├─ pomodoro_history_preview.dart        # 主页顶部历史记录组件
   │  ├─ pomodoro_history_item.dart           # 历史记录条目
   │  ├─ pomodoro_event_box.dart              # 主页中间事件箱组件
   │  ├─ pomodoro_event_card.dart             # 带可交互复选框的事件胶囊
   │  ├─ pomodoro_start_panel.dart            # 主页底部开始番茄钟组件
   │  ├─ pomodoro_home_add_button.dart        # 主页复用的可拖拽添加按钮
   │  ├─ pomodoro_timer_display.dart          # 计时器 00:00:00 + 状态文字
   │  ├─ pomodoro_lane_panel.dart             # 左侧竖排标签 + 分割线 + 右侧滚动内容通用板块
   │  ├─ pomodoro_record_chip.dart            # 打断/想法内容胶囊
   │  ├─ pomodoro_step_chip.dart              # 步骤内容胶囊
   │  ├─ pomodoro_timer_controls.dart         # 暂停/继续/结束入口
   │  └─ tomato_icon.dart                     # 自定义番茄图标，支持简化填充动画
   │
   └─ dialogs/
      ├─ interruption_input_dialog.dart       # 记录打断
      ├─ idea_input_dialog.dart               # 记录想法
      ├─ end_focus_confirm_dialog.dart        # 结束专注确认
      ├─ idea_to_inbox_card_dialog.dart       # 单条想法加入事件箱卡片
      └─ history_session_dialog.dart          # 历史记录卡片弹窗
```

## 4. 页面职责

### PomodoroHomePage

入口：底部导航“番茄钟”Tab。

职责：

- 展示最近番茄钟历史记录 2-3 条
- 根据 `completed_at` 是否为空展示历史记录“已完成/未完成”
- 展示可选择的事件箱
- 管理当前选中的事件
- 控制“开始番茄钟”组件的 disabled/enabled 状态和内容
- 提供与安排主页一致的添加按钮交互
- 跳转到计时页和历史记录详细页

不负责：

- 不直接写 session 数据
- 不处理计时器 tick
- 不复用安排页“点击空白进入录入页”的逻辑
- 不复用四象限上色逻辑

### PomodoroTimerPage

入口：

- 番茄钟主页点击“开始番茄钟”
- 事件详情页点击“进入番茄钟”

职责：

- 创建或恢复一个番茄钟 session
- 显示计时器和 running/paused 状态
- 记录打断、想法
- 记录步骤完成时间和耗时
- 支持步骤内容编辑并同步到事件
- 5 秒内连续完成多个步骤时不记录步骤耗时，只记录完成状态/完成时间
- 跳步勾选完成步骤时不记录该步骤耗时
- 结束专注并按顺序触发想法加入事件箱卡片
- 所有步骤完成后才将事件标记为 `completed`

### PomodoroHistoryPage

入口：主页历史记录组件右上角“查看全部>”。

职责：

- 展示完整番茄钟历史记录
- 默认展示本月使用过番茄钟的事件
- 按“今天 / 昨天 / 之前日期（仅 x 日）”分组展示
- 顶部提供年月选择入口
- 支持后续扩展名称/日期检索
- 点击记录展示历史卡片弹窗
- 历史弹窗内允许编辑目的、步骤文本、步骤预计耗时
- 对历史弹窗产生的编辑记录首次内容、最后一次内容和最后修改时间

## 5. Controller 职责边界

### PomodoroHomeController

状态：

- `recentSessions`
- `candidateEvents`
- `selectedEventId`
- `loading/error`

动作：

- `load()`
- `selectEvent(eventId)`
- `clearSelection()`
- `openInputPage()`
- `canStart`

### PomodoroTimerController

状态：

- `session`
- `event`
- `elapsedSeconds`
- `timerStatus`
- `interruptions`
- `ideas`
- `stepRecords`
- `activeEditingStep`

动作：

- `start(eventId)`
- `pause()`
- `resume()`
- `requestEnd()`
- `finish()`
- `addInterruption(reason)`
- `resolveInterruption(id)`
- `addIdea(content)`
- `completeStep(stepOrder)`
- `shouldRecordStepDuration(stepOrder)`
- `updateStepDescription(stepOrder, value)`
- `syncEventCompletionIfAllStepsDone()`
- `showIdeasToInboxCards()`
- `createInboxEventFromIdea(draft)`

### PomodoroHistoryController

状态：

- `sessions`
- `selectedMonth`
- `searchQuery`
- `loading/error`

动作：

- `loadAll()`
- `selectMonth(year, month)`
- `updateSearchQuery(value)`
- `openSessionDialog(sessionId)`
- `saveHistoryEventEdit(edit)`

## 6. 数据访问边界

建议新增 `PomodoroRepository`，不要让页面直接调用 `LocalDatabase`。

`PomodoroRepository` 负责：

- 查询主页历史预览
- 查询历史记录完整列表
- 查询番茄钟可选事件
- 创建/恢复/更新 session
- 页面退出后按真实时间恢复未完成 session 的累计时长
- 写入打断/想法/步骤完成记录
- 同步步骤文本修改
- 同步历史弹窗中对目的、步骤、步骤预计耗时的编辑
- 记录历史弹窗编辑的首次内容、最后一次内容、最后修改时间
- 结束 session 时写入实际用时
- 所有步骤完成时同步 event 状态和 completed_at
- 将用户选择加入事件箱的想法创建为基础事件；默认只填 `title/summary`，不自动生成步骤，并回写 idea 的加入状态

这样后续如果从本地 sqflite 切到后端同步，只需要替换 repository。

## 7. 复用关系

可复用：

- `Event` / `StepItem`
- `shared/event_formatters.dart`
- `shared/event_schedule.dart` 中的日期工具
- 安排页添加按钮的交互逻辑
- `ArrangeStyle` 的部分颜色可以作为临时基础，但番茄钟模块建议独立 `PomodoroStyle`
- 自定义番茄图标素材已存在，优先按透明背景 PNG/WebP 接入；如果素材带背景，先作为 UI 资源处理，不影响数据模型。

谨慎复用：

- 安排页事件箱视觉参数可以参考，但不直接复用 `EventBox`
- 安排页 `EventCard` 不建议直接复用，因为番茄钟事件箱需要 checkbox、深蓝选中态、浅蓝默认态，且不接四象限颜色

## 8. 架构风险

### 高

- 前端本地 DB 当前没有番茄钟相关表，但后端已有 `PomodoroSession / Interruption / Idea` ORM。需要补齐前端本地表，否则真机离线数据无法保存。
- `StepItem` 前端模型没有 `id` 字段。步骤完成记录如果要精准关联，需要新增 step id，或用 `event_id + step_order + description_snapshot` 作为 MVP 方案。

### 中

- “实际用时”字段还不存在于 `Event` 前端模型。PRD 要求完成后总用时改为实际用时，建议新增 `actual_minutes`，不要覆盖预计耗时。
- 打断/想法的弹窗目前是占位，但数据模型应提前支持真实写入，避免后续返工。
- 未完成 session 允许保留并继续计时，需要 controller 能在页面切换后维持或恢复计时状态。
- 从计时页返回后未完成 session 需要按真实时间继续累计，而不是只在页面打开时 tick。
- 历史弹窗允许编辑事件内容，需要避免和事件详情页、事件录入页的编辑逻辑分叉；建议通过 repository 暴露统一保存入口。

### 低

- 历史记录详细页包含分组、年月选择、弹窗详情和编辑记录，建议从一开始拆成 page + list item + filter header + dialog。
