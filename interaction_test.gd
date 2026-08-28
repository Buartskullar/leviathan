extends Node

@onready var object1: TestEntity = $Entity1
@onready var object2: TestEntity = $Entity2

func _ready() -> void:
	InteractionManager.process_interaction(object1, object2)
	print("Дело сделано")
