extends CanvasLayer

@export var min_wait := 3.0
@export var max_wait := 6.0
@export var warning_time := 1.0

@onready var eye: Sprite2D = $Eye
@onready var hide_spots: Node = $"../HideSpots"

var player: Node2D
var active := false

func _ready() -> void:
	var screen := get_viewport().get_visible_rect().size
	eye.position = Vector2(screen.x / 2, 120)

func start(p: Node2D) -> void:
	if active:
		return
	player = p
	active = true
	_watch_loop()

func stop() -> void:
	active = false
	create_tween().tween_property(eye, "modulate:a", 0.0, 0.3)

func _watch_loop() -> void:
	while active:
		await get_tree().create_timer(randf_range(min_wait, max_wait)).timeout
		if not active:
			return

		create_tween().tween_property(eye, "modulate:a", 1.0, 0.2)   # eye appears
		await get_tree().create_timer(warning_time).timeout
		if not active:
			return

		if not _is_hidden():
			print("spotted!")
			get_tree().reload_current_scene()
			return

		create_tween().tween_property(eye, "modulate:a", 0.0, 0.3)   # eye leaves

func _is_hidden() -> bool:
	for spot in hide_spots.get_children():
		if spot is Area2D and spot.overlaps_body(player):
			return true
	return false
