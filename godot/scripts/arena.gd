class_name Arena
extends Node3D
## Genera la mazmorra: suelo, muros, antorchas, portal y obstáculos aleatorios por nivel.

const W := 14.0
const H := 22.0

var obstacles := []          # [{pos: Vector3, r: float}]
var level_nodes: Node3D
var floor_mm: MultiMesh
var floor_colors := []
var torches := []
var portal_mat: StandardMaterial3D
var portal_light: OmniLight3D
var portal_fx: CPUParticles3D
var portal_rune: StandardMaterial3D
var time := 0.0

var wall_mm: MultiMesh
var wall_colors := []
var outside: Node3D
var biome := ""

func build() -> void:
	_build_floor()
	_build_walls()
	_build_torches()
	_build_portal()
	_build_dust()
	level_nodes = Node3D.new()
	add_child(level_nodes)

func _process(delta: float) -> void:
	time += delta
	for i in torches.size():
		var t: OmniLight3D = torches[i]
		t.light_energy = 1.8 + sin(time * 13.0 + i * 2.1) * 0.25 + randf() * 0.15
	if portal_rune:
		portal_rune.emission_energy_multiplier = 1.5 + sin(time * 3.0) * 0.8

func _material(c: Color, rough := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _build_floor() -> void:
	var under := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(W + 4, H + 4)
	under.mesh = pm
	under.material_override = _material(Color(0.04, 0.04, 0.05))
	under.position.y = -0.25
	add_child(under)
	floor_mm = MultiMesh.new()
	floor_mm.transform_format = MultiMesh.TRANSFORM_3D
	floor_mm.use_colors = true
	var tile := BoxMesh.new()
	tile.size = Vector3(0.95, 0.3, 0.95)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.8
	tile.material = m
	floor_mm.mesh = tile
	floor_mm.instance_count = int(W * H)
	var i := 0
	for x in int(W):
		for z in int(H):
			var t := Transform3D(Basis(Vector3.UP, randf_range(-0.03, 0.03)), Vector3(-W / 2 + 0.5 + x, -0.15 + randf_range(-0.025, 0.02), -H / 2 + 0.5 + z))
			floor_mm.set_instance_transform(i, t)
			var v := randf_range(0.7, 1.05)
			var c := Color(0.36 * v, 0.37 * v, 0.42 * v)
			if randf() < 0.08:
				c = c.lerp(Color(0.22, 0.32, 0.18), 0.5)
			floor_colors.append(c)
			floor_mm.set_instance_color(i, c)
			i += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = floor_mm
	add_child(mmi)

func _build_walls() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for w in [[Vector3(0, 1.5, -H / 2 - 0.5), Vector3(W + 2, 3, 1)], [Vector3(0, 1.5, H / 2 + 0.5), Vector3(W + 2, 3, 1)],
			[Vector3(-W / 2 - 0.5, 1.5, 0), Vector3(1, 3, H)], [Vector3(W / 2 + 0.5, 1.5, 0), Vector3(1, 3, H)]]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = w[1]
		cs.shape = bs
		cs.position = w[0]
		body.add_child(cs)
	# ladrillos (multimesh)
	var bricks := []
	for x in range(int(-W / 2) - 1, int(W / 2) + 1):
		for row in 6:
			bricks.append(Vector3(x + 0.5 + (0.5 if row % 2 else 0.0), 0.25 + row * 0.5, -H / 2 - 0.5))
		bricks.append(Vector3(x + 0.5, 0.25, H / 2 + 0.5))
		if x % 2 == 0:
			bricks.append(Vector3(x + 0.5, 3.25, -H / 2 - 0.5))
	for z in range(int(-H / 2), int(H / 2)):
		for side in [-1, 1]:
			for row in 6:
				bricks.append(Vector3(side * (W / 2 + 0.5), 0.25 + row * 0.5, z + 0.5 + (0.5 if row % 2 else 0.0)))
			if z % 2 == 0:
				bricks.append(Vector3(side * (W / 2 + 0.5), 3.25, z + 0.5))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var b := BoxMesh.new()
	b.size = Vector3(0.97, 0.46, 0.97)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	b.material = m
	mm.mesh = b
	mm.instance_count = bricks.size()
	for i in bricks.size():
		mm.set_instance_transform(i, Transform3D(Basis(), bricks[i]))
		var v := randf_range(0.65, 1.0)
		var wc := Color(0.48 * v, 0.4 * v, 0.33 * v)
		wall_colors.append(wc)
		mm.set_instance_color(i, wc)
	wall_mm = mm
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)

