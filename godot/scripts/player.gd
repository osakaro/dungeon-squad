extends CharacterBody3D
## Héroe controlado por el jugador: movimiento, auto-ataque y habilidades automáticas con cooldown.

var main
var key := "arquero"
var rig: Rig
var dead := false

var max_hp := 100.0
var hp := 100.0
var dmg := 10.0
var rate := 2.0
var speed := 6.0
var multi := 1
var pierce := 0
var bounce := 0
var diag := 0
var aoe := 1.8
var chain := 0
var melee_range := 2.4
var wave := 0
var lifesteal := 0.0
var thorns := 0.0
var crit := 0.05

var attack_cd := 0.0
var spin_t := 0.0
var spin_tick := 0.0
var shield_t := 0.0
var hurt_t := 0.0
var invuln := 0.0
var abilities := []
var orbs := []
var orb_angle := 0.0
var shield_mesh: MeshInstance3D
var hp_fg: MeshInstance3D
var hp_lbl: Label3D

const KIND := {"arquero": "arrow", "mago": "fire", "asesino": "dagger", "nigromante": "bolt"}

func setup(m, k: String) -> void:
	main = m
	key = k
	var h: Dictionary = GameData.HEROES[k]
	var wl := GameData.wl(k)
	max_hp = h.hp * (1.0 + 0.1 * (wl - 1))
	hp = max_hp
	dmg = h.dmg * (1.0 + 0.2 * (wl - 1))
	rate = h.rate
	speed = h.speed
	if k == "nigromante":
		lifesteal = 0.6
	if k == "asesino":
		crit = 0.2
	for i in h.abilities.size():
		abilities.append({"key": h.abilities[i], "lvl": 1 if i == 0 else 0, "t": 2.0})
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = 0.38
	s.height = 1.0
	cs.shape = s
	cs.position.y = 0.5
	add_child(cs)
	rig = Builder.hero(k)
	add_child(rig)
	if rig is CharModel:
		rig.attack_speed = max(1.2, rate * 0.9)
		rig.run_speed_ref = speed
	shield_mesh = MeshInstance3D.new()
	shield_mesh.mesh = Rig.sphere(1.0, 24)
	var sm := FX.flat_mat(Color(1, 0.75, 0.2, 0.18), 1.5)
	shield_mesh.material_override = sm
	shield_mesh.position.y = 0.9
	shield_mesh.visible = false
	add_child(shield_mesh)
	_build_hp_bar()
	# círculo bajo el héroe
	var ring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.5
	t.outer_radius = 0.58
	ring.mesh = t
	ring.scale = Vector3(1, 0.1, 1)
	ring.position.y = 0.03
	ring.material_override = FX.flat_mat(Color(h.color.r, h.color.g, h.color.b, 0.7), 1.5)
	add_child(ring)

func _build_hp_bar() -> void:
	for i in 2:
		var q := QuadMesh.new()
		q.size = Vector2(1.06, 0.15) if i == 0 else Vector2(1.0, 0.1)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.billboard_keep_scale = true
		m.no_depth_test = true
		m.render_priority = 2 + i
		m.albedo_color = Color(0.05, 0.05, 0.08) if i == 0 else Color(0.35, 0.9, 0.4)
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position.y = 2.25
		add_child(mi)
		if i == 1:
			hp_fg = mi
	hp_lbl = Label3D.new()
	hp_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_lbl.no_depth_test = true
	hp_lbl.font = preload("res://assets/fonts/LilitaOne.ttf")
	hp_lbl.font_size = 34
	hp_lbl.outline_size = 8
	hp_lbl.pixel_size = 0.006
	hp_lbl.position.y = 2.48
	hp_lbl.render_priority = 4
	add_child(hp_lbl)

func cd_of(a: Dictionary) -> float:
	return GameData.ABILITIES[a.key].cd * pow(0.85, max(0, a.lvl - 1))

