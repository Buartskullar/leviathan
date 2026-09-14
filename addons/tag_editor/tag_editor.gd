@tool
extends Window

const TAG_DB_PATH := "res://Interactions/data/TagDatabase.tres"

var database: TagDatabase
var editing_tag: TagInfo

var id_edit := LineEdit.new()
var name_edit := LineEdit.new()
var description_edit := TextEdit.new()

func setup(db: TagDatabase, tag: TagInfo) -> void:
	database = db
	editing_tag = tag
	_build_ui()
	if editing_tag:
		_load_tag()

func _build_ui() -> void:
	close_requested.connect(_on_close_requested)
	title = "Tag"
	size = Vector2i(500, 400)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var id_label := Label.new()
	id_label.text = "ID"
	root.add_child(id_label)
	root.add_child(id_edit)
	id_edit.placeholder_text = "flammable"
	var name_label := Label.new()
	name_label.text = "Display Name"
	root.add_child(name_label)
	root.add_child(name_edit)
	name_edit.placeholder_text = "Flammable"
	var description_label := Label.new()
	description_label.text = "Description"
	root.add_child(description_label)
	description_edit.custom_minimum_size.y = 150
	root.add_child(description_edit)
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

func _load_tag() -> void:
	if editing_tag == null:
		return
	id_edit.text = str(editing_tag.id)
	name_edit.text = editing_tag.display_name
	description_edit.text = editing_tag.description

func _on_close_requested() -> void:
	queue_free()

func _save() -> void:
	if database == null:
		push_error("TAG SAVE: DATABASE IS NULL")
		return
	var id := id_edit.text.strip_edges()
	var display_name := name_edit.text.strip_edges()
	var description := description_edit.text.strip_edges()
	if id.is_empty():
		push_error("TAG SAVE: ID IS EMPTY")
		return
	if editing_tag == null:
		if _id_exists(id):
			push_error("TAG SAVE: TAG ID ALREADY EXISTS: " + id)
			return
		editing_tag = TagInfo.new()
		database.tags.append(editing_tag)
	else:
		if str(editing_tag.id) != id and _id_exists(id):
			push_error("TAG SAVE: TAG ID ALREADY EXISTS: " + id)
			return
	editing_tag.id = StringName(id)
	editing_tag.display_name = display_name
	editing_tag.description = description
	database.emit_changed()
	var error := ResourceSaver.save(database, TAG_DB_PATH)
	if error != OK:
		push_error("TAG DATABASE SAVE ERROR: " + str(error))
		return
	print("TAG SAVED: ", id)
	queue_free()

func _id_exists(id: String) -> bool:
	for tag in database.tags:
		if tag == null:
			continue
		if str(tag.id) == id:
			return true
	return false
