extends CanvasLayer
## Interfaz limpia estilo juego de móvil: menú centrado en el héroe, HUD mínimo, cartas y pantallas de historia.

const GOLD := Color(1.0, 0.76, 0.28)
const GREY := Color(0.78, 0.8, 0.86)
const PANEL := Color(0.06, 0.07, 0.11, 0.72)
const FONT_TITLE := preload("res://assets/fonts/LilitaOne.ttf")
const FONT_BOLD := preload("res://assets/fonts/Fredoka-Bold.ttf")

var main
var joy_vec := Vector2.ZERO
var joy_index := -1
var joy_origin := Vector2.ZERO

# HUD
var hud: Control
var lbl_room: Label
var lbl_coins: Label
var ab_row: HBoxContainer
var ab_widgets := []
var boss_box: VBoxContainer
var boss_bar: ProgressBar
var boss_name: Label
var banner: Label
var joy_base: Panel
var joy_knob: Panel
# menú
var menu: Control
var m_name: Label
var m_sub: Label
var m_stats: HBoxContainer
var m_abil: HBoxContainer
var m_lock: Label
var m_play: Button
var m_upgrade: Button
var m_coins: Label
var m_chapter: Label
var m_chapter_best: Label
var m_dots: HBoxContainer
# otras pantallas
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

