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
	music.volume_db = -13.0
	add_child(music)
	muted = not GameData.sfx_on
	play_music("title")

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
	sounds["arrow"] = tone(0.1, 900, 400, 0, 0.18, 0.5, 0.004, 0.25)
	sounds["fire"] = mix([tone(0.3, 300, 120, 2, 0.25, 0.6, 0.01, 0.2), tone(0.2, 600, 200, 0, 0.2)])
	sounds["dagger"] = tone(0.08, 1200, 600, 0, 0.15, 0.6, 0.003, 0.3)
	sounds["bolt"] = mix([tone(0.25, 900, 300, 3, 0.25), tone(0.25, 1350, 450, 0, 0.12)])
	sounds["slash"] = tone(0.14, 700, 250, 0, 0.25, 0.7, 0.004, 0.18)
	sounds["wave"] = tone(0.3, 500, 150, 2, 0.25, 0.5, 0.01, 0.3)
	sounds["hit"] = tone(0.07, 160, 90, 0, 0.35, 0.15, 0.002, 0.2)
	sounds["crit"] = mix([tone(0.09, 180, 90, 0, 0.35, 0.15, 0.002, 0.2), tone(0.18, 1320, 1300, 0, 0.08)])
	sounds["kill"] = mix([tone(0.18, 220, 90, 0, 0.3, 0.3, 0.004, 0.15), tone(0.12, 520, 700, 3, 0.08)])
	sounds["boom"] = mix([tone(0.5, 110, 35, 0, 0.45), tone(0.4, 1, 1, 0, 0.25, 1.0, 0.004, 0.05)])
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

const MIN_GAP := {"hit": 110, "crit": 110, "kill": 90, "arrow": 90, "dagger": 90, "slash": 90, "fire": 90, "bolt": 90,
	"eshot": 140, "coin": 70, "boom": 120, "wave": 120}

func play(name: String, vol_db := 0.0, pitch_var := 0.08) -> void:
	if muted or not sounds.has(name):
		return
	var now := Time.get_ticks_msec()
	if now - int(last_play.get(name, 0)) < int(MIN_GAP.get(name, 60)):
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
	GameData.sfx_on = not m

func set_intense(_on: bool) -> void:
	pass

# ---------- música ----------
## Música ambiental tranquila, distinta para cada bioma. Se genera en segundo plano.
const MRATE := 16000
const TRACKS := {
	# raíz, escala (semitonos), acordes (grados), bpm, timbre de melodía, percusión
	"title": [146.83, [0, 3, 5, 7, 10], [[0, 3, 7], [-4, 0, 3], [-2, 2, 5], [-5, -2, 2]], 66.0, 3, false],
	"forest": [146.83, [0, 2, 3, 7, 9], [[0, 3, 7], [5, 9, 12], [-2, 2, 5], [3, 7, 10]], 72.0, 3, false],
	"ice": [164.81, [0, 2, 3, 7, 10], [[0, 3, 7], [-4, 0, 3], [-7, -3, 0], [-2, 2, 5]], 62.0, 0, false],
	"lava": [130.81, [0, 1, 3, 7, 8], [[0, 3, 7], [1, 5, 8], [-4, 0, 3], [-5, -1, 2]], 80.0, 2, true],
}
var _cache := {}
var _wanted := ""
var _thread: Thread
var _queue := []

func play_music(kind: String) -> void:
	_wanted = kind
	if _cache.has(kind):
		_start(kind)
	elif not kind in _queue:
		_queue.append(kind)
		_next_job()

func _next_job() -> void:
	if _thread and _thread.is_alive():
		return
	if _thread:
		_thread.wait_to_finish()
	if _queue.is_empty():
		return
	var k: String = _queue.pop_front()
	_thread = Thread.new()
	_thread.start(_job.bind(k))

func _job(k: String) -> void:
	var w := _make_track(k)
	call_deferred("_job_done", k, w)

func _job_done(k: String, w: AudioStreamWAV) -> void:
	_cache[k] = w
	if _wanted == k:
		_start(k)
	_next_job()

