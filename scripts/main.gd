extends Control

const DiceClass = preload("res://scripts/dice.gd")
const ContentSchema = preload("res://scripts/content_schema.gd")
const ContentLibrary = preload("res://scripts/content_library.gd")
const EventActionSchema = preload("res://scripts/event_action_schema.gd")
const ScenarioPackage = preload("res://scripts/scenario_package.gd")

var scenario: Dictionary = {}
var database: Dictionary = {}
var events: Dictionary = {}
var content_library
var current_view := "menu"
var content_root: MarginContainer
var toast_label: Label
var time_status_label: Label
var title_label: Label
var body_label: RichTextLabel
var choices_box: VBoxContainer
var event_text_pages: Array[String] = []
var event_text_page_index := 0
var event_text_options: Array = []
var hp_label: Label
var inventory_label: Label
var battle_log: RichTextLabel
var enemy_hp_label: Label
var player_hp_label: Label
var editor_list: ItemList
var editor_event_id: LineEdit
var editor_name: LineEdit
var editor_type: OptionButton
var editor_location: OptionButton
var editor_lock: CheckBox
var editor_prerequisites: LineEdit
var editor_prerequisite_mode: OptionButton
var editor_flow_mode: OptionButton
var editor_repeatable: CheckBox
var editor_draft: CheckBox
var editor_action_cost: SpinBox
var editor_countdown_days: SpinBox
var editor_timeout_event: OptionButton
var editor_ends_continuous: CheckBox
var editor_background_path: LineEdit
var editor_background_preview: TextureRect
var editor_music_path: LineEdit
var editor_text: TextEdit
var editor_preview: HBoxContainer
var editor_options_list: ItemList
var editor_option_text: LineEdit
var editor_option_action: OptionButton
var editor_option_next: OptionButton
var editor_option_success: OptionButton
var editor_option_failure: OptionButton
var editor_option_stat: OptionButton
var editor_option_difficulty: SpinBox
var editor_option_resource: OptionButton
var editor_option_item: OptionButton
var editor_option_damage: SpinBox
var editor_option_flag: LineEdit
var editor_options: Array = []
var selected_editor_option_index := -1
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
var map_point_list: ItemList
var map_point_name: LineEdit
var map_point_position_label: Label
var map_point_picker_canvas: Control
var image_dialog: FileDialog
var pending_image_target := ""
var audio_dialog: FileDialog
var pending_audio_target := ""
var package_dialog: FileDialog
var pending_package_action := ""
var content_validation: Dictionary = {}
var map_music_player: AudioStreamPlayer
var event_music_player: AudioStreamPlayer
var preview_music_player: AudioStreamPlayer
var current_map_music_path := ""
var current_event_music_path := ""
var map_marker_count := 0
var map_menu_overlay: Control
var last_map_focus_position := Vector2.ZERO
var last_map_canvas_size := Vector2(980, 300)
var has_map_focus := false
var selected_map_point_index := -1
var draft_map_point_position := Vector2(480, 150)

var bg := Color("101724")
var panel := Color("182235")
var panel_alt := Color("202d43")
var accent := Color("62d4c7")
var gold := Color("e8b75d")
var text_main := Color("e8eef8")
var text_dim := Color("9fb0c8")
var danger := Color("e36f78")

const LOCATIONS := ["渡船", "雾港码头", "雾港广场", "黑帆酒馆", "旧灯塔", "地下钟室", "槐树镇", "北都"]
const DEFAULT_MAP_IMAGE := "res://assets/defaults/default_map.png"
const DEFAULT_ENEMY_IMAGE := "res://assets/defaults/default_enemy.png"
const DEFAULT_ITEM_IMAGE := "res://assets/defaults/default_item.png"
const MAP_CANVAS_FALLBACK_SIZE := Vector2(980, 300)
const MAP_CLICK_ZOOM_SCALE := 1.35
const MAP_CLICK_ZOOM_DURATION := 0.34
const MAP_CLICK_FADE_ALPHA := 0.32
const DEFAULT_SELL_ITEM_PRICES := {
	"item.silver_salt": 5,
	"item.salvage": 2
}
const LOCATION_ENTRY := {
	"渡船": "intro_01",
	"雾港码头": "harbor_01",
	"雾港广场": "square_01",
	"黑帆酒馆": "tavern_01",
	"旧灯塔": "lighthouse_01",
	"地下钟室": "archive_01",
	"槐树镇": "rural_001_01",
	"北都": "city_021_01"
}
const MAP_MARKER_POSITIONS := {
	"渡船": Vector2(120, 210),
	"雾港码头": Vector2(300, 185),
	"雾港广场": Vector2(520, 145),
	"黑帆酒馆": Vector2(620, 85),
	"旧灯塔": Vector2(790, 95),
	"地下钟室": Vector2(860, 205),
	"槐树镇": Vector2(420, 230),
	"北都": Vector2(720, 225)
}

func _ready() -> void:
	content_library = ContentLibrary.new()
	content_library.load_from_resources("res://data/scenario.json", "res://data/database.json", GameState.custom_content)
	_sync_content_from_library()
	_refresh_content_validation()
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

func _reload_event_registry() -> void:
	content_library.reload_custom_content(GameState.custom_content)
	_sync_content_from_library()

func _sync_content_from_library() -> void:
	scenario = content_library.scenario
	database = content_library.database
	events = content_library.events
	GameState.custom_content = content_library.custom_content

func _refresh_content_validation() -> void:
	content_validation = ContentSchema.validate_package(ScenarioPackage.make_package(scenario, database, GameState.custom_content))

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
		return _load_texture(fallback_path) if not fallback_path.is_empty() else null
	if path.begins_with("res://"):
		var resource_texture := _load_texture(path)
		return resource_texture if resource_texture != null else (_load_texture(fallback_path) if not fallback_path.is_empty() else null)
	var absolute_path := ProjectSettings.globalize_path(path) if path.begins_with("user://") else path
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return _load_texture(fallback_path) if not fallback_path.is_empty() else null
	return ImageTexture.create_from_image(image)

func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var absolute_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") or path.begins_with("user://") else path
	if ["png", "jpg", "jpeg", "webp"].has(path.get_extension().to_lower()):
		var image := Image.load_from_file(absolute_path)
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)
	var resource_texture := load(path) as Texture2D
	if resource_texture != null:
		return resource_texture
	var fallback_image := Image.load_from_file(absolute_path)
	if fallback_image == null or fallback_image.is_empty():
		return null
	return ImageTexture.create_from_image(fallback_image)

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
			_refresh_map_point_picker_texture()

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

func _ensure_package_dialog() -> void:
	if package_dialog != null:
		return
	package_dialog = FileDialog.new()
	package_dialog.access = FileDialog.ACCESS_FILESYSTEM
	package_dialog.filters = PackedStringArray(["*.json ; Scenario package JSON"])
	package_dialog.file_selected.connect(_on_package_file_selected)
	add_child(package_dialog)

func _request_package_export() -> void:
	_ensure_package_dialog()
	pending_package_action = "export"
	package_dialog.title = "导出剧本包"
	package_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	package_dialog.current_file = "mist_harbor_scenario_package.json"
	package_dialog.popup_centered_ratio(0.72)

func _request_package_import() -> void:
	_ensure_package_dialog()
	pending_package_action = "import"
	package_dialog.title = "导入剧本包"
	package_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	package_dialog.current_file = ""
	package_dialog.popup_centered_ratio(0.72)

func _request_event_text_import() -> void:
	_ensure_package_dialog()
	pending_package_action = "import_events"
	package_dialog.title = "导入事件文案数据"
	package_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	package_dialog.current_file = ""
	package_dialog.popup_centered_ratio(0.72)

func _request_event_import_template_export() -> void:
	_ensure_package_dialog()
	pending_package_action = "export_event_template"
	package_dialog.title = "导出事件导入模板"
	package_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	package_dialog.current_file = "event_import_template.json"
	package_dialog.popup_centered_ratio(0.72)

func _on_package_file_selected(path: String) -> void:
	if pending_package_action == "export":
		var result := ScenarioPackage.export_to_path(path, scenario, database, GameState.custom_content)
		if result.ok:
			_toast("剧本包已导出")
		else:
			_toast("导出失败：" + _first_error(result))
	elif pending_package_action == "export_event_template":
		if _export_event_import_template(path):
			_toast("事件导入模板已导出")
		else:
			_toast("模板导出失败")
	elif pending_package_action == "import":
		var result := ScenarioPackage.import_from_path(path)
		if not result.ok:
			_toast("导入失败：" + _first_error(result))
			return
		var package: Dictionary = result.package
		content_library.set_package(package)
		_sync_content_from_library()
		GameState.save_custom_content()
		_refresh_content_validation()
		_toast("剧本包已导入")
		show_tools()
	elif pending_package_action == "import_events":
		var result := _import_event_text_data(path)
		if not result.ok:
			_toast("事件导入失败：" + _first_error(result))
			return
		_reload_event_registry()
		GameState.save_custom_content()
		_refresh_content_validation()
		_toast("事件导入完成：新增%d，更新%d，未完善%d" % [int(result.added), int(result.updated), int(result.draft)])
		show_tools()
	pending_package_action = ""

func _first_error(result: Dictionary) -> String:
	var errors: Array = result.get("errors", [])
	return str(errors[0]) if not errors.is_empty() else "未知错误"

func _export_event_import_template(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_event_import_template(), "  "))
	return true

func _event_import_template() -> Dictionary:
	return {
		"format": "mist_harbor_event_text_import",
		"version": 1,
		"notes": [
			"id/title/text 是必填文案字段。",
			"location 需要对应大地图素材页配置的事件发生点。",
			"background_image/music 可先留空；留空导入后会自动标记为 draft，暂不可使用。",
			"补齐素材后，在事件编辑器取消“事件数据未完善，暂不可使用”即可启用。"
		],
		"events": [
			{
				"id": "custom.story_001",
				"title": "示例事件标题",
				"chapter": "第一章",
				"speaker": "旁白",
				"type": "剧情事件",
				"location": "雾港码头",
				"background_image": "",
				"music": "",
				"locked": false,
				"prerequisites": [],
				"prerequisite_mode": "all",
				"flow_mode": "interruptible",
				"repeatable": false,
				"action_cost": 1,
				"ends_continuous": false,
				"text": "这里填写剧情正文。",
				"options": [
					{"text": "返回地图", "action": "open_map"}
				]
			}
		]
	}

func _import_event_text_data(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["文件不存在：%s" % path]}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	var raw_events: Array = []
	if parsed is Array:
		raw_events = parsed
	elif parsed is Dictionary:
		var event_value = parsed.get("events", [])
		if event_value is Array:
			raw_events = event_value
		else:
			return {"ok": false, "errors": ["events 必须是数组"]}
	else:
		return {"ok": false, "errors": ["事件文案文件必须是 JSON 对象或数组"]}
	if raw_events.is_empty():
		return {"ok": false, "errors": ["没有可导入的事件"]}
	var added := 0
	var updated := 0
	var draft_count := 0
	var errors: Array[String] = []
	for index in range(raw_events.size()):
		if not raw_events[index] is Dictionary:
			errors.append("事件 #%d 必须是对象" % index)
			continue
		var imported := _normalize_imported_event(raw_events[index], index, errors)
		if imported.is_empty():
			continue
		if bool(imported.get("draft", false)):
			draft_count += 1
		var replaced := false
		for i in range(GameState.custom_content.events.size()):
			if str(GameState.custom_content.events[i].get("id", "")) == str(imported.id):
				GameState.custom_content.events[i] = imported
				replaced = true
				updated += 1
				break
		if not replaced:
			GameState.custom_content.events.append(imported)
			added += 1
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	return {"ok": true, "errors": [], "added": added, "updated": updated, "draft": draft_count}

