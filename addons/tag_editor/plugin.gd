@tool
extends EditorPlugin

var inspector_plugin: EditorInspectorPlugin
var interaction_dock: Control
var interaction_button: Button


func _enter_tree() -> void:
	# TagSet inspector
	inspector_plugin = preload(
		"res://addons/tag_editor/tag_inspector.gd"
	).new()
	add_inspector_plugin(inspector_plugin)
	# Interaction Database
	interaction_dock = preload(
		"res://addons/tag_editor/interaction_dock.gd"
	).new()
	interaction_dock.name = "Interaction Database"
	interaction_button = add_control_to_bottom_panel(
		interaction_dock,
		"Interactions"
	)

func _exit_tree() -> void:
	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)
		inspector_plugin = null
	if interaction_dock:
		remove_control_from_bottom_panel(interaction_dock)
		interaction_dock.queue_free()
		interaction_dock = null
