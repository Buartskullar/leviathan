@tool
extends VBoxContainer

const TAG_DB_PATH := "res://Interactions/data/TagDatabase.tres"

var database: TagDatabase
var search := LineEdit.new()
var tag_list := VBoxContainer.new()
var scroll := ScrollContainer.new()
var status_label := Label.new()

func _init() -> void:
	name = "TagDatabase"
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
	database = load(TAG_DB_PATH) as TagDatabase
	if database == null:
		push_error("TagDatabase not found: " + TAG_DB_PATH)

func _build_ui() -> void:
	var title := Label.new()
	title.text = "TAG DATABASE"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	var toolbar := HBoxContainer.new()
	var add_button := Button.new()
	add_button.text = "+ Add Tag"
	add_button.pressed.connect(_add_tag)
	var reload_button := Button.new()
	reload_button.text = "Reload"
	reload_button.pressed.connect(refresh)
	toolbar.add_child(add_button)
	toolbar.add_child(reload_button)
	add_child(toolbar)
	search.placeholder_text = "Search tags..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.text_changed.connect(func(_text): _rebuild_list())
	add_child(search)
	status_label.custom_minimum_size.y = 25
	add_child(status_label)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tag_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.add_child(tag_list)
	add_child(scroll)

func _rebuild_list() -> void:
	for child in tag_list.get_children():
		child.queue_free()
	if database == null:
		status_label.text = "Database not found"
		return
	var filter := search.text.to_lower().strip_edges()
	var visible_count := 0
	for tag in database.tags:
		if tag == null:
			continue
		if not filter.is_empty() and not str(tag.id).to_lower().contains(filter):
			continue
		_add_tag_row(tag)
		visible_count += 1
	status_label.text = "Tags: %d" % visible_count

func _add_tag_row(tag: TagInfo) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = 32
	var id_label := Label.new()
	id_label.text = str(tag.id)
	id_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var edit_button := Button.new()
	edit_button.text = "Edit"
	edit_button.pressed.connect(_edit_tag.bind(tag))
	var delete_button := Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(_confirm_delete.bind(tag))
	row.add_child(id_label)
	row.add_child(edit_button)
	row.add_child(delete_button)
	tag_list.add_child(row)

func _add_tag() -> void:
	var editor := preload("res://addons/tag_editor/tag_editor.gd").new()
	add_child(editor)
	editor.setup(database, null)
	editor.tree_exited.connect(refresh)
	editor.popup_centered()

func _edit_tag(tag: TagInfo) -> void:
	var editor := preload("res://addons/tag_editor/tag_editor.gd").new()
	add_child(editor)
	editor.setup(database, tag)
	editor.tree_exited.connect(refresh)
	editor.popup_centered()

func _confirm_delete(tag: TagInfo) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Delete Tag"
	dialog.dialog_text = "Delete tag \"%s\"?" % tag.id
	dialog.ok_button_text = "Delete"
	dialog.cancel_button_text = "Cancel"
	dialog.confirmed.connect(_delete_tag.bind(tag))
	add_child(dialog)
	dialog.popup_centered()

func _delete_tag(tag: TagInfo) -> void:
	if database == null:
		return
	if not database.tags.has(tag):
		return
	database.tags.erase(tag)
	database.emit_changed()
	var error := ResourceSaver.save(database, TAG_DB_PATH)
	if error != OK:
		push_error("TAG DATABASE SAVE ERROR: " + str(error))
		return
	refresh()
