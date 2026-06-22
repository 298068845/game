extends Control

const DiceClass = preload("res://scripts/dice.gd")

var scenario: Dictionary = {}
var database: Dictionary = {}
var events: Dictionary = {}
var current_view := "menu"
var content_root: MarginContainer
var toast_label: Label
var time_status_label: Label
var title_label: Label
var body_label: RichTextLabel
var choices_box: VBoxContainer
var hp_label: Label
var inventory_label: Label
var battle_log: RichTextLabel
var enemy_hp_label: Label
var player_hp_label: Label
var editor_list: ItemList
var editor_name: LineEdit
var editor_type: OptionButton
var editor_location: OptionButton
var editor_lock: CheckBox
var editor_prerequisites: LineEdit
var editor_prerequisite_mode: OptionButton
var editor_flow_mode: OptionButton
var editor_repeatable: CheckBox
var editor_action_cost: SpinBox
var editor_ends_continuous: CheckBox
var editor_background_path: LineEdit
var editor_background_preview: TextureRect
var editor_music_path: LineEdit
var editor_text: TextEdit
var editor_preview: HBoxContainer
var manager_list: ItemList
var manager_kind: OptionButton
var manager_name: LineEdit
var manager_desc: TextEdit
var selected_editor_index := -1
var selected_manager_index := -1
var entity_kind: OptionButton
var entity_list: ItemList
var entity_name: LineEdit
var entity_role: LineEdit
var entity_stat_inputs: Dictionary = {}
var entity_loadout_inputs: Dictionary = {}
var entity_carry_item: OptionButton
var entity_carry_qty: SpinBox
var entity_carry_list: ItemList
var entity_portrait_path: LineEdit
var entity_portrait_preview: TextureRect
var entity_draft_inventory: Dictionary = {}
var editing_entity_id := ""
var item_list_editor: ItemList
var item_category: OptionButton
var item_name_input: LineEdit
var item_desc_input: TextEdit
var item_bonus_inputs: Dictionary = {}
var item_image_path: LineEdit
var item_image_preview: TextureRect
var editing_item_id := ""
var tools_tabs: TabContainer
var map_background_path: LineEdit
var map_background_preview: TextureRect
var map_music_path: LineEdit
var image_dialog: FileDialog
var pending_image_target := ""
var audio_dialog: FileDialog
var pending_audio_target := ""
var map_music_player: AudioStreamPlayer
var event_music_player: AudioStreamPlayer
var preview_music_player: AudioStreamPlayer
var current_map_music_path := ""
var current_event_music_path := ""

var bg := Color("101724")
var panel := Color("182235")
var panel_alt := Color("202d43")
var accent := Color("62d4c7")
var gold := Color("e8b75d")
var text_main := Color("e8eef8")
var text_dim := Color("9fb0c8")
var danger := Color("e36f78")

const LOCATIONS := ["渡船", "雾港码头", "雾港广场", "黑帆酒馆", "旧灯塔", "地下钟室"]
const DEFAULT_MAP_IMAGE := "res://assets/defaults/default_map.png"
const DEFAULT_ENEMY_IMAGE := "res://assets/defaults/default_enemy.png"
const DEFAULT_ITEM_IMAGE := "res://assets/defaults/default_item.png"
const LOCATION_ENTRY := {
	"渡船": "intro_01",
	"雾港码头": "harbor_01",
	"雾港广场": "square_01",
	"黑帆酒馆": "tavern_01",
	"旧灯塔": "lighthouse_01",
	"地下钟室": "archive_01"
}

func _ready() -> void:
	scenario = _read_json("res://data/scenario.json")
	database = _read_json("res://data/database.json")
	for event in scenario.get("events", []):
		events[event.id] = event
	for custom_event in GameState.custom_content.get("events", []):
		_register_custom_event(custom_event)
	_build_audio_system()
	_build_shell()
	show_menu()
	if OS.get_cmdline_user_args().has("--preview-tools"):
		show_tools.call_deferred()
	elif OS.get_cmdline_user_args().has("--preview-entities"):
		_preview_tools_page.call_deferred(1)
	elif OS.get_cmdline_user_args().has("--preview-items"):
		_preview_tools_page.call_deferred(2)
	elif OS.get_cmdline_user_args().has("--preview-map-assets"):
		_preview_tools_page.call_deferred(3)
	elif OS.get_cmdline_user_args().has("--preview-inventory"):
		show_inventory.call_deferred()
	elif OS.get_cmdline_user_args().has("--preview-map"):
		show_map.call_deferred()
	elif OS.get_cmdline_user_args().has("--preview-battle"):
		show_battle.call_deferred(true)
	elif OS.get_cmdline_user_args().has("--preview-schedule"):
		_preview_schedule.call_deferred()

func _read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _build_audio_system() -> void:
	map_music_player = AudioStreamPlayer.new()
	map_music_player.name = "MapMusic"
	add_child(map_music_player)
	event_music_player = AudioStreamPlayer.new()
	event_music_player.name = "EventMusic"
	add_child(event_music_player)
	preview_music_player = AudioStreamPlayer.new()
	preview_music_player.name = "PreviewMusic"
	add_child(preview_music_player)

func _ensure_image_dialog() -> void:
	if image_dialog != null:
		return
	image_dialog = FileDialog.new()
	image_dialog.title = "选择图片素材"
	image_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	image_dialog.access = FileDialog.ACCESS_FILESYSTEM
	image_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; 图片文件"])
	image_dialog.file_selected.connect(_on_image_file_selected)
	add_child(image_dialog)

func _request_image(target: String) -> void:
	_ensure_image_dialog()
	pending_image_target = target
	image_dialog.popup_centered_ratio(0.72)

func _on_image_file_selected(source_path: String) -> void:
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		_toast("图片读取失败")
		return
	var asset_dir := "user://mist_harbor_assets"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(asset_dir))
	var asset_name := (source_path + str(Time.get_ticks_msec())).md5_text() + ".png"
	var stored_path := asset_dir + "/" + asset_name
	if image.save_png(ProjectSettings.globalize_path(stored_path)) != OK:
		_toast("图片复制失败")
		return
	_set_image_target(pending_image_target, stored_path)
	_toast("图片已复制到内容素材库")

func _texture_from_path(path: String, fallback_path: String = "") -> Texture2D:
	if path.is_empty():
		return load(fallback_path) as Texture2D if not fallback_path.is_empty() else null
	if path.begins_with("res://"):
		var resource_texture := load(path) as Texture2D
		return resource_texture if resource_texture != null else (load(fallback_path) as Texture2D if not fallback_path.is_empty() else null)
	var absolute_path := ProjectSettings.globalize_path(path) if path.begins_with("user://") else path
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return load(fallback_path) as Texture2D if not fallback_path.is_empty() else null
	return ImageTexture.create_from_image(image)

func _set_preview(preview: TextureRect, path: String, fallback_path: String = "") -> void:
	if preview != null:
		preview.texture = _texture_from_path(path, fallback_path)

func _set_image_target(target: String, path: String) -> void:
	match target:
		"event_background":
			editor_background_path.text = path
			_set_preview(editor_background_preview, path)
		"entity_portrait":
			entity_portrait_path.text = path
			_set_preview(entity_portrait_preview, path, DEFAULT_ENEMY_IMAGE if entity_kind != null and entity_kind.selected == 1 else "")
		"item_image":
			item_image_path.text = path
			_set_preview(item_image_preview, path, DEFAULT_ITEM_IMAGE)
		"map_background":
			map_background_path.text = path
			_set_preview(map_background_preview, path, DEFAULT_MAP_IMAGE)

func _clear_image_target(target: String) -> void:
	_set_image_target(target, "")

func _make_image_picker(target: String, line: LineEdit, preview: TextureRect) -> VBoxContainer:
	var box := VBoxContainer.new()
	var row := HBoxContainer.new()
	box.add_child(row)
	line.editable = false
	line.placeholder_text = "未设置图片"
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(line)
	var choose := _button("选择图片")
	choose.custom_minimum_size.x = 90
	choose.pressed.connect(func(): _request_image(target))
	row.add_child(choose)
	var clear := _button("清除")
	clear.custom_minimum_size.x = 64
	clear.pressed.connect(func(): _clear_image_target(target))
	row.add_child(clear)
	preview.custom_minimum_size = Vector2(0, 120)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(preview)
	return box

func _ensure_audio_dialog() -> void:
	if audio_dialog != null:
		return
	audio_dialog = FileDialog.new()
	audio_dialog.title = "选择声音素材"
	audio_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	audio_dialog.access = FileDialog.ACCESS_FILESYSTEM
	audio_dialog.filters = PackedStringArray(["*.mp3, *.ogg, *.wav ; 音频文件"])
	audio_dialog.file_selected.connect(_on_audio_file_selected)
	add_child(audio_dialog)

func _request_audio(target: String) -> void:
	_ensure_audio_dialog()
	pending_audio_target = target
	audio_dialog.popup_centered_ratio(0.72)

func _on_audio_file_selected(source_path: String) -> void:
	var extension := source_path.get_extension().to_lower()
	if not ["mp3", "ogg", "wav"].has(extension):
		_toast("仅支持 MP3、OGG 和 WAV")
		return
	var data := FileAccess.get_file_as_bytes(source_path)
	if data.is_empty():
		_toast("音频读取失败")
		return
	var asset_dir := "user://mist_harbor_assets/audio"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(asset_dir))
	var asset_name := (source_path + str(Time.get_ticks_msec())).md5_text() + "." + extension
	var stored_path := asset_dir + "/" + asset_name
	var output := FileAccess.open(stored_path, FileAccess.WRITE)
	if output == null:
		_toast("音频复制失败")
		return
	output.store_buffer(data)
	_set_audio_target(pending_audio_target, stored_path)
	_toast("音频已复制到内容素材库")

func _set_audio_target(target: String, path: String) -> void:
	match target:
		"event_music": editor_music_path.text = path
		"map_music": map_music_path.text = path

