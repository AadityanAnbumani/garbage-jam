extends Node2D

signal puzzle_completed
signal puzzle_failed

@export var shape_scene: PackedScene
@export var autostart := false
@export var drawing_rect := Rect2(370, 35, 520, 630)
@export var fit_margin := 45.0
#@export var fit_margin := 30.0
@export var closed := false
@export var tolerance := 20.0
@export var required_coverage := 0.8
@export var allowed_stray := 0.45
@export var sample_spacing := 8.0
@export var line_width := 4.0
@export var line_color := Color(0.1, 0.25, 0.8)
@export var dot_color := Color.BLACK
@export var dot_radius := 5.0
@export var label_size := 16
@export var ui_position := Vector2(20, 20)
@export var show_debug := true
@export var show_area_guide := false

var ideal_paths: Array[PackedVector2Array] = []
var dot_positions := PackedVector2Array()
var strokes: Array[PackedVector2Array] = []
var line_nodes: Array[Line2D] = []
var current_line: Line2D
var drawing := false
var active := false
var locked := false
var ui_box: HBoxContainer
var status: Label

var input_enabled := true
func _ready() -> void:
	_build_ui()
	ui_box.visible = false
	if autostart and shape_scene:
		start_puzzle(shape_scene)
	queue_redraw()


func start_puzzle(scene: PackedScene) -> void:
	end_puzzle()
	_load_shape(scene)
	if ideal_paths.is_empty():
		return
	active = true
	ui_box.visible = true
	queue_redraw()


func end_puzzle() -> void:
	active = false
	locked = false
	drawing = false
	_clear_strokes()
	ideal_paths.clear()
	dot_positions.clear()
	ui_box.visible = false
	status.text = ""
	queue_redraw()


func _load_shape(scene: PackedScene) -> void:
	var shape := scene.instantiate()
	var raw_paths: Array[PackedVector2Array] = []
	for child in shape.get_children():
		var line := child as Line2D
		if line == null or line.get_point_count() < 2:
			continue
		var pts := PackedVector2Array()
		for p in line.points:
			pts.append(line.transform * p)
		raw_paths.append(pts)
	shape.free()

	if raw_paths.is_empty():
		push_error("Shape scene has no Line2D with at least 2 points")
		return

	var bounds := Rect2(raw_paths[0][0], Vector2.ZERO)
	for pts in raw_paths:
		for p in pts:
			bounds = bounds.expand(p)

	#var avail := drawing_rect.size - Vector2.ONE * fit_margin * 2.0
	#var s := minf(avail.x / maxf(bounds.size.x, 1.0), avail.y / maxf(bounds.size.y, 1.0))
	#var offset := drawing_rect.position + (drawing_rect.size - bounds.size * s) / 2.0 - bounds.position * s
	
	var margin := fit_margin + dot_radius + 12.0
	var avail := drawing_rect.size - Vector2.ONE * margin * 2.0

	var s := minf(
		avail.x / maxf(bounds.size.x, 1.0),
		avail.y / maxf(bounds.size.y, 1.0)
	)

	var offset := drawing_rect.position + (drawing_rect.size - bounds.size * s) / 2.0 - bounds.position * s

	for pts in raw_paths:
		var fitted := PackedVector2Array()
		for p in pts:
			fitted.append(p * s + offset)
		dot_positions.append_array(fitted)
		if closed:
			fitted.append(fitted[0])
		ideal_paths.append(fitted)


func _build_ui() -> void:
	ui_box = HBoxContainer.new()
	ui_box.position = ui_position
	add_child(ui_box)

	for entry in [["Undo", _on_undo_pressed], ["Clear", _on_clear_pressed]]:
		var b := Button.new()
		b.text = entry[0]
		b.pressed.connect(entry[1])
		ui_box.add_child(b)

	status = Label.new()
	status.position = ui_position + Vector2(0, 40)
	status.visible = show_debug
	add_child(status)


