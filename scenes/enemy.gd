extends CharacterBody2D

@export var speed := 60.0
@export var start_direction := -1   # -1 = left, 1 = right

var direction := start_direction
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	direction = start_direction
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = direction * speed
	move_and_slide()

	if is_on_wall():
		direction = sign(get_wall_normal().x)

	sprite.flip_h = direction > 0

func _on_hitbox_body_entered(body: Node2D) -> void:
	print("hitbox touched: ", body.name, " groups: ", body.get_groups())
	if body.name == "player":
		get_tree().reload_current_scene()