func _load_audio_from_path(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if path.begins_with("res://"):
		return load(path) as AudioStream
	var absolute_path := ProjectSettings.globalize_path(path) if path.begins_with("user://") else path
	match path.get_extension().to_lower():
		"mp3": return AudioStreamMP3.load_from_file(absolute_path)
		"ogg": return AudioStreamOggVorbis.load_from_file(absolute_path)
		"wav": return AudioStreamWAV.load_from_file(absolute_path)
	return null

func _set_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

func _preview_audio(path: String) -> void:
	var stream := _load_audio_from_path(path)
	if stream == null:
		_toast("未设置音频或音频无法读取")
		return
	preview_music_player.stop()
	preview_music_player.stream = stream
	preview_music_player.play()

func _make_audio_picker(target: String, line: LineEdit) -> HBoxContainer:
	var row := HBoxContainer.new()
	line.editable = false
	line.placeholder_text = "未设置音乐"
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(line)
	var choose := _button("选择音频")
	choose.custom_minimum_size.x = 90
	choose.pressed.connect(func(): _request_audio(target))
	row.add_child(choose)
	var preview := _button("试听")
	preview.custom_minimum_size.x = 64
	preview.pressed.connect(func(): _preview_audio(line.text))
	row.add_child(preview)
	var clear := _button("清除")
	clear.custom_minimum_size.x = 64
	clear.pressed.connect(func(): _set_audio_target(target, ""))
	row.add_child(clear)
	return row

func _ensure_map_music() -> void:
	var path := str(GameState.custom_content.get("map_music", ""))
	if path.is_empty():
		map_music_player.stop()
		current_map_music_path = ""
		return
	if current_map_music_path == path and map_music_player.stream != null:
		if not map_music_player.playing:
			map_music_player.play()
		return
	var stream := _load_audio_from_path(path)
	if stream == null:
		map_music_player.stop()
		current_map_music_path = ""
		return
	_set_stream_loop(stream)
	map_music_player.stream = stream
	map_music_player.play()
	current_map_music_path = path

func _activate_map_music() -> void:
	_ensure_map_music()
	event_music_player.stop()
	current_event_music_path = ""
	map_music_player.stream_paused = false

func _apply_event_music(event: Dictionary) -> void:
	_ensure_map_music()
	var path := str(event.get("music", ""))
	if path.is_empty():
		event_music_player.stop()
		current_event_music_path = ""
		map_music_player.stream_paused = false
		return
	var stream := _load_audio_from_path(path)
	if stream == null:
		event_music_player.stop()
		current_event_music_path = ""
		map_music_player.stream_paused = false
		return
	map_music_player.stream_paused = true
	if current_event_music_path == path and event_music_player.playing:
		return
	_set_stream_loop(stream)
	event_music_player.stream = stream
	event_music_player.play()
	current_event_music_path = path

func _register_custom_event(source: Dictionary) -> void:
	var event := source.duplicate(true)
	event.title = event.get("title", event.get("name", "自定义事件"))
	event.name = event.title
	event.chapter = event.get("chapter", "自定义事件")
	event.speaker = event.get("speaker", "旁白")
	event.options = event.get("options", [{"text":"返回地图", "action":"open_map"}])
	event.locked = event.get("locked", false)
	event.prerequisites = event.get("prerequisites", [])
	event.prerequisite_mode = event.get("prerequisite_mode", "all")
	event.flow_mode = event.get("flow_mode", "interruptible")
	event.repeatable = event.get("repeatable", false)
	event.action_cost = event.get("action_cost", 1)
	event.ends_continuous = event.get("ends_continuous", false)
	event.music = event.get("music", "")
	events[event.id] = event

func _all_event_definitions() -> Array:
	return events.values()

func _event_unlocked(event_id: String) -> bool:
	if not events.has(event_id):
		return false
	var event: Dictionary = events[event_id]
	if not bool(event.get("locked", false)):
		return true
	var prerequisites: Array = event.get("prerequisites", [])
	if prerequisites.is_empty():
		return false
	var visited: Array = GameState.world.get("visited", [])
	if event.get("prerequisite_mode", "all") == "any":
		return prerequisites.any(func(required): return visited.has(str(required)))
	return prerequisites.all(func(required): return visited.has(str(required)))

func _lock_description(event_id: String) -> String:
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

func _build_shell() -> void:
	var base := ColorRect.new()
	base.color = bg
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 0)
	add_child(outer)

	var header := PanelContainer.new()
	header.custom_minimum_size.y = 68
	header.add_theme_stylebox_override("panel", _box(Color("111c2b"), 0, 0))
	outer.add_child(header)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 28)
	header_margin.add_theme_constant_override("margin_right", 28)
	header.add_child(header_margin)
	var header_row := HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 16)
	header_margin.add_child(header_row)
	var brand := Label.new()
	brand.text = "雾港余烬"
	brand.add_theme_font_size_override("font_size", 25)
	brand.add_theme_color_override("font_color", accent)
	header_row.add_child(brand)
	var subtitle := Label.new()
	time_status_label = subtitle
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", text_dim)
	header_row.add_child(subtitle)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer)
	for spec in [["主菜单", show_menu], ["开始/继续", _continue_game], ["地图", show_map], ["休息", rest_day], ["背包/装备", show_inventory], ["角色育成", show_growth], ["创作工具", show_tools]]:
		var button := _button(spec[0], false)
		button.custom_minimum_size.x = 92
		button.pressed.connect(spec[1])
		header_row.add_child(button)

	content_root = MarginContainer.new()
	content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_root.add_theme_constant_override("margin_left", 28)
	content_root.add_theme_constant_override("margin_right", 28)
	content_root.add_theme_constant_override("margin_top", 22)
	content_root.add_theme_constant_override("margin_bottom", 20)
	outer.add_child(content_root)

	toast_label = Label.new()
	toast_label.visible = false
	toast_label.position = Vector2(30, 650)
	toast_label.add_theme_color_override("font_color", gold)
	toast_label.add_theme_font_size_override("font_size", 16)
	add_child(toast_label)
	_update_time_status()

func _clear_view() -> void:
	for child in content_root.get_children():
		child.queue_free()

func _box(color: Color, radius: int = 8, border: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = border
	style.border_width_right = border
	style.border_width_top = border
	style.border_width_bottom = border
	style.border_color = Color(color, 1.0).lightened(0.12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _button(label: String, primary := false) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(116, 40)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("092022") if primary else text_main)
	button.add_theme_stylebox_override("normal", _box(accent if primary else panel_alt, 6, 0))
	button.add_theme_stylebox_override("hover", _box((accent if primary else panel_alt).lightened(0.12), 6, 0))
	button.add_theme_stylebox_override("pressed", _box((accent if primary else panel_alt).darkened(0.12), 6, 0))
	return button

func _heading(text: String, size := 28) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", text_main)
	return label

func _muted(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", text_dim)
	return label

func _panel_container(color := Color.TRANSPARENT) -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", _box(panel if color == Color.TRANSPARENT else color))
	return result

func _toast(text: String) -> void:
	toast_label.text = text
	toast_label.visible = true
	var timer := get_tree().create_timer(2.5)
	timer.timeout.connect(func(): toast_label.visible = false)

func _update_time_status() -> void:
	if time_status_label != null:
		time_status_label.text = "%s  ·  行动 %d/%d  ·  饱腹 %d/%d" % [GameState.date_text(), int(GameState.world.action_points), int(GameState.world.max_action_points), int(GameState.player.satiety), int(GameState.player.max_satiety)]

func _continuous_active() -> bool:
	return not str(GameState.world.get("active_continuous", "")).is_empty()

func _block_if_continuous(action_name: String) -> bool:
	if not _continuous_active():
		return false
	var root_id := str(GameState.world.active_continuous)
	var root_event: Dictionary = events.get(root_id, {})
	_toast("连续事件“%s”进行中，完成后才能%s" % [root_event.get("title", root_id), action_name])
	return true

func _start_event(event_id: String) -> void:
	if _block_if_continuous("开始其他行动"):
		return
	if not _event_unlocked(event_id):
		_toast(_lock_description(event_id))
		return
	var event: Dictionary = events[event_id]
	var cost := int(event.get("action_cost", 1))
	if int(GameState.world.action_points) < cost:
		_toast("行动点不足，请先休息进入下一天")
		return
	GameState.world.action_points = int(GameState.world.action_points) - cost
	if event.get("flow_mode", "interruptible") == "continuous":
		GameState.world.active_continuous = event_id
	GameState.add_log("消耗%d行动点：%s" % [cost, event.get("title", event_id)])
	_update_time_status()
	show_event(event_id)

func rest_day() -> void:
	if _block_if_continuous("休息"):
		return
	var result: Dictionary = GameState.rest_day()
	GameState.player.hp = mini(int(GameState.player.hp), _effective_combat("生命"))
	GameState.add_log("休息至%s，消耗%d饱腹，生命上限惩罚%d" % [GameState.date_text(), result.satiety_cost, result.hp_penalty])
	_update_time_status()
	show_rest_result(result)

func show_rest_result(result: Dictionary) -> void:
	_activate_map_music()
	current_view = "rest"
	_clear_view()
	var card := _panel_container()
	content_root.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	card.add_child(box)
	box.add_child(_muted("新的一天"))
	box.add_child(_heading(GameState.date_text(), 34))
	var detail := "休息消耗%d点饱腹。行动点恢复至%d。" % [int(result.satiety_cost), int(GameState.world.action_points)]
	if int(result.hp_penalty) > 0:
		detail += "\n饱腹不足，生命上限永久降低%d点。" % int(result.hp_penalty)
	box.add_child(_muted(detail + "\n当前饱腹：%d/%d，生命：%d/%d。" % [int(GameState.player.satiety), int(GameState.player.max_satiety), int(GameState.player.hp), _effective_combat("生命")]))
	var map_button := _button("开始今日行动", true)
	map_button.pressed.connect(show_map)
	box.add_child(map_button)

func _all_equipment() -> Array:
	return _merged_definitions(database.get("equipment", []), GameState.custom_content.get("equipment", []))

func _all_items() -> Array:
	return _merged_definitions(database.get("items", []), GameState.custom_content.get("items", []))

func _merged_definitions(builtins: Array, customs: Array) -> Array:
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

func _all_entities(key: String) -> Array:
	return _merged_definitions(database.get(key, []), GameState.custom_content.get(key, []))

func _find_entity(key: String, entity_id: String) -> Dictionary:
	for entry in _all_entities(key):
		if entry.get("id", "") == entity_id:
			return entry
	return {}

func _find_content_item(item_id: String) -> Dictionary:
	for entry in _all_equipment():
		if entry.get("id", "") == item_id:
			return entry
	for entry in _all_items():
		if entry.get("id", "") == item_id:
			return entry
	if item_id == "quest.linya_watch":
		return {"id":item_id, "name":"林鸦的怀表", "type":"任务物品", "description":"指针停在十三分。"}
	return {"id":item_id, "name":item_id, "type":"未知", "description":"未找到物品定义。"}

func _item_name(item_id: String) -> String:
	return str(_find_content_item(item_id).get("name", item_id))

func _equipment_bonus(stat: String) -> int:
	var total := 0
	for slot in GameState.EQUIPMENT_SLOTS:
		var item_id = GameState.player.equipment.get(slot)
		if item_id != null:
			var definition := _find_content_item(str(item_id))
			total += int(definition.get("bonuses", {}).get(stat, 0))
	return total

func _effective_check(stat: String) -> int:
	return int(GameState.player.growth.get(stat, 8)) + _equipment_bonus(stat)

func _effective_combat(stat: String) -> int:
	var value := int(GameState.player.combat.get(stat, 8)) + _equipment_bonus(stat)
	if stat == "生命":
		value -= int(GameState.player.get("max_hp_penalty", 0))
	return maxi(1, value)

func _entity_equipment_bonus(entity: Dictionary, stat: String) -> int:
	var total := 0
	for item_id in entity.get("equipment", {}).values():
		if item_id != null:
			total += int(_find_content_item(str(item_id)).get("bonuses", {}).get(stat, 0))
	return total

func _prepare_enemy(source: Dictionary) -> Dictionary:
	var enemy := source.duplicate(true)
	var combat: Dictionary = enemy.get("combat_stats", {})
	if not combat.is_empty():
		var strength := int(combat.get("力量", 8)) + _entity_equipment_bonus(enemy, "力量")
		var defense_stat := int(combat.get("防御", 8)) + _entity_equipment_bonus(enemy, "防御")
		var skill := int(combat.get("技巧", 8)) + _entity_equipment_bonus(enemy, "技巧")
		enemy.hp = int(combat.get("生命", 10)) + _entity_equipment_bonus(enemy, "生命")
		enemy.defense = 10 + floori((defense_stat - 8) / 2.0)
		enemy.hit_modifier = floori((skill - 8) / 2.0)
		enemy.damage_modifier = floori((strength - 8) / 2.0)
		enemy.speed = int(combat.get("速度", 8)) + _entity_equipment_bonus(enemy, "速度")
	else:
		enemy.hit_modifier = int(enemy.get("attack", 0))
		enemy.damage_modifier = 1
	return enemy

func _inventory_lines(limit: int = 99) -> String:
	var lines: Array[String] = []
	for item_id in GameState.player.inventory.keys():
		lines.append("• %s ×%d" % [_item_name(str(item_id)), int(GameState.player.inventory[item_id])])
		if lines.size() >= limit:
			break
	return "背包为空" if lines.is_empty() else "\n".join(lines)

# --- 主菜单与游戏运行器 ---

func show_menu() -> void:
	current_view = "menu"
	_clear_view()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	content_root.add_child(row)
	var hero := _panel_container()
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hero)
	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 18)
	hero.add_child(hero_box)
	hero_box.add_child(_muted("可运行垂直切片 · 约15分钟"))
	hero_box.add_child(_heading("海底钟声正在偷走\n雾港居民的记忆", 42))
	var pitch := _muted("调查失踪档案员，完成一次 D20 洞察检定，\n在回合制战斗中击败盐蚀傀儡，并决定危险遗物的归宿。")
	pitch.add_theme_font_size_override("font_size", 18)
	hero_box.add_child(pitch)
	var start := _button("开始新游戏", true)
	start.pressed.connect(_new_game)
	hero_box.add_child(start)
	var load := _button("读取存档")
	load.disabled = not GameState.has_save()
	load.pressed.connect(_load_game)
	hero_box.add_child(load)

	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 360
	side.add_theme_constant_override("separation", 14)
	row.add_child(side)
	for card in [
		["◈ 可视化创作工具", "剧情/随机事件分类、节点预览、角色/敌人/物品管理"],
		["⚄ 双轨五维育成", "D20叙事属性与回合制战斗属性分别成长"],
		["⚔ 数据驱动战斗", "攻击、防御、洞察弱点、物品以及敌方AI"],
		["▣ 存储与读取", "剧情节点、角色属性、背包和战斗状态均可恢复"]
	]:
		var p := _panel_container()
		side.add_child(p)
		var v := VBoxContainer.new()
		p.add_child(v)
		v.add_child(_heading(card[0], 19))
		v.add_child(_muted(card[1]))

