extends Area2D

var triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player" and not triggered:
		triggered = true
		get_tree().reload_current_scene()
