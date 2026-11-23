extends Node2D

signal defeated

@export var rubble_scene: PackedScene
@export var rubble_needed := 5
@export var rubble_chance := 0.3

@export var start_wait := 2.5       # gap between slams
@export var start_warning := 1.8    # time the red light shows before impact
@export var min_wait := 0.8
@export var min_warning := 0.6
@export var speedup := 0.92         # each slam multiplies the times by this
@export var place_radius := 120.0   # how close to the red light she must be

@onready var arena_left: Marker2D = $ArenaLeft
@onready var arena_right: Marker2D = $ArenaRight
@onready var red_light: Sprite2D = $RedLight
@onready var hand: Node2D = $Hand
@onready var hitbox: Area2D = $Hand/Hitbox

var player: Node2D
var camera: Camera2D
var active := false
var marker_active := false
var spot := Vector2.ZERO
var rubble_count := 0
var wait_time: float
var warning_time: float

func _ready() -> void:
	hitbox.monitoring = false
	hand.visible = false
	red_light.visible = false

func start(p: Node2D) -> void:
	if active:
		return
	player = p
	camera = p.get_node("Camera2D")
	wait_time = start_wait
	warning_time = start_warning
	active = true
	_fight_loop()

func _process(_delta: float) -> void:
	if marker_active and rubble_count >= rubble_needed \
			and Input.is_action_just_pressed("place_rubble"):
		if absf(player.global_position.x - spot.x) <= place_radius:
			_defeat()

func _fight_loop() -> void:
	while active:
		await get_tree().create_timer(wait_time).timeout
		if not active:
			return
		await _slam()
		wait_time = maxf(min_wait, wait_time * speedup)
		warning_time = maxf(min_warning, warning_time * speedup)

func _view_rect() -> Rect2:
	var size := get_viewport_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - size / 2.0, size)

func _pick_spot_x() -> float:
	var view := _view_rect()
	var left := maxf(arena_left.global_position.x, view.position.x + 80.0)
	var right := minf(arena_right.global_position.x, view.end.x - 80.0)
	if left >= right:
		return player.global_position.x
	return randf_range(left, right)

func _slam() -> void:
	var floor_y := arena_left.global_position.y
	spot = Vector2(_pick_spot_x(), floor_y)

	# 1. Warning: red light
	red_light.global_position = spot
	red_light.visible = true
	marker_active = true
	await get_tree().create_timer(warning_time).timeout
	marker_active = false
	red_light.visible = false
	if not active:        # she placed the rubble during the warning
		return

	# 2. Hand drops from above the screen
	hand.global_position = Vector2(spot.x, _view_rect().position.y - 400.0)
	hand.visible = true
	var drop := create_tween()
	drop.tween_property(hand, "global_position:y", floor_y, 0.12)
	await drop.finished

	# 3. Impact check
	hitbox.set_deferred("monitoring", true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if hitbox.overlaps_body(player):
		print("crushed!")
		get_tree().reload_current_scene()
		return
	hitbox.set_deferred("monitoring", false)

	# 4. Maybe drop rubble
	if rubble_scene and randf() < rubble_chance:
		var r := rubble_scene.instantiate()
		get_parent().add_child(r)
		r.global_position = spot
		r.collected.connect(_on_rubble_collected)

	# 5. Hand lifts away
	await get_tree().create_timer(0.4).timeout
	var lift := create_tween()
	lift.tween_property(hand, "global_position:y", _view_rect().position.y - 400.0, 0.3)
	await lift.finished
	hand.visible = false

func _on_rubble_collected() -> void:
	rubble_count += 1
	print("rubble: ", rubble_count, "/", rubble_needed)

func _defeat() -> void:
	active = false
	marker_active = false
	red_light.visible = false
	hand.visible = false
	print("hand defeated!")
	defeated.emit()
