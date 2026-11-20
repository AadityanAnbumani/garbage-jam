extends Node2D

@onready var dialogue_controller = $Node2D/Control
@onready var book = $connectTheDots
@onready var puzzle = $connectTheDots/Puzzle
@onready var back_button = $connectTheDots/BackButton
@onready var ruby_sprite = get_node_or_null("Node2D/AnimatedSprite2D")
@onready var scene_animations = get_node_or_null("Node2D/AnimationPlayer")
@onready var book_ruby_text: RichTextLabel = $"ruby text"
const PASS_MATCH := 0.8
const MAX_STRAY := 0.30
@onready var dialogue_box = $Node2D

@onready var mom_text = $Node2D/Control/mama
@onready var ruby_text = $Node2D/Control/ruby

@onready var book_animations = $connectTheDots/AnimationPlayer


@onready var speechbubble = $SpeechBubble
@onready var ruby_room_text: RichTextLabel = $"ruby room text"

var room_dialogue_finished := false
var room_dialogue_active := false

var dialogue_active = false
var lines: Array = []
var current_line = 0
var typing = false
var typing_id = 0
var waiting_for_animation = false
var active_text: RichTextLabel

var book_opened_once = false
var first_book_open = true
var current_dialogue_id = ""

var puzzle_index := 0
var dialogue_transitioning := false
var book_intro_finished := false

var puzzle_unlocked := false	

var dialogues: Dictionary = {
"book_intro": [
	{
		"speaker": "ruby",
		#"animation": "default",
		"play": "bookZoom",
		"text": "[color=#ffa7ea]I wonder what that means?[/color]"
	},
],
"book_intro2": [
	{
		"speaker": "ruby",
		#"animation": "wow",
		"text": "[color=#ffa7ea]I love connect the dots![/color]"
	},
	{
		"speaker": "ruby",
		#"animation": "default",
		"text": "[color=#ffa7ea]Let me connect all the dots from 0 to the largest number and back to 0 again![/color]"
	}
],

"ruby_square": [
	{
		"speaker": "ruby",
		#"animation": "wow",
		"text": "[color=#ffa7ea]Did the square I just drew come into my room?![/color]"
	},
	{
		"speaker": "ruby",
		#"animation": "default",
		"text": "[color=#ffa7ea]hehe let's keep drawing![/color]"
	},
],

"bird":[
	{
		"speaker": "ruby",
		#"animation": "wow",
		"text": "[color=#ffa7ea]Aw,mr. birdie isn't here[/color]"
	},
],

"friend drawn":[
	{
		"speaker": "friend",
		"animation": "default",
		"text": "[color=#4F366F]I can’t believe it, I’m awake.. After all these years.[/color]"
	},
	{
		"speaker": "ruby",
		#"animation": "wow",
		"text": "[color=#ffa7ea]Hello! You’re gonna be my new friend![/color]"
	},
	{
		"speaker": "friend",
		"animation": "sad",
		"text": "[color=#4F366F]Ack, who are you.[/color]"
	},
	{
		"speaker": "ruby",
		#"animation": "wow",
		"text": "[color=#ffa7ea]My name's Ruby![/color]"
	},
	{
		"speaker": "friend",
		"animation": "sad",
		"text": "[color=#4F366F]We can be friends… if you draw me a key![/color]"
	},
],

"eyeball":[
	{
		"speaker": "friend",
		#"animation": "wow",
		"text": "[color=#4F366F]wouldn’t it be nice to have an extra eyeball.[/color]"
	},
],

"pentagram":[
	{
		"speaker": "friend",
		#"animation": "wow",
		"text": "[color=#4F366F]I wish I could play with you in the real world.[/color]"
	},
],

"dots done":[
	{
		"speaker": "friend",
		#"animation": "wow",
		"text": "[color=#4F366F]I had so much fun drawing with you![/color]"
	},
	{
		"speaker": "ruby",
		#"animation": "wow",
		"text": "[color=#ffa7ea]Me too![/color]"
	},
	{
		"speaker": "friend",
		#"animation": "wow",
		"text": "[color=#4F366F]it’s time for a real playdate.[/color]"
	},
],

}


var story: Array[Dictionary] = [
	{"type": "dialogue", "id": "intro"},
	{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/square_shape.tscn"),
	"reveal": "RedSquare",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/flower_shape.tscn"),
	"reveal": "Flower",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/bird_shape.tscn"),
	"reveal": "TODO_bird",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/crown_shape.tscn"),
	"reveal": "Crown",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/icecream_shape.tscn"),
	"reveal": "Icecream",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/shapeship_shape.tscn"),
	"reveal": "Spaceship",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/friend_shape.tscn"),
	"reveal": "TODO_friend",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/key_shape.tscn"),
	"reveal": "Key",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/candle_shape.tscn"),
	"reveal": "Candle",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/eyeball_shape.tscn"),
	"reveal": "TODO_eyeball",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/scissors_shape.tscn"),
	"reveal": "Scissors",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/pentagram_shape.tscn"),
	"reveal": "Pentagram",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/hand_shape.tscn"),
	"reveal": "TODO_hand",
},
]

