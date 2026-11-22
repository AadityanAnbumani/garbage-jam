extends Node

const TRACKS := {
	"track1": preload("res://assets/music/b4 frien.mp3"),
	"track2": preload("res://assets/music/after friend.mp3"),
	"track3": preload("res://assets/music/obby music.mp3"),
}

var players := {}
var started := {}
var current := ""

func _ready() -> void:
	for key in TRACKS:
		var p := AudioStreamPlayer.new()
		p.stream = TRACKS[key]
		p.bus = "Music"
		add_child(p)
		players[key] = p
		started[key] = false

func play_track(key: String) -> void:
	if key == current:
		return
	pause_current()
	current = key
	var p: AudioStreamPlayer = players[key]
	if started[key]:
		p.stream_paused = false   # resume where it left off
	else:
		p.play()
		started[key] = true

func pause_current() -> void:
	if current != "":
		players[current].stream_paused = true

func resume_current() -> void:
	if current != "":
		players[current].stream_paused = false

func set_volume(value: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	AudioServer.set_bus_mute(idx, value <= 0.0)

func get_volume() -> float:
	var idx := AudioServer.get_bus_index("Music")
	return db_to_linear(AudioServer.get_bus_volume_db(idx))