func _normalize_imported_event(source: Dictionary, index: int, errors: Array[String]) -> Dictionary:
	var event_id := str(source.get("id", "")).strip_edges()
	if event_id.is_empty():
		errors.append("事件 #%d 缺少 id" % index)
		return {}
	if not _valid_event_id(event_id):
		errors.append("事件 id 非法：%s" % event_id)
		return {}
	var title := str(source.get("title", source.get("name", ""))).strip_edges()
	if title.is_empty():
		errors.append("事件缺少 title/name：%s" % event_id)
		return {}
	var text := str(source.get("text", "")).strip_edges()
	if text.is_empty():
		errors.append("事件缺少 text：%s" % event_id)
		return {}
	var options = source.get("options", [{"text":"返回地图", "action":"open_map"}])
	if not options is Array or options.is_empty():
		options = [{"text":"返回地图", "action":"open_map"}]
	var entry := {
		"id": event_id,
		"name": title,
		"title": title,
		"chapter": str(source.get("chapter", "导入事件")),
		"speaker": str(source.get("speaker", "旁白")),
		"type": str(source.get("type", "剧情事件")),
		"location": str(source.get("location", "")).strip_edges(),
		"background_image": str(source.get("background_image", "")),
		"music": str(source.get("music", "")),
		"locked": bool(source.get("locked", false)),
		"prerequisites": _string_list_from_value(source.get("prerequisites", [])),
		"prerequisite_mode": str(source.get("prerequisite_mode", "all")),
		"flow_mode": str(source.get("flow_mode", "interruptible")),
		"repeatable": bool(source.get("repeatable", false)),
		"action_cost": int(source.get("action_cost", 1)),
		"countdown_days": int(source.get("countdown_days", 0)),
		"timeout_event": str(source.get("timeout_event", "")),
		"ends_continuous": bool(source.get("ends_continuous", false)),
		"text": text,
		"options": options
	}
	var notes := _import_event_incomplete_notes(entry)
	var source_draft := bool(source.get("draft", false))
	entry.draft = source_draft or not notes.is_empty()
	entry.import_notes = str(source.get("import_notes", notes)).strip_edges()
	return ContentSchema.normalize_event(entry)

func _import_event_incomplete_notes(event: Dictionary) -> String:
	var missing: Array[String] = []
	if str(event.get("location", "")).strip_edges().is_empty():
		missing.append("发生点")
	if str(event.get("background_image", "")).strip_edges().is_empty():
		missing.append("背景图")
	if str(event.get("music", "")).strip_edges().is_empty():
		missing.append("背景音乐")
	if not _map_point_names().has(str(event.get("location", ""))):
		missing.append("发生点未配置")
	return "缺少" + "、".join(missing) if not missing.is_empty() else ""

func _string_list_from_value(value) -> Array[String]:
	var result: Array[String] = []
	if value is String:
		for raw in str(value).split(","):
			var text := raw.strip_edges()
			if not text.is_empty() and not result.has(text):
				result.append(text)
	elif value is Array:
		for entry in value:
			var text := str(entry).strip_edges()
			if not text.is_empty() and not result.has(text):
				result.append(text)
	return result

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
	var normalized_event := ContentSchema.normalize_event(source)
	events[normalized_event.id] = normalized_event

func _all_event_definitions() -> Array:
	return content_library.all_event_definitions()

func _event_unlocked(event_id: String) -> bool:
	var visited: Array = GameState.world.get("visited", [])
	return content_library.event_unlocked(event_id, visited)

func _lock_description(event_id: String) -> String:
	return content_library.lock_description(event_id)

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
	brand.add_theme_font_size_override("font_size", 22)
	brand.add_theme_color_override("font_color", accent)
	header_row.add_child(brand)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer)
	for spec in [["主菜单", show_menu], ["开始/继续", _continue_game], ["地图", show_map], ["背包/装备", show_inventory], ["角色育成", show_growth], ["创作工具", show_tools]]:
		var button := _button(spec[0], false)
		button.custom_minimum_size.x = 86
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
	var timeout_event_id := _advance_event_countdowns()
	if not timeout_event_id.is_empty():
		show_event(timeout_event_id)
		return
	show_rest_result(result)

func _advance_event_countdowns() -> String:
	_ensure_event_countdown_state()
	var countdowns: Dictionary = GameState.world.event_countdowns
	var expired_target := ""
	for event_id_value in countdowns.keys():
		var event_id := str(event_id_value)
		if not events.has(event_id) or GameState.world.visited.has(event_id):
			countdowns.erase(event_id)
			continue
		var remaining := int(countdowns.get(event_id, 0)) - 1
		countdowns[event_id] = remaining
		var event: Dictionary = events[event_id]
		GameState.add_log("事件倒计时：%s 剩余%d天" % [event.get("title", event_id), maxi(remaining, 0)])
		if remaining <= 0 and expired_target.is_empty():
			countdowns.erase(event_id)
			if not GameState.world.visited.has(event_id):
				GameState.world.visited.append(event_id)
			var target := str(event.get("timeout_event", ""))
			if not target.is_empty() and events.has(target):
				expired_target = target
				GameState.add_log("事件超时：%s，触发%s" % [event.get("title", event_id), events[target].get("title", target)])
			else:
				GameState.add_log("事件超时：%s" % event.get("title", event_id))
	return expired_target

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

func show_inn() -> void:
	if _block_if_continuous("进入旅馆"):
		return
	current_view = "inn"
	_clear_view()
	var root := _facility_overlay_root("黑帆旅馆", "热汤、铺位和临时药台都挤在这间临海旅馆里。", _service_focus_position("inn"), Vector2(980, 520))
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	root.add_child(top_row)
	var intro := _facility_card("黑帆旅馆", "热汤、铺位和临时药台都挤在这间临海旅馆里。")
	intro.custom_minimum_size = Vector2(430, 120)
	top_row.add_child(intro)
	var intro_box := intro.get_child(0) as VBoxContainer
	intro_box.add_child(_muted("雾历 %s  ·  行动 %d/%d  ·  饱腹 %d/%d" % [GameState.date_text().replace("雾历 ", ""), int(GameState.world.action_points), int(GameState.world.max_action_points), int(GameState.player.satiety), int(GameState.player.max_satiety)]))
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	var stock := _facility_card("可用材料", "药草 %d  /  残骸 %d" % [int(GameState.player.inventory.get("item.herb", 0)), int(GameState.player.inventory.get("item.salvage", 0))])
	stock.custom_minimum_size = Vector2(280, 120)
	top_row.add_child(stock)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)
	var rest_card := _facility_card("留宿休息", "推进一天，恢复行动点，并结算饱腹消耗。")
	rest_card.custom_minimum_size = Vector2(420, 230)
	rest_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rest_card)
	var rest_box := rest_card.get_child(0) as VBoxContainer
	rest_box.add_child(_facility_rule_line("每次休息  -20 饱腹  /  行动恢复至上限"))
	rest_box.add_child(_muted("当前行动：%d/%d\n当前饱腹：%d/%d" % [int(GameState.world.action_points), int(GameState.world.max_action_points), int(GameState.player.satiety), int(GameState.player.max_satiety)]))
	var rest_spacer := Control.new()
	rest_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rest_box.add_child(rest_spacer)
	var rest := _outline_button("休息到明天")
	rest.custom_minimum_size = Vector2(250, 34)
	rest.pressed.connect(rest_day)
	rest_box.add_child(rest)
	var craft_card := _facility_card("调配补给", "用采集到的材料制作路上能用的药剂和口粮。")
	craft_card.custom_minimum_size = Vector2(420, 230)
	craft_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(craft_card)
	var craft_box := craft_card.get_child(0) as VBoxContainer
	craft_box.add_child(_facility_rule_line("药草 x2  →  提神药剂"))
	craft_box.add_child(_facility_rule_line("药草 x1 + 残骸 x1  →  旅行口粮"))
	var craft_spacer := Control.new()
	craft_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	craft_box.add_child(craft_spacer)
	var craft_tonic := _outline_button("调配提神药剂")
	craft_tonic.custom_minimum_size = Vector2(250, 34)
	craft_tonic.disabled = not GameState.has_item("item.herb", 2)
	craft_tonic.pressed.connect(func():
		if GameState.craft_item("item.tonic"):
			_toast("调配出提神药剂")
			show_inn()
	)
	craft_box.add_child(craft_tonic)
	var craft_ration := _outline_button("整理旅行口粮")
	craft_ration.custom_minimum_size = Vector2(250, 34)
	craft_ration.disabled = not (GameState.has_item("item.salvage") and GameState.has_item("item.herb"))
	craft_ration.pressed.connect(func():
		if GameState.craft_item("item.ration"):
			_toast("整理出旅行口粮")
			show_inn()
	)
	craft_box.add_child(craft_ration)
	var back := _outline_button("返回地图")
	back.custom_minimum_size = Vector2(260, 34)
	back.pressed.connect(func(): _return_from_facility_to_map(root))
	root.add_child(back)

func show_shop() -> void:
	if _block_if_continuous("进入商店"):
		return
	current_view = "shop"
	_clear_view()
	var root := _facility_overlay_root("雾港杂货商", "柜台后堆着麻袋、旧灯油和等价换银的小物件。", _service_focus_position("shop"), Vector2(920, 500))
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	root.add_child(top_row)
	var intro := _facility_card("雾港杂货商", "柜台后堆着麻袋、旧灯油和等价换银的小物件。")
	intro.custom_minimum_size = Vector2(430, 120)
	top_row.add_child(intro)
	var intro_box := intro.get_child(0) as VBoxContainer
	intro_box.add_child(_muted("银币 %d  ·  只收换金道具" % int(GameState.player.get("coins", 0))))
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	var wallet := _facility_card("交易规则", "按 sell_price、price 或默认换金价格结算。")
	wallet.custom_minimum_size = Vector2(320, 120)
	top_row.add_child(wallet)
	var card := _facility_card("出售", "背包中可出售的物品会显示在这里。")
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(card)
	var box := card.get_child(0) as VBoxContainer
	_rebuild_shop_sell_list(box)
	var back := _outline_button("返回地图")
	back.custom_minimum_size = Vector2(260, 34)
	back.pressed.connect(func(): _return_from_facility_to_map(root))
	root.add_child(back)

func _rebuild_shop_sell_list(box: VBoxContainer) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	var title := _heading("出售", 23)
	title.add_theme_color_override("font_color", Color(0.9, 0.96, 0.93, 1.0))
	box.add_child(title)
	var note := _muted("背包中可出售的物品会显示在这里。")
	note.add_theme_color_override("font_color", Color(0.78, 0.86, 0.82, 1.0))
	box.add_child(note)
	var sellable_items := _sellable_inventory_items()
	if sellable_items.is_empty():
		box.add_child(_muted("背包里暂时没有可出售的换金道具。"))
		return
	for entry in sellable_items:
		var item_id := str(entry.get("id", ""))
		var item_name := str(entry.get("name", item_id))
		var quantity := int(entry.get("quantity", 0))
		var price := int(entry.get("price", 0))
		var sell_button := _outline_button("%s x%d    出售 1 个 / %d银币" % [item_name, quantity, price])
		sell_button.disabled = quantity <= 0 or price <= 0
		sell_button.pressed.connect(func():
			if GameState.sell_item(item_id, 1, price):
				_toast("出售%s，获得%d银币" % [item_name, price])
				show_shop()
		)
		box.add_child(sell_button)

func _sellable_inventory_items() -> Array:
	var result: Array = []
	for item_id_value in GameState.player.inventory.keys():
		var item_id := str(item_id_value)
		var quantity := int(GameState.player.inventory.get(item_id, 0))
		if quantity <= 0:
			continue
		var definition := _find_content_item(item_id)
		if definition.is_empty():
			continue
		var price := _sell_price_for_item(definition)
		if price <= 0:
			continue
		result.append({"id": item_id, "name": definition.get("name", item_id), "quantity": quantity, "price": price})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	return result

func _sell_price_for_item(definition: Dictionary) -> int:
	if definition.has("sell_price"):
		return maxi(0, int(definition.get("sell_price", 0)))
	if definition.has("price"):
		return maxi(0, int(definition.get("price", 0)))
	var item_id := str(definition.get("id", ""))
	if DEFAULT_SELL_ITEM_PRICES.has(item_id):
		return int(DEFAULT_SELL_ITEM_PRICES[item_id])
	if str(definition.get("type", "")) == "换金道具":
		return 1
	return 0

func _facility_overlay_root(title_text: String, subtitle: String, fallback_focus: Vector2, panel_size := Vector2(940, 500)) -> VBoxContainer:
	var screen := Control.new()
	screen.clip_contents = true
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_root.add_child(screen)
	var map_layer := _add_facility_map_background(screen, fallback_focus)
	var vignette := ColorRect.new()
	vignette.color = Color(0.02, 0.04, 0.07, 0.24)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(vignette)
	var panel_container := MarginContainer.new()
	panel_container.anchor_left = 0.5
	panel_container.anchor_right = 0.5
	panel_container.anchor_top = 0.5
	panel_container.anchor_bottom = 0.5
	panel_container.offset_left = -panel_size.x * 0.5
	panel_container.offset_right = panel_size.x * 0.5
	panel_container.offset_top = -panel_size.y * 0.5
	panel_container.offset_bottom = panel_size.y * 0.5
	panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_container.add_theme_constant_override("margin_left", 0)
	panel_container.add_theme_constant_override("margin_right", 0)
	panel_container.add_theme_constant_override("margin_top", 0)
	panel_container.add_theme_constant_override("margin_bottom", 0)
	screen.add_child(panel_container)
	screen.set_meta("facility_map_layer", map_layer)
	screen.set_meta("facility_vignette", vignette)
	screen.set_meta("facility_panel", panel_container)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	panel_container.add_child(root)
	return root

