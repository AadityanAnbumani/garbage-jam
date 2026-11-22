extends Node2D

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var blind_zone: Area2D = $BlindZone

var blinded := false

func _ready() -> void:
	blind_zone.body_entered.connect(_on_blind_zone_body_entered)

func _on_blind_zone_body_entered(body: Node2D) -> void:
	print("entered: ", body.name)
	if body.name == "player" and not blinded:
		blinded = true
		canvas_layer.blind()
