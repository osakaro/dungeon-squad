"""Genera la música ambiental del juego (misma receta que audio.gd) y la guarda como WAV.
Uso: python3 tools/render_music.py <carpeta_salida>   (luego convertir a OGG con ffmpeg)"""
import sys, wave, hashlib
import numpy as np

R = 22050
TRACKS = {
    "title": [146.83, [0, 3, 5, 7, 10], [[0, 3, 7], [-4, 0, 3], [-2, 2, 5], [-5, -2, 2]], 66.0, 3, False],
    "forest": [146.83, [0, 2, 3, 7, 9], [[0, 3, 7], [5, 9, 12], [-2, 2, 5], [3, 7, 10]], 72.0, 3, False],
    "ice": [164.81, [0, 2, 3, 7, 10], [[0, 3, 7], [-4, 0, 3], [-7, -3, 0], [-2, 2, 5]], 62.0, 0, False],
    "lava": [130.81, [0, 1, 3, 7, 8], [[0, 3, 7], [1, 5, 8], [-4, 0, 3], [-5, -1, 2]], 80.0, 2, True],
}

def voice(buf, start, dur, f, wave_t, vol, attack, release):
    n = int(dur * R)
    i = np.arange(n)
    ph = (i + 1) * f / R
    if wave_t == 0:
        x = np.sin(ph * 2 * np.pi) + 0.3 * np.sin(ph * 2 * np.pi * 2.003)
    elif wave_t == 3:
        x = np.abs(np.mod(ph, 1) * 4 - 2) - 1
    else:
        x = (np.mod(ph, 1) * 2 - 1) * 0.5 + np.sin(ph * 2 * np.pi) * 0.5
    a = np.minimum(1, i / max(1, attack * R))
    if release <= 0:
        env = a * np.exp(-3.5 * i / n)
    else:
        env = a * np.minimum(1, (n - i) / (release * R))
    idx = (start + i) % len(buf)
    np.add.at(buf, idx, x * env * vol)

def tom(buf, start, vol):
    n = int(0.35 * R)
    i = np.arange(n); t = i / n
    f = 110 + (55 - 110) * t
    ph = np.cumsum(f / R)
    end = min(len(buf), start + n)
    buf[start:end] += (np.sin(ph * 2 * np.pi) * (1 - t) ** 3 * vol)[: end - start]

def make(kind):
    root, scale, chords, bpm, mw, perc = TRACKS[kind]
    beat = 60.0 / bpm
    bars = 16
    n = int(bars * 4 * beat * R)
    buf = np.zeros(n)
    rng = np.random.default_rng(int(hashlib.md5(kind.encode()).hexdigest()[:8], 16))
    for bar in range(0, bars, 2):
        ch = chords[(bar // 2) % len(chords)]
        st = int(bar * 4 * beat * R)
        for s in ch:
            voice(buf, st, 8 * beat + 1.0, root * 2 ** (s / 12), 0, 0.05, 1.6, 2.0)
        voice(buf, st, 8 * beat, root * 0.5 * 2 ** (ch[0] / 12), 0, 0.09, 0.3, 1.5)
    step = beat / 2
    for s in range(bars * 8):
        if rng.random() < 0.32 and (s // 8) % 4 != 3:
            deg = scale[rng.integers(len(scale))] + (12 if rng.random() < 0.4 else 0)
            f = root * 2 * 2 ** (deg / 12)
            st = int(s * step * R)
            voice(buf, st, 1.6, f, mw, 0.06, 0.01, 0.0)
            voice(buf, st + int(beat * 0.75 * R), 1.6, f, mw, 0.025, 0.01, 0.0)
    if perc:
        for b in range(bars * 4):
            if b % 2 == 0:
                tom(buf, int(b * beat * R), 0.18 if b % 4 == 0 else 0.1)
    return np.clip(buf * 1.6, -1, 1)

if __name__ == "__main__":
    out = sys.argv[1]
    for k in TRACKS:
        d = (make(k) * 32767).astype(np.int16)
        with wave.open(f"{out}/{k}.wav", "wb") as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(R); w.writeframes(d.tobytes())
        print("ok", k)