func _add_facility_map_background(parent: Control, fallback_focus: Vector2) -> Control:
	var map_texture := _texture_from_path(str(GameState.custom_content.get("map_background", "")), DEFAULT_MAP_IMAGE)
	if map_texture == null:
		return null
	var map_layer := Control.new()
	map_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(map_layer)
	var map_view := TextureRect.new()
	map_view.texture = map_texture
	map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_layer.add_child(map_view)
	var canvas_size := last_map_canvas_size if has_map_focus else MAP_CANVAS_FALLBACK_SIZE
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0:
		canvas_size = MAP_CANVAS_FALLBACK_SIZE
	var focus := last_map_focus_position if has_map_focus else fallback_focus
	map_layer.scale = Vector2(MAP_CLICK_ZOOM_SCALE, MAP_CLICK_ZOOM_SCALE)
	map_layer.position = _map_focus_position(focus, canvas_size, MAP_CLICK_ZOOM_SCALE)
	var haze := ColorRect.new()
	haze.color = Color(0.04, 0.08, 0.11, 0.24)
	haze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(haze)
	parent.set_meta("facility_haze", haze)
	return map_layer

func _return_from_facility_to_map(root: Control) -> void:
	var panel := root.get_parent() as Control
	var screen := panel.get_parent() as Control if panel != null else null
	if screen == null or not is_instance_valid(screen):
		show_map()
		return
	_activate_map_music()
	current_view = "map"
	has_map_focus = false
	_sync_visible_event_countdowns()
	var map_root := _create_map_root()
	content_root.move_child(map_root, screen.get_index())
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	var map_layer := screen.get_meta("facility_map_layer", null) as Control
	var vignette := screen.get_meta("facility_vignette", null) as CanvasItem
	var haze := screen.get_meta("facility_haze", null) as CanvasItem
	var facility_panel := screen.get_meta("facility_panel", null) as CanvasItem
	var tween := create_tween()
	tween.set_parallel(true)
	if map_layer != null and is_instance_valid(map_layer):
		tween.tween_property(map_layer, "scale", Vector2.ONE, MAP_CLICK_ZOOM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(map_layer, "position", Vector2.ZERO, MAP_CLICK_ZOOM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if facility_panel != null and is_instance_valid(facility_panel):
		tween.tween_property(facility_panel, "modulate:a", 0.0, MAP_CLICK_ZOOM_DURATION * 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if vignette != null and is_instance_valid(vignette):
		tween.tween_property(vignette, "modulate:a", 0.0, MAP_CLICK_ZOOM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if haze != null and is_instance_valid(haze):
		tween.tween_property(haze, "modulate:a", 0.0, MAP_CLICK_ZOOM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	if is_instance_valid(screen):
		screen.queue_free()

func _facility_status_strip() -> PanelContainer:
	var strip := _facility_frame(Color(0.03, 0.06, 0.09, 0.28), Color(1, 1, 1, 0.5))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	strip.add_child(row)
	for text in [
		GameState.date_text(),
		"行动 %d/%d" % [int(GameState.world.action_points), int(GameState.world.max_action_points)],
		"饱腹 %d/%d" % [int(GameState.player.satiety), int(GameState.player.max_satiety)],
		"银币 %d" % int(GameState.player.get("coins", 0))
	]:
		var label := _muted(str(text))
		label.add_theme_color_override("font_color", text_main)
		row.add_child(label)
	return strip

func _facility_card(title_text: String, subtitle: String) -> PanelContainer:
	var card := _facility_frame(Color(0.04, 0.11, 0.09, 0.68), Color(1, 1, 1, 0.5))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var title := _heading(title_text, 23)
	title.add_theme_color_override("font_color", Color(0.9, 0.96, 0.93, 1.0))
	box.add_child(title)
	var subtitle_label := _muted(subtitle)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.82, 1.0))
	box.add_child(subtitle_label)
	return card

func _facility_frame(fill: Color, border_color: Color) -> PanelContainer:
	var frame := PanelContainer.new()
	var style := _box(fill, 0, 1)
	style.border_color = border_color
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	frame.add_theme_stylebox_override("panel", style)
	return frame

func _outline_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(180, 34)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(0.92, 0.97, 0.95, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.92, 0.97, 0.95, 0.38))
	button.add_theme_stylebox_override("normal", _outline_box(Color(1, 1, 1, 0.72), Color(1, 1, 1, 0.04)))
	button.add_theme_stylebox_override("hover", _outline_box(Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.12)))
	button.add_theme_stylebox_override("pressed", _outline_box(accent, Color(accent, 0.18)))
	button.add_theme_stylebox_override("disabled", _outline_box(Color(1, 1, 1, 0.26), Color(0, 0, 0, 0.08)))
	return button

func _outline_box(border_color: Color, fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _facility_rule_line(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.92, 0.97, 0.95, 0.9))
	label.add_theme_stylebox_override("normal", _outline_box(Color(1, 1, 1, 0.58), Color(0, 0, 0, 0.08)))
	label.custom_minimum_size = Vector2(0, 28)
	return label

func _map_hud_box(fill: Color, border_color: Color) -> StyleBoxFlat:
	var style := _outline_box(border_color, fill)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _map_hud_card(title_text: String, subtitle: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _map_hud_box(Color(0.04, 0.1, 0.09, 0.52), Color(1, 1, 1, 0.42)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var title := _heading(title_text, 20)
	title.add_theme_color_override("font_color", Color(0.92, 0.97, 0.95, 1.0))
	box.add_child(title)
	if not subtitle.is_empty():
		var subtitle_label := _muted(subtitle)
		subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.82, 1.0))
		box.add_child(subtitle_label)
	return card

func _service_focus_position(service_id: String) -> Vector2:
	for service in _map_service_markers():
		if str(service.get("id", "")) == service_id:
			return service.get("position", MAP_CANVAS_FALLBACK_SIZE * 0.5)
	return MAP_CANVAS_FALLBACK_SIZE * 0.5

func _all_equipment() -> Array:
	return content_library.all_equipment()

func _all_items() -> Array:
	return content_library.all_items()

func _merged_definitions(builtins: Array, customs: Array) -> Array:
	return content_library.merged_definitions(builtins, customs)

func _all_entities(key: String) -> Array:
	return content_library.all_entities(key)

func _find_entity(key: String, entity_id: String) -> Dictionary:
	return content_library.find_entity(key, entity_id)

func _find_content_item(item_id: String) -> Dictionary:
	return content_library.find_content_item(item_id)

func _item_name(item_id: String) -> String:
	return content_library.item_name(item_id)

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
	_ensure_event_countdown_state()
	GameState.world.event_countdowns.erase(event_id)
	GameState.world.minutes = int(GameState.world.get("minutes", 0)) + 1
	_update_world_systems_for_event(event_id, event)
	if bool(event.get("ends_continuous", false)):
		GameState.world.active_continuous = ""
	_update_time_status()
	GameState.add_log("进入事件：" + event.title)
	_clear_view()
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	content_root.add_child(root)
	var stage := Control.new()
	stage.clip_contents = true
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.size_flags_stretch_ratio = 2.0
	root.add_child(stage)
	var background_view := TextureRect.new()
	background_view.texture = _event_background_texture(event)
	background_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage.add_child(background_view)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.06, 0.1, 0.22)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(shade)
	_add_event_portraits(stage, event)
	var dialogue_panel := _panel_container(Color(0.08, 0.12, 0.18, 0.94))
	dialogue_panel.custom_minimum_size.y = 235
	dialogue_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_panel.size_flags_stretch_ratio = 1.0
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_panel.gui_input.connect(_on_event_text_panel_input)
	root.add_child(dialogue_panel)
	var dialogue_box := VBoxContainer.new()
	dialogue_box.add_theme_constant_override("separation", 8)
	dialogue_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_panel.add_child(dialogue_box)
	var speaker_line := _muted(_event_speaker_line(event))
	speaker_line.add_theme_font_size_override("font_size", 16)
	dialogue_box.add_child(speaker_line)
	body_label = RichTextLabel.new()
	body_label.bbcode_enabled = true
	body_label.fit_content = false
	body_label.scroll_active = false
	body_label.mouse_filter = Control.MOUSE_FILTER_PASS
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_label.add_theme_font_size_override("normal_font_size", 22)
	body_label.add_theme_color_override("default_color", text_main)
	body_label.meta_clicked.connect(_on_event_text_meta_clicked)
	dialogue_box.add_child(body_label)
	var dialogue_bottom_padding := Control.new()
	dialogue_bottom_padding.custom_minimum_size.y = 14
	dialogue_box.add_child(dialogue_bottom_padding)
	event_text_pages = _paginate_event_text(str(event.get("text", "")))
	event_text_page_index = 0
	event_text_options = event.get("options", [])
	_render_event_text_page()

func _update_world_systems_for_event(event_id: String, event: Dictionary) -> void:
	match event_id:
		"intro_01":
			GameState.set_quest("find_linya", "寻找林鸦", "进行中", "午夜来信指向旧灯塔。")
		"harbor_powder":
			GameState.set_quest("gray_salt", "银灰粉末", "线索", "巡夜人袖口的粉末来自灰帆号。")
		"tavern_02":
			GameState.set_quest("sea_bell", "海底钟声", "线索", "钟声会偷走记忆。")
			GameState.adjust_relation("老乔", 1)
		"archive_01":
			GameState.set_quest("find_linya", "寻找林鸦", "完成", "林鸦被困在地下钟室。")
			GameState.adjust_relation("林鸦", 1)
		"ending_good":
			GameState.set_quest("tide_heart", "处理潮心", "完成", "潮心已被摧毁。")
			GameState.adjust_relation("港民", 2)
		"ending_secret":
			GameState.set_quest("tide_heart", "处理潮心", "完成", "潮心被封存带回调查所。")
	if event.get("location", "") == "地下钟室":
		GameState.set_quest("tide_heart", "处理潮心", "进行中", "铜钟下方的蓝色结晶正在搏动。")

func _relations_line() -> String:
	var relations: Dictionary = GameState.world.get("relations", {})
	return "关系：林鸦%+d  老乔%+d  港民%+d" % [int(relations.get("林鸦", 0)), int(relations.get("老乔", 0)), int(relations.get("港民", 0))]

func _event_background_texture(event: Dictionary) -> Texture2D:
	var event_background := _texture_from_path(str(event.get("background_image", "")))
	if event_background != null:
		return event_background
	return _texture_from_path(str(GameState.custom_content.get("map_background", "")), DEFAULT_MAP_IMAGE)

func _event_speaker_line(event: Dictionary) -> String:
	var speaker := str(event.get("speaker", "旁白"))
	if speaker.is_empty() or speaker == "旁白":
		return "%s" % event.get("title", "")
	return "%s  /  %s" % [speaker, str(_find_speaker_entity(speaker).get("role", event.get("speaker_role", "登场角色")))]

func _add_event_portraits(stage: Control, event: Dictionary) -> void:
	var player_texture := _player_portrait_texture()
	if player_texture != null:
		var player := _stage_portrait(player_texture, false)
		player.anchor_left = 0.0
		player.anchor_right = 0.0
		player.offset_left = 28
		player.offset_right = 308
		stage.add_child(player)
	var speaker := str(event.get("speaker", "旁白"))
	if speaker.is_empty() or speaker == "旁白":
		return
	var entity := _find_speaker_entity(speaker)
	var portrait_path := str(event.get("portrait_image", entity.get("portrait_image", "")))
	var speaker_texture := _texture_from_path(portrait_path, DEFAULT_ENEMY_IMAGE)
	if speaker_texture != null:
		var other := _stage_portrait(speaker_texture, true)
		other.anchor_left = 1.0
		other.anchor_right = 1.0
		other.offset_left = -308
		other.offset_right = -28
		stage.add_child(other)

func _stage_portrait(texture: Texture2D, face_left: bool) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.texture = texture
	portrait.anchor_top = 0.08
	portrait.anchor_bottom = 1.0
	portrait.offset_top = 0
	portrait.offset_bottom = -8
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.flip_h = face_left
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return portrait

func _player_portrait_texture() -> Texture2D:
	var portrait_path := str(GameState.player.get("portrait_image", ""))
	return _texture_from_path(portrait_path, DEFAULT_ENEMY_IMAGE)

func _paginate_event_text(text: String) -> Array[String]:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return [""]
	var pages: Array[String] = []
	var current := ""
	for paragraph in trimmed.split("\n"):
		var part := str(paragraph).strip_edges()
		if part.is_empty():
			continue
		if current.length() > 0 and current.length() + part.length() > 120:
			pages.append(current)
			current = part
		else:
			current = part if current.is_empty() else current + "\n" + part
		while current.length() > 180:
			pages.append(current.left(180))
			current = current.substr(180)
	if not current.is_empty():
		pages.append(current)
	return pages

