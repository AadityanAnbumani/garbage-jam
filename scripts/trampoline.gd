extends Area2D

@export var bounce_speed := 1400.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player" and body.velocity.y >= 0.0:
		body.velocity.y = -bounce_speed
