extends CanvasLayer
## Interfaz: menú con selección de héroe, HUD, cartas de mejora, pausa, fin de partida y joystick táctil.

const GOLD := Color(1.0, 0.8, 0.25)
const GREY := Color(0.75, 0.75, 0.82)

var main
var joy_vec := Vector2.ZERO
var joy_index := -1
var joy_origin := Vector2.ZERO

var hud: Control
var lbl_level: Label
var hp_bar: ProgressBar
var hp_lbl: Label
var lbl_coins: Label
var ab_row: HBoxContainer
var ab_widgets := []
var boss_box: VBoxContainer
var boss_bar: ProgressBar
var boss_name: Label
var banner: Label
var joy_base: Panel
var joy_knob: Panel

var menu: Control
var m_name: Label
var m_desc: Label
var m_stats: VBoxContainer
var m_abil: VBoxContainer
var m_weapon: Label
var m_upgrade: Button
var m_coins: Label

var choose: Control
var cards_row: HBoxContainer
var endscr: Control
var end_title: Label
var end_text: Label
var pause_scr: Control
var title_scr: Control
var title_hint: Label
var story_scr: Control
var story_title: Label
var story_text: Label
var story_btn: Button
var story_lines := []
var story_idx := 0
var story_cb: Callable
var m_play: Button
var m_chapter: Label
var m_chapter_best: Label
var m_lock: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	_build_menu()
	_build_choose()
	_build_end()
	_build_pause()
	_build_title()
	_build_story()
	hide_all()

# ---------------- helpers ----------------
func sb(c: Color, r := 14, border := Color(0, 0, 0, 0), bw := 0, margin := 12.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(r)
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	s.set_content_margin_all(margin)
	s.anti_aliasing = true
	return s

func lbl(text: String, size := 18, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", max(4, size / 5))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func wrapl(l: Label, w: float) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = w
	return l

func btn(text: String, cb: Callable, size := 22, color := GOLD) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", sb(color.darkened(0.1), 12, color.lightened(0.3), 2, 10))
	b.add_theme_stylebox_override("hover", sb(color.lightened(0.2), 12, Color.WHITE, 2, 10))
	b.add_theme_stylebox_override("pressed", sb(color.darkened(0.35), 12, color, 2, 10))
	b.add_theme_stylebox_override("disabled", sb(Color(0.25, 0.25, 0.28), 12, Color(0.4, 0.4, 0.4), 2, 10))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(s, Color(0.08, 0.05, 0.02))
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))
	b.custom_minimum_size = Vector2(0, 50)
	b.pressed.connect(func(): Sfx.play("click", -4.0, 0.0))
	b.pressed.connect(cb)
	return b