# ================= helpers =================
func sb(c: Color, r := 18, border := Color(0, 0, 0, 0), bw := 0, margin := 14.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(r)
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	s.set_content_margin_all(margin)
	s.anti_aliasing = true
	return s

func lbl(text: String, size := 18, color := Color.WHITE, title := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if title:
		l.add_theme_font_override("font", FONT_TITLE)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func wrapl(l: Label, w: float) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = w
	return l

func center(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

## primary: botón amarillo; si no, botón translúcido
func btn(text: String, cb: Callable, size := 20, primary := false, color := GOLD) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", FONT_BOLD)
	b.add_theme_font_size_override("font_size", size)
	var base: Color = color if primary else Color(1, 1, 1, 0.1)
	var n := sb(base, 40, Color(0, 0, 0, 0), 0, 10)
	n.content_margin_left = 22
	n.content_margin_right = 22
	if primary:
		n.shadow_color = Color(color.r, color.g, color.b, 0.35)
		n.shadow_size = 10
		n.shadow_offset = Vector2(0, 4)
	var h := n.duplicate()
	h.bg_color = base.lightened(0.15) if primary else Color(1, 1, 1, 0.2)
	var p := n.duplicate()
	p.bg_color = base.darkened(0.15) if primary else Color(1, 1, 1, 0.05)
	var d := n.duplicate()
	d.bg_color = Color(1, 1, 1, 0.06)
	d.shadow_size = 0
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("disabled", d)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var fc := Color(0.15, 0.08, 0.02) if primary else Color.WHITE
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(s, fc)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	b.custom_minimum_size = Vector2(0, 46)
	b.pressed.connect(func(): Sfx.play("click", -10.0, 0.0))
	b.pressed.connect(cb)
	return b

func round_btn(text: String, cb: Callable, d := 46) -> Button:
	var b := btn(text, cb, 20)
	for s in ["normal", "hover", "pressed"]:
		var st: StyleBoxFlat = b.get_theme_stylebox(s).duplicate()
		st.bg_color = Color(0.06, 0.07, 0.11, 0.75 if s == "normal" else 0.95)
		st.content_margin_left = 0
		st.content_margin_right = 0
		b.add_theme_stylebox_override(s, st)
	b.custom_minimum_size = Vector2(d, d)
	return b

func full(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c

func ig(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func margin(m: int, mt := -1) -> MarginContainer:
	var mc := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_bottom"]:
		mc.add_theme_constant_override(s, m)
	mc.add_theme_constant_override("margin_top", m if mt < 0 else mt)
	full(mc)
	ig(mc)
	return mc

func bar(fill: Color, h := 10.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, h)
	b.add_theme_stylebox_override("background", sb(Color(0, 0, 0, 0.45), 20, Color(0, 0, 0, 0), 0, 0))
	b.add_theme_stylebox_override("fill", sb(fill, 20, Color(0, 0, 0, 0), 0, 0))
	ig(b)
	return b

func pill(text: String, size := 16, color := Color.WHITE) -> PanelContainer:
	var p := PanelContainer.new()
	var st := sb(PANEL, 40, Color(0, 0, 0, 0), 0, 6)
	st.content_margin_left = 16
	st.content_margin_right = 16
	p.add_theme_stylebox_override("panel", st)
	p.add_child(lbl(text, size, color))
	ig(p)
	return p

func coin_icon(d := 22) -> Panel:
	var c := Panel.new()
	c.custom_minimum_size = Vector2(d, d)
	var st := sb(Color(1, 0.78, 0.25), d, Color(0.85, 0.55, 0.1), 3, 0)
	c.add_theme_stylebox_override("panel", st)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ig(c)
	return c

func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	ig(h)
	return h

func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	ig(v)
	return v

func spacer(expand_h := true) -> Control:
	var c := ig(Control.new())
	if expand_h:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c

func hide_all() -> void:
	for c in [hud, menu, choose, endscr, pause_scr, title_scr, story_scr]:
		c.visible = false

func _clear(c: Node) -> void:
	for ch in c.get_children():
		ch.queue_free()

func _fade_in(c: Control, t := 0.25) -> void:
	c.modulate.a = 0.0
	c.create_tween().tween_property(c, "modulate:a", 1.0, t)

# ================= HUD =================
func _build_hud() -> void:
	hud = ig(full(Control.new()))
	add_child(hud)
	var m := margin(16)
	hud.add_child(m)
	var root := vbox(0)
	m.add_child(root)
	var top := hbox(10)
	root.add_child(top)
	var room_pill := pill("", 17)
	lbl_room = room_pill.get_child(0)
	room_pill.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(room_pill)
	top.add_child(spacer())
	boss_box = vbox(4)
	boss_box.custom_minimum_size.x = 380
	boss_name = center(lbl("", 16, Color(1, 0.75, 0.7)))
	boss_box.add_child(boss_name)
	boss_bar = bar(Color(0.92, 0.25, 0.3), 12)
	boss_box.add_child(boss_bar)
	top.add_child(boss_box)
	top.add_child(spacer())
	var cp := PanelContainer.new()
	var cst := sb(PANEL, 40, Color(0, 0, 0, 0), 0, 6)
	cst.content_margin_left = 10
	cst.content_margin_right = 16
	cp.add_theme_stylebox_override("panel", cst)
	ig(cp)
	var ch := hbox(8)
	ch.add_child(coin_icon(20))
	lbl_coins = lbl("0", 17, Color(1, 0.9, 0.6))
	ch.add_child(lbl_coins)
	cp.add_child(ch)
	cp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(cp)
	var pb := round_btn("II", func(): main.toggle_pause(), 40)
	pb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(pb)
	root.add_child(spacer(false))
	ab_row = hbox(14)
	ab_row.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(ab_row)
	banner = center(lbl("", 54, Color.WHITE, true))
	full(banner)
	banner.modulate.a = 0.0
	hud.add_child(banner)
	joy_base = ig(Panel.new())
	joy_base.size = Vector2(140, 140)
	joy_base.add_theme_stylebox_override("panel", sb(Color(1, 1, 1, 0.06), 70, Color(1, 1, 1, 0.25), 2, 0))
	joy_base.visible = false
	hud.add_child(joy_base)
	joy_knob = ig(Panel.new())
	joy_knob.size = Vector2(60, 60)
	joy_knob.add_theme_stylebox_override("panel", sb(Color(1, 1, 1, 0.35), 30, Color(0, 0, 0, 0), 0, 0))
	joy_knob.visible = false
	hud.add_child(joy_knob)

func set_abilities(abilities: Array) -> void:
	_clear(ab_row)
	ab_widgets.clear()
	for a in abilities:
		var info: Dictionary = GameData.ABILITIES[a.key]
		var w := CooldownIcon.new()
		w.custom_minimum_size = Vector2(68, 68)
		w.setup(a.key, info.color)
		ab_row.add_child(w)
		ab_widgets.append({"w": w, "a": a})

func update_hud(p, level: int, coins: int) -> void:
	lbl_room.text = "Sala %d / %d" % [level, GameData.MAX_LEVEL]
	lbl_coins.text = str(coins)
	for item in ab_widgets:
		var a: Dictionary = item.a
		var w: CooldownIcon = item.w
		if a.lvl == 0:
			w.set_state(1.0, true, 0, 0.0)
		else:
			w.set_state(clamp(a.t / p.cd_of(a), 0.0, 1.0), false, a.lvl, a.t)
	var boss = null
	for e in main.get_enemies():
		if e.is_boss:
			boss = e
	boss_box.modulate.a = 1.0 if boss else 0.0
	if boss:
		boss_name.text = boss.display_name
		boss_bar.max_value = boss.max_hp
		boss_bar.value = boss.hp

func show_banner(text: String, color := Color.WHITE) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", color)
	banner.pivot_offset = banner.size / 2
	banner.scale = Vector2.ONE * 0.85
	var tw := banner.create_tween().set_parallel()
	tw.tween_property(banner, "modulate:a", 1.0, 0.3)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.9)
	tw.chain().tween_property(banner, "modulate:a", 0.0, 0.5)

func show_hud() -> void:
	hide_all()
	hud.visible = true

# ================= MENÚ =================
func _build_menu() -> void:
	menu = ig(full(Control.new()))
	add_child(menu)
	# degradado inferior para que se lea el texto
	var shade := TextureRect.new()
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.7))
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.45)
	gt.fill_to = Vector2(0, 1)
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	full(shade)
	ig(shade)
	menu.add_child(shade)
	var m := margin(22)
	menu.add_child(m)
	var root := vbox(0)
	m.add_child(root)
	# barra superior: logo pequeño + monedas
	var top := hbox(10)
	root.add_child(top)
	var em := Emblem.new()
	em.custom_minimum_size = Vector2(46, 46)
	top.add_child(em)
	var logo := lbl("DUNGEON SQUAD", 30, Color.WHITE, true)
	logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(logo)
	top.add_child(spacer())
	var cp := PanelContainer.new()
	var cst := sb(PANEL, 40, Color(0, 0, 0, 0), 0, 6)
	cst.content_margin_left = 10
	cst.content_margin_right = 18
	cp.add_theme_stylebox_override("panel", cst)
	var ch := hbox(8)
	ch.add_child(coin_icon(22))
	m_coins = lbl("0", 19, Color(1, 0.9, 0.6))
	ch.add_child(m_coins)
	cp.add_child(ch)
	cp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(cp)
	# centro: flechas a los lados del héroe
	var mid := hbox(0)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid)
	var prev := round_btn("<", func(): main.show_hero(main.sel - 1), 52)
	prev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(prev)
	mid.add_child(spacer())
	var nxt := round_btn(">", func(): main.show_hero(main.sel + 1), 52)
	nxt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(nxt)
	# info del héroe
	var info := vbox(6)
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(info)
	m_name = center(lbl("", 40, Color.WHITE, true))
	info.add_child(m_name)
	m_sub = center(lbl("", 16, GREY))
	info.add_child(m_sub)
	m_lock = center(lbl("", 16, Color(1, 0.6, 0.5)))
	info.add_child(m_lock)
	var row := hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	m_stats = hbox(8)
	row.add_child(m_stats)
	m_abil = hbox(8)
	row.add_child(m_abil)
	info.add_child(row)
	var gap := ig(Control.new())
	gap.custom_minimum_size.y = 12
	info.add_child(gap)
	# fila inferior: capítulo | JUGAR | mejorar arma
	var bottom := hbox(14)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(bottom)
	var chap := PanelContainer.new()
	chap.add_theme_stylebox_override("panel", sb(PANEL, 22, Color(1, 1, 1, 0.08), 1, 10))
	chap.custom_minimum_size.x = 330
	var chh := hbox(6)
	chh.mouse_filter = Control.MOUSE_FILTER_PASS
	chh.add_child(round_btn("<", func(): main.change_chapter(-1), 34))
	var cv := vbox(0)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_chapter = center(lbl("", 17))
	cv.add_child(m_chapter)
	m_chapter_best = center(lbl("", 13, GREY))
	cv.add_child(m_chapter_best)
	chh.add_child(cv)
	chh.add_child(round_btn(">", func(): main.change_chapter(1), 34))
	chap.add_child(chh)
	bottom.add_child(chap)
	m_play = btn("JUGAR", func(): main.start_run(), 30, true)
	m_play.custom_minimum_size = Vector2(240, 66)
	bottom.add_child(m_play)
	m_upgrade = btn("Mejorar arma", func(): main.upgrade_weapon(), 16)
	m_upgrade.custom_minimum_size = Vector2(330, 56)
	bottom.add_child(m_upgrade)

