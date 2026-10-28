#!/usr/bin/env python3
"""
Lydeffektene i spillet (2026-10-28). Alt er syntetisert her, så det er
ingen lisens å ta vare på.

Kjør fra roten av repoet:   python3 Util/grafikk/lag_lyd.py

Skriver lyd/*.wav (22050 Hz, mono, 16 bit). Brukes av lib/lyd.lua.

Bakgrunnslydene (stemning_eng.wav, stemning_hule.wav) er naturlyder, ikke
musikk: vind og fugler på enga, en dyp tone og drypp med ekko i hulene.
De går sømløst i ring (halen legges inn i starten). WAV og ikke mp3, fordi
mp3 har en kort stillhet i starten som nettleserne ikke alltid fjerner.
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


def lagre_lokke(navn, mix, hale, styrke):
    """Løkke som går rundt uten hakk: de siste `hale` prøvene glir over i
    starten (krysstoning med lik effekt), så både jevn vind og drypp som
    dør ut henger sammen. Lagres i halv samplingsrate (11025 Hz), som holder
    for naturlydene og halverer filen."""
    from scipy.signal import decimate
    mix = decimate(mix, 2)
    hale //= 2
    lengde = len(mix) - hale
    t = np.linspace(0, math.pi / 2, hale)
    start = mix[:hale] * np.sin(t) + mix[lengde:] * np.cos(t)
    mix = np.concatenate([start, mix[hale:lengde]])
    mix = mix / (np.abs(mix).max() + 1e-9) * styrke
    with wave.open(os.path.join(UT, navn + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE // 2)
        w.writeframes((mix * 32767).astype(np.int16).tobytes())


def lavpass(x, a):
    """Enkel lavpass (a nær 1 = mørkere)."""
    from scipy.signal import lfilter
    return lfilter([1 - a], [1, -a], x)


def eng_stemning():
    """Enga: myk vind som kommer og går, og fugler innimellom. 32 s."""
    rng = np.random.default_rng(21)
    sek, hale = 32, 3
    n = RATE * (sek + hale)
    t = np.arange(n) / RATE
    vind = lavpass(rng.normal(0, 1, n), 0.985)
    kast = 0.55 + 0.45 * np.sin(2 * math.pi * t / 11.0) * np.sin(2 * math.pi * t / 7.3 + 1)
    mix = vind / np.abs(vind).max() * kast * 0.5
    # fugler: korte kvitter (to-tre fløytetoner som glir) på tilfeldige steder
    tidspunkt = 1.5
    while tidspunkt < sek:
        f0 = rng.uniform(2600, 4200)
        for k in range(int(rng.integers(2, 5))):
            lengde = rng.uniform(0.06, 0.12)
            tt = tid(lengde)
            glid = f0 * (1 + rng.uniform(-0.25, 0.25) * tt / lengde)
            fase = 2 * math.pi * np.cumsum(glid) / RATE
            kv = np.sin(fase) * np.sin(math.pi * tt / lengde) ** 2
            i = int((tidspunkt + k * (lengde + 0.04)) * RATE)
            mix[i:i + len(kv)] += kv * 0.22
        tidspunkt += rng.uniform(2.5, 6.0)
    lagre_lokke("stemning_eng", mix, RATE * hale, 0.5)


def hule_stemning():
    """Hulene: en dyp, rolig tone som puster, og drypp med ekko. 30 s."""
    rng = np.random.default_rng(33)
    sek, hale = 30, 4
    n = RATE * (sek + hale)
    t = np.arange(n) / RATE
    pust = 0.6 + 0.4 * np.sin(2 * math.pi * t / 15.0)
    drone = (np.sin(2 * math.pi * 55 * t) + 0.5 * np.sin(2 * math.pi * 82.5 * t + 0.7)) * pust * 0.12
    rumling = lavpass(rng.normal(0, 1, n), 0.995)
    mix = drone + rumling / np.abs(rumling).max() * 0.08
    tidspunkt = 0.8
    while tidspunkt < sek:
        f = rng.uniform(900, 1600)
        tt = tid(0.25)
        dr = np.sin(2 * math.pi * np.cumsum(f * (1 + 0.6 * np.exp(-tt * 40))) / RATE) * np.exp(-tt * 28)
        i = int(tidspunkt * RATE)
        for ekko, styrke in ((0, 0.35), (0.23, 0.12), (0.47, 0.05)):
            j = i + int(ekko * RATE)
            mix[j:j + len(dr)] += dr[:max(0, n - j)] * styrke
        tidspunkt += rng.uniform(1.5, 4.5)
    lagre_lokke("stemning_hule", mix, RATE * hale, 0.45)


def main():
    os.makedirs(UT, exist_ok=True)
    # knapp: kort, mykt "pop"
    lagre("klikk", tone(lambda t: 520 + 900 * np.exp(-t * 60), 0.07, demp=45, overtoner=(1.0, 0.15)), 0.4)
    # blad: lett rasl og en myk marimbatone; tonen stiger (pentaton) når man
    # tar mange på rad. Filene heter fortsatt draape1-5.
    rasl_rng = np.random.default_rng(5)
    for i, n in enumerate([-2, 0, 3, 5, 7]):
        f = note(n + 3)
        tt = tid(0.3)
        marimba = (np.sin(2 * math.pi * f * tt) * np.exp(-tt * 14)
                   + 0.35 * np.sin(2 * math.pi * f * 4 * tt) * np.exp(-tt * 45)) * np.clip(tt / 0.003, 0, 1)
        rasl = lavpass(rasl_rng.normal(0, 1, len(tt)), 0.6) * np.exp(-tt * 35)
        rasl = rasl - lavpass(rasl, 0.97)      # bare den lyse delen, som tørre blader
        lagre("draape%d" % (i + 1), marimba + rasl * 0.5, 0.45)
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
    eng_stemning()
    hule_stemning()
    print("lyder skrevet til", UT)


if __name__ == "__main__":
    main()
