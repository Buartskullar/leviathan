@tool
extends EditorPlugin

var inspector_plugin: EditorInspectorPlugin
var interaction_dock: Control
var interaction_button: Button
var tag_database_dock: Control
var effect_database_dock: Control

func _enter_tree() -> void:
	inspector_plugin = preload("res://addons/tag_editor/tag_inspector.gd").new()
	add_inspector_plugin(inspector_plugin)
	interaction_dock = preload("res://addons/tag_editor/interaction_dock.gd").new()
	interaction_dock.name = "Interaction Database"
	interaction_button = add_control_to_bottom_panel(interaction_dock, "Interaction editor")
	tag_database_dock = preload("res://addons/tag_editor/tag_database_dock.gd").new()
	tag_database_dock.name = "Tag Database"
	add_control_to_bottom_panel(tag_database_dock,"Tag editor")
	effect_database_dock = preload("res://addons/tag_editor/effect_database_dock.gd").new()
	effect_database_dock.name = "Effect Database"
	add_control_to_bottom_panel(effect_database_dock, "Effect editor")

func _exit_tree() -> void:
	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)
		inspector_plugin = null
	if interaction_dock:
		remove_control_from_bottom_panel(interaction_dock)
		interaction_dock.queue_free()
		interaction_dock = null
	if tag_database_dock:
		remove_control_from_bottom_panel(tag_database_dock)
		tag_database_dock.queue_free()
		tag_database_dock = null
	if effect_database_dock:
		remove_control_from_bottom_panel(effect_database_dock)
		effect_database_dock.queue_free()
		effect_database_dock = null
