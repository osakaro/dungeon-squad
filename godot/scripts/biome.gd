class_name Biome
## Paisaje exterior de cada capítulo (lo que se ve alrededor de la mazmorra) y su ambientación.

const SETTINGS := {
	"forest": {"floor": Color(0.85, 1.0, 0.8), "wall": Color(0.75, 0.9, 0.7), "torch": Color(1.0, 0.6, 0.25),
		"fog": Color(0.05, 0.1, 0.06), "ambient": Color(0.5, 0.65, 0.5), "bg": Color(0.03, 0.06, 0.04),
		"ground": [Color(0.08, 0.2, 0.06), Color(0.2, 0.38, 0.12)]},
	"ice": {"floor": Color(0.95, 1.0, 1.08), "wall": Color(0.9, 0.97, 1.08), "torch": Color(0.5, 0.8, 1.0),
		"fog": Color(0.35, 0.45, 0.6), "ambient": Color(0.6, 0.7, 0.9), "bg": Color(0.12, 0.16, 0.25),
		"ground": [Color(0.7, 0.78, 0.9), Color(0.95, 0.97, 1.0)]},
	"lava": {"floor": Color(0.85, 0.78, 0.75), "wall": Color(0.6, 0.45, 0.4), "torch": Color(1.0, 0.4, 0.1),
		"fog": Color(0.09, 0.03, 0.02), "ambient": Color(0.6, 0.48, 0.42), "bg": Color(0.06, 0.02, 0.01),
		"ground": [Color(0.04, 0.03, 0.03), Color(0.18, 0.1, 0.08)]},
}

static var _rng := RandomNumberGenerator.new()

