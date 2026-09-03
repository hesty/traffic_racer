#!/usr/bin/env python3
"""Procedurally generates the game's sound effects into assets/audio (16-bit mono WAV)."""
import math
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


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


def env(n, attack, release):
    e = np.ones(n)
    a = int(SR * attack)
    r = int(SR * release)
    if a:
        e[:a] = np.linspace(0, 1, a)
    if r:
        e[-r:] = np.linspace(1, 0, r)
    return e


def engine():
    # Seamless 1s loop: integer number of cycles so the loop point is continuous.
    dur = 1.0
    x = t(dur)
    f0 = 56.0
    s = np.zeros_like(x)
    for k, amp in enumerate([1.0, 0.55, 0.35, 0.22, 0.14, 0.08], start=1):
        s += amp * np.sign(np.sin(2 * math.pi * f0 * k * x)) * 0.3 + amp * np.sin(2 * math.pi * f0 * k * x)
    rumble = np.sin(2 * math.pi * 28 * x) * 0.4
    noise = np.random.default_rng(1).normal(0, 0.05, x.size)
    write("engine.wav", (s + rumble + noise) * 0.35, gain=0.6)


def crash():
    x = t(0.8)
    rng = np.random.default_rng(2)
    noise = rng.normal(0, 1, x.size) * np.exp(-x * 6)
    thump = np.sin(2 * math.pi * (70 * np.exp(-x * 3)) * x) * np.exp(-x * 5)
    write("crash.wav", noise * 0.7 + thump * 1.2)


def pickup():
    parts = []
    for f in (523.25, 659.25, 783.99, 1046.5):
        x = t(0.09)
        parts.append(np.sin(2 * math.pi * f * x) * env(x.size, 0.005, 0.04))
    write("pickup.wav", np.concatenate(parts))


def whoosh():
    x = t(0.35)
    rng = np.random.default_rng(3)
    noise = rng.normal(0, 1, x.size)
    # crude one-pole lowpass with a sweeping cutoff
    out = np.zeros_like(noise)
    acc = 0.0
    for i, n in enumerate(noise):
        a = 0.05 + 0.4 * (i / noise.size)
        acc += a * (n - acc)
        out[i] = acc
    write("whoosh.wav", out * np.sin(math.pi * x / 0.35) ** 2)


def nitro():
    x = t(0.7)
    f = 180 + 700 * (x / 0.7) ** 1.5
    phase = 2 * math.pi * np.cumsum(f) / SR
    s = (np.sin(phase) + 0.4 * np.sin(2 * phase)) * env(x.size, 0.02, 0.2)
    write("nitro.wav", s)


def level_up():
    parts = []
    for f in (659.25, 987.77):
        x = t(0.22)
        parts.append((np.sin(2 * math.pi * f * x) + 0.3 * np.sin(4 * math.pi * f * x)) * env(x.size, 0.01, 0.15))
    write("levelup.wav", np.concatenate(parts))


def shield():
    x = t(0.45)
    s = np.sin(2 * math.pi * 440 * x) * np.sin(2 * math.pi * 6 * x) + np.sin(2 * math.pi * 880 * x) * 0.5
    write("shield.wav", s * env(x.size, 0.02, 0.25))


def lane_change():
    x = t(0.12)
    s = np.sin(2 * math.pi * (300 + 200 * x / 0.12) * x)
    write("lane.wav", s * env(x.size, 0.005, 0.08), gain=0.5)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for fn in (engine, crash, pickup, whoosh, nitro, level_up, shield, lane_change):
        fn()
    print("generated:", sorted(os.listdir(OUT)))
