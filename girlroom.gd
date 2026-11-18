
extends Node2D

@onready var dialogue_scene = $Node2D/Control

var dialogue_active = false
var mama = false

func _ready() -> void:
	dialogue_scene.dialogue_finished.connect(_on_dialogue_finished)

	$Node2D.visible = false
	dialogue_scene.set_process_input(false)


func _on_girlpressed(viewport: Node, event: InputEvent, shape_idx: int) -> void:

	if dialogue_active:
		return

	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			if !mama:
				dialogue_active = true

				$AnimatedSprite2D.play("touch")
				#keyhole anim here possibly
				await get_tree().create_timer(1.0).timeout
				
				$mom.visible=false
				$Node2D.visible = true
				dialogue_scene.set_process_input(true)
				dialogue_scene.start_dialogue()
			#ruby has book atp	
			if mama:
				$AnimatedSprite2D.play("touchbook")
				await get_tree().create_timer(1.0).timeout
				$connectTheDots.visible = true
				
				

func _on_dialogue_finished():
	$Node2D.visible = false
	mama = true
	dialogue_scene.set_process_input(false)

	dialogue_active = false
	$AnimatedSprite2D.play("rubybook")
	
