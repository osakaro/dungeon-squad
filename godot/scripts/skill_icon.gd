class_name SkillIcon
extends Control
## Dibuja con vectores el icono de cada habilidad o mejora (sin imágenes externas).

var key := ""
var color := Color.WHITE
var _pass := 0      # 0 = contorno oscuro, 1 = color

func _init(k := "", c := Color.WHITE) -> void:
	key = k
	color = c
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(k: String, c: Color) -> void:
	tex = null
	key = k
	color = c
	queue_redraw()

func _p(x: float, y: float) -> Vector2:
	return Vector2(x, y) * size.x

func _col() -> Color:
	return Color(0, 0, 0, 0.6) if _pass == 0 else color

func _w(w: float) -> float:
	return (w + (0.035 if _pass == 0 else 0.0)) * size.x

func _line(a: Vector2, b: Vector2, w := 0.06) -> void:
	draw_line(_p(a.x, a.y), _p(b.x, b.y), _col(), _w(w), true)

func _poly(pts: Array) -> void:
	var arr := PackedVector2Array()
	for q in pts:
		arr.append(_p(q.x, q.y))
	if _pass == 0:
		draw_polyline(arr + PackedVector2Array([arr[0]]), _col(), _w(0.0) + 1.0, true)
	draw_colored_polygon(arr, _col())

func _circle(c: Vector2, r: float, filled := true, w := 0.06) -> void:
	if filled:
		draw_circle(_p(c.x, c.y), (r + (0.02 if _pass == 0 else 0.0)) * size.x, _col())
	else:
		draw_arc(_p(c.x, c.y), r * size.x, 0, TAU, 40, _col(), _w(w), true)

func _arc(c: Vector2, r: float, a0: float, a1: float, w := 0.06) -> void:
	draw_arc(_p(c.x, c.y), r * size.x, a0, a1, 24, _col(), _w(w), true)

func _arrow(a: Vector2, b: Vector2, w := 0.05, head := 0.12) -> void:
	_line(a, b, w)
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	_poly([b + d * 0.04, b - d * head + n * head * 0.6, b - d * head - n * head * 0.6])

func _blade(a: Vector2, b: Vector2, w := 0.07) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * w
	_poly([a + n, b - d * 0.08 + n, b, b - d * 0.08 - n, a - n])
	_line(a - n * 2.2, a + n * 2.2, 0.05)

func _heart(c: Vector2, r: float) -> void:
	var pts := []
	for i in 32:
		var t := i / 32.0 * TAU
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y) * r / 17.0)
	_poly(pts)

func _drop(c: Vector2, r: float) -> void:
	var pts := [c + Vector2(0, -r * 1.6)]
	for i in 17:
		var a := PI * 0.15 - i * PI * 1.3 / 16.0
		pts.append(c + Vector2(cos(a), -sin(a)) * r)
	_poly(pts)

func _star(c: Vector2, r1: float, r2: float, n: int, rot := 0.0) -> void:
	var pts := []
	for i in n * 2:
		var a := rot + i * PI / n
		pts.append(c + Vector2(cos(a), sin(a)) * (r1 if i % 2 == 0 else r2))
	_poly(pts)

var tex: Texture2D

func _draw() -> void:
	if tex == null and ResourceLoader.exists("res://assets/icons/%s.svg" % key):
		tex = load("res://assets/icons/%s.svg" % key)
	if tex:
		draw_texture_rect(tex, Rect2(Vector2(0, size.y * 0.04), size), false, Color(0, 0, 0, 0.45))
		draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false, color)
		return
	for p in 2:
		_pass = p
		_draw_icon()

