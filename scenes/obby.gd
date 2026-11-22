extends Node2D

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var blind_zone: Area2D = $BlindZone
@onready var eye_layer = $EyeLayer
@onready var eye_zone: Area2D = $EyeZone

var blinded := false

func _ready() -> void:
	blind_zone.body_entered.connect(_on_blind_zone_body_entered)
	eye_zone.body_entered.connect(_on_eye_zone_entered)
	eye_zone.body_exited.connect(_on_eye_zone_exited)

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
