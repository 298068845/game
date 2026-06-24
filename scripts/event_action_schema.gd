extends RefCounted

const ACTION_NONE := ""
const ACTIONS := {
	"": {
		"label": "跳转/仅效果",
		"required": [],
		"optional": ["next", "flag", "item", "item_quantity", "damage", "quest", "relation", "coins", "stat_reward", "stat_rewards"]
	},
	"open_map": {
		"label": "打开地图",
		"required": [],
		"optional": ["flag", "item", "item_quantity", "damage", "quest", "relation", "coins", "stat_reward", "stat_rewards"]
	},
	"open_growth": {
		"label": "打开育成",
		"required": [],
		"optional": ["flag", "item", "item_quantity", "damage", "quest", "relation", "coins", "stat_reward", "stat_rewards"]
	},
	"d20_check": {
		"label": "D20检定",
		"required": ["stat", "difficulty", "success", "failure"],
		"optional": ["flag", "item", "item_quantity", "damage", "quest", "relation", "coins", "stat_reward", "stat_rewards"]
	},
	"resource_check": {
		"label": "资源检定",
		"required": ["stat", "difficulty", "resource"],
		"optional": ["flag", "damage", "quest", "relation", "coins", "stat_reward", "stat_rewards"]
	},
	"start_battle": {
		"label": "开始战斗",
		"required": [],
		"optional": ["flag", "item", "item_quantity", "damage", "quest", "relation", "coins", "stat_reward", "stat_rewards", "enemy", "victory", "battle_intro"]
	},
	"summary": {
		"label": "查看总结",
		"required": [],
		"optional": ["flag", "item", "item_quantity", "damage", "quest", "relation", "coins", "stat_reward", "stat_rewards"]
	}
}

static func action_ids() -> Array:
	return ACTIONS.keys()

static func action_label(action_id: String) -> String:
	return str(ACTIONS.get(action_id, ACTIONS[ACTION_NONE]).get("label", action_id))

static func has_action(action_id: String) -> bool:
	return ACTIONS.has(action_id)

static func validate_option(option: Dictionary, event_ids: Dictionary, item_ids: Dictionary, stats: Array, errors: Array[String], warnings: Array[String], event_id: String) -> void:
	if not option.has("text") or str(option.get("text", "")).strip_edges().is_empty():
		errors.append("事件选项缺少文本：%s" % event_id)
	var action_id := str(option.get("action", ACTION_NONE))
	if not has_action(action_id):
		errors.append("事件选项 action 不受支持：%s -> %s" % [event_id, action_id])
		return
	for field in ACTIONS[action_id].required:
		if not option.has(field) or str(option.get(field, "")).is_empty():
			errors.append("事件选项缺少字段 %s：%s" % [field, event_id])
	if option.has("next") and not event_ids.has(str(option.next)):
		errors.append("事件跳转目标不存在：%s -> %s" % [event_id, option.next])
	if option.has("success") and not event_ids.has(str(option.success)):
		errors.append("检定成功目标不存在：%s -> %s" % [event_id, option.success])
	if option.has("failure") and not event_ids.has(str(option.failure)):
		errors.append("检定失败目标不存在：%s -> %s" % [event_id, option.failure])
	if option.has("stat") and not stats.has(str(option.stat)):
		errors.append("事件选项属性无效：%s -> %s" % [event_id, option.stat])
	if option.has("difficulty") and int(option.difficulty) <= 0:
		errors.append("事件选项难度必须大于 0：%s" % event_id)
	for field in ["item", "resource"]:
		if option.has(field) and not item_ids.has(str(option[field])):
			warnings.append("事件选项 %s 引用未在内容库中找到：%s -> %s" % [field, event_id, option[field]])