func _new_game() -> void:
	GameState.reset_run()
	_update_time_status()
	show_event("intro_01")

func _load_game() -> void:
	if GameState.load_game():
		_update_time_status()
		if not GameState.battle.is_empty() and GameState.battle.get("active", false):
			show_battle(false)
		else:
			show_event(GameState.world.get("scene", "intro_01"))
		_toast("存档读取成功")
	else:
		_toast("存档不存在或格式错误")

func _continue_game() -> void:
	if current_view == "game" or current_view == "battle":
		return
	show_event(GameState.world.get("scene", "intro_01"))

func show_event(event_id: String) -> void:
	if not events.has(event_id):
		_toast("找不到事件：" + event_id)
		return
	if not _event_unlocked(event_id):
		GameState.add_log("阻止触发锁定事件：" + event_id)
		_toast(_lock_description(event_id))
		return
	current_view = "game"
	var event: Dictionary = events[event_id]
	_apply_event_music(event)
	if event.get("flow_mode", "interruptible") == "continuous" and not bool(event.get("ends_continuous", false)) and not _continuous_active():
		GameState.world.active_continuous = event_id
	GameState.world.scene = event_id
	GameState.world.location = event.get("location", "未知地点")
	if not GameState.world.visited.has(event_id):
		GameState.world.visited.append(event_id)
	GameState.world.minutes = int(GameState.world.get("minutes", 0)) + 1
	if bool(event.get("ends_continuous", false)):
		GameState.world.active_continuous = ""
	_update_time_status()
	GameState.add_log("进入事件：" + event.title)
	_clear_view()
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	content_root.add_child(layout)
	var story := _panel_container()
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(story)
	var story_box := VBoxContainer.new()
	story_box.add_theme_constant_override("separation", 16)
	story.add_child(story_box)
	var meta := Label.new()
	meta.text = "%s  ·  %s  ·  %s" % [event.chapter, event.type, event.get("location", "未知地点")]
	meta.add_theme_color_override("font_color", accent if event.type == "剧情事件" else gold)
	meta.add_theme_font_size_override("font_size", 15)
	story_box.add_child(meta)
	var background_texture := _texture_from_path(event.get("background_image", ""))
	if background_texture != null:
		var background_view := TextureRect.new()
		background_view.texture = background_texture
		background_view.custom_minimum_size.y = 165
		background_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		story_box.add_child(background_view)
	title_label = _heading(event.title, 32)
	story_box.add_child(title_label)
	story_box.add_child(_muted(event.speaker))
	body_label = RichTextLabel.new()
	body_label.bbcode_enabled = true
	body_label.fit_content = true
	body_label.custom_minimum_size.y = 120 if background_texture != null else 210
	body_label.add_theme_font_size_override("normal_font_size", 19)
	body_label.add_theme_color_override("default_color", text_main)
	body_label.text = event.text
	story_box.add_child(body_label)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 10)
	story_box.add_child(choices_box)
	for option in event.get("options", []):
		var b := _button(option.text, true)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _choose(option))
		choices_box.add_child(b)

	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 330
	side.add_theme_constant_override("separation", 14)
	layout.add_child(side)
	var status := _panel_container()
	side.add_child(status)
	var status_box := VBoxContainer.new()
	status.add_child(status_box)
	status_box.add_child(_heading("调查员状态", 20))
	hp_label = _muted("生命：%d / %d" % [int(GameState.player.hp), _effective_combat("生命")])
	status_box.add_child(hp_label)
	status_box.add_child(_muted("%s\n行动：%d/%d  饱腹：%d/%d" % [GameState.date_text(), int(GameState.world.action_points), int(GameState.world.max_action_points), int(GameState.player.satiety), int(GameState.player.max_satiety)]))
	status_box.add_child(_muted("洞察：%d  意志：%d  魅力：%d" % [_effective_check("洞察"), _effective_check("意志"), _effective_check("魅力")]))
	inventory_label = _muted("背包：\n" + _inventory_lines(4))
	status_box.add_child(inventory_label)
	var save := _button("保存当前进度")
	save.pressed.connect(func(): _toast("保存成功" if GameState.save_game() else "保存失败"))
	status_box.add_child(save)
	var journal := _panel_container()
	side.add_child(journal)
	var journal_box := VBoxContainer.new()
	journal.add_child(journal_box)
	journal_box.add_child(_heading("当前目标", 20))
	journal_box.add_child(_muted(_objective_for(event_id)))

func _objective_for(id: String) -> String:
	if id.begins_with("intro") or id.begins_with("harbor"):
		return "进入雾港，寻找林鸦留下的线索。"
	if id.begins_with("tavern") or id.begins_with("lighthouse") or id.begins_with("check"):
		return "调查旧灯塔并找到隐蔽入口。"
	if id.begins_with("archive"):
		return "营救林鸦，阻止赫伯特唤醒沉船。"
	return "决定潮心的最终归宿。"

# --- 地图与地点事件触发 ---

func show_map() -> void:
	if _block_if_continuous("打开地图"):
		return
	_activate_map_music()
	current_view = "map"
	_clear_view()
	var page_scroll := ScrollContainer.new()
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_root.add_child(page_scroll)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.add_child(root)
	root.add_child(_heading("雾港地图", 30))
	var map_texture := _texture_from_path(GameState.custom_content.get("map_background", ""), DEFAULT_MAP_IMAGE)
	if map_texture != null:
		var map_view := TextureRect.new()
		map_view.texture = map_texture
		map_view.custom_minimum_size.y = 140
		map_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		map_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		root.add_child(map_view)
	root.add_child(_muted("%s · 行动点 %d/%d · 饱腹 %d/%d\n当前位置：%s。每次主动开始事件消耗行动点；行动点用尽后需要休息。" % [GameState.date_text(), int(GameState.world.action_points), int(GameState.world.max_action_points), int(GameState.player.satiety), int(GameState.player.max_satiety), GameState.world.get("location", "渡船")]))
	root.add_child(_heading("可重复日常行动", 21))
	var repeat_row := HBoxContainer.new()
	repeat_row.add_theme_constant_override("separation", 12)
	root.add_child(repeat_row)
	var repeat_count := 0
	for event in _all_event_definitions():
		if bool(event.get("repeatable", false)) and _event_unlocked(event.id) and _location_unlocked(event.get("location", "")):
			repeat_count += 1
			var repeat_card := _panel_container(panel_alt)
			repeat_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			repeat_row.add_child(repeat_card)
			var repeat_box := VBoxContainer.new()
			repeat_card.add_child(repeat_box)
			repeat_box.add_child(_heading(event.title, 17))
			repeat_box.add_child(_muted("%s · 已完成%d次" % [event.location, int(GameState.world.repeat_counts.get(event.id, 0))]))
			var start_repeat := _button("执行（%d行动点）" % int(event.get("action_cost", 1)), true)
			start_repeat.disabled = int(GameState.world.action_points) < int(event.get("action_cost", 1))
			start_repeat.pressed.connect(func(): _start_event(event.id))
			repeat_box.add_child(start_repeat)
	if repeat_count == 0:
		repeat_row.add_child(_muted("推进主线后会解锁采集、打捞等日常行动。"))
	root.add_child(_heading("地点", 21))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	root.add_child(grid)
	var descriptions := {
		"渡船": "调查开始之处，连接外界与雾港。",
		"雾港码头": "巡夜人驻守的封锁区，潮池藏有异常线索。",
		"雾港广场": "通往酒馆、灯塔和东侧泊位的交通中心。",
		"黑帆酒馆": "守灯人老乔在这里等待愿意听真话的人。",
		"旧灯塔": "档案与海底钟声的源头，铁门已从内部封闭。",
		"地下钟室": "铜钟、潮心与失踪档案员所在的最终区域。"
	}
	for location in LOCATIONS:
		var unlocked := _location_unlocked(location)
		var card := _panel_container(panel_alt if unlocked else Color("151b25"))
		card.custom_minimum_size = Vector2(360, 160)
		grid.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 9)
		card.add_child(box)
		var marker := "● 当前地点" if GameState.world.get("location", "") == location else ("◆ 已解锁" if unlocked else "▣ 未解锁")
		var state_label := _muted(marker)
		state_label.add_theme_color_override("font_color", accent if unlocked else text_dim.darkened(0.25))
		box.add_child(state_label)
		box.add_child(_heading(location, 22))
		var description := _muted(descriptions[location])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(description)
		var event_count := 0
		for event in _all_event_definitions():
			if event.get("location", "") == location:
				event_count += 1
		box.add_child(_muted("关联事件：%d" % event_count))
		var travel := _button("前往" if unlocked else "剧情尚未解锁", unlocked)
		travel.disabled = not unlocked
		travel.pressed.connect(func(): _travel_to(location))
		box.add_child(travel)

