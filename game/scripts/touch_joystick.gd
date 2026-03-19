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

func _reset_stick() -> void:
	_active_pointer = -1
	_current_vector = Vector2.ZERO
	_knob_offset = Vector2.ZERO
	vector_changed.emit(Vector2.ZERO)
	active_changed.emit(false)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, base_radius, Color(0.08, 0.1, 0.14, 0.22))
	draw_arc(center, engage_radius, 0.0, TAU, 48, Color(0.7, 0.9, 1.0, 0.14), 3.0)
	draw_circle(center + _knob_offset, knob_radius, Color(0.55, 0.86, 1.0, 0.75))
