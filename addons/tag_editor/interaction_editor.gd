@tool
extends Window

const EFFECT_DB_PATH := "res://Interactions/data/EffectDatabase.tres"
const TAG_DB_PATH := "res://Interactions/data/TagDatabase.tres"
const INTERACTION_DB_PATH := "res://Interactions/data/InteractionDatabase.tres"

var database: InteractionDatabase
var effect_database: EffectDatabase

var source_option := OptionButton.new()
var target_option := OptionButton.new()
var effects_list := VBoxContainer.new()

var source_tags: Array[TagInfo] = []
var target_tags: Array[TagInfo] = []

var editing_rule: InteractionRule


func setup(
	db: InteractionDatabase,
	source: TagInfo,
	target: TagInfo,
	rule: InteractionRule
) -> void:

	database = db

	# Очень важно:
	editing_rule = null

	if rule != null:
		editing_rule = rule

	var tag_db := load(TAG_DB_PATH) as TagDatabase

	if tag_db:
		source_tags = tag_db.tags
		target_tags = tag_db.tags

	effect_database = load(EFFECT_DB_PATH) as EffectDatabase

	_build_ui()

	if source:
		_select_tag(source_option, source)

	if target:
		_select_tag(target_option, target)

	if editing_rule:
		_load_rule()


func _build_ui() -> void:
	close_requested.connect(_on_close_requested)

	title = "Interaction"
	size = Vector2i(500, 500)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var source_label := Label.new()
	source_label.text = "SOURCE TAG"
	root.add_child(source_label)
	root.add_child(source_option)

	var target_label := Label.new()
	target_label.text = "TARGET TAG"
	root.add_child(target_label)
	root.add_child(target_option)

	var effects_label := Label.new()
	effects_label.text = "EFFECTS"
	root.add_child(effects_label)

	effects_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(effects_list)

	var add_effect := Button.new()
	add_effect.text = "+ Add Effect"
	add_effect.pressed.connect(_add_effect)
	root.add_child(add_effect)

	var buttons := HBoxContainer.new()

	var save := Button.new()
	save.text = "Save"
	save.pressed.connect(_save)

	var delete := Button.new()
	delete.text = "Delete"
	delete.pressed.connect(_delete)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(queue_free)

	buttons.add_child(save)
	buttons.add_child(delete)
	buttons.add_child(cancel)

	root.add_child(buttons)

	add_child(root)

	_fill_tags()


func _on_close_requested() -> void:
	queue_free()


func _fill_tags() -> void:
	source_option.clear()
	target_option.clear()

	for tag in source_tags:
		if tag:
			source_option.add_item(str(tag.id))

	for tag in target_tags:
		if tag:
			target_option.add_item(str(tag.id))


func _select_tag(
	option: OptionButton,
	tag: TagInfo
) -> void:

	for i in option.item_count:
		if option.get_item_text(i) == str(tag.id):
			option.select(i)
			return


func _load_rule() -> void:
	if editing_rule == null:
		return

	for i in source_option.item_count:
		if source_option.get_item_text(i) == str(editing_rule.source_tag_id):
			source_option.select(i)
			break

	for i in target_option.item_count:
		if target_option.get_item_text(i) == str(editing_rule.target_tag_id):
			target_option.select(i)
			break

	_rebuild_effect_list()


func _rebuild_effect_list() -> void:
	for child in effects_list.get_children():
		child.queue_free()

	if editing_rule == null:
		return

	for effect_id in editing_rule.effect_ids:
		var row := HBoxContainer.new()

		var label := Label.new()
		label.text = str(effect_id)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var remove := Button.new()
		remove.text = "×"
		remove.pressed.connect(
			_remove_effect.bind(effect_id)
		)

		row.add_child(label)
		row.add_child(remove)

		effects_list.add_child(row)


func _add_effect() -> void:
	if effect_database == null:
		return

	if editing_rule == null:
		editing_rule = InteractionRule.new()

	var popup := AcceptDialog.new()
	popup.title = "Select Effect"
	popup.size = Vector2i(350, 400)

	var list := VBoxContainer.new()

	for effect in effect_database.effects:
		if effect == null:
			continue

		var button := Button.new()
		button.text = str(effect.id)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT

		button.pressed.connect(
			func():
				if not effect.id in editing_rule.effect_ids:
					editing_rule.effect_ids.append(effect.id)

				_rebuild_effect_list()
				popup.queue_free()
		)

		list.add_child(button)

	popup.add_child(list)
	add_child(popup)
	popup.popup_centered()


func _remove_effect(effect_id: StringName) -> void:
	if editing_rule == null:
		return

	editing_rule.effect_ids.erase(effect_id)
	_rebuild_effect_list()


func _save() -> void:
	if database == null:
		push_error("SAVE: DATABASE IS NULL")
		return

	var source_id := source_option.get_item_text(
		source_option.selected
	)

	var target_id := target_option.get_item_text(
		target_option.selected
	)

	print("SAVE SOURCE: ", source_id)
	print("SAVE TARGET: ", target_id)

	if source_id.is_empty() or target_id.is_empty():
		push_error("SAVE: SOURCE OR TARGET EMPTY")
		return

	# Если правило вообще не создано
	if editing_rule == null:
		editing_rule = InteractionRule.new()

	# Если правило новое и ещё не находится в Database
	if not database.rules.has(editing_rule):
		database.rules.append(editing_rule)
		print("NEW RULE ADDED TO DATABASE")

	editing_rule.source_tag_id = StringName(source_id)
	editing_rule.target_tag_id = StringName(target_id)

	print(
		"RULE DATA: ",
		editing_rule.source_tag_id,
		" -> ",
		editing_rule.target_tag_id
	)

	print(
		"RULE EFFECTS: ",
		editing_rule.effect_ids
	)

	print(
		"RULE COUNT BEFORE SAVE: ",
		database.rules.size()
	)

	database.build_index()

	var error := ResourceSaver.save(
		database,
		INTERACTION_DB_PATH
	)

	print("SAVE RESULT: ", error)

	if error != OK:
		push_error(
			"INTERACTION DATABASE SAVE ERROR: "
			+ str(error)
		)
		return

	print(
		"RULE COUNT AFTER SAVE: ",
		database.rules.size()
	)

	queue_free()


func _delete() -> void:
	if database == null:
		queue_free()
		return

	if editing_rule == null:
		queue_free()
		return

	database.rules.erase(editing_rule)
	database.build_index()

	var error := ResourceSaver.save(
		database,
		INTERACTION_DB_PATH
	)

	if error != OK:
		push_error(
			"Interaction Database save error: %s"
			% error
		)
		return

	print("INTERACTION DELETED")

	queue_free()
