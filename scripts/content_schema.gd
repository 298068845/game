extends RefCounted

const EventActionSchema = preload("res://scripts/event_action_schema.gd")

const SCHEMA_VERSION := 1
const COLLECTION_KEYS := ["events", "characters", "enemies", "equipment", "items"]
const CHECK_STATS := ["体魄", "洞察", "意志", "魅力", "学识"]
const COMBAT_STATS := ["力量", "防御", "速度", "技巧", "生命"]
const FLOW_MODES := ["continuous", "interruptible"]
const PREREQUISITE_MODES := ["all", "any"]

static func empty_custom_content() -> Dictionary:
	return {
		"events": [],
		"characters": [],
		"enemies": [],
		"equipment": [],
		"items": [],
		"map_background": "",
		"map_music": "",
		"map_points": []
	}

static func normalize_custom_content(source: Dictionary) -> Dictionary:
	var content := empty_custom_content()
	content.merge(source, true)
	for key in COLLECTION_KEYS:
		if not content.has(key) or not content[key] is Array:
			content[key] = []
	if not content.has("map_background") or not content.map_background is String:
		content.map_background = ""
	if not content.has("map_music") or not content.map_music is String:
		content.map_music = ""
	if not content.has("map_points") or not content.map_points is Array:
		content.map_points = []
	var normalized_points: Array = []
	for point in content.map_points:
		if not point is Dictionary:
			continue
		var name := str(point.get("name", "")).strip_edges()
		if name.is_empty():
			continue
		normalized_points.append({"name": name, "x": int(point.get("x", 480)), "y": int(point.get("y", 150))})
	content.map_points = normalized_points
	return content

static func normalize_event(source: Dictionary) -> Dictionary:
	var event := source.duplicate(true)
	event.id = str(event.get("id", "custom.%d" % Time.get_unix_time_from_system()))
	event.title = str(event.get("title", event.get("name", "自定义事件")))
	event.name = event.title
	event.chapter = str(event.get("chapter", "自定义事件"))
	event.speaker = str(event.get("speaker", "旁白"))
	event.type = str(event.get("type", "剧情事件"))
	event.location = str(event.get("location", "雾港码头"))
	event.text = str(event.get("text", ""))
	event.options = event.get("options", [{"text": "返回地图", "action": "open_map"}])
	event.locked = bool(event.get("locked", false))
	event.prerequisites = _string_array(event.get("prerequisites", []))
	event.prerequisite_mode = str(event.get("prerequisite_mode", "all"))
	if not PREREQUISITE_MODES.has(event.prerequisite_mode):
		event.prerequisite_mode = "all"
	event.flow_mode = str(event.get("flow_mode", "interruptible"))
	if not FLOW_MODES.has(event.flow_mode):
		event.flow_mode = "interruptible"
	event.repeatable = bool(event.get("repeatable", false))
	event.action_cost = maxi(0, int(event.get("action_cost", 1)))
	event.ends_continuous = bool(event.get("ends_continuous", false))
	event.background_image = str(event.get("background_image", ""))
	event.music = str(event.get("music", ""))
	event.draft = bool(event.get("draft", false))
	event.import_notes = str(event.get("import_notes", ""))
	return event

static func validate_package(package: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var scenario_value = package.get("scenario", {})
	var database_value = package.get("database", {})
	var custom_value = package.get("custom_content", {})
	var scenario: Dictionary = scenario_value if scenario_value is Dictionary else {}
	var database: Dictionary = database_value if database_value is Dictionary else {}
	var custom_content := normalize_custom_content(custom_value if custom_value is Dictionary else {})
	if not scenario_value is Dictionary:
		errors.append("scenario 必须是对象")
	if not database_value is Dictionary:
		errors.append("database 必须是对象")
	if not custom_value is Dictionary:
		warnings.append("custom_content 不是对象，已按空自定义内容处理")

	_validate_database(database, custom_content, errors, warnings)
	_validate_scenario(scenario, custom_content.events, database, custom_content, errors, warnings)

	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"summary": _summary(scenario, database, custom_content)
	}

static func _validate_scenario(scenario: Dictionary, custom_events: Array, database: Dictionary, custom_content: Dictionary, errors: Array[String], warnings: Array[String]) -> void:
	if scenario.is_empty():
		errors.append("缺少 scenario 对象")
		return
	if not scenario.has("id") or str(scenario.id).is_empty():
		errors.append("scenario.id 不能为空")
	if not scenario.has("events") or not scenario.events is Array:
		errors.append("scenario.events 必须是数组")
		return

	var ids := {}
	var custom_ids := {}
	var all_events: Array = []
	for event in scenario.events:
		all_events.append(event)
	for event in custom_events:
		all_events.append(normalize_event(event if event is Dictionary else {}))

	for index in range(all_events.size()):
		var event = all_events[index]
		if not event is Dictionary:
			errors.append("事件 #%d 必须是对象" % index)
			continue
		var event_id := str(event.get("id", ""))
		if event_id.is_empty():
			errors.append("事件 #%d 缺少 id" % index)
			continue
		var is_custom: bool = index >= scenario.events.size()
		if is_custom and custom_ids.has(event_id):
			errors.append("事件 id 重复：%s" % event_id)
		elif is_custom and ids.has(event_id):
			warnings.append("自定义事件覆盖内置事件：%s" % event_id)
		elif not is_custom and ids.has(event_id):
			errors.append("事件 id 重复：%s" % event_id)
		if is_custom:
			custom_ids[event_id] = true
		ids[event_id] = true
		if str(event.get("location", "")).is_empty():
			errors.append("事件缺少地点：%s" % event_id)
		if not FLOW_MODES.has(str(event.get("flow_mode", ""))):
			errors.append("事件流程模式无效：%s" % event_id)
		if int(event.get("action_cost", -1)) < 0:
			errors.append("事件行动点消耗无效：%s" % event_id)
		if not event.has("music"):
			warnings.append("事件未声明 music 字段：%s" % event_id)

	var item_ids := _collect_item_ids(database, custom_content)
	var stats := []
	stats.append_array(CHECK_STATS)
	stats.append_array(COMBAT_STATS)
	for event in all_events:
		if not event is Dictionary:
			continue
		var event_id := str(event.get("id", ""))
		for option in event.get("options", []):
			if not option is Dictionary:
				errors.append("事件选项必须是对象：%s" % event_id)
				continue
			EventActionSchema.validate_option(option, ids, item_ids, stats, errors, warnings, event_id)
		if bool(event.get("locked", false)):
			if event.get("prerequisites", []).is_empty():
				errors.append("锁定事件缺少前置条件：%s" % event_id)
			if not PREREQUISITE_MODES.has(str(event.get("prerequisite_mode", ""))):
				errors.append("前置满足模式无效：%s" % event_id)
			for required in event.get("prerequisites", []):
				if not ids.has(str(required)):
					errors.append("前置事件不存在：%s -> %s" % [event_id, required])

