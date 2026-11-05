#!/usr/bin/env python3
"""ui_kit 효과음을 합성한다. 외부 샘플 없이 결정적으로 같은 파일을 만들며 결과는 CC0로 저장소에 둔다."""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[1] / 'godot/addons/seorilabs_game/ui_kit/sfx'


def tone(duration, freqs, attack=0.004, decay=None, gain=0.5, noise=0.0, seed=1):
    decay = duration if decay is None else decay
    frames = int(RATE * duration)
    state = seed
    samples = []
    for i in range(frames):
        t = i / RATE
        env = min(1.0, t / attack) * math.exp(-t / decay * 4.0)
        value = sum(math.sin(2 * math.pi * f(t) * t) for f in freqs) / max(1, len(freqs))
        if noise:
            state = (state * 1103515245 + 12345) & 0x7fffffff
            value += noise * ((state / 0x7fffffff) * 2 - 1)
        samples.append(max(-1.0, min(1.0, value * env * gain)))
    return samples


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(s * 32767)) for s in samples))


def main():
    write('tap.wav', tone(0.06, [lambda t: 1800 - 6000 * t], decay=0.03, gain=0.45, noise=0.15))
    write('confirm.wav', tone(0.22, [lambda t: 660, lambda t: 880 if t > 0.08 else 660], decay=0.14, gain=0.45))
    write('cancel.wav', tone(0.16, [lambda t: 520 - 900 * t], decay=0.1, gain=0.4))
    write('error.wav', tone(0.26, [lambda t: 220, lambda t: 233], decay=0.18, gain=0.4, noise=0.05))
    sting = tone(0.9, [lambda t: 523 if t < 0.12 else 659 if t < 0.24 else 784 if t < 0.36 else 1046], decay=0.5, gain=0.5)
    shimmer = tone(0.9, [lambda t: 2093, lambda t: 2637], attack=0.2, decay=0.6, gain=0.12)
    write('reward_sting.wav', [max(-1.0, min(1.0, a + b)) for a, b in zip(sting, shimmer)])


if __name__ == '__main__':
    main()
