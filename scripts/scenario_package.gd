extends RefCounted

const ContentSchema = preload("res://scripts/content_schema.gd")
const PACKAGE_VERSION := 1

static func make_package(scenario: Dictionary, database: Dictionary, custom_content: Dictionary) -> Dictionary:
	var normalized_content := ContentSchema.normalize_custom_content(custom_content)
	return {
		"package_version": PACKAGE_VERSION,
		"schema_version": ContentSchema.SCHEMA_VERSION,
		"exported_at": Time.get_datetime_string_from_system(true),
		"asset_paths": _collect_asset_paths(scenario, database, normalized_content),
		"scenario": scenario.duplicate(true),
		"database": database.duplicate(true),
		"custom_content": normalized_content.duplicate(true)
	}

static func export_to_path(path: String, scenario: Dictionary, database: Dictionary, custom_content: Dictionary) -> Dictionary:
	var package := make_package(scenario, database, custom_content)
	var validation := ContentSchema.validate_package(package)
	if not validation.ok:
		return {"ok": false, "errors": validation.errors}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "errors": ["无法写入文件：%s" % path]}
	file.store_string(JSON.stringify(package, "  "))
	return {"ok": true, "errors": [], "path": path}

static func import_from_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["文件不存在：%s" % path]}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {"ok": false, "errors": ["剧本包不是有效 JSON 对象"]}
	var package: Dictionary = parsed
	if not package.has("scenario") or not package.has("database"):
		return {"ok": false, "errors": ["剧本包必须包含 scenario 和 database"]}
	var warnings: Array = []
	if int(package.get("package_version", 0)) != PACKAGE_VERSION:
		warnings.append("剧本包版本与当前导入器不同：%s" % package.get("package_version", "未声明"))
	if int(package.get("schema_version", 0)) != ContentSchema.SCHEMA_VERSION:
		warnings.append("内容 schema 版本与当前项目不同：%s" % package.get("schema_version", "未声明"))
	var custom_value = package.get("custom_content", {})
	package.custom_content = ContentSchema.normalize_custom_content(custom_value if custom_value is Dictionary else {})
	var validation := ContentSchema.validate_package(package)
	if not validation.ok:
		return {"ok": false, "errors": validation.errors, "warnings": validation.warnings}
	warnings.append_array(validation.warnings)
	return {"ok": true, "errors": [], "warnings": warnings, "package": package}

static func _collect_asset_paths(scenario: Dictionary, database: Dictionary, custom_content: Dictionary) -> Array:
	var paths: Array[String] = []
	_collect_paths_from_value(scenario, paths)
	_collect_paths_from_value(database, paths)
	_collect_paths_from_value(custom_content, paths)
	return paths

static func _collect_paths_from_value(value, paths: Array[String]) -> void:
	if value is Dictionary:
		for key in value:
			var entry = value[key]
			if (str(key).ends_with("image") or str(key).ends_with("music") or str(key).ends_with("path")) and entry is String:
				var path := str(entry)
				if not path.is_empty() and not paths.has(path):
					paths.append(path)
			else:
				_collect_paths_from_value(entry, paths)
	elif value is Array:
		for entry in value:
			_collect_paths_from_value(entry, paths)
