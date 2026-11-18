
extends Control

@onready var dialogue_text = $RichTextLabel

var dialogue = [
	"yes mama? ",
	"I found this drawing book in the attic”",
	"WOAH, I’m gonna draw right now!!",
	"Thanks, mom!"
]

var current_line = 0
var typing = false

func _ready():
	show_dialogue()

func show_dialogue():
	typing = true
	dialogue_text.text = dialogue[current_line]
	dialogue_text.visible_characters = 0

	for i in range(dialogue[current_line].length()):
		dialogue_text.visible_characters += 1
		await get_tree().create_timer(0.05).timeout

	typing = false

func _input(event):
	if event.is_action_pressed("ui_accept"):

		if typing:
			dialogue_text.visible_characters = -1
			typing = false
		else:
			current_line += 1

		if current_line < dialogue.size():
			show_dialogue()
		else:
			print("Dialogue finished!")