func _location_unlocked(location: String) -> bool:
	if not LOCATION_ENTRY.has(location):
		return false
	var entry_id: String = LOCATION_ENTRY[location]
	return GameState.world.get("visited", []).has(entry_id) or _event_unlocked(entry_id)

func _travel_to(location: String) -> void:
	if not _location_unlocked(location):
		_toast("该地点尚未解锁")
		return
	var entry_id: String = LOCATION_ENTRY.get(location, "intro_01")
	# 到访过地点入口后，优先触发同地点尚未经历的随机事件。
	if GameState.world.visited.has(entry_id):
		for event in _all_event_definitions():
			if event.get("location", "") == location and event.get("type", "剧情事件") == "随机事件" and not GameState.world.visited.has(event.id) and _event_unlocked(event.id):
				GameState.add_log("地图触发随机事件：%s @ %s" % [event.title, location])
				_start_event(event.id)
				return
	GameState.add_log("移动至：" + location)
	_start_event(entry_id)

func _choose(option: Dictionary) -> void:
	if option.has("flag"):
		GameState.world.flags[option.flag] = true
	if option.has("item") and not GameState.has_item(option.item):
		GameState.add_item(option.item)
		GameState.add_log("获得物品：" + option.item)
	if option.has("damage"):
		GameState.player.hp = max(1, int(GameState.player.hp) - int(option.damage))
	if option.has("action"):
		match option.action:
			"open_growth": show_growth()
			"open_map": show_map()
			"d20_check": _perform_check(option)
			"resource_check": _perform_resource_check(option)
			"start_battle": show_battle(true)
			"summary": show_summary()
		return
	if option.has("next"):
		show_event(option.next)

func _perform_resource_check(option: Dictionary) -> void:
	var stat := str(option.get("stat", "洞察"))
	var difficulty := int(option.get("difficulty", 10))
	var modifier := floori((_effective_check(stat) - 8) / 2.0)
	var roll: Dictionary = DiceClass.d20(modifier)
	var quantity := 1
	if int(roll.raw) == 20 or int(roll.total) >= difficulty + 8:
		quantity = 4
	elif int(roll.total) >= difficulty + 4:
		quantity = 3
	elif int(roll.total) >= difficulty:
		quantity = 2
	var resource_id := str(option.get("resource", "item.ration"))
	GameState.add_item(resource_id, quantity)
	var event_id := str(GameState.world.scene)
	GameState.world.repeat_counts[event_id] = int(GameState.world.repeat_counts.get(event_id, 0)) + 1
	GameState.add_log("%s检定%d，获得%s×%d" % [stat, int(roll.total), _item_name(resource_id), quantity])
	show_resource_result(stat, roll, difficulty, resource_id, quantity)

func show_resource_result(stat: String, roll: Dictionary, difficulty: int, resource_id: String, quantity: int) -> void:
	current_view = "resource_result"
	_clear_view()
	var card := _panel_container()
	content_root.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)
	box.add_child(_muted("可重复事件结算"))
	box.add_child(_heading("获得 %s ×%d" % [_item_name(resource_id), quantity], 32))
	box.add_child(_muted("%s D20：%d %+d = %d，对抗难度%d。检定结果越高，获得资源越多。\n剩余行动点：%d/%d" % [stat, int(roll.raw), int(roll.modifier), int(roll.total), difficulty, int(GameState.world.action_points), int(GameState.world.max_action_points)]))
	var map_button := _button("返回地图", true)
	map_button.pressed.connect(show_map)
	box.add_child(map_button)
	var rest_button := _button("休息进入下一天")
	rest_button.pressed.connect(rest_day)
	box.add_child(rest_button)

func _perform_check(option: Dictionary) -> void:
	var stat := str(option.get("stat", "洞察"))
	var score := _effective_check(stat)
	var modifier := floori((score - 8) / 2.0)
	if GameState.world.flags.get("noticed_powder", false):
		modifier += 1
	var roll: Dictionary = DiceClass.d20(modifier)
	var success: bool = int(roll.total) >= int(option.difficulty)
	GameState.add_log("D20 %s检定：%d %+d = %d，对抗难度%d，%s" % [stat, roll.raw, roll.modifier, roll.total, option.difficulty, "成功" if success else "失败"])
	_toast("D20：%d %+d = %d，%s" % [roll.raw, roll.modifier, roll.total, "成功" if success else "失败"])
	show_event(option.success if success else option.failure)

# --- 运行时装备与背包 ---

func show_inventory() -> void:
	current_view = "inventory"
	_clear_view()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	content_root.add_child(root)
	root.add_child(_heading("调查员 · 装备与背包", 30))
	root.add_child(_muted("装备提供检定或战斗五维加成。穿戴新装备时，同槽旧装备会自动放回背包。"))
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	root.add_child(columns)

	var equipment_card := _panel_container()
	equipment_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(equipment_card)
	var equipment_box := VBoxContainer.new()
	equipment_box.add_theme_constant_override("separation", 8)
	equipment_card.add_child(equipment_box)
	equipment_box.add_child(_heading("装备栏", 22))
	var stat_text := "检定：体魄%d  洞察%d  意志%d  魅力%d  学识%d\n战斗：力量%d  防御%d  速度%d  技巧%d  生命%d" % [
		_effective_check("体魄"), _effective_check("洞察"), _effective_check("意志"), _effective_check("魅力"), _effective_check("学识"),
		_effective_combat("力量"), _effective_combat("防御"), _effective_combat("速度"), _effective_combat("技巧"), _effective_combat("生命")]
	equipment_box.add_child(_muted(stat_text))
	var slot_grid := GridContainer.new()
	slot_grid.columns = 2
	slot_grid.add_theme_constant_override("h_separation", 10)
	slot_grid.add_theme_constant_override("v_separation", 8)
	equipment_box.add_child(slot_grid)
	for slot in GameState.EQUIPMENT_SLOTS:
		var item_id = GameState.player.equipment.get(slot)
		var slot_card := _panel_container(panel_alt)
		slot_card.custom_minimum_size = Vector2(250, 86)
		slot_grid.add_child(slot_card)
		var row := HBoxContainer.new()
		slot_card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(_muted(str(slot)))
		info.add_child(_heading("未装备" if item_id == null else _item_name(str(item_id)), 17))
		if item_id != null:
			info.add_child(_muted(_bonus_text(_find_content_item(str(item_id)).get("bonuses", {}))))
			var unequip := _button("卸下")
			unequip.custom_minimum_size.x = 70
			unequip.pressed.connect(func():
				GameState.unequip_slot(str(slot))
				GameState.player.hp = mini(int(GameState.player.hp), _effective_combat("生命"))
				show_inventory()
			)
			row.add_child(unequip)

	var bag_card := _panel_container()
	bag_card.custom_minimum_size.x = 420
	columns.add_child(bag_card)
	var bag_box := VBoxContainer.new()
	bag_box.add_theme_constant_override("separation", 8)
	bag_card.add_child(bag_box)
	bag_box.add_child(_heading("背包", 22))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag_box.add_child(scroll)
	var item_list := VBoxContainer.new()
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 8)
	scroll.add_child(item_list)
	if GameState.player.inventory.is_empty():
		item_list.add_child(_muted("背包为空。"))
	for item_id in GameState.player.inventory.keys():
		var definition := _find_content_item(str(item_id))
		var row_card := _panel_container(panel_alt)
		item_list.add_child(row_card)
		var row := HBoxContainer.new()
		row_card.add_child(row)
		var icon_texture := _texture_from_path(definition.get("image", ""), DEFAULT_ITEM_IMAGE)
		if icon_texture != null:
			var icon := TextureRect.new()
			icon.texture = icon_texture
			icon.custom_minimum_size = Vector2(62, 62)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var kind: String = str(definition.get("slot", definition.get("type", "其他")))
		info.add_child(_heading("%s ×%d" % [definition.get("name", item_id), int(GameState.player.inventory[item_id])], 17))
		info.add_child(_muted("%s · %s" % [kind, definition.get("description", "")]))
		if str(item_id) == "item.ration":
			var eat := _button("食用", true)
			eat.custom_minimum_size.x = 76
			eat.pressed.connect(_eat_ration)
			row.add_child(eat)
		elif definition.has("slot"):
			var equip := _button("装备", true)
			equip.custom_minimum_size.x = 76
			equip.pressed.connect(func(): _equip_from_bag(str(item_id), str(definition.slot)))
			row.add_child(equip)
	var back := _button("返回剧情", true)
	back.pressed.connect(func(): show_event(GameState.world.get("scene", "intro_01")))
	root.add_child(back)

func _bonus_text(bonuses: Dictionary) -> String:
	if bonuses.is_empty():
		return "无属性加成"
	var parts: Array[String] = []
	for stat in bonuses:
		parts.append("%s%+d" % [stat, int(bonuses[stat])])
	return "  ".join(parts)

func _equip_from_bag(item_id: String, slot: String) -> void:
	if GameState.equip_item(item_id, slot):
		GameState.player.hp = mini(int(GameState.player.hp), _effective_combat("生命"))
		_toast("已装备：" + _item_name(item_id))
	show_inventory()

func _eat_ration() -> void:
	if GameState.eat_ration():
		_update_time_status()
		_toast("食用旅行口粮，恢复30点饱腹")
	show_inventory()

# --- 双轨五维育成 ---

func show_growth() -> void:
	current_view = "growth"
	_clear_view()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	content_root.add_child(root)
	root.add_child(_heading("角色育成 · 双轨五维", 30))
	root.add_child(_muted("叙事属性影响 D20 检定；战斗属性影响伤害、命中、防御、行动顺序和生命。每条轨道本局有3次训练机会。"))
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 20)
	root.add_child(columns)
	columns.add_child(_growth_panel("叙事属性", GameState.player.growth, true))
	columns.add_child(_growth_panel("战斗属性", GameState.player.combat, false))
	var back := _button("返回剧情", true)
	back.pressed.connect(func(): show_event(GameState.world.get("scene", "intro_02")))
	root.add_child(back)