func _physics_process(delta: float) -> void:
	if dead or main.state != "play":
		if not dead:
			rig.animate(delta, 0.0)
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if main.ui.joy_vec.length() > 0.15:
		input = main.ui.joy_vec
	velocity = Vector3(input.x, 0, input.y) * speed
	move_and_slide()
	global_position.y = 0
	var moving := input.length() > 0.1
	if moving:
		if spin_t <= 0.0:
			rig.rotation.y = lerp_angle(rig.rotation.y, atan2(velocity.x, velocity.z), delta * 14.0)
		attack_cd = min(attack_cd, 0.15)
		if randf() < 0.12:
			FX.burst(global_position + Vector3.UP * 0.05, Color(0.5, 0.48, 0.42), 2, 1.0, 0.06, 0.4, 0.5)
	else:
		attack_cd -= delta
		if attack_cd <= 0.0 and main.nearest_enemy(global_position) != null:
			attack()
			attack_cd = 1.0 / rate
	# habilidades automáticas
	for a in abilities:
		if a.lvl == 0:
			continue
		a.t -= delta
		if a.t <= 0.0 and main.nearest_enemy(global_position) != null:
			if cast(a.key, a.lvl):
				a.t = cd_of(a)
				Sfx.play({"hielo": "ice", "grito": "shout", "sombra": "teleport", "esqueleto": "summon", "drenaje": "drain"}.get(a.key, "cast"), -2.0)
				if rig is CharModel and a.key != "torbellino" and a.key != "sombra":
					rig.cast_anim()
			else:
				a.t = 0.3
	# torbellino
	if spin_t > 0.0:
		spin_t -= delta
		spin_tick -= delta
		if rig is CharModel:
			rig.spin(spin_t > 0.0)
		else:
			rig.rotation.y += delta * 22.0
			rig.arm_r.rotation.x = -1.5
		if spin_tick <= 0.0:
			spin_tick = 0.25
			main.explode(global_position, 2.4, dmg * 0.5, Color(1, 0.95, 0.7), Callable(), false)
			FX.slash(global_position, randf() * TAU, 2.4, Color(1, 0.95, 0.7))
			Sfx.play("slash", -14.0)
	# escudo / daño recibido
	shield_t -= delta
	hurt_t -= delta
	invuln -= delta
	shield_mesh.visible = shield_t > 0.0
	if shield_t > 0.0:
		shield_mesh.rotation.y += delta
	rig.tint(Color(1, 0, 0, 1.2) if hurt_t > 0.0 else Color(0, 0, 0, 0))
	# orbes
	orb_angle += delta * 3.2
	for i in orbs.size():
		var a := orb_angle + i * TAU / orbs.size()
		var o: Node3D = orbs[i]
		o.position = Vector3(sin(a) * 1.8, 0.9, cos(a) * 1.8)
		for e in main.get_enemies():
			if e.is_active() and e.orb_cd <= 0.0 and Vector2(e.global_position.x - o.global_position.x, e.global_position.z - o.global_position.z).length() < e.radius + 0.35:
				e.orb_cd = 0.4
				e.hurt(dmg * 0.45)
	rig.animate(delta, velocity.length())
	hp_fg.scale.x = max(0.001, hp / max_hp)
	hp_lbl.text = str(int(ceil(hp)))

# ---------------- ataque básico ----------------
func attack() -> void:
	var tgt = main.nearest_enemy(global_position)
	if tgt == null:
		return
	var to: Vector3 = tgt.global_position - global_position
	var a := atan2(to.x, to.z)
	if spin_t <= 0.0:
		rig.rotation.y = a
	rig.attack()
	if key == "guerrero":
		FX.slash(global_position, a, melee_range, Color(1, 0.95, 0.75))
		Sfx.play("slash", -12.0)
		for e in main.get_enemies():
			if not e.is_active():
				continue
			var d: Vector3 = e.global_position - global_position
			d.y = 0
			if d.length() < melee_range + e.radius:
				var da: float = abs(angle_difference(atan2(d.x, d.z), a))
				if da < 1.35 or d.length() < 1.0:
					e.hurt(dmg)
		for i in wave:
			var aa := a + (i - (wave - 1) / 2.0) * 0.3
			main.shoot(global_position, Vector3(sin(aa), 0, cos(aa)) * 11.0, {"kind": "wave", "dmg": dmg * 0.6, "pierce": 99, "life": 1.0})
		return
	var sp: float = {"mago": 12.0, "nigromante": 14.0, "asesino": 20.0}.get(key, 19.0)
	var offs := []
	for i in multi:
		offs.append((i - (multi - 1) / 2.0) * 0.14)
	for i in range(1, diag + 1):
		offs.append(i * 0.45)
		offs.append(-i * 0.45)
	for o in offs:
		var d := Vector3(sin(a + o), 0, cos(a + o))
		main.shoot(global_position, d * sp, {"kind": KIND[key], "dmg": dmg, "pierce": pierce, "bounce": bounce,
			"aoe": aoe if key == "mago" else 0.0, "chain": chain if key != "arquero" else 0,
			"life": 0.65 if key == "asesino" else 1.4})

