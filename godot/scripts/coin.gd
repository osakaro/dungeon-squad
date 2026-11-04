extends Node3D
## Moneda que salta al morir un enemigo y luego vuela hacia el jugador.

var main
var value := 1
var vel := Vector3.ZERO
var age := 0.0
var mesh: MeshInstance3D

func setup(m, v: int) -> void:
	main = m
	value = v
	add_to_group("coins")
	mesh = MeshInstance3D.new()
	mesh.mesh = Rig.cyl(0.14, 0.14, 0.04, 16)
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(1, 0.78, 0.2)
	mt.metallic = 1.0
	mt.roughness = 0.25
	mt.emission_enabled = true
	mt.emission = Color(1, 0.6, 0.1)
	mt.emission_energy_multiplier = 0.6
	mesh.material_override = mt
	mesh.rotation.x = PI / 2
	add_child(mesh)
	var a := randf() * TAU
	vel = Vector3(cos(a) * randf_range(1, 3), randf_range(4, 6), sin(a) * randf_range(1, 3))

func _physics_process(delta: float) -> void:
	if main.state != "play":
		return
	age += delta
	rotation.y += delta * 6.0
	var p = main.player
	if p == null:
		return
	var to: Vector3 = p.global_position + Vector3(0, 0.8, 0) - global_position
	if age > 0.6 and (to.length() < 3.5 or main.portal_open):
		vel = vel.lerp(to.normalized() * (10.0 + age * 6.0), delta * 8.0)
		if to.length() < 0.5:
			main.collect_coin(value, global_position)
			queue_free()
			return
	else:
		vel.y -= 18.0 * delta
		vel.x *= 0.98
		vel.z *= 0.98
	global_position += vel * delta
	if global_position.y < 0.25 and not (age > 0.6 and (to.length() < 3.5 or main.portal_open)):
		# rebota y luego se queda flotando en el suelo hasta que la recojas
		global_position.y = 0.25
		vel.y = abs(vel.y) * 0.4 if abs(vel.y) > 1.0 else 0.0
		vel.x *= 0.85
		vel.z *= 0.85
		if age > 0.8:
			mesh.position.y = sin(age * 4.0) * 0.06
	global_position.x = clamp(global_position.x, -6.6, 6.6)
	global_position.z = clamp(global_position.z, -10.6, 10.6)
