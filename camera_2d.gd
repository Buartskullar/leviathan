extends Camera2D

@export var tilemap: TileMapLayer
@export var playerobj: CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var zoom_vector = _aligntotiles()
	#set_zoom(zoom_vector)
	_applylimits()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_sticktoplayer()
 
func _sticktoplayer():
	global_position = playerobj.global_position

func _applylimits():
	var tilemap_info = GetTilemapInfo()
	var level_size = Vector2(tilemap_info.size * tilemap_info.tile_size)
	
	set_limit(SIDE_LEFT, 0)
	set_limit(SIDE_TOP, 0)
	set_limit(SIDE_RIGHT, level_size.x)
	set_limit(SIDE_BOTTOM, level_size.y)

#неиспользуемая функция которая пытается подогнать камеру под клеточки. 
#Нет смысла заниматься этим, пока у нас нет интерфейса
func _aligntotiles():
	var viewport_size = get_viewport().size
	
	var tilemap_info = GetTilemapInfo()
	var amount_of_full_tiles = Vector2i(
		viewport_size[0]/tilemap_info.tile_size.x,
		viewport_size[1]/tilemap_info.tile_size.y
		)
	amount_of_full_tiles += Vector2i(1,1)
	
	#32/16
	var target_size = Vector2(tilemap_info.tile_size * amount_of_full_tiles)
	 
	var viewport_aspect = float(viewport_size[0]) / viewport_size[1]
	var target_aspect = float(target_size.x) / target_size.y
	
	var new_zoom_x = 1.0
	var new_zoom_y = 1.0
	
	if viewport_aspect > target_aspect:
		new_zoom_y = float(viewport_size[1]) / target_size.y
		new_zoom_x = float(viewport_size[0]) / target_size.x
	else:
		new_zoom_y = float(target_size.y) / viewport_size[1]
		new_zoom_x = float(target_size.x) / viewport_size[0]
	
	return (Vector2(new_zoom_x, new_zoom_y))
			
func GetTilemapInfo():
	var tile_size = tilemap.tile_set.tile_size
	
	var tilemap_rect = tilemap.get_used_rect()
	var tilemap_size = Vector2i(
		tilemap_rect.end.x - tilemap_rect.position.x,
		tilemap_rect.end.y - tilemap_rect.position.y
	)
	return {"size": tilemap_size, "tile_size": tile_size}
