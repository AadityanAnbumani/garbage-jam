extends Node2D

@onready var dialogue_controller = $Node2D/Control
@onready var book = $connectTheDots
@onready var puzzle = $connectTheDots/Puzzle

@onready var ruby_sprite = get_node_or_null("Node2D/AnimatedSprite2D")
@onready var scene_animations = get_node_or_null("Node2D/AnimationPlayer")
@onready var book_ruby_text: RichTextLabel = $"ruby text"
const PASS_MATCH := 0.8
const MAX_STRAY := 0.35
@onready var dialogue_box = $Node2D

@onready var mom_text = $Node2D/Control/mama
@onready var ruby_text = $Node2D/Control/ruby

@onready var book_animations = $connectTheDots/AnimationPlayer


@onready var speechbubble = $SpeechBubble
@onready var ruby_room_text: RichTextLabel = $"ruby room text"


@onready var friend_sprite: AnimatedSprite2D = $connectTheDots/imgs/friend
@onready var friend_text = $"friend text"

var room_dialogue_finished := false
var room_dialogue_active := false

@onready var voice_player = $VoicePlayer

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

var final_dialogue_available := false
var final_dialogue_played := false 	

@onready var friend_room_sprite: AnimatedSprite2D = $friend

@onready var back_button = $connectTheDots/BackButton
@onready var help_button = $connectTheDots/help
@onready var undo_button = $connectTheDots/undo
@onready var clear_button = $connectTheDots/clear
@onready var sticky_note = $connectTheDots/StickyNote

func _set_puzzle_ui(visible: bool) -> void:
	back_button.visible = visible
	help_button.visible = visible
	undo_button.visible = visible
	clear_button.visible = visible
	sticky_note.visible = visible
	

