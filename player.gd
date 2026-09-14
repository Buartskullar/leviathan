extends CharacterBody2D

const TILE_SIZE = 64

@onready var tag_set_node: TagSetNode = $TagSet
var tag_set: TagSet:
	get:
		return tag_set_node.tag_set

var direction = Vector2()

const UP = Vector2(0, -1)
const RIGHT = Vector2(1, 0)
const LEFT = Vector2(-1, 0)
const DOWN = Vector2(0, 1)

var fast_movement = false

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("move_down"):
		_move(DOWN)
	elif Input.is_action_just_pressed("move_up"):
		_move(UP)
	elif Input.is_action_just_pressed("move_left"):
		_move(LEFT)
	elif Input.is_action_just_pressed("move_right"):
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
	if dir == DOWN:
		if $down.is_colliding() and $down.get_collider().tag_set.has_tag("solid"):
			return
		global_position += dir * TILE_SIZE
	elif dir == UP:
		if $up.is_colliding() and $up.get_collider().tag_set.has_tag("solid"):
			return
		global_position += dir * TILE_SIZE
	elif dir == LEFT:
		if $left.is_colliding() and $left.get_collider().tag_set.has_tag("solid"):
			return
		global_position += dir * TILE_SIZE
	elif dir == RIGHT:
		if $right.is_colliding() and $right.get_collider().tag_set.has_tag("solid"):
			return
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
