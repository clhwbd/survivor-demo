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

# Ghost trail state — trails behind the main arc
var _ghost_progress: float = 0.0
var _perpendicular_sparks: Array = []

func setup(primary: Color, accent: Color = Color(1.0, 0.97, 0.88, 0.95), scale_mul: float = 1.0, duration_mul: float = 1.0) -> void:
	primary_color = primary
	accent_color = accent
	radius_scale = maxf(0.4, scale_mul)
	life_time *= maxf(0.45, duration_mul)
	# Pre-generate perpendicular spark offsets for visual richness
	for i in range(maxi(2, spark_count)):
		_perpendicular_sparks.append(randf_range(0.5, 1.8))

func _ready() -> void:
	z_index = 42
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if life_time <= 0.0:
		queue_free()
		return
	progress = minf(1.0, progress + delta / life_time)
	# Ghost trails at 40-70% phase lag
	_ghost_progress = maxf(0.0, progress - 0.38)
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

	# ── Ghost trail: secondary arc that follows behind ───────────────────────
	if _ghost_progress > 0.0:
		var ghost_eased := 1.0 - pow(1.0 - _ghost_progress, 3.0)
		var ghost_fade := (1.0 - ghost_eased) * 0.48
		var ghost_radius := (base_radius + radius_growth * ghost_eased) * radius_scale * 0.88
		var ghost_start := start_angle + _ghost_progress * 0.18
		var ghost_end := end_angle + _ghost_progress * 0.18
		var ghost_color := primary_color.lerp(accent_color, 0.3)
		ghost_color.a *= ghost_fade
		draw_arc(Vector2.ZERO, ghost_radius, ghost_start, ghost_end, 16, ghost_color, maxf(1.0, arc_width * 0.28), true)
		var ghost_inner := accent_color
		ghost_inner.a *= ghost_fade * 0.65
		draw_arc(Vector2.ZERO, ghost_radius - 4.0 * radius_scale, ghost_start + 0.08, ghost_end - 0.08, 12, ghost_inner, maxf(0.5, arc_width * 0.18), true)

	# ── Perpendicular sparks: burst outward from arc midpoint ────────────────
	var mid_t := 0.5
	var mid_angle := lerpf(start_angle + 0.05, end_angle - 0.05, mid_t)
	var perp_dir := Vector2.RIGHT.rotated(mid_angle + PI * 0.5)
	var perp_inner := perp_dir * (radius * 0.25)
	var perp_outer := perp_dir * (radius + spark_length * 1.2 * (1.0 - progress * 0.4))
	var perp_color := accent_color.lerp(primary_color, 0.25)
	perp_color.a *= fade * 0.62
	draw_line(perp_inner, perp_outer, perp_color, maxf(1.0, arc_width * 0.28))
	# Mirror opposite side
	var perp_inner2 := -perp_dir * (radius * 0.25)
	var perp_outer2 := -perp_dir * (radius + spark_length * 1.2 * (1.0 - progress * 0.4))
	draw_line(perp_inner2, perp_outer2, perp_color, maxf(1.0, arc_width * 0.28))

	# ── Leading-edge glow dot ─────────────────────────────────────────────────
	var tip_radius := (base_radius + radius_growth) * radius_scale
	var tip_color := accent_color
	tip_color.a *= fade * 0.72
	draw_circle(Vector2.RIGHT.rotated(end_angle) * tip_radius * 0.92, maxf(2.0, arc_width * 0.22 * (1.0 - progress * 0.5)), tip_color)
