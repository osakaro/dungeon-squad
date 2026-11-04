class_name FX
## Efectos visuales: partículas, anillos, números de daño, tajos, rayos y temblor de cámara.

static var root: Node3D
static var shake_amount := 0.0
static var _pmat: StandardMaterial3D
static var _slash_mesh: ArrayMesh

static func _particle_mat() -> StandardMaterial3D:
	if _pmat == null:
		_pmat = StandardMaterial3D.new()
		_pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_pmat.vertex_color_use_as_albedo = true
		_pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _pmat

static func flat_mat(c: Color, energy := 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(c.r * energy, c.g * energy, c.b * energy, c.a)
	return m

static func _later(t: float, cb: Callable) -> void:
	root.get_tree().create_timer(t, false).timeout.connect(cb)

## Partículas genéricas (gravedad negativa = caen, positiva = suben)
static func make_particles(color: Color, amount: int, speed: float, size: float, life: float, gravity := -8.0, one_shot := true) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 0.92 if one_shot else 0.0
	var m := SphereMesh.new()
	m.radius = size
	m.height = size * 2.0
	m.radial_segments = 6
	m.rings = 3
	m.material = _particle_mat()
	p.mesh = m
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, gravity, 0)
	p.damping_min = 1.0
	p.damping_max = 3.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	var g := Gradient.new()
	g.set_color(0, Color(color.r * 2.0, color.g * 2.0, color.b * 2.0, 1.0))
	g.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = g
	return p

static func burst(pos: Vector3, color: Color, amount := 16, speed := 4.0, size := 0.08, life := 0.6, gravity := -8.0) -> void:
	if root == null:
		return
	var p := make_particles(color, amount, speed, size, life, gravity)
	root.add_child(p)
	p.global_position = pos
	p.emitting = true
	_later(life + 0.4, p.queue_free)

static func ring(pos: Vector3, radius: float, color: Color, life := 0.4) -> void:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = radius * 0.86
	t.outer_radius = radius
	t.rings = 48
	t.ring_segments = 4
	mi.mesh = t
	var m := flat_mat(color, 2.5)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.global_position = Vector3(pos.x, 0.08, pos.z)
	mi.scale = Vector3(0.6, 0.1, 0.6)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(1.05, 0.1, 1.05), life).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, life)
	tw.chain().tween_callback(mi.queue_free)

static func number(pos: Vector3, value: float, color: Color, big := false) -> void:
	var l := Label3D.new()
	l.text = str(int(round(value)))
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.006
	l.font_size = 60 if big else 40
	l.outline_size = 10
	l.font = preload("res://assets/fonts/LilitaOne.ttf")
	l.modulate = color
	l.outline_modulate = Color(0, 0, 0, 0.85)
	root.add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.35, 0.35), 1.7, 0)
	l.scale = Vector3.ONE * 0.4
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "scale", Vector3.ONE * (1.3 if big else 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y + 1.1, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.3).set_delay(0.45)
	tw.chain().tween_callback(l.queue_free)

static func _get_slash_mesh() -> ArrayMesh:
	if _slash_mesh == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n := 20
		var span := 2.6
		for i in n:
			var a0 := -span / 2.0 + span * i / n
			var a1 := -span / 2.0 + span * (i + 1) / n
			var p0 := Vector3(sin(a0), 0, cos(a0))
			var p1 := Vector3(sin(a1), 0, cos(a1))
			var ri := 0.45
			st.add_vertex(p0 * ri); st.add_vertex(p0); st.add_vertex(p1)
			st.add_vertex(p0 * ri); st.add_vertex(p1); st.add_vertex(p1 * ri)
		_slash_mesh = st.commit()
	return _slash_mesh

static func slash(pos: Vector3, angle: float, radius: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _get_slash_mesh()
	var m := flat_mat(color, 2.2)
	m.albedo_color.a = 0.8
	mi.material_override = m
	root.add_child(mi)
	mi.global_position = Vector3(pos.x, 0.8, pos.z)
	mi.rotation.y = angle - 0.6
	mi.scale = Vector3.ONE * radius
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "rotation:y", angle + 0.3, 0.16)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.22)
	tw.chain().tween_callback(mi.queue_free)

static func beam(a: Vector3, b: Vector3, color: Color, width := 0.08) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	var d := a.distance_to(b)
	c.top_radius = width
	c.bottom_radius = width
	c.height = d
	mi.mesh = c
	var m := flat_mat(color, 3.0)
	mi.material_override = m
	root.add_child(mi)
	var pa := Vector3(a.x, 1.0, a.z)
	var pb := Vector3(b.x, 1.0, b.z)
	mi.look_at_from_position((pa + pb) / 2.0, pb, Vector3.UP)
	mi.rotate_object_local(Vector3.RIGHT, PI / 2)
	var tw := mi.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, 0.35)
	tw.tween_callback(mi.queue_free)

static func glow_sphere(r: float, c: Color, energy := 4.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2
	s.radial_segments = 12
	s.rings = 6
	mi.mesh = s
	mi.material_override = Rig.glow_mat(c, energy)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

## Estela continua que se queda en el mundo (local_coords = false)
static func trail(parent: Node3D, color: Color, size := 0.07, amount := 24, life := 0.35) -> CPUParticles3D:
	var p := make_particles(color, amount, 0.4, size, life, 0.5, false)
	p.local_coords = false
	parent.add_child(p)
	p.emitting = true
	return p

static func shake(v: float) -> void:
	shake_amount = max(shake_amount, v)
