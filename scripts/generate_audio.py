#!/usr/bin/env python3
"""Procedurally generates every sound in assets/audio (16-bit mono WAV).

Run `python3 scripts/generate_audio.py` after tweaking. Everything is synthesised
from scratch so the project ships no third-party audio.
"""
import math
import os
import wave

import numpy as np

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
RNG = np.random.default_rng(2024)


# --- helpers -------------------------------------------------------------

def write(name, samples, gain=0.9):
    samples = np.asarray(samples, dtype=np.float64)
    peak = np.max(np.abs(samples)) or 1.0
    data = (samples / peak * gain * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def t(seconds):
    return np.arange(int(SR * seconds)) / SR


def adsr(n, a=0.005, d=0.05, s=0.7, r=0.1):
    a_n, d_n, r_n = int(SR * a), int(SR * d), int(SR * r)
    env = np.full(n, s, dtype=np.float64)
    a_n = min(a_n, n)
    env[:a_n] = np.linspace(0, 1, a_n)
    d_end = min(a_n + d_n, n)
    env[a_n:d_end] = np.linspace(1, s, d_end - a_n)
    r_n = min(r_n, n)
    if r_n:
        env[-r_n:] *= np.linspace(1, 0, r_n)
    return env


def saw(freq, x):
    return 2 * ((freq * x) % 1) - 1


def square(freq, x, duty=0.5):
    return np.where((freq * x) % 1 < duty, 1.0, -1.0)


def tri(freq, x):
    return 2 * np.abs(saw(freq, x)) - 1


def sweep(f0, f1, x, curve=1.0):
    """Phase for a frequency sweep f0 -> f1 over x."""
    frac = (x / x[-1]) ** curve
    f = f0 + (f1 - f0) * frac
    return 2 * math.pi * np.cumsum(f) / SR


def svf(x, cutoff, q=0.7, mode="lp"):
    """State-variable filter; cutoff may be an array (per-sample)."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=np.float64), x.shape)
    g = np.tan(np.pi * np.clip(cutoff, 20, SR * 0.45) / SR)
    k = 1.0 / q
    lp = bp = 0.0
    ic1 = ic2 = 0.0
    out = np.empty_like(x)
    for i in range(x.size):
        gi = g[i]
        a1 = 1.0 / (1.0 + gi * (gi + k))
        a2 = gi * a1
        a3 = gi * a2
        v3 = x[i] - ic2
        v1 = a1 * ic1 + a2 * v3
        v2 = ic2 + a2 * ic1 + a3 * v3
        ic1 = 2 * v1 - ic1
        ic2 = 2 * v2 - ic2
        lp, bp = v2, v1
        out[i] = lp if mode == "lp" else bp if mode == "bp" else x[i] - k * bp - lp
    return out


def bell(freq, dur, partials=((1.0, 1.0, 0.6), (2.76, 0.45, 0.35), (5.4, 0.2, 0.2))):
    x = t(dur)
    out = np.zeros_like(x)
    for ratio, amp, decay in partials:
        out += amp * np.sin(2 * math.pi * freq * ratio * x) * np.exp(-x / decay)
    return out


def reverb(x, tail=0.25, mix=0.25):
    """Cheap comb-filter reverb for a bit of space."""
    out = x.copy()
    for delay_s, g in ((0.029, 0.55), (0.037, 0.45), (0.051, 0.35)):
        d = int(SR * delay_s)
        buf = np.zeros(x.size + int(SR * tail))
        buf[: x.size] = x
        for i in range(d, buf.size):
            buf[i] += g * buf[i - d]
        out = np.pad(out, (0, buf.size - out.size)) + mix * buf
    return out


# --- sounds ---------------------------------------------------------------

def engine():
    # 2 s seamless loop: every partial is a multiple of 0.5 Hz so the wrap is
    # continuous. Layers: sub, fundamental with pulse-width movement, exhaust
    # noise and a slow rumble modulation.
    dur = 2.0
    x = t(dur + 0.3)  # extra tail is crossfaded into the start for a click-free loop
    f0 = 52.0
    sub = 0.5 * np.sin(2 * math.pi * (f0 / 2) * x)
    body = np.zeros_like(x)
    for k, amp in enumerate([1.0, 0.7, 0.5, 0.36, 0.25, 0.18, 0.12, 0.08], start=1):
        body += amp * saw(f0 * k, x)
    duty = 0.5 + 0.15 * np.sin(2 * math.pi * 3 * x)
    pulse = np.where((f0 * x) % 1 < duty, 1.0, -1.0) * 0.4
    exhaust = svf(RNG.normal(0, 1, x.size), 900, q=0.9, mode="bp") * 0.35
    rumble = 1 + 0.12 * np.sin(2 * math.pi * 4 * x)
    mix = (sub + body * 0.35 + pulse + exhaust) * rumble
    mix = svf(mix, 1800, q=0.8)
    n = int(SR * dur)
    fade = int(SR * 0.3)
    ramp = np.linspace(0, 1, fade)
    loop = mix[:n].copy()
    loop[:fade] = loop[:fade] * ramp + mix[n:n + fade] * (1 - ramp)
    write("engine.wav", loop, gain=0.7)


def crash():
    x = t(1.3)
    thump = np.sin(sweep(90, 28, x, curve=0.5)) * np.exp(-x * 4.5) * 1.4
    crunch = svf(RNG.normal(0, 1, x.size), 500 + 2500 * np.exp(-x * 6), q=0.6, mode="bp")
    crunch *= np.exp(-x * 5) * 1.2
    glass = np.zeros_like(x)
    for _ in range(18):
        start = int(RNG.uniform(0.02, 0.5) * SR)
        length = int(RNG.uniform(0.01, 0.05) * SR)
        f = RNG.uniform(2500, 7000)
        xs = np.arange(length) / SR
        seg = np.sin(2 * math.pi * f * xs) * np.exp(-np.arange(length) / (length / 3))
        glass[start:start + length] += seg * 0.35
    metal = np.sin(2 * math.pi * 320 * x) * np.sin(2 * math.pi * 1.6 * 320 * x) * np.exp(-x * 7) * 0.5
    write("crash.wav", reverb(thump + crunch + glass + metal, tail=0.3, mix=0.2))


def pickup():
    notes = [(783.99, 0.0), (1046.5, 0.08), (1318.5, 0.16)]
    total = int(SR * 0.6)
    out = np.zeros(total)
    for f, start in notes:
        b = bell(f, 0.42)
        i = int(SR * start)
        out[i:i + b.size] += b
    write("pickup.wav", reverb(out, mix=0.3), gain=0.85)


def whoosh():
    x = t(0.45)
    noise = RNG.normal(0, 1, x.size)
    cutoff = 300 + 2600 * np.sin(np.pi * x / x[-1]) ** 1.5
    body = svf(noise, cutoff, q=2.5, mode="bp")
    env = np.sin(np.pi * x / x[-1]) ** 1.2
    # Doppler-ish pitch drop at the end.
    tone = np.sin(sweep(900, 400, x, curve=2.0)) * np.exp(-x * 6) * 0.25
    write("whoosh.wav", body * env + tone, gain=0.8)


def nitro():
    x = t(0.9)
    jet = svf(RNG.normal(0, 1, x.size), 400 + 3500 * (x / x[-1]) ** 1.5, q=1.6, mode="bp")
    jet *= adsr(x.size, a=0.03, d=0.1, s=0.9, r=0.35)
    tone = (saw(1, x) * 0 + np.sin(sweep(160, 980, x, curve=1.4)) + 0.4 * np.sin(sweep(320, 1960, x, curve=1.4)))
    tone *= adsr(x.size, a=0.02, d=0.2, s=0.7, r=0.3) * 0.7
    sub = np.sin(sweep(50, 110, x)) * adsr(x.size, a=0.01, d=0.3, s=0.5, r=0.3) * 0.8
    write("nitro.wav", reverb(jet + tone + sub, mix=0.15))


def level_up():
    notes = [523.25, 659.25, 783.99, 1046.5]
    step = 0.11
    total = int(SR * (step * len(notes) + 0.6))
    out = np.zeros(total)
    for i, f in enumerate(notes):
        dur = 0.5 if i == len(notes) - 1 else 0.25
        x = t(dur)
        tone = (0.5 * square(f, x, 0.3) + 0.6 * np.sin(2 * math.pi * f * x) + 0.3 * np.sin(4 * math.pi * f * x))
        tone *= adsr(x.size, a=0.005, d=0.08, s=0.6, r=0.2)
        tone = svf(tone, 4000)
        s = int(SR * step * i)
        out[s:s + tone.size] += tone
    write("levelup.wav", reverb(out, mix=0.3), gain=0.85)


def shield():
    x = t(0.6)
    vib = 1 + 0.01 * np.sin(2 * math.pi * 7 * x)
    tone = np.sin(2 * math.pi * 660 * vib * x) + 0.5 * np.sin(2 * math.pi * 990 * vib * x) + 0.3 * np.sin(2 * math.pi * 1320 * x)
    shimmer = svf(RNG.normal(0, 1, x.size), 5000 + 3000 * np.sin(2 * math.pi * 3 * x), q=4, mode="bp") * 0.3
    env = adsr(x.size, a=0.05, d=0.1, s=0.8, r=0.3)
    write("shield.wav", reverb((tone + shimmer) * env, mix=0.35))


def lane_change():
    x = t(0.16)
    swish = svf(RNG.normal(0, 1, x.size), 1200 + 2500 * np.sin(np.pi * x / x[-1]), q=2, mode="bp")
    swish *= np.sin(np.pi * x / x[-1]) ** 1.5
    tick = np.sin(2 * math.pi * 1800 * x) * np.exp(-x * 90) * 0.5
    write("lane.wav", swish + tick, gain=0.55)


def start_rev():
    x = t(0.8)
    f = sweep(52, 190, x, curve=0.7)
    body = saw(1, x) * 0
    for k, amp in enumerate([1.0, 0.6, 0.4, 0.25, 0.15], start=1):
        body += amp * np.sin(f * k)
    body = svf(body, 2200) * adsr(x.size, a=0.02, d=0.1, s=0.9, r=0.25)
    write("start.wav", body, gain=0.8)


def music():
    """Driving synthwave-style loop: 8 bars at 128 BPM, seamless."""
    bpm = 128
    beat = 60 / bpm
    bars = 8
    total_s = beat * 4 * bars
    n = int(SR * total_s)
    out = np.zeros(n)

    def add(start_s, samples, gain=1.0):
        i = int(start_s * SR)
        idx = (np.arange(samples.size) + i) % n  # wrap tails for a seamless loop
        np.add.at(out, idx, samples * gain)

    # A minor progression: Am - F - C - G (two bars each = 8 bars)
    A2, F2, C3, G2 = 110.0, 87.31, 130.81, 98.0
    chords = [
        (A2, [220.0, 261.63, 329.63]),
        (F2, [174.61, 220.0, 261.63]),
        (C3, [261.63, 329.63, 392.0]),
        (G2, [196.0, 246.94, 293.66]),
    ]

    # Drums
    kick_x = t(0.22)
    kick = np.sin(sweep(160, 45, kick_x, curve=0.4)) * np.exp(-kick_x * 14)
    hat_x = t(0.05)
    hat = svf(RNG.normal(0, 1, hat_x.size), 7000, q=1.2, mode="bp") * np.exp(-hat_x * 90)
    snare_x = t(0.18)
    snare = (svf(RNG.normal(0, 1, snare_x.size), 1800, q=0.8, mode="bp") * np.exp(-snare_x * 22)
             + np.sin(2 * math.pi * 190 * snare_x) * np.exp(-snare_x * 30) * 0.6)

    for bar in range(bars):
        for b in range(4):
            at = (bar * 4 + b) * beat
            add(at, kick, 1.0)
            if b in (1, 3):
                add(at, snare, 0.55)
            for e in range(2):
                add(at + e * beat / 2, hat, 0.22 if e == 0 else 0.35)

    # Bass: driving 8ths, filtered saw
    for bar in range(bars):
        root, chord = chords[bar // 2]
        for e in range(8):
            at = bar * 4 * beat + e * beat / 2
            x = t(beat / 2 * 0.9)
            f = root if e % 4 != 3 else root * 2
            tone = saw(f, x) + 0.4 * square(f / 2, x, 0.4)
            tone = svf(tone, 500 + 400 * (e % 2), q=1.2) * adsr(x.size, 0.003, 0.05, 0.6, 0.06)
            add(at, tone, 0.5)

    # Arp: 16th notes cycling chord tones over two octaves
    for bar in range(bars):
        _, chord = chords[bar // 2]
        seq = chord + [c * 2 for c in chord]
        for s in range(16):
            at = bar * 4 * beat + s * beat / 4
            f = seq[(s * 3) % len(seq)]
            x = t(beat / 4 * 1.6)
            tone = (0.6 * square(f, x, 0.25) + 0.5 * tri(f, x)) * adsr(x.size, 0.002, 0.04, 0.35, 0.08)
            tone = svf(tone, 3500)
            add(at, tone, 0.16)

    # Pad: detuned saws sustaining each chord
    for bar in range(0, bars, 2):
        _, chord = chords[bar // 2]
        x = t(beat * 8)
        pad = np.zeros_like(x)
        for c in chord:
            for det in (0.995, 1.0, 1.006):
                pad += saw(c * det, x)
        pad = svf(pad, 900 + 500 * np.sin(2 * math.pi * x / x[-1]), q=0.8)
        pad *= adsr(x.size, 0.3, 0.2, 0.8, 0.5)
        add(bar * 4 * beat, pad, 0.05)

    out = svf(out, 9000)
    write("music.wav", reverb(out, tail=0.0, mix=0.12)[:n], gain=0.8)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for fn in (engine, crash, pickup, whoosh, nitro, level_up, shield, lane_change, start_rev, music):
        fn()
        print("ok", fn.__name__)
    print("generated:", sorted(os.listdir(OUT)))
