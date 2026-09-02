extends Node

const INTERACTION_DB_PATH := "res://Interactions/data/InteractionDatabase.tres"
var database: InteractionDatabase

func _ready() -> void:
	database = load(INTERACTION_DB_PATH) as InteractionDatabase
	if database == null:
		push_error("Ошибка загрузки матрицы взаимодействий")
		return
	database.build_index()

func process_interaction(source: Node, target: Node) -> void:
	var source_tag_set: TagSet = source.get_node("TagSet").tag_set
	var target_tag_set: TagSet = target.get_node("TagSet").tag_set
	if source_tag_set == null or target_tag_set == null:
		return
	var rules := database.get_interactions(source_tag_set, target_tag_set)
	if rules.is_empty():
		return
	var context := EffectContext.new()
	context.setup(
		source,
		target,
		source_tag_set,
		target_tag_set)
	for rule in rules:
		_execute_rule(rule, context)
func _execute_rule(rule: InteractionRule, context: EffectContext) -> void:
	for effect_id in rule.effect_ids:
		EffectManager.execute_effect(effect_id, context)