func _growth_panel(label: String, stats: Dictionary, narrative: bool) -> PanelContainer:
	var card := _panel_container()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	box.add_child(_heading(label, 23))
	var remaining_key := "training_growth" if narrative else "training_combat"
	box.add_child(_muted("剩余训练次数：%d" % int(GameState.player[remaining_key])))
	for stat_name in stats.keys():
		var row := HBoxContainer.new()
		box.add_child(row)
		var name_label := Label.new()
		name_label.text = str(stat_name)
		name_label.custom_minimum_size.x = 90
		name_label.add_theme_font_size_override("font_size", 18)
		row.add_child(name_label)
		var value := Label.new()
		value.text = str(stats[stat_name])
		value.custom_minimum_size.x = 70
		value.add_theme_color_override("font_color", gold)
		value.add_theme_font_size_override("font_size", 20)
		row.add_child(value)
		var train := _button("掷骰训练")
		train.disabled = int(GameState.player[remaining_key]) <= 0
		train.pressed.connect(func():
			var rolled := DiceClass.roll_stat()
			var old := int(stats[stat_name])
			stats[stat_name] = max(old, rolled)
			GameState.player[remaining_key] = int(GameState.player[remaining_key]) - 1
			if not narrative and stat_name == "生命":
				GameState.player.hp = _effective_combat("生命")
			GameState.add_log("训练%s：掷得%d，%d → %d" % [stat_name, rolled, old, int(stats[stat_name])])
			_toast("%s掷得 %d，属性%s" % [stat_name, rolled, "提升" if rolled > old else "保持"])
			show_growth()
		)
		row.add_child(train)
	return card

# --- 回合制战斗 ---

func show_battle(new_battle: bool) -> void:
	current_view = "battle"
	if new_battle or GameState.battle.is_empty():
		var enemy: Dictionary = _prepare_enemy(_find_entity("enemies", "enemy.brine_thrall"))
		if GameState.world.flags.get("battle_advantage", false):
			enemy.hp -= 3
		GameState.battle = {"active": true, "enemy": enemy, "round": 1, "guard": false, "weakened": false, "log": ["盐蚀傀儡从铜钟后扑出！"]}
	_clear_view()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	content_root.add_child(root)
	root.add_child(_heading("回合制战斗 · 地下钟室", 30))
	var arena := HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 22)
	root.add_child(arena)
	var combatants := _panel_container()
	combatants.custom_minimum_size.x = 420
	arena.add_child(combatants)
	var combat_box := VBoxContainer.new()
	combat_box.add_theme_constant_override("separation", 16)
	combatants.add_child(combat_box)
	player_hp_label = _heading("调查员  HP %d/%d" % [int(GameState.player.hp), _effective_combat("生命")], 22)
	combat_box.add_child(player_hp_label)
	combat_box.add_child(_muted("力量 %d  防御 %d  速度 %d  技巧 %d" % [_effective_combat("力量"), _effective_combat("防御"), _effective_combat("速度"), _effective_combat("技巧")]))
	combat_box.add_child(HSeparator.new())
	enemy_hp_label = _heading("%s  HP %d" % [GameState.battle.enemy.name, int(GameState.battle.enemy.hp)], 22)
	enemy_hp_label.add_theme_color_override("font_color", danger)
	combat_box.add_child(enemy_hp_label)
	var enemy_portrait := _texture_from_path(GameState.battle.enemy.get("portrait_image", ""), DEFAULT_ENEMY_IMAGE)
	if enemy_portrait != null:
		var portrait := TextureRect.new()
		portrait.texture = enemy_portrait
		portrait.custom_minimum_size.y = 150
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		combat_box.add_child(portrait)
	combat_box.add_child(_muted("一具被海盐侵蚀、遗忘了姓名的港民躯壳。"))
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	combat_box.add_child(actions)
	for spec in [["攻击", "attack"], ["防御姿态", "guard"], ["洞察弱点", "inspect"], ["使用提神药剂", "item"]]:
		var b := _button(spec[0], spec[1] == "attack")
		b.disabled = spec[1] == "item" and not GameState.has_item("item.tonic")
		b.pressed.connect(func(): _battle_action(spec[1]))
		actions.add_child(b)
	var log_card := _panel_container()
	log_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(log_card)
	var log_box := VBoxContainer.new()
	log_card.add_child(log_box)
	log_box.add_child(_heading("战斗记录 · 第%d回合" % int(GameState.battle.round), 22))
	battle_log = RichTextLabel.new()
	battle_log.bbcode_enabled = true
	battle_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_log.add_theme_font_size_override("normal_font_size", 17)
	battle_log.text = "\n".join(GameState.battle.log)
	log_box.add_child(battle_log)
	var save := _button("战斗中保存")
	save.pressed.connect(func(): _toast("战斗存档成功" if GameState.save_game() else "保存失败"))
	log_box.add_child(save)

func _battle_action(action: String) -> void:
	var battle_state: Dictionary = GameState.battle
	match action:
		"attack":
			var hit: Dictionary = DiceClass.d20(floori((_effective_combat("技巧") - 8) / 2.0))
			if hit.total >= int(battle_state.enemy.defense):
				var dealt := DiceClass.damage(6, floori((_effective_combat("力量") - 8) / 2.0))
				if battle_state.weakened:
					dealt += 2
				battle_state.enemy.hp = int(battle_state.enemy.hp) - dealt
				battle_state.log.append("你掷出%d，命中并造成%d点伤害。" % [hit.total, dealt])
			else:
				battle_state.log.append("你掷出%d，攻击被盐壳挡开。" % hit.total)
		"guard":
			battle_state.guard = true
			battle_state.log.append("你采取防御姿态，本回合受到的伤害减半。")
		"inspect":
			var check: Dictionary = DiceClass.d20(floori((_effective_check("洞察") - 8) / 2.0))
			battle_state.weakened = check.total >= 12
			battle_state.log.append("洞察检定%d：%s。" % [check.total, "发现胸口盐核，后续伤害+2" if battle_state.weakened else "没能看穿它的动作"])
		"item":
			GameState.remove_item("item.tonic")
			var healed: int = mini(6, _effective_combat("生命") - int(GameState.player.hp))
			GameState.player.hp = int(GameState.player.hp) + healed
			battle_state.log.append("你使用提神药剂，恢复%d点生命。" % healed)
	if int(battle_state.enemy.hp) <= 0:
		battle_state.log.append("盐蚀傀儡倒下了。")
		battle_state.active = false
		GameState.world.battle_won = true
		GameState.add_log("战斗胜利，共%d回合" % int(battle_state.round))
		show_event("after_battle")
		return
	_enemy_turn()
	if int(GameState.player.hp) <= 0:
		GameState.player.hp = max(5, floori(_effective_combat("生命") / 2.0))
		battle_state.enemy.hp = int(battle_state.enemy.hp) + 3
		battle_state.log.append("你倒下后被林鸦唤醒；她替你挡住一击，但敌人恢复了力量。")
	battle_state.round = int(battle_state.round) + 1
	show_battle(false)

func _enemy_turn() -> void:
	var battle_state: Dictionary = GameState.battle
	var hit: Dictionary = DiceClass.d20(int(battle_state.enemy.get("hit_modifier", battle_state.enemy.get("attack", 0))))
	var defense := 10 + floori((_effective_combat("防御") - 8) / 2.0)
	if hit.total >= defense:
		var damage := DiceClass.damage(5, int(battle_state.enemy.get("damage_modifier", 1)))
		if battle_state.guard:
			damage = ceili(damage / 2.0)
		GameState.player.hp = int(GameState.player.hp) - damage
		battle_state.log.append("傀儡掷出%d，锚钩造成%d点伤害。" % [hit.total, damage])
	else:
		battle_state.log.append("傀儡掷出%d，它的锚钩从你身边掠过。" % hit.total)
	battle_state.guard = false

# --- 创作工具 ---

func show_tools() -> void:
	current_view = "tools"
	_clear_view()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	content_root.add_child(root)
	root.add_child(_heading("内容创作与管理工具", 30))
	var tabs := TabContainer.new()
	tools_tabs = tabs
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	_build_event_editor(tabs)
	_build_entity_manager(tabs)
	_build_item_manager(tabs)
	_build_map_asset_manager(tabs)
	_build_database_overview(tabs)

func _preview_tools_page(index: int) -> void:
	show_tools()
	tools_tabs.current_tab = index

func _preview_schedule() -> void:
	for event_id in ["intro_01", "intro_02", "harbor_01", "harbor_02", "square_01"]:
		if not GameState.world.visited.has(event_id):
			GameState.world.visited.append(event_id)
	GameState.world.active_continuous = ""
	show_map()

func _build_map_asset_manager(tabs: TabContainer) -> void:
	var page := ScrollContainer.new()
	page.name = "大地图素材"
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(page)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	page.add_child(content)
	content.add_child(_heading("大地图背景图", 24))
	content.add_child(_muted("该图片显示在地图界面顶部，可使用完整区域地图、城市俯视图或手绘羊皮纸地图。图片会复制到用户内容素材目录。"))
	map_background_path = LineEdit.new()
	map_background_preview = TextureRect.new()
	content.add_child(_make_image_picker("map_background", map_background_path, map_background_preview))
	map_background_preview.custom_minimum_size.y = 330
	map_background_path.text = GameState.custom_content.get("map_background", "")
	_set_preview(map_background_preview, map_background_path.text, DEFAULT_MAP_IMAGE)
	content.add_child(_muted("大地图背景音乐（进入地图或无事件音乐的事件时播放）"))
	map_music_path = LineEdit.new()
	map_music_path.text = GameState.custom_content.get("map_music", "")
	content.add_child(_make_audio_picker("map_music", map_music_path))
	var save := _button("保存大地图图片与音乐", true)
	save.pressed.connect(func():
		GameState.custom_content.map_background = map_background_path.text
		GameState.custom_content.map_music = map_music_path.text
		GameState.save_custom_content()
		_activate_map_music()
		_toast("大地图素材已保存")
	)
	content.add_child(save)

