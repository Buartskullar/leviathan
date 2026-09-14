@tool
extends VBoxContainer

const TAG_DB_PATH := "res://Interactions/data/TagDatabase.tres"
const INTERACTION_DB_PATH := "res://Interactions/data/InteractionDatabase.tres"

var database: InteractionDatabase

var search_source := LineEdit.new()
var search_target := LineEdit.new()

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
		push_error(
			"TagDatabase not found: " + TAG_DB_PATH
		)

	database = load(
		INTERACTION_DB_PATH
	) as InteractionDatabase

	if database == null:
		push_error(
			"InteractionDatabase not found: "
			+ INTERACTION_DB_PATH
		)
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

	var add_button := Button.new()
	add_button.text = "+ Add Interaction"
	add_button.pressed.connect(_add_interaction)

	toolbar.add_child(reload_button)
	toolbar.add_child(add_button)

	add_child(toolbar)

	var filters := HBoxContainer.new()

	search_source.placeholder_text = "Search source..."
	search_target.placeholder_text = "Search target..."

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

	var source_tags := _get_visible_tags(
		search_source.text
	)

	var target_tags := _get_visible_tags(
		search_target.text
	)

	matrix.columns = target_tags.size() + 1

	var corner := Label.new()
	corner.text = "SOURCE ↓ / TARGET →"
	corner.custom_minimum_size = Vector2(160, 40)
	matrix.add_child(corner)

	for target in target_tags:
		var label := Label.new()

		label.text = str(target.id)

		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)

		label.vertical_alignment = (
			VERTICAL_ALIGNMENT_CENTER
		)

		label.custom_minimum_size = Vector2(100, 40)
		label.tooltip_text = _tag_tooltip(target)

		matrix.add_child(label)

	for source in source_tags:
		var source_label := Label.new()

		source_label.text = str(source.id)
		source_label.vertical_alignment = (
			VERTICAL_ALIGNMENT_CENTER
		)

		source_label.custom_minimum_size = Vector2(
			160,
			40
		)

		source_label.tooltip_text = _tag_tooltip(source)

		matrix.add_child(source_label)

		for target in target_tags:
			var rule := database.get_interaction_by_tags(
				source,
				target
			)

			var button := Button.new()

			button.custom_minimum_size = Vector2(
				100,
				40
			)

			if rule:
				button.text = _rule_text(rule)
				button.tooltip_text = "Edit interaction"
			else:
				button.text = "—"
				button.tooltip_text = "Create interaction"

			button.pressed.connect(
				_on_cell_pressed.bind(
					source,
					target
				)
			)

			matrix.add_child(button)

	status_label.text = (
		"Interactions: %d"
		% database.rules.size()
	)


func _rule_text(
	rule: InteractionRule
) -> String:

	if rule.effect_ids.is_empty():
		return "•"

	return "\n".join(
		Array(rule.effect_ids).map(
			func(id):
				return str(id))
	)


func _tag_tooltip(
	tag: TagInfo
) -> String:

	return "ID: %s\nName: %s\nDescription: %s" % [
		tag.id,
		tag.display_name,
		tag.description
	]


func _on_cell_pressed(
	source: TagInfo,
	target: TagInfo
) -> void:

	var rule := database.get_interaction_by_tags(
		source,
		target
	)

	var editor := preload(
		"res://addons/tag_editor/interaction_editor.gd"
	).new()

	editor.setup(
		database,
		source,
		target,
		rule
	)

	add_child(editor)

	editor.tree_exited.connect(
		refresh
	)

	editor.popup_centered()


func _add_interaction() -> void:
	var editor := preload(
		"res://addons/tag_editor/interaction_editor.gd"
	).new()

	add_child(editor)

	editor.setup(
		database,
		null,
		null,
		null
	)

	editor.tree_exited.connect(refresh)
	editor.popup_centered()
