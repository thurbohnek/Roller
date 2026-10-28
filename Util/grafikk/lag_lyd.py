#!/usr/bin/env python3
"""
Lydeffektene i spillet (2026-10-28). Alt er syntetisert her, så det er
ingen lisens å ta vare på.

Kjør fra roten av repoet:   python3 Util/grafikk/lag_lyd.py

Skriver lyd/*.wav (22050 Hz, mono, 16 bit). Brukes av lib/lyd.lua.
"""
import math
import os
import wave

import numpy as np

RATE = 22050
UT = "lyd"


def tid(sek):
    return np.arange(int(RATE * sek)) / RATE


def tone(frekv, sek, demp=8.0, overtoner=(1.0, 0.3, 0.12), angrep=0.004):
    t = tid(sek)
    if callable(frekv):
        fase = 2 * math.pi * np.cumsum(frekv(t)) / RATE
    else:
        fase = 2 * math.pi * frekv * t
    s = sum(a * np.sin(fase * (i + 1)) for i, a in enumerate(overtoner))
    konvolutt = np.exp(-demp * t) * np.clip(t / angrep, 0, 1)
    return s * konvolutt


def etter(*deler, avstand):
    """Legger lydene etter hverandre med fast avstand (sekunder), overlappende."""
    n = int(RATE * avstand)
    lengde = n * (len(deler) - 1) + max(len(d) for d in deler)
    ut = np.zeros(lengde)
    for i, d in enumerate(deler):
        ut[i * n:i * n + len(d)] += d
    return ut


def lagre(navn, s, styrke=0.6):
    s = s / (np.abs(s).max() + 1e-9) * styrke
    # myk slutt, så det ikke klikker
    n = min(len(s), int(RATE * 0.01))
    s[-n:] *= np.linspace(1, 0, n)
    data = (s * 32767).astype(np.int16)
    with wave.open(os.path.join(UT, navn + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def note(n):
    """Halvtoner fra A4 (440 Hz)."""
    return 440 * 2 ** (n / 12)


def main():
    os.makedirs(UT, exist_ok=True)
    # knapp: kort, mykt "pop"
    lagre("klikk", tone(lambda t: 520 + 900 * np.exp(-t * 60), 0.07, demp=45, overtoner=(1.0, 0.15)), 0.4)
    # dråpe: lys "pling", fem tonehøyder (pentaton) som stiger når man tar mange på rad
    for i, n in enumerate([3, 5, 7, 10, 12]):
        f = note(n + 12)
        s = tone(lambda t, f=f: f * (1 + 0.03 * np.exp(-t * 40)), 0.22, demp=16, overtoner=(1.0, 0.25, 0.08))
        lagre("draape%d" % (i + 1), s, 0.42)
    # unge reddet: glad arpeggio
    lagre("unge", etter(*[tone(note(n), 0.35, demp=7) for n in (3, 7, 10, 15)], avstand=0.085), 0.55)
    # mål: liten fanfare som ender i en akkord
    biter = [tone(note(n), 0.3, demp=7) for n in (-2, 3, 7)]
    akkord = sum(tone(note(n), 1.1, demp=2.6, overtoner=(1.0, 0.35, 0.15, 0.06)) for n in (3, 7, 10, 15))
    lagre("mal", etter(*biter, akkord, avstand=0.11), 0.6)
    # død: mykt "bonk" som faller
    t = tid(0.35)
    bonk = tone(lambda t: 260 * np.exp(-t * 5) + 70, 0.35, demp=9, overtoner=(1.0, 0.4))
    stoy = np.random.default_rng(1).normal(0, 1, len(t)) * np.exp(-t * 40) * 0.25
    lagre("dod", bonk + stoy[:len(bonk)], 0.55)
    # kjøp: "ka-tsjing"
    glitter = sum(tone(note(n), 0.5, demp=6, overtoner=(1.0, 0.2)) for n in (22, 26, 29))
    lagre("kjop", etter(tone(note(15), 0.1, demp=30), glitter, avstand=0.07), 0.5)
    # gave: stigende glitter
    lagre("gave", etter(*[tone(note(n), 0.25, demp=10) for n in (10, 12, 15, 17, 19, 22, 24)], avstand=0.05), 0.5)
    print("lyder skrevet til", UT)


if __name__ == "__main__":
    main()
