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

	var original_position := joystick.global_position
	var arbitrary_press := Vector2(320, 480)
	joystick.begin_pointer(1, arbitrary_press)
	_assert(emitted_vectors.size() > 0, "touch press should emit vector_changed")
	_assert(emitted_vectors.back().is_zero_approx(), "touch origin press should start at zero vector")
	_assert(joystick.global_position.distance_to(original_position) > 40.0, "floating joystick should move near the pressed position")

	joystick.update_pointer(1, arbitrary_press + Vector2(56, 0))
	_assert(emitted_vectors.back().length() > 0.0, "drag after floating press should produce a non-zero vector")

	joystick.cancel_input()
	_assert(emitted_vectors.back().is_zero_approx(), "cancel_input should reset joystick vector to zero")
	_assert(joystick.global_position.distance_to(original_position) < 1.0, "cancel_input should restore joystick to its layout position")

	emitted_vectors.clear()
	joystick.begin_pointer(2, Vector2(540, 300))
	joystick.update_pointer(2, Vector2(590, 336))
	_assert(emitted_vectors.size() > 0 and emitted_vectors.back().length() > 0.0, "second floating touch should reactivate joystick")
	joystick.end_pointer(2)
	_assert(emitted_vectors.back().is_zero_approx(), "end_pointer should keep joystick vector at zero")

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