# ---------------- habilidades ----------------
func cast(k: String, l: int) -> bool:
	var tgt = main.nearest_enemy(global_position)
	match k:
		"lluvia":
			if tgt == null:
				return false
			var p: Vector3 = tgt.global_position
			var r := 2.2 + 0.3 * l
			FX.ring(p, r, Color(0.5, 0.8, 1), 0.6)
			for i in 18:
				var off := Vector3(randf_range(-r, r), 0, randf_range(-r, r)) * 0.8
				var arrow := MeshInstance3D.new()
				arrow.mesh = Rig.box(0.05, 0.7, 0.05)
				arrow.material_override = Rig.glow_mat(Color(0.7, 0.9, 1), 3.0)
				main.add_child(arrow)
				arrow.global_position = p + off + Vector3(0, 9, 0)
				var tw := arrow.create_tween()
				tw.tween_interval(i * 0.02)
				tw.tween_property(arrow, "global_position:y", 0.3, 0.35).set_ease(Tween.EASE_IN)
				tw.tween_callback(arrow.queue_free)
			FX._later(0.45, func(): main.explode(p, r, dmg * (2.0 + l), Color(0.5, 0.8, 1)))
		"cargado":
			if tgt == null:
				return false
			var d: Vector3 = tgt.global_position - global_position
			d.y = 0
			main.shoot(global_position, d.normalized() * 28.0, {"kind": "big", "dmg": dmg * (3.0 + l), "pierce": 99})
			FX.burst(global_position + Vector3.UP, Color(0.4, 0.9, 1), 16, 4.0, 0.06, 0.4)
			FX.shake(0.15)
		"meteoro":
			if tgt == null:
				return false
			var p: Vector3 = tgt.global_position
			var r := 2.4 + 0.3 * l
			FX.ring(p, r, Color(1, 0.3, 0.05), 0.9)
			var met := FX.glow_sphere(0.55, Color(1, 0.4, 0.05), 6.0)
			main.add_child(met)
			met.global_position = p + Vector3(4, 12, -4)
			FX.trail(met, Color(1, 0.5, 0.1), 0.25, 60, 0.5)
			var l2 := OmniLight3D.new()
			l2.light_color = Color(1, 0.5, 0.1)
			l2.omni_range = 8.0
			l2.light_energy = 3.0
			met.add_child(l2)
			var tw := met.create_tween()
			tw.tween_property(met, "global_position", p + Vector3(0, 0.3, 0), 0.8).set_ease(Tween.EASE_IN)
			tw.tween_callback(func():
				main.explode(p, r, dmg * (3.0 + l), Color(1, 0.4, 0.05))
				FX.burst(p + Vector3.UP * 0.3, Color(1, 0.5, 0.1), 60, 9.0, 0.14, 0.9)
				FX.burst(p + Vector3.UP * 0.3, Color(0.25, 0.22, 0.2), 25, 3.0, 0.2, 1.4, 1.5)
				FX.shake(0.6)
				met.queue_free())
		"hielo":
			var r := 4.0 + 0.4 * l
			main.explode(global_position, r, dmg * (1.0 + 0.5 * l), Color(0.6, 0.95, 1), func(e): e.slow = 3.0 + l * 0.5)
			FX.burst(global_position + Vector3.UP * 0.5, Color(0.7, 0.95, 1), 50, 9.0, 0.07, 0.6, -1.0)
			FX.shake(0.2)
		"torbellino":
			spin_t = 2.0 + 0.5 * l
			spin_tick = 0.0
		"grito":
			FX.ring(global_position, 5.0, Color(1, 0.6, 0.15), 0.6)
			FX.ring(global_position, 3.5, Color(1, 0.6, 0.15), 0.45)
			for e in main.get_enemies():
				if e.is_active() and e.global_position.distance_to(global_position) < 5.0 + e.radius:
					e.stun = 1.5 + 0.3 * l
					var away: Vector3 = e.global_position - global_position
					e.knock = away.normalized() * 6.0
			shield_t = 3.0 + l
			FX.burst(global_position + Vector3.UP, Color(1, 0.8, 0.3), 30, 5.0, 0.06, 0.5, 0)
			FX.shake(0.35)
		"abanico":
			var n := 10 + 2 * l
			for i in n:
				var a := i * TAU / n
				main.shoot(global_position, Vector3(sin(a), 0, cos(a)) * 16.0, {"kind": "dagger", "dmg": dmg * 1.3, "pierce": 1, "life": 0.8})
		"sombra":
			if tgt == null:
				return false
			var tp: Vector3 = tgt.global_position
			FX.burst(global_position + Vector3.UP * 0.8, Color(0.6, 0.2, 1), 26, 3.0, 0.09, 0.6, 1.0)
			var d: Vector3 = tp - global_position
			d.y = 0
			var dest: Vector3 = tp + d.normalized() * (tgt.radius + 0.8)
			var q := PhysicsRayQueryParameters3D.create(tp + Vector3.UP * 0.5, dest + Vector3.UP * 0.5, 1)
			if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
				global_position = dest
			rig.rotation.y = atan2(-d.x, -d.z)
			rig.attack()
			tgt.hurt(dmg * (5.0 + 2.0 * l), true)
			FX.burst(global_position + Vector3.UP * 0.8, Color(0.6, 0.2, 1), 26, 3.0, 0.09, 0.6, 1.0)
			FX.slash(global_position, rig.rotation.y, 1.6, Color(0.7, 0.3, 1))
			FX.shake(0.2)
		"esqueleto":
			for i in 1 + l / 2:
				var a := randf() * TAU
				main.spawn_minion(global_position + Vector3(cos(a), 0, sin(a)) * 1.5, dmg * 0.8, 12.0)
		"drenaje":
			var n := 0
			for e in main.get_enemies():
				if e.is_active() and e.global_position.distance_to(global_position) < 6.0:
					FX.beam(global_position, e.global_position, Color(0.4, 1, 0.5))
					e.hurt(dmg * (1.0 + 0.5 * l))
					n += 1
			if n == 0:
				return false
			heal(4.0 * n)
			FX.ring(global_position, 6.0, Color(0.4, 1, 0.5))
	return true

