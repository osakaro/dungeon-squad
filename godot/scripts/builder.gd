class_name Builder
## Fabrica los modelos 3D de héroes, enemigos y esbirros.

const SKIN := Color(0.94, 0.76, 0.6)

static func humanoid(body_c: Color, skin_c := SKIN, leg_c := Color(0.22, 0.22, 0.27), eye_c := Color(0, 0, 0, 0)) -> Rig:
	var r := Rig.new()
	var body := r.mat(body_c)
	var skin := r.mat(skin_c)
	var leg := r.mat(leg_c)
	var boot := r.mat(leg_c.darkened(0.45))
	r.leg_l = r.pivot(Vector3(-0.13, 0.6, 0))
	r.leg_r = r.pivot(Vector3(0.13, 0.6, 0))
	for l in [r.leg_l, r.leg_r]:
		r.part(Rig.box(0.18, 0.5, 0.21), leg, Vector3(0, -0.25, 0), l)
		r.part(Rig.box(0.2, 0.14, 0.28), boot, Vector3(0, -0.53, 0.03), l)
	r.body = r.pivot(Vector3(0, 0.92, 0))
	r.part(Rig.box(0.52, 0.62, 0.32), body, Vector3.ZERO, r.body)
	r.part(Rig.box(0.55, 0.08, 0.35), r.mat(Color(0.25, 0.16, 0.09)), Vector3(0, -0.26, 0), r.body)
	r.part(Rig.box(0.1, 0.08, 0.04), Rig.glow_mat(Color(1, 0.8, 0.3), 1.0), Vector3(0, -0.26, 0.18), r.body)
	r.arm_l = r.pivot(Vector3(-0.34, 1.17, 0))
	r.arm_r = r.pivot(Vector3(0.34, 1.17, 0))
	for a in [r.arm_l, r.arm_r]:
		r.part(Rig.box(0.15, 0.5, 0.15), body, Vector3(0, -0.24, 0), a)
	r.hand_l = r.part(Rig.sphere(0.085, 10), skin, Vector3(0, -0.55, 0), r.arm_l)
	r.hand_r = r.part(Rig.sphere(0.085, 10), skin, Vector3(0, -0.55, 0), r.arm_r)
	r.head = r.part(Rig.sphere(0.24), skin, Vector3(0, 1.47, 0))
	var eye: Material = Rig.glow_mat(Color(eye_c.r, eye_c.g, eye_c.b), 5.0) if eye_c.a > 0.0 else r.mat(Color(0.05, 0.05, 0.05), 0.2)
	r.part(Rig.sphere(0.04, 8), eye, Vector3(-0.08, 1.5, 0.21))
	r.part(Rig.sphere(0.04, 8), eye, Vector3(0.08, 1.5, 0.21))
	return r

static func _cape(r: Rig, c: Color) -> void:
	r.cape = r.pivot(Vector3(0, 1.18, -0.17))
	r.part(Rig.box(0.5, 0.85, 0.04), r.mat(c), Vector3(0, -0.42, 0), r.cape)

static func _cone(r: Rig, rad: float, h: float, m: Material, pos: Vector3, parent: Node3D = null) -> MeshInstance3D:
	return r.part(Rig.cyl(0.0, rad, h), m, pos, parent)

static func hero(key: String) -> Rig:
	var c: CharModel
	match key:
		"arquero":
			c = CharModel.create("Rogue_Hooded", 1.75, ["Knife", "Knife_Offhand", "1H_Crossbow", "Throwable"],
				{"anim_attack": "2H_Ranged_Shoot", "anim_cast": "2H_Ranged_Shoot"})
		"mago":
			c = CharModel.create("Mage", 1.75, ["Spellbook", "Spellbook_open", "1H_Wand"],
				{"anim_attack": "Spellcast_Shoot", "anim_cast": "Spellcast_Long"})
			_hand_light(c, Color(1, 0.5, 0.15))
		"guerrero":
			c = CharModel.create("Knight", 1.85, ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "2H_Sword"],
				{"anim_attack": "1H_Melee_Attack_Slice_Horizontal", "anim_cast": "Cheer", "anim_spin": "2H_Melee_Attack_Spinning"})
		"asesino":
			c = CharModel.create("Rogue", 1.75, ["1H_Crossbow", "2H_Crossbow", "Throwable"],
				{"anim_attack": "Throw", "anim_cast": "Dualwield_Melee_Attack_Stab"})
		"nigromante":
			c = CharModel.create("Skeleton_Mage", 1.8, [],
				{"anim_attack": "Spellcast_Shoot", "anim_cast": "Spellcast_Raise", "anim_death": "Death_C_Skeletons"})
			c.attach("Skeleton_Staff")
			_hand_light(c, Color(0.3, 1.0, 0.45))
	return c

