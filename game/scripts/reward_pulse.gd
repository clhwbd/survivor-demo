extends Node2D
class_name RewardPulse

@export var life_time: float = 0.48
@export var base_radius: float = 22.0
@export var radius_growth: float = 84.0
@export var ring_width: float = 5.0
@export var ray_length: float = 34.0
@export var ray_count: int = 8

var primary_color: Color = Color(1.0, 0.84, 0.36, 1.0)
var accent_color: Color = Color(1.0, 0.97, 0.88, 0.95)
var progress: float = 0.0
var pulse_scale: float = 1.0

func setup(primary: Color, accent: Color = Color(1.0, 0.97, 0.88, 0.95), scale_mul: float = 1.0, duration_mul: float = 1.0) -> void:
	primary_color = primary
	accent_color = accent
	pulse_scale = maxf(0.5, scale_mul)
	life_time *= maxf(0.45, duration_mul)

func _ready() -> void:
	z_index = 41
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
	var radius := (base_radius + radius_growth * eased) * pulse_scale
	var inner_radius := maxf(6.0, radius * 0.36)

	var outer_color := primary_color
	outer_color.a *= fade * 0.95
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, outer_color, maxf(1.5, ring_width * (1.0 - progress * 0.35)), true)

	var inner_color := accent_color
	inner_color.a *= fade * 0.65
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 28, inner_color, maxf(1.0, ring_width * 0.42), true)

	var core_color := accent_color
	core_color.a *= fade * 0.55
	draw_circle(Vector2.ZERO, maxf(3.0, radius * 0.18 * (1.0 - progress * 0.30)), core_color)

	for i in range(maxi(4, ray_count)):
		var angle := TAU * float(i) / float(maxi(4, ray_count)) + eased * 0.35
		var dir := Vector2.RIGHT.rotated(angle)
		var ray_start := dir * (inner_radius + 4.0)
		var ray_end := dir * (radius + ray_length * (1.0 - progress * 0.45) * (0.8 + 0.18 * sin(float(i) * 1.7)))
		var ray_color := primary_color.lerp(accent_color, 0.42)
		ray_color.a *= fade * (0.55 + 0.25 * sin(float(i) * 0.8 + progress * 3.2))
		draw_line(ray_start, ray_end, ray_color, maxf(1.0, ring_width * 0.26))