# ---------------- vida ----------------
func on_hit() -> void:
	if lifesteal > 0.0:
		hp = min(max_hp, hp + lifesteal)

func heal(v: float) -> void:
	hp = min(max_hp, hp + v)
	FX.number(global_position, v, Color(0.4, 1, 0.5))
	FX.burst(global_position + Vector3.UP, Color(0.4, 1, 0.5), 12, 2.0, 0.06, 0.6, 2.0)

func take_damage(d: float) -> void:
	if dead or invuln > 0.0:
		return
	if shield_t > 0.0:
		d *= 0.4
	hp -= d
	hurt_t = 0.15
	invuln = 0.2
	Sfx.play("hurt", -8.0)
	FX.number(global_position, d, Color(1, 0.3, 0.3))
	FX.shake(0.18)
	if hp <= 0.0:
		hp = 0.0
		dead = true
		FX.burst(global_position + Vector3.UP, Color(0.9, 0.1, 0.1), 40, 5.0, 0.08, 0.9)
		rig.tint(Color(0, 0, 0, 0))
		if rig is CharModel:
			rig.die()
		else:
			var tw := rig.create_tween()
			tw.tween_property(rig, "rotation:x", -PI / 2, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		main.on_player_died()

## Máximo de veces que se puede coger cada mejora
const PASSIVE_MAX := {"multi": 3, "pierce": 2, "bounce": 2, "diag": 2, "aoe": 3, "chain": 3, "orb": 3, "arc": 2,
	"wave": 3, "lifesteal": 3, "thorns": 3, "crit": 3, "spdpas": 2, "dmg": 6, "rate": 4, "hp": 6, "spd": 3}
const ABILITY_MAX := 5
var taken := {}

func can_take(p: String) -> bool:
	return int(taken.get(p, 0)) < int(PASSIVE_MAX.get(p, 99))

func apply_passive(p: String) -> void:
	taken[p] = int(taken.get(p, 0)) + 1
	match p:
		"multi": multi += 1
		"pierce": pierce += 1
		"bounce": bounce += 1
		"diag": diag += 1
		"aoe": aoe *= 1.5
		"chain": chain += 1
		"orb": add_orb()
		"arc": melee_range *= 1.4
		"wave": wave += 1
		"lifesteal": lifesteal += 1.5
		"thorns": thorns += 15.0
		"crit": crit += 0.15
		"spdpas":
			speed *= 1.2
			rate *= 1.1
		"dmg": dmg *= 1.3
		"rate": rate *= 1.25
		"hp":
			max_hp += 25.0
			hp += 25.0
		"heal": hp = min(max_hp, hp + max_hp * 0.5)
		"spd": speed *= 1.15

func add_orb() -> void:
	var c: Color = Color(0.4, 1, 0.5) if key == "nigromante" else Color(0.7, 0.5, 1)
	var o := FX.glow_sphere(0.2, c, 5.0)
	var l := OmniLight3D.new()
	l.light_color = c
	l.omni_range = 2.5
	o.add_child(l)
	add_child(o)
	FX.trail(o, c, 0.06, 20, 0.3)
	orbs.append(o)
