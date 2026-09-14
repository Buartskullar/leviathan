@tool
extends VBoxContainer

const TAG_DB_PATH := "res://Interactions/data/TagDatabase.tres"
const INTERACTION_DB_PATH := "res://Interactions/data/InteractionDatabase.tres"
const VALIDATOR_SCRIPT := preload("res://addons/tag_editor/database_validator.gd")

var database: InteractionDatabase

var search_source := LineEdit.new()
var search_target := LineEdit.new()
var search_effect := LineEdit.new()

var matrix_scroll := ScrollContainer.new()
var matrix := GridContainer.new()

var status_label := Label.new()
var all_tags: Array[TagInfo] = []


func _init() -> void:
	name = "InteractionDatabase"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_ui()
	call_deferred("_initial_load")

func _initial_load() -> void:
	refresh()

func refresh() -> void:
	_load_data()
	_rebuild_matrix()

func _load_data() -> void:
	var tag_db := load(TAG_DB_PATH) as TagDatabase
	if tag_db:
		all_tags = tag_db.tags
	else:
		all_tags.clear()
		push_error("TagDatabase not found: " + TAG_DB_PATH)
	database = load(INTERACTION_DB_PATH) as InteractionDatabase
	if database == null:
		push_error("InteractionDatabase not found: " + INTERACTION_DB_PATH)
		return
	database.build_index()

func _build_ui() -> void:
	var title := Label.new()
	title.text = "INTERACTION DATABASE"
	title.add_theme_font_size_override(
		"font_size",
		18
	)
	add_child(title)

	var toolbar := HBoxContainer.new()

	var reload_button := Button.new()
	reload_button.text = "Reload"
	reload_button.pressed.connect(refresh)
	var validate_button := Button.new()
	validate_button.text = "Validate Database"
	validate_button.pressed.connect(_validate_database)
	toolbar.add_child(validate_button)
	var add_button := Button.new()
	add_button.text = "+ Add Interaction"
	add_button.pressed.connect(_add_interaction)

	toolbar.add_child(reload_button)
	toolbar.add_child(add_button)

	add_child(toolbar)

	var filters := HBoxContainer.new()

	search_source.placeholder_text = "Search source..."
	search_target.placeholder_text = "Search target..."
	search_effect.placeholder_text = "Search effect..."
	search_effect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_effect.text_changed.connect(func(_text): _rebuild_matrix())

	search_source.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	search_target.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	search_source.text_changed.connect(
		func(_text):
			_rebuild_matrix()
	)

	search_target.text_changed.connect(
		func(_text):
			_rebuild_matrix()
	)

	filters.add_child(search_source)
	filters.add_child(search_target)
	filters.add_child(search_effect)

	add_child(filters)

	status_label.text = ""
	add_child(status_label)

	matrix_scroll.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	matrix_scroll.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	matrix_scroll.add_child(matrix)
	add_child(matrix_scroll)


func _get_visible_tags(
	search: String
) -> Array[TagInfo]:

	var result: Array[TagInfo] = []

	search = search.to_lower().strip_edges()

	for tag in all_tags:
		if tag == null:
			continue

		if search.is_empty():
			result.append(tag)
			continue

		if str(tag.id).to_lower().contains(search):
			result.append(tag)

	return result


func _rebuild_matrix() -> void:
	if database == null:
		return
	for child in matrix.get_children():
		child.queue_free()
	var source_filter := search_source.text.to_lower().strip_edges()
	var target_filter := search_target.text.to_lower().strip_edges()
	var effect_filter := search_effect.text.to_lower().strip_edges()
	if not effect_filter.is_empty():
		_rebuild_effect_filtered_matrix(effect_filter)
		return
	var source_tags := _get_visible_tags(source_filter)
	var target_tags := _get_visible_tags(target_filter)
	matrix.columns = target_tags.size() + 1
	var corner := Label.new()
	corner.text = "SOURCE ↓ / TARGET →"
	corner.custom_minimum_size = Vector2(160, 40)
	matrix.add_child(corner)
	for target in target_tags:
		var label := Label.new()
		label.text = str(target.id)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(100, 40)
		label.tooltip_text = _tag_tooltip(target)
		matrix.add_child(label)
	for source in source_tags:
		var source_label := Label.new()
		source_label.text = str(source.id)
		source_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		source_label.custom_minimum_size = Vector2(160, 40)
		source_label.tooltip_text = _tag_tooltip(source)
		matrix.add_child(source_label)
		for target in target_tags:
			var rule := database.get_interaction_by_tags(source, target)
			var button := Button.new()
			button.custom_minimum_size = Vector2(100, 40)
			if rule:
				button.text = _rule_text(rule)
				button.tooltip_text = "Edit interaction"
				if rule.effect_ids.is_empty():
					button.self_modulate = Color(1.0, 0.8, 0.4)
				elif _rule_has_invalid_effect(rule):
					button.self_modulate = Color(1.0, 0.4, 0.4)
				else:
					button.self_modulate = Color(0.5, 1.0, 0.5)
			else:
				button.text = "—"
				button.tooltip_text = "Create interaction"
				button.self_modulate = Color(0.6, 0.6, 0.6)
			button.pressed.connect(_on_cell_pressed.bind(source, target))
			matrix.add_child(button)
	status_label.text = "Interactions: %d" % database.rules.size()

