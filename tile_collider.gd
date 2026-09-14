extends Area2D

signal _body_entered_with_self(body: Node2D, tile: Node2D)

@onready var tag_set_node: TagSetNode = $TagSet
@onready var tag_set: TagSet:
	get:
		return tag_set_node.tag_set

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if tag_set_node and tag_set_node.tag_set:
		tag_set_node.tag_set = tag_set_node.tag_set.duplicate(true)

func _on_body_entered(body: Node2D) -> void:
	_body_entered_with_self.emit(body, self)
