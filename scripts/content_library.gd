extends RefCounted

const ContentSchema = preload("res://scripts/content_schema.gd")

var scenario: Dictionary = {}
var database: Dictionary = {}
var custom_content: Dictionary = {}
var events: Dictionary = {}

func load_from_resources(scenario_path: String, database_path: String, source_custom_content: Dictionary) -> void:
	scenario = _read_json(scenario_path)
	database = _read_json(database_path)
	custom_content = ContentSchema.normalize_custom_content(source_custom_content)
	reload_events()

func set_package(package: Dictionary) -> void:
	scenario = package.get("scenario", {})
	database = package.get("database", {})
	custom_content = ContentSchema.normalize_custom_content(package.get("custom_content", {}))
	reload_events()

func reload_custom_content(source_custom_content: Dictionary) -> void:
	custom_content = ContentSchema.normalize_custom_content(source_custom_content)
	reload_events()

func reload_events() -> void:
	events.clear()
	for event in scenario.get("events", []):
		events[event.id] = event
	for custom_event in custom_content.get("events", []):
		var event := ContentSchema.normalize_event(custom_event)
		events[event.id] = event

func all_event_definitions() -> Array:
	return events.values()

func has_event(event_id: String) -> bool:
	return events.has(event_id)

func get_event(event_id: String) -> Dictionary:
	return events.get(event_id, {})

func event_unlocked(event_id: String, visited: Array) -> bool:
	if not events.has(event_id):
		return false
	var event: Dictionary = events[event_id]
	if not bool(event.get("locked", false)):
		return true
	var prerequisites: Array = event.get("prerequisites", [])
	if prerequisites.is_empty():
		return false
	if event.get("prerequisite_mode", "all") == "any":
		return prerequisites.any(func(required): return visited.has(str(required)))
	return prerequisites.all(func(required): return visited.has(str(required)))

func lock_description(event_id: String) -> String:
	if not events.has(event_id):
		return "事件不存在"
	var event: Dictionary = events[event_id]
	var prerequisites: Array = event.get("prerequisites", [])
	if prerequisites.is_empty():
		return "该事件已锁定，未设置解锁条件"
	var names: Array[String] = []
	for required in prerequisites:
		var required_event: Dictionary = events.get(str(required), {})
		names.append(required_event.get("title", str(required)))
	var connector := " 或 " if event.get("prerequisite_mode", "all") == "any" else "、"
	return "需要先触发：" + connector.join(names)

func all_equipment() -> Array:
	return merged_definitions(database.get("equipment", []), custom_content.get("equipment", []))

func all_items() -> Array:
	return merged_definitions(database.get("items", []), custom_content.get("items", []))

func all_entities(key: String) -> Array:
	return merged_definitions(database.get(key, []), custom_content.get(key, []))

func find_entity(key: String, entity_id: String) -> Dictionary:
	for entry in all_entities(key):
		if entry.get("id", "") == entity_id:
			return entry
	return {}

func find_content_item(item_id: String) -> Dictionary:
	for entry in all_equipment():
		if entry.get("id", "") == item_id:
			return entry
	for entry in all_items():
		if entry.get("id", "") == item_id:
			return entry
	if item_id == "quest.linya_watch":
		return {"id": item_id, "name": "林鸦的怀表", "type": "任务物品", "description": "指针停在十三分。"}
	return {"id": item_id, "name": item_id, "type": "未知", "description": "未找到物品定义。"}

func item_name(item_id: String) -> String:
	return str(find_content_item(item_id).get("name", item_id))

func merged_definitions(builtins: Array, customs: Array) -> Array:
	var order: Array[String] = []
	var definitions := {}
	for entry in builtins + customs:
		var entry_id := str(entry.get("id", ""))
		if not order.has(entry_id):
			order.append(entry_id)
		definitions[entry_id] = entry
	var result: Array = []
	for entry_id in order:
		result.append(definitions[entry_id])
	return result

func _read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
