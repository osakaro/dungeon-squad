class_name EnemyArrows
extends Control
## Flechas en el borde de la pantalla que señalan a los enemigos que no se ven.

var main

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	if main == null or main.state != "play" or main.cam == null:
		return
	var cam: Camera3D = main.cam
	var r := Rect2(Vector2.ZERO, size)
	var inner := r.grow(-46)
	var c := size / 2
	var t := Time.get_ticks_msec() / 1000.0
	for e in main.get_enemies():
		if not is_instance_valid(e) or not e.is_active():
			continue
		var wp: Vector3 = e.global_position + Vector3.UP
		var behind := cam.is_position_behind(wp)
		var sp := cam.unproject_position(wp)
		if not behind and r.grow(-10).has_point(sp):
			continue
		var dir := (sp - c)
		if behind:
			dir = -dir
		if dir.length() < 1.0:
			continue
		dir = dir.normalized()
		var kx: float = (inner.size.x / 2) / max(0.001, abs(dir.x))
		var ky: float = (inner.size.y / 2) / max(0.001, abs(dir.y))
		var p: Vector2 = c + dir * min(kx, ky)
		var s := 15.0 if not e.is_boss else 22.0
		s *= 1.0 + sin(t * 6.0) * 0.08
		var col := Color(1, 0.35, 0.3) if not e.is_boss else Color(1, 0.75, 0.25)
		var n := Vector2(-dir.y, dir.x)
		var pts := PackedVector2Array([p + dir * s, p - dir * s * 0.6 + n * s * 0.75, p - dir * s * 0.25, p - dir * s * 0.6 - n * s * 0.75])
		draw_colored_polygon(pts, Color(0, 0, 0, 0.35))
		var pts2 := PackedVector2Array()
		for q in pts:
			pts2.append(q - dir * 2.0)
		draw_colored_polygon(pts2, col)
