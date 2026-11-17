extends Node2D
func  _ready() -> void:
	pass
	

func _on_girlpressed(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			$AnimatedSprite2D.play("touch")
