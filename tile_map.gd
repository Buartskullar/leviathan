extends Node2D
#тайлмапа процедурно генерирует локацию
#тайлмапа выбирает теги для тайлов по группам (стенам теги стен, ямам теги ям etc.)
#тайлмапа создаёт коллайдер зоны вписывая им в тегсеты эти теги
#тайлмапа менеджит столкновения

var tiles_pos: Array[Vector2i]
var tiles_ids: Array[int]
var tiles_grid: Dictionary

@onready var colliderzone = preload("res://tile_collider.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var extracted_tiles_pos = $TileSet.get_used_cells()
	build_map(extracted_tiles_pos)
	extracted_tiles_pos = $TileSet.get_used_cells()
	for tile in extracted_tiles_pos:
			tiles_pos.append(tile)
			tiles_ids.append($TileSet.get_cell_source_id(tile))
	if tiles_ids.size() == tiles_pos.size():
		for i in tiles_pos.size():
			tiles_grid[tiles_pos[i]] = tiles_ids[i]
	else:
		print("втф массив координат и массив типов не одинаковые")
	_make_zones(tiles_grid)

func build_map(tiles):
	if tiles == []:
		for i in range(32):
			for z in range(32):
				if z % 2 == 0 or i % 4 == 0:
					$TileSet.set_cell(Vector2i(i,z),0,Vector2i(0,0))
				elif z % 5 == 0:
					$TileSet.set_cell(Vector2i(i,z),2,Vector2i(0,0))
				else:
					$TileSet.set_cell(Vector2i(i,z),1,Vector2i(0,0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _go_forth_my_tags(body: Node2D, tile: Node2D):
	InteractionManager.process_interaction(tile, body)

func _make_zones(tiles_grid):
	#должен создавать боксы коллизий
	#сделать умнее, чтобы ты давал все теги и жёстко раздавал
	for tile in tiles_grid:
		if tiles_grid[tile] == 1:
			var collider = colliderzone.instantiate()
			collider.global_position = Vector2(tile) * 64
			add_child(collider)
			collider.tag_set.add_tag("solid")
		elif tiles_grid[tile] == 2:
			var collider = colliderzone.instantiate()
			collider.global_position = Vector2(tile) * 64
			add_child(collider)
			collider.tag_set.add_tag("fire")
			collider._body_entered_with_self.connect(_go_forth_my_tags)

func pass_tilesize():
	return $TileSet.tile_set.tile_size
func pass_usedrect():
	return $TileSet.get_used_rect()
