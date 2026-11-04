class_name Rig
extends Node3D
## Modelo articulado construido por código (cuerpo, brazos, piernas) con animación procedural.

var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var hand_l: Node3D
var hand_r: Node3D
var head: Node3D
var body: Node3D
var cape: Node3D
var wing_l: Node3D
var wing_r: Node3D
var bob_node: Node3D
var mats: Array = []
var _base := {}
var _tint := Color(0, 0, 0, 0)
var attack_t := 0.0
var phase := 0.0
var time := 0.0

# ---------- helpers de construcción ----------
static func box(x: float, y: float, z: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(x, y, z)
	return m

static func sphere(r: float, seg := 16) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = seg
	m.rings = max(4, seg / 2)
	return m

static func cyl(top: float, bottom: float, h: float, seg := 12) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	return m

func mat(c: Color, rough := 0.75, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	mats.append(m)
	return m

static func glow_mat(c: Color, energy := 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m

func part(mesh: Mesh, m: Material, pos: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	(parent if parent else self).add_child(mi)
	return mi

func pivot(pos: Vector3, parent: Node3D = null) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	(parent if parent else self).add_child(p)
	return p

func glow_light(parent: Node3D, c: Color, r: float, pos: Vector3, light_range := 3.0) -> MeshInstance3D:
	var g := part(sphere(r, 12), glow_mat(c, 4.0), pos, parent)
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 1.2
	l.omni_range = light_range
	g.add_child(l)
	return g

# ---------- animación ----------
func attack() -> void:
	attack_t = 0.25

func animate(delta: float, speed: float) -> void:
	time += delta
	if wing_l:
		var f := sin(time * 18.0) * 0.7
		wing_l.rotation.z = f
		wing_r.rotation.z = -f
	if cape:
		cape.rotation.x = 0.15 + min(speed / 6.0, 1.0) * 0.5 + sin(time * 6.0) * 0.06
	if leg_l == null:
		return
	var amount: float = clamp(speed / 5.0, 0.0, 1.0)
	if amount > 0.05:
		phase += delta * (6.0 + speed * 1.6)
	else:
		phase = lerp(phase, round(phase / PI) * PI, delta * 10.0)
	var s := sin(phase) * 0.75 * amount
	leg_l.rotation.x = s
	leg_r.rotation.x = -s
	arm_l.rotation.x = -s * 0.8
	if attack_t > 0.0:
		attack_t -= delta
		arm_r.rotation.x = -1.7 * (attack_t / 0.25)
	else:
		arm_r.rotation.x = lerp(arm_r.rotation.x, s * 0.8, delta * 12.0)
	if body:
		body.scale.y = 1.0 + sin(time * 2.5) * 0.02 * (1.0 - amount)
		body.position.y = 0.92 + abs(sin(phase)) * 0.04 * amount

func tint(c: Color) -> void:
	if c == _tint:
		return
	_tint = c
	for m in mats:
		if not _base.has(m):
			_base[m] = [m.emission_enabled, m.emission, m.emission_energy_multiplier]
		if c.a > 0.0:
			m.emission_enabled = true
			m.emission = Color(c.r, c.g, c.b)
			m.emission_energy_multiplier = c.a * 2.0
		else:
			m.emission_enabled = _base[m][0]
			m.emission = _base[m][1]
			m.emission_energy_multiplier = _base[m][2]
