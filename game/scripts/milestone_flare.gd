extends Node2D
class_name MilestoneFlare

@export var life_time: float = 0.62
@export var base_radius: float = 32.0
@export var radius_growth: float = 112.0
@export var ring_width: float = 6.0
@export var fan_length: float = 64.0
@export var fan_width: float = 0.30
@export var fan_count: int = 5
@export var spark_count: int = 10

var primary_color: Color = Color(1.0, 0.84, 0.36, 1.0)
var accent_color: Color = Color(1.0, 0.97, 0.88, 0.95)
var progress: float = 0.0
var flare_scale: float = 1.0
var angle_offset: float = 0.0

func setup(primary: Color, accent: Color = Color(1.0, 0.97, 0.88, 0.95), scale_mul: float = 1.0, duration_mul: float = 1.0, fan_total: int = 5) -> void:
	primary_color = primary
	accent_color = accent
	flare_scale = maxf(0.55, scale_mul)
	life_time *= maxf(0.45, duration_mul)
	fan_count = maxi(3, fan_total)
	angle_offset = randf_range(-0.18, 0.18)

func _ready() -> void:
	z_index = 43
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if life_time <= 0.0:
		queue_free()
		return
	progress = minf(1.0, progress + delta / life_time)
	rotation = lerpf(rotation, angle_offset + progress * 0.22, delta * 8.0)
	queue_redraw()
	if progress >= 1.0:
		queue_free()

func _draw() -> void:
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var fade := 1.0 - eased
	var radius := (base_radius + radius_growth * eased) * flare_scale
	var inner_radius := maxf(8.0, radius * 0.26)

	var ring_color := primary_color
	ring_color.a *= fade * 0.92
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, ring_color, maxf(2.0, ring_width * (1.0 - progress * 0.30)), true)

	var inner_ring := accent_color
	inner_ring.a *= fade * 0.72
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 32, inner_ring, maxf(1.0, ring_width * 0.45), true)

	var core_color := accent_color
	core_color.a *= fade * 0.30
	draw_circle(Vector2.ZERO, maxf(4.0, radius * 0.14 * (1.0 - progress * 0.18)), core_color)

	for i in range(fan_count):
		var fan_ratio := 0.0 if fan_count <= 1 else float(i) / float(fan_count - 1)
		var center_angle := -PI * 0.5 + lerpf(-0.72, 0.72, fan_ratio) + angle_offset * 0.7
		var left := Vector2.RIGHT.rotated(center_angle - fan_width) * (radius * 0.30)
		var tip := Vector2.RIGHT.rotated(center_angle) * (radius + fan_length * (1.0 - progress * 0.22))
		var right := Vector2.RIGHT.rotated(center_angle + fan_width) * (radius * 0.30)
		var fan_color := accent_color.lerp(primary_color, 0.34)
		fan_color.a *= fade * 0.24 * (1.0 - absf(fan_ratio - 0.5) * 0.35)
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, left, tip, right]), fan_color)

	for i in range(maxi(6, spark_count)):
		var angle := TAU * float(i) / float(maxi(6, spark_count)) + angle_offset + eased * 0.35
		var dir := Vector2.RIGHT.rotated(angle)
		var inner := dir * (inner_radius + 4.0)
		var outer := dir * (radius + 10.0 + 18.0 * sin(float(i) * 0.8 + progress * 4.2))
		var spark_color := primary_color.lerp(accent_color, 0.52)
		spark_color.a *= fade * 0.58
		draw_line(inner, outer, spark_color, maxf(1.0, ring_width * 0.22))
