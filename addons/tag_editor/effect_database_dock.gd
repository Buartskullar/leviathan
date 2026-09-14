@tool
extends VBoxContainer

const EFFECT_DB_PATH := "res://Interactions/data/EffectDatabase.tres"
const EFFECTS_DIR := "res://Interactions/effects/"

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
	var delete_button := Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(_confirm_delete.bind(effect))
	row.add_child(id_label)
	row.add_child(edit_button)
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

func _confirm_delete(effect: Effect) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Delete Effect"
	dialog.dialog_text = "Delete effect \"%s\"?" % effect.id
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
