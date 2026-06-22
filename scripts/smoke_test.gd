extends SceneTree

func _init() -> void:
	for asset_path in ["res://assets/defaults/default_map.png", "res://assets/defaults/default_enemy.png", "res://assets/defaults/default_item.png"]:
		assert(ResourceLoader.exists(asset_path), "缺少默认图片：" + asset_path)
	var scenario = JSON.parse_string(FileAccess.get_file_as_string("res://data/scenario.json"))
	var database = JSON.parse_string(FileAccess.get_file_as_string("res://data/database.json"))
	assert(scenario is Dictionary)
	assert(database is Dictionary)
	assert(scenario.events.size() >= 19)
	assert(database.characters.size() >= 3)
	assert(database.enemies.size() >= 1)
	assert(database.items.size() >= 3)
	assert(database.equipment.size() >= 6)
	var required_slots := ["头盔", "盔甲", "武器", "臂甲", "鞋子", "饰品"]
	for slot in required_slots:
		assert(database.equipment.any(func(entry): return entry.slot == slot), "缺少装备种类：" + slot)
	for entity in database.characters + database.enemies:
		assert(entity.check_stats.size() == 5, "检定五维不完整：" + entity.name)
		assert(entity.combat_stats.size() == 5, "战斗五维不完整：" + entity.name)
		assert(entity.equipment.size() == 6, "装备栏不完整：" + entity.name)
		assert(entity.inventory is Dictionary, "背包格式错误：" + entity.name)
	var ids := {}
	for event in scenario.events:
		assert(not ids.has(event.id), "重复事件ID：" + event.id)
		assert(event.has("location") and not str(event.location).is_empty(), "事件缺少地点：" + event.id)
		assert(["continuous", "interruptible"].has(event.get("flow_mode", "")), "事件流程模式错误：" + event.id)
		assert(int(event.get("action_cost", -1)) >= 0, "行动点消耗错误：" + event.id)
		assert(event.has("music"), "事件缺少音乐字段：" + event.id)
		ids[event.id] = true
	for event in scenario.events:
		for option in event.get("options", []):
			if option.has("next"):
				assert(ids.has(option.next), "缺失跳转：" + option.next)
			if option.get("action", "") == "d20_check":
				assert(ids.has(option.success) and ids.has(option.failure))
		if event.get("locked", false):
			assert(not event.get("prerequisites", []).is_empty(), "锁定事件缺少前置条件：" + event.id)
			assert(["all", "any"].has(event.get("prerequisite_mode", "")), "前置满足模式错误：" + event.id)
			for required in event.prerequisites:
				assert(ids.has(required), "前置事件不存在：%s -> %s" % [event.id, required])
	assert(ids.has("after_battle"))
	assert(scenario.events.filter(func(event): return event.get("repeatable", false)).size() >= 3)
	print("SMOKE TEST PASS: %d events, %d characters, %d enemies, %d equipment, %d items" % [scenario.events.size(), database.characters.size(), database.enemies.size(), database.equipment.size(), database.items.size()])
	quit()