func _rebuild_effect_filtered_matrix(effect_filter: String) -> void:
	var matching_rules: Array[InteractionRule] = []
	for rule in database.rules:
		if rule == null:
			continue
		for effect_id in rule.effect_ids:
			if str(effect_id).to_lower().contains(effect_filter):
				matching_rules.append(rule)
				break
	matrix.columns = 1
	if matching_rules.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No interactions found for effect: " + effect_filter
		empty_label.custom_minimum_size = Vector2(400, 40)
		matrix.add_child(empty_label)
		status_label.text = "Interactions: 0"
		return
	var header := Label.new()
	header.text = "Interactions using: " + effect_filter
	header.custom_minimum_size = Vector2(400, 40)
	matrix.add_child(header)
	for rule in matching_rules:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(400, 40)
		var source_label := Label.new()
		source_label.text = str(rule.source_tag_id)
		source_label.custom_minimum_size = Vector2(120, 40)
		source_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var arrow_label := Label.new()
		arrow_label.text = " → "
		arrow_label.custom_minimum_size = Vector2(40, 40)
		arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var target_label := Label.new()
		target_label.text = str(rule.target_tag_id)
		target_label.custom_minimum_size = Vector2(120, 40)
		target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var effects_label := Label.new()
		effects_label.text = _rule_text(rule)
		effects_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		effects_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var edit_button := Button.new()
		edit_button.text = "Edit"
		edit_button.pressed.connect(_on_rule_pressed.bind(rule))
		row.add_child(source_label)
		row.add_child(arrow_label)
		row.add_child(target_label)
		row.add_child(effects_label)
		row.add_child(edit_button)
		matrix.add_child(row)
	status_label.text = "Matching interactions: %d" % matching_rules.size()

func _on_rule_pressed(rule: InteractionRule) -> void:
	var source := _find_tag(rule.source_tag_id)
	var target := _find_tag(rule.target_tag_id)
	if source == null or target == null:
		return
	_on_cell_pressed(source, target)

func _find_tag(tag_id: StringName) -> TagInfo:
	for tag in all_tags:
		if tag == null:
			continue
		if tag.id == tag_id:
			return tag
	return null

func _rule_text(rule: InteractionRule) -> String:
	if rule.effect_ids.is_empty():
		return "•"
	return "\n".join(
		Array(rule.effect_ids).map(
			func(id):
				return str(id))
	)

func _tag_tooltip(tag: TagInfo) -> String:
	return "ID: %s\nName: %s\nDescription: %s" % [
		tag.id,
		tag.display_name,
		tag.description]

func _on_cell_pressed(
	source: TagInfo,
	target: TagInfo) -> void:
	var rule := database.get_interaction_by_tags(
		source,
		target)
	var editor := preload("res://addons/tag_editor/interaction_editor.gd").new()
	editor.setup(
		database,
		source,
		target,
		rule)
	add_child(editor)
	editor.tree_exited.connect(refresh)
	editor.popup_centered()

func _add_interaction() -> void:
	var editor := preload("res://addons/tag_editor/interaction_editor.gd").new()
	add_child(editor)
	editor.setup(
		database,
		null,
		null,
		null)
	editor.tree_exited.connect(refresh)
	editor.popup_centered()

func _rule_has_invalid_effect(rule: InteractionRule) -> bool:
	var effect_db := load("res://Interactions/data/EffectDatabase.tres") as EffectDatabase
	if effect_db == null:
		return true
	effect_db.build_index()
	for effect_id in rule.effect_ids:
		if effect_db.get_effect(effect_id) == null:
			return true
	return false
	
func _duplicate_interaction(source: TagInfo, target: TagInfo) -> void:
	if database == null:
		return
	var original := database.get_interaction_by_tags(source, target)
	if original == null:
		return
	var rule := InteractionRule.new()
	rule.source_tag_id = original.source_tag_id
	rule.target_tag_id = original.target_tag_id
	rule.effect_ids = original.effect_ids.duplicate()
	var editor := preload("res://addons/tag_editor/interaction_editor.gd").new()
	add_child(editor)
	editor.setup(database, source, target, rule)
	editor.tree_exited.connect(refresh)
	editor.popup_centered()

func _validate_database() -> void:
	var validator := VALIDATOR_SCRIPT.new()
	var dialog := AcceptDialog.new()
	dialog.title = "Database Validation"
	var label := Label.new()
	label.text = validator.validate()
	label.custom_minimum_size = Vector2(600, 400)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.add_child(label)
	add_child(dialog)
	dialog.popup_centered()
