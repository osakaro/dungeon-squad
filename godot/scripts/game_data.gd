extends Node
## Datos globales: héroes, habilidades, mejoras y guardado.

const MAX_LEVEL := 25          # salas por capítulo
const START_HERO := "guerrero"

## Capítulos: cada uno tiene 25 salas y un bioma distinto alrededor del mapa.
const CHAPTERS := [
	{"name": "El Bosque Susurrante", "biome": "forest", "boss": "Rey del Bosque Marchito",
		"intro": ["Hace siglos, el escuadrón de héroes mantenía la paz en el reino de Valdoria.",
			"Pero el nigromante Malakar ha despertado y su ejército de esqueletos devora el Bosque Susurrante.",
			"Sir Aldric, el último caballero en pie, se adentra solo en la espesura...",
			"Debe encontrar a sus compañeros perdidos y reunir de nuevo al DUNGEON SQUAD."],
		"outro": ["El Rey del Bosque Marchito cae y los árboles vuelven a respirar.",
			"Pero las huellas de Malakar se pierden hacia el norte, entre montañas de hielo eterno..."]},
	{"name": "Las Cumbres Heladas", "biome": "ice", "boss": "Rey Escarcha",
		"intro": ["El viento corta como una espada en las Cumbres Heladas.",
			"Malakar ha encerrado aquí a los héroes que se atrevieron a desafiarle.",
			"Entre la nieve se oyen pasos rápidos... y el crujir de huesos congelados."],
		"outro": ["El Rey Escarcha se quiebra en mil pedazos de hielo.",
			"Morvek, un hechicero esqueleto que odia a Malakar, decide unirse al escuadrón.",
			"Juntos parten hacia el último refugio del nigromante: el Corazón del Volcán."]},
	{"name": "El Corazón del Volcán", "biome": "lava", "boss": "Malakar, Señor de las Cenizas",
		"intro": ["La roca arde bajo los pies del escuadrón.",
			"En lo más profundo del volcán, Malakar prepara el ritual que despertará a todos los muertos de Valdoria.",
			"Es ahora o nunca, héroes."],
		"outro": ["Malakar se desvanece entre las llamas y su ejército se convierte en polvo.",
			"Valdoria vuelve a ser libre. El DUNGEON SQUAD será recordado para siempre.",
			"¡GRACIAS POR JUGAR!"]},
]

## Cuándo se desbloquea cada héroe: [capítulo, sala superada]
const UNLOCKS := {
	"guerrero": [-1, 0],
	"arquero": [0, 10],
	"mago": [0, 25],
	"asesino": [1, 10],
	"nigromante": [1, 25],
}
const UNLOCK_STORY := {
	"arquero": "Entre las ramas encuentras a Lyra, la arquera élfica, atrapada en una jaula de huesos. Tras liberarla, tensa su ballesta: «Malakar pagará por esto».",
	"mago": "Eldrin, el viejo mago, te esperaba al final del bosque. «Sabía que vendrías, caballero. Mi fuego está a tu servicio».",
	"asesino": "Una sombra cae del techo helado. Es Kael, el asesino, que llevaba semanas cazando esqueletos en solitario. «Por fin alguien que sabe pelear».",
	"nigromante": "Morvek, el hechicero esqueleto, se arrodilla ante el escuadrón. «Malakar me robó la vida. Ahora usaré su magia contra él».",
}
const SAVE_PATH := "user://dungeonsquad_v2.cfg"

const HEROES := {
	"arquero": {"name": "Arquero", "desc": "Dispara flechas rápidas a distancia. Frágil pero letal.",
		"hp": 100.0, "dmg": 12.0, "rate": 2.2, "speed": 6.5, "color": Color(0.3, 0.8, 0.4),
		"abilities": ["lluvia", "cargado"], "passives": ["multi", "pierce", "bounce", "diag"]},
	"mago": {"name": "Mago", "desc": "Lanza bolas de fuego que explotan en área.",
		"hp": 80.0, "dmg": 18.0, "rate": 1.2, "speed": 5.8, "color": Color(0.55, 0.45, 1.0),
		"abilities": ["meteoro", "hielo"], "passives": ["aoe", "chain", "multi", "orb"]},
	"guerrero": {"name": "Guerrero", "desc": "Tajos cuerpo a cuerpo en arco. Aguanta muchísimo.",
		"hp": 170.0, "dmg": 28.0, "rate": 1.4, "speed": 6.0, "color": Color(0.95, 0.35, 0.3),
		"abilities": ["torbellino", "grito"], "passives": ["arc", "wave", "lifesteal", "thorns"]},
	"asesino": {"name": "Asesino", "desc": "Dagas veloces y golpes críticos devastadores.",
		"hp": 90.0, "dmg": 9.0, "rate": 3.2, "speed": 7.4, "color": Color(0.85, 0.2, 0.35),
		"abilities": ["abanico", "sombra"], "passives": ["crit", "multi", "pierce", "spdpas"]},
	"nigromante": {"name": "Nigromante", "desc": "Rayos que roban vida. Invoca esqueletos que luchan por él.",
		"hp": 95.0, "dmg": 14.0, "rate": 1.6, "speed": 5.8, "color": Color(0.4, 1.0, 0.55),
		"abilities": ["esqueleto", "drenaje"], "passives": ["lifesteal", "chain", "orb", "multi"]},
}

