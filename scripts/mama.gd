
extends Control
signal dialogue_finished

@onready var mom_text = $mama
@onready var ruby_text = $ruby
@onready var ruby_sprite = $"../AnimatedSprite2D"
@onready var voice_player = $VoicePlayer
var dialogue_finished_typing = false

var active_text: RichTextLabel

var dialogue = [
	{
		"speaker": "ruby",
		"animation": "default",
		"text": "[color=#ffa7ea] Yes, mama?[/color]",
		"audio": preload("res://assets/recordings/mama2.mp3")
	},
	{
		"speaker": "mom",
		"animation": "huh",
		"text": "[color=#ffffff]I found this drawing book in the attic![/color]",
		"audio": preload("res://assets/recordings/mama3.mp3")
	},
	{
		"speaker": "ruby",
		 "animation": "wow",
		"text": "[color=#ffa7ea][wave amp=50.0 freq=10.0]WOAH[/wave], I'm gonna draw right now!![/color]",
		"audio": preload("res://assets/recordings/mama4.mp3")
	},
	{
		"speaker": "ruby",
		"animation": "default",
		"text": "[color=#ffa7ea]Thanks, mama![/color]",
		"audio": preload("res://assets/recordings/mama5.mp3")
	}
]
var current_line = 0
var typing = false

@onready var animation_player = $"../AnimationPlayer"

var waiting_for_animation = false

func start_dialogue():
	current_line = 0
	show_dialogue()
	print("starting")
	
	
func show_dialogue():

	typing = true
	dialogue_finished_typing = false

	mom_text.visible = false
	ruby_text.visible = false

	var current_dialogue = dialogue[current_line]

	if current_dialogue.has("animation"):
		ruby_sprite.play(current_dialogue["animation"])

	if current_line == 1:
		play_book_animation()

	if current_dialogue["speaker"] == "mom":
		active_text = mom_text
	elif current_dialogue["speaker"] == "ruby":
		active_text = ruby_text

	active_text.visible = true
	active_text.text = current_dialogue["text"]
	active_text.visible_characters = 0

	# play audio
	if current_dialogue.has("audio"):
		voice_player.stream = current_dialogue["audio"]
		voice_player.play()

	# calc type speed
	var character_count = active_text.get_total_character_count()
	var audio_duration = voice_player.stream.get_length()

	var typing_speed = 0.05

	if character_count > 0 and audio_duration > 0:
		typing_speed = (audio_duration / character_count) * 0.7

	for i in range(character_count):

		if not typing:
			break

		active_text.visible_characters += 1

		await get_tree().create_timer(typing_speed).timeout

	typing = false
	dialogue_finished_typing = true

	# Wait for audio to finish
	if voice_player.playing:
		await voice_player.finished

	dialogue_finished_typing = true

func _input(event):
	if event.is_action_pressed("ui_accept"):

		if waiting_for_animation:
			return

		if typing:
			active_text.visible_characters = -1
			typing = false

		else:
			voice_player.stop()

			current_line += 1

			if current_line < dialogue.size():
				show_dialogue()
			else:
				dialogue_finished.emit()

func play_book_animation():

	waiting_for_animation = true

	animation_player.play("book slide")

	await animation_player.animation_finished

	waiting_for_animation = false
