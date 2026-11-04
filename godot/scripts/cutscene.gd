extends Node
## Escenas animadas de la historia: la cámara se mueve, los personajes actúan y aparecen subtítulos.

var main
var ui
var actors := []
var skip := false

func _process(delta: float) -> void:
	for a in actors:
		if is_instance_valid(a):
			a.animate(delta, float(a.get_meta("spd", 0.0)))

# ---------------- utilidades ----------------
func _begin(title := "") -> void:
	skip = false
	main.state = "cutscene"
	main.clear_level()
	main.arena.clear_level()
	main.arena.close_portal()
	if main.player:
		main.player.visible = false
	ui.cine_show(true, title)

func _end(cb: Callable) -> void:
	for a in actors:
		if is_instance_valid(a):
			a.queue_free()
	actors.clear()
	ui.cine_show(false)
	if main.player:
		main.player.visible = true
	cb.call()

func actor(model, pos: Vector3, face := 0.0):
	main.add_child(model)
	model.global_position = pos
	model.rotation.y = face
	actors.append(model)
	return model

func cam(pos: Vector3, look: Vector3, snap := false) -> void:
	main.cine_pos = pos
	main.cine_look = look
	if snap:
		main.cam.global_transform = Transform3D(Basis(), pos).looking_at(look, Vector3.UP)

func say(text: String) -> void:
	if skip:
		return
	ui.cine_say(text)
	await ui.cine_next

func wait(t: float) -> void:
	if skip:
		return
	await get_tree().create_timer(t).timeout

func walk(a: Rig, to: Vector3, dur: float) -> void:
	var d := to - a.global_position
	a.rotation.y = atan2(d.x, d.z)
	a.set_meta("spd", 3.5)
	var tw := a.create_tween()
	tw.tween_property(a, "global_position", to, dur)
	tw.tween_callback(func(): a.set_meta("spd", 0.0))

func act(a: Rig, anim: String, spd := 1.0) -> void:
	if a is CharModel:
		a.action(anim, spd)

func malakar() -> CharModel:
	var m := CharModel.create("Skeleton_Mage", 3.4, [], {"anim_attack": "Spellcast_Shoot", "anim_cast": "Spellcast_Raise"})
	m.attach("Skeleton_Staff")
	var l := OmniLight3D.new()
	l.light_color = Color(0.7, 0.2, 1.0)
	l.light_energy = 3.0
	l.omni_range = 8.0
	l.position = Vector3(0, 3, 1)
	m.add_child(l)
	return m

func unlocked_heroes() -> Array:
	return main.hero_keys.filter(func(k): return GameData.is_unlocked(k))