func _chip(text: String) -> PanelContainer:
	var p := pill(text, 14, Color(0.92, 0.93, 0.97))
	return p

func show_menu() -> void:
	hide_all()
	menu.visible = true
	_fade_in(menu)

func update_menu(key: String) -> void:
	var h: Dictionary = GameData.HEROES[key]
	var wl := GameData.wl(key)
	var locked := not GameData.is_unlocked(key)
	m_name.text = h.name if not locked else "???"
	m_name.add_theme_color_override("font_color", Color.WHITE if not locked else Color(0.6, 0.6, 0.65))
	m_sub.text = h.desc
	m_lock.text = GameData.unlock_text(key) if locked else ""
	m_lock.visible = locked
	m_play.disabled = locked
	m_play.text = "BLOQUEADO" if locked else "JUGAR"
	_clear(m_stats)
	m_stats.add_child(_chip("Vida %d" % int(h.hp * (1.0 + 0.1 * (wl - 1)))))
	m_stats.add_child(_chip("Daño %d" % int(h.dmg * (1.0 + 0.2 * (wl - 1)))))
	m_stats.add_child(_chip("Arma Nv %d" % wl))
	_clear(m_abil)
	for i in h.abilities.size():
		var info: Dictionary = GameData.ABILITIES[h.abilities[i]]
		var c := Panel.new()
		c.custom_minimum_size = Vector2(34, 34)
		c.add_theme_stylebox_override("panel", sb(Color(info.color.r * 0.25, info.color.g * 0.25, info.color.b * 0.25, 0.9), 17, info.color, 1, 0))
		c.tooltip_text = info.name + ": " + info.desc
		var ic := SkillIcon.new(h.abilities[i], info.color.lightened(0.3))
		full(ic)
		ic.offset_left = 6
		ic.offset_top = 6
		ic.offset_right = -6
		ic.offset_bottom = -6
		c.add_child(ic)
		m_abil.add_child(c)
	var ch: Dictionary = GameData.CHAPTERS[main.chapter]
	m_chapter.text = "Capítulo %d  -  %s" % [main.chapter + 1, ch.name]
	m_chapter_best.text = "Mejor sala: %d / %d" % [int(GameData.chapter_best.get(main.chapter, 0)), GameData.MAX_LEVEL]
	var cost := 40 * wl
	m_upgrade.text = "Mejorar arma  -  %d monedas" % cost
	m_upgrade.disabled = GameData.coins < cost or locked
	m_coins.text = str(GameData.coins)

