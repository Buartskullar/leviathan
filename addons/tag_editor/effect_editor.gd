@tool
extends Window

const EFFECT_DB_PATH := "res://Interactions/data/EffectDatabase.tres"
const EFFECTS_DIR := "res://Interactions/effects/"

var database: EffectDatabase
var editing_effect: Effect
var id_edit := LineEdit.new()
var script_path_edit := LineEdit.new()
var path_was_changed := false
var description_edit := TextEdit.new()

func setup(db: EffectDatabase, effect: Effect) -> void:
	database = db
	editing_effect = effect
	_build_ui()
	if editing_effect:
		_load_effect()
	else:
		script_path_edit.text = EFFECTS_DIR
		id_edit.text_changed.connect(_on_id_changed)
	script_path_edit.text_changed.connect(_on_script_path_changed)

func _build_ui() -> void:
	close_requested.connect(_on_close_requested)
	title = "Effect"
	size = Vector2i(500, 300)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var id_label := Label.new()
	id_label.text = "ID"
	root.add_child(id_label)
	root.add_child(id_edit)
	id_edit.placeholder_text = "enflame"
	var description_label := Label.new()
	description_label.text = "Description"
	root.add_child(description_label)
	description_edit.custom_minimum_size = Vector2(0, 80)
	root.add_child(description_edit)
	var script_label := Label.new()
	script_label.text = "Script Path"
	root.add_child(script_label)
	root.add_child(script_path_edit)
	script_path_edit.placeholder_text = "res://Interactions/effects/enflame.gd"
	var buttons := HBoxContainer.new()
	var save := Button.new()
	save.text = "Save"
	save.pressed.connect(_save)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(queue_free)
	buttons.add_child(save)
	buttons.add_child(cancel)
	root.add_child(buttons)
	add_child(root)

func _load_effect() -> void:
	if editing_effect == null:
		return
	id_edit.text = str(editing_effect.id)
	description_edit.text = editing_effect.description
	script_path_edit.text = editing_effect.script_path

func _on_id_changed(new_id: String) -> void:
	if editing_effect != null:
		return
	if path_was_changed:
		return
	var id := new_id.strip_edges()
	if id.is_empty():
		script_path_edit.text = EFFECTS_DIR
	else:
		script_path_edit.text = EFFECTS_DIR + id + ".gd"

func _on_script_path_changed(new_path: String) -> void:
	if editing_effect != null:
		return
	var default_path := EFFECTS_DIR + id_edit.text.strip_edges() + ".gd"
	if new_path != EFFECTS_DIR and new_path != default_path:
		path_was_changed = true

func _on_close_requested() -> void:
	queue_free()

func _save() -> void:
	if database == null:
		push_error("EFFECT SAVE: DATABASE IS NULL")
		return
	var id := id_edit.text.strip_edges()
	var script_path := script_path_edit.text.strip_edges()
	if id.is_empty():
		push_error("EFFECT SAVE: ID IS EMPTY")
		return
	if script_path.is_empty():
		script_path = EFFECTS_DIR + id + ".gd"
	if not script_path.begins_with("res://"):
		push_error("EFFECT SAVE: SCRIPT PATH MUST START WITH res://")
		return
	if not script_path.ends_with(".gd"):
		push_error("EFFECT SAVE: SCRIPT PATH MUST END WITH .gd")
		return
	if editing_effect == null:
		if _id_exists(id):
			push_error("EFFECT SAVE: EFFECT ID ALREADY EXISTS: " + id)
			return
		editing_effect = Effect.new()
		database.effects.append(editing_effect)
	else:
		if str(editing_effect.id) != id and _id_exists(id):
			push_error("EFFECT SAVE: EFFECT ID ALREADY EXISTS: " + id)
			return
	if not FileAccess.file_exists(script_path):
		if not _create_effect_script(script_path):
			if database.effects.has(editing_effect) and editing_effect.id.is_empty():
				database.effects.erase(editing_effect)
			return
	editing_effect.id = StringName(id)
	editing_effect.description = description_edit.text
	editing_effect.script_path = script_path
	database.emit_changed()
	var error := ResourceSaver.save(database, EFFECT_DB_PATH)
	if error != OK:
		push_error("EFFECT DATABASE SAVE ERROR: " + str(error))
		return
	print("EFFECT SAVED: ", id)
	queue_free()

func _create_effect_script(script_path: String) -> bool:
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
	file.store_string(_get_effect_template())
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
