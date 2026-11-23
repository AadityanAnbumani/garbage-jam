class_name DotsSpot
extends Area2D

@export var drawing: PackedScene
@export var reveal: Node2D
@export var tolerance := 20.0
@export var closed := false
@export var cutscene_after := false

var solved := false
