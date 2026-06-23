extends SceneTree

func _initialize() -> void:
	var state = root.get_node("GameState")
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
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
	app.show_inventory()
	await process_frame
	state.add_item("item.herb", 2)
	assert(state.craft_item("item.tonic"))
	state.add_item("item.silver_salt", 1)
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
	app._new_custom_event()
	assert(app.editor_event_id.editable and app.editor_event_id.text == "")
	assert(app.editor_location != null)
	assert(app.entity_kind != null and app.entity_stat_inputs.size() == 10)
	assert(app.item_category != null and app.item_bonus_inputs.size() == 10)
	assert(app.map_background_path != null)
	assert(app.map_music_path != null and app.editor_music_path != null)
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