const ABILITIES := {
	"lluvia": {"name": "Lluvia de flechas", "short": "LL", "cd": 6.0, "color": Color(0.5, 0.8, 1.0), "desc": "Cae una lluvia de flechas sobre el enemigo más cercano."},
	"cargado": {"name": "Disparo cargado", "short": "DC", "cd": 5.0, "color": Color(0.4, 0.9, 1.0), "desc": "Flecha enorme que atraviesa a todos."},
	"meteoro": {"name": "Meteoro", "short": "ME", "cd": 7.0, "color": Color(1.0, 0.45, 0.1), "desc": "Un meteoro cae del cielo y arrasa la zona."},
	"hielo": {"name": "Nova de hielo", "short": "NH", "cd": 8.0, "color": Color(0.6, 0.95, 1.0), "desc": "Onda helada que daña y ralentiza."},
	"torbellino": {"name": "Torbellino", "short": "TO", "cd": 7.0, "color": Color(1.0, 0.9, 0.5), "desc": "Giras con la espada dañando todo a tu alrededor."},
	"grito": {"name": "Grito de guerra", "short": "GR", "cd": 10.0, "color": Color(1.0, 0.6, 0.15), "desc": "Aturde a los enemigos cercanos y te protege."},
	"abanico": {"name": "Abanico de dagas", "short": "AB", "cd": 4.0, "color": Color(0.85, 0.85, 0.95), "desc": "Lanzas dagas en todas direcciones."},
	"sombra": {"name": "Paso sombrío", "short": "PS", "cd": 6.0, "color": Color(0.7, 0.35, 1.0), "desc": "Te teletransportas tras un enemigo y le das un crítico."},
	"esqueleto": {"name": "Invocar esqueletos", "short": "IE", "cd": 9.0, "color": Color(0.9, 0.9, 0.8), "desc": "Levanta esqueletos que atacan por ti."},
	"drenaje": {"name": "Drenaje vital", "short": "DV", "cd": 6.0, "color": Color(0.4, 1.0, 0.5), "desc": "Roba vida de todos los enemigos cercanos."},
}

const PASSIVES := {
	"multi": ["Disparo múltiple", "+1 proyectil por ataque"],
	"pierce": ["Perforación", "Los proyectiles atraviesan +1 enemigo"],
	"bounce": ["Rebote", "Los proyectiles rebotan en las paredes"],
	"diag": ["Abanico", "+2 proyectiles en diagonal"],
	"aoe": ["Gran explosión", "+50% radio de explosión"],
	"chain": ["Cadena", "Los proyectiles saltan a +1 enemigo"],
	"orb": ["Orbe arcano", "Un orbe gira a tu alrededor y daña"],
	"arc": ["Tajo amplio", "+40% alcance del golpe"],
	"wave": ["Onda de choque", "Cada tajo lanza una onda"],
	"lifesteal": ["Vampirismo", "Recuperas vida al golpear"],
	"thorns": ["Espinas", "Dañas a quien te toca"],
	"crit": ["Letalidad", "+15% probabilidad de crítico"],
	"spdpas": ["Sombra veloz", "+20% velocidad y +10% ataque"],
	"dmg": ["Poder", "+30% daño"],
	"rate": ["Frenesí", "+25% velocidad de ataque"],
	"hp": ["Vitalidad", "+25 vida máxima"],
	"heal": ["Poción", "Recupera el 50% de la vida"],
	"spd": ["Botas ligeras", "+15% velocidad de movimiento"],
}

## Mejoras permanentes del personaje (valen para todos los héroes)
## [nombre, descripción con %s, valor por nivel, nivel máximo, coste base]
const TALENTS := {
	"t_vida": ["Vitalidad", "+%d%% vida máxima", 8, 10, 30],
	"t_fuerza": ["Fuerza", "+%d%% daño", 6, 10, 35],
	"t_ataque": ["Destreza", "+%d%% velocidad de ataque", 4, 8, 40],
	"t_agilidad": ["Agilidad", "+%d%% velocidad de movimiento", 3, 6, 30],
	"t_critico": ["Precisión", "+%d%% probabilidad de crítico", 2, 8, 45],
	"t_armadura": ["Armadura", "-%d%% daño recibido", 3, 8, 50],
	"t_regen": ["Regeneración", "Recuperas %d%% de vida en cada sala", 2, 5, 60],
	"t_suerte": ["Suerte", "+%d%% cartas raras, épicas y legendarias", 10, 5, 55],
	"t_codicia": ["Codicia", "+%d%% monedas", 10, 5, 40],
}
var talents := {}
var mastery := {}      # héroe -> nivel inicial extra de su habilidad principal (0-2)
var dual := []         # héroes con la segunda habilidad desbloqueada desde el inicio