func full(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c

func ig(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func margin(m: int) -> MarginContainer:
	var mc := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(s, m)
	full(mc)
	ig(mc)
	return mc

func bar(fill: Color, h := 22.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, h)
	b.add_theme_stylebox_override("background", sb(Color(0.05, 0.04, 0.06, 0.9), 8, Color(0, 0, 0), 2, 0))
	b.add_theme_stylebox_override("fill", sb(fill, 8, Color(0, 0, 0, 0), 0, 0))
	ig(b)
	return b

func hide_all() -> void:
	for c in [hud, menu, choose, endscr, pause_scr, title_scr, story_scr]:
		c.visible = false

func _clear(c: Node) -> void:
	for ch in c.get_children():
		ch.queue_free()

# ---------------- HUD ----------------
func _build_hud() -> void:
	hud = ig(full(Control.new()))
	add_child(hud)
	var m := margin(18)
	hud.add_child(m)
	var root := ig(VBoxContainer.new())
	m.add_child(root)
	var top := ig(HBoxContainer.new())
	root.add_child(top)
	var left := ig(VBoxContainer.new())
	top.add_child(left)
	lbl_level = lbl("", 22)
	left.add_child(lbl_level)
	var hpwrap := ig(Control.new())
	hpwrap.custom_minimum_size = Vector2(300, 26)
	left.add_child(hpwrap)
	hp_bar = bar(Color(0.25, 0.85, 0.35), 26)
	full(hp_bar)
	hpwrap.add_child(hp_bar)
	hp_lbl = lbl("", 15)
	full(hp_lbl)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hpwrap.add_child(hp_lbl)
	var sp1 := ig(Control.new())
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp1)
	boss_box = ig(VBoxContainer.new())
	boss_box.custom_minimum_size.x = 420
	boss_name = lbl("", 20, Color(1, 0.4, 0.3))
	var bl := boss_name
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(bl)
	boss_bar = bar(Color(0.9, 0.15, 0.2), 18)
	boss_box.add_child(boss_bar)
	top.add_child(boss_box)
	var sp2 := ig(Control.new())
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp2)
	var right := ig(VBoxContainer.new())
	right.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.add_child(right)
	lbl_coins = lbl("", 24, GOLD)
	lbl_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(lbl_coins)
	var pb := btn("II", func(): main.toggle_pause(), 20, Color(0.6, 0.6, 0.7))
	pb.custom_minimum_size = Vector2(52, 46)
	pb.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_child(pb)
	var fill := ig(Control.new())
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(fill)
	ab_row = ig(HBoxContainer.new())
	ab_row.alignment = BoxContainer.ALIGNMENT_END
	ab_row.add_theme_constant_override("separation", 16)
	root.add_child(ab_row)
	banner = lbl("", 72, GOLD)
	full(banner)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.modulate.a = 0.0
	hud.add_child(banner)
	joy_base = ig(Panel.new())
	joy_base.size = Vector2(150, 150)
	joy_base.add_theme_stylebox_override("panel", sb(Color(1, 1, 1, 0.08), 75, Color(1, 1, 1, 0.35), 3, 0))
	joy_base.visible = false
	hud.add_child(joy_base)
	joy_knob = ig(Panel.new())
	joy_knob.size = Vector2(64, 64)
	joy_knob.add_theme_stylebox_override("panel", sb(Color(1, 1, 1, 0.45), 32, Color.WHITE, 2, 0))
	joy_knob.visible = false
	hud.add_child(joy_knob)

func set_abilities(abilities: Array) -> void:
	_clear(ab_row)
	ab_widgets.clear()
	for a in abilities:
		var info: Dictionary = GameData.ABILITIES[a.key]
		var col: Color = info.color
		var v := ig(VBoxContainer.new())
		var p := ig(Panel.new())
		p.custom_minimum_size = Vector2(86, 86)
		p.add_theme_stylebox_override("panel", sb(col.darkened(0.6), 16, col, 3, 0))
		var icon := SkillIcon.new(a.key, col.lightened(0.35))
		full(icon)
		icon.offset_left = 12
		icon.offset_top = 12
		icon.offset_right = -12
		icon.offset_bottom = -12
		p.add_child(icon)
		var cd := ColorRect.new()
		cd.color = Color(0, 0, 0, 0.65)
		full(cd)
		ig(cd)
		p.add_child(cd)
		var cdl := lbl("", 24)
		full(cdl)
		cdl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cdl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(cdl)
		var lv := lbl("", 14, GOLD)
		full(lv)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lv.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lv.offset_right = -6
		lv.offset_bottom = -2
		p.add_child(lv)
		v.add_child(p)
		var nm := lbl(info.name, 13, GREY)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		ab_row.add_child(v)
		ab_widgets.append({"icon": icon, "panel": p, "cd": cd, "cdl": cdl, "lv": lv, "a": a})

