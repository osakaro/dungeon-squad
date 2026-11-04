extends Node3D
## Bucle principal: estados del juego, niveles, cámara y creación de entidades.

const PlayerScript := preload("res://scripts/player.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const ProjectileScript := preload("res://scripts/projectile.gd")
const CoinScript := preload("res://scripts/coin.gd")
const MinionScript := preload("res://scripts/minion.gd")
const UIScript := preload("res://scripts/ui.gd")

var state := "title"         # title, menu, play, choose, story, end, pause
var arena: Arena
var cam: Camera3D
var env: Environment
var ui
var player = null
var hero_keys := []
var sel := 0
var showcase: Rig
var pedestal: Node3D
var spot: SpotLight3D
var level := 1               # sala dentro del capítulo (1-25)
var chapter := 0
var lineup: Node3D
var cine
var cine_pos := Vector3(0, 8, 12)
var cine_look := Vector3.ZERO
var title_t := 0.0
var run_coins := 0
var portal_open := false
var level_time := 0.0

func _ready() -> void:
	randomize()
	FX.root = self
	_build_env()
	arena = Arena.new()
	add_child(arena)
	arena.build()
	cam = Camera3D.new()
	cam.fov = 50.0
	add_child(cam)
	cam.position = Vector3(0, 6, 14)
	cam.current = true
	_build_pedestal()
	ui = UIScript.new()
	ui.main = self
	add_child(ui)
	cine = preload("res://scripts/cutscene.gd").new()
	cine.main = self
	cine.ui = ui
	add_child(cine)
	hero_keys = ["guerrero", "arquero", "mago", "asesino", "nigromante"]
	chapter = clamp(GameData.chapters_open - 1, 0, GameData.CHAPTERS.size() - 1)
	go_title()

# ---------------- TÍTULO ----------------
func go_title() -> void:
	state = "title"
	pedestal.visible = false
	arena.set_biome(GameData.CHAPTERS[chapter].biome, env)
	lineup = Node3D.new()
	add_child(lineup)
	var keys := hero_keys.filter(func(k): return GameData.is_unlocked(k))
	for i in keys.size():
		var h := Builder.hero(keys[i])
		lineup.add_child(h)
		h.position = Vector3((i - (keys.size() - 1) / 2.0) * 1.4, 0, 2.0 - abs(i - (keys.size() - 1) / 2.0) * 0.4)
		h.rotation.y = 0.0
		if h is CharModel:
			h.anim_idle = "Idle" if i % 2 == 0 else "Unarmed_Idle"
	Sfx.play_music("title")
	ui.show_title()

func difficulty() -> int:
	return chapter * GameData.MAX_LEVEL + level

func change_chapter(d: int) -> void:
	chapter = clamp(chapter + d, 0, GameData.chapters_open - 1)
	arena.set_biome(GameData.CHAPTERS[chapter].biome, env)
	ui.update_menu(hero_keys[sel])

func _build_env() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.65)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.95
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 2.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.05, 0.1)
	env.fog_density = 0.012
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	env.adjustment_contrast = 1.05
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.75, 0.8, 1.0)
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	sun.rotation_degrees = Vector3(-60, -25, 0)
	add_child(sun)

func _build_pedestal() -> void:
	pedestal = Node3D.new()
	pedestal.position = Vector3(0, 0, 3)
	add_child(pedestal)
	var base := MeshInstance3D.new()
	base.mesh = Rig.cyl(1.1, 1.25, 0.3, 32)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.28, 0.3)
	m.roughness = 0.6
	base.material_override = m
	base.position.y = 0.15
	pedestal.add_child(base)
	var rim := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 1.1
	t.outer_radius = 1.2
	rim.mesh = t
	rim.scale = Vector3(1, 0.3, 1)
	rim.position.y = 0.3
	rim.material_override = Rig.glow_mat(Color(1, 0.75, 0.3), 1.0)
	pedestal.add_child(rim)
	spot = SpotLight3D.new()
	spot.position = Vector3(0, 6, 1.5)
	spot.rotation_degrees = Vector3(-75, 0, 0)
	spot.spot_angle = 28.0
	spot.light_energy = 2.0
	spot.spot_range = 12.0
	spot.shadow_enabled = true
	pedestal.add_child(spot)

# ---------------- MENÚ ----------------
func go_menu() -> void:
	get_tree().paused = false
	Sfx.set_intense(false)
	state = "menu"
	if lineup:
		lineup.queue_free()
		lineup = null
	Sfx.play_music("title")
	clear_level()
	if player:
		player.queue_free()
		player = null
	arena.clear_level()
	arena.close_portal()
	arena.set_biome(GameData.CHAPTERS[chapter].biome, env)
	pedestal.visible = true
	show_hero(sel)
	ui.show_menu()