static func _hand_light(c: CharModel, col: Color) -> void:
	if c.skel == null:
		return
	var ba := BoneAttachment3D.new()
	ba.bone_name = "handslot.r"
	c.skel.add_child(ba)
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 1.4
	l.omni_range = 3.5
	l.position = Vector3(0, 0.6, 0)
	ba.add_child(l)

static func enemy(type: String) -> Rig:
	var r: Rig
	match type:
		"rogue":
			var rg := CharModel.create("Skeleton_Rogue", 1.6, [], {"anim_run": "Running_A", "anim_attack": "Dualwield_Melee_Attack_Slice",
				"anim_spawn": "Spawn_Ground_Skeletons", "anim_death": "Death_C_Skeletons", "run_speed_ref": 4.5})
			rg.attach("Skeleton_Blade")
			rg.attach("Skeleton_Blade", "handslot.l")
			return rg
		"skmage":
			var mg := CharModel.create("Skeleton_Mage", 1.7, [], {"anim_run": "Walking_D_Skeletons", "anim_attack": "Spellcast_Shoot",
				"anim_spawn": "Spawn_Ground_Skeletons", "anim_death": "Death_C_Skeletons", "run_speed_ref": 1.5})
			mg.attach("Skeleton_Staff")
			var ml := OmniLight3D.new()
			ml.light_color = Color(0.75, 0.3, 1.0)
			ml.light_energy = 1.6
			ml.omni_range = 3.5
			ml.position = Vector3(0, 1.4, 0.5)
			mg.add_child(ml)
			return mg
		"brute":
			return CharModel.create("Barbarian", 2.3, ["1H_Axe_Offhand", "Barbarian_Round_Shield", "1H_Axe", "Mug"],
				{"anim_attack": "2H_Melee_Attack_Chop", "anim_cast": "2H_Melee_Attack_Spin", "run_speed_ref": 3.0})
		"champion":
			return CharModel.create("Barbarian", 3.6, ["1H_Axe_Offhand", "1H_Axe", "Mug"],
				{"anim_attack": "2H_Melee_Attack_Chop", "anim_cast": "2H_Melee_Attack_Spin", "run_speed_ref": 2.0})
		"skeleton":
			var sk := CharModel.create("Skeleton_Minion", 1.65, [], {"anim_run": "Running_B", "anim_attack": "1H_Melee_Attack_Chop",
				"anim_spawn": "Spawn_Ground_Skeletons", "anim_death": "Death_C_Skeletons", "run_speed_ref": 3.0})
			sk.attach("Skeleton_Blade")
			return sk
		"boss":
			var bs := CharModel.create("Skeleton_Warrior", 4.0, [], {"anim_run": "Walking_D_Skeletons", "anim_attack": "1H_Melee_Attack_Slice_Horizontal",
				"anim_cast": "Spellcast_Raise", "anim_spawn": "Spawn_Ground_Skeletons", "anim_death": "Death_C_Skeletons", "run_speed_ref": 1.4})
			bs.attach("Skeleton_Axe")
			bs.attach("Skeleton_Shield_Large_A", "handslot.l")
			var l := OmniLight3D.new()
			l.light_color = Color(0.3, 0.8, 1.0)
			l.light_energy = 2.5
			l.omni_range = 6.0
			l.position = Vector3(0, 3.5, 0.6)
			bs.add_child(l)
			return bs
		"skel":
			var mn := CharModel.create("Skeleton_Minion", 1.45, [], {"anim_run": "Running_B", "anim_attack": "1H_Melee_Attack_Chop",
				"anim_spawn": "Spawn_Ground_Skeletons", "anim_death": "Death_C_Skeletons", "run_speed_ref": 3.5})
			mn.attach("Skeleton_Blade")
			return mn
	return r