func update_hud(p, level: int, coins: int) -> void:
	var h: Dictionary = GameData.HEROES[p.key]
	lbl_level.text = "%s  -  Cap. %d  -  Sala %d / %d" % [h.name, main.chapter + 1, level, GameData.MAX_LEVEL]
	hp_bar.max_value = p.max_hp
	hp_bar.value = p.hp
	hp_lbl.text = "%d / %d" % [ceil(p.hp), p.max_hp]
	lbl_coins.text = "%d monedas" % coins
	for w in ab_widgets:
		var a: Dictionary = w.a
		if a.lvl == 0:
			w.panel.modulate = Color(0.4, 0.4, 0.45)
			w.cd.anchor_top = 0.0
			w.cdl.text = "BLOQ"
			w.icon.modulate.a = 0.25
			w.cdl.add_theme_font_size_override("font_size", 16)
			w.lv.text = ""
		else:
			w.panel.modulate = Color.WHITE
			var frac: float = clamp(a.t / p.cd_of(a), 0.0, 1.0)
			w.cd.anchor_top = 1.0 - frac
			w.cdl.add_theme_font_size_override("font_size", 24)
			w.cdl.text = ("%.1f" % a.t) if a.t > 0.05 else ""
			w.icon.modulate.a = 1.0 if a.t <= 0.05 else 0.35
			w.lv.text = "Nv %d" % a.lvl
	var boss = null
	for e in main.get_enemies():
		if e.is_boss:
			boss = e
	boss_box.modulate.a = 1.0 if boss else 0.0
	if boss:
		boss_name.text = boss.display_name
		boss_bar.max_value = boss.max_hp
		boss_bar.value = boss.hp

func show_banner(text: String, color := GOLD) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", color)
	banner.pivot_offset = banner.size / 2
	var tw := banner.create_tween()
	banner.scale = Vector2.ONE * 1.6
	tw.set_parallel()
	tw.tween_property(banner, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.0)
	tw.chain().tween_property(banner, "modulate:a", 0.0, 0.4)

func show_hud() -> void:
	hide_all()
	hud.visible = true

# ---------------- MENÚ ----------------
func _build_menu() -> void:
	menu = full(Control.new())
	add_child(menu)
	var side := Panel.new()
	side.anchor_bottom = 1.0
	side.offset_right = 540
	side.add_theme_stylebox_override("panel", sb(Color(0.03, 0.03, 0.07, 0.86), 0, Color(1, 0.8, 0.25, 0.4), 0, 0))
	menu.add_child(side)
	var m := margin(34)
	side.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var em := Emblem.new()
	em.custom_minimum_size = Vector2(64, 64)
	head.add_child(em)
	head.add_child(lbl("DUNGEON SQUAD", 44, GOLD))
	v.add_child(head)
	var chap := HBoxContainer.new()
	chap.add_theme_constant_override("separation", 8)
	var cprev := btn("<", func(): main.change_chapter(-1), 18, Color(0.6, 0.6, 0.7))
	cprev.custom_minimum_size = Vector2(44, 40)
	chap.add_child(cprev)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", -4)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_chapter = lbl("", 18, Color.WHITE)
	m_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(m_chapter)
	m_chapter_best = lbl("", 13, GREY)
	m_chapter_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(m_chapter_best)
	chap.add_child(cv)
	var cnext := btn(">", func(): main.change_chapter(1), 18, Color(0.6, 0.6, 0.7))
	cnext.custom_minimum_size = Vector2(44, 40)
	chap.add_child(cnext)
	v.add_child(chap)
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 18)
	v.add_child(sep)
	m_name = lbl("", 42)
	v.add_child(m_name)
	m_desc = wrapl(lbl("", 17, GREY), 460)
	v.add_child(m_desc)
	m_lock = wrapl(lbl("", 17, Color(1, 0.5, 0.4)), 460)
	v.add_child(m_lock)
	m_stats = VBoxContainer.new()
	v.add_child(m_stats)
	v.add_child(lbl("HABILIDADES AUTOMÁTICAS", 15, GOLD))
	m_abil = VBoxContainer.new()
	m_abil.add_theme_constant_override("separation", 8)
	v.add_child(m_abil)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fill)
	m_weapon = lbl("", 17)
	v.add_child(m_weapon)
	m_upgrade = btn("Mejorar arma", func(): main.upgrade_weapon(), 18, Color(0.45, 0.75, 1.0))
	v.add_child(m_upgrade)
	m_coins = lbl("", 20, GOLD)
	v.add_child(m_coins)
	# botones de navegación (abajo a la derecha)
	var nav_m := margin(30)
	menu.add_child(nav_m)
	var nav_v := ig(VBoxContainer.new())
	nav_v.alignment = BoxContainer.ALIGNMENT_END
	nav_m.add_child(nav_v)
	var nav := ig(HBoxContainer.new())
	nav.alignment = BoxContainer.ALIGNMENT_END
	nav.add_theme_constant_override("separation", 12)
	nav_v.add_child(nav)
	var prev := btn("<", func(): main.show_hero(main.sel - 1), 28, Color(0.6, 0.6, 0.7))
	prev.custom_minimum_size = Vector2(70, 64)
	var play := btn("JUGAR", func(): main.start_run(), 32)
	m_play = play
	play.custom_minimum_size = Vector2(240, 64)
	var nxt := btn(">", func(): main.show_hero(main.sel + 1), 28, Color(0.6, 0.6, 0.7))
	nxt.custom_minimum_size = Vector2(70, 64)
	for b in [prev, play, nxt]:
		nav.add_child(b)