func show_hero(i: int) -> void:
	sel = wrapi(i, 0, hero_keys.size())
	if showcase:
		showcase.queue_free()
	var key: String = hero_keys[sel]
	showcase = Builder.hero(key)
	pedestal.add_child(showcase)
	showcase.position.y = 0.3
	showcase.rotation.y = 0.4
	spot.light_color = GameData.HEROES[key].color.lightened(0.5)
	FX.burst(pedestal.global_position + Vector3(0, 1, 0), GameData.HEROES[key].color, 40, 4.0, 0.06, 0.9, -2.0)
	ui.update_menu(key)
	if showcase is CharModel:
		if GameData.is_unlocked(key):
			showcase.action("Cheer")
		else:
			showcase.silhouette(true)

func upgrade_weapon() -> void:
	var key: String = hero_keys[sel]
	var cost := 40 * GameData.wl(key)
	if GameData.coins < cost:
		return
	GameData.coins -= cost
	GameData.weapon_level[key] = GameData.wl(key) + 1
	GameData.save_game()
	Sfx.play("upgrade", 0.0, 0.0)
	FX.burst(pedestal.global_position + Vector3(0, 1.2, 0), Color(1, 0.8, 0.25), 60, 6.0, 0.07, 1.0, -3.0)
	FX.ring(pedestal.global_position, 2.0, Color(1, 0.8, 0.25), 0.6)
	ui.update_menu(key)

# ---------------- PARTIDA ----------------
func start_run() -> void:
	if not GameData.is_unlocked(hero_keys[sel]):
		return
	var story_key := "intro_%d" % chapter
	if not story_key in GameData.story_seen:
		GameData.story_seen.append(story_key)
		GameData.save_game()
		if lineup:
			lineup.queue_free()
			lineup = null
		if showcase:
			showcase.queue_free()
			showcase = null
		pedestal.visible = false
		cine.intro(chapter, _begin_run)
		return
	_begin_run()

func _begin_run() -> void:
	get_tree().paused = false
	clear_level()
	if player:
		player.queue_free()
	if showcase:
		showcase.queue_free()
		showcase = null
	pedestal.visible = false
	player = PlayerScript.new()
	add_child(player)
	player.setup(self, hero_keys[sel])
	level = 1
	run_coins = 0
	ui.set_abilities(player.abilities)
	load_level()

func load_level() -> void:
	clear_level()
	var ch: Dictionary = GameData.CHAPTERS[chapter]
	arena.set_biome(ch.biome, env)
	Sfx.play_music(ch.biome)
	arena.gen_level(level)
	if level > 1 and GameData.talent("t_regen") > 0:
		player.heal(player.max_hp * GameData.talent_value("t_regen") / 100.0)
	player.global_position = Vector3(0, 0, Arena.H / 2 - 2)
	player.rig.rotation.y = PI
	portal_open = false
	arena.close_portal()
	level_time = 0.0
	var boss := level % 5 == 0
	var banner := "SALA %d" % level
	var count: int = 4 + int(level * 0.35) + chapter * 2
	if level == GameData.MAX_LEVEL:
		spawn_enemy("boss", Vector3(0, 0, -5), 0.6, true)
		banner = ch.boss.to_upper()
		count = 2
	elif level % 10 == 0:
		spawn_enemy("boss", Vector3(0, 0, -5), 0.6)
		banner = "¡JEFE!"
		count = 1 + chapter
	elif boss:
		spawn_enemy("champion", Vector3(0, 0, -5), 0.6)
		banner = "¡CAMPEÓN!"
		count = 2 + chapter
	var g := difficulty()
	for i in count:
		var r := randf()
		var t := "skeleton"
		if g > 1 and r < 0.18 + g * 0.006:
			t = "skmage"
		elif g > 5 and r < 0.3 + g * 0.008:
			t = "brute"
		elif g > 2 and r < 0.55:
			t = "rogue"
		spawn_enemy(t, arena.random_spawn(player.global_position, 5.0), i * 0.12)
	state = "play"
	Sfx.play("level", -4.0, 0.0)
	ui.show_hud()
	ui.show_banner(banner, Color(1, 0.55, 0.5) if boss else Color.WHITE)

func clear_level() -> void:
	for g in ["enemies", "projectiles", "coins", "minions"]:
		for n in get_tree().get_nodes_in_group(g):
			n.remove_from_group(g)
			n.queue_free()

func get_enemies() -> Array:
	return get_tree().get_nodes_in_group("enemies")

