extends Node

const SAVE_PATH := "user://mist_harbor_save.json"
const CONTENT_PATH := "user://mist_harbor_custom_content.json"
const SAVE_VERSION := 2
const EQUIPMENT_SLOTS := ["头盔", "盔甲", "武器", "臂甲", "鞋子", "饰品"]
const LEGACY_ITEM_IDS := {
	"旧港通行证": "item.pass", "提神药剂": "item.tonic", "裂纹透镜": "item.lens",
	"银灰盐块": "item.silver_salt", "林鸦的怀表": "quest.linya_watch"
}
const CRAFT_RECIPES := {
	"item.tonic": {"name": "调配提神药剂", "cost": {"item.herb": 2}},
	"item.ration": {"name": "整理旅行口粮", "cost": {"item.salvage": 1, "item.herb": 1}}
}

var player: Dictionary
var world: Dictionary
var battle: Dictionary
var custom_content: Dictionary

func _ready() -> void:
	randomize()
	reset_run()
	load_custom_content()

func reset_run() -> void:
	player = {
		"name": "调查员",
		"growth": {"体魄": 8, "洞察": 8, "意志": 8, "魅力": 8, "学识": 8},
		"combat": {"力量": 8, "防御": 8, "速度": 8, "技巧": 8, "生命": 12},
		"hp": 14,
		"satiety": 80,
		"max_satiety": 100,
		"max_hp_penalty": 0,
		"equipment": {"头盔": null, "盔甲": "equip.archive_coat", "武器": "equip.signal_pistol", "臂甲": null, "鞋子": null, "饰品": null},
		"inventory": {"item.pass": 1, "item.tonic": 1, "item.ration": 2, "equip.watch_cap": 1},
		"coins": 0,
		"training_growth": 3,
		"training_combat": 3
	}
	world = {"scene": "intro_01", "location": "渡船", "visited": [], "flags": {}, "minutes": 0, "log": [], "battle_won": false, "date":{"year":1,"month":1,"day":1}, "action_points":3, "max_action_points":3, "active_continuous":"", "repeat_counts":{}, "quests": {}, "relations": {"林鸦": 0, "老乔": 0, "港民": 0}, "random_seed": 137, "random_cooldowns": {}}
	battle = {}

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "player": player, "world": world, "battle": battle}, "  "))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary or not parsed.has("player") or not parsed.has("world"):
		return false
	player = parsed.player
	world = parsed.world
	battle = parsed.get("battle", {})
	_migrate_save(int(parsed.get("version", 1)))
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func add_log(text: String) -> void:
	world.log.append(text)
	if world.log.size() > 80:
		world.log.pop_front()

func load_custom_content() -> void:
	custom_content = {"events": [], "characters": [], "enemies": [], "equipment": [], "items": [], "map_background": "", "map_music": ""}
	if FileAccess.file_exists(CONTENT_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONTENT_PATH))
		if parsed is Dictionary:
			custom_content.merge(parsed, true)
	for key in ["events", "characters", "enemies", "equipment", "items"]:
		if not custom_content.has(key) or not custom_content[key] is Array:
			custom_content[key] = []
	if not custom_content.has("map_background"):
		custom_content.map_background = ""
	if not custom_content.has("map_music"):
		custom_content.map_music = ""

func save_custom_content() -> bool:
	var file := FileAccess.open(CONTENT_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(custom_content, "  "))
	return true

func _migrate_player_inventory() -> void:
	if not player.has("inventory"):
		player.inventory = {}
		for legacy_name in player.get("items", []):
			var item_id: String = LEGACY_ITEM_IDS.get(str(legacy_name), str(legacy_name))
			player.inventory[item_id] = int(player.inventory.get(item_id, 0)) + 1
	if not player.has("equipment"):
		player.equipment = {}
	for slot in EQUIPMENT_SLOTS:
		if not player.equipment.has(slot):
			player.equipment[slot] = null
	player.erase("items")

func _migrate_save(version: int) -> void:
	_migrate_player_inventory()
	if not world.has("visited"):
		world.visited = []
	if not world.has("location"):
		world.location = "渡船"
	if not world.has("date"):
		world.date = {"year":1,"month":1,"day":1}
	if not world.has("action_points"):
		world.action_points = 3
	if not world.has("max_action_points"):
		world.max_action_points = 3
	if not world.has("active_continuous"):
		world.active_continuous = ""
	if not world.has("repeat_counts"):
		world.repeat_counts = {}
	if not player.has("satiety"):
		player.satiety = 80
	if not player.has("max_satiety"):
		player.max_satiety = 100
	if not player.has("max_hp_penalty"):
		player.max_hp_penalty = 0
	if version < 2:
		_migrate_v1_to_v2()
	_ensure_world_systems()

