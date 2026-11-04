extends CharacterBody3D
## Enemigos: slime, murciélago, cristal, orco (bruto) y demonio (jefe).

# tipo: [radio, vida, velocidad, daño, monedas, altura barra]
const STATS := {
	"slime": [0.45, 30.0, 2.6, 10.0, 3, 1.3],
	"bat": [0.35, 16.0, 4.4, 7.0, 3, 1.9],
	"crystal": [0.5, 26.0, 0.0, 9.0, 4, 2.0],
	"brute": [0.6, 95.0, 1.7, 18.0, 9, 3.0],
	"boss": [1.1, 650.0, 1.4, 25.0, 60, 4.8],
	"skeleton": [0.4, 40.0, 2.5, 12.0, 4, 2.1],
}

var main
var type := "slime"
var radius := 0.45
var hp := 30.0
var max_hp := 30.0
var speed := 2.0
var dmg := 10.0
var coins := 3
var rig: Rig
var bar_fg: MeshInstance3D
var t := 0.0
var stun := 0.0
var slow := 0.0
var flash := 0.0
var hit_cd := 0.0
var orb_cd := 0.0
var spawn_t := 0.8
var dead := false
var mode := "chase"
var mode_t := 0.0
var charge_dir := Vector3.ZERO
var pattern := 0
var knock := Vector3.ZERO

func setup(m, _type: String, level: int, delay := 0.0) -> void:
	main = m
	type = _type
	var s: Array = STATS[type]
	var sc := 1.0 + 0.3 * (level - 1)
	radius = s[0]
	max_hp = s[1] * sc
	hp = max_hp
	speed = s[2]
	dmg = s[3] * (1.0 + 0.15 * (level - 1))
	coins = s[4] + level / 2
	spawn_t = 0.8 + delay
	t = randf() * 2.0
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 5
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = 1.0
	cs.shape = sh
	cs.position.y = 0.5
	add_child(cs)
	rig = Builder.enemy(type)
	add_child(rig)
	if rig is CharModel:
		rig.spawn()
		spawn_t += 0.6
	else:
		rig.position.y = -2.0
	_build_bar(s[5])

func _build_bar(h: float) -> void:
	var w := 2.4 if type == "boss" else 1.0
	for i in 2:
		var q := QuadMesh.new()
		q.size = Vector2(w + (0.08 if i == 0 else 0.0), 0.14 if i == 0 else 0.1)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.billboard_keep_scale = true
		m.no_depth_test = true
		m.albedo_color = Color(0.05, 0.02, 0.02) if i == 0 else Color(1, 0.2, 0.25)
		m.render_priority = i
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position.y = h
		add_child(mi)
		if i == 1:
			bar_fg = mi
	bar_fg.visible = false
	get_child(get_child_count() - 2).visible = false

func is_active() -> bool:
	return not dead and spawn_t <= 0.0

