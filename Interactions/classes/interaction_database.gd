class_name InteractionDatabase
extends Resource

@export var rules: Array[InteractionRule] = []

var _interactions: Dictionary = {}

func build_index() -> void:
	_interactions.clear()
	for rule in rules:
		if rule == null:
			continue
		if rule.source_tag_id.is_empty():
			continue
		if rule.target_tag_id.is_empty():
			continue
		if not _interactions.has(rule.source_tag_id):
			_interactions[rule.source_tag_id] = {}
		var source_map: Dictionary = _interactions[rule.source_tag_id]
		if source_map.has(rule.target_tag_id):
			push_error("Дубликат взаимодействий: %s -> %s" % [rule.source_tag_id, rule.target_tag_id])
			continue
		source_map[rule.target_tag_id] = rule

func get_interaction(source_tag_id: StringName, target_tag_id: StringName) -> InteractionRule:
	if source_tag_id.is_empty():
		return null
	if target_tag_id.is_empty():
		return null
	var source_map: Dictionary = _interactions.get(source_tag_id, {})
	return source_map.get(target_tag_id, null)

func get_interaction_by_tags(source_tag: TagInfo, target_tag: TagInfo) -> InteractionRule:
	if source_tag == null:
		return null
	if target_tag == null:
		return null
	return get_interaction(source_tag.id, target_tag.id)

func get_interactions(source_tags: TagSet, target_tags: TagSet) -> Array[InteractionRule]:
	var result: Array[InteractionRule] = []
	if source_tags == null:
		return result
	if target_tags == null:
		return result
	for source_tag in source_tags.tags:
		if source_tag == null:
			continue
		var source_map: Dictionary = _interactions.get(source_tag.id, {})
		if source_map.is_empty():
			continue
		for target_tag in target_tags.tags:
			if target_tag == null:
				continue
			var rule: InteractionRule = source_map.get(target_tag.id, null)
			if rule != null:
				result.append(rule)
	return result

func has_interaction(source_tags: TagSet, target_tags: TagSet) -> bool:
	if source_tags == null:
		return false
	if target_tags == null:
		return false
	for source_tag in source_tags.tags:
		if source_tag == null:
			continue
		var source_map: Dictionary = _interactions.get(source_tag.id, {})
		if source_map.is_empty():
			continue
		for target_tag in target_tags.tags:
			if target_tag == null:
				continue
			if source_map.has(target_tag.id):
				return true
	return false

func get_source_interactions(source_tag_id: StringName) -> Dictionary:
	return _interactions.get(source_tag_id, {})

func validate() -> bool:
	var valid := true
	var pairs: Dictionary = {}
	for rule in rules:
		if rule == null:
			push_error("InteractionDatabase имеет нулевое правило")
			valid = false
			continue
		if rule.source_tag_id.is_empty():
			push_error("У InteractionRule пустой сурс тег id")
			valid = false
			continue
		if rule.target_tag_id.is_empty():
			push_error("У InteractionRule пустой таргет тег id")
			valid = false
			continue
		if TagManager.get_tag(rule.source_tag_id) == null:
			push_error("Неизвестный сурс тег: %s" % rule.source_tag_id)
			valid = false
		if TagManager.get_tag(rule.target_tag_id) == null:
			push_error("Неизвестный таргет тег: %s" % rule.target_tag_id)
			valid = false
		var key := "%s|%s" % [rule.source_tag_id, rule.target_tag_id]
		if pairs.has(key):
			push_error("Дубликат взаимодействий: %s -> %s" % [rule.source_tag_id, rule.target_tag_id])
			valid = false
		else:
			pairs[key] = true
	return valid
