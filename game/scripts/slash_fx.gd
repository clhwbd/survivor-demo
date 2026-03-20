extends Node2D
class_name SlashFx

@export var life_time: float = 0.22
@export var base_radius: float = 26.0
@export var radius_growth: float = 26.0
@export var arc_width: float = 8.0
@export var spark_length: float = 16.0
@export var spark_count: int = 5

var primary_color: Color = Color(1.0, 0.84, 0.36, 1.0)
var accent_color: Color = Color(1.0, 0.97, 0.88, 0.95)
var progress: float = 0.0
var arc_span: float = PI * 0.92
var radius_scale: float = 1.0

func setup(primary: Color, accent: Color = Color(1.0, 0.97, 0.88, 0.95), scale_mul: float = 1.0, duration_mul: float = 1.0) -> void:
	primary_color = primary
	accent_color = accent
	radius_scale = maxf(0.4, scale_mul)
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
	var radius := (base_radius + radius_growth * eased) * radius_scale
	var start_angle := -arc_span * 0.5 - 0.25 + eased * 0.22
	var end_angle := arc_span * 0.5 + 0.18 + eased * 0.22
	var slash_color := primary_color
	slash_color.a *= fade
	draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 24, slash_color, maxf(2.0, arc_width * (1.0 - progress * 0.35)), true)

	var highlight := accent_color
	highlight.a *= fade * 0.88
	draw_arc(Vector2.ZERO, radius - 6.0 * radius_scale, start_angle + 0.12, end_angle - 0.10, 18, highlight, maxf(1.0, arc_width * 0.36), true)

	for i in range(maxi(3, spark_count)):
		var t := float(i) / float(maxi(1, spark_count - 1))
		var angle := lerpf(start_angle + 0.05, end_angle - 0.05, t)
		var dir := Vector2.RIGHT.rotated(angle)
		var outer := dir * (radius + spark_length * (1.0 - progress * 0.5) * (0.55 + t * 0.35))
		var inner := dir * (radius - 8.0 * radius_scale)
		var spark_color := primary_color.lerp(accent_color, 0.4)
		spark_color.a *= fade * (0.5 + 0.4 * (1.0 - t))
		draw_line(inner, outer, spark_color, maxf(1.0, arc_width * 0.22))

	var tail_color := accent_color
	tail_color.a *= fade * 0.55
	draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(end_angle) * radius * 0.72, tail_color, maxf(1.0, arc_width * 0.28))
