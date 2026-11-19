extends Node2D


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/girlroom.tscn")


func _on_credits_pressed() -> void:
	$Node2D.visible = true
	$TextureButton.disabled = false
	$play.disabled=true
	$credits.disabled=true
	$settings.disabled=true
	$TextureButton.visible=true


func _on_texture_button_pressed() -> void:
	$TextureButton.disabled = true
	$TextureButton.visible=false
	$Node2D.visible=false
	$play.disabled=false
	$credits.disabled=false
	$settings.disabled=false
