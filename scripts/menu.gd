
extends Node2D

var is_pause_menu := false

func _ready() -> void:
	if not GameManager.menu_animation_played:
		$AnimationPlayer.play("fade out")
		GameManager.menu_animation_played = true


func _input(event):
	if event.is_action_pressed("ui_cancel") and not is_pause_menu:
		$"Let'sDrawRubyTitle".visible=false
		is_pause_menu = true
		visible = true
		get_tree().paused = true


func _on_play_pressed() -> void:
	if is_pause_menu:
		# Continue playing
		is_pause_menu = false
		visible = false
		get_tree().paused = false
	else:
		# Start new game
		get_tree().change_scene_to_file("res://scenes/girlroom.tscn")


func _on_credits_pressed() -> void:
	$Node2D.visible = true
	$TextureButton.disabled = false
	$play.disabled = true
	$credits.disabled = true
	$settings.disabled = true
	$TextureButton.visible = true


func _on_texture_button_pressed() -> void:
	$TextureButton.disabled = true
	$TextureButton.visible = false
	$Node2D.visible = false
	$play.disabled = false
	$credits.disabled = false
	$settings.disabled = false
	$settings2.visible = false


func _on_settings_pressed() -> void:
	$settings2.visible = true
	$TextureButton.disabled = false
	$play.disabled = true
	$credits.disabled = true
	$settings.disabled = true
	$TextureButton.visible = true