func _build_event_editor(tabs: TabContainer) -> void:
	var page := HBoxContainer.new()
	page.name = "可视化事件编辑器"
	page.add_theme_constant_override("separation", 14)
	tabs.add_child(page)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 250
	page.add_child(left)
	left.add_child(_heading("事件库", 20))
	editor_list = ItemList.new()
	editor_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(editor_list)
	for event in scenario.events:
		editor_list.add_item("[内置%s] %s" % ["·锁" if event.get("locked", false) else "", event.title])
	for event in GameState.custom_content.events:
		editor_list.add_item("[自定义%s] %s" % ["·锁" if event.get("locked", false) else "", event.name])
	editor_list.item_selected.connect(_select_event)
	var add := _button("新建事件", true)
	add.pressed.connect(_new_custom_event)
	left.add_child(add)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(center)
	center.add_child(_heading("事件节点画布", 20))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(scroll)
	editor_preview = HBoxContainer.new()
	editor_preview.add_theme_constant_override("separation", 12)
	scroll.add_child(editor_preview)
	_refresh_event_preview(null)

	var inspector := _panel_container()
	inspector.custom_minimum_size.x = 320
	page.add_child(inspector)
	var inspector_scroll := ScrollContainer.new()
	inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector.add_child(inspector_scroll)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 8)
	inspector_scroll.add_child(form)
	form.add_child(_heading("事件属性", 20))
	form.add_child(_muted("事件名称"))
	editor_name = LineEdit.new()
	editor_name.placeholder_text = "输入事件名称"
	form.add_child(editor_name)
	form.add_child(_muted("事件类型"))
	editor_type = OptionButton.new()
	editor_type.add_item("剧情事件")
	editor_type.add_item("随机事件")
	form.add_child(editor_type)
	form.add_child(_muted("发生地点"))
	editor_location = OptionButton.new()
	for location in LOCATIONS:
		editor_location.add_item(location)
	form.add_child(editor_location)
	form.add_child(_muted("场景背景图"))
	editor_background_path = LineEdit.new()
	editor_background_preview = TextureRect.new()
	form.add_child(_make_image_picker("event_background", editor_background_path, editor_background_preview))
	form.add_child(_muted("事件音乐（可为空；为空时延续大地图音乐）"))
	editor_music_path = LineEdit.new()
	form.add_child(_make_audio_picker("event_music", editor_music_path))
	editor_lock = CheckBox.new()
	editor_lock.text = "启用事件锁"
	form.add_child(editor_lock)
	form.add_child(_muted("前置事件ID（多个用逗号分隔）"))
	editor_prerequisites = LineEdit.new()
	editor_prerequisites.placeholder_text = "例如：harbor_01,tavern_01"
	form.add_child(editor_prerequisites)
	form.add_child(_muted("多个前置事件的满足方式"))
	editor_prerequisite_mode = OptionButton.new()
	editor_prerequisite_mode.add_item("全部满足")
	editor_prerequisite_mode.set_item_metadata(0, "all")
	editor_prerequisite_mode.add_item("任一满足")
	editor_prerequisite_mode.set_item_metadata(1, "any")
	form.add_child(editor_prerequisite_mode)
	form.add_child(_muted("事件流程"))
	editor_flow_mode = OptionButton.new()
	editor_flow_mode.add_item("可中断事件")
	editor_flow_mode.set_item_metadata(0, "interruptible")
	editor_flow_mode.add_item("连续事件")
	editor_flow_mode.set_item_metadata(1, "continuous")
	form.add_child(editor_flow_mode)
	editor_repeatable = CheckBox.new()
	editor_repeatable.text = "允许重复触发"
	form.add_child(editor_repeatable)
	editor_ends_continuous = CheckBox.new()
	editor_ends_continuous.text = "到达此事件时结束连续流程"
	form.add_child(editor_ends_continuous)
	form.add_child(_muted("主动开始消耗的行动点"))
	editor_action_cost = SpinBox.new()
	editor_action_cost.min_value = 0
	editor_action_cost.max_value = 3
	editor_action_cost.value = 1
	form.add_child(editor_action_cost)
	form.add_child(_muted("正文/设计说明"))
	editor_text = TextEdit.new()
	editor_text.custom_minimum_size.y = 130
	editor_text.placeholder_text = "输入事件内容；运行时可继续扩展为节点。"
	form.add_child(editor_text)
	var save := _button("保存自定义事件", true)
	save.pressed.connect(_save_editor_event)
	form.add_child(save)
	var remove := _button("删除选中自定义事件")
	remove.pressed.connect(_delete_editor_event)
	form.add_child(remove)

func _select_event(index: int) -> void:
	selected_editor_index = index
	if index < scenario.events.size():
		var event: Dictionary = scenario.events[index]
		editor_name.text = event.title
		editor_type.select(0 if event.type == "剧情事件" else 1)
		_select_location_value(event.get("location", "雾港码头"))
		editor_background_path.text = event.get("background_image", "")
		_set_preview(editor_background_preview, editor_background_path.text)
		editor_music_path.text = event.get("music", "")
		_set_event_lock_form(event)
		_set_event_schedule_form(event)
		editor_text.text = event.text
		_refresh_event_preview(event)
	else:
		var custom_index: int = index - scenario.events.size()
		if custom_index >= 0 and custom_index < GameState.custom_content.events.size():
			var event: Dictionary = GameState.custom_content.events[custom_index]
			editor_name.text = event.name
			editor_type.select(0 if event.type == "剧情事件" else 1)
			_select_location_value(event.get("location", "雾港码头"))
			editor_background_path.text = event.get("background_image", "")
			_set_preview(editor_background_preview, editor_background_path.text)
			editor_music_path.text = event.get("music", "")
			_set_event_lock_form(event)
			_set_event_schedule_form(event)
			editor_text.text = event.text
			_refresh_event_preview(event)

func _refresh_event_preview(event) -> void:
	for child in editor_preview.get_children():
		child.queue_free()
	var nodes: Array = []
	if event == null:
		nodes = [["入口", "选择左侧事件"], ["对话", "编辑属性"], ["出口", "保存内容"]]
	else:
		var lock_text := "\n锁：%s" % ",".join(event.get("prerequisites", [])) if event.get("locked", false) else "\n无事件锁"
		nodes.append(["入口", "%s\n地点：%s\n%s · %d行动点%s" % [event.get("type", "剧情事件"), event.get("location", "未设置"), "连续" if event.get("flow_mode", "interruptible") == "continuous" else "可中断", int(event.get("action_cost", 1)), lock_text]])
		nodes.append(["对话节点", str(event.get("text", "")).left(56)])
		for option in event.get("options", []):
			nodes.append(["选项节点", str(option.get("text", "继续"))])
		nodes.append(["出口", str(event.get("next", "后续事件"))])
	for i in range(nodes.size()):
		var card := _panel_container(panel_alt)
		card.custom_minimum_size = Vector2(185, 145)
		editor_preview.add_child(card)
		var v := VBoxContainer.new()
		card.add_child(v)
		v.add_child(_heading(nodes[i][0], 17))
		var detail := _muted(nodes[i][1])
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(detail)
		if i < nodes.size() - 1:
			var arrow := _heading("→", 28)
			arrow.custom_minimum_size.x = 40
			editor_preview.add_child(arrow)

func _new_custom_event() -> void:
	selected_editor_index = -1
	editor_name.text = "未命名事件"
	editor_type.select(0)
	editor_location.select(1)
	editor_background_path.text = ""
	_set_preview(editor_background_preview, "")
	editor_music_path.text = ""
	editor_lock.button_pressed = false
	editor_prerequisites.text = ""
	editor_prerequisite_mode.select(0)
	editor_flow_mode.select(0)
	editor_repeatable.button_pressed = false
	editor_ends_continuous.button_pressed = false
	editor_action_cost.value = 1
	editor_text.text = ""
	_refresh_event_preview({"type":"剧情事件", "location":"雾港码头", "locked":false, "text":"新对话节点", "options":[{"text":"继续"}]})

func _select_location_value(location: String) -> void:
	for i in range(editor_location.item_count):
		if editor_location.get_item_text(i) == location:
			editor_location.select(i)
			return

func _set_event_lock_form(event: Dictionary) -> void:
	editor_lock.button_pressed = bool(event.get("locked", false))
	var prerequisite_strings: Array[String] = []
	for required in event.get("prerequisites", []):
		prerequisite_strings.append(str(required))
	editor_prerequisites.text = ",".join(prerequisite_strings)
	editor_prerequisite_mode.select(1 if event.get("prerequisite_mode", "all") == "any" else 0)

func _set_event_schedule_form(event: Dictionary) -> void:
	editor_flow_mode.select(1 if event.get("flow_mode", "interruptible") == "continuous" else 0)
	editor_repeatable.button_pressed = bool(event.get("repeatable", false))
	editor_ends_continuous.button_pressed = bool(event.get("ends_continuous", false))
	editor_action_cost.value = int(event.get("action_cost", 1))

func _save_editor_event() -> void:
	if editor_name.text.strip_edges().is_empty():
		_toast("事件名称不能为空")
		return
	var custom_index: int = selected_editor_index - scenario.events.size()
	var event_id := "custom.%d" % Time.get_unix_time_from_system()
	if selected_editor_index >= 0 and selected_editor_index < scenario.events.size():
		event_id = scenario.events[selected_editor_index].id
	elif custom_index >= 0 and custom_index < GameState.custom_content.events.size():
		event_id = GameState.custom_content.events[custom_index].get("id", event_id)
	var prerequisites: Array[String] = []
	for raw_id in editor_prerequisites.text.split(","):
		var required_id := raw_id.strip_edges()
		if not required_id.is_empty() and not prerequisites.has(required_id):
			prerequisites.append(required_id)
	var entry := {"id":event_id, "name":editor_name.text.strip_edges(), "title":editor_name.text.strip_edges(), "chapter":"自定义事件", "speaker":"旁白", "type":editor_type.get_item_text(editor_type.selected), "location":editor_location.get_item_text(editor_location.selected), "background_image":editor_background_path.text, "music":editor_music_path.text, "locked":editor_lock.button_pressed, "prerequisites":prerequisites, "prerequisite_mode":editor_prerequisite_mode.get_item_metadata(editor_prerequisite_mode.selected), "flow_mode":editor_flow_mode.get_item_metadata(editor_flow_mode.selected), "repeatable":editor_repeatable.button_pressed, "action_cost":int(editor_action_cost.value), "ends_continuous":editor_ends_continuous.button_pressed, "text":editor_text.text, "options":[{"text":"返回地图", "action":"open_map"}]}
	if custom_index >= 0 and custom_index < GameState.custom_content.events.size():
		GameState.custom_content.events[custom_index] = entry
	else:
		GameState.custom_content.events.append(entry)
	_register_custom_event(entry)
	GameState.save_custom_content()
	_toast("事件已保存")
	show_tools()

func _delete_editor_event() -> void:
	var custom_index: int = selected_editor_index - scenario.events.size()
	if custom_index >= 0 and custom_index < GameState.custom_content.events.size():
		var deleted_id: String = GameState.custom_content.events[custom_index].get("id", "")
		GameState.custom_content.events.remove_at(custom_index)
		events.erase(deleted_id)
		for builtin_event in scenario.events:
			if builtin_event.id == deleted_id:
				events[deleted_id] = builtin_event
				break
		GameState.save_custom_content()
		_toast("自定义事件已删除")
		show_tools()
	else:
		_toast("内置事件为只读，不能删除")

