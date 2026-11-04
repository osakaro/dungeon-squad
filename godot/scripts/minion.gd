extends CharacterBody3D
## Esqueleto invocado por el Nigromante.

var main
var rig: Rig
var life := 12.0
var hit_cd := 0.0
var dmg := 10.0

func setup(m, damage: float, duration: float) -> void:
	main = m
	dmg = damage
	life = duration
	add_to_group("minions")
	collision_layer = 8
	collision_mask = 1
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = 0.3
	s.height = 1.0
	cs.shape = s
	cs.position.y = 0.5
	add_child(cs)
	rig = Builder.enemy("skel")
	add_child(rig)
	if rig is CharModel:
		rig.spawn()
	else:
		rig.position.y = -1.2
		create_tween().tween_property(rig, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	if main.state != "play":
		return
	life -= delta
	hit_cd -= delta
	if life <= 0.0:
		FX.burst(global_position + Vector3.UP * 0.6, Color(0.9, 0.9, 0.8), 14, 3.0, 0.06, 0.5)
		queue_free()
		return
	var t = main.nearest_enemy(global_position)
	velocity = Vector3.ZERO
	if t:
		var to: Vector3 = t.global_position - global_position
		to.y = 0
		var d := to.length()
		rig.rotation.y = atan2(to.x, to.z)
		if d > t.radius + 0.55:
			velocity = to / d * 5.0
		elif hit_cd <= 0.0:
			hit_cd = 0.6
			rig.attack()
			t.hurt(dmg)
	move_and_slide()
	global_position.y = 0
	rig.animate(delta, velocity.length())
