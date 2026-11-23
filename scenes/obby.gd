extends Node2D
signal dialogue_finished
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


@onready var ruby_text: RichTextLabel = $player/Camera2D/ruby
@onready var friend_text: RichTextLabel = $"player/Camera2D/friend text"

@onready var ruby_sprite: AnimatedSprite2D = $player/AnimatedSprite2D
@onready var friend_sprite: AnimatedSprite2D = $Friend

@onready var voice_player =  $AudioStreamPlayer2D
var active_text: RichTextLabel
var current_line := 0
var typing := false
var dialogue_active := false

var current_spot: DotsSpot
var dots_player: Node2D
var book_open := false
var blinded := false

@onready var respawn_point: Marker2D = $RespawnPoint

func _ready() -> void:
	if GameManager.caught_by_eye:
		player.global_position = respawn_point.global_position
		player.velocity = Vector2.ZERO
		GameManager.caught_by_eye = false
	GameManager.obby = true
	$StaticBody2D/CollisionShape2D.disabled=true

	if not GameManager.obby_dialogue_played:
		$StaticBody2D/CollisionShape2D.disabled=false
		start_dialogue()
		await dialogue_finished
		GameManager.obby_dialogue_played = true
		$StaticBody2D/CollisionShape2D.disabled=true

		$player/Camera2D/AnimationPlayer.play("pencilfall")
	
	$player/Camera2D/AnimationPlayer.play("pencilfall")

	blind_zone.body_entered.connect(_on_blind_zone_body_entered)
	eye_zone.body_entered.connect(_on_eye_zone_entered)
	eye_zone.body_exited.connect(_on_eye_zone_exited)

	book_layer.visible = false
	dots_puzzle.visible = false
	dots_puzzle.end_puzzle()
	dots_puzzle.puzzle_completed.connect(_on_dots_completed)

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
	$BookLayer/connectTheDots.visible=true
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

	if GameManager.obby:
		dots_book.get_node("BackButton").hide()
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
	if $Pentagram.visible==true:
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/finalscene.tscn")

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

	cutscene_anim.play("birdFly")
	await cutscene_anim.animation_finished

	player.global_position = cutscene_sprite.global_position
	player.visible = true
	player_cam.make_current()
	player_cam.reset_smoothing()
	player.set_physics_process(true)


func start_dialogue() -> void:
	current_line = 0
	dialogue_active = true
	show_dialogue()

var dialogue = [
	{
		"speaker": "ruby",
		"text": "[color=#ffa7ea]AAAAAA!![/color]",
		"audio": preload("res://assets/recordings/aaaa.mp3")
	},
	{
		"speaker": "ruby",
		"text": "[color=#ffa7ea]Where am I?[/color]",
		"audio": preload("res://assets/recordings/obby2.mp3")
	},
	{
		"speaker": "friend",
		"text": "[color=#4F366F]To breathe means to take life, which is what I've taken from you.[/color]",
		"audio": preload("res://assets/recordings/Friend8.mp3")
	},
	{
		"speaker": "friend",
		"text": "[color=#4F366F]You probably won't last in there, so think of this as nothing more than a pitiful gift.[/color]",
		"audio": preload("res://assets/recordings/Friend9.mp3")
	},
	#{
		#"speaker": "ruby",
		#"animation": "sad",
		#"text": "[color=#ffa7ea]I miss my mama.[/color]",
		#"audio": preload("res://assets/recordings/missmama.mp3")
	#}
]


func show_dialogue() -> void:
	typing = true

	ruby_text.hide()
	friend_text.hide()

	var line = dialogue[current_line]

	if line["speaker"] == "ruby":
		active_text = ruby_text
	else:
		active_text = friend_text

	active_text.show()
	active_text.text = line["text"]
	active_text.visible_characters = 0

	voice_player.stop()

	var audio_duration := 0.0

	if line.has("audio"):
		voice_player.stream = line["audio"]
		voice_player.play()
		audio_duration = voice_player.stream.get_length()

	var character_count = active_text.get_total_character_count()
	var typing_speed = 0.05

	if character_count > 0 and audio_duration > 0:
		typing_speed = (audio_duration / character_count) * 0.7

	for i in range(character_count):
		if not typing:
			break

		active_text.visible_characters += 1
		await get_tree().create_timer(typing_speed).timeout

	typing = false

	if voice_player.playing:
		await voice_player.finished

func _input(event: InputEvent) -> void:
	if not dialogue_active:
		return

	if event.is_action_pressed("ui_accept"):

		if typing:
			active_text.visible_characters = -1
			typing = false
			return

		voice_player.stop()
		current_line += 1

		if current_line < dialogue.size():
			show_dialogue()
		else:
			dialogue_active = false
			ruby_text.hide()
			friend_text.hide()
			$StaticBody2D/CollisionShape2D.disabled = true

			dialogue_finished.emit()
			print("Dialogue finished!")