var current_puzzle_data: Dictionary = {}


var step = 0
var mama = false
var busy = false
var in_book_view = false
var puzzle_in_progress = false


func _ready() -> void:
	speechbubble.visible = false
	ruby_room_text.visible = false

	puzzle.visible = false
	puzzle.end_puzzle()

	puzzle.puzzle_completed.connect(_on_puzzle_completed)
	back_button.pressed.connect(_on_back_pressed)

	dialogue_controller.dialogue_finished.connect(_on_mama_dialogue_finished)

	if ruby_sprite == null:
		ruby_sprite = $AnimatedSprite2D
	if scene_animations == null:
		scene_animations = $AnimationPlayer

	dialogue_controller.visible = false
	book.visible = false

func _on_girlpressed(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if busy or in_book_view:
		return

	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:

			if !mama:
				busy = true

				$AnimationPlayer2.stop()
				$AnimationPlayer2/Arrow.visible = false
				$AnimatedSprite2D.play("touch")

				await get_tree().create_timer(1.0).timeout

				$Node2D.visible = true
				$mom.visible = false
				busy = false
				_run_step()
			#ruby has book atp
			else:
				if busy or dialogue_active:
					return

				busy = true
				$AnimatedSprite2D.play("touchbook")

				await get_tree().create_timer(1.0).timeout

				if room_dialogue_finished:
					room_dialogue_finished = false
					_run_puzzle()

				elif not book_intro_finished:
					if first_book_open:
						first_book_open = false
						await _play_first_book_intro()

				elif puzzle_in_progress and not in_book_view:
					await _open_book()

				busy = false

func _run_step() -> void:
	if step >= story.size():
		return

	var data: Dictionary = story[step]

	if data["type"] == "dialogue":
		_start_dialogue(data["id"])
		
		
func _run_puzzle() -> void:
	var puzzles: Array = []

	for data in story:
		if data["type"] == "puzzle":
			puzzles.append(data)

	if puzzle_index >= puzzles.size():
		print("ALL PUZZLES COMPLETED!")
		return

	current_puzzle_data = puzzles[puzzle_index]

	print("CURRENT PUZZLE: ", current_puzzle_data)

	
	book.visible = true
	in_book_view = true

	_begin_puzzle(current_puzzle_data)
func _start_dialogue(id: String) -> void:

	if id == "intro":
		dialogue_controller.visible = true
		dialogue_controller.start_dialogue()
		return

	if not dialogues.has(id):
		push_error("No dialogue named: " + id)
		return

	lines = dialogues[id]
	current_dialogue_id = id
	current_line = 0
	dialogue_active = true
	typing = false
	waiting_for_animation = false

	if in_book_view:
		book_ruby_text.visible = true
		book_ruby_text.text = ""
	else:
		dialogue_box.visible = true

	_show_line()

func _show_line() -> void:
	typing = true
	typing_id += 1
	var my_id = typing_id

	mom_text.visible = false
	ruby_text.visible = false

	var line: Dictionary = lines[current_line]

	if line.has("animation"):
		_play_ruby(line["animation"])

	if in_book_view:
		active_text = book_ruby_text
	elif line["speaker"] == "mom":
		active_text = mom_text
	else:
		active_text = ruby_text

	active_text.visible = true
	active_text.text = line["text"]
	active_text.visible_characters = 0

	for i in range(active_text.get_total_character_count()):
		if my_id != typing_id:
			return

		if typing:
			active_text.visible_characters += 1
			await get_tree().create_timer(0.05).timeout

	if my_id != typing_id:
		return

	typing = false

	# Wait for book zoom animation
	if line.has("play") and current_dialogue_id == "book_intro":
		waiting_for_animation = true
		book_animations.play(line["play"])

		await book_animations.animation_finished

		waiting_for_animation = false

		if current_dialogue_id == "book_intro":
			# Display square dots, but don't allow drawing
			puzzle.start_puzzle(preload("res://scenes/dots/square_shape.tscn"))
			puzzle.visible = true
			puzzle.input_enabled = false
			puzzle_unlocked = false

			_start_dialogue("book_intro2")
func _input(event: InputEvent) -> void:
	if not dialogue_active or waiting_for_animation or dialogue_transitioning:
		return

	if event.is_action_pressed("ui_accept"):

		if typing:
			active_text.visible_characters = -1
			typing = false
			return

		current_line += 1

		if current_line < lines.size():
			if room_dialogue_active:
				_show_room_line()
			else:
				_show_line()
		else:
			if room_dialogue_active:
				_end_room_dialogue()
			else:
				_end_dialogue()

func _end_dialogue() -> void:
	if dialogue_transitioning:
		return

	dialogue_transitioning = true
	dialogue_active = false
	typing = false

	if in_book_view:
		book_ruby_text.visible = false

	if current_dialogue_id == "book_intro2":
		book_intro_finished = true
		puzzle_unlocked = true
		puzzle.input_enabled = true
		dialogue_transitioning = false
		_run_puzzle()
		return

		dialogue_transitioning = false
		return

	dialogue_box.visible = false
	step += 1

	dialogue_transitioning = false

	await get_tree().create_timer(1.0).timeout
	_run_step()
	
func _play_ruby(anim_name: String) -> void:
	if ruby_sprite.sprite_frames == null or not ruby_sprite.sprite_frames.has_animation(anim_name):
		push_error("Ruby animation not found: " + anim_name)
		return
	ruby_sprite.play(anim_name)


func _play_scene_animation(anim_name: String) -> void:
	if not scene_animations.has_animation(anim_name):
		push_error("Scene animation not found: " + anim_name)
		return
	waiting_for_animation = true
	scene_animations.play(anim_name)
	await scene_animations.animation_finished
	waiting_for_animation = false


func _begin_puzzle(data: Dictionary) -> void:
	puzzle.required_coverage = PASS_MATCH
	puzzle.allowed_stray = MAX_STRAY
	puzzle.tolerance = data.get("tolerance", 20.0)
	puzzle.closed = data.get("closed", false)
	back_button.visible = data.get("can_leave", true)

	puzzle.visible = true
	puzzle.start_puzzle(data["shape"])

	puzzle_in_progress = true
	
func _open_book() -> void:
	in_book_view = true
	book.visible = true
	
func _close_book() -> void:
	in_book_view = false
	book.visible = false
	book_ruby_text.visible = false
	$AnimatedSprite2D.play("rubybook")

func _on_back_pressed() -> void:
	_close_book()



func _on_puzzle_completed() -> void:
	if busy:
		return

	busy = true
	puzzle_in_progress = false

	print("Yay! Puzzle completed!")

	# Show completed picture in the book
	var completed_image: Node = null

	if current_puzzle_data.has("reveal"):
		var imgs = book.get_node("imgs")
		completed_image = imgs.get_node_or_null(
			current_puzzle_data["reveal"]
		)

		if completed_image:
			completed_image.visible = true

	# Let the player see the completed picture
	await get_tree().create_timer(1.5).timeout

	# Hide puzzle and dots
	puzzle.end_puzzle()
	puzzle.visible = false

	# Close book
	book.visible = false
	in_book_view = false

	$AnimatedSprite2D.play("rubybook")

	# Hide previous picture AFTER closing the book
	if completed_image:
		completed_image.visible = false

	# Reveal object in Ruby's room
	if current_puzzle_data.has("reveal"):
		var room_node = get_node_or_null(
			current_puzzle_data["reveal"]
		)
		if room_node:
			room_node.visible = true

	puzzle_index += 1

	if puzzle_index == 1:
		await get_tree().create_timer(0.5).timeout
		busy = false
		_start_room_dialogue("ruby_square")
		return

	await get_tree().create_timer(1.0).timeout
	busy = false
	_run_puzzle()

func _reveal(path: String) -> void:
	# Reveal room object
	var room_node = get_node_or_null(path)

	if room_node != null:
		room_node.visible = true
		print("ROOM IMAGE VISIBLE: ", room_node.get_path())
	else:
		print("ROOM IMAGE NOT FOUND: ", path)

	# Find book image
	var current_book_image = book.get_node_or_null("imgs/" + path)

	if current_book_image != null:
		current_book_image.visible = true
		print("BOOK IMAGE FOUND: ", current_book_image.get_path())
		print("BOOK IMAGE VISIBLE: ", current_book_image.visible)
		print("BOOK IMAGE POSITION: ", current_book_image.position)
	else:
		print("BOOK IMAGE NOT FOUND: ", "imgs/" + path)
func _on_mama_dialogue_finished() -> void:
	dialogue_controller.visible = false
	$Node2D.visible = false

	mama = true
	$AnimatedSprite2D.play("rubybook")

	step += 1

func _start_room_dialogue(id: String) -> void:
	if not dialogues.has(id):
		push_error("No dialogue named: " + id)
		return

	lines = dialogues[id]
	current_dialogue_id = id
	current_line = 0

	dialogue_active = true
	room_dialogue_active = true
	typing = false

	speechbubble.visible = true
	ruby_room_text.visible = true
	ruby_room_text.text = ""

	_show_room_line()
	
func _end_room_dialogue() -> void:
	dialogue_active = false
	room_dialogue_active = false
	room_dialogue_finished = true
	typing = false

	ruby_room_text.visible = false
	speechbubble.visible = false

	print("Room dialogue finished!")
func _show_room_line() -> void:
	typing = true
	typing_id += 1
	var my_id = typing_id

	active_text = ruby_room_text

	var line: Dictionary = lines[current_line]

	active_text.text = line["text"]
	active_text.visible_characters = 0

	for i in range(active_text.get_total_character_count()):
		if my_id != typing_id:
			return

		if typing:
			active_text.visible_characters += 1
			await get_tree().create_timer(0.05).timeout

	if my_id != typing_id:
		return

	typing = false

func _play_first_book_intro() -> void:
	in_book_view = true
	book.visible = true

	# Absolutely no dots during bookOpen
	puzzle.end_puzzle()
	puzzle.visible = false
	puzzle_unlocked = false

	var book_anim = $connectTheDots/AnimationPlayer
	book_anim.play("bookOpen")
	await book_anim.animation_finished

	_start_dialogue("book_intro")
