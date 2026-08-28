@tool
extends EditorProperty

const DB_PATH := "res://Interactions/data/TagDatabase.tres"

var root := VBoxContainer.new()
var selected_list := VBoxContainer.new()
var add_button := Button.new()

var current_tags: Array[TagInfo] = []
var all_tags: Array[TagInfo] = []


func _init() -> void:
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var selected_label := Label.new()
	selected_label.text = "Selected tags:"
	root.add_child(selected_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 120
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(selected_list)

	root.add_child(scroll)

	add_button.text = "+ Add Tag"
	add_button.pressed.connect(_on_add_pressed)

	root.add_child(add_button)

	add_child(root)
	set_bottom_editor(root)


func _update_property() -> void:
	var object := get_edited_object()

	if object == null:
		return

	var value = object.get(get_edited_property())

	current_tags.clear()

	if value is Array:
		for tag in value:
			if tag is TagInfo:
				current_tags.append(tag)

	var db := load(DB_PATH) as TagDatabase

	if db:
		all_tags = db.tags
	else:
		all_tags.clear()
		push_error("Tag Editor: cannot load TagDatabase")

	_rebuild_selected()


func _rebuild_selected() -> void:
	for child in selected_list.get_children():
		child.queue_free()

	for tag in current_tags:
		var row := HBoxContainer.new()

		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label := Label.new()
		label.text = str(tag.id)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		label.tooltip_text = ("ID: %s\nName: %s\nDescription: %s" % [
		tag.id,
		tag.display_name,
		tag.description])

		var remove_button := Button.new()
		remove_button.text = "×"
		remove_button.tooltip_text = "Remove tag"

		remove_button.pressed.connect(_remove_tag.bind(tag))

		row.add_child(label)
		row.add_child(remove_button)

		selected_list.add_child(row)


func _on_add_pressed() -> void:
	_show_tag_selector()


func _show_tag_selector() -> void:
	var popup := AcceptDialog.new()

	popup.title = "Select Tag"
	popup.size = Vector2i(400, 500)

	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var search := LineEdit.new()
	search.placeholder_text = "Search tags..."
	search.clear_button_enabled = true

	container.add_child(search)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 350
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var tag_list := VBoxContainer.new()
	tag_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	scroll.add_child(tag_list)
	container.add_child(scroll)

	popup.add_child(container)

	get_tree().root.add_child(popup)

	_rebuild_selector(tag_list, "", popup)

	search.text_changed.connect(
		func(text: String):
			_rebuild_selector(tag_list, text, popup)
	)

	popup.popup_centered()


func _rebuild_selector(
	container: VBoxContainer,
	filter_text: String,
	popup: AcceptDialog
) -> void:

	for child in container.get_children():
		child.queue_free()

	var filter := filter_text.to_lower().strip_edges()

	for tag in all_tags:
		if tag == null:
			continue

		if tag in current_tags:
			continue

		var tag_id := str(tag.id)

		if filter != "" and not tag_id.to_lower().contains(filter):
			continue

		var button := Button.new()

		button.text = tag_id
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		button.pressed.connect(
			_add_tag_from_selector.bind(tag, popup)
		)

		container.add_child(button)


func _add_tag_from_selector(
	tag: TagInfo,
	popup: AcceptDialog
) -> void:

	if tag == null:
		return

	if tag in current_tags:
		return

	var object := get_edited_object()

	if object == null:
		return

	# Добавляем непосредственно в настоящий TagSet.
	var tags: Array = object.get(get_edited_property()).duplicate()

	tags.append(tag)

	object.set(get_edited_property(), tags)

	# Обновляем собственное состояние.
	current_tags.clear()

	for item in tags:
		if item is TagInfo:
			current_tags.append(item)

	# Сообщаем Inspector об изменении.
	emit_changed(
		get_edited_property(),
		tags
	)

	popup.queue_free()

	_rebuild_selected()


func _remove_tag(tag: TagInfo) -> void:

	if tag == null:
		return

	var object := get_edited_object()

	if object == null:
		return

	var tags: Array = object.get(get_edited_property()).duplicate()

	tags.erase(tag)

	object.set(get_edited_property(), tags)

	current_tags.clear()

	for item in tags:
		if item is TagInfo:
			current_tags.append(item)

	emit_changed(
		get_edited_property(),
		tags
	)

	_rebuild_selected()
