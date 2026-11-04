extends Node
## Sonido procedural: efectos y música generados por código (sin archivos de audio).

const RATE := 22050
var sounds := {}
var players := []
var next := 0
var last_play := {}
var music: AudioStreamPlayer
var muted := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 20:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)
	_make_sounds()
	music = AudioStreamPlayer.new()
	music.volume_db = -9.0
	add_child(music)
	music.stream = _make_music()
	music.play()

# ---------- síntesis ----------
## wave: 0 seno, 1 cuadrada, 2 sierra, 3 triángulo. noise: mezcla de ruido 0..1
func tone(dur: float, f0: float, f1: float, wave := 0, vol := 0.5, noise := 0.0, attack := 0.005, lp := 1.0) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var ph := 0.0
	var nz := 0.0
	for i in n:
		var t := float(i) / n
		var f: float = lerp(f0, f1, t)
		ph += f / RATE
		var x := 0.0
		match wave:
			0: x = sin(ph * TAU)
			1: x = 1.0 if fmod(ph, 1.0) < 0.5 else -1.0
			2: x = fmod(ph, 1.0) * 2.0 - 1.0
			3: x = abs(fmod(ph, 1.0) * 4.0 - 2.0) - 1.0
		if noise > 0.0:
			nz = lerp(nz, randf() * 2.0 - 1.0, lp)
			x = lerp(x, nz, noise)
		var env: float = min(1.0, float(i) / max(1.0, attack * RATE)) * pow(1.0 - t, 2.0)
		data.encode_s16(i * 2, int(clamp(x * env * vol, -1.0, 1.0) * 32767))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = data
	return s

func mix(parts: Array) -> AudioStreamWAV:
	var n := 0
	for p in parts:
		n = max(n, p.data.size())
	var data := PackedByteArray()
	data.resize(n)
	for i in range(0, n, 2):
		var v := 0
		for p in parts:
			if i < p.data.size():
				v += p.data.decode_s16(i)
		data.encode_s16(i, clamp(v, -32767, 32767))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = data
	return s

func seq(notes: Array, step: float, wave := 3, vol := 0.35) -> AudioStreamWAV:
	var parts := []
	for i in notes.size():
		var silence := tone(step * i, 1, 1, 0, 0.0)
		var nt := tone(step * 2.5, notes[i], notes[i], wave, vol)
		var joined := PackedByteArray(silence.data)
		joined.append_array(nt.data)
		var s := AudioStreamWAV.new()
		s.data = joined
		parts.append(s)
	return mix(parts)

func _make_sounds() -> void:
	sounds["arrow"] = tone(0.12, 1800, 500, 0, 0.25, 0.7, 0.002, 0.5)
	sounds["fire"] = mix([tone(0.3, 300, 120, 2, 0.25, 0.6, 0.01, 0.2), tone(0.2, 600, 200, 0, 0.2)])
	sounds["dagger"] = tone(0.09, 2500, 900, 0, 0.2, 0.8, 0.001, 0.7)
	sounds["bolt"] = mix([tone(0.25, 900, 300, 3, 0.25), tone(0.25, 1350, 450, 0, 0.12)])
	sounds["slash"] = tone(0.16, 1200, 300, 0, 0.35, 0.9, 0.002, 0.35)
	sounds["wave"] = tone(0.3, 500, 150, 2, 0.25, 0.5, 0.01, 0.3)
	sounds["hit"] = mix([tone(0.08, 180, 60, 1, 0.3, 0.5, 0.001, 0.5), tone(0.05, 900, 400, 0, 0.15)])
	sounds["crit"] = mix([tone(0.12, 220, 70, 1, 0.35, 0.5, 0.001, 0.5), tone(0.25, 1760, 1700, 0, 0.18)])
	sounds["kill"] = mix([tone(0.25, 300, 60, 2, 0.3, 0.6, 0.002, 0.3), tone(0.15, 600, 900, 3, 0.15)])
	sounds["boom"] = mix([tone(0.6, 120, 30, 0, 0.6), tone(0.6, 1, 1, 0, 0.55, 1.0, 0.002, 0.08)])
	sounds["eshot"] = tone(0.18, 700, 250, 3, 0.18)
	sounds["hurt"] = mix([tone(0.22, 260, 90, 1, 0.3), tone(0.15, 1, 1, 0, 0.3, 1.0, 0.001, 0.2)])
	sounds["coin"] = seq([1976.0, 2637.0], 0.06, 0, 0.25)
	sounds["cast"] = mix([tone(0.4, 300, 1200, 3, 0.25), tone(0.4, 450, 1800, 0, 0.12)])
	sounds["ice"] = mix([tone(0.5, 2400, 800, 0, 0.18, 0.4, 0.005, 0.9), tone(0.5, 1200, 400, 3, 0.2)])
	sounds["shout"] = mix([tone(0.5, 140, 110, 2, 0.35, 0.2, 0.02, 0.3), tone(0.5, 210, 160, 1, 0.12)])
	sounds["summon"] = mix([tone(0.6, 120, 300, 2, 0.3, 0.3, 0.05, 0.2), tone(0.6, 240, 600, 3, 0.15)])
	sounds["drain"] = tone(0.5, 900, 300, 3, 0.25)
	sounds["teleport"] = mix([tone(0.25, 200, 1600, 0, 0.25), tone(0.25, 1, 1, 0, 0.15, 1.0, 0.01, 0.6)])
	sounds["spawn"] = tone(0.4, 80, 220, 2, 0.15, 0.5, 0.1, 0.15)
	sounds["roar"] = mix([tone(0.9, 90, 55, 2, 0.4, 0.4, 0.05, 0.15), tone(0.9, 135, 80, 1, 0.12)])
	sounds["portal"] = seq([523.0, 659.0, 784.0, 1047.0, 1319.0], 0.08, 3, 0.25)
	sounds["level"] = seq([392.0, 523.0, 659.0], 0.1, 1, 0.12)
	sounds["pick"] = seq([659.0, 880.0, 1319.0], 0.06, 3, 0.3)
	sounds["click"] = tone(0.05, 1200, 900, 3, 0.25)
	sounds["death"] = seq([440.0, 349.0, 294.0, 220.0], 0.18, 2, 0.18)
	sounds["win"] = seq([523.0, 659.0, 784.0, 1047.0, 784.0, 1047.0, 1319.0], 0.12, 3, 0.3)
	sounds["upgrade"] = seq([784.0, 988.0, 1175.0, 1568.0], 0.07, 0, 0.25)

