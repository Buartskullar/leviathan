@tool
extends Window

const TAG_DB_PATH := "res://Interactions/data/TagDatabase.tres"
const EFFECT_DB_PATH := "res://Interactions/data/EffectDatabase.tres"
const INTERACTION_DB_PATH := "res://Interactions/data/InteractionDatabase.tres"

var database: InteractionDatabase
var editing_rule: InteractionRule
var original_rule: InteractionRule
var source_tag: TagInfo
var target_tag: TagInfo
var source_option := OptionButton.new()
var target_option := OptionButton.new()
var effects_list := VBoxContainer.new()
var effect_scroll := ScrollContainer.new()

func setup(
	db: InteractionDatabase,
	p_source: TagInfo,
	p_target: TagInfo,
	p_rule: InteractionRule
) -> void:
	database = db
	source_tag = p_source
	target_tag = p_target
	editing_rule = p_rule
	if p_rule:
		original_rule = p_rule
	_build_ui()
	_load_tags()
	_load_rule()

func _build_ui() -> void:
	close_requested.connect(_on_close_requested)
	title = "Interaction"
	size = Vector2i(550, 550)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var source_label := Label.new()
	source_label.text = "Source"
	root.add_child(source_label)
	root.add_child(source_option)
	var target_label := Label.new()
	target_label.text = "Target"
	root.add_child(target_label)
	root.add_child(target_option)
	var effects_label := Label.new()
	effects_label.text = "Effects"
	root.add_child(effects_label)
	effect_scroll.custom_minimum_size = Vector2(0, 220)
	effect_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effect_scroll.add_child(effects_list)
	root.add_child(effect_scroll)
	var effect_button := Button.new()
	effect_button.text = "+ Add Effect"
	effect_button.pressed.connect(_add_effect)
	root.add_child(effect_button)
	var preview_button := Button.new()
	preview_button.text = "Preview Interaction"
	preview_button.pressed.connect(_preview_interaction)
	root.add_child(preview_button)
	var duplicate_button := Button.new()
	duplicate_button.text = "Duplicate As..."
	duplicate_button.pressed.connect(_duplicate_as)
	root.add_child(duplicate_button)
	var buttons := HBoxContainer.new()
	var save_button := Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(_save)
	var delete_button := Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(_delete)
	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(queue_free)
	buttons.add_child(save_button)
	buttons.add_child(delete_button)
	buttons.add_child(cancel_button)
	root.add_child(buttons)
	add_child(root)

func _load_tags() -> void:
	source_option.clear()
	target_option.clear()
	var tag_db := load(TAG_DB_PATH) as TagDatabase
	if tag_db == null:
		push_error("TagDatabase not found: " + TAG_DB_PATH)
		return
	for tag in tag_db.tags:
		if tag == null:
			continue
		source_option.add_item(str(tag.id))
		source_option.set_item_metadata(source_option.item_count - 1, tag)
		target_option.add_item(str(tag.id))
		target_option.set_item_metadata(target_option.item_count - 1, tag)

func _load_rule() -> void:
	if editing_rule:
		_select_tag(source_option, editing_rule.source_tag_id)
		_select_tag(target_option, editing_rule.target_tag_id)
	else:
		_select_tag(source_option, source_tag.id if source_tag else &"")
		_select_tag(target_option, target_tag.id if target_tag else &"")
	_rebuild_effect_list()

func _select_tag(option: OptionButton, tag_id: StringName) -> void:
	for index in range(option.item_count):
		var tag := option.get_item_metadata(index) as TagInfo
		if tag and tag.id == tag_id:
			option.select(index)
			return

func _rebuild_effect_list() -> void:
	for child in effects_list.get_children():
		child.queue_free()
	if editing_rule == null:
		return
	var effect_db := load(EFFECT_DB_PATH) as EffectDatabase
	for effect_id in editing_rule.effect_ids:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.text = str(effect_id)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if effect_db:
			var effect := effect_db.get_effect(effect_id)
			if effect:
				label.tooltip_text = effect.description
			else:
				label.tooltip_text = "Missing effect"
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.pressed.connect(_remove_effect.bind(effect_id))
		row.add_child(label)
		row.add_child(remove_button)
		effects_list.add_child(row)

func _add_effect() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Add Effect"
	var root := VBoxContainer.new()
	var search := LineEdit.new()
	search.placeholder_text = "Search effects..."
	root.add_child(search)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 300)
	var list := VBoxContainer.new()
	scroll.add_child(list)
	root.add_child(scroll)
	dialog.add_child(root)
	var effect_db := load(EFFECT_DB_PATH) as EffectDatabase
	if effect_db == null:
		return
	effect_db.build_index()
	var rebuild := func(filter: String) -> void:
		for child in list.get_children():
			child.queue_free()
		var normalized_filter := filter.to_lower().strip_edges()
		for effect in effect_db.effects:
			if effect == null:
				continue
			if not normalized_filter.is_empty() and not str(effect.id).to_lower().contains(normalized_filter):
				continue
			var button := Button.new()
			button.text = str(effect.id)
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.tooltip_text = effect.description
			button.pressed.connect(func():
				if editing_rule == null:
					editing_rule = InteractionRule.new()
				if not database.rules.has(editing_rule):
					database.rules.append(editing_rule)
				if not editing_rule.effect_ids.has(effect.id):
					editing_rule.effect_ids.append(effect.id)
				dialog.queue_free()
				_rebuild_effect_list()
			)
			list.add_child(button)
	search.text_changed.connect(rebuild)
	rebuild.call("")
	add_child(dialog)
	dialog.popup_centered()

