# AGENTS.md

## 项目说明

`yike` 是主项目目录。

本项目是一个 Flutter 时间管理 / 日程安排原型，核心能力包括：
- 事件箱与事件录入
- AI 拆解事件
- 周日历安排
- 本地 SQLite 持久化
- FastAPI 后端，当前主要用于 AI 拆解，后续预留登录和用户同步能力

## 技术栈

前端：
- Flutter / Dart
- `sqflite` 本地 SQLite
- `http` 网络请求

后端：
- Python
- FastAPI
- SQLAlchemy
- SQLite
- `backend/services/ai_parser.py` 通过 OpenAI 兼容接口调用 DeepSeek

## 项目架构

### 前端入口

- `frontend/lib/main.dart`
  - Flutter 应用入口。
  - 当前底部导航包含：安排、番茄钟、模板、数据。

### 页面导出层

- `frontend/lib/screens/arrange_page.dart`
  - 只负责导出真正的安排页实现。
  - 保留这个薄导出层，避免外部引用路径频繁变化。

- `frontend/lib/screens/event_input.dart`
  - 只负责导出真正的事件箱与录入页实现。
  - 外部页面进入事件录入页时优先引用这个文件。

### 安排页模块

目录：`frontend/lib/screens/arrange/`

- `arrange_page.dart`
  - 安排页主页面。
  - 负责页面状态、数据加载、页面跳转、事件完成 / 恢复、拖入日历后的保存逻辑。

- `arrange_constants.dart`
  - tab、星期、时间段、页面初始页码、UI 尺寸常量。

- `arrange_helpers.dart`
  - 日期格式化、事件排序、耗时文本等纯函数。

- `widgets/`
  - 安排页 UI 组件和与 UI 强绑定的交互动画。
  - 业务保存逻辑不要下沉到这里。

### 事件箱与录入模块

目录：`frontend/lib/screens/event_input/`

- `event_input_page.dart`
  - 事件箱与录入页主页面。
  - 负责页面生命周期、导航、SnackBar、用户动作入口。

- `event_input_controller.dart`
  - 页面状态控制器。
  - 负责加载本地事件、AI 拆解、自定义事件创建、草稿编辑、软删除等行为。

- `event_input_state.dart`
  - 页面状态模型。
  - 只放状态字段和状态复制逻辑。

- `event_draft.dart`
  - 事件草稿模型。
  - 用于区分本地事件、AI 建议、用户编辑状态和展示耗时。

- `event_input_style.dart`
  - 页面设计 token 和响应式尺寸。
  - 小屏 / 中屏 / 大屏适配优先在这里集中处理，不要把断点散落到各个 widget。

- `widgets/`
  - 页面 UI 组件。
  - `editable_event_detail_card.dart`：事件详情卡片编辑区。
  - `event_step_editor.dart`：步骤行编辑，包含步骤文本、逐行耗时位置计算。
  - `measured_underline_text_field.dart`：可复用的“文本换行后逐行跟随横线”输入组件。
  - `event_detail_pager.dart`、`input_text_box.dart`、`event_input_actions.dart`、`event_duration_editor.dart`：页面局部 UI。

#### 逐行横线输入组件约定

`MeasuredUnderlineTextField` 的基本思路是：
- `TextField` 负责真实输入、光标、选择、键盘和换行。
- `CustomPainter` 使用 `TextPainter` 按相同样式重新测量文本。
- 通过 `computeLineMetrics()` 获取每一行宽度和基线。
- 按行绘制横线，横线宽度为文本宽度加 `underlineExtension`，并限制在输入框可用宽度内。

修改该组件时注意：
- TextField 和 TextPainter 必须使用同一套有效 `TextStyle`。
- 行高和下划线位置要集中用参数控制，避免在调用处写魔法数字。
- 如果右侧存在步骤耗时，耗时避让逻辑在 `event_step_editor.dart` 中处理，横线延长量需要纳入避让判断。

### 通用模块

- `frontend/lib/models/event.dart`
  - 事件和步骤数据模型。

- `frontend/lib/services/database.dart`
  - 本地 SQLite 访问层。
  - 软删除、恢复、本地事件读写都优先走这里。

- `frontend/lib/services/api.dart`
  - 前端访问后端 API 的封装。

### 后端模块

- `backend/main.py`
  - FastAPI 入口。

- `backend/models.py`
  - SQLAlchemy 数据模型。

- `backend/database.py`
  - 后端数据库连接。

- `backend/routers/events.py`
  - 事件相关 API。

- `backend/services/ai_parser.py`
  - AI 拆解服务。

## 开发约定

- 禁止批量删除文件或目录。
- 不要使用 `del /s`、`rd /s`、`rmidr /s`、`Remove-Item -Recurse`、`rm -rf`。
- 需要删除文件时，只能一次删除一个明确路径的文件，例如 `Remove-Item "C:\path\to\file.txt"`。
- 如果需要批量删除文件，应停止操作，并请用户手动删除。

- 代码保持简洁、易读。优先使用小组件、清晰回调和局部状态，不要过度设计。
- 暂时不要引入 Provider、Bloc、Riverpod 等状态管理，除非后续复杂度确实需要。
- 页面文件负责页面生命周期、导航和业务动作入口。
- 控制器负责状态变更和业务流程。
- `widgets/` 只放 UI 和 UI 强相关动画，不放持久化逻辑。
- 避免在页面文件里写大段嵌套 Widget，难读时及时拆分。
- 不要删除后端 CRUD，后续登录和同步能力可能会用到。
- 保留软删除逻辑。

## 业务规则备忘

- `calendar_order` 只表示同一个 `scheduledDate + timeSlot` 内的显示顺序。
- 同一个日历格子内拖拽重排目前是故意关闭的。
- 事件拖入日历后设置 `status = arranged`。
- 事件箱与录入页默认展示所有未完成、未软删除事件，不按已安排 / 未安排分类。
- 事件箱和日历事件拖拽统一使用长按；点击仍然进入详情页。
- 事件整卡删除应走软删除；未保存草稿只从当前页面移除。

## UI 验证约定

- 用户当前使用模拟器做 UI 视觉确认。
- 后续默认不要用浏览器预览页面。
- 常规验证优先运行 `dart analyze` 和相关 `flutter test`。
- 如果改动依赖肉眼判断，说明已改完并提示用户在模拟器确认。

## 常用检查命令

前端全量检查：

```bash
cd frontend
D:\Develop\Flutter\bin\flutter.bat analyze
```

事件箱与录入页定向检查：

```bash
cd frontend
D:\Develop\Flutter\bin\cache\dart-sdk\bin\dart.exe analyze lib\screens\event_input.dart lib\screens\event_input test\event_input_responsive_test.dart
D:\Develop\Flutter\bin\flutter.bat test test\event_input_responsive_test.dart
```

安排页定向检查：

```bash
cd frontend
D:\Develop\Flutter\bin\cache\dart-sdk\bin\dart.exe analyze lib\screens\arrange_page.dart lib\screens\arrange
```

后端导入检查：

```bash
cd backend
venv\Scripts\python.exe -c "import database, models, routers.events; print('ok')"
```

## Git 注意事项

- 远程仓库是 `origin -> https://github.com/CatUmbrella/yike.git`。
- 做风险较大的重构前，先提交并 push 一个干净快照。
- 不要回滚无关的用户修改。当前工作区可能存在与本次任务无关的本地改动。
