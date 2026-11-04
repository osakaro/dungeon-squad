class_name CharModel
extends Rig
## Personaje KayKit (.glb) con animaciones de esqueleto. Mantiene la misma interfaz que Rig.

const CHAR_DIR := "res://assets/kaykit/characters/"
const WEAPON_DIR := "res://assets/kaykit/weapons/"
const LOOPS := ["Idle", "Running_A", "Running_B", "Walking_A", "Walking_D_Skeletons", "2H_Melee_Attack_Spinning", "Spellcasting", "Unarmed_Idle", "2H_Melee_Idle"]

var model: Node3D
var ap: AnimationPlayer
var skel: Skeleton3D
var meshes := []
var overlay: StandardMaterial3D
var anim_idle := "Idle"
var anim_run := "Running_A"
var anim_attack := "1H_Melee_Attack_Chop"
var anim_cast := "Spellcast_Shoot"
var anim_hit := "Hit_A"
var anim_death := "Death_A"
var anim_spin := ""
var anim_spawn := ""
var run_speed_ref := 5.0
var attack_speed := 1.0
var action_t := 0.0
var locked := false
var _cur := ""

static func create(file: String, height: float, hide_list: Array = [], anims := {}) -> CharModel:
	var c := CharModel.new()
	c.model = (load(CHAR_DIR + file + ".glb") as PackedScene).instantiate()
	c.add_child(c.model)
	c.model.scale = Vector3.ONE * (height / 2.4)
	c.ap = c.model.find_child("AnimationPlayer", true, false)
	c.skel = c.model.find_child("Skeleton3D", true, false) as Skeleton3D
	for k in anims:
		c.set(k, anims[k])
	c.overlay = StandardMaterial3D.new()
	c.overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	c.overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	c.overlay.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	for n in c.model.find_children("*", "MeshInstance3D", true, false):
		if n.name in hide_list:
			n.visible = false
		else:
			c.meshes.append(n)
	if c.ap:
		for a in LOOPS:
			if c.ap.has_animation(a):
				c.ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		c._play(c.anim_idle, 0.0)
	return c

func attach(weapon: String, bone := "handslot.r", rot := Vector3.ZERO, scl := 1.0) -> Node3D:
	if skel == null:
		return null
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skel.add_child(ba)
	var w: Node3D = (load(WEAPON_DIR + weapon + ".gltf") as PackedScene).instantiate()
	w.rotation_degrees = rot
	w.scale = Vector3.ONE * scl
	ba.add_child(w)
	for n in w.find_children("*", "MeshInstance3D", true, false):
		meshes.append(n)
	return w

func _play(n: String, blend := 0.15, spd := 1.0) -> void:
	if ap == null or not ap.has_animation(n):
		return
	if n == _cur and ap.is_playing():
		ap.speed_scale = spd
		return
	_cur = n
	ap.play(n, blend)
	ap.speed_scale = spd

func action(n: String, spd := 1.0) -> void:
	if ap == null or locked or not ap.has_animation(n):
		return
	_cur = n
	ap.play(n, 0.06)
	ap.seek(0.0, true)
	ap.speed_scale = spd
	action_t = ap.get_animation(n).length / spd * 0.85

func animate(delta: float, speed: float) -> void:
	time += delta
	if locked or ap == null:
		return
	if action_t > 0.0:
		action_t -= delta
		return
	if speed > 0.4:
		_play(anim_run, 0.15, clamp(speed / run_speed_ref, 0.6, 1.8))
	else:
		_play(anim_idle, 0.2)

func attack() -> void:
	action(anim_attack, attack_speed)

func cast_anim() -> void:
	action(anim_cast, 1.4)

func hit() -> void:
	if action_t <= 0.0:
		action(anim_hit, 1.6)

func spin(on: bool) -> void:
	if on and anim_spin != "":
		_play(anim_spin, 0.1, 1.6)
		action_t = 0.1
	elif not on:
		action_t = 0.0

func spawn() -> void:
	if anim_spawn != "":
		action(anim_spawn, 1.0)

func die() -> void:
	if ap and ap.has_animation(anim_death):
		ap.play(anim_death, 0.1)
		ap.speed_scale = 1.0
	locked = true

func tint(c: Color) -> void:
	if c == _tint:
		return
	_tint = c
	if c.a > 0.0:
		overlay.albedo_color = Color(c.r, c.g, c.b, clamp(c.a * 0.45, 0.0, 0.8))
		for m in meshes:
			m.material_overlay = overlay
	else:
		for m in meshes:
			m.material_overlay = null