func _render_event_text_page() -> void:
	if body_label == null:
		return
	var lines: Array[String] = []
	if event_text_pages.is_empty():
		lines.append("")
	else:
		var index := clampi(event_text_page_index, 0, event_text_pages.size() - 1)
		lines.append(event_text_pages[index])
		if index >= event_text_pages.size() - 1:
			lines.append("")
			for i in range(event_text_options.size()):
				var option: Dictionary = event_text_options[i]
				lines.append("[url=%d]› %s[/url]" % [i, option.get("text", "继续")])
	body_label.text = "\n".join(lines)

func _advance_event_text_page() -> void:
	if event_text_page_index < event_text_pages.size() - 1:
		event_text_page_index += 1
		_render_event_text_page()

func _on_event_text_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_advance_event_text_page()

func _on_event_text_meta_clicked(meta) -> void:
	var index := int(str(meta))
	if index >= 0 and index < event_text_options.size():
		_choose(event_text_options[index])

func _speaker_portrait_card(event: Dictionary) -> PanelContainer:
	var speaker := str(event.get("speaker", "旁白"))
	if speaker.is_empty() or speaker == "旁白":
		return null
	var entity := _find_speaker_entity(speaker)
	var portrait_path := str(event.get("portrait_image", entity.get("portrait_image", "")))
	var portrait_texture := _texture_from_path(portrait_path, DEFAULT_ENEMY_IMAGE)
	var card := _panel_container(panel_alt)
	card.custom_minimum_size = Vector2(180, 245)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var portrait := TextureRect.new()
	portrait.texture = portrait_texture
	portrait.custom_minimum_size = Vector2(160, 170)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(portrait)
	box.add_child(_heading(speaker, 17))
	var role := str(entity.get("role", event.get("speaker_role", "登场角色")))
	var role_label := _muted(role)
	role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(role_label)
	return card

func _find_speaker_entity(speaker: String) -> Dictionary:
	for key in ["characters", "enemies"]:
		for entity in _all_entities(key):
			if str(entity.get("name", "")) == speaker:
				return entity
	return {}

func _quest_lines() -> String:
	var quests: Dictionary = GameState.world.get("quests", {})
	if quests.is_empty():
		return "线索：暂无"
	var lines: Array[String] = []
	for quest_id in quests:
		var quest: Dictionary = quests[quest_id]
		lines.append("%s｜%s\n%s" % [quest.get("status", ""), quest.get("title", quest_id), quest.get("clue", "")])
	return "\n\n".join(lines)

func _objective_for(id: String) -> String:
	if id.begins_with("intro") or id.begins_with("harbor"):
		return "进入雾港，寻找林鸦留下的线索。"
	if id.begins_with("tavern") or id.begins_with("lighthouse") or id.begins_with("check"):
		return "调查旧灯塔并找到隐蔽入口。"
	if id.begins_with("archive"):
		return "营救林鸦，阻止赫伯特唤醒沉船。"
	return "决定潮心的最终归宿。"

# --- 地图与地点事件触发 ---

func _default_map_points() -> Array:
	var points: Array = []
	for location in LOCATIONS:
		var position: Vector2 = MAP_MARKER_POSITIONS.get(location, Vector2(480, 150))
		points.append({"name": location, "x": int(position.x), "y": int(position.y), "builtin": true})
	return points

func _custom_map_points() -> Array:
	if not GameState.custom_content.has("map_points") or not GameState.custom_content.map_points is Array:
		GameState.custom_content.map_points = []
	return GameState.custom_content.map_points

func _all_map_points() -> Array:
	var by_name := {}
	var result: Array = []
	for point in _default_map_points():
		var name := str(point.get("name", "")).strip_edges()
		by_name[name] = result.size()
		result.append(point.duplicate(true))
	for custom_point in _custom_map_points():
		if not custom_point is Dictionary:
			continue
		var name := str(custom_point.get("name", "")).strip_edges()
		if name.is_empty():
			continue
		var normalized := {"name": name, "x": int(custom_point.get("x", 480)), "y": int(custom_point.get("y", 150)), "builtin": false}
		if by_name.has(name):
			result[int(by_name[name])] = normalized
		else:
			by_name[name] = result.size()
			result.append(normalized)
	return result

func _map_point_names() -> Array[String]:
	var names: Array[String] = []
	for point in _all_map_points():
		var name := str(point.get("name", "")).strip_edges()
		if not name.is_empty() and not names.has(name):
			names.append(name)
	return names

func _map_point_position(point_name: String) -> Vector2:
	for point in _all_map_points():
		if str(point.get("name", "")) == point_name:
			return Vector2(float(point.get("x", 480)), float(point.get("y", 150)))
	return MAP_MARKER_POSITIONS.get(point_name, Vector2(480, 150))

func show_map() -> void:
	if _block_if_continuous("打开地图"):
		return
	_activate_map_music()
	current_view = "map"
	has_map_focus = false
	_clear_view()
	_sync_visible_event_countdowns()
	_create_map_root()

func _create_map_root() -> Control:
	var root := Control.new()
	root.clip_contents = true
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_root.add_child(root)
	var map_texture := _texture_from_path(GameState.custom_content.get("map_background", ""), DEFAULT_MAP_IMAGE)
	_build_map_event_canvas(root, map_texture)
	_build_map_bottom_menu(root)
	return root

func _build_map_event_canvas(root: Control, map_texture: Texture2D) -> void:
	map_marker_count = 0
	var canvas_panel := PanelContainer.new()
	var canvas_style := _box(Color("101724"))
	canvas_style.content_margin_left = 0
	canvas_style.content_margin_right = 0
	canvas_style.content_margin_top = 0
	canvas_style.content_margin_bottom = 0
	canvas_panel.add_theme_stylebox_override("panel", canvas_style)
	canvas_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_panel.custom_minimum_size = Vector2(0, 0)
	canvas_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(canvas_panel)
	var canvas := Control.new()
	canvas.clip_contents = true
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.custom_minimum_size = Vector2(0, 0)
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_panel.add_child(canvas)
	var map_layer := Control.new()
	map_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(map_layer)
	if map_texture != null:
		var map_view := TextureRect.new()
		map_view.texture = map_texture
		map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		map_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		map_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_layer.add_child(map_view)
	var location_counts := {}
	for event in _map_marker_events():
		var location := str(event.get("location", ""))
		var base := _map_point_position(location)
		var count := int(location_counts.get(location, 0))
		location_counts[location] = count + 1
		var marker := _make_map_marker(event, map_layer)
		marker.position = base + Vector2((count % 3) * 48, floori(count / 3.0) * 48)
		map_layer.add_child(marker)
		map_marker_count += 1
	for service in _map_service_markers():
		var marker := _make_map_service_marker(service, map_layer)
		marker.position = service.get("position", Vector2(480, 150))
		map_layer.add_child(marker)
		map_marker_count += 1
	var legend := HBoxContainer.new()
	legend.position = Vector2(18, 18)
	legend.add_theme_constant_override("separation", 10)
	canvas.add_child(legend)
	for text in ["◆ 剧情", "✦ 随机", "↻ 可重复", "旅 旅馆", "商 商店"]:
		var label := _muted(text)
		label.add_theme_color_override("font_color", text_main)
		legend.add_child(label)
	var transition_shade := ColorRect.new()
	transition_shade.color = Color(0.03, 0.06, 0.1, 0.0)
	transition_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(transition_shade)
	map_layer.set_meta("transition_shade", transition_shade)
	if map_marker_count == 0:
		var empty := _muted("暂无可进入事件；推进剧情后地图上会出现入口标记。")
		empty.position = Vector2(18, 260)
		canvas.add_child(empty)

func _build_map_bottom_menu(root: Control) -> void:
	map_menu_overlay = Control.new()
	map_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_menu_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(map_menu_overlay)
	var menu_panel := PanelContainer.new()
	menu_panel.anchor_left = 0.5
	menu_panel.anchor_right = 0.5
	menu_panel.anchor_top = 1.0
	menu_panel.anchor_bottom = 1.0
	menu_panel.offset_left = -260
	menu_panel.offset_right = 260
	menu_panel.offset_top = -68
	menu_panel.offset_bottom = -14
	menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_panel.add_theme_stylebox_override("panel", _map_hud_box(Color(0.03, 0.07, 0.08, 0.58), Color(1, 1, 1, 0.46)))
	root.add_child(menu_panel)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	menu_panel.add_child(row)
	for spec in [["个人属性", _show_map_profile_panel], ["背包", _show_map_bag_panel], ["好感度", _show_map_relations_panel], ["系统", _show_map_system_panel]]:
		var button := _outline_button(str(spec[0]))
		button.custom_minimum_size = Vector2(118, 34)
		button.pressed.connect(spec[1])
		row.add_child(button)

func _clear_map_menu_overlay() -> void:
	if map_menu_overlay == null:
		return
	for child in map_menu_overlay.get_children():
		child.queue_free()

func _map_overlay_panel(title_text: String, size: Vector2 = Vector2(760, 430)) -> VBoxContainer:
	_clear_map_menu_overlay()
	var panel_container := PanelContainer.new()
	panel_container.anchor_left = 0.5
	panel_container.anchor_right = 0.5
	panel_container.anchor_top = 1.0
	panel_container.anchor_bottom = 1.0
	panel_container.offset_left = -size.x * 0.5
	panel_container.offset_right = size.x * 0.5
	panel_container.offset_top = -size.y - 84
	panel_container.offset_bottom = -84
	panel_container.clip_contents = true
	panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_container.add_theme_stylebox_override("panel", _map_hud_box(Color(0.04, 0.1, 0.09, 0.66), Color(1, 1, 1, 0.52)))
	map_menu_overlay.add_child(panel_container)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel_container.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)
	var title := _heading(title_text, 24)
	title.add_theme_color_override("font_color", Color(0.92, 0.97, 0.95, 1.0))
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close := _outline_button("关闭")
	close.custom_minimum_size = Vector2(88, 30)
	close.pressed.connect(_clear_map_menu_overlay)
	header.add_child(close)
	return box

func _show_map_profile_panel() -> void:
	var box := _map_overlay_panel("个人属性", Vector2(860, 430))
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(content)
	var portrait_card := _map_hud_card("主角", "当前生命 %d/%d  ·  饱腹 %d/%d" % [int(GameState.player.hp), _effective_combat("生命"), int(GameState.player.satiety), int(GameState.player.max_satiety)])
	portrait_card.custom_minimum_size = Vector2(245, 330)
	content.add_child(portrait_card)
	var portrait_box := portrait_card.get_child(0) as VBoxContainer
	var portrait := TextureRect.new()
	portrait.texture = _player_portrait_texture()
	portrait.custom_minimum_size = Vector2(210, 245)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_box.add_child(portrait)
	var stat_column := VBoxContainer.new()
	stat_column.add_theme_constant_override("separation", 12)
	stat_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(stat_column)
	var narrative_card := _map_hud_card("叙事五维", "调查、交涉和剧情检定使用。")
	narrative_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narrative_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stat_column.add_child(narrative_card)
	(narrative_card.get_child(0) as VBoxContainer).add_child(_map_stat_grid(ContentSchema.CHECK_STATS, true))
	var combat_card := _map_hud_card("战斗五维", "命中、防御和生存能力使用。")
	combat_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stat_column.add_child(combat_card)
	(combat_card.get_child(0) as VBoxContainer).add_child(_map_stat_grid(ContentSchema.COMBAT_STATS, false))

func _map_stat_grid(stat_names: Array, check_stats := true) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	for stat_name in stat_names:
		var label := _muted(str(stat_name))
		label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.82, 1.0))
		grid.add_child(label)
		var value := Label.new()
		value.text = str(_effective_check(str(stat_name)) if check_stats else _effective_combat(str(stat_name)))
		value.add_theme_color_override("font_color", gold)
		value.add_theme_font_size_override("font_size", 20)
		grid.add_child(value)
	return grid