func _draw_icon() -> void:
	var C := Vector2(0.5, 0.5)
	match key:
		"lluvia":
			for i in 4:
				var x := 0.2 + i * 0.2
				_arrow(Vector2(x + 0.08, 0.12 + (i % 2) * 0.1), Vector2(x - 0.04, 0.62 + (i % 2) * 0.12), 0.04, 0.1)
			_arc(Vector2(0.5, 0.88), 0.3, PI * 1.15, PI * 1.85, 0.04)
		"cargado":
			_circle(Vector2(0.25, 0.5), 0.16, false, 0.04)
			_circle(Vector2(0.25, 0.5), 0.07)
			_arrow(Vector2(0.12, 0.5), Vector2(0.9, 0.5), 0.09, 0.2)
			_line(Vector2(0.1, 0.32), Vector2(0.45, 0.32), 0.03)
			_line(Vector2(0.1, 0.68), Vector2(0.45, 0.68), 0.03)
		"meteoro":
			for i in 3:
				_line(Vector2(0.15 + i * 0.12, 0.12), Vector2(0.55 + i * 0.05, 0.55), 0.05 - i * 0.01)
			_circle(Vector2(0.64, 0.64), 0.2)
			_star(Vector2(0.64, 0.64), 0.28, 0.17, 8, 0.4)
		"hielo":
			for i in 6:
				var a := i * TAU / 6.0
				var d := Vector2(cos(a), sin(a))
				_line(C, C + d * 0.4, 0.05)
				var m := C + d * 0.26
				_line(m, m + d.rotated(0.8) * 0.12, 0.04)
				_line(m, m + d.rotated(-0.8) * 0.12, 0.04)
		"torbellino":
			_arc(C, 0.38, 0.0, 4.5, 0.05)
			_arc(C, 0.26, 1.5, 6.0, 0.05)
			_arc(C, 0.14, 3.0, 7.5, 0.05)
			_blade(Vector2(0.5, 0.5), Vector2(0.88, 0.2), 0.05)
		"grito":
			_poly([Vector2(0.12, 0.44), Vector2(0.5, 0.3), Vector2(0.5, 0.7), Vector2(0.12, 0.56)])
			_circle(Vector2(0.12, 0.5), 0.07)
			for i in 3:
				_arc(Vector2(0.5, 0.5), 0.14 + i * 0.12, -0.7, 0.7, 0.045)
		"abanico":
			for i in 8:
				var a := i * TAU / 8.0
				var d := Vector2(cos(a), sin(a))
				_blade(C + d * 0.12, C + d * 0.44, 0.04)
		"sombra":
			for i in 3:
				_line(Vector2(0.08, 0.35 + i * 0.15), Vector2(0.35, 0.35 + i * 0.15), 0.04)
			_circle(Vector2(0.62, 0.25), 0.11)
			_poly([Vector2(0.45, 0.4), Vector2(0.8, 0.4), Vector2(0.86, 0.9), Vector2(0.4, 0.9)])
		"esqueleto":
			_circle(Vector2(0.5, 0.42), 0.3)
			_poly([Vector2(0.32, 0.6), Vector2(0.68, 0.6), Vector2(0.64, 0.85), Vector2(0.36, 0.85)])
			if _pass == 1:
				draw_circle(_p(0.39, 0.42), 0.08 * size.x, Color(0.05, 0.05, 0.08))
				draw_circle(_p(0.61, 0.42), 0.08 * size.x, Color(0.05, 0.05, 0.08))
				for i in 3:
					draw_line(_p(0.42 + i * 0.08, 0.66), _p(0.42 + i * 0.08, 0.82), Color(0.05, 0.05, 0.08), 0.03 * size.x)
		"drenaje", "lifesteal":
			_drop(Vector2(0.5, 0.58), 0.26)
			if key == "drenaje":
				_arrow(Vector2(0.88, 0.85), Vector2(0.78, 0.2), 0.04, 0.1)
		"multi":
			for i in 3:
				_arrow(Vector2(0.12, 0.28 + i * 0.22), Vector2(0.86, 0.28 + i * 0.22), 0.045, 0.12)
		"pierce":
			_circle(Vector2(0.55, 0.5), 0.2, false, 0.05)
			_arrow(Vector2(0.08, 0.5), Vector2(0.92, 0.5), 0.05, 0.13)
		"bounce":
			_line(Vector2(0.85, 0.1), Vector2(0.85, 0.9), 0.06)
			_line(Vector2(0.12, 0.2), Vector2(0.78, 0.5), 0.05)
			_arrow(Vector2(0.78, 0.5), Vector2(0.2, 0.84), 0.05, 0.12)
		"diag":
			for a in [-0.55, 0.0, 0.55]:
				var d := Vector2(cos(a - PI / 2), sin(a - PI / 2))
				_arrow(Vector2(0.5, 0.88), Vector2(0.5, 0.88) + d * 0.72, 0.045, 0.12)
		"aoe":
			_star(C, 0.42, 0.2, 10)
			_circle(C, 0.13)
		"chain":
			_poly([Vector2(0.58, 0.05), Vector2(0.22, 0.55), Vector2(0.48, 0.55), Vector2(0.36, 0.95), Vector2(0.78, 0.4), Vector2(0.52, 0.4)])
		"orb":
			_circle(C, 0.32, false, 0.035)
			_circle(C, 0.12)
			_circle(Vector2(0.5 + 0.32 * cos(-0.6), 0.5 + 0.32 * sin(-0.6)), 0.1)
		"arc":
			_arc(Vector2(0.4, 0.62), 0.42, -1.6, 0.2, 0.07)
			_blade(Vector2(0.25, 0.8), Vector2(0.8, 0.22), 0.06)
		"wave":
			for i in 3:
				_arc(Vector2(0.2, 0.5), 0.2 + i * 0.16, -0.9, 0.9, 0.06 - i * 0.012)
		"thorns":
			_star(C, 0.44, 0.24, 8)
			_circle(C, 0.18)
		"crit":
			_circle(C, 0.34, false, 0.05)
			_circle(C, 0.18, false, 0.05)
			_circle(C, 0.06)
			for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				_line(C + d * 0.3, C + d * 0.46, 0.05)
		"spdpas", "spd":
			_poly([Vector2(0.4, 0.15), Vector2(0.6, 0.15), Vector2(0.6, 0.62), Vector2(0.88, 0.7), Vector2(0.88, 0.85), Vector2(0.4, 0.85)])
			for i in 3:
				_line(Vector2(0.06, 0.35 + i * 0.18), Vector2(0.3, 0.35 + i * 0.18), 0.04)
		"dmg":
			_blade(Vector2(0.5, 0.88), Vector2(0.5, 0.08), 0.08)
			_star(Vector2(0.5, 0.35), 0.4, 0.3, 8)
		"rate":
			for i in 2:
				_poly([Vector2(0.15 + i * 0.32, 0.2), Vector2(0.5 + i * 0.32, 0.5), Vector2(0.15 + i * 0.32, 0.8), Vector2(0.27 + i * 0.32, 0.5)])
		"hp":
			_heart(Vector2(0.5, 0.52), 0.38)
			if _pass == 1:
				draw_line(_p(0.5, 0.36), _p(0.5, 0.64), Color.WHITE, 0.07 * size.x)
				draw_line(_p(0.36, 0.5), _p(0.64, 0.5), Color.WHITE, 0.07 * size.x)
		"heal":
			_poly([Vector2(0.42, 0.1), Vector2(0.58, 0.1), Vector2(0.58, 0.32), Vector2(0.78, 0.5), Vector2(0.78, 0.85),
				Vector2(0.22, 0.85), Vector2(0.22, 0.5), Vector2(0.42, 0.32)])
			if _pass == 1:
				draw_rect(Rect2(_p(0.25, 0.55), _p(0.5, 0.27)), Color(1, 0.3, 0.4))
		_:
			_star(C, 0.4, 0.18, 5, -PI / 2)