static func _validate_database(database: Dictionary, custom_content: Dictionary, errors: Array[String], warnings: Array[String]) -> void:
	if database.is_empty():
		errors.append("缺少 database 对象")
		return
	for key in ["characters", "enemies", "equipment", "items"]:
		if not database.has(key) or not database[key] is Array:
			errors.append("database.%s 必须是数组" % key)

	var equipment_ids := {}
	for equipment in _combined(database.get("equipment", []), custom_content.get("equipment", [])):
		if not equipment is Dictionary:
			errors.append("装备条目必须是对象")
			continue
		var item_id := str(equipment.get("id", ""))
		if item_id.is_empty():
			errors.append("装备缺少 id")
		equipment_ids[item_id] = true
		if str(equipment.get("slot", "")).is_empty():
			errors.append("装备缺少 slot：%s" % item_id)

	var item_ids := {}
	for item in _combined(database.get("items", []), custom_content.get("items", [])):
		if not item is Dictionary:
			errors.append("物品条目必须是对象")
			continue
		var item_id := str(item.get("id", ""))
		if item_id.is_empty():
			errors.append("物品缺少 id")
		item_ids[item_id] = true
		if str(item.get("type", "")).is_empty():
			warnings.append("物品缺少 type：%s" % item_id)

	for key in ["characters", "enemies"]:
		for entity in _combined(database.get(key, []), custom_content.get(key, [])):
			_validate_entity(entity, key, equipment_ids, item_ids, errors)

static func _collect_item_ids(database: Dictionary, custom_content: Dictionary) -> Dictionary:
	var item_ids := {"quest.linya_watch": true}
	for equipment in _combined(database.get("equipment", []), custom_content.get("equipment", [])):
		if equipment is Dictionary and not str(equipment.get("id", "")).is_empty():
			item_ids[str(equipment.id)] = true
	for item in _combined(database.get("items", []), custom_content.get("items", [])):
		if item is Dictionary and not str(item.get("id", "")).is_empty():
			item_ids[str(item.id)] = true
	return item_ids

static func _validate_entity(entity, key: String, equipment_ids: Dictionary, item_ids: Dictionary, errors: Array[String]) -> void:
	if not entity is Dictionary:
		errors.append("%s 条目必须是对象" % key)
		return
	var entity_id := str(entity.get("id", ""))
	if entity_id.is_empty():
		errors.append("%s 条目缺少 id" % key)
	for stat in CHECK_STATS:
		if not entity.get("check_stats", {}).has(stat):
			errors.append("%s 检定属性缺少 %s：%s" % [key, stat, entity_id])
	for stat in COMBAT_STATS:
		if not entity.get("combat_stats", {}).has(stat):
			errors.append("%s 战斗属性缺少 %s：%s" % [key, stat, entity_id])
	var equipment: Dictionary = entity.get("equipment", {})
	for slot in equipment:
		var equipment_id = equipment[slot]
		if equipment_id != null and not str(equipment_id).is_empty() and not equipment_ids.has(str(equipment_id)):
			errors.append("%s 装备引用不存在：%s -> %s" % [key, entity_id, equipment_id])
	var inventory: Dictionary = entity.get("inventory", {})
	for item_id in inventory:
		var id := str(item_id)
		if not item_ids.has(id) and not equipment_ids.has(id):
			errors.append("%s 背包引用不存在：%s -> %s" % [key, entity_id, id])

static func _summary(scenario: Dictionary, database: Dictionary, custom_content: Dictionary) -> Dictionary:
	return {
		"scenario_id": str(scenario.get("id", "")),
		"events": database.get("_event_count", 0) + scenario.get("events", []).size() + custom_content.events.size(),
		"characters": database.get("characters", []).size() + custom_content.characters.size(),
		"enemies": database.get("enemies", []).size() + custom_content.enemies.size(),
		"equipment": database.get("equipment", []).size() + custom_content.equipment.size(),
		"items": database.get("items", []).size() + custom_content.items.size()
	}

static func _combined(first: Array, second: Array) -> Array:
	var output := []
	output.append_array(first)
	output.append_array(second)
	return output

static func _string_array(value) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in value:
			var text := str(entry).strip_edges()
			if not text.is_empty() and not result.has(text):
				result.append(text)
	return result
