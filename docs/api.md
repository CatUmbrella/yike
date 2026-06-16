# 后端接口文档

后端基于 FastAPI 构建，当前主要提供 AI 任务解析和事件基础管理接口。

本地默认地址：

```text
http://127.0.0.1:8000
```

FastAPI 交互式接口文档：

```text
http://127.0.0.1:8000/docs
```

## 鉴权说明

事件相关接口统一挂载在 `/api/events` 下。

如果后端配置了 `API_TOKEN`，请求需要携带：

```http
X-API-Key: your-api-token
```

如果未配置 `API_TOKEN`，后端会跳过接口鉴权。

通用请求头：

```http
Content-Type: application/json
X-API-Key: your-api-token
```

## 接口列表

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `GET` | `/` | 服务状态检查 |
| `POST` | `/api/events/parse` | AI 解析自然语言任务 |
| `POST` | `/api/events` | 创建事件 |
| `GET` | `/api/events` | 获取事件列表 |
| `GET` | `/api/events/{event_id}` | 获取事件详情 |
| `PUT` | `/api/events/{event_id}` | 更新事件 |
| `DELETE` | `/api/events/{event_id}` | 软删除事件 |

## 数据结构

### StepItem

事件步骤结构。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `step_order` | `int` | 步骤顺序 |
| `description` | `string` | 步骤描述 |
| `estimated_min` | `int` | 预计耗时，单位分钟 |

示例：

```json
{
  "step_order": 1,
  "description": "整理复习资料",
  "estimated_min": 20
}
```

### EventCreate

创建或更新事件时使用的请求结构。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `title` | `string` | 事件标题 |
| `summary` | `string` | 事件摘要 |
| `purpose` | `string` | 事件目的 |
| `status` | `string` | 事件状态，默认 `inbox` |
| `quadrant` | `string \| null` | 四象限分类 |
| `scheduled_date` | `string \| null` | 安排日期 |
| `time_slot` | `string \| null` | 时间段 |
| `calendar_order` | `int` | 日程排序 |
| `steps` | `StepItem[]` | 执行步骤 |

示例：

```json
{
  "title": "复习计算机网络",
  "summary": "复习计网",
  "purpose": "准备考试并整理重点",
  "status": "inbox",
  "quadrant": "important_urgent",
  "scheduled_date": "2026-06-16",
  "time_slot": "afternoon",
  "calendar_order": 0,
  "steps": [
    {
      "step_order": 1,
      "description": "复习 TCP/IP 基础概念",
      "estimated_min": 30
    },
    {
      "step_order": 2,
      "description": "整理实验报告",
      "estimated_min": 40
    }
  ]
}
```

### EventResponse

事件响应结构。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | `int` | 事件 ID |
| `title` | `string` | 事件标题 |
| `summary` | `string` | 事件摘要 |
| `purpose` | `string` | 事件目的 |
| `status` | `string` | 事件状态 |
| `quadrant` | `string \| null` | 四象限分类 |
| `scheduled_date` | `string \| null` | 安排日期 |
| `time_slot` | `string \| null` | 时间段 |
| `calendar_order` | `int` | 日程排序 |
| `steps` | `StepItem[]` | 执行步骤 |
| `created_at` | `string` | 创建时间 |
| `completed_at` | `string \| null` | 完成时间 |

### ParseRequest

AI 任务解析请求结构。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `text` | `string` | 用户输入的自然语言任务 |

### ParseResponse

AI 任务解析响应结构。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `events` | `EventItem[]` | AI 解析出的事件列表 |

### EventItem

AI 解析出的单个事件结构。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `title` | `string` | 事件标题 |
| `summary` | `string` | 事件摘要 |
| `total_minutes` | `int` | 预计总耗时，单位分钟 |
| `steps` | `StepItem[]` | 执行步骤 |

## 1. 服务状态检查

```http
GET /
```

响应示例：

```json
{
  "message": "一刻 API is running"
}
```

## 2. AI 解析自然语言任务

```http
POST /api/events/parse
```

请求体：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `text` | `string` | 是 | 用户输入的自然语言任务 |

请求示例：

```json
{
  "text": "明天下午复习计算机网络，并整理实验报告"
}
```

响应示例：

```json
{
  "events": [
    {
      "title": "复习计算机网络并整理实验报告",
      "summary": "复习计网",
      "total_minutes": 90,
      "steps": [
        {
          "step_order": 1,
          "description": "复习计算机网络重点内容",
          "estimated_min": 50
        },
        {
          "step_order": 2,
          "description": "整理实验报告内容",
          "estimated_min": 40
        }
      ]
    }
  ]
}
```

无有效任务时：

```json
{
  "events": []
}
```

## 3. 创建事件

```http
POST /api/events
```

请求体：`EventCreate`

请求示例：

```json
{
  "title": "复习计算机网络",
  "summary": "复习计网",
  "purpose": "准备考试",
  "status": "inbox",
  "quadrant": null,
  "scheduled_date": null,
  "time_slot": null,
  "calendar_order": 0,
  "steps": [
    {
      "step_order": 1,
      "description": "复习 TCP/IP 模型",
      "estimated_min": 30
    }
  ]
}
```

响应：`EventResponse`

## 4. 获取事件列表

```http
GET /api/events
```

查询参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `status` | `string` | 否 | 按事件状态筛选 |

请求示例：

```http
GET /api/events?status=inbox
```

响应示例：

```json
[
  {
    "id": 1,
    "title": "复习计算机网络",
    "summary": "复习计网",
    "purpose": "准备考试",
    "status": "inbox",
    "quadrant": null,
    "scheduled_date": null,
    "time_slot": null,
    "calendar_order": 0,
    "steps": [
      {
        "step_order": 1,
        "description": "复习 TCP/IP 模型",
        "estimated_min": 30
      }
    ],
    "created_at": "2026-06-16T10:00:00",
    "completed_at": null
  }
]
```

说明：

- 默认只返回未软删除的事件。
- 返回结果按创建时间倒序排列。

## 5. 获取事件详情

```http
GET /api/events/{event_id}
```

路径参数：

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `event_id` | `int` | 事件 ID |

响应：`EventResponse`

错误示例：

```json
{
  "detail": "Event not found"
}
```

## 6. 更新事件

```http
PUT /api/events/{event_id}
```

路径参数：

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `event_id` | `int` | 事件 ID |

请求体：`EventCreate`

说明：

- 更新事件时会替换事件主体信息。
- 当前实现会先删除旧步骤，再写入新的步骤列表。

响应：`EventResponse`

## 7. 删除事件

```http
DELETE /api/events/{event_id}
```

说明：

- 当前删除为软删除。
- 后端会写入 `deleted_at` 字段，不会直接物理删除数据。

响应示例：

```json
{
  "ok": true
}
```

## 常见错误

### 401 Unauthorized

当后端配置了 `API_TOKEN`，但请求未携带或携带了错误的 `X-API-Key` 时返回：

```json
{
  "detail": "Invalid API key"
}
```

### 404 Not Found

请求不存在的事件时返回：

```json
{
  "detail": "Event not found"
}
```

### 422 Validation Error

请求体字段类型不符合接口模型时，FastAPI 会返回参数校验错误。