func _show_map_bag_panel() -> void:
	var box := _map_overlay_panel("背包", Vector2(980, 430))
	var status := _facility_rule_line("生命 %d/%d    饱腹 %d/%d    银币 %d" % [int(GameState.player.hp), _effective_combat("生命"), int(GameState.player.satiety), int(GameState.player.max_satiety), int(GameState.player.get("coins", 0))])
	status.custom_minimum_size.y = 26
	box.add_child(status)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(content)
	var equipment_card := _map_hud_card("装备", "点击已装备部位可以卸下。")
	equipment_card.custom_minimum_size = Vector2(410, 0)
	equipment_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(equipment_card)
	var equipment_box := equipment_card.get_child(0) as VBoxContainer
	var equipment_grid := GridContainer.new()
	equipment_grid.columns = 3
	equipment_grid.add_theme_constant_override("h_separation", 7)
	equipment_grid.add_theme_constant_override("v_separation", 7)
	equipment_box.add_child(equipment_grid)
	for slot in ["", "头盔", "", "武器", "盔甲", "臂甲", "", "鞋子", "饰品"]:
		if str(slot).is_empty():
			var blank := Control.new()
			blank.custom_minimum_size = Vector2(112, 74)
			equipment_grid.add_child(blank)
		else:
			equipment_grid.add_child(_map_equipment_slot_card(str(slot)))
	var inventory_card := _map_hud_card("物品", "消耗品和装备可以直接使用。")
	inventory_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(inventory_card)
	var inventory_box := inventory_card.get_child(0) as VBoxContainer
	var bag_scroll := ScrollContainer.new()
	bag_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_box.add_child(bag_scroll)
	var bag_list := VBoxContainer.new()
	bag_list.add_theme_constant_override("separation", 8)
	bag_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_scroll.add_child(bag_list)
	if GameState.player.inventory.is_empty():
		bag_list.add_child(_muted("背包为空。"))
	for item_id in GameState.player.inventory.keys():
		bag_list.add_child(_map_bag_item_row(str(item_id)))

func _map_equipment_slot_card(slot: String) -> PanelContainer:
	var card := _facility_frame(Color(0.05, 0.1, 0.12, 0.5), Color(1, 1, 1, 0.38))
	card.custom_minimum_size = Vector2(112, 82)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	box.add_child(_muted(slot))
	var item_id = GameState.player.equipment.get(slot)
	var name := _heading("未装备" if item_id == null else _item_name(str(item_id)), 14)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name)
	if item_id != null:
		var unequip := _outline_button("卸下")
		unequip.custom_minimum_size = Vector2(82, 26)
		unequip.pressed.connect(func():
			GameState.unequip_slot(slot)
			GameState.player.hp = mini(int(GameState.player.hp), _effective_combat("生命"))
			_show_map_bag_panel()
		)
		box.add_child(unequip)
	return card

func _map_bag_item_row(item_id: String) -> PanelContainer:
	var definition := _find_content_item(item_id)
	var row_card := _facility_frame(Color(0.05, 0.1, 0.12, 0.5), Color(1, 1, 1, 0.38))
	row_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_card.custom_minimum_size.y = 62
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row_card.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var kind: String = str(definition.get("slot", definition.get("type", "其他")))
	var item_title := _heading("%s x%d" % [definition.get("name", item_id), int(GameState.player.inventory[item_id])], 16)
	item_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(item_title)
	info.add_child(_muted(kind))
	if item_id == "item.ration":
		var eat := _outline_button("食用")
		eat.custom_minimum_size = Vector2(76, 30)
		eat.pressed.connect(func():
			if GameState.eat_ration():
				_update_time_status()
				_toast("食用旅行口粮，恢复30点饱腹")
			_show_map_bag_panel()
		)
		row.add_child(eat)
	elif definition.has("slot"):
		var equip := _outline_button("装备")
		equip.custom_minimum_size = Vector2(76, 30)
		equip.pressed.connect(func():
			if GameState.equip_item(item_id, str(definition.slot)):
				GameState.player.hp = mini(int(GameState.player.hp), _effective_combat("生命"))
				_toast("已装备：" + _item_name(item_id))
			_show_map_bag_panel()
		)
		row.add_child(equip)
	return row_card

func _show_map_relations_panel() -> void:
	var box := _map_overlay_panel("好感度", Vector2(620, 360))
	var note := _facility_rule_line("从 0 起算，关键事件会改变关系值")
	box.add_child(note)
	var relations: Dictionary = GameState.world.get("relations", {})
	for name in relations.keys():
		var value := int(relations[name])
		var row_card := _map_hud_card("%s  %+d" % [name, value], "当前关系进度")
		box.add_child(row_card)
		var row_box := row_card.get_child(0) as VBoxContainer
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 10
		bar.value = clampi(value, 0, 10)
		bar.custom_minimum_size.y = 20
		row_box.add_child(bar)

func _show_map_system_panel() -> void:
	var box := _map_overlay_panel("系统", Vector2(460, 300))
	box.add_child(_facility_rule_line("保存、读取或退出当前原型"))
	for spec in [["保存", func(): _toast("保存成功" if GameState.save_game() else "保存失败")], ["读取", func(): _load_game()], ["退出", func(): get_tree().quit()]]:
		var button := _outline_button(str(spec[0]))
		button.custom_minimum_size = Vector2(220, 34)
		button.pressed.connect(spec[1])
		box.add_child(button)

func _map_marker_events() -> Array:
	var result: Array = []
	for event in _all_event_definitions():
		var location := str(event.get("location", ""))
		if location.is_empty() or not _location_unlocked(location) or not _event_unlocked(event.id):
			continue
		if bool(event.get("repeatable", false)):
			result.append(event)
		elif not GameState.world.visited.has(event.id):
			result.append(event)
	return result

func _ensure_event_countdown_state() -> void:
	if not GameState.world.has("event_countdowns") or not GameState.world.event_countdowns is Dictionary:
		GameState.world.event_countdowns = {}

func _sync_visible_event_countdowns() -> void:
	_ensure_event_countdown_state()
	var countdowns: Dictionary = GameState.world.event_countdowns
	for event in _map_marker_events():
		var event_id := str(event.get("id", ""))
		if event_id.is_empty() or GameState.world.visited.has(event_id):
			countdowns.erase(event_id)
			continue
		var days := int(event.get("countdown_days", 0))
		if days <= 0:
			countdowns.erase(event_id)
			continue
		if not countdowns.has(event_id):
			countdowns[event_id] = days

func _event_countdown_remaining(event: Dictionary) -> int:
	_ensure_event_countdown_state()
	var event_id := str(event.get("id", ""))
	if event_id.is_empty() or not GameState.world.event_countdowns.has(event_id):
		return 0
	return int(GameState.world.event_countdowns[event_id])

func _map_service_markers() -> Array:
	var result: Array = []
	if _location_unlocked("黑帆酒馆"):
		result.append({"id":"inn", "title":"黑帆旅馆", "location":"黑帆酒馆", "icon":"旅", "position":Vector2(650, 120), "color":Color("7fdc8f"), "callback":show_inn})
	if _location_unlocked("雾港广场"):
		result.append({"id":"shop", "title":"雾港杂货商", "location":"雾港广场", "icon":"商", "position":Vector2(555, 195), "color":Color("f1cf74"), "callback":show_shop})
	return result

func _make_map_service_marker(service: Dictionary, map_layer: Control) -> Button:
	var marker := Button.new()
	marker.text = str(service.get("icon", "•"))
	marker.tooltip_text = "%s\n%s · 设施入口\n点击进入" % [service.get("title", ""), service.get("location", "")]
	marker.custom_minimum_size = Vector2(42, 42)
	marker.add_theme_font_size_override("font_size", 18)
	var marker_color: Color = service.get("color", accent)
	marker.add_theme_stylebox_override("normal", _box(marker_color, 21, 1))
	marker.add_theme_stylebox_override("hover", _box(marker_color.lightened(0.16), 21, 1))
	marker.add_theme_stylebox_override("pressed", _box(marker_color.darkened(0.12), 21, 1))
	marker.add_theme_color_override("font_color", Color("07151a"))
	var callback: Callable = service.get("callback", show_map)
	marker.pressed.connect(func(): _zoom_map_to_marker_then(map_layer, marker, callback))
	return marker

func _make_map_marker(event: Dictionary, map_layer: Control) -> Button:
	var marker := Button.new()
	var icon := _map_marker_icon(event)
	marker.text = icon
	marker.tooltip_text = "%s\n%s · %s\n点击进入" % [event.get("title", event.get("id", "")), event.get("location", ""), _map_marker_kind(event)]
	marker.custom_minimum_size = Vector2(42, 42)
	marker.add_theme_font_size_override("font_size", 22)
	var remaining_days := _event_countdown_remaining(event)
	if remaining_days > 0:
		marker.text = "%s\n%d天" % [icon, remaining_days]
		marker.tooltip_text += "\n倒计时：剩余%d天" % remaining_days
		marker.custom_minimum_size = Vector2(50, 50)
		marker.add_theme_font_size_override("font_size", 16)
	var marker_color := _map_marker_color(event)
	marker.add_theme_stylebox_override("normal", _box(marker_color, 21, 1))
	marker.add_theme_stylebox_override("hover", _box(marker_color.lightened(0.16), 21, 1))
	marker.add_theme_stylebox_override("pressed", _box(marker_color.darkened(0.12), 21, 1))
	marker.add_theme_color_override("font_color", Color("07151a"))
	marker.disabled = int(GameState.world.action_points) < int(event.get("action_cost", 1))
	var event_id := str(event.id)
	marker.pressed.connect(func(): _zoom_map_to_marker_then(map_layer, marker, func(): _start_event(event_id)))
	return marker