func _build_torches() -> void:
	for z in [-7.0, 0.0, 7.0]:
		for side in [-1, 1]:
			var x: float = side * (W / 2 - 0.05)
			var holder := MeshInstance3D.new()
			holder.mesh = Rig.cyl(0.06, 0.05, 0.6, 6)
			holder.material_override = _material(Color(0.3, 0.2, 0.12))
			holder.position = Vector3(x - side * 0.15, 1.7, z)
			holder.rotation.z = side * 0.4
			add_child(holder)
			var flame := FX.make_particles(Color(1, 0.5, 0.15), 24, 0.6, 0.07, 0.5, 2.5, false)
			flame.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			flame.emission_sphere_radius = 0.06
			flame.position = Vector3(x - side * 0.27, 2.05, z)
			flame.emitting = true
			add_child(flame)
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.55, 0.2)
			l.omni_range = 7.5
			l.omni_attenuation = 1.4
			l.position = Vector3(x - side * 0.6, 2.2, z)
			if z == 0.0:
				l.shadow_enabled = true
			add_child(l)
			torches.append(l)

func _build_portal() -> void:
	var stone := _material(Color(0.42, 0.38, 0.36))
	var root := Node3D.new()
	root.position = Vector3(0, 0, -H / 2 + 0.2)
	add_child(root)
	for x in [-1.7, 1.7]:
		var p := MeshInstance3D.new()
		p.mesh = Rig.box(0.6, 3.0, 0.6)
		p.material_override = stone
		p.position = Vector3(x, 1.5, 0)
		root.add_child(p)
	var top := MeshInstance3D.new()
	top.mesh = Rig.box(4.2, 0.6, 0.7)
	top.material_override = stone
	top.position = Vector3(0, 3.2, 0)
	root.add_child(top)
	portal_rune = Rig.glow_mat(Color(0.3, 1.0, 0.7), 1.5)
	var rune := MeshInstance3D.new()
	rune.mesh = Rig.sphere(0.16, 4)
	rune.material_override = portal_rune
	rune.position = Vector3(0, 3.2, 0.36)
	root.add_child(rune)
	var plane := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2.8, 2.9)
	plane.mesh = q
	portal_mat = StandardMaterial3D.new()
	portal_mat.albedo_color = Color(0.02, 0.02, 0.04)
	portal_mat.emission_enabled = true
	portal_mat.emission = Color(0, 0, 0)
	plane.material_override = portal_mat
	plane.position = Vector3(0, 1.45, 0.05)
	root.add_child(plane)
	portal_light = OmniLight3D.new()
	portal_light.light_color = Color(0.3, 1.0, 0.7)
	portal_light.omni_range = 9.0
	portal_light.light_energy = 0.0
	portal_light.position = Vector3(0, 1.5, 1.2)
	root.add_child(portal_light)
	portal_fx = FX.make_particles(Color(0.3, 1.0, 0.75), 60, 1.2, 0.05, 1.4, 1.2, false)
	portal_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	portal_fx.emission_box_extents = Vector3(1.3, 1.4, 0.1)
	portal_fx.position = Vector3(0, 1.45, 0.3)
	portal_fx.emitting = false
	root.add_child(portal_fx)

func _build_dust() -> void:
	var d := FX.make_particles(Color(0.8, 0.75, 0.6, 0.5), 90, 0.15, 0.025, 9.0, 0.02, false)
	d.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	d.emission_box_extents = Vector3(W / 2, 1.5, H / 2)
	d.position.y = 1.8
	d.preprocess = 9.0
	d.emitting = true
	add_child(d)

func open_portal() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(portal_light, "light_energy", 3.5, 0.8)
	tw.tween_property(portal_mat, "emission", Color(0.15, 0.9, 0.6), 0.8)
	portal_mat.emission_energy_multiplier = 2.5
	portal_fx.emitting = true
	FX.burst(Vector3(0, 1.5, -H / 2 + 0.6), Color(0.3, 1, 0.7), 50, 6.0, 0.08, 1.0, -2.0)

func close_portal() -> void:
	portal_light.light_energy = 0.0
	portal_mat.emission = Color(0, 0, 0)
	portal_fx.emitting = false

func in_portal(p: Vector3) -> bool:
	return p.z < -H / 2 + 1.25 and abs(p.x) < 1.4

func set_biome(kind: String, env: Environment) -> void:
	if kind == biome:
		return
	biome = kind
	var st: Dictionary = Biome.SETTINGS[kind]
	for i in floor_colors.size():
		var c: Color = floor_colors[i]
		floor_mm.set_instance_color(i, Color(c.r * st.floor.r, c.g * st.floor.g, c.b * st.floor.b))
	for i in wall_colors.size():
		var c: Color = wall_colors[i]
		wall_mm.set_instance_color(i, Color(c.r * st.wall.r, c.g * st.wall.g, c.b * st.wall.b))
	for t in torches:
		t.light_color = st.torch
	if env:
		env.fog_light_color = st.fog
		env.ambient_light_color = st.ambient
		env.background_color = st.bg
	if outside:
		outside.queue_free()
	outside = Biome.build(kind)
	add_child(outside)

