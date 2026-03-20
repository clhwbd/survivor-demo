extends Node2D
class_name FeedbackBurst

@export var life_time: float = 0.32
@export var max_radius: float = 34.0
@export var ring_width: float = 4.0
@export var spark_length: float = 20.0
@export var spark_count: int = 6

var burst_color: Color = Color(1.0, 0.9, 0.5, 1.0)
var accent_color: Color = Color(1.0, 1.0, 1.0, 0.9)
var progress: float = 0.0

func setup(primary: Color, accent: Color = Color(1.0, 1.0, 1.0, 0.9), radius_scale: float = 1.0, duration_scale: float = 1.0) -> void:
	burst_color = primary
	accent_color = accent
	max_radius *= radius_scale
	ring_width = maxf(2.0, ring_width * radius_scale)
	spark_length *= radius_scale
	life_time *= duration_scale

func _ready() -> void:
	z_index = 40
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
	var radius := lerpf(4.0, max_radius, eased)
	var alpha := 1.0 - eased
	var ring_color := burst_color
	ring_color.a *= alpha
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, ring_color, maxf(1.5, ring_width * (1.0 - progress * 0.4)), true)
	var core_color := accent_color
	core_color.a *= alpha * 0.9
	draw_circle(Vector2.ZERO, maxf(2.5, radius * 0.24 * (1.0 - progress * 0.35)), core_color)
	for i in range(maxi(4, spark_count)):
		var angle := TAU * float(i) / float(maxi(4, spark_count)) + progress * 0.8
		var dir := Vector2.RIGHT.rotated(angle)
		var inner := dir * radius * 0.42
		var outer := dir * (radius + spark_length * (1.0 - progress * 0.45))
		var spark_color := burst_color.lerp(accent_color, 0.35)
		spark_color.a *= alpha * 0.82
		draw_line(inner, outer, spark_color, maxf(1.0, ring_width * 0.52))
