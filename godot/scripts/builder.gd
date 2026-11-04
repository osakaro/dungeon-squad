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
	var r: Rig
	var metal := func(rr: Rig): return rr.mat(Color(0.78, 0.8, 0.85), 0.25, 0.9)
	match key:
		"arquero":
			r = humanoid(Color(0.18, 0.5, 0.24), SKIN, Color(0.32, 0.24, 0.16))
			_cone(r, 0.3, 0.45, r.mat(Color(0.12, 0.38, 0.18)), Vector3(0, 1.72, -0.03))
			r.part(Rig.sphere(0.26), r.mat(Color(0.12, 0.38, 0.18)), Vector3(0, 1.5, -0.05)).scale = Vector3(1, 1, 0.9)
			_cape(r, Color(0.1, 0.32, 0.15))
			var wood := r.mat(Color(0.45, 0.28, 0.14))
			for i in 9:
				var a := -1.2 + i * 0.3
				var seg := r.part(Rig.box(0.05, 0.13, 0.05), wood, Vector3(0, sin(a) * 0.45, 0.08 + cos(a) * 0.16), r.hand_l)
				seg.rotation.x = -a * 0.4
			r.part(Rig.box(0.01, 0.86, 0.01), r.mat(Color(0.9, 0.9, 0.85)), Vector3(0, 0, 0.04), r.hand_l)
			var q := r.part(Rig.cyl(0.1, 0.09, 0.6), r.mat(Color(0.42, 0.22, 0.1)), Vector3(0.14, 1.05, -0.24))
			q.rotation.x = 0.3
			for i in 3:
				r.part(Rig.box(0.03, 0.2, 0.06), r.mat(Color(0.95, 0.95, 0.95)), Vector3(-0.04 + i * 0.04, 0.38, 0), q)
		"mago":
			r = humanoid(Color(0.3, 0.22, 0.7), SKIN, Color(0.3, 0.22, 0.7))
			var robe := r.mat(Color(0.26, 0.18, 0.62))
			r.part(Rig.cyl(0.22, 0.48, 0.9, 14), robe, Vector3(0, 0.45, 0))
			var hat := r.mat(Color(0.18, 0.12, 0.45))
			r.part(Rig.cyl(0.42, 0.42, 0.04, 20), hat, Vector3(0, 1.66, 0))
			var tip := _cone(r, 0.25, 0.7, hat, Vector3(0, 2.0, -0.03))
			tip.rotation.x = -0.18
			r.part(Rig.box(0.5, 0.06, 0.06), Rig.glow_mat(Color(1, 0.8, 0.2), 1.5), Vector3(0, 1.72, 0))
			var beard := _cone(r, 0.14, 0.38, r.mat(Color(0.92, 0.92, 0.95)), Vector3(0, 1.25, 0.15))
			beard.rotation.x = PI
			r.part(Rig.cyl(0.035, 0.035, 1.6, 6), r.mat(Color(0.4, 0.25, 0.12)), Vector3(0, 0.15, 0), r.hand_r)
			r.glow_light(r.hand_r, Color(1.0, 0.5, 0.15), 0.13, Vector3(0, 0.98, 0), 3.5)
		"guerrero":
			r = humanoid(Color(0.6, 0.15, 0.12), SKIN, Color(0.35, 0.37, 0.42))
			var mt: StandardMaterial3D = metal.call(r)
			r.part(Rig.sphere(0.28), mt, Vector3(0, 1.52, -0.01)).scale = Vector3(1, 0.88, 1)
			r.part(Rig.box(0.32, 0.04, 0.03), r.mat(Color(0.05, 0.05, 0.05)), Vector3(0, 1.5, 0.26))
			r.part(Rig.box(0.05, 0.3, 0.38), r.mat(Color(0.85, 0.1, 0.1)), Vector3(0, 1.83, -0.05))
			r.part(Rig.sphere(0.15, 10), mt, Vector3(-0.37, 1.2, 0))
			r.part(Rig.sphere(0.15, 10), mt, Vector3(0.37, 1.2, 0))
			r.part(Rig.box(0.5, 0.4, 0.06), mt, Vector3(0, 1.0, 0.17))
			_cape(r, Color(0.55, 0.08, 0.08))
			r.part(Rig.box(0.08, 0.025, 1.0), mt, Vector3(0, 0, 0.58), r.hand_r)
			r.part(Rig.box(0.32, 0.06, 0.06), r.mat(Color(0.85, 0.65, 0.15), 0.3, 0.8), Vector3(0, 0, 0.08), r.hand_r)
			var sh := r.part(Rig.cyl(0.34, 0.34, 0.06, 20), r.mat(Color(0.55, 0.12, 0.1), 0.4, 0.4), Vector3(-0.06, 0, 0.12), r.hand_l)
			sh.rotation.x = PI / 2
			r.part(Rig.cyl(0.36, 0.36, 0.04, 20), mt, Vector3(0, -0.02, 0), sh)
			r.part(Rig.sphere(0.08, 8), r.mat(Color(0.9, 0.7, 0.2), 0.3, 0.9), Vector3(0, 0.05, 0), sh)
			r.scale = Vector3.ONE * 1.08
		"asesino":
			r = humanoid(Color(0.12, 0.12, 0.17), SKIN, Color(0.1, 0.1, 0.13), Color(1, 0.2, 0.3))
			r.part(Rig.sphere(0.27), r.mat(Color(0.08, 0.08, 0.11)), Vector3(0, 1.52, -0.04)).scale = Vector3(1, 1.05, 1)
			r.part(Rig.box(0.5, 0.12, 0.36), r.mat(Color(0.7, 0.08, 0.15)), Vector3(0, 1.25, 0))
			r.cape = r.pivot(Vector3(0.1, 1.25, -0.18))
			r.part(Rig.box(0.12, 0.6, 0.03), r.mat(Color(0.7, 0.08, 0.15)), Vector3(0, -0.3, 0), r.cape)
			var mt2: StandardMaterial3D = metal.call(r)
			for h in [r.hand_l, r.hand_r]:
				r.part(Rig.box(0.03, 0.02, 0.45), mt2, Vector3(0, 0, 0.26), h)
				r.part(Rig.box(0.14, 0.04, 0.04), r.mat(Color(0.3, 0.1, 0.4)), Vector3(0, 0, 0.04), h)
		"nigromante":
			r = humanoid(Color(0.1, 0.16, 0.12), Color(0.72, 0.78, 0.7), Color(0.1, 0.16, 0.12), Color(0.4, 1, 0.5))
			var robe2 := r.mat(Color(0.08, 0.12, 0.09))
			r.part(Rig.cyl(0.22, 0.48, 0.9, 14), robe2, Vector3(0, 0.45, 0))
			_cone(r, 0.31, 0.6, robe2, Vector3(0, 1.72, -0.05))
			r.part(Rig.sphere(0.27), robe2, Vector3(0, 1.5, -0.07))
			for s in [-1, 1]:
				var sp := _cone(r, 0.08, 0.3, r.mat(Color(0.85, 0.85, 0.8)), Vector3(s * 0.36, 1.32, 0))
				sp.rotation.z = -s * 0.5
			r.part(Rig.cyl(0.035, 0.035, 1.7, 6), r.mat(Color(0.15, 0.15, 0.15)), Vector3(0, 0.15, 0), r.hand_r)
			var skull := r.part(Rig.sphere(0.14, 12), r.mat(Color(0.92, 0.9, 0.8)), Vector3(0, 1.0, 0), r.hand_r)
			r.glow_light(skull, Color(0.3, 1.0, 0.45), 0.05, Vector3(0, 0.02, 0.12), 3.5)
			_cape(r, Color(0.05, 0.08, 0.06))
	return r