func show_menu() -> void:
	hide_all()
	menu.visible = true

func update_menu(key: String) -> void:
	var h: Dictionary = GameData.HEROES[key]
	var col: Color = h.color
	var wl := GameData.wl(key)
	var locked := not GameData.is_unlocked(key)
	m_name.text = h.name.to_upper() if not locked else "???  " + h.name.to_upper()
	m_lock.text = ("BLOQUEADO: " + GameData.unlock_text(key)) if locked else ""
	m_lock.visible = locked
	m_play.disabled = locked
	m_play.text = "BLOQUEADO" if locked else "JUGAR"
	var ch: Dictionary = GameData.CHAPTERS[main.chapter]
	m_chapter.text = "Capítulo %d: %s" % [main.chapter + 1, ch.name]
	m_chapter_best.text = "Mejor: sala %d / %d   -   Capítulos abiertos: %d / %d" % [int(GameData.chapter_best.get(main.chapter, 0)), GameData.MAX_LEVEL, GameData.chapters_open, GameData.CHAPTERS.size()]
	m_name.add_theme_color_override("font_color", col.lightened(0.25))
	m_desc.text = h.desc
	_clear(m_stats)
	for s in [["Vida", h.hp * (1.0 + 0.1 * (wl - 1)), 220.0], ["Daño", h.dmg * h.rate * (1.0 + 0.2 * (wl - 1)), 45.0],
			["Vel. ataque", h.rate, 3.5], ["Movilidad", h.speed, 8.0]]:
		var row := HBoxContainer.new()
		var l := lbl(s[0], 15, GREY)
		l.custom_minimum_size.x = 120
		row.add_child(l)
		var b := bar(col, 12)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.max_value = s[2]
		b.value = s[1]
		row.add_child(b)
		m_stats.add_child(row)
	_clear(m_abil)
	for i in h.abilities.size():
		var info: Dictionary = GameData.ABILITIES[h.abilities[i]]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var p := Panel.new()
		p.custom_minimum_size = Vector2(48, 48)
		p.add_theme_stylebox_override("panel", sb(info.color.darkened(0.6), 10, info.color, 2, 0))
		var ic := SkillIcon.new(h.abilities[i], info.color.lightened(0.35))
		full(ic)
		ic.offset_left = 7
		ic.offset_top = 7
		ic.offset_right = -7
		ic.offset_bottom = -7
		p.add_child(ic)
		row.add_child(p)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		tv.add_child(lbl(info.name + ("" if i == 0 else "  (se desbloquea jugando)"), 16))
		tv.add_child(wrapl(lbl(info.desc + "  CD %ds" % info.cd, 13, GREY), 380))
		row.add_child(tv)
		m_abil.add_child(row)
	m_weapon.text = "Arma nivel %d   (+%d%% daño, +%d%% vida)" % [wl, 20 * (wl - 1), 10 * (wl - 1)]
	var cost := 40 * wl
	m_upgrade.text = "Mejorar arma  -  %d monedas" % cost
	m_upgrade.disabled = GameData.coins < cost
	m_coins.text = "Tienes %d monedas" % GameData.coins