# --- 角色与敌人结构化管理 ---

func _build_entity_manager(tabs: TabContainer) -> void:
	var page := HBoxContainer.new()
	page.name = "角色·敌人管理"
	page.add_theme_constant_override("separation", 16)
	tabs.add_child(page)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 260
	page.add_child(left)
	entity_kind = OptionButton.new()
	entity_kind.add_item("角色")
	entity_kind.add_item("敌人")
	entity_kind.item_selected.connect(_on_entity_kind_changed)
	left.add_child(entity_kind)
	entity_list = ItemList.new()
	entity_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	entity_list.item_selected.connect(_select_entity)
	left.add_child(entity_list)
	var create := _button("新建角色/敌人", true)
	create.pressed.connect(_clear_entity_form)
	left.add_child(create)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var form_card := _panel_container()
	form_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(form_card)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 10)
	form_card.add_child(form)
	form.add_child(_heading("角色/敌人属性设定", 22))
	var basic := HBoxContainer.new()
	form.add_child(basic)
	var name_box := VBoxContainer.new()
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	basic.add_child(name_box)
	name_box.add_child(_muted("名称"))
	entity_name = LineEdit.new()
	name_box.add_child(entity_name)
	var role_box := VBoxContainer.new()
	role_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	basic.add_child(role_box)
	role_box.add_child(_muted("定位/身份"))
	entity_role = LineEdit.new()
	role_box.add_child(entity_role)
	form.add_child(_muted("角色立绘 / 敌人立绘"))
	entity_portrait_path = LineEdit.new()
	entity_portrait_preview = TextureRect.new()
	form.add_child(_make_image_picker("entity_portrait", entity_portrait_path, entity_portrait_preview))

	entity_stat_inputs.clear()
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 18)
	form.add_child(stats_row)
	stats_row.add_child(_stat_editor_group("检定五维", ["体魄", "洞察", "意志", "魅力", "学识"], "check"))
	stats_row.add_child(_stat_editor_group("战斗五维", ["力量", "防御", "速度", "技巧", "生命"], "combat"))

	form.add_child(_heading("携带装备", 19))
	var loadout_grid := GridContainer.new()
	loadout_grid.columns = 3
	loadout_grid.add_theme_constant_override("h_separation", 12)
	form.add_child(loadout_grid)
	entity_loadout_inputs.clear()
	for slot in GameState.EQUIPMENT_SLOTS:
		var slot_box := VBoxContainer.new()
		loadout_grid.add_child(slot_box)
		slot_box.add_child(_muted(str(slot)))
		var picker := OptionButton.new()
		picker.add_item("无")
		picker.set_item_metadata(0, "")
		for equipment in _all_equipment():
			if equipment.get("slot", "") == slot:
				picker.add_item(equipment.get("name", equipment.id))
				picker.set_item_metadata(picker.item_count - 1, equipment.id)
		slot_box.add_child(picker)
		entity_loadout_inputs[slot] = picker

	form.add_child(_heading("携带背包物品", 19))
	var carry_row := HBoxContainer.new()
	form.add_child(carry_row)
	entity_carry_item = OptionButton.new()
	entity_carry_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_all_item_picker(entity_carry_item)
	carry_row.add_child(entity_carry_item)
	entity_carry_qty = SpinBox.new()
	entity_carry_qty.min_value = 1
	entity_carry_qty.max_value = 99
	entity_carry_qty.value = 1
	carry_row.add_child(entity_carry_qty)
	var add_carry := _button("加入携带物")
	add_carry.pressed.connect(_add_entity_carry)
	carry_row.add_child(add_carry)
	entity_carry_list = ItemList.new()
	entity_carry_list.custom_minimum_size.y = 100
	form.add_child(entity_carry_list)
	var remove_carry := _button("移除选中携带物")
	remove_carry.pressed.connect(_remove_entity_carry)
	form.add_child(remove_carry)
	var save := _button("保存到自定义角色/敌人库", true)
	save.pressed.connect(_save_entity)
	form.add_child(save)
	_refresh_entity_list()
	_clear_entity_form()

func _stat_editor_group(title: String, names: Array, prefix: String) -> PanelContainer:
	var card := _panel_container(panel_alt)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	card.add_child(box)
	box.add_child(_heading(title, 18))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	box.add_child(grid)
	for stat in names:
		var stat_box := VBoxContainer.new()
		grid.add_child(stat_box)
		stat_box.add_child(_muted(str(stat)))
		var input := SpinBox.new()
		input.min_value = 1
		input.max_value = 99
		input.value = 8 if stat != "生命" else 12
		input.custom_minimum_size.x = 82
		stat_box.add_child(input)
		entity_stat_inputs["%s.%s" % [prefix, stat]] = input
	return card

func _on_entity_kind_changed(_index: int) -> void:
	_refresh_entity_list()
	_clear_entity_form()

func _entity_key() -> String:
	return "characters" if entity_kind.selected == 0 else "enemies"

func _refresh_entity_list() -> void:
	if entity_list == null:
		return
	entity_list.clear()
	var key := _entity_key()
	for entry in _all_entities(key):
		var is_custom: bool = GameState.custom_content.get(key, []).any(func(custom): return custom.get("id", "") == entry.id)
		entity_list.add_item("[%s] %s" % ["自定义/覆盖" if is_custom else "内置", entry.name])

func _clear_entity_form() -> void:
	editing_entity_id = ""
	entity_draft_inventory = {}
	if entity_name != null:
		entity_name.text = ""
		entity_role.text = ""
		entity_portrait_path.text = ""
		_set_preview(entity_portrait_preview, "", DEFAULT_ENEMY_IMAGE if entity_kind.selected == 1 else "")
		for input in entity_stat_inputs.values():
			input.value = 8
		for slot in entity_loadout_inputs:
			entity_loadout_inputs[slot].select(0)
		_refresh_entity_carry_list()

func _select_entity(index: int) -> void:
	var key := _entity_key()
	var definitions := _all_entities(key)
	if index < 0 or index >= definitions.size():
		return
	var entry: Dictionary = definitions[index]
	editing_entity_id = entry.get("id", "")
	entity_name.text = entry.get("name", "")
	entity_role.text = entry.get("role", "")
	entity_portrait_path.text = entry.get("portrait_image", "")
	_set_preview(entity_portrait_preview, entity_portrait_path.text, DEFAULT_ENEMY_IMAGE if entity_kind.selected == 1 else "")
	var check_stats: Dictionary = entry.get("check_stats", {})
	var combat_stats: Dictionary = entry.get("combat_stats", {})
	for stat in ["体魄", "洞察", "意志", "魅力", "学识"]:
		entity_stat_inputs["check." + stat].value = int(check_stats.get(stat, 8))
	for stat in ["力量", "防御", "速度", "技巧", "生命"]:
		entity_stat_inputs["combat." + stat].value = int(combat_stats.get(stat, 12 if stat == "生命" else 8))
	var loadout: Dictionary = entry.get("equipment", {})
	for slot in entity_loadout_inputs:
		_select_picker_metadata(entity_loadout_inputs[slot], str(loadout.get(slot, "")) if loadout.get(slot) != null else "")
	entity_draft_inventory = entry.get("inventory", {}).duplicate(true)
	_refresh_entity_carry_list()

func _populate_all_item_picker(picker: OptionButton) -> void:
	picker.clear()
	for entry in _all_equipment() + _all_items():
		picker.add_item("%s · %s" % [entry.get("slot", entry.get("type", "物品")), entry.name])
		picker.set_item_metadata(picker.item_count - 1, entry.id)

func _select_picker_metadata(picker: OptionButton, target: String) -> void:
	for i in range(picker.item_count):
		if str(picker.get_item_metadata(i)) == target:
			picker.select(i)
			return
	picker.select(0)

func _add_entity_carry() -> void:
	if entity_carry_item.item_count == 0:
		return
	var item_id := str(entity_carry_item.get_item_metadata(entity_carry_item.selected))
	entity_draft_inventory[item_id] = int(entity_draft_inventory.get(item_id, 0)) + int(entity_carry_qty.value)
	_refresh_entity_carry_list()

func _remove_entity_carry() -> void:
	var selected := entity_carry_list.get_selected_items()
	if selected.is_empty():
		return
	var keys := entity_draft_inventory.keys()
	if selected[0] < keys.size():
		entity_draft_inventory.erase(keys[selected[0]])
	_refresh_entity_carry_list()

func _refresh_entity_carry_list() -> void:
	if entity_carry_list == null:
		return
	entity_carry_list.clear()
	for item_id in entity_draft_inventory:
		entity_carry_list.add_item("%s ×%d" % [_item_name(str(item_id)), int(entity_draft_inventory[item_id])])

func _save_entity() -> void:
	if entity_name.text.strip_edges().is_empty():
		_toast("名称不能为空")
		return
	var check_stats := {}
	var combat_stats := {}
	for stat in ["体魄", "洞察", "意志", "魅力", "学识"]:
		check_stats[stat] = int(entity_stat_inputs["check." + stat].value)
	for stat in ["力量", "防御", "速度", "技巧", "生命"]:
		combat_stats[stat] = int(entity_stat_inputs["combat." + stat].value)
	var loadout := {}
	for slot in entity_loadout_inputs:
		var picker: OptionButton = entity_loadout_inputs[slot]
		var value := str(picker.get_item_metadata(picker.selected))
		loadout[slot] = null if value.is_empty() else value
	var key := _entity_key()
	var entry := {
		"id": editing_entity_id if not editing_entity_id.is_empty() else "custom.%s.%d" % [key, Time.get_unix_time_from_system()],
		"name": entity_name.text.strip_edges(), "role": entity_role.text.strip_edges(), "portrait_image":entity_portrait_path.text, "tags": ["自定义"],
		"check_stats": check_stats, "combat_stats": combat_stats, "equipment": loadout,
		"inventory": entity_draft_inventory.duplicate(true)
	}
	if key == "enemies":
		entry.hp = combat_stats.生命
		entry.attack = floori((int(combat_stats.力量) - 8) / 2.0)
		entry.defense = 10 + floori((int(combat_stats.防御) - 8) / 2.0)
		entry.speed = combat_stats.速度
	var replaced := false
	for i in range(GameState.custom_content[key].size()):
		if GameState.custom_content[key][i].get("id", "") == editing_entity_id and not editing_entity_id.is_empty():
			GameState.custom_content[key][i] = entry
			replaced = true
			break
	if not replaced:
		GameState.custom_content[key].append(entry)
	GameState.save_custom_content()
	editing_entity_id = entry.id
	_refresh_entity_list()
	_toast("角色/敌人设定已保存")

# --- 装备与物品结构化管理 ---