# ---------------- INTRO DE CAPÍTULO ----------------
func intro(chapter: int, cb: Callable) -> void:
	var ch: Dictionary = GameData.CHAPTERS[chapter]
	main.arena.set_biome(ch.biome, main.env)
	Sfx.play_music(ch.biome)
	_begin("Capítulo %d\n%s" % [chapter + 1, ch.name])
	var lines: Array = ch.intro
	var split: int = max(1, lines.size() - 2)
	# Plano 1: Malakar invoca a su ejército
	var mk = actor(malakar(), Vector3(0, -3.5, -6), 0.0)
	cam(Vector3(0, 10, 13), Vector3(0, 0, -2), true)
	cam(Vector3(0, 6, 8), Vector3(0, 1.5, -5))
	await wait(1.8)
	mk.create_tween().tween_property(mk, "global_position:y", 0.0, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FX.burst(Vector3(0, 0.5, -6), Color(0.7, 0.2, 1), 60, 6.0, 0.1, 1.2, 1.0)
	FX.ring(Vector3(0, 0, -6), 3.5, Color(0.7, 0.2, 1), 1.0)
	Sfx.play("roar", -4.0)
	await wait(1.0)
	act(mk, "Spellcast_Raise", 0.8)
	var skels := []
	for i in 6:
		var a := i * TAU / 6.0
		var p := Vector3(0, 0, -6) + Vector3(cos(a), 0, sin(a) * 0.6 + 0.6) * 3.2
		var s = actor(Builder.enemy("skeleton"), p, 0.0)
		s.spawn()
		skels.append(s)
		FX.burst(p + Vector3.UP * 0.2, Color(0.7, 0.2, 1), 12, 3.0, 0.06, 0.6, 2.0)
	Sfx.play("summon", -4.0)
	for i in split:
		if i == 1:
			cam(Vector3(2.5, 3.2, -1.5), Vector3(0, 2.4, -6))
			act(mk, "Cheer")
		await say(lines[i])
	# Malakar desaparece y su ejército marcha hacia el portal
	if not skip:
		act(mk, "Spellcast_Shoot")
		FX.burst(Vector3(0, 2, -6), Color(0.7, 0.2, 1), 70, 7.0, 0.1, 1.0, 0.0)
		Sfx.play("teleport", -2.0)
		mk.create_tween().tween_property(mk, "global_position:y", -4.0, 0.8)
		for s in skels:
			walk(s, Vector3(randf_range(-1, 1), 0, -10.5), 2.5)
		await wait(1.2)
	# Plano 2: llegan los héroes
	var heroes := unlocked_heroes()
	var party := []
	for i in heroes.size():
		var h = actor(Builder.hero(heroes[i]), Vector3((i - (heroes.size() - 1) / 2.0) * 1.3, 0, 13 + i * 0.8), PI)
		party.append(h)
		walk(h, Vector3((i - (heroes.size() - 1) / 2.0) * 1.3, 0, 4.0), 2.6)
	cam(Vector3(5, 3.2, 10.5), Vector3(0, 1.0, 5))
	await wait(1.6)
	for i in range(split, lines.size()):
		if i == lines.size() - 1:
			cam(Vector3(0, 1.9, 0.8), Vector3(0, 1.2, 4.0))
			for h in party:
				h.rotation.y = PI
				act(h, "Cheer")
		await say(lines[i])
	_end(cb)

# ---------------- HÉROE RESCATADO ----------------
func unlock(hero: String, cb: Callable) -> void:
	_begin("¡Nuevo héroe!")
	var cage_center := Vector3(0, 0, -1)
	var rescued = actor(Builder.hero(hero), cage_center, 0.0)
	var bars := []
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.88, 0.8)
	for i in 10:
		var a := i * TAU / 10.0
		var b := MeshInstance3D.new()
		b.mesh = Rig.cyl(0.06, 0.06, 2.6, 6)
		b.material_override = mat
		main.add_child(b)
		b.global_position = cage_center + Vector3(cos(a), 1.3, sin(a)) * Vector3(1, 1, 1)
		bars.append(b)
	var me = actor(Builder.hero(main.player.key), Vector3(0, 0, 8), PI)
	cam(Vector3(5, 3.5, 6), Vector3(0, 1, 1), true)
	walk(me, Vector3(1.4, 0, 1.4), 2.2)
	await wait(2.3)
	act(me, me.anim_attack if me is CharModel else "Cheer")
	await wait(0.35)
	for b in bars:
		var tw: Tween = b.create_tween()
		tw.tween_property(b, "position:y", -2.0, 0.5).set_ease(Tween.EASE_IN)
		tw.tween_callback(b.queue_free)
	FX.burst(cage_center + Vector3.UP, Color(1, 0.9, 0.6), 50, 6.0, 0.08, 0.9)
	FX.ring(cage_center, 2.0, GameData.HEROES[hero].color)
	Sfx.play("win", -3.0, 0.0)
	cam(Vector3(-1.2, 1.9, 3.6), Vector3(0.4, 1.1, -0.2))
	me.rotation.y = -0.6
	act(rescued, "Cheer")
	await say(GameData.UNLOCK_STORY[hero])
	for b in bars:
		if is_instance_valid(b):
			b.queue_free()
	_end(cb)

# ---------------- FINAL DE CAPÍTULO ----------------
func outro(chapter: int, cb: Callable) -> void:
	var ch: Dictionary = GameData.CHAPTERS[chapter]
	_begin("¡Capítulo %d completado!" % (chapter + 1))
	var heroes := unlocked_heroes()
	var party := []
	for i in heroes.size():
		var x := (i - (heroes.size() - 1) / 2.0) * 1.3
		party.append(actor(Builder.hero(heroes[i]), Vector3(x, 0, 2.0 - abs(x) * 0.25), 0.0))
	cam(Vector3(0, 6, 12), Vector3(0, 1, 2), true)
	cam(Vector3(0, 2.0, 6.5), Vector3(0, 1.1, 2))
	for i in ch.outro.size():
		for h in party:
			act(h, "Cheer")
		for k in 3:
			FX.burst(Vector3(randf_range(-5, 5), randf_range(3, 5), randf_range(-4, 0)), Color.from_hsv(randf(), 0.7, 1.0), 40, 5.0, 0.07, 1.2, -3.0)
		Sfx.play("portal", -6.0, 0.1)
		if i == 1:
			cam(Vector3(-4, 2.4, 6), Vector3(0, 1.1, 2))
		await say(ch.outro[i])
	_end(cb)
