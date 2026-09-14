class_name EffectContext
extends RefCounted

var source
var target
var source_tags: TagSet
var target_tags: TagSet

func setup(
	p_source,
	p_target,
	p_source_tags: TagSet,
	p_target_tags: TagSet) -> void:
	source = p_source
	target = p_target
	source_tags = p_source_tags
	target_tags = p_target_tags