func _zoom_map_to_marker_then(map_layer: Control, marker: Control, callback: Callable) -> void:
	if map_layer == null or marker == null or not is_instance_valid(map_layer) or not is_instance_valid(marker):
		callback.call()
		return
	if bool(map_layer.get_meta("zooming", false)):
		return
	map_layer.set_meta("zooming", true)
	var canvas_size := _map_canvas_size(map_layer)
	var focus_position := _map_marker_center(marker)
	last_map_focus_position = focus_position
	last_map_canvas_size = canvas_size
	has_map_focus = true
	var target_scale := Vector2(MAP_CLICK_ZOOM_SCALE, MAP_CLICK_ZOOM_SCALE)
	var target_position := _map_focus_position(focus_position, canvas_size, MAP_CLICK_ZOOM_SCALE)
	var transition_shade := map_layer.get_meta("transition_shade", null) as ColorRect
	if transition_shade != null and is_instance_valid(transition_shade):
		transition_shade.color = Color(0.03, 0.06, 0.1, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(map_layer, "scale", target_scale, MAP_CLICK_ZOOM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(map_layer, "position", target_position, MAP_CLICK_ZOOM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if transition_shade != null and is_instance_valid(transition_shade):
		tween.tween_property(transition_shade, "color", Color(0.03, 0.06, 0.1, MAP_CLICK_FADE_ALPHA), MAP_CLICK_ZOOM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	if is_instance_valid(map_layer):
		map_layer.set_meta("zooming", false)
	callback.call()

func _map_canvas_size(map_layer: Control) -> Vector2:
	var canvas := map_layer.get_parent() as Control
	var canvas_size := canvas.size if canvas != null else MAP_CANVAS_FALLBACK_SIZE
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0:
		return MAP_CANVAS_FALLBACK_SIZE
	return canvas_size

func _map_marker_center(marker: Control) -> Vector2:
	var marker_size := marker.size
	if marker_size.x <= 0.0 or marker_size.y <= 0.0:
		marker_size = marker.custom_minimum_size
	return marker.position + marker_size * 0.5

func _map_focus_position(focus: Vector2, canvas_size: Vector2, zoom_scale: float) -> Vector2:
	var target_position := canvas_size * 0.5 - focus * zoom_scale
	var min_position := canvas_size - canvas_size * zoom_scale
	target_position.x = clampf(target_position.x, min_position.x, 0.0)
	target_position.y = clampf(target_position.y, min_position.y, 0.0)
	return target_position

func _map_marker_icon(event: Dictionary) -> String:
	if bool(event.get("repeatable", false)):
		return "↻"
	if event.get("type", "剧情事件") == "随机事件":
		return "✦"
	return "◆"

func _map_marker_kind(event: Dictionary) -> String:
	if bool(event.get("repeatable", false)):
		return "可重复事件"
	if event.get("type", "剧情事件") == "随机事件":
		return "随机事件"
	return "剧情事件"

func _map_marker_color(event: Dictionary) -> Color:
	if bool(event.get("repeatable", false)):
		return Color("62d4c7")
	if event.get("type", "剧情事件") == "随机事件":
		return Color("e8b75d")
	return Color("9fb0ff")

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
		var random_event := _select_random_location_event(location)
		if not random_event.is_empty():
			GameState.add_log("地图触发随机事件：%s @ %s" % [random_event.title, location])
			_start_event(random_event.id)
			return
	GameState.add_log("移动至：" + location)
	_start_event(entry_id)

func _select_random_location_event(location: String) -> Dictionary:
	var candidates: Array = []
	for event in _all_event_definitions():
		if event.get("location", "") == location and event.get("type", "剧情事件") == "随机事件" and not GameState.world.visited.has(event.id) and _event_unlocked(event.id):
			if int(GameState.world.random_cooldowns.get(event.id, 0)) <= int(GameState.world.minutes):
				candidates.append(event)
	if candidates.is_empty():
		return {}
	var seed: int = int(GameState.world.get("random_seed", 137))
	var index: int = abs(seed + int(GameState.world.minutes) + location.hash()) % candidates.size()
	var selected: Dictionary = candidates[index]
	GameState.world.random_seed = (seed * 1103515245 + 12345) & 0x7fffffff
	GameState.world.random_cooldowns[selected.id] = int(GameState.world.minutes) + 3
	return selected

func _choose(option: Dictionary) -> void:
	if option.has("flag"):
		GameState.world.flags[option.flag] = true
	if option.has("quest") and option.quest is Dictionary:
		var quest: Dictionary = option.quest
		GameState.set_quest(str(quest.get("id", "custom")), str(quest.get("title", "任务")), str(quest.get("status", "进行中")), str(quest.get("clue", "")))
	if option.has("relation") and option.relation is Dictionary:
		GameState.adjust_relation(str(option.relation.get("name", "")), int(option.relation.get("delta", 0)))
	if option.has("coins"):
		GameState.player.coins = int(GameState.player.get("coins", 0)) + int(option.coins)
	if option.has("stat_rewards") and option.stat_rewards is Array:
		for reward in option.stat_rewards:
			if reward is Dictionary:
				_apply_stat_reward(reward)
	if option.has("stat_reward") and option.stat_reward is Dictionary:
		_apply_stat_reward(option.stat_reward)
	if option.has("item") and (int(option.get("item_quantity", 1)) > 1 or not GameState.has_item(option.item)):
		GameState.add_item(option.item, int(option.get("item_quantity", 1)))
		GameState.add_log("获得物品：" + option.item)
	if option.has("damage"):
		GameState.player.hp = max(1, int(GameState.player.hp) - int(option.damage))
	if option.has("action"):
		match option.action:
			"open_growth": show_growth()
			"open_map": show_map()
			"d20_check": _perform_check(option)
			"resource_check": _perform_resource_check(option)
			"start_battle": show_battle(true, option)
			"summary": show_summary()
		return
	if option.has("next"):
		show_event(option.next)

func _apply_stat_reward(reward: Dictionary) -> void:
	var track := str(reward.get("track", "growth"))
	var stat := str(reward.get("stat", ""))
	var amount := int(reward.get("amount", 0))
	var target: Dictionary = GameState.player.growth if track == "growth" else GameState.player.combat
	if stat.is_empty() or amount == 0 or not target.has(stat):
		return
	target[stat] = int(target.get(stat, 8)) + amount
	if track == "combat" and stat == "生命":
		GameState.player.hp = mini(_effective_combat("生命"), int(GameState.player.hp) + amount)
	GameState.add_log("事件奖励：%s %+d" % [stat, amount])

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
	var rest_button := _button("前往旅馆休息")
	rest_button.pressed.connect(show_inn)
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
	bag_box.add_child(_muted("银币：%d" % int(GameState.player.get("coins", 0))))
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

func show_battle(new_battle: bool, battle_config: Dictionary = {}) -> void:
	current_view = "battle"
	if new_battle or GameState.battle.is_empty():
		var enemy_id := str(battle_config.get("enemy", "enemy.brine_thrall"))
		var enemy: Dictionary = _prepare_enemy(_find_entity("enemies", enemy_id))
		if enemy.is_empty():
			enemy = _prepare_enemy(_find_entity("enemies", "enemy.brine_thrall"))
		if GameState.world.flags.get("battle_advantage", false):
			enemy.hp -= 3
		GameState.battle = {
			"active": true,
			"enemy": enemy,
			"round": 1,
			"guard": false,
			"weakened": false,
			"defeats": 0,
			"enemy_intent": "attack",
			"victory_event": str(battle_config.get("victory", "after_battle")),
			"log": [str(battle_config.get("battle_intro", "%s拦住了去路！" % enemy.get("name", "敌人")))]
		}
	_clear_view()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	content_root.add_child(root)
	root.add_child(_heading("回合制战斗 · %s" % GameState.world.get("location", "未知地点"), 30))
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
	combat_box.add_child(_muted("%s\n敌方意图：%s" % [GameState.battle.enemy.get("role", "敌对目标"), _enemy_intent_text()]))
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	combat_box.add_child(actions)
	for spec in [["攻击", "attack"], ["强攻", "power"], ["快攻", "quick"], ["防御姿态", "guard"], ["洞察弱点", "inspect"], ["使用提神药剂", "item"], ["撤退重整", "retreat"]]:
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
				battle_state.log.append("你掷出%d，攻击被%s挡开。" % [hit.total, battle_state.enemy.get("name", "敌人")])
		"power":
			var hit: Dictionary = DiceClass.d20(floori((_effective_combat("力量") - 8) / 2.0) - 1)
			if hit.total >= int(battle_state.enemy.defense):
				var dealt := DiceClass.damage(8, floori((_effective_combat("力量") - 8) / 2.0))
				if battle_state.weakened:
					dealt += 2
				battle_state.enemy.hp = int(battle_state.enemy.hp) - dealt
				battle_state.log.append("你冒险强攻，掷出%d，造成%d点伤害。" % [hit.total, dealt])
			else:
				battle_state.log.append("强攻落空，盐蚀傀儡抓住了破绽。")
		"quick":
			var hit: Dictionary = DiceClass.d20(floori((_effective_combat("速度") - 8) / 2.0))
			if hit.total >= int(battle_state.enemy.defense) - 2:
				var dealt := DiceClass.damage(4, floori((_effective_combat("技巧") - 8) / 2.0))
				if battle_state.weakened:
					dealt += 1
				battle_state.enemy.hp = int(battle_state.enemy.hp) - dealt
				battle_state.guard = true
				battle_state.log.append("你快速射击，造成%d点伤害并保持距离。" % dealt)
			else:
				battle_state.log.append("快攻未能命中。")
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
		"retreat":
			battle_state.active = false
			GameState.world.active_continuous = ""
			GameState.add_log("战斗中撤退，重整行动")
			show_map()
			return
	if int(battle_state.enemy.hp) <= 0:
		battle_state.log.append("%s倒下了。" % battle_state.enemy.get("name", "敌人"))
		battle_state.active = false
		GameState.world.battle_won = true
		GameState.add_log("战斗胜利，共%d回合" % int(battle_state.round))
		show_event(str(battle_state.get("victory_event", "after_battle")))
		return
	_enemy_turn()
	if int(GameState.player.hp) <= 0:
		battle_state.defeats = int(battle_state.get("defeats", 0)) + 1
		if int(battle_state.defeats) >= 2:
			battle_state.active = false
			GameState.player.hp = 1
			GameState.world.active_continuous = ""
			GameState.add_log("战斗失败，撤出地下钟室")
			show_map()
			return
		GameState.player.hp = max(5, floori(_effective_combat("生命") / 2.0))
		battle_state.enemy.hp = int(battle_state.enemy.hp) + 3
		battle_state.log.append("你倒下后被林鸦唤醒；她替你挡住一击，但敌人恢复了力量。")
	battle_state.round = int(battle_state.round) + 1
	battle_state.enemy_intent = "heavy" if int(battle_state.round) % 3 == 0 else ("guard_break" if battle_state.weakened else "attack")
	show_battle(false)

func _enemy_turn() -> void:
	var battle_state: Dictionary = GameState.battle
	var intent := str(battle_state.get("enemy_intent", "attack"))
	var hit_bonus := int(battle_state.enemy.get("hit_modifier", battle_state.enemy.get("attack", 0))) + (1 if intent == "guard_break" else 0)
	var hit: Dictionary = DiceClass.d20(hit_bonus)
	var defense := 10 + floori((_effective_combat("防御") - 8) / 2.0)
	if hit.total >= defense:
		var damage := DiceClass.damage(7 if intent == "heavy" else 5, int(battle_state.enemy.get("damage_modifier", 1)))
		if battle_state.guard:
			damage = damage if intent == "guard_break" else ceili(damage / 2.0)
		GameState.player.hp = int(GameState.player.hp) - damage
		battle_state.log.append("%s掷出%d，造成%d点伤害。" % [battle_state.enemy.get("name", "敌人"), hit.total, damage])
	else:
		battle_state.log.append("%s掷出%d，攻击从你身边掠过。" % [battle_state.enemy.get("name", "敌人"), hit.total])
	battle_state.guard = false

func _enemy_intent_text() -> String:
	match str(GameState.battle.get("enemy_intent", "attack")):
		"heavy":
			return "蓄力重击"
		"guard_break":
			return "破防横扫"
	return "普通攻击"

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
	content.add_child(_heading("事件发生点", 24))
	content.add_child(_muted("发生点决定事件入口在大地图上的显示位置；创建事件时会从这里选择发生点。点击下方地图设置发生点坐标。"))
	content.add_child(_build_map_point_picker())
	var point_editor := HBoxContainer.new()
	point_editor.add_theme_constant_override("separation", 12)
	content.add_child(point_editor)
	map_point_list = ItemList.new()
	map_point_list.custom_minimum_size = Vector2(330, 190)
	map_point_list.item_selected.connect(_select_map_point)
	point_editor.add_child(map_point_list)
	var point_form := VBoxContainer.new()
	point_form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	point_editor.add_child(point_form)
	point_form.add_child(_muted("发生点名称"))
	map_point_name = LineEdit.new()
	map_point_name.placeholder_text = "例如：旧码头仓库"
	point_form.add_child(map_point_name)
	point_form.add_child(_muted("当前坐标"))
	map_point_position_label = _muted("")
	point_form.add_child(map_point_position_label)
	_set_map_point_draft_position(draft_map_point_position)
	var point_buttons := HBoxContainer.new()
	point_form.add_child(point_buttons)
	var save_point := _button("保存发生点", true)
	save_point.pressed.connect(_save_map_point)
	point_buttons.add_child(save_point)
	var new_point := _button("清空表单")
	new_point.pressed.connect(_clear_map_point_form)
	point_buttons.add_child(new_point)
	var delete_point := _button("删除自定义点")
	delete_point.pressed.connect(_delete_map_point)
	point_form.add_child(delete_point)
	_refresh_map_point_list()
	var save := _button("保存大地图图片与音乐", true)
	save.pressed.connect(func():
		GameState.custom_content.map_background = map_background_path.text
		GameState.custom_content.map_music = map_music_path.text
		GameState.save_custom_content()
		_activate_map_music()
		_toast("大地图素材已保存")
	)
	content.add_child(save)

func _build_map_point_picker() -> PanelContainer:
	var holder := _panel_container(Color("101724"))
	holder.custom_minimum_size = Vector2(0, 320)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_point_picker_canvas = Control.new()
	map_point_picker_canvas.clip_contents = true
	map_point_picker_canvas.custom_minimum_size = MAP_CANVAS_FALLBACK_SIZE
	map_point_picker_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_point_picker_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	map_point_picker_canvas.gui_input.connect(_on_map_point_picker_input)
	holder.add_child(map_point_picker_canvas)
	var path := map_background_path.text if map_background_path != null else str(GameState.custom_content.get("map_background", ""))
	var map_texture := _texture_from_path(path, DEFAULT_MAP_IMAGE)
	if map_texture != null:
		var map_view := TextureRect.new()
		map_view.texture = map_texture
		map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		map_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		map_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_point_picker_canvas.add_child(map_view)
	_refresh_map_point_picker_markers()
	return holder

func _refresh_map_point_picker_texture() -> void:
	if map_point_picker_canvas == null:
		return
	var path := map_background_path.text if map_background_path != null else str(GameState.custom_content.get("map_background", ""))
	var map_texture := _texture_from_path(path, DEFAULT_MAP_IMAGE)
	for child in map_point_picker_canvas.get_children():
		if child is TextureRect:
			child.texture = map_texture
			break

func _on_map_point_picker_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var size := map_point_picker_canvas.size
		var position := Vector2(clampf(event.position.x, 0.0, size.x), clampf(event.position.y, 0.0, size.y))
		_set_map_point_draft_position(position)
		_refresh_map_point_picker_markers()

func _set_map_point_draft_position(position: Vector2) -> void:
	draft_map_point_position = Vector2(roundi(position.x), roundi(position.y))
	if map_point_position_label != null:
		map_point_position_label.text = "X %d · Y %d" % [int(draft_map_point_position.x), int(draft_map_point_position.y)]

func _refresh_map_point_picker_markers() -> void:
	if map_point_picker_canvas == null:
		return
	for child in map_point_picker_canvas.get_children():
		if child.get_meta("map_point_marker", false):
			child.queue_free()
	for point in _all_map_points():
		var marker := _map_point_preview_marker(str(point.get("name", "")), Vector2(float(point.get("x", 480)), float(point.get("y", 150))), bool(point.get("builtin", false)))
		map_point_picker_canvas.add_child(marker)
	var draft_marker := _map_point_preview_marker("当前选择", draft_map_point_position, false, true)
	map_point_picker_canvas.add_child(draft_marker)

func _map_point_preview_marker(label_text: String, position: Vector2, builtin: bool, is_draft: bool = false) -> Label:
	var marker := Label.new()
	marker.set_meta("map_point_marker", true)
	marker.text = "● " + label_text
	marker.position = position - Vector2(8, 12)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_theme_font_size_override("font_size", 15 if is_draft else 13)
	marker.add_theme_color_override("font_color", gold if is_draft else (text_dim if builtin else accent))
	return marker

func _refresh_map_point_list() -> void:
	if map_point_list == null:
		return
	map_point_list.clear()
	for point in _all_map_points():
		var name := str(point.get("name", ""))
		var source := "内置" if bool(point.get("builtin", false)) else "自定义"
		var index := map_point_list.item_count
		map_point_list.add_item("[%s] %s  (%d, %d)" % [source, name, int(point.get("x", 0)), int(point.get("y", 0))])
		map_point_list.set_item_metadata(index, point)

func _select_map_point(index: int) -> void:
	selected_map_point_index = index
	if map_point_list == null or index < 0 or index >= map_point_list.item_count:
		return
	var point: Dictionary = map_point_list.get_item_metadata(index)
	map_point_name.text = str(point.get("name", ""))
	_set_map_point_draft_position(Vector2(float(point.get("x", 480)), float(point.get("y", 150))))
	_refresh_map_point_picker_markers()

func _clear_map_point_form() -> void:
	selected_map_point_index = -1
	if map_point_list != null:
		map_point_list.deselect_all()
	if map_point_name != null:
		map_point_name.text = ""
		_set_map_point_draft_position(Vector2(480, 150))
		_refresh_map_point_picker_markers()

func _save_map_point() -> void:
	var name := map_point_name.text.strip_edges()
	if name.is_empty():
		_toast("发生点名称不能为空")
		return
	var points := _custom_map_points()
	var entry := {"name": name, "x": int(draft_map_point_position.x), "y": int(draft_map_point_position.y)}
	var replaced := false
	for i in range(points.size()):
		if points[i] is Dictionary and str(points[i].get("name", "")) == name:
			points[i] = entry
			replaced = true
			break
	if not replaced:
		points.append(entry)
	GameState.save_custom_content()
	_refresh_content_validation()
	_refresh_map_point_list()
	_refresh_map_point_picker_markers()
	_refresh_editor_location_picker(name)
	_toast("发生点已保存")

func _delete_map_point() -> void:
	var name := map_point_name.text.strip_edges()
	if name.is_empty():
		_toast("请选择或输入要删除的自定义发生点")
		return
	var points := _custom_map_points()
	for i in range(points.size()):
		if points[i] is Dictionary and str(points[i].get("name", "")) == name:
			points.remove_at(i)
			GameState.save_custom_content()
			_refresh_content_validation()
			_refresh_map_point_list()
			_refresh_map_point_picker_markers()
			_refresh_editor_location_picker()
			_clear_map_point_form()
			_toast("自定义发生点已删除")
			return
	_toast("内置发生点不能删除；如有同名自定义覆盖，可先保存后再删除覆盖")

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
		editor_list.add_item("[内置%s] %s · %s" % ["·锁" if event.get("locked", false) else "", event.title, event.get("id", "")])
	for event in GameState.custom_content.events:
		var state_tags := ""
		if bool(event.get("draft", false)):
			state_tags += "·未完善"
		if bool(event.get("locked", false)):
			state_tags += "·锁"
		editor_list.add_item("[自定义%s] %s · %s" % [state_tags, event.get("name", event.get("title", "")), event.get("id", "")])
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
	form.add_child(_muted("事件ID（用于前置锁和跳转）"))
	editor_event_id = LineEdit.new()
	editor_event_id.placeholder_text = "例如：harbor_clue_01"
	form.add_child(editor_event_id)
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
	_refresh_editor_location_picker()
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
	editor_draft = CheckBox.new()
	editor_draft.text = "事件数据未完善，暂不可使用"
	form.add_child(editor_draft)
	editor_ends_continuous = CheckBox.new()
	editor_ends_continuous.text = "到达此事件时结束连续流程"
	form.add_child(editor_ends_continuous)
	form.add_child(_muted("主动开始消耗的行动点"))
	editor_action_cost = SpinBox.new()
	editor_action_cost.min_value = 0
	editor_action_cost.max_value = 3
	editor_action_cost.value = 1
	form.add_child(editor_action_cost)
	form.add_child(_muted("地图倒计时天数（0表示不开启）"))
	editor_countdown_days = SpinBox.new()
	editor_countdown_days.min_value = 0
	editor_countdown_days.max_value = 99
	editor_countdown_days.value = 0
	form.add_child(editor_countdown_days)
	form.add_child(_muted("倒计时结束后自动触发的事件"))
	editor_timeout_event = OptionButton.new()
	form.add_child(editor_timeout_event)
	form.add_child(_muted("正文/设计说明"))
	editor_text = TextEdit.new()
	editor_text.custom_minimum_size.y = 130
	editor_text.placeholder_text = "输入事件内容；运行时可继续扩展为节点。"
	form.add_child(editor_text)
	form.add_child(_heading("选项动作", 18))
	editor_options_list = ItemList.new()
	editor_options_list.custom_minimum_size.y = 96
	editor_options_list.item_selected.connect(_select_editor_option)
	form.add_child(editor_options_list)
	var option_buttons := HBoxContainer.new()
	form.add_child(option_buttons)
	var add_option := _button("新增选项")
	add_option.pressed.connect(_add_editor_option)
	option_buttons.add_child(add_option)
	var apply_option := _button("更新选项", true)
	apply_option.pressed.connect(_apply_editor_option)
	option_buttons.add_child(apply_option)
	var remove_option := _button("删除选项")
	remove_option.pressed.connect(_remove_editor_option)
	option_buttons.add_child(remove_option)
	form.add_child(_muted("选项文本"))
	editor_option_text = LineEdit.new()
	form.add_child(editor_option_text)
	form.add_child(_muted("动作类型"))
	editor_option_action = OptionButton.new()
	for action_id in EventActionSchema.action_ids():
		editor_option_action.add_item(EventActionSchema.action_label(str(action_id)))
		editor_option_action.set_item_metadata(editor_option_action.item_count - 1, str(action_id))
	form.add_child(editor_option_action)
	form.add_child(_muted("普通跳转目标"))
	editor_option_next = OptionButton.new()
	form.add_child(editor_option_next)
	form.add_child(_muted("D20 成功 / 失败目标"))
	var check_targets := HBoxContainer.new()
	form.add_child(check_targets)
	editor_option_success = OptionButton.new()
	editor_option_success.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check_targets.add_child(editor_option_success)
	editor_option_failure = OptionButton.new()
	editor_option_failure.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check_targets.add_child(editor_option_failure)
	form.add_child(_muted("检定属性 / 难度"))
	var check_row := HBoxContainer.new()
	form.add_child(check_row)
	editor_option_stat = OptionButton.new()
	for stat in ContentSchema.CHECK_STATS:
		editor_option_stat.add_item(stat)
	check_row.add_child(editor_option_stat)
	editor_option_difficulty = SpinBox.new()
	editor_option_difficulty.min_value = 1
	editor_option_difficulty.max_value = 30
	editor_option_difficulty.value = 10
	check_row.add_child(editor_option_difficulty)
	form.add_child(_muted("资源奖励 / 直接获得物品"))
	var item_row := HBoxContainer.new()
	form.add_child(item_row)
	editor_option_resource = OptionButton.new()
	editor_option_resource.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_row.add_child(editor_option_resource)
	editor_option_item = OptionButton.new()
	editor_option_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_row.add_child(editor_option_item)
	form.add_child(_muted("设置 flag / 伤害"))
	var effect_row := HBoxContainer.new()
	form.add_child(effect_row)
	editor_option_flag = LineEdit.new()
	editor_option_flag.placeholder_text = "可为空"
	editor_option_flag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_row.add_child(editor_option_flag)
	editor_option_damage = SpinBox.new()
	editor_option_damage.min_value = 0
	editor_option_damage.max_value = 99
	effect_row.add_child(editor_option_damage)
	var save := _button("保存自定义事件", true)
	save.pressed.connect(_save_editor_event)
	form.add_child(save)
	var remove := _button("删除选中自定义事件")
	remove.pressed.connect(_delete_editor_event)
	form.add_child(remove)

func _select_event(index: int) -> void:
	selected_editor_index = index
	_refresh_event_option_pickers()
	if index < scenario.events.size():
		var event: Dictionary = scenario.events[index]
		editor_event_id.text = event.get("id", "")
		editor_event_id.editable = false
		editor_name.text = event.title
		editor_type.select(0 if event.type == "剧情事件" else 1)
		_select_location_value(event.get("location", "雾港码头"))
		editor_background_path.text = event.get("background_image", "")
		_set_preview(editor_background_preview, editor_background_path.text)
		editor_music_path.text = event.get("music", "")
		_set_event_lock_form(event)
		_set_event_schedule_form(event)
		editor_draft.button_pressed = bool(event.get("draft", false))
		editor_text.text = event.text
		_set_event_options_form(event)
		_refresh_event_preview(event)
	else:
		var custom_index: int = index - scenario.events.size()
		if custom_index >= 0 and custom_index < GameState.custom_content.events.size():
			var event: Dictionary = GameState.custom_content.events[custom_index]
			editor_event_id.text = event.get("id", "")
			editor_event_id.editable = true
			editor_name.text = event.name
			editor_type.select(0 if event.type == "剧情事件" else 1)
			_select_location_value(event.get("location", "雾港码头"))
			editor_background_path.text = event.get("background_image", "")
			_set_preview(editor_background_preview, editor_background_path.text)
			editor_music_path.text = event.get("music", "")
			_set_event_lock_form(event)
			_set_event_schedule_form(event)
			editor_draft.button_pressed = bool(event.get("draft", false))
			editor_text.text = event.text
			_set_event_options_form(event)
			_refresh_event_preview(event)

func _refresh_event_option_pickers() -> void:
	if editor_option_next == null:
		return
	for picker in [editor_option_next, editor_option_success, editor_option_failure]:
		_populate_event_target_picker(picker)
	if editor_timeout_event != null:
		_populate_event_target_picker(editor_timeout_event)
	for picker in [editor_option_resource, editor_option_item]:
		_populate_option_item_picker(picker)

func _populate_event_target_picker(picker: OptionButton) -> void:
	picker.clear()
	picker.add_item("不跳转")
	picker.set_item_metadata(0, "")
	for event in scenario.get("events", []):
		picker.add_item("%s · %s" % [event.get("id", ""), event.get("title", "")])
		picker.set_item_metadata(picker.item_count - 1, event.get("id", ""))
	for event in GameState.custom_content.get("events", []):
		picker.add_item("%s · %s" % [event.get("id", ""), event.get("title", event.get("name", ""))])
		picker.set_item_metadata(picker.item_count - 1, event.get("id", ""))

func _populate_option_item_picker(picker: OptionButton) -> void:
	picker.clear()
	picker.add_item("不设置")
	picker.set_item_metadata(0, "")
	for entry in _all_equipment() + _all_items():
		picker.add_item("%s · %s" % [entry.get("id", ""), entry.get("name", "")])
		picker.set_item_metadata(picker.item_count - 1, entry.get("id", ""))

func _set_event_options_form(event: Dictionary) -> void:
	editor_options = event.get("options", [{"text":"返回地图", "action":"open_map"}]).duplicate(true)
	selected_editor_option_index = -1
	_refresh_editor_options_list()
	if not editor_options.is_empty():
		_select_editor_option(0)

func _refresh_editor_options_list() -> void:
	if editor_options_list == null:
		return
	editor_options_list.clear()
	for option in editor_options:
		editor_options_list.add_item(_option_summary(option))

func _option_summary(option: Dictionary) -> String:
	var action_id := str(option.get("action", ""))
	var target := ""
	if option.has("next"):
		target = " -> " + str(option.next)
	elif option.has("success") or option.has("failure"):
		target = " -> %s / %s" % [option.get("success", ""), option.get("failure", "")]
	return "%s [%s]%s" % [option.get("text", "继续"), EventActionSchema.action_label(action_id), target]

func _select_editor_option(index: int) -> void:
	if index < 0 or index >= editor_options.size():
		return
	selected_editor_option_index = index
	if editor_options_list != null:
		editor_options_list.select(index)
	_write_editor_option_fields(editor_options[index])

func _write_editor_option_fields(option: Dictionary) -> void:
	editor_option_text.text = option.get("text", "继续")
	_select_picker_metadata(editor_option_action, str(option.get("action", "")))
	_select_picker_metadata(editor_option_next, str(option.get("next", "")))
	_select_picker_metadata(editor_option_success, str(option.get("success", "")))
	_select_picker_metadata(editor_option_failure, str(option.get("failure", "")))
	_select_picker_text(editor_option_stat, str(option.get("stat", "洞察")))
	editor_option_difficulty.value = int(option.get("difficulty", 10))
	_select_picker_metadata(editor_option_resource, str(option.get("resource", "")))
	_select_picker_metadata(editor_option_item, str(option.get("item", "")))
	editor_option_damage.value = int(option.get("damage", 0))
	editor_option_flag.text = str(option.get("flag", ""))

func _read_editor_option_fields() -> Dictionary:
	var option := {"text": editor_option_text.text.strip_edges() if not editor_option_text.text.strip_edges().is_empty() else "继续"}
	var action_id := str(editor_option_action.get_item_metadata(editor_option_action.selected))
	var flag := editor_option_flag.text.strip_edges()
	var item_id := str(editor_option_item.get_item_metadata(editor_option_item.selected))
	if not flag.is_empty():
		option.flag = flag
	if int(editor_option_damage.value) > 0:
		option.damage = int(editor_option_damage.value)
	if not item_id.is_empty() and action_id != "resource_check":
		option.item = item_id
	if action_id.is_empty():
		var next_id := str(editor_option_next.get_item_metadata(editor_option_next.selected))
		if not next_id.is_empty():
			option.next = next_id
	else:
		option.action = action_id
		match action_id:
			"d20_check":
				option.stat = editor_option_stat.get_item_text(editor_option_stat.selected)
				option.difficulty = int(editor_option_difficulty.value)
				option.success = str(editor_option_success.get_item_metadata(editor_option_success.selected))
				option.failure = str(editor_option_failure.get_item_metadata(editor_option_failure.selected))
			"resource_check":
				option.stat = editor_option_stat.get_item_text(editor_option_stat.selected)
				option.difficulty = int(editor_option_difficulty.value)
				var resource_id := str(editor_option_resource.get_item_metadata(editor_option_resource.selected))
				option.resource = resource_id if not resource_id.is_empty() else "item.ration"
	return option

func _add_editor_option() -> void:
	_refresh_event_option_pickers()
	editor_options.append({"text":"返回地图", "action":"open_map"})
	_refresh_editor_options_list()
	_select_editor_option(editor_options.size() - 1)

func _apply_editor_option() -> void:
	if selected_editor_option_index < 0 or selected_editor_option_index >= editor_options.size():
		_add_editor_option()
		return
	editor_options[selected_editor_option_index] = _read_editor_option_fields()
	_refresh_editor_options_list()
	_select_editor_option(selected_editor_option_index)
	_refresh_event_preview(_event_from_editor_fields())

func _remove_editor_option() -> void:
	if selected_editor_option_index < 0 or selected_editor_option_index >= editor_options.size():
		return
	editor_options.remove_at(selected_editor_option_index)
	selected_editor_option_index = mini(selected_editor_option_index, editor_options.size() - 1)
	_refresh_editor_options_list()
	if selected_editor_option_index >= 0:
		_select_editor_option(selected_editor_option_index)

func _event_from_editor_fields() -> Dictionary:
	var timeout_event := ""
	if editor_timeout_event != null and editor_timeout_event.item_count > 0:
		timeout_event = str(editor_timeout_event.get_item_metadata(editor_timeout_event.selected))
	return {"type":editor_type.get_item_text(editor_type.selected), "location":editor_location.get_item_text(editor_location.selected), "locked":editor_lock.button_pressed, "draft":editor_draft.button_pressed, "prerequisites":editor_prerequisites.text.split(","), "flow_mode":editor_flow_mode.get_item_metadata(editor_flow_mode.selected), "action_cost":int(editor_action_cost.value), "countdown_days":int(editor_countdown_days.value) if editor_countdown_days != null else 0, "timeout_event":timeout_event, "text":editor_text.text, "options":editor_options}

func _refresh_event_preview(event) -> void:
	for child in editor_preview.get_children():
		child.queue_free()
	var nodes: Array = []
	if event == null:
		nodes = [["入口", "选择左侧事件"], ["对话", "编辑属性"], ["出口", "保存内容"]]
	else:
		var lock_text := "\n未完善：不可使用" if event.get("draft", false) else ("\n锁：%s" % ",".join(event.get("prerequisites", [])) if event.get("locked", false) else "\n无事件锁")
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
	_refresh_event_option_pickers()
	editor_event_id.text = ""
	editor_event_id.editable = true
	editor_name.text = "未命名事件"
	editor_type.select(0)
	_select_location_value("雾港码头")
	editor_background_path.text = ""
	_set_preview(editor_background_preview, "")
	editor_music_path.text = ""
	editor_lock.button_pressed = false
	editor_prerequisites.text = ""
	editor_prerequisite_mode.select(0)
	editor_flow_mode.select(0)
	editor_repeatable.button_pressed = false
	editor_draft.button_pressed = false
	editor_ends_continuous.button_pressed = false
	editor_action_cost.value = 1
	if editor_countdown_days != null:
		editor_countdown_days.value = 0
	if editor_timeout_event != null:
		_select_picker_metadata(editor_timeout_event, "")
	editor_text.text = ""
	_set_event_options_form({"options":[{"text":"返回地图", "action":"open_map"}]})
	_refresh_event_preview({"type":"剧情事件", "location":"雾港码头", "locked":false, "text":"新对话节点", "options":editor_options})

func _refresh_editor_location_picker(selected_location: String = "") -> void:
	if editor_location == null:
		return
	var current := selected_location
	if current.is_empty() and editor_location.item_count > 0:
		current = editor_location.get_item_text(editor_location.selected)
	editor_location.clear()
	for location in _map_point_names():
		editor_location.add_item(location)
	if editor_location.item_count == 0:
		editor_location.add_item("雾港码头")
	_select_location_value(current if not current.is_empty() else "雾港码头")

func _select_location_value(location: String) -> void:
	if editor_location.item_count == 0:
		editor_location.add_item(location if not location.is_empty() else "雾港码头")
	for i in range(editor_location.item_count):
		if editor_location.get_item_text(i) == location:
			editor_location.select(i)
			return
	if not location.is_empty():
		editor_location.add_item(location)
		editor_location.select(editor_location.item_count - 1)

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
	editor_draft.button_pressed = bool(event.get("draft", false))
	editor_ends_continuous.button_pressed = bool(event.get("ends_continuous", false))
	editor_action_cost.value = int(event.get("action_cost", 1))
	if editor_countdown_days != null:
		editor_countdown_days.value = int(event.get("countdown_days", 0))
	if editor_timeout_event != null:
		_select_picker_metadata(editor_timeout_event, str(event.get("timeout_event", "")))

func _valid_event_id(event_id: String) -> bool:
	if event_id.is_empty():
		return false
	for i in range(event_id.length()):
		var code := event_id.unicode_at(i)
		var is_digit := code >= 48 and code <= 57
		var is_upper := code >= 65 and code <= 90
		var is_lower := code >= 97 and code <= 122
		var is_symbol := code == 45 or code == 46 or code == 95
		if not (is_digit or is_upper or is_lower or is_symbol):
			return false
	return true

func _custom_event_id_conflicts(event_id: String, current_custom_index: int) -> bool:
	for i in range(GameState.custom_content.events.size()):
		if i != current_custom_index and GameState.custom_content.events[i].get("id", "") == event_id:
			return true
	return false

func _save_editor_event() -> void:
	if editor_name.text.strip_edges().is_empty():
		_toast("事件名称不能为空")
		return
	if editor_event_id.text.strip_edges().is_empty():
		_toast("事件ID不能为空")
		return
	if not _valid_event_id(editor_event_id.text.strip_edges()):
		_toast("事件ID仅支持字母、数字、下划线、点和短横线")
		return
	if selected_editor_option_index >= 0 and selected_editor_option_index < editor_options.size():
		editor_options[selected_editor_option_index] = _read_editor_option_fields()
	var custom_index: int = selected_editor_index - scenario.events.size()
	var event_id := editor_event_id.text.strip_edges()
	if selected_editor_index >= 0 and selected_editor_index < scenario.events.size():
		event_id = scenario.events[selected_editor_index].id
	elif custom_index >= 0 and custom_index < GameState.custom_content.events.size():
		pass
	if _custom_event_id_conflicts(event_id, custom_index):
		_toast("事件ID已被其他自定义事件使用")
		return
	var prerequisites: Array[String] = []
	for raw_id in editor_prerequisites.text.split(","):
		var required_id := raw_id.strip_edges()
		if not required_id.is_empty() and not prerequisites.has(required_id):
			prerequisites.append(required_id)
	var saved_options := editor_options.duplicate(true)
	if saved_options.is_empty():
		saved_options = [{"text":"返回地图", "action":"open_map"}]
	var incomplete_notes := _import_event_incomplete_notes({"location":editor_location.get_item_text(editor_location.selected), "background_image":editor_background_path.text, "music":editor_music_path.text})
	var draft := editor_draft.button_pressed or not incomplete_notes.is_empty()
	var entry := {"id":event_id, "name":editor_name.text.strip_edges(), "title":editor_name.text.strip_edges(), "chapter":"自定义事件", "speaker":"旁白", "type":editor_type.get_item_text(editor_type.selected), "location":editor_location.get_item_text(editor_location.selected), "background_image":editor_background_path.text, "music":editor_music_path.text, "locked":editor_lock.button_pressed, "draft":draft, "import_notes":incomplete_notes if draft else "", "prerequisites":prerequisites, "prerequisite_mode":editor_prerequisite_mode.get_item_metadata(editor_prerequisite_mode.selected), "flow_mode":editor_flow_mode.get_item_metadata(editor_flow_mode.selected), "repeatable":editor_repeatable.button_pressed, "action_cost":int(editor_action_cost.value), "ends_continuous":editor_ends_continuous.button_pressed, "text":editor_text.text, "options":saved_options}
	entry.countdown_days = int(editor_countdown_days.value) if editor_countdown_days != null else 0
	entry.timeout_event = str(editor_timeout_event.get_item_metadata(editor_timeout_event.selected)) if editor_timeout_event != null and editor_timeout_event.item_count > 0 else ""
	if custom_index >= 0 and custom_index < GameState.custom_content.events.size():
		GameState.custom_content.events[custom_index] = entry
	else:
		GameState.custom_content.events.append(entry)
	_reload_event_registry()
	GameState.save_custom_content()
	editor_event_id.text = event_id
	_toast("事件已保存")
	show_tools()

func _delete_editor_event() -> void:
	var custom_index: int = selected_editor_index - scenario.events.size()
	if custom_index >= 0 and custom_index < GameState.custom_content.events.size():
		GameState.custom_content.events.remove_at(custom_index)
		_reload_event_registry()
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

func _select_picker_text(picker: OptionButton, target: String) -> void:
	for i in range(picker.item_count):
		if picker.get_item_text(i) == target:
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

func _validation_text() -> String:
	_refresh_content_validation()
	var lines: Array[String] = []
	lines.append("OK：内容结构校验通过" if content_validation.get("ok", false) else "ERROR：内容结构校验失败")
	for error in content_validation.get("errors", []):
		lines.append("ERROR：%s" % error)
	for warning in content_validation.get("warnings", []):
		lines.append("WARN：%s" % warning)
	if lines.size() == 1:
		lines.append("已检查：JSON结构、事件ID、跳转目标、D20分支、前置条件、角色/敌人装备与背包引用。")
	return "\n".join(lines)

func _build_database_overview(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "内容包概览"
	tabs.add_child(page)
	page.add_child(_heading("剧本包与内容校验", 24))
	page.add_child(_muted("剧本ID：%s   预计时长：%d分钟" % [scenario.get("id", ""), int(scenario.get("estimated_minutes", 0))]))
	page.add_child(_muted("剧情事件：%d   角色：%d   敌人：%d   装备：%d   物品：%d" % [scenario.get("events", []).size(), database.get("characters", []).size(), database.get("enemies", []).size(), database.get("equipment", []).size(), database.get("items", []).size()]))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	page.add_child(actions)
	var import_button := _button("导入剧本包", true)
	import_button.pressed.connect(_request_package_import)
	actions.add_child(import_button)
	var import_events_button := _button("导入事件文案", true)
	import_events_button.pressed.connect(_request_event_text_import)
	actions.add_child(import_events_button)
	var export_button := _button("导出剧本包")
	export_button.pressed.connect(_request_package_export)
	actions.add_child(export_button)
	var template_button := _button("导出事件导入模板")
	template_button.pressed.connect(_request_event_import_template_export)
	actions.add_child(template_button)
	var validation_panel := _panel_container()
	page.add_child(validation_panel)
	var validation_box := VBoxContainer.new()
	validation_panel.add_child(validation_box)
	validation_box.add_child(_heading("校验结果", 20))
	validation_box.add_child(_muted(_validation_text()))

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
