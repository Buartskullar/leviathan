class_name TestEntity
extends Node2D

@onready var tag_set_node: TagSetNode = $TagSet

var tag_set: TagSet:
	get:
		return tag_set_node.tag_set

func _ready() -> void:
	for tag in tag_set.tags:
		print(name, " TAG: ", tag.id)
