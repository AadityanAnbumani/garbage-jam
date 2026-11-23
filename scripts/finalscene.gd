extends Node2D
func _ready():
	GameManager.obby = false
	$AnimatedSprite2D2.play("um")
	await get_tree().create_timer(1.0).timeout
	$AnimatedSprite2D2.play("huh")
	$AnimationPlayer.play("fade out")
	await $AnimationPlayer.animation_finished
	GameManager.menu_animation_played = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
