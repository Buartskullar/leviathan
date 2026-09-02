@tool
extends EditorInspectorPlugin

var TagPicker = preload("res://addons/tag_editor/tag_picker.gd")


func _can_handle(object: Object) -> bool:
	return object is TagSet


func _parse_property(
	object: Object,
	type: Variant.Type,
	name: String,
	hint_type: PropertyHint,
	hint_string: String,
	usage_flags: int,
	wide: bool
) -> bool:

	if object is TagSet and name == "tags":
		add_property_editor(
			name,
			TagPicker.new(),
			false,
			"Tags"
		)

		return true

	return false