# ---------------- CARTAS ----------------
func _build_choose() -> void:
	choose = full(Control.new())
	add_child(choose)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05, 0.75)
	full(bg)
	choose.add_child(bg)
	var c := CenterContainer.new()
	full(c)
	choose.add_child(c)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 20)
	c.add_child(v)
	var t := lbl("¡SALA SUPERADA!", 52, GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := lbl("Elige una mejora", 20, GREY)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	cards_row = HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 22)
	v.add_child(cards_row)

const RARITY := {
	"common": ["COMÚN", Color(0.7, 0.72, 0.78)],
	"rare": ["RARA", Color(0.35, 0.65, 1.0)],
	"epic": ["ÉPICA", Color(0.75, 0.4, 1.0)],
	"legend": ["LEGENDARIA", Color(1.0, 0.75, 0.2)],
}

func show_choose(options: Array) -> void:
	hide_all()
	choose.visible = true
	_clear(cards_row)
	for i in options.size():
		var o: Dictionary = options[i]
		var r: Array = RARITY[o.rarity]
		var rc: Color = r[1]
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(250, 360)
		cards_row.add_child(holder)
		var b := Button.new()
		b.size = Vector2(250, 360)
		b.pivot_offset = b.size / 2
		var normal := sb(Color(0.07, 0.07, 0.12), 22, rc.darkened(0.15), 4, 0)
		normal.shadow_color = Color(rc.r, rc.g, rc.b, 0.25)
		normal.shadow_size = 10
		var hover := sb(Color(0.11, 0.1, 0.18), 22, rc.lightened(0.35), 5, 0)
		hover.shadow_color = Color(rc.r, rc.g, rc.b, 0.6)
		hover.shadow_size = 26
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", hover)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		holder.add_child(b)
		# franja superior de rareza
		var band := Panel.new()
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bs := sb(rc.darkened(0.25), 0, Color(0, 0, 0, 0), 0, 0)
		bs.corner_radius_top_left = 18
		bs.corner_radius_top_right = 18
		band.add_theme_stylebox_override("panel", bs)
		band.position = Vector2(4, 4)
		band.size = Vector2(242, 34)
		b.add_child(band)
		var rl := lbl(r[0] + "  -  " + o.tag, 14, Color.WHITE)
		rl.size = band.size
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		band.add_child(rl)
		# icono grande en un círculo
		var circ := Panel.new()
		circ.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cs := sb(Color(o.color.r * 0.25, o.color.g * 0.25, o.color.b * 0.25), 70, o.color, 3, 0)
		cs.shadow_color = Color(o.color.r, o.color.g, o.color.b, 0.45)
		cs.shadow_size = 18
		circ.add_theme_stylebox_override("panel", cs)
		circ.position = Vector2(55, 58)
		circ.size = Vector2(140, 140)
		b.add_child(circ)
		var icon := SkillIcon.new(o.icon, o.color.lightened(0.3))
		icon.position = Vector2(25, 25)
		icon.size = Vector2(90, 90)
		circ.add_child(icon)
		var tl := wrapl(lbl(o.title, 24, Color.WHITE), 220)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.position = Vector2(15, 214)
		tl.size.x = 220
		b.add_child(tl)
		var dl := wrapl(lbl(o.desc, 16, GREY), 220)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.position = Vector2(15, 262)
		dl.size.x = 220
		b.add_child(dl)
		b.mouse_entered.connect(func():
			Sfx.play("click", -12.0, 0.2)
			var tw := b.create_tween()
			tw.tween_property(b, "scale", Vector2.ONE * 1.07, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
		b.mouse_exited.connect(func():
			b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.12))
		b.pressed.connect(func():
			for other in cards_row.get_children():
				if other != holder:
					other.create_tween().tween_property(other, "modulate:a", 0.0, 0.2)
			var tw := b.create_tween()
			tw.tween_property(b, "scale", Vector2.ONE * 1.2, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_interval(0.25)
			tw.tween_callback(main.pick_option.bind(o)))
		# animación de entrada: aparece girando desde abajo
		b.modulate.a = 0.0
		b.scale = Vector2(0.05, 1.0)
		b.position.y = 60
		var tw2 := b.create_tween().set_parallel()
		tw2.tween_property(b, "modulate:a", 1.0, 0.25).set_delay(0.15 + i * 0.15)
		tw2.tween_property(b, "scale", Vector2.ONE, 0.35).set_delay(0.15 + i * 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw2.tween_property(b, "position:y", 0.0, 0.35).set_delay(0.15 + i * 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# ---------------- FIN / PAUSA ----------------
func _overlay(title: String, color: Color) -> Array:
	var root := full(Control.new())
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05, 0.8)
	full(bg)
	root.add_child(bg)
	var c := CenterContainer.new()
	full(c)
	root.add_child(c)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	c.add_child(v)
	var t := lbl(title, 60, color)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	return [root, v, t]

func _build_end() -> void:
	var o := _overlay("", GOLD)
	endscr = o[0]
	end_title = o[2]
	end_text = wrapl(lbl("", 20, GREY), 520)
	end_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	o[1].add_child(end_text)
	o[1].add_child(btn("Reintentar", func(): main.start_run(), 24))
	o[1].add_child(btn("Volver al menú", func(): main.go_menu(), 22, Color(0.6, 0.6, 0.7)))

func show_end(win: bool, level: int, coins: int) -> void:
	hide_all()
	endscr.visible = true
	end_title.text = "¡CAPÍTULO COMPLETADO!" if win else "HAS CAÍDO"
	end_title.add_theme_color_override("font_color", GOLD if win else Color(1, 0.3, 0.3))
	end_text.text = "Llegaste a la sala %d y ganaste %d monedas.\nTotal: %d monedas. Mejora el arma de tus héroes en el menú." % [level, coins, GameData.coins]

func _build_pause() -> void:
	var o := _overlay("PAUSA", Color.WHITE)
	pause_scr = o[0]
	o[1].add_child(btn("Continuar", func(): main.toggle_pause(), 24))
	var mus: Button
	mus = btn("Música: " + ("SI" if GameData.music_on else "NO"), func():
		Sfx.set_music_on(not GameData.music_on)
		GameData.save_game()
		mus.text = "Música: " + ("SI" if GameData.music_on else "NO"), 20, Color(0.45, 0.75, 1.0))
	o[1].add_child(mus)
	var snd: Button
	snd = btn("Efectos: " + ("NO" if Sfx.muted else "SI"), func():
		Sfx.set_muted(not Sfx.muted)
		GameData.save_game()
		snd.text = "Efectos: " + ("NO" if Sfx.muted else "SI"), 20, Color(0.45, 0.75, 1.0))
	o[1].add_child(snd)
	o[1].add_child(btn("Abandonar partida", func(): main.go_menu(), 22, Color(0.6, 0.6, 0.7)))

func set_paused(p: bool) -> void:
	pause_scr.visible = p

# ---------------- ENTRADA ----------------
func _unhandled_input(e: InputEvent) -> void:
	if title_scr.visible and ((e is InputEventKey and e.pressed) or (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed) or (e is InputEventJoypadButton and e.pressed)):
		Sfx.play("pick", 0.0, 0.0)
		main.go_menu()
		return
	if story_scr.visible and e is InputEventKey and e.pressed and (e.keycode == KEY_SPACE or e.keycode == KEY_ENTER):
		_story_next()
		return
	if e.is_action_pressed("pause"):
		main.toggle_pause()

func _input(e: InputEvent) -> void:
	if main == null or main.state != "play":
		_reset_joy()
		return
	if e is InputEventScreenTouch:
		if e.pressed and joy_index == -1 and e.position.y > 110:
			joy_index = e.index
			joy_origin = e.position
			joy_base.visible = true
			joy_knob.visible = true
			joy_base.position = joy_origin - joy_base.size / 2
			joy_knob.position = joy_origin - joy_knob.size / 2
		elif not e.pressed and e.index == joy_index:
			_reset_joy()
	elif e is InputEventScreenDrag and e.index == joy_index:
		var d: Vector2 = (e.position - joy_origin).limit_length(70.0)
		joy_vec = d / 70.0
		joy_knob.position = joy_origin + d - joy_knob.size / 2

func _reset_joy() -> void:
	joy_index = -1
	joy_vec = Vector2.ZERO
	if joy_base:
		joy_base.visible = false
		joy_knob.visible = false

# ---------------- PANTALLA DE TÍTULO ----------------
func _build_title() -> void:
	title_scr = ig(full(Control.new()))
	add_child(title_scr)
	var grad := TextureRect.new()
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0, 0, 0, 0.75))
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.45)
	gt.fill_to = Vector2(1.1, 1.1)
	grad.texture = gt
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	full(grad)
	ig(grad)
	title_scr.add_child(grad)
	var c := CenterContainer.new()
	full(c)
	ig(c)
	title_scr.add_child(c)
	var v := ig(VBoxContainer.new())
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -10)
	c.add_child(v)
	var em := Emblem.new()
	em.custom_minimum_size = Vector2(230, 230)
	em.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(em)
	var t1 := lbl("DUNGEON", 110, GOLD)
	t1.add_theme_constant_override("outline_size", 26)
	t1.add_theme_color_override("font_outline_color", Color(0.35, 0.12, 0.02))
	t1.add_theme_constant_override("shadow_offset_y", 10)
	t1.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t1)
	var t2 := lbl("S  Q  U  A  D", 64, Color(1, 1, 1))
	t2.add_theme_constant_override("outline_size", 18)
	t2.add_theme_color_override("font_outline_color", Color(0.6, 0.1, 0.1))
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t2)
	var sp := ig(Control.new())
	sp.custom_minimum_size.y = 50
	v.add_child(sp)
	title_hint = lbl("Pulsa cualquier tecla para empezar", 24, Color(1, 0.95, 0.8))
	title_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title_hint)
	var credit := lbl("Modelos: KayKit (Kay Lousberg)  -  Hecho con Godot", 13, Color(1, 1, 1, 0.5))
	credit.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	credit.position.y -= 34
	credit.position.x -= 200
	credit.size.x = 400
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_scr.add_child(credit)
	# animación del logo
	v.pivot_offset = Vector2(400, 300)

