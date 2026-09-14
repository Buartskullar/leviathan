@tool
class_name DatabaseValidator
extends RefCounted

const TAG_DB_PATH := "res://Interactions/data/TagDatabase.tres"
const INTERACTION_DB_PATH := "res://Interactions/data/InteractionDatabase.tres"
const EFFECT_DB_PATH := "res://Interactions/data/EffectDatabase.tres"

func validate() -> String:
	var output := ""
	var errors := 0
	var warnings := 0
	var tag_db := load(TAG_DB_PATH) as TagDatabase
	var interaction_db := load(INTERACTION_DB_PATH) as InteractionDatabase
	var effect_db := load(EFFECT_DB_PATH) as EffectDatabase
	if tag_db == null:
		output += "ERROR: TagDatabase not found\n"
		errors += 1
	if interaction_db == null:
		output += "ERROR: InteractionDatabase not found\n"
		errors += 1
	if effect_db == null:
		output += "ERROR: EffectDatabase not found\n"
		errors += 1
	if errors > 0:
		return output + "\nErrors: %d\nWarnings: %d" % [errors, warnings]
	var tag_ids := {}
	for tag in tag_db.tags:
		if tag == null:
			output += "ERROR: Null tag\n"
			errors += 1
			continue
		if tag.id.is_empty():
			output += "ERROR: Tag with empty ID\n"
			errors += 1
			continue
		if tag_ids.has(tag.id):
			output += "ERROR: Duplicate tag ID: %s\n" % tag.id
			errors += 1
		else:
			tag_ids[tag.id] = true
	var effect_ids := {}
	for effect in effect_db.effects:
		if effect == null:
			output += "ERROR: Null effect\n"
			errors += 1
			continue
		if effect.id.is_empty():
			output += "ERROR: Effect with empty ID\n"
			errors += 1
			continue
		if effect_ids.has(effect.id):
			output += "ERROR: Duplicate effect ID: %s\n" % effect.id
			errors += 1
		else:
			effect_ids[effect.id] = true
		if effect.script_path.is_empty():
			output += "WARNING: Effect %s has no script path\n" % effect.id
			warnings += 1
		elif not FileAccess.file_exists(effect.script_path):
			output += "ERROR: Missing script for effect %s: %s\n" % [effect.id, effect.script_path]
			errors += 1
	var pairs := {}
	for rule in interaction_db.rules:
		if rule == null:
			output += "ERROR: Null interaction rule\n"
			errors += 1
			continue
		if rule.source_tag_id.is_empty():
			output += "ERROR: Interaction has empty source ID\n"
			errors += 1
			continue
		if rule.target_tag_id.is_empty():
			output += "ERROR: Interaction has empty target ID\n"
			errors += 1
			continue
		if not tag_ids.has(rule.source_tag_id):
			output += "ERROR: Unknown source tag: %s\n" % rule.source_tag_id
			errors += 1
		if not tag_ids.has(rule.target_tag_id):
			output += "ERROR: Unknown target tag: %s\n" % rule.target_tag_id
			errors += 1
		var pair := "%s|%s" % [rule.source_tag_id, rule.target_tag_id]
		if pairs.has(pair):
			output += "ERROR: Duplicate interaction: %s\n" % pair
			errors += 1
		else:
			pairs[pair] = true
		if rule.effect_ids.is_empty():
			output += "WARNING: Interaction %s has no effects\n" % pair
			warnings += 1
		for effect_id in rule.effect_ids:
			if not effect_ids.has(effect_id):
				output += "ERROR: Unknown effect %s in interaction %s\n" % [effect_id, pair]
				errors += 1
	output += "\nErrors: %d\nWarnings: %d" % [errors, warnings]
	if errors == 0:
		output = "VALID\n\n" + output
	else:
		output = "INVALID\n\n" + output
	return output
