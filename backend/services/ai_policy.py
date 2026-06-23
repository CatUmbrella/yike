from typing import Any

POLICY_VERSION = "task_parse_policy_v1"
MAX_POLICY_ITEMS = 4

POLICY_ITEMS = {
    "effective_task_only": {
        "id": "effective_task_only",
        "rule": "只输出用户刻意要执行、推进、完成或提醒的真实任务。",
        "example": {
            "input": "最近有点累，感觉事情很多",
            "output_hint": '{"events": []}',
        },
    },
    "daily_activity_ignore": {
        "id": "daily_activity_ignore",
        "rule": "日常本来会做的生活动作不输出，除非用户明确要求提醒或专门安排。",
        "example": {
            "input": "明天起床洗漱吃饭",
            "output_hint": '{"events": []}',
        },
    },
    "cancelled_item_ignore": {
        "id": "cancelled_item_ignore",
        "rule": "已取消事项不输出。",
        "example": {
            "input": "取消下午整理书桌",
            "output_hint": '{"events": []}',
        },
    },
    "uncertain_item_ignore": {
        "id": "uncertain_item_ignore",
        "rule": "不确定事项不输出，除非用户要求确认、查询、询问或决定。",
        "example": {
            "input": "也许之后可以看看论文方向",
            "output_hint": '{"events": []}',
        },
    },
    "time_not_title": {
        "id": "time_not_title",
        "rule": "时间只用于理解、排序、估时和判断合并粒度，不写进 title/summary。",
        "example": {
            "input": "明天下午写周报",
            "output_hint": 'title 写“写周报”，不要写“明天下午写周报”。',
        },
    },
    "merge_or_split_granularity": {
        "id": "merge_or_split_granularity",
        "rule": "能合并的尽量合并；明显超过 3 小时或主题不同，才拆成多个 events。",
        "example": {
            "input": "复习计网并整理实验报告",
            "output_hint": "如果可作为一个真实可执行事项，可以合并为一个 event。",
        },
    },
    "simple_task_no_steps": {
        "id": "simple_task_no_steps",
        "rule": "一步能完成的简单事件不拆步骤，steps 可以为空。",
        "example": {
            "input": "写一篇周报",
            "output_hint": "steps 可以为空。",
        },
    },
    "complex_task_steps": {
        "id": "complex_task_steps",
        "rule": "复杂事件才拆 steps；steps 只写具体执行动作，不写心理准备、检查、打开页面等微动作。",
        "example": {
            "input": "准备毕业答辩材料",
            "output_hint": "可以拆为整理材料、制作答辩稿、完善讲稿等具体动作。",
        },
    },
    "unknown_duration_zero": {
        "id": "unknown_duration_zero",
        "rule": "无法合理估计耗时时，total_minutes 或 estimated_min 可以返回 0，不要强行估时。",
        "example": {
            "input": "研究一下论文方向",
            "output_hint": "total_minutes 可以为 0。",
        },
    },
    "duration_contract": {
        "id": "duration_contract",
        "rule": "total_minutes 和 estimated_min 必须是非负整数；steps 非空且 total_minutes 为 0 时，后端会按步骤合计修正。",
        "example": {
            "input": "拆成两个步骤，每步 20 分钟",
            "output_hint": "total_minutes 可为 40；如果返回 0，后端会用步骤合计修正。",
        },
    },
}

DEFAULT_POLICY_KEYS = [
    "effective_task_only",
    "simple_task_no_steps",
    "unknown_duration_zero",
    "duration_contract",
]

RETRIEVE_PARSE_POLICY_TOOL = {
    "type": "function",
    "function": {
        "name": "retrieve_parse_policy",
        "description": (
            "获取任务事件抽取规则片段和示例。这个工具只读，不生成事件，"
            "用于在最终 JSON 输出前确认拆分、步骤和耗时等规则。"
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "policy_keys": {
                    "type": "array",
                    "description": "需要取回的规则 key；不确定时可省略，后端返回默认核心规则。",
                    "items": {
                        "type": "string",
                        "enum": list(POLICY_ITEMS.keys()),
                    },
                    "maxItems": MAX_POLICY_ITEMS,
                }
            },
            "additionalProperties": False,
        },
    },
}


def retrieve_parse_policy(policy_keys: Any = None) -> dict[str, Any]:
    keys = _normalize_policy_keys(policy_keys)
    return {
        "policy_version": POLICY_VERSION,
        "items": [POLICY_ITEMS[key] for key in keys],
    }


def _normalize_policy_keys(policy_keys: Any) -> list[str]:
    if not isinstance(policy_keys, list):
        return DEFAULT_POLICY_KEYS

    keys: list[str] = []
    for key in policy_keys:
        if not isinstance(key, str) or key not in POLICY_ITEMS or key in keys:
            continue
        keys.append(key)
        if len(keys) >= MAX_POLICY_ITEMS:
            break
    return keys or DEFAULT_POLICY_KEYS
