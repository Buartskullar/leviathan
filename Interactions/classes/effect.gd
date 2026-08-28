class_name Effect
extends Resource

@export var id: StringName
@export var script_path: String

func execute(context: EffectContext) -> void:
	print("BASE EFFECT EXECUTED")
	pass
