extends Node2D

@onready var book = $connectTheDots
@onready var puzzle = $connectTheDots/Puzzle
@onready var back_button = $connectTheDots/BackButton
@onready var dialogue_box = $Node2D
@onready var mom_text = $Node2D/Control/mama
@onready var ruby_text = $Node2D/Control/ruby
@onready var ruby_sprite = get_node_or_null("Node2D/AnimatedSprite2D")
@onready var scene_animations = get_node_or_null("Node2D/AnimationPlayer")

const PASS_MATCH := 0.8

var dialogues: Dictionary = {
	"intro": [
		{
			"speaker": "ruby",
			"text": "[color=#ffa7ea]Placeholder line 1 (ruby)[/color]"
		},
		{
			"speaker": "mom",
			"text": "[color=#ffffff]Placeholder line 2 (mom)[/color]"
		},
		{
			"speaker": "ruby",
			"text": "[color=#ffa7ea]Placeholder line 3 (ruby)[/color]"
		},
	],
}

var story: Array[Dictionary] = [
	{"type": "dialogue", "id": "intro"},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/bird_shape.tscn"),
		"reveal": "TODO_bird",
		"can_leave": false,
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/candle_shape.tscn"),
		"reveal": "TODO_candle",
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/crown_shape.tscn"),
		"reveal": "TODO_crown",
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/eyeball_shape.tscn"),
		"reveal": "TODO_eyeball",
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/flower_shape.tscn"),
		"reveal": "TODO_flower",
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/friend_shape.tscn"),
		"reveal": "TODO_friend",
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/hand_shape.tscn"),
		"reveal": "TODO_hand",
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/icecream_shape.tscn"),
		"reveal": "TODO_icecream",
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/key_shape.tscn"),
		"reveal": "TODO_key",
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/pentagram_shape.tscn"),
		"reveal": "TODO_pentagram",
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/scissors_shape.tscn"),
		"reveal": "TODO_scissors",
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/shapeship_shape.tscn"),
		"reveal": "TODO_shapeship",
	},
	{
		"type": "puzzle",
		"shape": preload("res://scenes/dots/square_shape.tscn"),
		"reveal": "TODO_square",
	},
]

var step = 0
var mama = false
var busy = false
var in_book_view = false
var puzzle_in_progress = false

var dialogue_active = false
var lines: Array = []
var current_line = 0
var typing = false
var typing_id = 0
var waiting_for_animation = false
var active_text: RichTextLabel


func _ready() -> void:
	puzzle.puzzle_completed.connect(_on_puzzle_completed)
	back_button.pressed.connect(_on_back_pressed)

	if ruby_sprite == null:
		ruby_sprite = $AnimatedSprite2D
	if scene_animations == null:
		scene_animations = $AnimationPlayer

	mom_text.get_parent().set_process_input(false)
	dialogue_box.visible = false
	book.visible = false


func _on_girlpressed(viewport: Node, event: InputEvent, shape_idx: int) -> void:

	if dialogue_active or busy or in_book_view:
		return

	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			if !mama:
				busy = true

				$AnimatedSprite2D.play("touch")
				#keyhole anim here possibly
				await get_tree().create_timer(1.0).timeout

				$mom.visible=false
				busy = false
				_run_step()
			#ruby has book atp
			elif puzzle_in_progress:
				busy = true
				$AnimatedSprite2D.play("touchbook")
				await get_tree().create_timer(1.0).timeout
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
	if not dialogues.has(id):
		push_error("No dialogue named: " + id)
		step += 1
		_run_step()
		return
	lines = dialogues[id]
	current_line = 0
	dialogue_active = true
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
	if line.has("play"):
		_play_scene_animation(line["play"])

	if line["speaker"] == "mom":
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
	dialogue_box.visible = false
	dialogue_active = false
	mama = true
	$AnimatedSprite2D.play("rubybook")
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


func _close_book() -> void:
	in_book_view = false
	book.visible = false
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
