extends Node2D

@onready var master_slider: HSlider = $HSlider
@onready var dialogue_slider: HSlider = $HSlider2
@onready var music_slider: HSlider = $HSlider3

func _ready() -> void:
	_setup_slider(master_slider, "Master")
	_setup_slider(dialogue_slider, "Dialogue")
	_setup_slider(music_slider, "Music")

func _setup_slider(slider: HSlider, bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(idx))
	slider.value_changed.connect(_on_slider_changed.bind(bus_name))

func _on_slider_changed(value: float, bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	AudioServer.set_bus_mute(idx, value <= 0.0)


func _on_back_button_pressed() -> void:
	$".".visible=false