static func _mat(c: Color, rough := 0.85, emission := Color(0, 0, 0), e := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if e > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = e
	return m

## Posiciones aleatorias fuera de la zona de juego
static func _spots(n: int, min_gap := 0.0) -> Array:
	var res := []
	var tries := 0
	while res.size() < n and tries < n * 20:
		tries += 1
		var p := Vector3(_rng.randf_range(-30, 30), 0, _rng.randf_range(-30, 24))
		if abs(p.x) < 8.8 + min_gap and abs(p.z) < 12.4 + min_gap:
			continue
		res.append(p)
	return res

static func _multi(parent: Node3D, mesh: Mesh, mat: Material, xforms: Array, colors := []) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors.size() > 0
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	parent.add_child(mmi)

static func _vc_mat(rough := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = rough
	return m

static func _ground(parent: Node3D, cols: Array) -> void:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(90, 90)
	g.mesh = pm
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	var n := FastNoiseLite.new()
	n.frequency = 0.02
	tex.noise = n
	var grad := Gradient.new()
	grad.set_color(0, cols[0])
	grad.set_color(1, cols[1])
	tex.color_ramp = grad
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = Vector3(3, 3, 3)
	m.roughness = 0.95
	g.material_override = m
	g.position = Vector3(0, -0.28, -3)
	parent.add_child(g)

static func _particles(parent: Node3D, color: Color, amount: int, size: float, life: float, grav: float, vel: float, pos: Vector3, ext: Vector3) -> void:
	var p := FX.make_particles(color, amount, vel, size, life, grav, false)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = ext
	p.position = pos
	p.preprocess = life
	p.damping_min = 0.0
	p.damping_max = 0.0
	parent.add_child(p)
	p.emitting = true

static func build(kind: String) -> Node3D:
	_rng.seed = hash(kind)
	var root := Node3D.new()
	var st: Dictionary = SETTINGS[kind]
	_ground(root, st.ground)
	match kind:
		"forest": _forest(root)
		"ice": _ice(root)
		"lava": _lava(root)
	return root

static func _forest(root: Node3D) -> void:
	var trunks := []
	var leaves := []
	var leaf_cols := []
	for p in _spots(170):
		var s := _rng.randf_range(0.8, 1.6)
		var rot := Basis(Vector3.UP, _rng.randf() * TAU)
		trunks.append(Transform3D(rot.scaled(Vector3(s, s, s)), p + Vector3(0, 1.0 * s, 0)))
		for k in 3:
			leaves.append(Transform3D(rot.scaled(Vector3.ONE * s * (1.0 - k * 0.22)), p + Vector3(0, (2.0 + k * 0.9) * s, 0)))
			leaf_cols.append(Color(0.1, 0.32 + _rng.randf() * 0.2, 0.08).lightened(k * 0.06))
	_multi(root, Rig.cyl(0.18, 0.28, 2.0, 7), _mat(Color(0.3, 0.2, 0.12)), trunks)
	_multi(root, Rig.cyl(0.0, 1.3, 1.6, 8), _vc_mat(), leaves, leaf_cols)
	var bushes := []
	var bcols := []
	for p in _spots(120):
		var s := _rng.randf_range(0.4, 0.9)
		bushes.append(Transform3D(Basis().scaled(Vector3(s * 1.3, s, s * 1.3)), p + Vector3(0, s * 0.3, 0)))
		bcols.append(Color(0.12, 0.35 + _rng.randf() * 0.15, 0.1))
	_multi(root, Rig.sphere(0.7, 8), _vc_mat(), bushes, bcols)
	var shrooms := []
	for p in _spots(40):
		shrooms.append(Transform3D(Basis(), p + Vector3(0, 0.15, 0)))
	_multi(root, Rig.sphere(0.16, 8), _mat(Color(0.3, 0.9, 1.0), 0.5, Color(0.2, 0.8, 1.0), 2.5), shrooms)
	_particles(root, Color(0.8, 1.0, 0.3), 90, 0.05, 6.0, 0.0, 0.4, Vector3(0, 2, -3), Vector3(28, 2, 28))

static func _ice(root: Node3D) -> void:
	var pines := []
	var snow := []
	for p in _spots(140):
		var s := _rng.randf_range(0.8, 1.7)
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * s)
		pines.append(Transform3D(b, p + Vector3(0, 1.5 * s, 0)))
		snow.append(Transform3D(b, p + Vector3(0, 2.6 * s, 0)))
	_multi(root, Rig.cyl(0.0, 1.0, 3.0, 8), _mat(Color(0.08, 0.22, 0.2)), pines)
	_multi(root, Rig.cyl(0.0, 0.55, 1.0, 8), _mat(Color(0.95, 0.97, 1.0), 0.6), snow)
	var crystals := []
	for p in _spots(45):
		var s := _rng.randf_range(0.6, 1.6)
		crystals.append(Transform3D(Basis(Vector3(_rng.randf(), 1, _rng.randf()).normalized(), _rng.randf() * 0.5).scaled(Vector3(s * 0.5, s * 1.6, s * 0.5)), p + Vector3(0, s * 0.6, 0)))
	_multi(root, Rig.sphere(0.6, 4), _mat(Color(0.6, 0.9, 1.0), 0.1, Color(0.3, 0.7, 1.0), 1.8), crystals)
	var rocks := []
	for p in _spots(60):
		var s := _rng.randf_range(0.4, 1.2)
		rocks.append(Transform3D(Basis().scaled(Vector3(s * 1.4, s * 0.7, s)), p))
	_multi(root, Rig.sphere(0.8, 6), _mat(Color(0.85, 0.9, 1.0), 0.7), rocks)
	_particles(root, Color(1, 1, 1), 400, 0.05, 7.0, -1.2, 0.3, Vector3(0, 10, -3), Vector3(30, 1, 30))

static func _lava(root: Node3D) -> void:
	var lava := _mat(Color(1.0, 0.35, 0.05), 0.4, Color(1.0, 0.3, 0.02), 3.0)
	for p in _spots(14, 2.0):
		var pool := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var r := _rng.randf_range(1.5, 4.0)
		cm.top_radius = r
		cm.bottom_radius = r
		cm.height = 0.05
		cm.radial_segments = 14
		pool.mesh = cm
		pool.material_override = lava
		pool.position = p + Vector3(0, -0.24, 0)
		pool.scale = Vector3(1, 1, _rng.randf_range(0.6, 1.2))
		root.add_child(pool)
		if _rng.randf() < 0.5:
			var l := OmniLight3D.new()
			l.light_color = Color(1, 0.4, 0.1)
			l.omni_range = r * 2.5
			l.light_energy = 1.5
			l.position = p + Vector3(0, 1, 0)
			root.add_child(l)
	var rocks := []
	var rcols := []
	for p in _spots(150):
		var s := _rng.randf_range(0.5, 1.8)
		rocks.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.6, 1.4), s)), p + Vector3(0, s * 0.3, 0)))
		rcols.append(Color(0.1, 0.08, 0.08).lightened(_rng.randf() * 0.1))
	_multi(root, Rig.sphere(0.8, 5), _vc_mat(), rocks, rcols)
	var spikes := []
	for p in _spots(60):
		var s := _rng.randf_range(0.8, 2.5)
		spikes.append(Transform3D(Basis(Vector3(_rng.randf() - 0.5, 1, _rng.randf() - 0.5).normalized(), 0.2).scaled(Vector3(s * 0.5, s, s * 0.5)), p + Vector3(0, s * 0.8, 0)))
	_multi(root, Rig.cyl(0.0, 0.6, 1.8, 6), _mat(Color(0.12, 0.08, 0.07)), spikes)
	_particles(root, Color(1.0, 0.5, 0.1), 160, 0.05, 5.0, 1.0, 0.5, Vector3(0, 0.5, -3), Vector3(30, 0.5, 30))
