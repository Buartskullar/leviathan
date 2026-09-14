@tool
extends VBoxContainer

const EFFECT_DB_PATH := "res://Interactions/data/EffectDatabase.tres"
const EFFECTS_DIR := "res://Interactions/effects/"
const INTERACTION_DB_PATH := "res://Interactions/data/InteractionDatabase.tres"

var database: EffectDatabase
var search := LineEdit.new()
var effect_list := VBoxContainer.new()
var scroll := ScrollContainer.new()
var status_label := Label.new()

func _init() -> void:
	name = "EffectDatabase"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_ui()
	call_deferred("_initial_load")

func _initial_load() -> void:
	refresh()

func refresh() -> void:
	_load_database()
	_rebuild_list()

func _load_database() -> void:
	database = load(EFFECT_DB_PATH) as EffectDatabase
	if database == null:
		push_error("EffectDatabase not found: " + EFFECT_DB_PATH)
		return
	database.build_index()

func _build_ui() -> void:
	var title := Label.new()
	title.text = "EFFECT DATABASE"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	var toolbar := HBoxContainer.new()
	var add_button := Button.new()
	add_button.text = "+ Add Effect"
	add_button.pressed.connect(_add_effect)
	var reload_button := Button.new()
	reload_button.text = "Reload"
	reload_button.pressed.connect(refresh)
	toolbar.add_child(add_button)
	toolbar.add_child(reload_button)
	add_child(toolbar)
	search.placeholder_text = "Search effects..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.text_changed.connect(func(_text): _rebuild_list())
	add_child(search)
	status_label.custom_minimum_size.y = 25
	add_child(status_label)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	effect_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.add_child(effect_list)
	add_child(scroll)

func _rebuild_list() -> void:
	for child in effect_list.get_children():
		child.queue_free()
	if database == null:
		status_label.text = "Database not found"
		return
	var filter := search.text.to_lower().strip_edges()
	var visible_count := 0
	for effect in database.effects:
		if effect == null:
			continue
		if not filter.is_empty() and not str(effect.id).to_lower().contains(filter):
			continue
		_add_effect_row(effect)
		visible_count += 1
	status_label.text = "Effects: %d" % visible_count

func _add_effect_row(effect: Effect) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = 32
	var id_label := Label.new()
	id_label.text = str(effect.id)
	id_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var edit_button := Button.new()
	edit_button.text = "Edit"
	edit_button.pressed.connect(_edit_effect.bind(effect))
	var script_button := Button.new()
	script_button.text = "Open Script"
	script_button.pressed.connect(_open_script.bind(effect))
	var used_button := Button.new()
	used_button.text = "Used By"
	used_button.pressed.connect(_show_used_by.bind(effect))
	var duplicate_button := Button.new()
	duplicate_button.text = "Duplicate"
	duplicate_button.pressed.connect(_duplicate_effect.bind(effect))
	var delete_button := Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(_confirm_delete.bind(effect))
	row.add_child(id_label)
	row.add_child(edit_button)
	row.add_child(script_button)
	row.add_child(used_button)
	row.add_child(duplicate_button)
	row.add_child(delete_button)
	effect_list.add_child(row)

func _add_effect() -> void:
	var editor := preload("res://addons/tag_editor/effect_editor.gd").new()
	add_child(editor)
	editor.setup(database, null)
	editor.tree_exited.connect(refresh)
	editor.popup_centered()

func _edit_effect(effect: Effect) -> void:
	var editor := preload("res://addons/tag_editor/effect_editor.gd").new()
	add_child(editor)
	editor.setup(database, effect)
	editor.tree_exited.connect(refresh)
	editor.popup_centered()

func _open_script(effect: Effect) -> void:
	if effect == null:
		return
	if effect.script_path.is_empty():
		return
	var script := load(effect.script_path) as Script
	if script == null:
		push_error("Cannot load effect script: " + effect.script_path)
		return
	EditorInterface.edit_script(script)

func _show_used_by(effect: Effect) -> void:
	if effect == null:
		return
	var dialog := AcceptDialog.new()
	dialog.title = "Used By: " + str(effect.id)
	var text := ""
	var interaction_db := load(INTERACTION_DB_PATH) as InteractionDatabase
	if interaction_db:
		for rule in interaction_db.rules:
			if rule == null:
				continue
			if effect.id in rule.effect_ids:
				text += "%s → %s\n" % [rule.source_tag_id, rule.target_tag_id]
	if text.is_empty():
		text = "This effect is not used by any interaction."
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(400, 100)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.add_child(label)
	add_child(dialog)
	dialog.popup_centered()

func _duplicate_effect(effect: Effect) -> void:
	if database == null or effect == null:
		return
	var new_id := str(effect.id) + "_copy"
	var counter := 2
	while _id_exists(new_id):
		new_id = "%s_copy%d" % [effect.id, counter]
		counter += 1
	var new_path := EFFECTS_DIR + new_id + ".gd"
	if not _copy_effect_script(effect.script_path, new_path):
		return
	var new_effect := Effect.new()
	new_effect.id = StringName(new_id)
	new_effect.description = effect.description
	new_effect.script_path = new_path
	database.effects.append(new_effect)
	database.emit_changed()
	var error := ResourceSaver.save(database, EFFECT_DB_PATH)
	if error != OK:
		push_error("EFFECT DATABASE SAVE ERROR: " + str(error))
		return
	EditorInterface.get_resource_filesystem().scan_sources()
	refresh()

func _copy_effect_script(source_path: String, target_path: String) -> bool:
	if not source_path.is_empty() and FileAccess.file_exists(source_path):
		var source := FileAccess.open(source_path, FileAccess.READ)
		if source == null:
			push_error("Cannot read effect script: " + source_path)
			return false
		var content := source.get_as_text()
		source.close()
		return _write_script(target_path, content)
	return _create_effect_script(target_path)

func _create_effect_script(script_path: String) -> bool:
	return _write_script(script_path, _get_effect_template())

func _write_script(script_path: String, content: String) -> bool:
	var absolute_path := ProjectSettings.globalize_path(script_path)
	var directory := absolute_path.get_base_dir()
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Cannot create effect directory: " + directory)
		return false
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot create effect script: " + script_path)
		return false
	file.store_string(content)
	file.close()
	EditorInterface.get_resource_filesystem().scan_sources()
	return true

func _get_effect_template() -> String:
	return """extends Effect

func execute(context: EffectContext) -> void:
	print("EFFECT EXECUTED")
"""

func _id_exists(id: String) -> bool:
	for effect in database.effects:
		if effect == null:
			continue
		if str(effect.id) == id:
			return true
	return false

func _confirm_delete(effect: Effect) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Delete Effect"
	dialog.dialog_text = "Delete effect \"%s\"?\n\nThe script file will not be deleted." % effect.id
	dialog.ok_button_text = "Delete"
	dialog.cancel_button_text = "Cancel"
	dialog.confirmed.connect(_delete_effect.bind(effect))
	add_child(dialog)
	dialog.popup_centered()

func _delete_effect(effect: Effect) -> void:
	if database == null:
		return
	if not database.effects.has(effect):
		return
	database.effects.erase(effect)
	database.emit_changed()
	var error := ResourceSaver.save(database, EFFECT_DB_PATH)
	if error != OK:
		push_error("EFFECT DATABASE SAVE ERROR: " + str(error))
		return
	refresh()
