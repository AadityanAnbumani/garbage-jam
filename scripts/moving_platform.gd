extends AnimatableBody2D

@export var travel := Vector2(1300, 0)   # how far it moves from where you place it
@export var speed := 100.0

var start_pos: Vector2
var end_pos: Vector2
var target: Vector2

func _ready() -> void:
	start_pos = global_position
	end_pos = start_pos + travel
	target = end_pos

func _physics_process(delta: float) -> void:
	global_position = global_position.move_toward(target, speed * delta)
	if global_position.is_equal_approx(target):
		target = start_pos if target == end_pos else end_pos
