extends Node3D
## Proyectil (del jugador o enemigo). Usa raycasts contra los muros y distancia contra criaturas.

var main
var vel := Vector3.ZERO
var dmg := 10.0
var pierce := 0
var bounce := 0
var aoe := 0.0
var chain := 0
var enemy := false
var life := 3.0
var kind := "arrow"
var hit := []
var spin_node: Node3D
var done := false

const COLORS := {"arrow": Color(1, 1, 0.9), "fire": Color(1, 0.45, 0.1), "dagger": Color(0.85, 0.9, 1),
	"bolt": Color(0.35, 1, 0.5), "ebul": Color(1, 0.2, 0.6), "wave": Color(1, 0.85, 0.4), "big": Color(0.4, 0.9, 1)}

func setup(m, opts: Dictionary) -> void:
	main = m
	for k in opts:
		set(k, opts[k])
	add_to_group("projectiles")
	_build()

func _build() -> void:
	var c: Color = COLORS[kind]
	match kind:
		"arrow", "big":
			var s := 1.0 if kind == "arrow" else 2.2
			var shaft := MeshInstance3D.new()
			shaft.mesh = Rig.box(0.04 * s, 0.04 * s, 0.7 * s)
			shaft.material_override = Rig.glow_mat(Color(0.6, 0.45, 0.3), 0.3) if kind == "arrow" else Rig.glow_mat(c, 4.0)
			add_child(shaft)
			var tip := MeshInstance3D.new()
			tip.mesh = Rig.cyl(0.0, 0.06 * s, 0.16 * s, 4)
			tip.rotation.x = PI / 2
			tip.position.z = 0.4 * s
			tip.material_override = Rig.glow_mat(c, 2.0)
			add_child(tip)
			FX.trail(self, c, 0.03 * s, 16, 0.2)
		"fire":
			add_child(FX.glow_sphere(0.22, c, 5.0))
			var l := OmniLight3D.new()
			l.light_color = c
			l.omni_range = 3.0
			l.light_energy = 1.5
			add_child(l)
			FX.trail(self, c, 0.1, 30, 0.35)
		"dagger":
			spin_node = Node3D.new()
			add_child(spin_node)
			var b := MeshInstance3D.new()
			b.mesh = Rig.box(0.05, 0.02, 0.42)
			b.material_override = Rig.glow_mat(c, 1.2)
			spin_node.add_child(b)
			FX.trail(self, Color(0.7, 0.3, 1), 0.03, 12, 0.15)
		"bolt":
			add_child(FX.glow_sphere(0.17, c, 5.0))
			FX.trail(self, c, 0.08, 30, 0.4)
		"ebul":
			add_child(FX.glow_sphere(0.17, c, 4.0))
			FX.trail(self, c, 0.06, 12, 0.2)
		"wave":
			var w := MeshInstance3D.new()
			w.mesh = Rig.box(1.3, 0.12, 0.25)
			var m := FX.flat_mat(c, 2.0)
			m.albedo_color.a = 0.75
			w.material_override = m
			add_child(w)

func orient() -> void:
	if vel.length() > 0.01:
		rotation.y = atan2(vel.x, vel.z)

func _physics_process(delta: float) -> void:
	if done or main.state != "play":
		return
	life -= delta
	if life <= 0.0:
		_end(false)
		return
	if spin_node:
		spin_node.rotation.y += delta * 25.0
	var from := global_position
	var to := from + vel * delta
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	if r:
		if bounce > 0 and not enemy:
			bounce -= 1
			life = min(life, 0.7)
			vel = vel.bounce(r.normal)
			vel.y = 0
			global_position = r.position + r.normal * 0.05
			orient()
			return
		global_position = r.position
		_end(true)
		return
	global_position = to
	if enemy:
		var p = main.player
		if p and not p.dead and _flat(p.global_position) < 0.5:
			p.take_damage(dmg)
			_end(true)
		return
	for e in main.get_enemies():
		if e in hit or not e.is_active():
			continue
		if _flat(e.global_position) < e.radius + 0.25:
			hit.append(e)
			if aoe > 0.0:
				main.explode(global_position, aoe, dmg, COLORS.fire)
			else:
				e.hurt(dmg)
			if chain > 0:
				var n = main.nearest_enemy(global_position, hit, 7.0)
				if n:
					var d: Vector3 = n.global_position - global_position
					d.y = 0
					vel = d.normalized() * vel.length()
					orient()
					chain -= 1
					life = 0.9
					FX.burst(global_position, COLORS[kind], 8, 3.0, 0.05, 0.3)
					return
			if aoe > 0.0 or pierce <= 0:
				_end(true, aoe <= 0.0)
				return
			pierce -= 1

func _flat(p: Vector3) -> float:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()

func _end(impact: bool, sparks := true) -> void:
	if done:
		return
	done = true
	if impact and sparks:
		FX.burst(global_position, COLORS[kind], 8, 3.0, 0.05, 0.3)
	if impact and aoe > 0.0 and not enemy and hit.is_empty():
		main.explode(global_position, aoe, dmg, COLORS.fire)
	queue_free()
