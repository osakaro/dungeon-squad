extends Node
## Datos globales: héroes, habilidades, mejoras y guardado.

const MAX_LEVEL := 10
const SAVE_PATH := "user://dungeonsquad.cfg"

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

var coins := 0
var weapon_level := {}

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

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "coins", coins)
	cfg.set_value("save", "weapon_level", weapon_level)
	cfg.save(SAVE_PATH)