func _start(kind: String) -> void:
	if music.stream == _cache[kind] and music.playing:
		return
	var tw := create_tween()
	if music.playing:
		tw.tween_property(music, "volume_db", -40.0, 0.8)
	tw.tween_callback(func():
		music.stream = _cache[kind]
		music.volume_db = -40.0
		music.play()
		music.stream_paused = not GameData.music_on)
	tw.tween_property(music, "volume_db", -13.0, 1.5)

func set_music_on(on: bool) -> void:
	GameData.music_on = on
	music.stream_paused = not on

func _exit_tree() -> void:
	if _thread:
		_thread.wait_to_finish()

func _make_track(kind: String) -> AudioStreamWAV:
	var cfg: Array = TRACKS[kind]
	var root: float = cfg[0]
	var scale: Array = cfg[1]
	var chords: Array = cfg[2]
	var beat: float = 60.0 / cfg[3]
	var bars := 16
	var n := int(bars * 4 * beat * MRATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	# colchón de acordes (pad) con ataque lento
	for bar in range(0, bars, 2):
		var ch: Array = chords[(bar / 2) % chords.size()]
		var st := int(bar * 4 * beat * MRATE)
		for semi in ch:
			_voice(buf, st, 8 * beat + 1.0, root * pow(2.0, semi / 12.0), 0, 0.05, 1.6, 2.0)
		_voice(buf, st, 8 * beat, root * 0.5 * pow(2.0, ch[0] / 12.0), 0, 0.09, 0.3, 1.5)
	# melodía suave y escasa, con eco
	var step := beat / 2.0
	for s in bars * 8:
		if rng.randf() < 0.32 and (s / 8) % 4 != 3:
			var deg: int = scale[rng.randi() % scale.size()] + (12 if rng.randf() < 0.4 else 0)
			var f := root * 2.0 * pow(2.0, deg / 12.0)
			var st2 := int(s * step * MRATE)
			_voice(buf, st2, 1.6, f, cfg[4], 0.06, 0.01, 0.0)
			_voice(buf, st2 + int(beat * 0.75 * MRATE), 1.6, f, cfg[4], 0.025, 0.01, 0.0)
	# percusión suave (solo volcán)
	if cfg[5]:
		for b in bars * 4:
			if b % 2 == 0:
				_tom(buf, int(b * beat * MRATE), 0.18 if b % 4 == 0 else 0.1)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clamp(buf[i] * 1.6, -1.0, 1.0) * 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MRATE
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w

## Una nota: wave 0 seno, 2 sierra suave, 3 triángulo. release = 0 => decaimiento de pulsación
func _voice(buf: PackedFloat32Array, start: int, dur: float, f: float, wave: int, vol: float, attack: float, release: float) -> void:
	var n := int(dur * MRATE)
	var inc := f / MRATE
	var ph := 0.0
	var a_n: float = max(1.0, attack * MRATE)
	var r_n := release * MRATE
	var size := buf.size()
	for i in n:
		var idx := (start + i) % size
		ph += inc
		var x: float
		if wave == 0:
			x = sin(ph * TAU) + 0.3 * sin(ph * TAU * 2.003)
		elif wave == 3:
			x = abs(fmod(ph, 1.0) * 4.0 - 2.0) - 1.0
		else:
			x = (fmod(ph, 1.0) * 2.0 - 1.0) * 0.5 + sin(ph * TAU) * 0.5
		var env: float
		if release <= 0.0:
			env = min(1.0, i / a_n) * exp(-3.5 * float(i) / n)
		else:
			env = min(1.0, i / a_n) * min(1.0, float(n - i) / r_n)
		buf[idx] += x * env * vol

func _tom(buf: PackedFloat32Array, start: int, vol: float) -> void:
	var n := int(0.35 * MRATE)
	var ph := 0.0
	for i in n:
		if start + i >= buf.size():
			return
		var t := float(i) / n
		ph += lerp(110.0, 55.0, t) / MRATE
		buf[start + i] += sin(ph * TAU) * pow(1.0 - t, 3.0) * vol
