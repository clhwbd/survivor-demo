extends Node2D
class_name CollectPulse

@export var life_time: float = 0.38
@export var max_radius: float = 28.0
@export var ring_width: float = 3.5
@export var spark_length: float = 14.0
@export var spark_count: int = 5

var primary_color: Color = Color(1.0, 0.84, 0.36, 1.0)
var accent_color: Color = Color(1.0, 0.97, 0.88, 0.95)
var progress: float = 0.0
var pulse_scale: float = 1.0

func setup(primary: Color, accent: Color = Color(1.0, 0.97, 0.88, 0.95), scale_mul: float = 1.0, duration_mul: float = 1.0) -> void:
	primary_color = primary
	accent_color = accent
	pulse_scale = maxf(0.4, scale_mul)
	life_time *= maxf(0.45, duration_mul)

func _ready() -> void:
	z_index = 42
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if life_time <= 0.0:
		queue_free()
		return
	progress = minf(1.0, progress + delta / life_time)
	queue_redraw()
	if progress >= 1.0:
		queue_free()

func _draw() -> void:
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var fade := 1.0 - eased
	var radius := lerpf(6.0, max_radius * pulse_scale, eased)

	var ring_color := primary_color
	ring_color.a *= fade * 0.92
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, ring_color, maxf(1.5, ring_width * (1.0 - progress * 0.4)), true)

	var inner_ring := accent_color
	inner_ring.a *= fade * 0.72
	draw_arc(Vector2.ZERO, radius * 0.52, 0.0, TAU, 22, inner_ring, maxf(1.0, ring_width * 0.45), true)

	var core_color := accent_color
	core_color.a *= fade * 0.55
	draw_circle(Vector2.ZERO, maxf(3.0, radius * 0.20 * (1.0 - progress * 0.25)), core_color)

	for i in range(maxi(4, spark_count)):
		var angle := TAU * float(i) / float(maxi(4, spark_count)) + eased * 0.4
		var dir := Vector2.RIGHT.rotated(angle)
		var inner := dir * (radius * 0.58 + 2.0)
		var outer := dir * (radius + spark_length * (1.0 - progress * 0.42))
		var spark_color := primary_color.lerp(accent_color, 0.4)
		spark_color.a *= fade * (0.62 + 0.28 * sin(float(i) * 1.3 + progress * 4.0))
		draw_line(inner, outer, spark_color, maxf(1.0, ring_width * 0.28))
