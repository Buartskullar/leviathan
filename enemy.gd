extends StaticBody2D
@onready var tag_set_node: TagSetNode = $TagSet
var tag_set: TagSet:
	get:
		return tag_set_node.tag_set

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