func nearest_enemy(pos: Vector3, exclude := [], max_d := INF):
	var best = null
	var bd: float = max_d
	for e in get_enemies():
		if not e.is_active() or e in exclude:
			continue
		var d: float = Vector2(e.global_position.x - pos.x, e.global_position.z - pos.z).length()
		if d < bd:
			bd = d
			best = e
	return best

func spawn_enemy(type: String, pos: Vector3, delay := 0.0, final := false) -> void:
	var e = EnemyScript.new()
	add_child(e)
	e.global_position = pos
	e.setup(self, type, difficulty(), delay, final)
	Sfx.play("roar" if type == "boss" else "spawn", -10.0 if type != "boss" else 0.0)
	FX.ring(pos, 1.2 if type != "boss" else 2.5, Color(0.6, 0.3, 1), 0.8)
	FX.burst(pos + Vector3.UP * 0.2, Color(0.6, 0.3, 1), 14, 3.0, 0.05, 0.7, 2.0)

func shoot(from: Vector3, vel: Vector3, opts: Dictionary) -> void:
	var p = ProjectileScript.new()
	add_child(p)
	p.global_position = Vector3(from.x, 0.9, from.z)
	opts["vel"] = vel
	p.setup(self, opts)
	p.orient()
	if opts.get("enemy", false):
		Sfx.play("eshot", -14.0)
	else:
		Sfx.play({"arrow": "arrow", "big": "arrow", "fire": "fire", "dagger": "dagger", "bolt": "bolt", "wave": "wave"}.get(opts.get("kind", "arrow"), "arrow"), -13.0)

func explode(pos: Vector3, r: float, dmg: float, color: Color, extra := Callable(), fx := true) -> void:
	if fx:
		Sfx.play("boom", -9.0)
		FX.ring(pos, r, color)
		FX.burst(pos + Vector3.UP * 0.4, color, 24, r * 2.5, 0.08, 0.5, -4.0)
	for e in get_enemies():
		if not is_instance_valid(e) or not e.is_active():
			continue
		if Vector2(e.global_position.x - pos.x, e.global_position.z - pos.z).length() < r + e.radius:
			if extra.is_valid():
				extra.call(e)
			e.hurt(dmg)

func spawn_coins(pos: Vector3, value: int) -> void:
	var n: int = clamp(value, 1, 8)
	for i in n:
		var c = CoinScript.new()
		add_child(c)
		c.global_position = pos + Vector3.UP * 0.5
		c.setup(self, value / n + (1 if i < value % n else 0))

func collect_coin(v: int, pos: Vector3) -> void:
	run_coins += int(ceil(v * (1.0 + GameData.talent_value("t_codicia") / 100.0)))
	Sfx.play("coin", -14.0, 0.1)
	FX.burst(pos, Color(1, 0.8, 0.2), 5, 2.0, 0.04, 0.3, 0)

func spawn_minion(pos: Vector3, dmg: float, duration: float) -> void:
	var m = MinionScript.new()
	add_child(m)
	m.global_position = pos
	m.setup(self, dmg, duration)
	FX.burst(pos + Vector3.UP * 0.3, Color(0.4, 1, 0.5), 20, 3.0, 0.06, 0.7, 2.0)

func hit_stop(t: float) -> void:
	Engine.time_scale = 0.1
	await get_tree().create_timer(t * 0.1, true, false, false).timeout
	Engine.time_scale = 1.0

func _physics_process(delta: float) -> void:
	if state != "play" or player == null:
		return
	level_time += delta
	if not portal_open and level_time > 1.2 and get_enemies().is_empty():
		portal_open = true
		arena.open_portal()
		Sfx.play("portal")
		ui.show_banner("¡SALA DESPEJADA!", Color(0.4, 1, 0.7))
		for p in get_tree().get_nodes_in_group("projectiles"):
			if p.enemy:
				p.queue_free()
	if portal_open and arena.in_portal(player.global_position):
		room_cleared()

func room_cleared() -> void:
	state = "story"
	for c in get_tree().get_nodes_in_group("coins"):
		collect_coin(c.value, c.global_position)
	GameData.record_progress(chapter, level)
	var new_heroes := GameData.check_unlocks(chapter, level)
	GameData.save_game()
	_after_unlocks(new_heroes)

func _after_unlocks(list: Array) -> void:
	if list.size() > 0:
		var h: String = list.pop_front()
		Sfx.play("win", 0.0, 0.0)
		cine.unlock(h, _after_unlocks.bind(list))
		return
	if level >= GameData.MAX_LEVEL:
		cine.outro(chapter, finish.bind(true))
	else:
		show_choose()

