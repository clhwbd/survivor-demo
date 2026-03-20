extends Control
class_name TouchJoystick

signal vector_changed(direction: Vector2)
signal active_changed(active: bool)

@export var base_radius: float = 68.0
@export var knob_radius: float = 28.0
@export var engage_radius: float = 86.0
@export_range(0.0, 0.95, 0.01) var deadzone: float = 0.12

var _active_pointer := -1
var _current_vector := Vector2.ZERO
var _knob_offset := Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(base_radius * 2.8, base_radius * 2.8)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_EXIT_TREE:
		cancel_input()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		cancel_input()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_global_rect().has_point(event.global_position):
				_active_pointer = -2
				_update_from_global(event.global_position)
				accept_event()
		else:
			if _active_pointer == -2:
				_reset_stick()
				accept_event()
	elif event is InputEventMouseMotion and _active_pointer == -2:
		_update_from_global(event.global_position)
		accept_event()

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if get_global_rect().has_point(event.position):
			_active_pointer = event.index
			_update_from_global(event.position)
			accept_event()
	elif event.index == _active_pointer:
		_reset_stick()
		accept_event()

func _handle_drag(pointer_index: int, screen_position: Vector2) -> void:
	if pointer_index != _active_pointer:
		return
	_update_from_global(screen_position)
	accept_event()

func _update_from_global(screen_position: Vector2) -> void:
	var center: Vector2 = global_position + size * 0.5
	var delta: Vector2 = screen_position - center
	var distance: float = minf(delta.length(), engage_radius)
	var normalized: Vector2 = Vector2.ZERO
	if distance > 0.0:
		normalized = delta.normalized() * (distance / engage_radius)
	if normalized.length() < deadzone:
		normalized = Vector2.ZERO
	_current_vector = normalized.limit_length(1.0)
	_knob_offset = _current_vector * base_radius
	vector_changed.emit(_current_vector)
	active_changed.emit(_current_vector.length() > 0.0)
	queue_redraw()

func cancel_input() -> void:
	if _active_pointer == -1 and _current_vector == Vector2.ZERO and _knob_offset == Vector2.ZERO:
		return
	_reset_stick()

func _reset_stick() -> void:
	_active_pointer = -1
	_current_vector = Vector2.ZERO
	_knob_offset = Vector2.ZERO
	vector_changed.emit(Vector2.ZERO)
	active_changed.emit(false)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var ring_color := Color(0.93, 0.82, 0.55, 0.42)
	var base_color := Color(0.14, 0.09, 0.07, 0.36)
	var base_inner := Color(0.50, 0.26, 0.18, 0.12)
	var knob_color := Color(0.84, 0.39, 0.26, 0.92)
	var knob_highlight := Color(0.99, 0.92, 0.80, 0.28)
	var active_ring := Color(0.62, 0.94, 0.76, 0.32) if _current_vector.length() > 0.0 else ring_color

	draw_circle(center, engage_radius, Color(0, 0, 0, 0.08))
	draw_circle(center, base_radius + 10.0, base_color)
	draw_circle(center, base_radius - 6.0, base_inner)
	draw_arc(center, engage_radius, 0.0, TAU, 56, active_ring, 4.0)
	draw_circle(center + _knob_offset, knob_radius + 6.0, Color(0, 0, 0, 0.16))
	draw_circle(center + _knob_offset, knob_radius, knob_color)
	draw_circle(center + _knob_offset + Vector2(-6, -7), knob_radius * 0.42, knob_highlight)
