extends Node2D

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var blind_zone: Area2D = $BlindZone
@onready var eye_layer = $EyeLayer
@onready var eye_zone: Area2D = $EyeZone
@onready var book_layer: CanvasLayer = $BookLayer
@onready var dots_book: Node2D = $BookLayer/connectTheDots
@onready var dots_puzzle = $BookLayer/connectTheDots/Puzzle
@onready var dots_spots: Node2D = $DotsSpots
@onready var player: CharacterBody2D = $player
@onready var player_cam: Camera2D = $player/Camera2D
@onready var cutscene_sprite: Sprite2D = $GirlFly
@onready var cutscene_cam: Camera2D = $GirlFly/Camera2D
@onready var cutscene_anim: AnimationPlayer = $AnimationPlayer

var current_spot: DotsSpot
var dots_player: Node2D
var book_open := false
var blinded := false

func _ready() -> void:
	blind_zone.body_entered.connect(_on_blind_zone_body_entered)
	eye_zone.body_entered.connect(_on_eye_zone_entered)
	eye_zone.body_exited.connect(_on_eye_zone_exited)
	book_layer.visible = false
	dots_puzzle.visible = false
	dots_puzzle.end_puzzle()
	dots_puzzle.puzzle_completed.connect(_on_dots_completed)
	dots_book.get_node("BackButton").pressed.connect(_close_book)
	for spot: DotsSpot in dots_spots.get_children():
		spot.body_entered.connect(_on_dots_spot_entered.bind(spot))
		if spot.reveal:
			spot.reveal.visible = false
			_set_collisions(spot.reveal, false)

func _on_blind_zone_body_entered(body: Node2D) -> void:
	print("entered: ", body.name)
	if body.name == "player" and not blinded:
		blinded = true
		canvas_layer.blind()

func _on_eye_zone_entered(body: Node2D) -> void:
	if body.name == "player":
		eye_layer.start(body)

func _on_eye_zone_exited(body: Node2D) -> void:
	if body.name == "player":
		eye_layer.stop()

func _set_collisions(root: Node, enabled: bool) -> void:
	for type in ["CollisionShape2D", "CollisionPolygon2D"]:
		for c in root.find_children("*", type, true, false):
			c.set_deferred("disabled", not enabled)

func _on_dots_spot_entered(body: Node2D, spot: DotsSpot) -> void:
	if body.name != "player" or spot.solved or book_open:
		return
	current_spot = spot
	dots_player = body
	if "velocity" in body:
		body.velocity = Vector2.ZERO
	_open_book(spot)

func _open_book(spot: DotsSpot) -> void:
	book_open = true
	dots_player.set_physics_process(false)
	book_layer.visible = true
	for n in ["BackButton", "help", "undo", "clear", "StickyNote"]:
		var node = dots_book.get_node_or_null(n)
		if node:
			node.visible = true
	var help2 = dots_book.get_node_or_null("help2")
	if help2:
		help2.visible = false
	dots_puzzle.end_puzzle()
	dots_puzzle.required_coverage = 0.8
	dots_puzzle.allowed_stray = 0.35
	dots_puzzle.tolerance = spot.tolerance
	dots_puzzle.closed = spot.closed
	dots_puzzle.visible = true
	dots_puzzle.input_enabled = true
	dots_puzzle.start_puzzle(spot.drawing)

func _close_book() -> void:
	book_open = false
	dots_puzzle.end_puzzle()
	dots_puzzle.visible = false
	book_layer.visible = false
	if dots_player:
		dots_player.set_physics_process(true)

func _on_dots_completed() -> void:
	var spot := current_spot
	spot.solved = true
	await get_tree().create_timer(1.0).timeout
	_close_book()
	current_spot = null
	if spot.reveal:
		await get_tree().create_timer(0.5).timeout
		_reveal(spot.reveal)
	if spot.cutscene_after:
		await get_tree().create_timer(1.0).timeout
		await play_cutscene()

func _reveal(node: Node2D) -> void:
	node.modulate.a = 0.0
	node.visible = true
	_set_collisions(node, true)
	create_tween().tween_property(node, "modulate:a", 1.0, 0.6)
	
func play_cutscene() -> void:
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	player.visible = false
	cutscene_cam.make_current()

	cutscene_anim.play("your_animation_name")
	await cutscene_anim.animation_finished

	player.global_position = cutscene_sprite.global_position
	player.visible = true
	player_cam.make_current()
	player_cam.reset_smoothing()
	player.set_physics_process(true)
