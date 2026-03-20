extends SceneTree

const TouchJoystick := preload("res://scripts/touch_joystick.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Control.new()
	host.name = "Host"
	root.add_child(host)

	var joystick := TouchJoystick.new()
	joystick.position = Vector2(20, 20)
	joystick.size = Vector2(190, 190)
	host.add_child(joystick)
	await process_frame

	var emitted_vectors: Array[Vector2] = []
	joystick.vector_changed.connect(func(direction: Vector2) -> void:
		emitted_vectors.append(direction)
	)

	var center := joystick.global_position + joystick.size * 0.5
	var press := InputEventScreenTouch.new()
	press.index = 1
	press.pressed = true
	press.position = center + Vector2(30, 0)
	joystick._gui_input(press)
	_assert(emitted_vectors.size() > 0, "touch press should emit vector_changed")
	_assert(emitted_vectors.back().length() > 0.0, "touch press should produce a non-zero vector")

	joystick.cancel_input()
	_assert(emitted_vectors.back().is_zero_approx(), "cancel_input should reset joystick vector to zero")

	emitted_vectors.clear()
	joystick._gui_input(press)
	_assert(emitted_vectors.size() > 0 and emitted_vectors.back().length() > 0.0, "second touch press should reactivate joystick")
	joystick.cancel_input()
	_assert(emitted_vectors.back().is_zero_approx(), "repeated cancel_input should keep joystick vector at zero")

	if _failures.is_empty():
		print("touch_joystick_smoke: ok")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
