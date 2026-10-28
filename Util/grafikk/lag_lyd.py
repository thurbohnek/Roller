#!/usr/bin/env python3
"""
Lydeffektene i spillet (2026-10-28). Alt er syntetisert her, så det er
ingen lisens å ta vare på.

Kjør fra roten av repoet:   python3 Util/grafikk/lag_lyd.py

Skriver lyd/*.wav (22050 Hz, mono, 16 bit), også musikken (lyd/musikk.wav).
Musikken er WAV og ikke mp3 fordi mp3 har en kort stillhet i starten som
nettleserne ikke alltid fjerner, og da hakker løkka. Brukes av lib/lyd.lua.

Musikken er en rolig speledåse over C - Am - F - G, 96 slag i minuttet,
16 takter (40 s) som går sømløst i ring: halen av siste takt legges inn
i begynnelsen.
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


def musikk():
    rng = np.random.default_rng(8)
    bpm = 96
    slag = 60 / bpm
    takter = 16
    lengde = int(RATE * slag * 4 * takter)
    hale = int(RATE * 3)
    mix = np.zeros(lengde + hale)
    # akkorder som halvtoner fra A4; grunntone + ters + kvint
    C, Am, F, G, Dm, Em = (-9, -5, -2), (-12, -9, -5), (-16, -12, -9), (-14, -10, -7), (-7, -4, 0), (-5, -2, 2)
    gang = [C, Am, F, G, C, Am, Dm, G, F, G, Em, Am, F, G, C, C]

    def legg(s, start):
        i = int(start * RATE)
        mix[i:i + len(s)] += s[:len(mix) - i]

    for t, akk in enumerate(gang):
        t0 = t * 4 * slag
        # pute: myke, lange akkorder
        for n in akk:
            tt = tid(4 * slag + 0.6)
            pad = (np.sin(2 * math.pi * note(n) * tt) + 0.3 * np.sin(2 * math.pi * note(n) * 2.003 * tt))
            konv = np.clip(tt / 0.5, 0, 1) * np.clip((4 * slag + 0.6 - tt) / 0.6, 0, 1)
            legg(pad * konv * 0.10, t0)
        # bass på slag 1 og 3
        for b in (0, 2):
            legg(tone(note(akk[0] - 12), 1.2, demp=3.5, overtoner=(1.0, 0.25)) * 0.35, t0 + b * slag)
        # speledåse: åttendedeler fra akkordtonene, av og til en pause
        toner = [akk[0] + 12, akk[1] + 12, akk[2] + 12, akk[1] + 24, akk[0] + 24]
        monster = [0, 2, 1, 3, 2, 4, 3, 1] if t % 2 == 0 else [4, 3, 2, 1, 2, 0, 1, 2]
        for e in range(8):
            if rng.random() < 0.18 and e % 2 == 1:
                continue
            n = toner[monster[e]]
            legg(tone(note(n), 0.9, demp=5.5, overtoner=(1.0, 0.0, 0.18, 0.0, 0.06)) * 0.22, t0 + e * slag / 2)
        # lett rasling på baktakten
        for e in range(4):
            tt = tid(0.08)
            st = rng.normal(0, 1, len(tt)) * np.exp(-tt * 60)
            st = np.convolve(st, [1, -1], "same")  # bare diskant
            legg(st * 0.05, t0 + e * slag + slag / 2)
    # halen tilbake til starten, så løkka går rundt uten hakk
    mix[:hale] += mix[lengde:lengde + hale]
    mix = mix[:lengde]
    mix = mix / np.abs(mix).max() * 0.7
    with wave.open(os.path.join(UT, "musikk.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((mix * 32767).astype(np.int16).tobytes())


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
    musikk()
    print("lyder skrevet til", UT)


if __name__ == "__main__":
    main()