func _physics_process(delta: float) -> void:
	if dead or main.state != "play":
		return
	if spawn_t > 0.0:
		spawn_t -= delta
		rig.position.y = lerp(rig.position.y, 0.0, delta * 8.0)
		if spawn_t <= 0.0:
			rig.position.y = 0.0
			bar_fg.visible = true
			get_child(get_child_count() - 2).visible = true
		return
	var p = main.player
	if p == null:
		return
	t += delta
	stun -= delta
	slow -= delta
	flash -= delta
	hit_cd -= delta
	orb_cd -= delta
	var tint := Color(0, 0, 0, 0)
	if flash > 0.0:
		tint = Color(1, 1, 1, 1.5)
	elif mode == "windup":
		tint = Color(1, 0.1, 0, 0.6 + sin(t * 30.0) * 0.4)
	elif stun > 0.0:
		tint = Color(1, 0.9, 0.2, 0.5)
	elif slow > 0.0:
		tint = Color(0.3, 0.7, 1.0, 0.6)
	rig.tint(tint)
	bar_fg.scale.x = max(0.001, hp / max_hp)
	if stun > 0.0:
		velocity = knock
		knock = knock.lerp(Vector3.ZERO, delta * 10.0)
		move_and_slide()
		rig.animate(delta, 0.0)
		return
	var to: Vector3 = p.global_position - global_position
	to.y = 0
	var d: float = max(to.length(), 0.01)
	var dir := to / d
	var sm := 0.4 if slow > 0.0 else 1.0
	var face := dir
	match type:
		"slime":
			velocity = dir * speed * sm
			var b: float = abs(sin(t * 6.0))
			rig.bob_node.position.y = b * 0.3
			rig.bob_node.scale = Vector3(1.0 + (1.0 - b) * 0.15, 0.85 + b * 0.2, 1.0 + (1.0 - b) * 0.15)
		"bat":
			var side := Vector3(-dir.z, 0, dir.x) * sin(t * 3.0) * 1.2
			velocity = (dir + side).normalized() * speed * sm
			rig.bob_node.position.y = 1.2 + sin(t * 5.0) * 0.2
		"crystal":
			velocity = Vector3.ZERO
			rig.bob_node.rotation.y += delta * 2.0
			rig.bob_node.position.y = 1.0 + sin(t * 3.0) * 0.15
			if t > 2.4 / sm:
				t = 0.0
				var shots := 3 if main.level > 3 else 1
				for i in shots:
					var a := atan2(dir.x, dir.z) + (i - (shots - 1) / 2.0) * 0.25
					main.shoot(global_position, Vector3(sin(a), 0, cos(a)) * 7.0, {"kind": "ebul", "enemy": true, "dmg": dmg})
				FX.burst(global_position + Vector3.UP, Color(0.7, 0.3, 1), 8, 2.0, 0.05, 0.3)
		"brute":
			mode_t -= delta
			match mode:
				"chase":
					velocity = dir * speed * sm
					if mode_t <= 0.0 and d < 8.0:
						mode = "windup"
						mode_t = 0.7
				"windup":
					velocity = Vector3.ZERO
					charge_dir = dir
					if rig.arm_r:
						rig.arm_r.rotation.x = -2.2
					if mode_t <= 0.0:
						mode = "charge"
						Sfx.play("shout", -4.0)
						if rig is CharModel:
							rig.action(rig.anim_cast, 1.3)
						mode_t = 0.55
				"charge":
					velocity = charge_dir * 12.0 * sm
					face = charge_dir
					if randf() < 0.5:
						FX.burst(global_position + Vector3.UP * 0.1, Color(0.6, 0.5, 0.4), 2, 1.5, 0.08, 0.4, 0)
					if mode_t <= 0.0:
						mode = "chase"
						mode_t = 3.0
		"boss":
			var enraged := hp < max_hp * 0.5
			velocity = dir * speed * sm * (1.4 if enraged else 1.0)
			mode_t -= delta
			if mode == "spiral":
				velocity = Vector3.ZERO
				if fmod(t, 0.08) < delta:
					for k in 2:
						var a := t * 4.0 + k * PI
						main.shoot(global_position, Vector3(sin(a), 0, cos(a)) * 6.0, {"kind": "ebul", "enemy": true, "dmg": dmg * 0.4})
				if mode_t <= 0.0:
					mode = "chase"
					mode_t = 1.5
			elif mode_t <= 0.0:
				pattern = (pattern + 1) % 3
				rig.attack()
				FX.shake(0.25)
				match pattern:
					0:
						var n: int = 14 + main.level
						for i in n:
							var a := i * TAU / n + t
							main.shoot(global_position, Vector3(sin(a), 0, cos(a)) * 6.5, {"kind": "ebul", "enemy": true, "dmg": dmg * 0.5})
						FX.ring(global_position, 3.0, Color(1, 0.2, 0.3))
						mode_t = 2.2 if enraged else 3.0
					1:
						mode = "spiral"
						mode_t = 1.6
					2:
						if rig is CharModel:
							rig.cast_anim()
						if main.get_enemies().size() < 10:
							for i in 3:
								var a := randf() * TAU
								main.spawn_enemy("skeleton", global_position + Vector3(cos(a), 0, sin(a)) * 2.0, 0.0)
						FX.ring(global_position, 2.5, Color(0.6, 0.2, 1))
						mode_t = 2.0
	velocity += knock
	knock = knock.lerp(Vector3.ZERO, delta * 10.0)
	move_and_slide()
	global_position.y = 0
	rig.rotation.y = lerp_angle(rig.rotation.y, atan2(face.x, face.z), delta * 10.0)
	if type != "crystal":
		rig.animate(delta, velocity.length())
	if d < radius + 0.45 and hit_cd <= 0.0:
		hit_cd = 0.8
		if rig is CharModel and mode != "charge":
			rig.attack()
		p.take_damage(dmg)
		if p.thorns > 0.0:
			hurt(p.thorns)

func hurt(amount: float, force_crit := false) -> void:
	if not is_active():
		return
	var p = main.player
	var crit: bool = force_crit or (p != null and randf() < p.crit)
	if crit:
		amount *= 2.2
	hp -= amount
	flash = 0.1
	Sfx.play("crit" if crit else "hit", -6.0 if crit else -10.0)
	if rig is CharModel and type != "boss" and randf() < 0.3:
		rig.hit()
	FX.number(global_position + Vector3.UP * (1.5 if type == "boss" else 0.0), amount, Color(1, 0.85, 0.2) if crit else Color.WHITE, crit)
	if p:
		p.on_hit()
		if type != "boss" and type != "crystal":
			var away: Vector3 = global_position - p.global_position
			away.y = 0
			knock = away.normalized() * (4.0 if crit else 2.0)
	if hp <= 0.0:
		die()

func die() -> void:
	if dead:
		return
	dead = true
	remove_from_group("enemies")
	var c: Color = {"slime": Color(0.3, 0.9, 0.45), "bat": Color(0.5, 0.2, 0.6), "crystal": Color(0.7, 0.3, 1),
		"brute": Color(0.5, 0.35, 0.2), "boss": Color(0.4, 0.8, 1.0), "skeleton": Color(0.9, 0.9, 0.8)}[type]
	FX.burst(global_position + Vector3.UP * 0.6, c, 60 if type == "boss" else 22, 6.0 if type == "boss" else 4.5, 0.1, 0.8)
	if type == "boss":
		FX.shake(0.8)
		FX.ring(global_position, 5.0, Color(1, 0.5, 0.1), 0.8)
		main.hit_stop(0.25)
	main.spawn_coins(global_position, coins)
	Sfx.play("roar" if type == "boss" else "kill", 0.0 if type == "boss" else -6.0)
	if rig is CharModel:
		var xf := rig.global_transform
		remove_child(rig)
		main.add_child(rig)
		rig.global_transform = xf
		rig.tint(Color(0, 0, 0, 0))
		rig.die()
		var r := rig
		main.get_tree().create_timer(1.8, false).timeout.connect(func(): if is_instance_valid(r): r.queue_free())
	queue_free()