func talent(k: String) -> int:
	return int(talents.get(k, 0))

func talent_value(k: String) -> float:
	return talent(k) * float(TALENTS[k][2])

func talent_cost(k: String) -> int:
	return int(TALENTS[k][4] * pow(1.45, talent(k)))

func buy_talent(k: String) -> bool:
	var c := talent_cost(k)
	if coins < c or talent(k) >= int(TALENTS[k][3]):
		return false
	coins -= c
	talents[k] = talent(k) + 1
	save_game()
	return true

func weapon_cost(h: String) -> int:
	return int(40 * pow(1.5, wl(h) - 1))

func mastery_cost(h: String) -> int:
	return 150 * (int(mastery.get(h, 0)) + 1)

const DUAL_COST := 300

func buy(kind: String, h: String) -> bool:
	var c := 0
	match kind:
		"weapon": c = weapon_cost(h)
		"mastery": c = mastery_cost(h) if int(mastery.get(h, 0)) < 2 else 999999
		"dual": c = DUAL_COST if not h in dual else 999999
	if coins < c:
		return false
	coins -= c
	match kind:
		"weapon": weapon_level[h] = wl(h) + 1
		"mastery": mastery[h] = int(mastery.get(h, 0)) + 1
		"dual": dual.append(h)
	save_game()
	return true

var coins := 0
var weapon_level := {}
var unlocked := ["guerrero"]
var chapter_best := {}       # capítulo -> mejor sala alcanzada
var chapters_open := 1
var story_seen := []
var music_on := true
var sfx_on := true

func is_unlocked(hero: String) -> bool:
	return hero in unlocked

func unlock_text(hero: String) -> String:
	var u: Array = UNLOCKS[hero]
	return "Se desbloquea al superar la sala %d del capítulo %d" % [u[1], u[0] + 1]

## Devuelve los héroes que se desbloquean al superar esta sala
func check_unlocks(chapter: int, room: int) -> Array:
	var res := []
	for h in UNLOCKS:
		var u: Array = UNLOCKS[h]
		if u[0] == chapter and u[1] == room and not h in unlocked:
			unlocked.append(h)
			res.append(h)
	return res

func record_progress(chapter: int, room: int) -> void:
	chapter_best[chapter] = max(int(chapter_best.get(chapter, 0)), room)
	if room >= MAX_LEVEL and chapter + 1 < CHAPTERS.size():
		chapters_open = max(chapters_open, chapter + 2)

func _ready() -> void:
	_setup_input()
	load_game()

func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "pause": [KEY_ESCAPE, KEY_P],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)
		for k in keys[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
	var axes := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in axes:
		var j := InputEventJoypadMotion.new()
		j.axis = axes[action][0]
		j.axis_value = axes[action][1]
		InputMap.action_add_event(action, j)
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	InputMap.action_add_event("pause", start)

func wl(key: String) -> int:
	return int(weapon_level.get(key, 1))

func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		coins = int(cfg.get_value("save", "coins", 0))
		weapon_level = cfg.get_value("save", "weapon_level", {})
		unlocked = cfg.get_value("save", "unlocked", ["guerrero"])
		chapter_best = cfg.get_value("save", "chapter_best", {})
		chapters_open = int(cfg.get_value("save", "chapters_open", 1))
		story_seen = cfg.get_value("save", "story_seen", [])
		music_on = bool(cfg.get_value("save", "music_on", true))
		sfx_on = bool(cfg.get_value("save", "sfx_on", true))
		talents = cfg.get_value("save", "talents", {})
		mastery = cfg.get_value("save", "mastery", {})
		dual = cfg.get_value("save", "dual", [])

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "coins", coins)
	cfg.set_value("save", "weapon_level", weapon_level)
	cfg.set_value("save", "unlocked", unlocked)
	cfg.set_value("save", "chapter_best", chapter_best)
	cfg.set_value("save", "chapters_open", chapters_open)
	cfg.set_value("save", "story_seen", story_seen)
	cfg.set_value("save", "music_on", music_on)
	cfg.set_value("save", "sfx_on", sfx_on)
	cfg.set_value("save", "talents", talents)
	cfg.set_value("save", "mastery", mastery)
	cfg.set_value("save", "dual", dual)
	cfg.save(SAVE_PATH)
