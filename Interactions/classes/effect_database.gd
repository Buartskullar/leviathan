class_name EffectDatabase
extends Resource

@export var effects: Array[Effect] = []

var _effects_map: Dictionary = {}

func build_index() -> void:
	_effects_map.clear()
	for effect in effects:
		if effect == null:
			continue
		if effect.id.is_empty():
			push_warning("У эффетка пустой айдишник")
			continue
		if _effects_map.has(effect.id):
			push_error("Дубликат эффетка: %s" % effect.id)
			continue
		_effects_map[effect.id] = effect

func get_effect(effect_id: StringName) -> Effect:
	if effect_id.is_empty():
		return null
	return _effects_map.get(effect_id, null)
	
	
