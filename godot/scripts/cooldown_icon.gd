class_name CooldownIcon
extends Control
## Botón redondo de habilidad con recarga circular (como en los juegos de móvil).

var icon: SkillIcon
var color := Color.WHITE
var frac := 0.0
var locked := false
var lvl := 0
var secs := 0.0
var _flash := 0.0
var _was_ready := false
var _font: Font

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = preload("res://assets/fonts/Fredoka-Bold.ttf")

func setup(key: String, c: Color) -> void:
	color = c
	icon = SkillIcon.new(key, SkillIcon.color_of(key))
	add_child(icon)

func set_state(f: float, lock: bool, level: int, s: float) -> void:
	var ready := f <= 0.001 and not lock
	if ready and not _was_ready:
		_flash = 1.0
	_was_ready = ready
	frac = f
	locked = lock
	lvl = level
	secs = s
	queue_redraw()

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = max(0.0, _flash - delta * 2.5)
		queue_redraw()

func _draw() -> void:
	var c := size / 2
	var r: float = min(size.x, size.y) / 2
	icon.position = Vector2(r * 0.42, r * 0.42)
	icon.size = Vector2(r * 1.16, r * 1.16)
	draw_circle(c, r, Color(0.05, 0.06, 0.1, 0.8))
	draw_circle(c, r - 3, Color(color.r * 0.22, color.g * 0.22, color.b * 0.22, 0.95))
	icon.modulate.a = 0.3 if locked else (0.55 if frac > 0.0 else 1.0)
	if locked:
		draw_arc(c, r - 1.5, 0, TAU, 48, Color(1, 1, 1, 0.15), 2.0, true)
		return
	if frac > 0.0:
		var pts := PackedVector2Array([c])
		var n := 40
		for i in n + 1:
			var a := -PI / 2 + TAU * (1.0 - frac) + TAU * frac * i / n
			pts.append(c + Vector2(cos(a), sin(a)) * (r - 3))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
		draw_arc(c, r - 1.5, -PI / 2, -PI / 2 + TAU * (1.0 - frac), 48, color, 3.0, true)
		draw_string(_font, Vector2(0, c.y + 8), "%d" % ceil(secs), HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color(1, 1, 1, 0.95))
	else:
		draw_arc(c, r - 1.5, 0, TAU, 48, color.lightened(0.2), 3.0, true)
	if _flash > 0.0:
		draw_circle(c, r * (1.0 + (1.0 - _flash) * 0.35), Color(color.r, color.g, color.b, 0.35 * _flash))
	if lvl > 0:
		draw_circle(c + Vector2(r * 0.72, r * 0.72), 11, Color(0.08, 0.08, 0.12))
		draw_string(_font, c + Vector2(r * 0.72 - 11, r * 0.72 + 5), str(lvl), HORIZONTAL_ALIGNMENT_CENTER, 22, 13, GOLD_COL)

const GOLD_COL := Color(1, 0.8, 0.35)
