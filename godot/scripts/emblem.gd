class_name Emblem
extends Control
## Escudo con espadas cruzadas del logo de DUNGEON SQUAD.

var t := 0.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _p(x: float, y: float) -> Vector2:
	return Vector2(x, y) * size.x

func _sword(a: Vector2, b: Vector2, w: float, blade: Color) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * w
	var pts := PackedVector2Array([_p(a.x, a.y) + n * size.x, _p(b.x, b.y) - d * 0.08 * size.x + n * size.x, _p(b.x, b.y),
		_p(b.x, b.y) - d * 0.08 * size.x - n * size.x, _p(a.x, a.y) - n * size.x])
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0, 0, 0, 0.8), 6.0, true)
	draw_colored_polygon(pts, blade)
	var g1 := _p(a.x, a.y) + d * 0.02 * size.x
	draw_line(g1 - n * size.x * 3.5, g1 + n * size.x * 3.5, Color(0.1, 0.05, 0.0), 14.0, true)
	draw_line(g1 - n * size.x * 3.5, g1 + n * size.x * 3.5, Color(0.95, 0.7, 0.2), 9.0, true)
	draw_line(_p(a.x, a.y), _p(a.x, a.y) - d * 0.13 * size.x, Color(0.35, 0.2, 0.1), 10.0, true)
	draw_circle(_p(a.x, a.y) - d * 0.15 * size.x, 0.025 * size.x, Color(0.95, 0.7, 0.2))

func _draw() -> void:
	var glow := 0.5 + sin(t * 2.0) * 0.2
	draw_circle(_p(0.5, 0.5), 0.48 * size.x, Color(1, 0.6, 0.15, 0.08 * glow))
	draw_circle(_p(0.5, 0.5), 0.38 * size.x, Color(1, 0.6, 0.15, 0.1 * glow))
	_sword(Vector2(0.18, 0.85), Vector2(0.86, 0.1), 0.028, Color(0.82, 0.86, 0.92))
	_sword(Vector2(0.82, 0.85), Vector2(0.14, 0.1), 0.028, Color(0.82, 0.86, 0.92))
	var shield := PackedVector2Array()
	for q in [Vector2(0.28, 0.24), Vector2(0.5, 0.18), Vector2(0.72, 0.24), Vector2(0.72, 0.5), Vector2(0.66, 0.66),
			Vector2(0.5, 0.82), Vector2(0.34, 0.66), Vector2(0.28, 0.5)]:
		shield.append(_p(q.x, q.y))
	draw_polyline(shield + PackedVector2Array([shield[0]]), Color(0.1, 0.05, 0.0), 16.0, true)
	draw_colored_polygon(shield, Color(0.55, 0.1, 0.12))
	var inner := PackedVector2Array()
	var c := _p(0.5, 0.48)
	for q in shield:
		inner.append(c + (q - c) * 0.8)
	draw_colored_polygon(inner, Color(0.75, 0.15, 0.15))
	draw_polyline(shield + PackedVector2Array([shield[0]]), Color(0.95, 0.72, 0.2), 7.0, true)
	# calavera
	draw_circle(_p(0.5, 0.44), 0.1 * size.x, Color(0.95, 0.92, 0.85))
	draw_rect(Rect2(_p(0.44, 0.5), _p(0.12, 0.08)), Color(0.95, 0.92, 0.85))
	var eye := Color(1, 0.6, 0.1).lerp(Color(1, 0.9, 0.3), glow)
	draw_circle(_p(0.46, 0.44), 0.03 * size.x, eye)
	draw_circle(_p(0.54, 0.44), 0.03 * size.x, eye)
	for i in 3:
		draw_line(_p(0.465 + i * 0.035, 0.52), _p(0.465 + i * 0.035, 0.575), Color(0.3, 0.1, 0.1), 3.0)
