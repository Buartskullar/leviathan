extends CharacterBody2D

const TILE_SIZE = 64

var direction = Vector2()

const UP = Vector2(0, -1)
const RIGHT = Vector2(1, 0)
const LEFT = Vector2(-1, 0)
const DOWN = Vector2(0, 1)

var fast_movement = false

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("move_down") and !$down.is_colliding():
		_move(DOWN)
	elif Input.is_action_just_pressed("move_up") and !$up.is_colliding():
		_move(UP)
	elif Input.is_action_just_pressed("move_left") and !$left.is_colliding():
		_move(LEFT)
	elif Input.is_action_just_pressed("move_right") and !$right.is_colliding():
		_move(RIGHT)
	
	if Input.is_action_just_pressed("move_down") and $down.is_colliding():
		_attack(DOWN)
	elif Input.is_action_just_pressed("move_up") and $up.is_colliding():
		_attack(UP)
	elif Input.is_action_just_pressed("move_left") and $left.is_colliding():
		_attack(LEFT)
	elif Input.is_action_just_pressed("move_right") and $right.is_colliding():
		_attack(RIGHT)
		

##двигает персонажа на TILE_SIZE в сторону вектора DIR.
func _move(dir: Vector2):
	global_position += dir * TILE_SIZE

func _attack(dir: Vector2):
	if dir == DOWN and $down.get_collider().is_in_group("destructable"):
		$down.get_collider().queue_free()
	elif dir == UP and $up.get_collider().is_in_group("destructable"):
		$up.get_collider().queue_free()
	elif dir == RIGHT and $right.get_collider().is_in_group("destructable"):
		$right.get_collider().queue_free()
	elif dir == LEFT and $left.get_collider().is_in_group("destructable"):
		$left.get_collider().queue_free()