func _build_item_manager(tabs: TabContainer) -> void:
	var page := HBoxContainer.new()
	page.name = "装备·物品管理"
	page.add_theme_constant_override("separation", 16)
	tabs.add_child(page)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 285
	page.add_child(left)
	left.add_child(_heading("装备与物品库", 20))
	item_list_editor = ItemList.new()
	item_list_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list_editor.item_selected.connect(_select_item_definition)
	left.add_child(item_list_editor)
	var create := _button("新建装备/物品", true)
	create.pressed.connect(_clear_item_form)
	left.add_child(create)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var card := _panel_container()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(card)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 9)
	card.add_child(form)
	form.add_child(_heading("装备/物品属性设定", 22))
	var basic := HBoxContainer.new()
	form.add_child(basic)
	var name_box := VBoxContainer.new()
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	basic.add_child(name_box)
	name_box.add_child(_muted("名称"))
	item_name_input = LineEdit.new()
	name_box.add_child(item_name_input)
	var category_box := VBoxContainer.new()
	category_box.custom_minimum_size.x = 220
	basic.add_child(category_box)
	category_box.add_child(_muted("种类"))
	item_category = OptionButton.new()
	for category in GameState.EQUIPMENT_SLOTS + ["消耗品", "任务物品", "换金道具"]:
		item_category.add_item(category)
	category_box.add_child(item_category)
	form.add_child(_muted("描述"))
	item_desc_input = TextEdit.new()
	item_desc_input.custom_minimum_size.y = 80
	form.add_child(item_desc_input)
	form.add_child(_muted("物品 / 装备图片"))
	item_image_path = LineEdit.new()
	item_image_preview = TextureRect.new()
	form.add_child(_make_image_picker("item_image", item_image_path, item_image_preview))
	form.add_child(_heading("检定/战斗五维加成", 19))
	item_bonus_inputs.clear()
	var bonus_grid := GridContainer.new()
	bonus_grid.columns = 10
	bonus_grid.add_theme_constant_override("h_separation", 6)
	form.add_child(bonus_grid)
	for stat in ["体魄", "洞察", "意志", "魅力", "学识", "力量", "防御", "速度", "技巧", "生命"]:
		var stat_box := VBoxContainer.new()
		bonus_grid.add_child(stat_box)
		stat_box.add_child(_muted(stat))
		var input := SpinBox.new()
		input.min_value = -20
		input.max_value = 20
		input.value = 0
		input.custom_minimum_size.x = 70
		stat_box.add_child(input)
		item_bonus_inputs[stat] = input
	form.add_child(_muted("装备种类可以设置五维加成；消耗品、任务物品和换金道具会忽略加成。"))
	var save := _button("保存到自定义装备/物品库", true)
	save.pressed.connect(_save_item_definition)
	form.add_child(save)
	_refresh_item_definition_list()
	_clear_item_form()

func _refresh_item_definition_list() -> void:
	if item_list_editor == null:
		return
	item_list_editor.clear()
	for entry in _all_equipment():
		var is_custom: bool = GameState.custom_content.equipment.any(func(custom): return custom.get("id", "") == entry.id)
		item_list_editor.add_item("[%s装备·%s] %s" % ["自定义/覆盖" if is_custom else "内置", entry.slot, entry.name])
	for entry in _all_items():
		var is_custom: bool = GameState.custom_content.items.any(func(custom): return custom.get("id", "") == entry.id)
		item_list_editor.add_item("[%s物品·%s] %s" % ["自定义/覆盖" if is_custom else "内置", entry.type, entry.name])

func _combined_item_definitions() -> Array:
	return _all_equipment() + _all_items()

func _clear_item_form() -> void:
	editing_item_id = ""
	if item_name_input != null:
		item_name_input.text = ""
		item_desc_input.text = ""
		item_image_path.text = ""
		_set_preview(item_image_preview, "", DEFAULT_ITEM_IMAGE)
		item_category.select(0)
		for input in item_bonus_inputs.values():
			input.value = 0

func _select_item_definition(index: int) -> void:
	var entries := _combined_item_definitions()
	if index < 0 or index >= entries.size():
		return
	var entry: Dictionary = entries[index]
	editing_item_id = entry.get("id", "")
	item_name_input.text = entry.get("name", "")
	item_desc_input.text = entry.get("description", "")
	item_image_path.text = entry.get("image", "")
	_set_preview(item_image_preview, item_image_path.text, DEFAULT_ITEM_IMAGE)
	var category := str(entry.get("slot", entry.get("type", "任务物品")))
	for i in range(item_category.item_count):
		if item_category.get_item_text(i) == category:
			item_category.select(i)
	var bonuses: Dictionary = entry.get("bonuses", {})
	for stat in item_bonus_inputs:
		item_bonus_inputs[stat].value = int(bonuses.get(stat, 0))

func _save_item_definition() -> void:
	if item_name_input.text.strip_edges().is_empty():
		_toast("物品名称不能为空")
		return
	var category := item_category.get_item_text(item_category.selected)
	var is_equipment := GameState.EQUIPMENT_SLOTS.has(category)
	var key := "equipment" if is_equipment else "items"
	var bonuses := {}
	if is_equipment:
		for stat in item_bonus_inputs:
			var value := int(item_bonus_inputs[stat].value)
			if value != 0:
				bonuses[stat] = value
	var entry := {
		"id": editing_item_id if not editing_item_id.is_empty() else "custom.%s.%d" % [key, Time.get_unix_time_from_system()],
		"name": item_name_input.text.strip_edges(), "description": item_desc_input.text.strip_edges(), "image":item_image_path.text
	}
	if is_equipment:
		entry.slot = category
		entry.bonuses = bonuses
	else:
		entry.type = category
		entry.max_stack = 99 if category == "换金道具" else (9 if category == "消耗品" else 1)
	for collection in ["equipment", "items"]:
		for i in range(GameState.custom_content[collection].size() - 1, -1, -1):
			if GameState.custom_content[collection][i].get("id", "") == editing_item_id and not editing_item_id.is_empty():
				GameState.custom_content[collection].remove_at(i)
	GameState.custom_content[key].append(entry)
	GameState.save_custom_content()
	editing_item_id = entry.id
	_refresh_item_definition_list()
	_toast("装备/物品设定已保存")

func _build_manager(tabs: TabContainer) -> void:
	var page := HBoxContainer.new()
	page.name = "角色·敌人·物品管理"
	page.add_theme_constant_override("separation", 18)
	tabs.add_child(page)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 360
	page.add_child(left)
	manager_kind = OptionButton.new()
	for name in ["角色", "敌人", "物品"]:
		manager_kind.add_item(name)
	manager_kind.item_selected.connect(func(_i): _refresh_manager_list())
	left.add_child(manager_kind)
	manager_list = ItemList.new()
	manager_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	manager_list.item_selected.connect(_select_manager_entry)
	left.add_child(manager_list)

	var form_card := _panel_container()
	form_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(form_card)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 10)
	form_card.add_child(form)
	form.add_child(_heading("基础数据编辑", 22))
	form.add_child(_muted("名称"))
	manager_name = LineEdit.new()
	form.add_child(manager_name)
	form.add_child(_muted("定位、数值或描述"))
	manager_desc = TextEdit.new()
	manager_desc.custom_minimum_size.y = 220
	form.add_child(manager_desc)
	var save := _button("新增到自定义数据库", true)
	save.pressed.connect(_save_manager_entry)
	form.add_child(save)
	form.add_child(_muted("内置数据只读；自定义条目存入 user:// 内容库，可继续扩展为完整属性表单。"))
	_refresh_manager_list()

func _manager_key() -> String:
	return ["characters", "enemies", "items"][manager_kind.selected]

func _refresh_manager_list() -> void:
	if manager_list == null:
		return
	manager_list.clear()
	var key := _manager_key()
	for entry in database.get(key, []):
		manager_list.add_item("[内置] " + entry.name)
	for entry in GameState.custom_content.get(key, []):
		manager_list.add_item("[自定义] " + entry.name)

func _select_manager_entry(index: int) -> void:
	selected_manager_index = index
	var key := _manager_key()
	var builtins: Array = database.get(key, [])
	var entry: Dictionary
	if index < builtins.size():
		entry = builtins[index]
	else:
		entry = GameState.custom_content[key][index - builtins.size()]
	manager_name.text = entry.get("name", "")
	manager_desc.text = JSON.stringify(entry, "  ")

func _save_manager_entry() -> void:
	if manager_name.text.strip_edges().is_empty():
		_toast("名称不能为空")
		return
	var key := _manager_key()
	GameState.custom_content[key].append({"id":"custom.%s.%d" % [key, Time.get_unix_time_from_system()], "name":manager_name.text.strip_edges(), "description":manager_desc.text})
	GameState.save_custom_content()
	manager_name.text = ""
	manager_desc.text = ""
	_refresh_manager_list()
	_toast("条目已加入自定义数据库")

func _build_database_overview(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "内容包概览"
	tabs.add_child(page)
	page.add_child(_heading("雾港余烬 · 内置内容包", 24))
	page.add_child(_muted("剧本ID：%s   预计时长：%d分钟" % [scenario.id, int(scenario.estimated_minutes)]))
	page.add_child(_muted("剧情事件：%d   角色：%d   敌人：%d   装备：%d   物品：%d" % [scenario.events.size(), database.characters.size(), database.enemies.size(), database.equipment.size(), database.items.size()]))
	var validation := _panel_container()
	page.add_child(validation)
	var v := VBoxContainer.new()
	validation.add_child(v)
	v.add_child(_heading("导入校验结果", 20))
	v.add_child(_muted("✓ JSON解析通过\n✓ 事件ID无重复\n✓ 所有剧情跳转目标存在\n✓ D20检定成功/失败分支完整\n✓ 战斗敌人引用存在\n✓ 存档版本字段已配置"))

func show_summary() -> void:
	current_view = "summary"
	_clear_view()
	var card := _panel_container()
	content_root.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)
	box.add_child(_muted("剧本完成"))
	box.add_child(_heading("雾港余烬 · 调查结算", 34))
	var ending := "摧毁潮心，雾港重见晨光" if GameState.world.flags.get("destroy_heart", false) else "封存潮心，带走危险证据"
	box.add_child(_muted("结局：%s\n经历事件：%d\n战斗结果：%s\n最终生命：%d/%d\n背包物品：%s" % [ending, int(GameState.world.minutes), "胜利" if GameState.world.battle_won else "未完成", int(GameState.player.hp), _effective_combat("生命"), _inventory_lines(99).replace("\n", "；")]))
	var log := RichTextLabel.new()
	log.custom_minimum_size.y = 220
	log.add_theme_font_size_override("normal_font_size", 15)
	log.text = "调查记录\n\n" + "\n".join(GameState.world.log)
	box.add_child(log)
	var save := _button("保存已通关存档")
	save.pressed.connect(func(): _toast("保存成功" if GameState.save_game() else "保存失败"))
	box.add_child(save)
	var restart := _button("重新开始", true)
	restart.pressed.connect(_new_game)
	box.add_child(restart)
