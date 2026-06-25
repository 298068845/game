extends SceneTree

func _initialize() -> void:
	var state = root.get_node("GameState")
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	if app.events.is_empty():
		assert(app.database.get("characters", []).is_empty())
		assert(app.database.get("enemies", []).is_empty())
		assert(app.database.get("equipment", []).is_empty())
		assert(app.database.get("items", []).is_empty())
		quit()
	assert(not app._event_unlocked("harbor_01"))
	assert(not app._location_unlocked("雾港码头"))
	app.show_event("harbor_01")
	await process_frame
	assert(state.world.scene == "intro_01")
	app.show_event("intro_01")
	await process_frame
	assert(state.world.scene == "intro_01")
	assert(state.world.location == "渡船")
	assert(state.world.quests.has("find_linya"))
	assert(app.event_text_pages.size() > 0)
	assert(app.body_label.text.contains("[url=0]"))
	assert(not app.body_label.text.contains("点击继续"))
	app.show_event("intro_02")
	await process_frame
	assert(state.world.active_continuous == "intro_01")
	app.show_map()
	await process_frame
	assert(app.current_view == "game")
	app.show_event("harbor_01")
	await process_frame
	app.show_event("harbor_02")
	await process_frame
	app.show_event("square_01")
	await process_frame
	assert(state.world.active_continuous == "")
	app.show_map()
	await process_frame
	assert(app._location_unlocked("雾港码头"))
	assert(app._event_unlocked("repeat_forage"))
	assert(app.map_marker_count > 0)
	assert(app.find_children("*", "Label", true, false).filter(func(node): return node.text == "◆ 剧情").is_empty())
	app._show_map_bag_panel()
	await process_frame
	var bag_panel := app.map_menu_overlay.get_child(0) as Control
	assert(bag_panel.position.y >= 0)
	assert(bag_panel.position.y + bag_panel.size.y <= app.map_menu_overlay.size.y - 68)
	app._show_map_relations_panel()
	await process_frame
	var relations_panel := app.map_menu_overlay.get_child(0) as Control
	assert(relations_panel.position.y >= 0)
	assert(relations_panel.position.y + relations_panel.size.y <= app.map_menu_overlay.size.y - 68)
	assert(app._map_marker_icon({"repeatable":true}) == "↻")
	assert(app._map_marker_icon({"type":"随机事件"}) == "✦")
	assert(app._map_marker_icon({"type":"剧情事件"}) == "◆")
	var service_ids: Array = app._map_service_markers().map(func(service): return service.get("id", ""))
	assert(service_ids.has("inn") and service_ids.has("shop"))
	var ration_before: int = int(state.player.inventory.get("item.ration", 0))
	app._start_event("repeat_forage")
	await process_frame
	assert(state.world.scene == "repeat_forage")
	assert(state.world.action_points == 2)
	app._perform_resource_check({"stat":"洞察", "difficulty":11, "resource":"item.ration"})
	await process_frame
	assert(int(state.player.inventory.get("item.ration", 0)) > ration_before)
	assert(int(state.world.repeat_counts.get("repeat_forage", 0)) == 1)
	app.show_map()
	await process_frame
	app._start_event("repeat_forage")
	await process_frame
	app._perform_resource_check({"stat":"洞察", "difficulty":11, "resource":"item.ration"})
	await process_frame
	app.show_map()
	await process_frame
	app._start_event("repeat_forage")
	await process_frame
	assert(state.world.action_points == 0)
	var scene_at_zero: String = state.world.scene
	app._start_event("repeat_forage")
	assert(state.world.scene == scene_at_zero)
	var old_date: String = state.date_text()
	app.rest_day()
	await process_frame
	assert(state.world.action_points == 3 and state.date_text() != old_date)
	assert(state.player.satiety == 60)
	state.player.satiety = 5
	var penalty_before: int = int(state.player.max_hp_penalty)
	app.rest_day()
	await process_frame
	assert(int(state.player.max_hp_penalty) == penalty_before + 2)
	assert(state.player.satiety == 0)
	app.show_event("lighthouse_01")
	await process_frame
	assert(state.world.active_continuous == "lighthouse_01")
	app.show_map()
	await process_frame
	assert(app.current_view == "game")
	state.world.active_continuous = ""
	assert(app._event_unlocked("harbor_02"))
	assert(not app._event_unlocked("archive_01"))
	state.world.visited.append("check_failure")
	assert(app._event_unlocked("archive_01"))
	app.show_growth()
	await process_frame
	app.show_inn()
	await process_frame
	assert(app.current_view == "inn")
	app.show_shop()
	await process_frame
	assert(app.current_view == "shop")
	assert(app._sellable_inventory_items().is_empty())
	app.show_inventory()
	await process_frame
	state.add_item("item.herb", 2)
	assert(state.craft_item("item.tonic"))
	state.add_item("item.silver_salt", 1)
	var sellables: Array = app._sellable_inventory_items()
	assert(sellables.size() == 1)
	assert(str(sellables[0].id) == "item.silver_salt")
	assert(int(sellables[0].price) == 5)
	assert(int(sellables[0].quantity) == 1)
	var coins_before: int = int(state.player.coins)
	assert(state.sell_item("item.silver_salt", 1, 5))
	assert(int(state.player.coins) == coins_before + 5)
	assert(state.has_item("equip.watch_cap"))
	var defense_before: int = app._effective_combat("防御")
	app._equip_from_bag("equip.watch_cap", "头盔")
	await process_frame
	assert(state.player.equipment.头盔 == "equip.watch_cap")
	assert(app._effective_combat("防御") == defense_before + 1)
	app.show_tools()
	await process_frame
	assert(app.editor_event_id != null)
	var event_editor_page: Node = app.tools_tabs.get_child(0)
	assert(event_editor_page.find_children("*", "ScrollContainer", true, false).is_empty())
	assert(app.editor_preview is HFlowContainer)
	assert(app.editor_event_id.editable and app.editor_event_id.text.begins_with("custom_event_"))
	assert(app.editor_list.get_selected_items().is_empty())
	app.editor_type.select(1)
	app.editor_type.item_selected.emit(1)
	for location_index in range(app.editor_location.item_count):
		if app.editor_location.get_item_text(location_index) == "黑帆酒馆":
			app.editor_location.select(location_index)
			app.editor_location.item_selected.emit(location_index)
			break
	await process_frame
	var preview_text := ""
	for preview_label in app.editor_preview.find_children("*", "Label", true, false):
		preview_text += (preview_label as Label).text + "\n"
	assert(preview_text.contains("随机事件") and preview_text.contains("黑帆酒馆"))
	assert(not app.editor_option_check_row.visible)
	assert(not app.editor_option_check_targets_box.visible)
	assert(not app.editor_option_next_box.visible)
	app._new_custom_event()
	assert(app.editor_event_id.editable and app.editor_event_id.text.begins_with("custom_event_"))
	assert(app.editor_list.get_selected_items().is_empty())
	assert(app.editor_location != null)
	assert(app.entity_kind != null and app.entity_stat_inputs.size() == 10)
	assert(app.item_category != null and app.item_bonus_inputs.size() == 10)
	assert(app.map_background_path != null)
	assert(app.map_music_path != null and app.editor_music_path != null)
	assert(app.map_point_list != null and app.map_point_name != null)
	var event_import_path := "user://event_text_import_test.json"
	var event_import_file := FileAccess.open(event_import_path, FileAccess.WRITE)
	assert(event_import_file != null)
	event_import_file.store_string(JSON.stringify({"events":[{"id":"custom.import_text_test", "title":"导入文案测试", "location":"雾港码头", "text":"只有文案，素材稍后补。", "options":[{"text":"返回地图", "action":"open_map"}]}]}))
	event_import_file.close()
	var import_result: Dictionary = app._import_event_text_data(ProjectSettings.globalize_path(event_import_path))
	assert(import_result.ok and int(import_result.draft) == 1)
	app._reload_event_registry()
	assert(not app._event_unlocked("custom.import_text_test"))
	assert(app._lock_description("custom.import_text_test").contains("事件数据未完善"))
	for i in range(state.custom_content.events.size() - 1, -1, -1):
		if state.custom_content.events[i].get("id", "") == "custom.import_text_test":
			state.custom_content.events.remove_at(i)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(event_import_path))
	app._reload_event_registry()
	state.custom_content.events.append({"id":"custom.countdown_source", "title":"倒计时测试", "type":"剧情事件", "location":"渡船", "text":"倒计时入口", "countdown_days":1, "timeout_event":"custom.countdown_timeout", "options":[{"text":"返回地图", "action":"open_map"}]})
	state.custom_content.events.append({"id":"custom.countdown_timeout", "title":"倒计时超时", "type":"剧情事件", "location":"渡船", "text":"倒计时结束", "options":[{"text":"返回地图", "action":"open_map"}]})
	app._reload_event_registry()
	app.show_map()
	await process_frame
	assert(int(state.world.event_countdowns.get("custom.countdown_source", -1)) == 1)
	assert(app._event_countdown_remaining(app.events["custom.countdown_source"]) == 1)
	assert(app._advance_event_countdowns() == "custom.countdown_timeout")
	assert(state.world.visited.has("custom.countdown_source"))
	assert(not state.world.event_countdowns.has("custom.countdown_source"))
	for i in range(state.custom_content.events.size() - 1, -1, -1):
		var cleanup_id := str(state.custom_content.events[i].get("id", ""))
		if cleanup_id == "custom.countdown_source" or cleanup_id == "custom.countdown_timeout":
			state.custom_content.events.remove_at(i)
	app._reload_event_registry()
	app.map_point_name.text = "测试发生点"
	app._set_map_point_draft_position(Vector2(321, 222))
	app._save_map_point()
	assert(app._map_point_names().has("测试发生点"))
	assert(app._map_point_position("测试发生点") == Vector2(321, 222))
	app._select_location_value("测试发生点")
	assert(app.editor_location.get_item_text(app.editor_location.selected) == "测试发生点")
	app._delete_map_point()
	assert(not app._custom_map_points().any(func(point): return point.get("name", "") == "测试发生点"))
	assert(app.item_image_preview.texture != null)
	assert(app.map_background_preview.texture != null)
	app.entity_kind.select(1)
	app._on_entity_kind_changed(1)
	assert(app.entity_portrait_preview.texture != null)
	assert(app._texture_from_path("", app.DEFAULT_MAP_IMAGE) != null)
	var test_image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	test_image.fill(Color(0.2, 0.7, 0.8, 1.0))
	var source_path := "user://asset_import_test.png"
	assert(test_image.save_png(ProjectSettings.globalize_path(source_path)) == OK)
	app.pending_image_target = "event_background"
	app._on_image_file_selected(ProjectSettings.globalize_path(source_path))
	assert(app.editor_background_path.text.begins_with("user://mist_harbor_assets/"))
	assert(app._texture_from_path(app.editor_background_path.text) != null)
	var imported_path: String = app.editor_background_path.text
	app._set_image_target("entity_portrait", imported_path)
	app._set_image_target("item_image", imported_path)
	app._set_image_target("map_background", imported_path)
	assert(app.entity_portrait_preview.texture != null)
	assert(app.item_image_preview.texture != null)
	assert(app.map_background_preview.texture != null)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(source_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(imported_path))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 8000
	wav.stereo = false
	var samples := PackedByteArray()
	samples.resize(1600)
	wav.data = samples
	var wav_base := "user://audio_system_test"
	assert(wav.save_to_wav(wav_base) == OK)
	var wav_path := wav_base + ".wav"
	assert(app._load_audio_from_path(wav_path) != null)
	app.pending_audio_target = "event_music"
	app._on_audio_file_selected(ProjectSettings.globalize_path(wav_path))
	assert(app.editor_music_path.text.begins_with("user://mist_harbor_assets/audio/"))
	var copied_audio: String = app.editor_music_path.text
	var old_map_music: String = state.custom_content.get("map_music", "")
	state.custom_content.map_music = copied_audio
	app._activate_map_music()
	assert(app.map_music_player.stream != null and not app.map_music_player.stream_paused)
	app._apply_event_music({"music":copied_audio})
	assert(app.event_music_player.stream != null and app.map_music_player.stream_paused)
	app._apply_event_music({"music":""})
	assert(not app.event_music_player.playing and not app.map_music_player.stream_paused)
	state.custom_content.map_music = old_map_music
	app.map_music_player.stop()
	app.event_music_player.stop()
	app.current_map_music_path = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(wav_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(copied_audio))
	app.show_battle(true)
	await process_frame
	assert(state.battle.active)
	app._battle_action("quick")
	await process_frame
	assert(state.battle.has("enemy_intent"))
	if not state.world.visited.has("archive_02"):
		state.world.visited.append("archive_02")
	# 使用确定性高属性验证完整战斗结算路径。
	state.player.combat.力量 = 40
	state.player.combat.技巧 = 40
	for i in range(8):
		if not state.battle.get("active", false):
			break
		app._battle_action("attack")
		await process_frame
	assert(state.world.battle_won)
	assert(state.world.scene == "after_battle")
	assert(state.save_game())
	assert(state.load_game())
	print("INTEGRATION TEST PASS: views, battle, save/load")
	app.queue_free()
	await process_frame
	quit()