func show_title() -> void:
	hide_all()
	title_scr.visible = true
	title_scr.modulate.a = 0.0
	var tw := title_scr.create_tween()
	tw.tween_property(title_scr, "modulate:a", 1.0, 1.2)
	var blink := title_hint.create_tween().set_loops()
	blink.tween_property(title_hint, "modulate:a", 0.2, 0.8)
	blink.tween_property(title_hint, "modulate:a", 1.0, 0.8)

# ---------------- HISTORIA ----------------
func _build_story() -> void:
	story_scr = full(Control.new())
	add_child(story_scr)
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.01, 0.03, 0.88)
	full(bg)
	story_scr.add_child(bg)
	var c := CenterContainer.new()
	full(c)
	story_scr.add_child(c)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 26)
	c.add_child(v)
	story_title = lbl("", 46, GOLD)
	story_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(story_title)
	story_text = wrapl(lbl("", 26, Color(0.92, 0.9, 0.85)), 820)
	story_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_text.custom_minimum_size.y = 150
	v.add_child(story_text)
	story_btn = btn("Continuar", func(): _story_next(), 22)
	story_btn.custom_minimum_size = Vector2(240, 54)
	story_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(story_btn)

## Muestra una secuencia de textos con efecto máquina de escribir
func show_story(title: String, lines: Array, cb: Callable, color := GOLD) -> void:
	hide_all()
	story_scr.visible = true
	story_title.text = title
	story_title.add_theme_color_override("font_color", color)
	story_lines = lines
	story_idx = -1
	story_cb = cb
	_story_next()

func _story_next() -> void:
	if story_text.visible_ratio < 1.0 and story_idx >= 0:
		story_text.visible_ratio = 1.0
		return
	story_idx += 1
	if story_idx >= story_lines.size():
		story_scr.visible = false
		story_cb.call()
		return
	story_text.text = story_lines[story_idx]
	story_text.visible_ratio = 0.0
	var tw := story_text.create_tween()
	tw.tween_property(story_text, "visible_ratio", 1.0, story_text.text.length() * 0.028)
	story_btn.text = "Continuar" if story_idx < story_lines.size() - 1 else "¡Adelante!"
