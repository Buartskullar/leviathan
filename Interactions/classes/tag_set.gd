class_name TagSet
extends Resource

@export var tags: Array[TagInfo] = []

func has_tag(tag_identifier: Variant) -> bool:
	var target_tag: TagInfo = _get_tag_resource(tag_identifier)
	return target_tag in tags

func add_tag(tag_identifier: Variant) -> void:
	var target_tag: TagInfo = _get_tag_resource(tag_identifier)
	if target_tag == null:
		return
	if not has_tag(target_tag):
		tags.append(target_tag)

func remove_tag(tag_identifier: Variant) -> void:
	var target_tag: TagInfo = _get_tag_resource(tag_identifier)
	if target_tag:
		tags.erase(target_tag)

func has_all(required_tags: Array) -> bool:
	for t in required_tags:
		if not has_tag(t):
			return false
	return true

func has_any(required_tags: Array) -> bool:
	for t in required_tags:
		if has_tag(t):
			return true
	return false

func clear() -> void:
	tags.clear()

func _get_tag_resource(identifier: Variant) -> TagInfo:
	if identifier is TagInfo:
		return identifier
	if identifier is String or identifier is StringName:
		return TagManager.get_tag(identifier as StringName)
	return null
