import json

from openai import OpenAI

from config import AI_BASE_URL, AI_MODEL, OPENAI_API_KEY

#提示词
SYSTEM_PROMPT = """你是任务事件抽取与轻量拆解助手。只处理当前用户输入，返回纯 JSON。

规则：
- 只提取用户刻意要执行、推进、完成或提醒的事情。
- 忽略修饰词、情绪、状态、背景、愿望、节奏描述和空泛规划。
- 日常本来会做的生活动作不输出，如起床、洗漱、吃饭、午休、散步、放松、通勤、去常规地点；除非用户明确要求提醒或专门安排。
- 不按日期、星期、频率、时间段拆事件；时间只用于理解、排序、估时和判断合并粒度，不写进 title/summary。
- 本次返回是完整替换结果，不追加历史结果；无有效任务返回 {"events": []}。
- 一个 event 必须是真实可执行、可单独安排到日程里的事情。
- 能合并的尽量合并，但合并后必须仍是一件真实可执行的事。
- 日程粒度以 3 小时为界限；明显超过 3 小时或主题不同，应拆成多个 events。
- 不逐句拆，不把修饰词、背景描述拆成事件。
- 已取消事项不输出；不确定事项不输出，除非用户要求确认、查询、询问或决定。
- title 只写具体要做的事，删除时间词、频率词和空泛词。
- summary 是 title 的六字左右中文短总结，不含时间、频率、日期。
- steps 允许为空；一步能完成的简单事件不拆步骤。
- 复杂事件才拆 steps；个性化高且缺少背景时，只给通用执行步骤。
- steps 只写具体执行动作，不写心理准备、复盘、检查、打开页面、点击按钮等微动作。
- total_minutes 和 estimated_min 都是分钟整数；steps 非空时 total_minutes 等于 estimated_min 之和。
- 能合理估计时返回 5 到 180；少于 5 按 5；无法合理估计返回 0。
- 不返回 null；无法判断的文本字段用空字符串。
- title、summary、description 必须使用中文。

只返回以下 JSON 结构，不要 Markdown、解释或额外字段：
{
  "events": [
    {
      "title": "事件完整名称",
      "summary": "六字左右短标题",
      "total_minutes": 50,
      "steps": [
        {
          "step_order": 1,
          "description": "第一步要做什么",
          "estimated_min": 20
        }
      ]
    }
  ]
}"""

def parse_event_text(text: str) -> dict:
    if not OPENAI_API_KEY:
        raise RuntimeError("OPENAI_API_KEY is not configured")

    client = OpenAI(
        api_key=OPENAI_API_KEY,
        base_url=AI_BASE_URL,
    )

    response = client.chat.completions.create(
        model=AI_MODEL,
        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": text},
        ],
        temperature=0.3,
    )

    #选择回答，并去除回答中的空格
    content = response.choices[0].message.content.strip()

    #清理可能存在的Markdown标记
    if content.startswith("```"):
        content = content.split("\n", 1)[-1]
        if content.endswith("```"):
            content = content[:-3]

    return json.loads(content)
