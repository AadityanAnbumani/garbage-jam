extends Node2D

signal puzzle_completed
signal puzzle_failed

var ideal_paths: Array[PackedVector2Array] = []
var dot_positions := PackedVector2Array()

@export var closed := false
@export var tolerance := 40.0
@export var required_coverage := 0.9
@export var allowed_stray := 0.1
@export var sample_spacing := 8.0
@export var line_width := 6.0
@export var line_color := Color.WHITE

var strokes: Array[PackedVector2Array] = []
var line_nodes: Array[Line2D] = []
var current_line: Line2D
var drawing := false
var locked := false
var status: Label


func _ready() -> void:
	_load_shape()
	_build_ui()
	queue_redraw()


func _load_shape() -> void:
	for child in $Shape.get_children():
		if child is Line2D and child.get_point_count() >= 2:
			var pts := PackedVector2Array()
			for p in child.points:
				pts.append(to_local(child.to_global(p)))
			dot_positions.append_array(pts)
			if closed:
				pts.append(pts[0])
			ideal_paths.append(pts)
			child.visible = false


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var box := HBoxContainer.new()
	box.position = Vector2(20, 20)
	layer.add_child(box)

	for entry in [["Done", _on_done_pressed], ["Undo", _on_undo_pressed], ["Clear", _on_clear_pressed]]:
		var b := Button.new()
		b.text = entry[0]
		b.pressed.connect(entry[1])
		box.add_child(b)

	status = Label.new()
	status.position = Vector2(20, 60)
	layer.add_child(status)


func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_stroke(get_local_mouse_position())
		elif drawing:
			_end_stroke()
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


func _on_done_pressed() -> void:
	if locked:
		return
	if _check():
		locked = true
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
	strokes.clear()
	for line in line_nodes:
		line.queue_free()
	line_nodes.clear()
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
	for d in dot_positions:
		draw_circle(d, 8.0, Color.WHITE)