var dialogues: Dictionary = {
"book_intro": [
	{
		"speaker": "ruby",
		"text": "[color=#ffa7ea]Your pencil can create anything the world can hold, but never what breathes.[/color]",
		"audio": preload("res://assets/recordings/bookintro1.mp3"),
	},
	{
		"speaker": "ruby",
		"play": "bookZoom",
		"text": "[color=#ffa7ea]I wonder what that means?[/color]",
		"audio": preload("res://assets/recordings/bookintro2.mp3"),
	},
],
"book_intro2": [
	{
		"speaker": "ruby",
		"text": "[color=#ffa7ea]I love connect the dots![/color]",
		"audio": preload("res://assets/recordings/bookintro3.mp3"),
	},
	{
		"speaker": "ruby",
		"text": "[color=#ffa7ea]Let me connect all the dots from 0 to the largest number and back to 0 again![/color]",
		"audio": preload("res://assets/recordings/bookintro4.mp3"),
	}
],

"ruby_square": [
	{
		"speaker": "ruby",
		"text": "[color=#ffa7ea]Did the square I just drew come into my room?![/color]",
		"audio": preload("res://assets/recordings/square1.mp3"),
	},
	{
		"speaker": "ruby",
		"text": "[color=#ffa7ea]hehe let's keep drawing![/color]",
		"audio": preload("res://assets/recordings/square2.mp3"),
	},
],

"bird":[
	{
		"speaker": "ruby",
		"text": "[color=#ffa7ea]Aw,mr. birdie isn't here[/color]",
		"audio": preload("res://assets/recordings/bird.mp3"),
	},
],

"friend drawn":[
	{
		"speaker": "friend",
		"animation": "dance",
		"text": "[color=#4F366F]I can’t believe it, I’m awake.. After all these years.[/color]",
		#"audio": preload("res://assets/recordings/bird.mp3"),  change to your rec
	},
	{
		"speaker": "ruby",
		"text": "[color=#ffa7ea]Hello! You’re gonna be my new friend![/color]",
		"audio": preload("res://assets/recordings/frienddrawn2.mp3"),
	},
	{
		"speaker": "friend",
		"animation": "sad",
		"text": "[color=#4F366F]Ack, who are you.[/color]",
		#"audio": preload("res://assets/recordings/bird.mp3"),change to your rec
	},
	{
		"speaker": "ruby",
		"text": "[color=#ffa7ea]My name's Ruby![/color]",
		"audio": preload("res://assets/recordings/frienddrawn4.mp3"),
	},
	{
		"speaker": "friend",
		"animation": "yay",
		"text": "[color=#4F366F]We can be friends… if you draw me a key![/color]",
		#"audio": preload("res://assets/recordings/bird.mp3"),  change to your rec
	},
],

"eyeball":[
	{
		"speaker": "friend",
		"animation": "default",
		"text": "[color=#4F366F]wouldn’t it be nice to have an extra eyeball.[/color]",
		#"audio": preload("res://assets/recordings/bird.mp3"),  change to your rec
	},
],

"pentagram":[
	{
		"speaker": "friend",
		"animation": "yay",
		"text": "[color=#4F366F]I wish I could play with you in the real world.[/color]",
		#"audio": preload("res://assets/recordings/bird.mp3"),  change to your rec
	},
],

"dots done":[
	{
		"speaker": "friend",
		"animation": "yay",
		"text": "[color=#4F366F]I had so much fun drawing with you![/color]",
		#"audio": preload("res://assets/recordings/bird.mp3"),  change to your rec
	},
	{
		"speaker": "ruby",
		"text": "[color=#ffa7ea]Me too![/color]",
		"audio": preload("res://assets/recordings/dotsdone2.mp3")
		
		
	},
	{
		"speaker": "friend",
		"animation": "smile",
		"text": "[color=#4F366F]it’s time for a real playdate.[/color]",
		#"audio": preload("res://assets/recordings/bird.mp3"),  change to your rec
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
	"reveal": "Bird",
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
	"reveal": "friend",
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
	"room_reveals": ["Candle", "Candle2", "Candle3","Candle4", "Candle5", "Candle6"]
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/eyeball_shape.tscn"),
	"reveal": "Eyeball",
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
	"reveal": "Hand",
},
]

var current_puzzle_data: Dictionary = {}


var step = 0
var mama = false
var busy = false
var in_book_view = false
var puzzle_in_progress = false


func _ready() -> void:
	help_button.pressed.connect(_on_help_pressed)
	_set_puzzle_ui(false)
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
				
				elif final_dialogue_available and not final_dialogue_played:
					final_dialogue_played = true
					await _play_final_book_dialogue()

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
		print("all dots doneeenenne")
		final_dialogue_available = true
		return

	current_puzzle_data = puzzles[puzzle_index]

	print("CURRENT PUZZLE: ", current_puzzle_data)

	
	book.visible = true
	in_book_view = true

	_begin_puzzle(current_puzzle_data)
func _start_dialogue(id: String) -> void:
	room_dialogue_active = false

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
	friend_text.visible = false

	var line: Dictionary = lines[current_line]

	if in_book_view:
		if line["speaker"] == "friend":
			active_text = friend_text
		else:
			active_text = book_ruby_text
	elif line["speaker"] == "mom":
		active_text = mom_text
	else:
		active_text = ruby_text

	# Play the correct character animation
	if line.has("animation"):
		if line["speaker"] == "friend":
			_play_friend(line["animation"])
		elif line["speaker"] == "ruby":
			_play_ruby(line["animation"])

	active_text.visible = true
	active_text.text = line["text"]
	active_text.visible_characters = 0
	var audio_duration = _play_dialogue_voice(line)
	var character_count = active_text.get_total_character_count()

	var typing_speed = 0.05

	if character_count > 0 and audio_duration > 0:
		typing_speed = (audio_duration / character_count) * 0.7

	for i in range(active_text.get_total_character_count()):
		if my_id != typing_id:
			return

		if typing:
			active_text.visible_characters += 1
			await get_tree().create_timer(typing_speed).timeout

	if my_id != typing_id:
		return

	typing = false

	if line.has("play") and current_dialogue_id == "book_intro":
		waiting_for_animation = true
		book_animations.play(line["play"])

		await book_animations.animation_finished

		waiting_for_animation = false

		if current_dialogue_id == "book_intro":
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

		voice_player.stop()

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
	if current_dialogue_id in ["friend drawn", "eyeball", "pentagram"]:

		friend_text.hide()
		friend_sprite.hide()
		friend_room_sprite.hide()
		book_ruby_text.hide()

		# Hide the completed puzzle's book image
		var reveal_name: String = current_puzzle_data.get("reveal", "")
		var imgs = book.get_node_or_null("imgs")

		if imgs:
			var completed_image = imgs.get_node_or_null(reveal_name)
			if completed_image:
				completed_image.hide()

		# Close book AFTER dialogue finishes
		book.hide()
		in_book_view = false

		$AnimatedSprite2D.play("rubybook")

		dialogue_transitioning = false

		await get_tree().create_timer(1.0).timeout

		busy = false
		_run_puzzle()
		return
	if current_dialogue_id == "dots done":

		friend_text.visible = false
		book_ruby_text.visible = false

		friend_sprite.visible = false

		book.visible = false
		in_book_view = false

		$AnimatedSprite2D.play("rubybook")

		final_dialogue_available = false

		print("FINAL BOOK DIALOGUE COMPLETED!")

		busy = false
		
		$AnimationPlayer.play("friend escape")
		await $AnimationPlayer.animation_finished
		get_tree().change_scene_to_file("res://scenes/obby.tscn")
		return
		
	dialogue_box.visible = false
	step += 1

	dialogue_transitioning = false

	await get_tree().create_timer(1.0).timeout
	_run_step()

var help := false

func _on_help_pressed() -> void:
	help = !help
	$connectTheDots/help2.visible = help

func _play_dialogue_voice(line: Dictionary) -> float:

	voice_player.stop()

	if line.has("audio"):
		voice_player.stream = line["audio"]
		voice_player.play()

		return voice_player.stream.get_length()

	return 0.0
	
func _play_friend(anim_name: String) -> void:
	if friend_sprite.sprite_frames == null:
		return

	if not friend_sprite.sprite_frames.has_animation(anim_name):
		push_error("Friend animation not found: " + anim_name)
		return

	friend_sprite.play(anim_name)
	
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

	puzzle.visible = true
	puzzle.start_puzzle(data["shape"])

	puzzle_in_progress = true

	_set_puzzle_ui(true)
	
func _open_book() -> void:
	in_book_view = true
	book.visible = true

	if puzzle_in_progress:
		puzzle.visible = true
		undo_button.show()
		clear_button.show()
		back_button.show()
		help_button.show()
		sticky_note.show()
	
func _close_book() -> void:
	in_book_view = false
	book.visible = false
	book_ruby_text.visible = false

	help = false
	$connectTheDots/help2.visible = false

	_set_puzzle_ui(false)
	$AnimatedSprite2D.play("rubybook")
	
func _on_back_pressed() -> void:
	_close_book()

func _on_puzzle_completed() -> void:
	if busy:
		return

	busy = true
	puzzle_in_progress = false

	print("Yay! Puzzle completed!")

	var reveal_name: String = current_puzzle_data.get("reveal", "")
	var book_image: Node = null

	# 1. Hide puzzle and dots + ui
	help = false
	$connectTheDots/help2.visible = false
	puzzle.end_puzzle()
	puzzle.visible = false
	_set_puzzle_ui(false)

	# 2. Reveal the picture in the book
	if not reveal_name.is_empty():
		var imgs = book.get_node_or_null("imgs")
		if imgs:
			book_image = imgs.get_node_or_null(reveal_name)

			if book_image:
				book_image.show()
				print("BOOK IMAGE REVEALED: ", book_image.get_path())
		else:
			push_warning("imgs folder not found!")

	
	# Give the player time to see the picture
	await get_tree().create_timer(1.5).timeout

	# FRIEND SPECIAL EVENT
	if reveal_name == "friend":

		# Keep the book open!
		# Keep the friend visible inside the book!

		puzzle_index += 1
		busy = false

		_start_dialogue("friend drawn")
		return

	# EYEBALL SPECIAL EVENT
	if reveal_name == "Eyeball":
		puzzle_index += 1
		busy = false

		# Keep book and eyeball visible during dialogue
		book.show()
		in_book_view = true
		book_image.show()

		_start_friend_dialogue("eyeball", true)
		return


	# PENTAGRAM SPECIAL EVENT
	if reveal_name == "Pentagram":
		puzzle_index += 1
		busy = false

		var room_node = get_node_or_null("Pentagram")
		if room_node:
			room_node.show()
		else:
			push_warning("Pentagram room node not found!")

		book.show()
		in_book_view = true
		book_image.show()

		_start_friend_dialogue("pentagram", true)
		return
	# NORMAL PUZZLE COMPLETION
	if book_image:
		book_image.hide()

	book.visible = false
	in_book_view = false

	$AnimatedSprite2D.play("rubybook")

	# 4. Reveal room object if it exists
	if current_puzzle_data.has("room_reveals"):
		for path in current_puzzle_data["room_reveals"]:
			var room_node = get_node_or_null(path)
			if room_node:
				room_node.show()
	else:
		# single objs
		var room_node = get_node_or_null(reveal_name)
		if room_node:
			room_node.show()

	puzzle_index += 1

	if puzzle_index == 1:
		await get_tree().create_timer(0.5).timeout
		busy = false
		_start_room_dialogue("ruby_square")
		return
		
	# birb puzzle
	if puzzle_index == 3:
		await get_tree().create_timer(0.5).timeout
		busy = false
		_start_room_dialogue("bird")
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
	room_dialogue_finished = false
	typing = false

	ruby_room_text.hide()
	speechbubble.hide()

	# Hide room friend
	friend_room_sprite.hide()

	print("Room dialogue finished!")

	await get_tree().create_timer(1.0).timeout

	busy = false
	_run_puzzle()
	
func _show_room_line() -> void:
	typing = true
	typing_id += 1
	var my_id = typing_id

	active_text = ruby_room_text

	var line: Dictionary = lines[current_line]

	active_text.text = line["text"]
	active_text.visible_characters = 0
	
	var audio_duration = _play_dialogue_voice(line)
	var character_count = active_text.get_total_character_count()

	var typing_speed = 0.05

	if character_count > 0 and audio_duration > 0:
		typing_speed = (audio_duration / character_count) * 0.7

	for i in range(active_text.get_total_character_count()):
		if my_id != typing_id:
			return

		if typing:
			active_text.visible_characters += 1
			await get_tree().create_timer(typing_speed).timeout

	if my_id != typing_id:
		return

	typing = false

func _play_final_book_dialogue() -> void:
	busy = true
	in_book_view = true

	# Show book
	book.visible = true

	# No puzzle or dots
	puzzle.end_puzzle()
	puzzle.visible = false

	# Hide all previously used dialogue
	book_ruby_text.visible = false
	ruby_text.visible = false
	friend_text.visible = false

	# Show friend inside the book
	friend_sprite.visible = true
	friend_room_sprite.visible = false

	# Start final conversation
	_start_dialogue("dots done")

	busy = false
	

func _start_pentagram_event() -> void:
	book.hide()
	in_book_view = false
	puzzle.hide()

	book_ruby_text.hide()
	friend_text.hide()

	friend_sprite.hide()
	friend_room_sprite.show()
	friend_room_sprite.play("default")

	_start_room_dialogue("pentagram")

func _start_eyeball_event() -> void:
	# Hide book and all book dialogue
	book.hide()
	in_book_view = false
	puzzle.hide()

	book_ruby_text.hide()
	friend_text.hide()

	# Show main-scene friend
	friend_sprite.hide()
	friend_room_sprite.show()
	friend_room_sprite.play("default")

	# Start room dialogue
	_start_room_dialogue("eyeball")
	
	
func _start_friend_dialogue(id: String, use_room_sprite: bool = false) -> void:
	if not dialogues.has(id):
		push_error("No dialogue named: " + id)
		return

	friend_sprite.hide()
	friend_room_sprite.hide()

	if use_room_sprite:
		friend_room_sprite.show()
		friend_room_sprite.play("default")
	else:
		friend_sprite.show()

	_start_dialogue(id)
	
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
