extends Effect

func execute(context: EffectContext) -> void:
	if context.target_tags == null:
		return
	context.target_tags.add_tag(&"fire")
	print(context.target.name, " был ПОДОЖЖЁН ", context.source.name)
	for tag in context.target.tag_set.tags:
		print(context.target.name, " TAG: ", tag.id)
