extends Node

const DB_PATH := "res://Interactions/data/EffectDatabase.tres"
var database: EffectDatabase

func _ready() -> void:
	if not ResourceLoader.exists(DB_PATH):
		push_error("База данных эффектов НЕ найдена")
		return
	database = load(DB_PATH) as EffectDatabase
	if database == null:
		push_error("Не удалось загрузить базу данных эффектов!")
		return
	database.build_index()
	
func get_effect(effect_id: StringName) -> Effect:
	if database == null:
		return null
	return database.get_effect(effect_id)

func execute_effect(effect_id: StringName, context: EffectContext) -> void:
	var effect := get_effect(effect_id)
	if effect == null:
		push_error("Не найден эффект: %s" % effect_id)
		return
	var script = load(effect.script_path) as Script
	if script:
		var execution_instance = effect.duplicate()
		execution_instance.set_script(script)
		execution_instance.execute(context)
	else:
		effect.execute(context)