func _input(event: InputEvent) -> void:
	if not active or not input_enabled or locked or not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var pos := get_local_mouse_position()
			if drawing_rect.has_point(pos):
				_start_stroke(pos)
				get_viewport().set_input_as_handled()
		elif drawing:
			_end_stroke()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and drawing:
		_add_point(get_local_mouse_position())


func _start_stroke(pos: Vector2) -> void:
	drawing = true
	current_line = Line2D.new()
	current_line.width = line_width
	current_line.default_color = line_color
	current_line.add_point(pos)
	add_child(current_line)
	line_nodes.append(current_line)


func _add_point(pos: Vector2) -> void:
	if pos.distance_to(current_line.points[-1]) < 2.0:
		return
	current_line.add_point(pos)


func _end_stroke() -> void:
	drawing = false

	if current_line.get_point_count() < 2:
		current_line.queue_free()
		line_nodes.pop_back()
		return

	strokes.append(current_line.points)

	# check last to first dot
	_check_loop_closure()

func _check_loop_closure() -> void:
	if dot_positions.is_empty() or strokes.is_empty():
		return

	var last_point = strokes[-1][-1]
	var first_dot = dot_positions[0]

	if last_point.distance_to(first_dot) <= tolerance:

		if _check():
			print("yay")
			locked = true
			ui_box.visible = false
			puzzle_completed.emit()

		else:
			# FAILURE
			puzzle_failed.emit()
			
func _clear_strokes() -> void:
	strokes.clear()
	for line in line_nodes:
		line.queue_free()
	line_nodes.clear()


func _on_done_pressed() -> void:
	if locked:
		return
	if _check():
		locked = true
		ui_box.visible = false
		puzzle_completed.emit()
	else:
		puzzle_failed.emit()


func _on_undo_pressed() -> void:
	if locked or strokes.is_empty():
		return
	strokes.pop_back()
	line_nodes.pop_back().queue_free()
	status.text = ""


func _on_clear_pressed() -> void:
	if locked:
		return
	_clear_strokes()
	status.text = ""


func _check() -> bool:
	if strokes.is_empty():
		status.text = "Draw something first!"
		return false

	var ideal_samples := PackedVector2Array()
	for path in ideal_paths:
		ideal_samples.append_array(_sample_polyline(path))

	var covered := 0
	for p in ideal_samples:
		if _distance_to_strokes(p) <= tolerance:
			covered += 1
	var coverage := float(covered) / ideal_samples.size()

	var ink_samples := PackedVector2Array()
	for stroke in strokes:
		ink_samples.append_array(_sample_polyline(stroke))
	var stray := 0
	for p in ink_samples:
		if _distance_to_paths(p) > tolerance:
			stray += 1
	var stray_ratio := float(stray) / ink_samples.size()

	status.text = "Coverage: %d%%   Stray: %d%%" % [coverage * 100, stray_ratio * 100]
	return coverage >= required_coverage and stray_ratio <= allowed_stray


func _sample_polyline(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var steps := maxi(1, int(a.distance_to(b) / sample_spacing))
		for s in steps:
			result.append(a.lerp(b, float(s) / steps))
	result.append(points[-1])
	return result


func _distance_to_polyline(p: Vector2, points: PackedVector2Array) -> float:
	var best := INF
	for i in points.size() - 1:
		var closest := Geometry2D.get_closest_point_to_segment(p, points[i], points[i + 1])
		best = minf(best, p.distance_to(closest))
	return best


func _distance_to_strokes(p: Vector2) -> float:
	var best := INF
	for stroke in strokes:
		best = minf(best, _distance_to_polyline(p, stroke))
	return best


func _distance_to_paths(p: Vector2) -> float:
	var best := INF
	for path in ideal_paths:
		best = minf(best, _distance_to_polyline(p, path))
	return best


func _draw() -> void:
	if show_area_guide:
		draw_rect(drawing_rect, Color.RED, false, 2.0)
	var font := ThemeDB.fallback_font
	for i in dot_positions.size():
		var d := dot_positions[i]
		draw_circle(d, dot_radius, dot_color)
		draw_string(font, d + Vector2(8, -6), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, dot_color)