# ================= CARTAS =================
const RARITY := {
	"common": ["Común", Color(0.72, 0.75, 0.8)],
	"rare": ["Rara", Color(0.4, 0.68, 1.0)],
	"epic": ["Épica", Color(0.72, 0.45, 1.0)],
	"legend": ["Legendaria", Color(1.0, 0.75, 0.3)],
}

func _build_choose() -> void:
	choose = full(Control.new())
	add_child(choose)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05, 0.6)
	full(bg)
	choose.add_child(bg)
	var c := CenterContainer.new()
	full(c)
	choose.add_child(c)
	var v := vbox(26)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	v.add_child(center(lbl("Elige una habilidad", 38, Color.WHITE, true)))
	cards_row = HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 20)
	v.add_child(cards_row)

func show_choose(options: Array) -> void:
	hide_all()
	choose.visible = true
	_fade_in(choose)
	_clear(cards_row)
	for i in options.size():
		var o: Dictionary = options[i]
		var r: Array = RARITY[o.rarity]
		var rc: Color = r[1]
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(220, 300)
		cards_row.add_child(holder)
		var b := Button.new()
		b.size = Vector2(220, 300)
		b.pivot_offset = b.size / 2
		var n := sb(Color(0.09, 0.1, 0.15, 0.95), 24, Color(rc.r, rc.g, rc.b, 0.55), 2, 0)
		var hv := sb(Color(0.12, 0.13, 0.2, 0.98), 24, rc, 3, 0)
		hv.shadow_color = Color(rc.r, rc.g, rc.b, 0.35)
		hv.shadow_size = 18
		b.add_theme_stylebox_override("normal", n)
		b.add_theme_stylebox_override("hover", hv)
		b.add_theme_stylebox_override("pressed", hv)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		holder.add_child(b)
		var circ := Panel.new()
		circ.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cs := sb(Color(rc.r * 0.18, rc.g * 0.18, rc.b * 0.18), 60, Color(rc.r, rc.g, rc.b, 0.7), 2, 0)
		circ.add_theme_stylebox_override("panel", cs)
		circ.position = Vector2(50, 34)
		circ.size = Vector2(120, 120)
		b.add_child(circ)
		var icon := SkillIcon.new(o.icon, o.color.lightened(0.25))
		icon.position = Vector2(24, 24)
		icon.size = Vector2(72, 72)
		circ.add_child(icon)
		var rl := center(lbl(r[0], 13, rc))
		rl.position = Vector2(0, 166)
		rl.size = Vector2(220, 20)
		b.add_child(rl)
		var tl := center(wrapl(lbl(o.title, 21, Color.WHITE, true), 196))
		tl.position = Vector2(12, 188)
		tl.size.x = 196
		b.add_child(tl)
		var dl := center(wrapl(lbl(o.desc, 14, GREY), 190))
		dl.position = Vector2(15, 228)
		dl.size.x = 190
		b.add_child(dl)
		b.mouse_entered.connect(func():
			b.create_tween().tween_property(b, "scale", Vector2.ONE * 1.04, 0.12))
		b.mouse_exited.connect(func():
			b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.12))
		b.pressed.connect(func():
			for other in cards_row.get_children():
				if other != holder:
					other.create_tween().tween_property(other, "modulate:a", 0.0, 0.18)
			var tw := b.create_tween()
			tw.tween_property(b, "scale", Vector2.ONE * 1.1, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_interval(0.2)
			tw.tween_callback(main.pick_option.bind(o)))
		b.modulate.a = 0.0
		b.position.y = 30
		var tw2 := b.create_tween().set_parallel()
		tw2.tween_property(b, "modulate:a", 1.0, 0.25).set_delay(0.08 + i * 0.1)
		tw2.tween_property(b, "position:y", 0.0, 0.3).set_delay(0.08 + i * 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# ================= FIN / PAUSA =================
func _overlay(title: String) -> Array:
	var root := full(Control.new())
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05, 0.6)
	full(bg)
	root.add_child(bg)
	var c := CenterContainer.new()
	full(c)
	root.add_child(c)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", sb(Color(0.08, 0.09, 0.14, 0.95), 26, Color(1, 1, 1, 0.08), 1, 30))
	panel.custom_minimum_size.x = 420
	c.add_child(panel)
	var v := vbox(12)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(v)
	var t := center(lbl(title, 40, Color.WHITE, true))
	v.add_child(t)
	return [root, v, t]

func _build_end() -> void:
	var o := _overlay("")
	endscr = o[0]
	end_title = o[2]
	end_text = center(wrapl(lbl("", 17, GREY), 360))
	o[1].add_child(end_text)
	o[1].add_child(btn("Reintentar", func(): main.start_run(), 20, true))
	o[1].add_child(btn("Volver al menú", func(): main.go_menu(), 18))

func show_end(win: bool, level: int, coins: int) -> void:
	hide_all()
	endscr.visible = true
	_fade_in(endscr, 0.4)
	end_title.text = "¡Capítulo completado!" if win else "Has caído"
	end_title.add_theme_color_override("font_color", GOLD if win else Color(1, 0.55, 0.5))
	end_text.text = "Sala alcanzada: %d\nMonedas ganadas: %d\n\nTotal: %d monedas" % [level, coins, GameData.coins]

func _build_pause() -> void:
	var o := _overlay("Pausa")
	pause_scr = o[0]
	o[1].add_child(btn("Continuar", func(): main.toggle_pause(), 20, true))
	var mus: Button
	mus = btn("Música: " + ("Sí" if GameData.music_on else "No"), func():
		Sfx.set_music_on(not GameData.music_on)
		GameData.save_game()
		mus.text = "Música: " + ("Sí" if GameData.music_on else "No"), 17)
	o[1].add_child(mus)
	var snd: Button
	snd = btn("Efectos: " + ("No" if Sfx.muted else "Sí"), func():
		Sfx.set_muted(not Sfx.muted)
		GameData.save_game()
		snd.text = "Efectos: " + ("No" if Sfx.muted else "Sí"), 17)
	o[1].add_child(snd)
	o[1].add_child(btn("Abandonar partida", func(): main.go_menu(), 17))

func set_paused(p: bool) -> void:
	pause_scr.visible = p
	if p:
		_fade_in(pause_scr, 0.15)

# ================= TÍTULO =================
func _build_title() -> void:
	title_scr = ig(full(Control.new()))
	add_child(title_scr)
	var grad := TextureRect.new()
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0, 0, 0, 0.7))
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.45)
	gt.fill_to = Vector2(1.1, 1.1)
	grad.texture = gt
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	full(grad)
	ig(grad)
	title_scr.add_child(grad)
	var c := ig(CenterContainer.new())
	full(c)
	title_scr.add_child(c)
	var v := vbox(-6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	var em := Emblem.new()
	em.custom_minimum_size = Vector2(170, 170)
	em.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(em)
	var t1 := center(lbl("DUNGEON SQUAD", 92, Color.WHITE, true))
	t1.add_theme_constant_override("outline_size", 14)
	t1.add_theme_color_override("font_outline_color", Color(0.25, 0.08, 0.02))
	t1.add_theme_constant_override("shadow_offset_y", 8)
	v.add_child(t1)
	var sub := center(lbl("La leyenda del escuadrón", 20, Color(1, 0.85, 0.6)))
	v.add_child(sub)
	var sp := ig(Control.new())
	sp.custom_minimum_size.y = 60
	v.add_child(sp)
	title_hint = center(lbl("Pulsa cualquier tecla", 20, Color(1, 1, 1, 0.9)))
	v.add_child(title_hint)
	var credit := center(lbl("Modelos: KayKit  -  Hecho con Godot", 12, Color(1, 1, 1, 0.4)))
	credit.anchor_left = 0.0
	credit.anchor_right = 1.0
	credit.anchor_top = 1.0
	credit.anchor_bottom = 1.0
	credit.offset_top = -36
	credit.offset_bottom = -12
	title_scr.add_child(credit)

func show_title() -> void:
	hide_all()
	title_scr.visible = true
	_fade_in(title_scr, 1.2)
	var blink := title_hint.create_tween().set_loops()
	blink.tween_property(title_hint, "modulate:a", 0.25, 0.9)
	blink.tween_property(title_hint, "modulate:a", 1.0, 0.9)

# ================= HISTORIA =================
func _build_story() -> void:
	story_scr = full(Control.new())
	add_child(story_scr)
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.01, 0.03, 0.82)
	full(bg)
	story_scr.add_child(bg)
	var c := CenterContainer.new()
	full(c)
	story_scr.add_child(c)
	var v := vbox(22)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	story_title = center(lbl("", 40, GOLD, true))
	v.add_child(story_title)
	story_text = center(wrapl(lbl("", 22, Color(0.92, 0.9, 0.86)), 760))
	story_text.custom_minimum_size.y = 120
	v.add_child(story_text)
	story_btn = btn("Continuar", func(): _story_next(), 18, true)
	story_btn.custom_minimum_size = Vector2(200, 48)
	story_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(story_btn)

func show_story(title: String, lines: Array, cb: Callable, color := GOLD) -> void:
	hide_all()
	story_scr.visible = true
	_fade_in(story_scr, 0.4)
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
	tw.tween_property(story_text, "visible_ratio", 1.0, story_text.text.length() * 0.025)
	story_btn.text = "Continuar" if story_idx < story_lines.size() - 1 else "¡Adelante!"

# ================= ENTRADA =================
func _unhandled_input(e: InputEvent) -> void:
	if title_scr.visible and ((e is InputEventKey and e.pressed) or (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed) or (e is InputEventJoypadButton and e.pressed)):
		Sfx.play("pick", -6.0, 0.0)
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
