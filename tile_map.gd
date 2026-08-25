extends Node2D
#нужно сделать чтобы тайлсет собирался из данных в таблице
var tiles_pos: Array[Vector2i]
var tiles_ids: Array[int]
var tiles_grid: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var extracted_tiles_pos = $TileSet.get_used_cells()
	if extracted_tiles_pos == []:
		for i in range(9):
			for z in range(9):
				if z % 2 == 0:
					$TileSet.set_cell(Vector2i(i,z),0,Vector2i(0,0))
				else:
					$TileSet.set_cell(Vector2i(i,z),1,Vector2i(0,0))
	extracted_tiles_pos = $TileSet.get_used_cells()
	for tile in extracted_tiles_pos:
			tiles_pos.append(tile)
			tiles_ids.append($TileSet.get_cell_source_id(tile))
	if tiles_ids.size() == tiles_pos.size():
		for i in tiles_pos.size():
			tiles_grid[tiles_pos[i]] = tiles_ids[i]
	else:
		print("втф массив координат и массив типов не одинаковые")
	print(tiles_grid)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func pass_tilesize():
	return $TileSet.tile_set.tile_size
func pass_usedrect():
	return $TileSet.get_used_rect()
