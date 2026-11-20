extends Node2D

@onready var dialogue_controller = $Node2D/Control
@onready var book = $connectTheDots
@onready var puzzle = $connectTheDots/Puzzle
@onready var back_button = $connectTheDots/BackButton
@onready var ruby_sprite = get_node_or_null("Node2D/AnimatedSprite2D")
@onready var scene_animations = get_node_or_null("Node2D/AnimationPlayer")
@onready var book_ruby_text: RichTextLabel = $"ruby text"
const PASS_MATCH := 0.8

@onready var dialogue_box = $Node2D

@onready var mom_text = $Node2D/Control/mama
@onready var ruby_text = $Node2D/Control/ruby

var dialogue_active = false
var lines: Array = []
var current_line = 0
var typing = false
var typing_id = 0
var waiting_for_animation = false
var active_text: RichTextLabel

var book_opened_once = false
var first_book_open = true

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
		"text": "[color=#ffa7ea]I [emphasis]love connect the dots![/color]"
	},
	{
		"speaker": "ruby",
		#"animation": "default",
		"text": "[color=#ffa7ea]Let me connect all the dots from 0 to the largest number and back to 0 again![/color]"
	}
],
}


var story: Array[Dictionary] = [
	{"type": "dialogue", "id": "intro"},
	{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/square_shape.tscn"),
	"reveal": "TODO_square",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/flower_shape.tscn"),
	"reveal": "TODO_flower",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/bird_shape.tscn"),
	"reveal": "TODO_bird",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/crown_shape.tscn"),
	"reveal": "TODO_crown",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/icecream_shape.tscn"),
	"reveal": "TODO_icecream",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/shapeship_shape.tscn"),
	"reveal": "TODO_shapeship",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/friend_shape.tscn"),
	"reveal": "TODO_friend",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/key_shape.tscn"),
	"reveal": "TODO_key",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/candle_shape.tscn"),
	"reveal": "TODO_candle",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/eyeball_shape.tscn"),
	"reveal": "TODO_eyeball",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/scissors_shape.tscn"),
	"reveal": "TODO_scissors",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/pentagram_shape.tscn"),
	"reveal": "TODO_pentagram",
},
{
	"type": "puzzle",
	"shape": preload("res://scenes/dots/hand_shape.tscn"),
	"reveal": "TODO_hand",
},
]

var step = 0
var mama = false
var busy = false
var in_book_view = false
var puzzle_in_progress = false


func _ready() -> void:
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

				$AnimatedSprite2D.play("touch")
				#keyhole anim here possibly
				await get_tree().create_timer(1.0).timeout

				$Node2D.visible=true
				$mom.visible=false
				busy = false
				_run_step()
			#ruby has book atp
			else:
				busy = true

				$AnimatedSprite2D.play("touchbook")
				await get_tree().create_timer(1.0).timeout

				if first_book_open:
					first_book_open = false
					await _play_first_book_intro()

				elif puzzle_in_progress:
					_open_book()

				busy = false


func _run_step() -> void:
	if step >= story.size():
		return
	var data: Dictionary = story[step]
	if data["type"] == "dialogue":
		_start_dialogue(data["id"])
	else:
		_begin_puzzle(data)


func _start_dialogue(id: String) -> void:

	if id == "intro":
		dialogue_controller.visible = true
		dialogue_controller.start_dialogue()
		return

	if not dialogues.has(id):
		push_error("No dialogue named: " + id)
		return

	lines = dialogues[id]
	current_line = 0
	dialogue_active = true

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
		if not typing or my_id != typing_id:
			return

		active_text.visible_characters += 1
		await get_tree().create_timer(0.05).timeout

	if my_id == typing_id:
		typing = false

	if line.has("play"):
		waiting_for_animation = true

		var book_sprite = $connectTheDots/AnimationPlayer

		if book_sprite.sprite_frames.has_animation(line["play"]):
			book_sprite.play(line["play"])
			await book_sprite.animation_finished
		else:
			push_error("Book animation not found: " + line["play"])

		waiting_for_animation = false

func _input(event: InputEvent) -> void:
	if not dialogue_active:
		return

	if event.is_action_pressed("ui_accept"):
		if waiting_for_animation:
			return

		if typing:
			active_text.visible_characters = -1
			typing = false
		else:
			current_line += 1

			if current_line < lines.size():
				_show_line()
			else:
				_end_dialogue()

func _end_dialogue() -> void:

	dialogue_active = false
	typing = false

	if in_book_view:
		if lines == dialogues["book_intro"]:
			_start_dialogue("book_intro2")
			return

		book_ruby_text.visible = false
		return

	dialogue_box.visible = false

	step += 1

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
	puzzle.allowed_stray = 1.0 - PASS_MATCH
	puzzle.tolerance = data.get("tolerance", 20.0)
	puzzle.closed = data.get("closed", false)
	back_button.visible = data.get("can_leave", true)
	puzzle.start_puzzle(data["shape"])
	puzzle_in_progress = true
	_open_book()


func _open_book() -> void:
	in_book_view = true
	book.visible = true

	var book_anim = $connectTheDots/AnimationPlayer

	book_anim.play("bookOpen")
	await book_anim.animation_finished

	_start_dialogue("book_intro")

func _close_book() -> void:
	in_book_view = false
	book.visible = false
	book_ruby_text.visible = false
	$AnimatedSprite2D.play("rubybook")

func _on_back_pressed() -> void:
	_close_book()


func _on_puzzle_completed() -> void:
	puzzle_in_progress = false
	busy = true
	await get_tree().create_timer(1.0).timeout
	puzzle.end_puzzle()
	_close_book()
	await get_tree().create_timer(0.5).timeout
	_reveal(story[step]["reveal"])
	step += 1
	await get_tree().create_timer(1.0).timeout
	busy = false
	_run_step()


func _reveal(path: String) -> void:
	var node = get_node_or_null(path)
	if node == null:
		push_error("Reveal node not found: " + path)
		return
	node.visible = true

func _on_mama_dialogue_finished() -> void:
	dialogue_controller.visible = false
	$Node2D.visible = false

	mama = true
	$AnimatedSprite2D.play("rubybook")

	step += 1

func _play_first_book_intro() -> void:
	in_book_view = true
	book.visible = true

	var book_anim = $connectTheDots/AnimationPlayer
	book_anim.play("bookOpen")
	await book_anim.animation_finished

	_start_dialogue("book_intro")
