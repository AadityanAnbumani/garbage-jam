extends CanvasLayer

@onready var flash: ColorRect = $Flash

func blind(hold_time := 2.0) -> void:
	var t := create_tween()
	t.tween_property(flash, "color:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	t.tween_interval(hold_time)
	t.tween_property(flash, "color:a", 0.0, 1.5)