func _remove_effect(effect_id: StringName) -> void:
	if editing_rule == null:
		return
	editing_rule.effect_ids.erase(effect_id)
	_rebuild_effect_list()

func _preview_interaction() -> void:
	if editing_rule == null:
		return
	var dialog := AcceptDialog.new()
	dialog.title = "Interaction Preview"
	var text := "Source: %s\nTarget: %s\n\nEffects:\n" % [editing_rule.source_tag_id, editing_rule.target_tag_id]
	if editing_rule.effect_ids.is_empty():
		text += "No effects"
	else:
		var effect_db := load(EFFECT_DB_PATH) as EffectDatabase
		if effect_db:
			effect_db.build_index()
		for effect_id in editing_rule.effect_ids:
			var effect: Effect = effect_db.get_effect(effect_id) if effect_db else null
			if effect:
				text += "• %s" % effect_id
				if not effect.description.is_empty():
					text += " — " + effect.description
				text += "\n"
			else:
				text += "• %s [MISSING]\n" % effect_id
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(450, 220)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.add_child(label)
	add_child(dialog)
	dialog.popup_centered()

func _duplicate_as() -> void:
	if editing_rule == null:
		return
	var dialog := Window.new()
	dialog.title = "Duplicate Interaction As..."
	dialog.size = Vector2i(400, 250)
	dialog.transient = true
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var source_label := Label.new()
	source_label.text = "New Source"
	root.add_child(source_label)
	var new_source := OptionButton.new()
	root.add_child(new_source)
	var target_label := Label.new()
	target_label.text = "New Target"
	root.add_child(target_label)
	var new_target := OptionButton.new()
	root.add_child(new_target)
	var info := Label.new()
	info.text = "Effects from the current interaction will be copied."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(info)
	var buttons := HBoxContainer.new()
	var duplicate_button := Button.new()
	duplicate_button.text = "Duplicate"
	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	buttons.add_child(duplicate_button)
	buttons.add_child(cancel_button)
	root.add_child(buttons)
	dialog.add_child(root)
	var tag_db := load(TAG_DB_PATH) as TagDatabase
	if tag_db == null:
		dialog.queue_free()
		return
	for tag in tag_db.tags:
		if tag == null:
			continue
		new_source.add_item(str(tag.id))
		new_source.set_item_metadata(new_source.item_count - 1, tag)
		new_target.add_item(str(tag.id))
		new_target.set_item_metadata(new_target.item_count - 1, tag)
	_select_tag(new_source, editing_rule.source_tag_id)
	_select_tag(new_target, editing_rule.target_tag_id)
	duplicate_button.pressed.connect(func():
		var selected_source := new_source.get_selected_metadata() as TagInfo
		var selected_target := new_target.get_selected_metadata() as TagInfo
		if selected_source == null or selected_target == null:
			return
		if database.get_interaction_by_tags(selected_source, selected_target) != null:
			info.text = "An interaction with this Source → Target already exists."
			return
		var new_rule := InteractionRule.new()
		new_rule.source_tag_id = selected_source.id
		new_rule.target_tag_id = selected_target.id
		new_rule.effect_ids = editing_rule.effect_ids.duplicate()
		database.rules.append(new_rule)
		database.emit_changed()
		var error := ResourceSaver.save(database, INTERACTION_DB_PATH)
		if error != OK:
			push_error("INTERACTION DATABASE SAVE ERROR: " + str(error))
			return
		database.build_index()
		dialog.queue_free()
	)
	cancel_button.pressed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func _save() -> void:
	if database == null:
		return
	var selected_source := source_option.get_selected_metadata() as TagInfo
	var selected_target := target_option.get_selected_metadata() as TagInfo
	if selected_source == null or selected_target == null:
		push_error("INTERACTION SAVE: SOURCE OR TARGET IS EMPTY")
		return
	if editing_rule == null:
		editing_rule = InteractionRule.new()
	if not database.rules.has(editing_rule):
		database.rules.append(editing_rule)
	if original_rule != editing_rule:
		var existing := database.get_interaction_by_tags(selected_source, selected_target)
		if existing != null and existing != editing_rule:
			push_error("INTERACTION SAVE: INTERACTION ALREADY EXISTS")
			return
	editing_rule.source_tag_id = selected_source.id
	editing_rule.target_tag_id = selected_target.id
	database.emit_changed()
	var error := ResourceSaver.save(database, INTERACTION_DB_PATH)
	if error != OK:
		push_error("INTERACTION DATABASE SAVE ERROR: " + str(error))
		return
	database.build_index()
	queue_free()

func _delete() -> void:
	if editing_rule == null:
		queue_free()
		return
	if database and database.rules.has(editing_rule):
		database.rules.erase(editing_rule)
		database.emit_changed()
		var error := ResourceSaver.save(database, INTERACTION_DB_PATH)
		if error != OK:
			push_error("INTERACTION DATABASE SAVE ERROR: " + str(error))
			return
	queue_free()

func _on_close_requested() -> void:
	queue_free()