func clear_level() -> void:
	for c in level_nodes.get_children():
		c.queue_free()
	obstacles.clear()

func gen_level(level: int) -> void:
	clear_level()
	var n_pillars := 1 + randi() % 3
	for i in n_pillars:
		var pos := _free_spot(2.8)
		if pos != Vector3.INF:
			_pillar(pos)
	for i in 2 + randi() % 4:
		var pos := _free_spot(1.6)
		if pos != Vector3.INF:
			if randf() < 0.5:
				_crate(pos)
			else:
				_barrel(pos)
	for i in 10:
		_bone(Vector3(randf_range(-W / 2 + 0.5, W / 2 - 0.5), 0, randf_range(-H / 2 + 0.5, H / 2 - 0.5)))

func _free_spot(spacing: float) -> Vector3:
	for tries in 30:
		var p := Vector3(randf_range(-W / 2 + 1.5, W / 2 - 1.5), 0, randf_range(-H / 2 + 3.0, H / 2 - 4.0))
		var ok := true
		for o in obstacles:
			if p.distance_to(o.pos) < spacing + o.r:
				ok = false
				break
		if ok and abs(p.x) < 2.5 and p.z < -H / 2 + 4.0:
			ok = false
		if ok:
			return p
	return Vector3.INF

func _static(pos: Vector3, shape: Shape3D, shape_y: float, r: float) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position.y = shape_y
	b.add_child(cs)
	level_nodes.add_child(b)
	b.position = pos
	obstacles.append({"pos": pos, "r": r})
	return b

func _mesh(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi

func _pillar(pos: Vector3) -> void:
	var s := CylinderShape3D.new()
	s.radius = 0.6
	s.height = 3.0
	var b := _static(pos, s, 1.5, 0.6)
	var stone := _material(Color(0.45, 0.42, 0.4))
	_mesh(b, Rig.box(1.3, 0.35, 1.3), stone, Vector3(0, 0.17, 0))
	_mesh(b, Rig.cyl(0.48, 0.52, 2.4, 12), stone, Vector3(0, 1.5, 0))
	_mesh(b, Rig.box(1.3, 0.35, 1.3), stone, Vector3(0, 2.85, 0))
	if randf() < 0.5:
		var moss := _material(Color(0.2, 0.35, 0.15))
		_mesh(b, Rig.cyl(0.53, 0.55, 0.5, 12), moss, Vector3(0, 0.6, 0))

func _crate(pos: Vector3) -> void:
	var s := BoxShape3D.new()
	s.size = Vector3(0.8, 0.8, 0.8)
	var b := _static(pos, s, 0.4, 0.5)
	b.rotation.y = randf() * TAU
	var wood := _material(Color(0.5, 0.33, 0.17))
	_mesh(b, Rig.box(0.8, 0.8, 0.8), wood, Vector3(0, 0.4, 0))
	var dark := _material(Color(0.3, 0.2, 0.1))
	_mesh(b, Rig.box(0.84, 0.1, 0.84), dark, Vector3(0, 0.75, 0))
	_mesh(b, Rig.box(0.84, 0.1, 0.84), dark, Vector3(0, 0.05, 0))

func _barrel(pos: Vector3) -> void:
	var s := CylinderShape3D.new()
	s.radius = 0.38
	s.height = 0.85
	var b := _static(pos, s, 0.42, 0.4)
	_mesh(b, Rig.cyl(0.33, 0.33, 0.85, 14), _material(Color(0.45, 0.28, 0.14)), Vector3(0, 0.42, 0))
	var metal := _material(Color(0.3, 0.3, 0.32), 0.4)
	metal.metallic = 0.8
	for y in [0.15, 0.7]:
		_mesh(b, Rig.cyl(0.36, 0.36, 0.06, 14), metal, Vector3(0, y, 0))

func _bone(pos: Vector3) -> void:
	var bone := _material(Color(0.85, 0.82, 0.72))
	var n := Node3D.new()
	level_nodes.add_child(n)
	n.position = pos
	n.rotation.y = randf() * TAU
	if randf() < 0.3:
		_mesh(n, Rig.sphere(0.12, 10), bone, Vector3(0, 0.1, 0))
	else:
		var c := _mesh(n, Rig.cyl(0.025, 0.025, 0.35, 6), bone, Vector3(0, 0.03, 0))
		c.rotation.z = PI / 2

func random_spawn(avoid: Vector3, min_dist: float) -> Vector3:
	for tries in 40:
		var p := Vector3(randf_range(-W / 2 + 1.2, W / 2 - 1.2), 0, randf_range(-H / 2 + 1.8, H / 2 - 5.0))
		if p.distance_to(avoid) < min_dist:
			continue
		var ok := true
		for o in obstacles:
			if p.distance_to(o.pos) < o.r + 1.0:
				ok = false
				break
		if ok:
			return p
	return Vector3(randf_range(-4, 4), 0, -6)