func _migrate_v1_to_v2() -> void:
	if not player.has("coins"):
		player.coins = 0

func _ensure_world_systems() -> void:
	if not world.has("quests") or not world.quests is Dictionary:
		world.quests = {}
	if not world.has("relations") or not world.relations is Dictionary:
		world.relations = {"林鸦": 0, "老乔": 0, "港民": 0}
	for name in ["林鸦", "老乔", "港民"]:
		if not world.relations.has(name):
			world.relations[name] = 0
	if not world.has("random_seed"):
		world.random_seed = 137
	if not world.has("random_cooldowns") or not world.random_cooldowns is Dictionary:
		world.random_cooldowns = {}
	if not player.has("coins"):
		player.coins = 0

func set_quest(quest_id: String, title: String, status: String, clue: String = "") -> void:
	world.quests[quest_id] = {"title": title, "status": status, "clue": clue}

func adjust_relation(name: String, delta: int) -> void:
	world.relations[name] = int(world.relations.get(name, 0)) + delta

func sell_item(item_id: String, quantity: int, price: int) -> bool:
	if not remove_item(item_id, quantity):
		return false
	player.coins = int(player.coins) + quantity * price
	return true

func craft_item(item_id: String) -> bool:
	if not CRAFT_RECIPES.has(item_id):
		return false
	var recipe: Dictionary = CRAFT_RECIPES[item_id]
	var cost: Dictionary = recipe.get("cost", {})
	for ingredient in cost:
		if not has_item(str(ingredient), int(cost[ingredient])):
			return false
	for ingredient in cost:
		remove_item(str(ingredient), int(cost[ingredient]))
	add_item(item_id)
	return true

func resolve_item_id(item_ref: String) -> String:
	return LEGACY_ITEM_IDS.get(item_ref, item_ref)

func add_item(item_ref: String, quantity: int = 1) -> void:
	var item_id := resolve_item_id(item_ref)
	player.inventory[item_id] = int(player.inventory.get(item_id, 0)) + maxi(1, quantity)

func has_item(item_ref: String, quantity: int = 1) -> bool:
	return int(player.inventory.get(resolve_item_id(item_ref), 0)) >= quantity

func remove_item(item_ref: String, quantity: int = 1) -> bool:
	var item_id := resolve_item_id(item_ref)
	var current := int(player.inventory.get(item_id, 0))
	if current < quantity:
		return false
	current -= quantity
	if current <= 0:
		player.inventory.erase(item_id)
	else:
		player.inventory[item_id] = current
	return true

func equip_item(item_id: String, slot: String) -> bool:
	if not EQUIPMENT_SLOTS.has(slot) or not has_item(item_id):
		return false
	var old_item = player.equipment.get(slot)
	remove_item(item_id)
	player.equipment[slot] = item_id
	if old_item != null and not str(old_item).is_empty():
		add_item(str(old_item))
	return true

func unequip_slot(slot: String) -> bool:
	var item = player.equipment.get(slot)
	if item == null or str(item).is_empty():
		return false
	add_item(str(item))
	player.equipment[slot] = null
	return true

func date_text() -> String:
	return "雾历 %d年%02d月%02d日" % [int(world.date.year), int(world.date.month), int(world.date.day)]

func rest_day() -> Dictionary:
	var satiety_cost := 20
	var shortage := maxi(0, satiety_cost - int(player.satiety))
	player.satiety = maxi(0, int(player.satiety) - satiety_cost)
	var hp_penalty := 0
	if shortage > 0:
		hp_penalty = maxi(1, ceili(shortage / 10.0))
		player.max_hp_penalty = int(player.max_hp_penalty) + hp_penalty
	world.date.day = int(world.date.day) + 1
	if int(world.date.day) > 30:
		world.date.day = 1
		world.date.month = int(world.date.month) + 1
	if int(world.date.month) > 12:
		world.date.month = 1
		world.date.year = int(world.date.year) + 1
	world.action_points = int(world.max_action_points)
	return {"satiety_cost":satiety_cost, "shortage":shortage, "hp_penalty":hp_penalty}

func eat_ration() -> bool:
	if not remove_item("item.ration"):
		return false
	player.satiety = mini(int(player.max_satiety), int(player.satiety) + 30)
	return true
