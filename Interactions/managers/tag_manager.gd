extends Node

const DB_PATH = "res://Interactions/data/TagDatabase.tres"
var _tags_map: Dictionary = {}

func _ready() -> void:
	if ResourceLoader.exists(DB_PATH):
		var db = load(DB_PATH) as TagDatabase
		if db:
			for tag in db.tags:
				if tag and tag.id:
					_tags_map[tag.id] = tag
	else:
		push_error("Tag base error!!!")

func get_tag(tag_id: StringName) -> TagInfo:
	return _tags_map.get(tag_id, null)

func get_all_tags() -> Array[TagInfo]:
	return _tags_map.values()
