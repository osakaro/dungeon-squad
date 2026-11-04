extends Node3D
## Bucle principal: estados del juego, niveles, cámara y creación de entidades.

const PlayerScript := preload("res://scripts/player.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const ProjectileScript := preload("res://scripts/projectile.gd")
const CoinScript := preload("res://scripts/coin.gd")
const MinionScript := preload("res://scripts/minion.gd")
const UIScript := preload("res://scripts/ui.gd")

var state := "menu"          # menu, play, choose, end, pause
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
var level := 1
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
	hero_keys = GameData.HEROES.keys()
	go_menu()

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
	rim.material_override = Rig.glow_mat(Color(1, 0.75, 0.3), 3.0)
	pedestal.add_child(rim)
	spot = SpotLight3D.new()
	spot.position = Vector3(0, 6, 1.5)
	spot.rotation_degrees = Vector3(-75, 0, 0)
	spot.spot_angle = 28.0
	spot.light_energy = 3.0
	spot.spot_range = 12.0
	spot.shadow_enabled = true
	pedestal.add_child(spot)

# ---------------- MENÚ ----------------
func go_menu() -> void:
	get_tree().paused = false
	Sfx.set_intense(false)
	state = "menu"
	clear_level()
	if player:
		player.queue_free()
		player = null
	arena.clear_level()
	arena.close_portal()
	arena.set_theme(0, env)
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
		showcase.action("Cheer")

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
	arena.set_theme(0 if level <= 5 else 1, env)
	arena.gen_level(level)
	player.global_position = Vector3(0, 0, Arena.H / 2 - 2)
	player.rig.rotation.y = PI
	portal_open = false
	arena.close_portal()
	level_time = 0.0
	var boss := level % 5 == 0
	if boss:
		spawn_enemy("boss", Vector3(0, 0, -5), 0.6)
	var count: int = (1 + level / 5) if boss else 3 + level
	for i in count:
		var r := randf()
		var t := "slime"
		if r < 0.22 + level * 0.02:
			t = "crystal"
		elif level > 2 and r < 0.38 + level * 0.03:
			t = "brute"
		elif level > 1 and r < 0.52:
			t = "bat"
		elif level > 1 and r < 0.8:
			t = "skeleton"
		spawn_enemy(t, arena.random_spawn(player.global_position, 5.0), i * 0.12)
	state = "play"
	Sfx.set_intense(boss)
	Sfx.play("level", -4.0, 0.0)
	ui.show_hud()
	ui.show_banner("¡JEFE!" if boss else "NIVEL %d" % level, Color(1, 0.3, 0.25) if boss else ui.GOLD)

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

func spawn_enemy(type: String, pos: Vector3, delay := 0.0) -> void:
	var e = EnemyScript.new()
	add_child(e)
	e.global_position = pos
	e.setup(self, type, level, delay)
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
		Sfx.play("eshot", -6.0)
	else:
		Sfx.play({"arrow": "arrow", "big": "arrow", "fire": "fire", "dagger": "dagger", "bolt": "bolt", "wave": "wave"}.get(opts.get("kind", "arrow"), "arrow"), -4.0)

func explode(pos: Vector3, r: float, dmg: float, color: Color, extra := Callable(), fx := true) -> void:
	if fx:
		Sfx.play("boom", -3.0)
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
	run_coins += v
	Sfx.play("coin", -8.0, 0.15)
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
		if level >= GameData.MAX_LEVEL:
			finish(true)
		else:
			show_choose()

func _process(delta: float) -> void:
	var target_pos: Vector3
	var look: Vector3
	if state == "menu":
		if showcase:
			showcase.rotation.y += delta * 0.7
			showcase.animate(delta, 0.0)
		target_pos = pedestal.global_position + Vector3(-1.5, 2.0, 5.2)
		look = pedestal.global_position + Vector3(-1.5, 1.0, 0)
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
	var k := 1.0 - exp(-5.0 * delta)
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
		var d: Array = GameData.PASSIVES[p]
		pool.append({"tag": "MEJORA", "icon": "+", "title": d[0], "desc": d[1], "color": Color(0.45, 0.75, 1.0),
			"cb": player.apply_passive.bind(p), "w": 1.0})
	for a in player.abilities:
		var info: Dictionary = GameData.ABILITIES[a.key]
		if a.lvl == 0:
			pool.append({"tag": "NUEVA HABILIDAD", "icon": info.short, "title": info.name, "desc": info.desc,
				"color": ui.GOLD, "cb": _level_ability.bind(a), "w": 3.0})
		else:
			pool.append({"tag": "HABILIDAD  Nv %d" % (a.lvl + 1), "icon": info.short, "title": info.name,
				"desc": "Más daño y -15% de cooldown", "color": info.color, "cb": _level_ability.bind(a), "w": 1.6})
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