func play(name: String, vol_db := 0.0, pitch_var := 0.08) -> void:
	if muted or not sounds.has(name):
		return
	var now := Time.get_ticks_msec()
	if now - int(last_play.get(name, 0)) < 35:
		return
	last_play[name] = now
	var p: AudioStreamPlayer = players[next]
	next = (next + 1) % players.size()
	p.stream = sounds[name]
	p.volume_db = vol_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()

func set_muted(m: bool) -> void:
	muted = m
	music.stream_paused = m

func set_intense(on: bool) -> void:
	music.pitch_scale = 1.12 if on else 1.0

# ---------- música ----------
func _make_music() -> AudioStreamWAV:
	var bpm := 112.0
	var beat := 60.0 / bpm
	var bars := 8
	var n := int(bars * 4 * beat * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	# progresión en La menor: Am  F  G  Em
	var roots := [110.0, 87.31, 98.0, 82.41]
	var chords := [[0, 3, 7], [0, 4, 7], [0, 4, 7], [0, 3, 7]]
	var step := beat / 4.0
	var steps := bars * 16
	for s in steps:
		var bar := s / 16
		var ci: int = (bar / 2) % 4
		var root: float = roots[ci]
		var start := int(s * step * RATE)
		# bajo en corcheas
		if s % 2 == 0:
			_add(buf, start, step * 1.8, root, 2, 0.16, 0.25)
		# arpegio
		var ch: Array = chords[ci]
		var semis: int = ch[s % 3] + (12 if (s / 3) % 2 == 1 else 0)
		_add(buf, start, step * 1.5, root * 4.0 * pow(2.0, semis / 12.0), 3, 0.07, 1.0)
		# bombo y caja
		if s % 8 == 0:
			_kick(buf, start)
		if s % 8 == 4:
			_noise(buf, start, 0.12, 0.12)
		if s % 2 == 1:
			_noise(buf, start, 0.03, 0.035)
	# pad
	for bar in bars:
		var ci2: int = (bar / 2) % 4
		var r2: float = roots[ci2] * 2.0
		for semi in chords[ci2]:
			_add(buf, int(bar * 4 * beat * RATE), 4 * beat, r2 * pow(2.0, semi / 12.0), 0, 0.045, 1.0, 0.4)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clamp(buf[i], -1.0, 1.0) * 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w

func _add(buf: PackedFloat32Array, start: int, dur: float, f: float, wave: int, vol: float, lp := 1.0, attack := 0.01) -> void:
	var n := int(dur * RATE)
	var ph := 0.0
	var y := 0.0
	for i in n:
		var idx := start + i
		if idx >= buf.size():
			return
		ph += f / RATE
		var x := 0.0
		match wave:
			0: x = sin(ph * TAU)
			2: x = fmod(ph, 1.0) * 2.0 - 1.0
			3: x = abs(fmod(ph, 1.0) * 4.0 - 2.0) - 1.0
		y = lerp(y, x, lp)
		var t := float(i) / n
		var env: float = min(1.0, t / attack) * (1.0 - t)
		buf[idx] += y * env * vol

func _kick(buf: PackedFloat32Array, start: int) -> void:
	var n := int(0.25 * RATE)
	var ph := 0.0
	for i in n:
		if start + i >= buf.size():
			return
		var t := float(i) / n
		ph += lerp(140.0, 40.0, sqrt(t)) / RATE
		buf[start + i] += sin(ph * TAU) * pow(1.0 - t, 2.0) * 0.4

func _noise(buf: PackedFloat32Array, start: int, dur: float, vol: float) -> void:
	var n := int(dur * RATE)
	for i in n:
		if start + i >= buf.size():
			return
		buf[start + i] += (randf() * 2.0 - 1.0) * pow(1.0 - float(i) / n, 3.0) * vol