static func enemy(type: String) -> Rig:
	var r: Rig
	match type:
		"slime":
			r = Rig.new()
			r.bob_node = r.pivot(Vector3.ZERO)
			var m := r.mat(Color(0.3, 0.9, 0.45, 0.78), 0.1)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.rim_enabled = true
			var b := r.part(Rig.sphere(0.45, 20), m, Vector3(0, 0.34, 0), r.bob_node)
			b.scale = Vector3(1, 0.75, 1)
			r.part(Rig.sphere(0.2, 12), r.mat(Color(0.1, 0.5, 0.2)), Vector3(0, 0.3, 0), r.bob_node)
			for x in [-0.15, 0.15]:
				r.part(Rig.sphere(0.08, 8), r.mat(Color(0.05, 0.05, 0.05), 0.1), Vector3(x, 0.45, 0.35), r.bob_node)
				r.part(Rig.sphere(0.025, 6), Rig.glow_mat(Color.WHITE, 1.0), Vector3(x + 0.03, 0.48, 0.42), r.bob_node)
		"bat":
			r = Rig.new()
			r.bob_node = r.pivot(Vector3(0, 1.2, 0))
			var bm := r.mat(Color(0.25, 0.12, 0.3))
			r.part(Rig.sphere(0.24, 12), bm, Vector3.ZERO, r.bob_node)
			for x in [-0.09, 0.09]:
				r.part(Rig.sphere(0.04, 6), Rig.glow_mat(Color(1, 0.2, 0.2), 6.0), Vector3(x, 0.05, 0.2), r.bob_node)
				var ear := _cone(r, 0.06, 0.18, bm, Vector3(x, 0.24, 0), r.bob_node)
				ear.rotation.z = -x * 3.0
			r.wing_l = r.pivot(Vector3(-0.18, 0.05, 0), r.bob_node)
			r.wing_r = r.pivot(Vector3(0.18, 0.05, 0), r.bob_node)
			var wm := r.mat(Color(0.18, 0.08, 0.22))
			r.part(Rig.box(0.6, 0.03, 0.34), wm, Vector3(-0.3, 0, 0), r.wing_l)
			r.part(Rig.box(0.6, 0.03, 0.34), wm, Vector3(0.3, 0, 0), r.wing_r)
		"crystal":
			r = Rig.new()
			var stone := r.mat(Color(0.35, 0.34, 0.38))
			r.part(Rig.cyl(0.38, 0.48, 0.35, 8), stone, Vector3(0, 0.17, 0))
			r.bob_node = r.pivot(Vector3(0, 1.0, 0))
			var cm := r.mat(Color(0.7, 0.3, 1.0), 0.15, 0.3)
			cm.emission_enabled = true
			cm.emission = Color(0.55, 0.15, 0.9)
			cm.emission_energy_multiplier = 1.4
			var c := r.part(Rig.sphere(0.42, 4), cm, Vector3.ZERO, r.bob_node)
			c.scale = Vector3(0.8, 1.4, 0.8)
			for i in 3:
				var a := i * TAU / 3.0
				r.part(Rig.sphere(0.1, 4), cm, Vector3(cos(a) * 0.6, 0.1, sin(a) * 0.6), r.bob_node)
			var l := OmniLight3D.new()
			l.light_color = Color(0.7, 0.3, 1.0)
			l.omni_range = 3.0
			r.bob_node.add_child(l)
		"brute":
			r = humanoid(Color(0.4, 0.27, 0.14), Color(0.38, 0.6, 0.25), Color(0.25, 0.17, 0.1), Color(1, 0.25, 0))
			var wood := r.mat(Color(0.35, 0.22, 0.1))
			r.part(Rig.box(0.12, 0.12, 0.85), wood, Vector3(0, 0, 0.4), r.hand_r)
			r.part(Rig.sphere(0.18, 10), wood, Vector3(0, 0, 0.85), r.hand_r)
			for x in [-0.09, 0.09]:
				var tusk := _cone(r, 0.03, 0.12, r.mat(Color(0.95, 0.92, 0.8)), Vector3(x, 1.36, 0.2))
				tusk.rotation.x = 0.3
			r.part(Rig.box(0.6, 0.15, 0.36), r.mat(Color(0.3, 0.3, 0.32), 0.4, 0.7), Vector3(0, 0.25, 0), r.body)
			r.scale = Vector3.ONE * 1.45
		"boss":
			r = humanoid(Color(0.3, 0.05, 0.08), Color(0.7, 0.15, 0.12), Color(0.15, 0.03, 0.03), Color(1, 0.9, 0.1))
			var horn := r.mat(Color(0.12, 0.1, 0.1), 0.4)
			for s in [-1, 1]:
				var h := _cone(r, 0.08, 0.42, horn, Vector3(s * 0.17, 1.74, 0))
				h.rotation.z = -s * 0.55
			var blade := r.mat(Color(0.25, 0.25, 0.28), 0.3, 0.9)
			r.part(Rig.box(0.12, 0.04, 1.4), blade, Vector3(0, 0, 0.75), r.hand_r)
			r.part(Rig.box(0.02, 0.05, 1.3), Rig.glow_mat(Color(1, 0.2, 0.05), 5.0), Vector3(0.07, 0, 0.75), r.hand_r)
			r.wing_l = r.pivot(Vector3(-0.15, 1.1, -0.18))
			r.wing_r = r.pivot(Vector3(0.15, 1.1, -0.18))
			var wm2 := r.mat(Color(0.2, 0.04, 0.06))
			r.part(Rig.box(0.9, 0.6, 0.03), wm2, Vector3(-0.45, 0.15, 0), r.wing_l)
			r.part(Rig.box(0.9, 0.6, 0.03), wm2, Vector3(0.45, 0.15, 0), r.wing_r)
			r.glow_light(r.body, Color(1, 0.3, 0.05), 0.08, Vector3(0, 0.1, 0.17), 5.0)
			r.scale = Vector3.ONE * 2.4
		"skel":
			r = humanoid(Color(0.88, 0.86, 0.78), Color(0.9, 0.88, 0.8), Color(0.82, 0.8, 0.72), Color(0.3, 1, 0.45))
			r.part(Rig.box(0.05, 0.03, 0.6), r.mat(Color(0.6, 0.62, 0.66), 0.3, 0.8), Vector3(0, 0, 0.32), r.hand_r)
			for i in 3:
				r.part(Rig.box(0.54, 0.04, 0.34), r.mat(Color(0.6, 0.58, 0.5)), Vector3(0, 0.15 - i * 0.12, 0), r.body)
			r.scale = Vector3.ONE * 0.85
	return r