func _process(delta: float) -> void:
	var target_pos: Vector3
	var look: Vector3
	if state == "title":
		title_t += delta
		if lineup:
			for h in lineup.get_children():
				h.animate(delta, 0.0)
		target_pos = Vector3(sin(title_t * 0.12) * 6.0, 2.6, 2.0 + cos(title_t * 0.12) * 6.0)
		look = Vector3(0, 1.4, 1.5)
	elif state == "cutscene":
		target_pos = cine_pos
		look = cine_look
	elif state == "menu":
		if showcase:
			showcase.rotation.y += delta * 0.7
			showcase.animate(delta, 0.0)
		target_pos = pedestal.global_position + Vector3(0, 2.3, 6.4)
		look = pedestal.global_position + Vector3(0, 1.25, 0)
	elif player:
		var pp: Vector3 = player.global_position
		var vp := get_viewport().get_visible_rect().size
		var far: float = 1.0 if vp.x >= vp.y else 1.6
		var cz: float = clamp(pp.z, -Arena.H / 2 + 7.5, Arena.H / 2 - 4.0)
		target_pos = Vector3(pp.x * 0.4, 16.5 * far, cz + 6.5 * far)
		look = Vector3(pp.x * 0.4, 0, cz - 3.5)
	else:
		return
	var want := Transform3D(Basis(), target_pos).looking_at(look, Vector3.UP)
	var k := 1.0 - exp((-1.8 if state == "cutscene" else -5.0) * delta)
	var tr := cam.global_transform.interpolate_with(want, k)
	cam.global_transform = tr
	cam.h_offset = randf_range(-1, 1) * FX.shake_amount * 0.5
	cam.v_offset = randf_range(-1, 1) * FX.shake_amount * 0.5
	FX.shake_amount = move_toward(FX.shake_amount, 0.0, delta * 2.0)
	if player and state != "menu":
		ui.update_hud(player, level, run_coins)

# ---------------- CARTAS / FIN ----------------
func show_choose() -> void:
	state = "choose"
	var h: Dictionary = GameData.HEROES[player.key]
	var pool := []
	for p in h.passives + ["dmg", "rate", "hp", "heal", "spd"]:
		if not player.can_take(p):
			continue
		var d: Array = GameData.PASSIVES[p]
		var common: bool = p in ["dmg", "rate", "hp", "heal", "spd"]
		pool.append({"tag": "MEJORA", "icon": p, "title": d[0], "desc": d[1], "rarity": "common" if common else "rare",
			"color": Color(0.75, 0.8, 0.9) if common else Color(0.45, 0.75, 1.0), "cb": player.apply_passive.bind(p), "w": 1.0})
	for a in player.abilities:
		var info: Dictionary = GameData.ABILITIES[a.key]
		if a.lvl == 0:
			pool.append({"tag": "NUEVA", "icon": a.key, "title": info.name, "desc": info.desc, "rarity": "legend",
				"color": info.color, "cb": _level_ability.bind(a), "w": 3.0})
		elif a.lvl < player.ABILITY_MAX:
			pool.append({"tag": "NIVEL %d" % (a.lvl + 1), "icon": a.key, "title": info.name, "rarity": "epic",
				"desc": "Más daño y -15% de tiempo de recarga", "color": info.color, "cb": _level_ability.bind(a), "w": 1.6})
	var luck := 1.0 + GameData.talent_value("t_suerte") / 100.0
	for o in pool:
		if o.rarity != "common":
			o.w *= luck
	var picks := []
	while picks.size() < 3 and pool.size() > 0:
		var total := 0.0
		for o in pool:
			total += o.w
		var r := randf() * total
		for o in pool:
			r -= o.w
			if r <= 0.0:
				picks.append(o)
				pool.erase(o)
				break
	ui.show_choose(picks)

func _level_ability(a: Dictionary) -> void:
	a.lvl += 1
	a.t = min(a.t, 1.0)

func pick_option(o: Dictionary) -> void:
	if state != "choose":
		return
	Sfx.play("pick", 0.0, 0.0)
	o.cb.call()
	level += 1
	load_level()

func on_player_died() -> void:
	state = "dying"
	Sfx.play("death", 0.0, 0.0)
	await get_tree().create_timer(1.3).timeout
	if state == "dying":
		finish(false)

func finish(win: bool) -> void:
	state = "end"
	GameData.record_progress(chapter, level if win else level - 1)
	if win:
		Sfx.play("win", 0.0, 0.0)
	GameData.coins += run_coins
	GameData.save_game()
	ui.show_end(win, level, run_coins)

func toggle_pause() -> void:
	if state == "play":
		state = "pause"
		get_tree().paused = true
		ui.set_paused(true)
	elif state == "pause":
		state = "play"
		get_tree().paused = false
		ui.set_paused(false)
