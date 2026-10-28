#!/usr/bin/env python3
"""
Tegner ikonene og bakgrunnene til grensesnittet i ny stil (2026-10-28).

Kjør fra roten av repoet:   python3 Util/grafikk/lag_ui.py

Alt tegnes som vektorformer i 4x og skaleres ned, så kantene blir glatte.
Ikonene lagres i ui/ i 128 x 128 (vises som 64 eller mindre, altså skarpe
også på skjermer med dobbel oppløsning). Fargene er de samme som i
lib/ui.lua.
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

UT = "ui"
SS = 4                      # supersampling
N = 128                     # ferdig ikonstørrelse
S = N * SS


def hexf(h, a=255):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


HVIT = hexf("FFFFFF")
KREM = hexf("FFF0DC")
JORD = hexf("3E1F0C")
KANT = hexf("C47A3A")
ROSA = hexf("F49AA8")
ROSA_M = hexf("D9667A")
ROSA_L = hexf("FFC8D0")
BLA = hexf("78CDFA")
BLA_M = hexf("2E7FB8")
GULL = hexf("FFD054")
GULL_M = hexf("C9901E")
ROD = hexf("F05A6E")
ROD_M = hexf("B02A40")


def lerret():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def ferdig(im, navn, skygge=True):
    if skygge:
        a = im.split()[3]
        sk = Image.new("RGBA", im.size, (0, 0, 0, 0))
        sk.putalpha(a.point(lambda v: int(v * 0.35)))
        sk = sk.filter(ImageFilter.GaussianBlur(SS * 2))
        bunn = Image.new("RGBA", im.size, (0, 0, 0, 0))
        bunn.alpha_composite(sk, (0, SS * 4))
        bunn.alpha_composite(im)
        im = bunn
    im.resize((N, N), Image.LANCZOS).save(os.path.join(UT, navn + ".png"), optimize=True)


def p(v):
    """Koordinater i 0..1 til lerretet."""
    return v * S


# ------------------------------------------------------------- ikoner

def draape():
    im = lerret()
    d = ImageDraw.Draw(im)
    cx, cy, r = p(0.5), p(0.6), p(0.28)
    form = [(cx + r * math.sin(t), cy + r * math.cos(t)) for t in np.linspace(-2.3, 2.3, 80)]
    form = [(cx, p(0.08))] + form[::-1] + [(cx, p(0.08))]
    form = [(cx - r * 0.98 * math.sin(2.3) * 0, p(0.08))]
    pts = []
    for t in np.linspace(0, 2 * math.pi, 200):
        # dråpeform: sirkel nederst som spisses oppover
        x = math.sin(t)
        y = -math.cos(t)
        spiss = max(0, -y) ** 1.6
        pts.append((cx + r * x * (1 - spiss * 0.92), cy + r * y * (1 + spiss * 0.85)))
    d.polygon(pts, fill=BLA_M)
    inn = [(cx + (x - cx) * 0.86, cy + (y - cy) * 0.86 + p(0.01)) for x, y in pts]
    d.polygon(inn, fill=BLA)
    d.ellipse((p(0.36), p(0.52), p(0.46), p(0.68)), fill=(235, 250, 255, 255))
    d.ellipse((p(0.39), p(0.72), p(0.43), p(0.76)), fill=(235, 250, 255, 200))
    ferdig(im, "draape")


def hjerte():
    im = lerret()
    d = ImageDraw.Draw(im)
    pts = []
    for t in np.linspace(0, 2 * math.pi, 300):
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((p(0.5) + x * p(0.026), p(0.47) + y * p(0.026)))
    d.polygon(pts, fill=ROD_M)
    d.polygon([(p(0.5) + (x - p(0.5)) * 0.86, p(0.47) + (y - p(0.47)) * 0.86) for x, y in pts], fill=ROD)
    d.ellipse((p(0.28), p(0.3), p(0.4), p(0.42)), fill=(255, 220, 226, 230))
    ferdig(im, "hjerte")


def mark_ring(d, cx, cy, r, tykk, farge, mork, lys, ansikt=True, apen=50):
    """Søt, krøllet mark: en tykk bue med hode og ansikt. apen = grader
    åpning mellom hode og hale."""
    a0 = -90 + apen / 2
    a1 = 270 - apen / 2
    # kropp: mange runde ledd langs buen, mørk kant bak
    for kant, f, w in ((True, mork, tykk), (False, farge, tykk * 0.8)):
        for a in np.linspace(a0, a1, 140):
            rr = math.radians(a)
            x, y = cx + r * math.cos(rr), cy + r * math.sin(rr)
            # halen smalner
            k = 0.55 + 0.45 * min(1, (a - a0) / 70)
            ww = w * k / 2
            d.ellipse((x - ww, y - ww, x + ww, y + ww), fill=f)
    # ledd-striper
    for a in np.linspace(a0 + 25, a1 - 30, 9):
        rr = math.radians(a)
        x1, y1 = cx + (r - tykk * 0.32) * math.cos(rr), cy + (r - tykk * 0.32) * math.sin(rr)
        x2, y2 = cx + (r + tykk * 0.32) * math.cos(rr), cy + (r + tykk * 0.32) * math.sin(rr)
        d.line((x1, y1, x2, y2), fill=mork, width=int(tykk * 0.09))
    # glans langs ytterkanten
    d.arc((cx - r - tykk * 0.18, cy - r - tykk * 0.18, cx + r + tykk * 0.18, cy + r + tykk * 0.18),
          150, 230, fill=lys, width=int(tykk * 0.16))
    # hode i enden
    hr = math.radians(a1)
    hx, hy = cx + r * math.cos(hr), cy + r * math.sin(hr)
    hs = tykk * 0.62
    d.ellipse((hx - hs, hy - hs, hx + hs, hy + hs), fill=mork)
    hs2 = hs * 0.86
    d.ellipse((hx - hs2, hy - hs2, hx + hs2, hy + hs2), fill=farge)
    if ansikt:
        ex, ey = hx + hs * 0.1, hy - hs * 0.15
        er = hs * 0.36
        d.ellipse((ex - er, ey - er, ex + er, ey + er), fill=HVIT)
        pr = er * 0.55
        d.ellipse((ex - pr + er * 0.2, ey - pr, ex + pr + er * 0.2, ey + pr), fill=(40, 20, 30, 255))
        d.ellipse((ex - pr * 0.1, ey - pr * 0.8, ex + pr * 0.5, ey - pr * 0.2), fill=HVIT)
        # rødme
        d.ellipse((hx - hs * 0.55, hy + hs * 0.2, hx - hs * 0.05, hy + hs * 0.5), fill=(255, 120, 140, 160))


def unge():
    im = lerret()
    d = ImageDraw.Draw(im)
    mark_ring(d, p(0.5), p(0.52), p(0.27), p(0.2), ROSA, ROSA_M, ROSA_L)
    ferdig(im, "unge")


def unge_tom():
    im = lerret()
    d = ImageDraw.Draw(im)
    d.ellipse((p(0.14), p(0.16), p(0.86), p(0.88)), outline=(255, 240, 220, 150), width=int(p(0.06)))
    ferdig(im, "unge_tom", skygge=False)


def pause():
    im = lerret()
    d = ImageDraw.Draw(im)
    for x in (0.33, 0.57):
        d.rounded_rectangle((p(x), p(0.22), p(x + 0.12), p(0.78)), radius=p(0.05), fill=HVIT)
    ferdig(im, "pause")


def spill():
    im = lerret()
    d = ImageDraw.Draw(im)
    d.polygon([(p(0.34), p(0.2)), (p(0.34), p(0.8)), (p(0.82), p(0.5))], fill=HVIT)
    d.line([(p(0.34), p(0.2)), (p(0.34), p(0.8)), (p(0.82), p(0.5)), (p(0.34), p(0.2))], fill=HVIT,
           width=int(p(0.08)), joint="curve")
    ferdig(im, "spill")


def tilbake():
    im = lerret()
    d = ImageDraw.Draw(im)
    w = int(p(0.12))
    d.line([(p(0.62), p(0.22)), (p(0.34), p(0.5)), (p(0.62), p(0.78))], fill=HVIT, width=w, joint="curve")
    for x, y in ((p(0.62), p(0.22)), (p(0.34), p(0.5)), (p(0.62), p(0.78))):
        d.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=HVIT)
    ferdig(im, "tilbake")


def igjen():
    im = lerret()
    d = ImageDraw.Draw(im)
    w = int(p(0.11))
    d.arc((p(0.2), p(0.2), p(0.8), p(0.8)), 40, 330, fill=HVIT, width=w)
    a = math.radians(330)
    x, y = p(0.5) + p(0.3) * math.cos(a), p(0.5) + p(0.3) * math.sin(a)
    d.polygon([(x - p(0.15), y - p(0.06)), (x + p(0.08), y - p(0.16)), (x + p(0.06), y + p(0.1))], fill=HVIT)
    ferdig(im, "igjen")


def hjem():
    im = lerret()
    d = ImageDraw.Draw(im)
    d.polygon([(p(0.5), p(0.16)), (p(0.86), p(0.48)), (p(0.14), p(0.48))], fill=HVIT)
    d.rounded_rectangle((p(0.24), p(0.44), p(0.76), p(0.84)), radius=p(0.04), fill=HVIT)
    d.rounded_rectangle((p(0.43), p(0.6), p(0.57), p(0.84)), radius=p(0.03), fill=(0, 0, 0, 0))
    ferdig(im, "hjem")


def liste():
    im = lerret()
    d = ImageDraw.Draw(im)
    for y in (0.3, 0.5, 0.7):
        d.rounded_rectangle((p(0.22), p(y - 0.055), p(0.78), p(y + 0.055)), radius=p(0.05), fill=HVIT)
    ferdig(im, "liste")


def tannhjul():
    im = lerret()
    d = ImageDraw.Draw(im)
    cx = cy = p(0.5)
    pts = []
    for i in range(16 * 4):
        a = 2 * math.pi * i / 64
        tann = (i // 4) % 2 == 0
        r = p(0.36) if tann else p(0.28)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    d.polygon(pts, fill=HVIT)
    d.ellipse((cx - p(0.11), cy - p(0.11), cx + p(0.11), cy + p(0.11)), fill=(0, 0, 0, 0))
    ferdig(im, "tannhjul")


def lyd(av=False):
    im = lerret()
    d = ImageDraw.Draw(im)
    d.polygon([(p(0.16), p(0.38)), (p(0.3), p(0.38)), (p(0.5), p(0.2)), (p(0.5), p(0.8)), (p(0.3), p(0.62)),
               (p(0.16), p(0.62))], fill=HVIT)
    if av:
        w = int(p(0.08))
        d.line([(p(0.6), p(0.36)), (p(0.86), p(0.64))], fill=HVIT, width=w)
        d.line([(p(0.86), p(0.36)), (p(0.6), p(0.64))], fill=HVIT, width=w)
    else:
        for r in (0.14, 0.26):
            d.arc((p(0.5) - p(r), p(0.5) - p(r), p(0.5) + p(r), p(0.5) + p(r)), -50, 50, fill=HVIT, width=int(p(0.07)))
    ferdig(im, "lyd_av" if av else "lyd")


def laas():
    im = lerret()
    d = ImageDraw.Draw(im)
    d.arc((p(0.3), p(0.14), p(0.7), p(0.58)), 180, 360, fill=KREM, width=int(p(0.09)))
    d.line([(p(0.345), p(0.36)), (p(0.345), p(0.48))], fill=KREM, width=int(p(0.09)))
    d.line([(p(0.655), p(0.36)), (p(0.655), p(0.48))], fill=KREM, width=int(p(0.09)))
    d.rounded_rectangle((p(0.2), p(0.44), p(0.8), p(0.86)), radius=p(0.08), fill=GULL_M)
    d.rounded_rectangle((p(0.23), p(0.47), p(0.77), p(0.82)), radius=p(0.07), fill=GULL)
    d.ellipse((p(0.45), p(0.56), p(0.55), p(0.66)), fill=JORD)
    d.rectangle((p(0.48), p(0.62), p(0.52), p(0.74)), fill=JORD)
    ferdig(im, "laas")


def stjerne():
    im = lerret()
    d = ImageDraw.Draw(im)
    def stj(skala, farge):
        pts = []
        for i in range(10):
            a = -math.pi / 2 + i * math.pi / 5
            r = (p(0.4) if i % 2 == 0 else p(0.18)) * skala
            pts.append((p(0.5) + r * math.cos(a), p(0.53) + r * math.sin(a)))
        d.polygon(pts, fill=farge)
    stj(1.0, GULL_M)
    stj(0.84, GULL)
    ferdig(im, "stjerne")


def hake():
    im = lerret()
    d = ImageDraw.Draw(im)
    w = int(p(0.13))
    pts = [(p(0.2), p(0.52)), (p(0.42), p(0.74)), (p(0.82), p(0.28))]
    d.line(pts, fill=HVIT, width=w, joint="curve")
    for x, y in pts:
        d.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=HVIT)
    ferdig(im, "hake")


def hjelp():
    im = lerret()
    d = ImageDraw.Draw(im)
    from PIL import ImageFont
    f = ImageFont.truetype("Fredoka-Bold.ttf", int(p(0.82)))
    d.text((p(0.5), p(0.5)), "?", font=f, fill=HVIT, anchor="mm")
    ferdig(im, "hjelp")


def gave():
    im = lerret()
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((p(0.16), p(0.4), p(0.84), p(0.86)), radius=p(0.06), fill=hexf("D83A52"))
    d.rounded_rectangle((p(0.12), p(0.3), p(0.88), p(0.46)), radius=p(0.05), fill=hexf("FF6F86"))
    d.rectangle((p(0.44), p(0.3), p(0.56), p(0.86)), fill=GULL)
    for s in (-1, 1):
        d.ellipse((p(0.5) + s * p(0.02) - p(0.14) + s * p(0.1), p(0.12), p(0.5) + s * p(0.02) + p(0.14) + s * p(0.1),
                   p(0.32)), outline=GULL, width=int(p(0.06)))
    ferdig(im, "gave")


def magnet():
    """Evne i butikken: dråper trekkes til marken."""
    im = lerret()
    d = ImageDraw.Draw(im)
    b = p(0.17)
    d.arc((p(0.18), p(0.14), p(0.82), p(0.78)), 180, 360, fill=ROD_M, width=int(b + p(0.03)))
    d.arc((p(0.195), p(0.155), p(0.805), p(0.765)), 180, 360, fill=ROD, width=int(b))
    for x in (p(0.18), p(0.82) - b - p(0.03)):
        d.rectangle((x, p(0.46), x + b + p(0.03), p(0.66)), fill=ROD)
        d.rectangle((x, p(0.66), x + b + p(0.03), p(0.84)), fill=hexf("E8EEF2"))
        d.rectangle((x, p(0.80), x + b + p(0.03), p(0.84)), fill=hexf("B8C2CA"))
    ferdig(im, "magnet")


def klover():
    """Evne i butikken: flaks gir doble dråper."""
    im = lerret()
    d = ImageDraw.Draw(im)
    gr, grm = hexf("6BD98A"), hexf("2F9A52")
    d.line([(p(0.5), p(0.55)), (p(0.62), p(0.9))], fill=grm, width=int(p(0.06)))
    for a in (0, 90, 180, 270):
        r = math.radians(a + 45)
        cx, cy = p(0.5) + math.cos(r) * p(0.17), p(0.47) + math.sin(r) * p(0.17)
        d.ellipse((cx - p(0.17), cy - p(0.17), cx + p(0.17), cy + p(0.17)), fill=grm)
        d.ellipse((cx - p(0.145), cy - p(0.145), cx + p(0.145), cy + p(0.145)), fill=gr)
    d.ellipse((p(0.44), p(0.41), p(0.56), p(0.53)), fill=grm)
    ferdig(im, "klover")


def radar():
    """Evne i butikken: pil mot ungene."""
    im = lerret()
    d = ImageDraw.Draw(im)
    d.ellipse((p(0.1), p(0.1), p(0.9), p(0.9)), fill=hexf("2E7FB8"))
    d.ellipse((p(0.14), p(0.14), p(0.86), p(0.86)), fill=hexf("5BB8F0"))
    for r in (0.27, 0.15):
        d.ellipse((p(0.5 - r), p(0.5 - r), p(0.5 + r), p(0.5 + r)), outline=hexf("D8F2FF"), width=int(p(0.025)))
    d.pieslice((p(0.14), p(0.14), p(0.86), p(0.86)), 290, 340, fill=(255, 255, 255, 120))
    d.ellipse((p(0.6), p(0.26), p(0.72), p(0.38)), fill=ROSA)
    d.ellipse((p(0.46), p(0.46), p(0.54), p(0.54)), fill=HVIT)
    ferdig(im, "radar")


def flagg():
    """Oppdrag."""
    im = lerret()
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((p(0.2), p(0.1), p(0.27), p(0.9)), radius=p(0.03), fill=hexf("8A5A34"))
    d.polygon([(p(0.27), p(0.14)), (p(0.84), p(0.26)), (p(0.27), p(0.54))], fill=GULL_M)
    d.polygon([(p(0.27), p(0.17)), (p(0.78), p(0.27)), (p(0.27), p(0.5))], fill=GULL)
    d.ellipse((p(0.15), p(0.06), p(0.32), p(0.2)), fill=GULL)
    ferdig(im, "flagg")


def pose():
    """Butikken."""
    im = lerret()
    d = ImageDraw.Draw(im)
    d.arc((p(0.32), p(0.1), p(0.68), p(0.46)), 180, 360, fill=JORD, width=int(p(0.05)))
    d.rounded_rectangle((p(0.16), p(0.3), p(0.84), p(0.9)), radius=p(0.08), fill=hexf("C9405A"))
    d.rounded_rectangle((p(0.2), p(0.34), p(0.8), p(0.86)), radius=p(0.06), fill=hexf("F05A6E"))
    # en dråpe på posen
    d.ellipse((p(0.38), p(0.5), p(0.62), p(0.74)), fill=BLA)
    d.polygon([(p(0.5), p(0.38)), (p(0.385), p(0.6)), (p(0.615), p(0.6))], fill=BLA)
    ferdig(im, "pose")


def blad(gull=False):
    """Pengene i spillet: et blad (meitemark drar blader ned i gangene sine
    for å spise dem). gull=True: gyllent blad, verdt 5."""
    im = lerret()
    d = ImageDraw.Draw(im)
    if gull:
        lys, mid, mork, nerve = hexf("FFE58A"), hexf("FFC53D"), hexf("C9901E"), hexf("FFF4C8")
    else:
        lys, mid, mork, nerve = hexf("9BE07A"), hexf("5BBF5A"), hexf("2F8A3E"), hexf("D8F5C0")
    # bladform: to buer mellom stilk og spiss, litt på skrå
    cx, cy = p(0.5), p(0.48)
    vinkel = math.radians(-35)
    def rot(x, y):
        return (cx + x * math.cos(vinkel) - y * math.sin(vinkel), cy + x * math.sin(vinkel) + y * math.cos(vinkel))
    pts = []
    for t in np.linspace(0, math.pi, 60):
        pts.append(rot(-p(0.36) * math.cos(t), -p(0.2) * math.sin(t) ** 0.9))
    for t in np.linspace(math.pi, 0, 60):
        pts.append(rot(-p(0.36) * math.cos(t), p(0.2) * math.sin(t) ** 0.9))
    d.polygon(pts, fill=mork)
    indre = [(cx + (x - cx) * 0.86, cy + (y - cy) * 0.86) for x, y in pts]
    d.polygon(indre, fill=mid)
    # lys halvdel
    halv = [rot(-p(0.36) * math.cos(t) * 0.86, -p(0.2) * math.sin(t) ** 0.9 * 0.86) for t in np.linspace(0, math.pi, 60)]
    d.polygon(halv + [rot(p(0.31), 0)], fill=lys)
    # midtnerve og sidenerver
    d.line([rot(-p(0.44), 0), rot(p(0.3), 0)], fill=nerve, width=int(p(0.025)))
    d.line([rot(-p(0.44), 0), rot(-p(0.36), 0)], fill=mork, width=int(p(0.04)))   # stilk
    for x in (-0.18, -0.04, 0.1):
        for sy in (-1, 1):
            d.line([rot(p(x), 0), rot(p(x + 0.1), sy * p(0.12))], fill=nerve, width=int(p(0.016)))
    if gull:
        for gx, gy, r in ((0.78, 0.22, 0.05), (0.22, 0.8, 0.035)):
            d.polygon([(p(gx), p(gy - r * 2)), (p(gx + r * 0.5), p(gy)), (p(gx), p(gy + r * 2)), (p(gx - r * 0.5), p(gy))], fill=HVIT)
            d.polygon([(p(gx - r * 2), p(gy)), (p(gx), p(gy - r * 0.5)), (p(gx + r * 2), p(gy)), (p(gx), p(gy + r * 0.5))], fill=HVIT)
    ferdig(im, "blad_gull" if gull else "blad")


def pauseknapp():
    """pauseknapp.png i roten (knapp1 i banefilene): rund jordknapp med
    pause-ikon, samme stil som ui.rundKnapp. 150 x 150."""
    n = 150 * SS
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    r = n * 0.46
    c = n / 2
    d.ellipse((c - r, c - r + n * 0.03, c + r, c + r + n * 0.03), fill=hexf("C47A3A"))
    topp, bunn = np.array([106, 58, 26]), np.array([74, 36, 16])
    for i in range(int(2 * r)):
        t = i / (2 * r)
        f = tuple(int(v) for v in topp * (1 - t) + bunn * t)
        y = c - r + i
        w = math.sqrt(max(0, r * r - (y - c) ** 2))
        d.line((c - w, y, c + w, y), fill=f + (255,))
    d.ellipse((c - r, c - r, c + r, c + r), outline=hexf("C47A3A"), width=int(n * 0.025))
    for x in (0.38, 0.54):
        d.rounded_rectangle((n * x, n * 0.32, n * (x + 0.09), n * 0.68), radius=n * 0.04, fill=KREM)
    im.resize((150, 150), Image.LANCZOS).save("pauseknapp.png", optimize=True)


def main():
    os.makedirs(UT, exist_ok=True)
    pauseknapp()
    for f in (draape, hjerte, unge, unge_tom, pause, spill, tilbake, igjen, hjem, liste, tannhjul,
              laas, stjerne, hake, gave, hjelp, magnet, klover, radar, flagg, pose, blad):
        f()
    blad(gull=True)
    lyd(False)
    lyd(True)
    print("ikoner skrevet til", UT)




# ------------------------------------------------------------- bakgrunner
#
# Bakgrunnene er 2400 x 1440, altså 1200 x 720 skjermenheter i 2x. Innholdet
# er 960 x 540; 120 enheter på hver side dekker brede telefoner (opptil
# 20:9), og 90 over og under dekker høye skjermer som iPad (4:3).
# k(x, y) gjør om fra skjermenheter (som i Lua) til bildepiksler.

BW, BH = 2400, 1440


def k(x, y):
    return (x + 120) * 2, (y + 90) * 2


def gradient_bilde(w, h, topp, bunn):
    t = np.linspace(0, 1, h)[:, None, None]
    a = np.array(topp[:3]) * (1 - t) + np.array(bunn[:3]) * t
    return Image.fromarray((a * np.ones((1, w, 1))).astype(np.uint8)).convert("RGBA")


def bolge(x, base, ledd, fro):
    r = np.random.default_rng(fro)
    return base + sum(a * np.sin(2 * math.pi * x / p_ + r.uniform(0, 6)) for p_, a in ledd)


def overflate(im, gress_y, fro=1):
    """Himmel over gress_y (bildepiksler), eng med gress og en sol."""
    d = ImageDraw.Draw(im)
    himmel = gradient_bilde(BW, int(gress_y) + 60, hexf("7CC8FF"), hexf("D6EEFF"))
    im.alpha_composite(himmel, (0, 0))
    glod = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(glod).ellipse((1880, 60, 2220, 400), fill=(255, 250, 210, 170))
    im.alpha_composite(glod.filter(ImageFilter.GaussianBlur(50)))
    ImageDraw.Draw(im).ellipse((1975, 150, 2125, 300), fill=(255, 249, 220, 255))
    x = np.arange(BW)
    for b, c, f in ((gress_y - 70, hexf("A8DCC0"), fro), (gress_y - 35, hexf("86C9A0"), fro + 1)):
        y = bolge(x, b, [(700, 22), (230, 8)], f)
        ImageDraw.Draw(im).polygon(list(zip(x, y)) + [(BW, BH), (0, BH)], fill=c)
    return x


def jord(im, gress_y, morkere_mot_bunn=True, fro=3):
    """Jord under gress_y med lag, steiner og røtter."""
    x = np.arange(BW)
    topp = bolge(x, gress_y, [(900, 10), (300, 5)], fro)
    lag = Image.new("RGBA", im.size, (0, 0, 0, 0))
    g = gradient_bilde(BW, BH, hexf("8A5530"), hexf("2A1408") if morkere_mot_bunn else hexf("5A3014"))
    maske = Image.new("L", im.size, 0)
    ImageDraw.Draw(maske).polygon(list(zip(x, topp)) + [(BW, BH), (0, BH)], fill=255)
    lag.paste(g, (0, 0), maske)
    im.alpha_composite(lag)
    d = ImageDraw.Draw(im)
    # jordlag (svake striper)
    for i, yy in enumerate((topp.mean() + 180, topp.mean() + 420, topp.mean() + 700)):
        y = bolge(x, yy, [(800, 25), (260, 10)], fro + 10 + i)
        ov = Image.new("RGBA", im.size, (0, 0, 0, 0))
        ImageDraw.Draw(ov).line(list(zip(x, y)), fill=(0, 0, 0, 40), width=26)
        im.alpha_composite(ov.filter(ImageFilter.GaussianBlur(6)))
    # gresskant
    d = ImageDraw.Draw(im)
    d.line(list(zip(x, topp + 10)), fill=hexf("3C9A4B"), width=34)
    d.line(list(zip(x, topp - 2)), fill=hexf("6CCB72"), width=16)
    r = np.random.default_rng(fro)
    for _ in range(220):
        gx = int(r.integers(0, BW))
        yy = topp[gx]
        d.line([(gx, yy), (gx + int(r.integers(-8, 9)), yy - int(r.integers(14, 34)))],
               fill=hexf("5BC46A") if r.random() < .5 else hexf("3C9A4B"), width=5)
    # steiner
    for _ in range(70):
        cx = int(r.integers(0, BW))
        cy = int(r.integers(int(topp.mean()) + 60, BH))
        rx, ry = int(r.integers(14, 46)), int(r.integers(10, 28))
        dyp = (cy - topp.mean()) / (BH - topp.mean())
        f = tuple(int(c * (1 - 0.5 * dyp)) for c in (150, 98, 58))
        d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=f + (255,), outline=(40, 20, 8, 160), width=4)
        d.arc((cx - rx + 5, cy - ry + 4, cx + rx - 5, cy + ry - 4), 200, 290, fill=(255, 255, 255, 50), width=4)
    # røtter fra gresset
    for rx in r.integers(0, BW, 9):
        y0 = topp[int(rx)] + 20
        pts = [(rx + 20 * math.sin(t / 50), y0 + t) for t in range(0, int(r.integers(140, 320)), 8)]
        d.line(pts, fill=hexf("B07A48"), width=10, joint="curve")
        for j in range(4, len(pts) - 2, 7):
            s = 1 if j % 2 else -1
            d.line([pts[j], (pts[j][0] + s * 40, pts[j][1] + 50)], fill=hexf("B07A48"), width=5)
    return topp


def hule(im, cx, cy, w, h, lys=1.0):
    """Hulrom (bildepiksler): mørkt innvendig, varmt lys, kant."""
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((cx - w / 2 - 10, cy - h / 2 - 6, cx + w / 2 + 10, cy + h / 2 + 14), radius=h / 2,
                        fill=hexf("1E0C04"))
    d.rounded_rectangle((cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), radius=h / 2 - 6, fill=hexf("3A1C0A"))
    glod = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(glod).ellipse((cx - w * 0.4, cy - h * 0.35, cx + w * 0.4, cy + h * 0.4),
                                 fill=(255, 190, 110, int(70 * lys)))
    im.alpha_composite(glod.filter(ImageFilter.GaussianBlur(40)))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((cx - w / 2 + 16, cy + h / 2 - 34, cx + w / 2 - 16, cy + h / 2 - 8), radius=13,
                        fill=hexf("5A3014"))  # gulv


def tunnel(im, pts, bredde=54):
    d = ImageDraw.Draw(im)
    d.line(pts, fill=hexf("1E0C04"), width=bredde + 16, joint="curve")
    d.line(pts, fill=hexf("3A1C0A"), width=bredde, joint="curve")
    for x, y in (pts[0], pts[-1]):
        pass


# Rommene i hjemmet, i skjermenheter (samme tall som scenes/hjem.lua).
HJEM_ROM = {
    "spill": (480, 330, 300, 150),
    "familie": (175, 290, 230, 124),
    "athletics": (205, 455, 250, 104),
    "butikk": (785, 290, 230, 124),
    "oppdrag": (755, 455, 250, 104),
}


def hjem_bg():
    im = Image.new("RGBA", (BW, BH), (0, 0, 0, 255))
    gress = k(0, 150)[1]
    overflate(im, gress)
    jord(im, gress)
    # inngang fra gresset ned til spillrommet
    sx, sy = k(480, 150)
    tunnel(im, [(sx + 20, sy + 10), (sx - 10, sy + 120), (sx + 10, k(0, 330)[1] - 120)], 64)
    # tunneler mellom rommene
    tunnel(im, [k(175, 290), k(330, 300), k(480, 330)])
    tunnel(im, [k(785, 290), k(630, 300), k(480, 330)])
    tunnel(im, [k(175, 290), k(190, 380), k(205, 455)])
    tunnel(im, [k(785, 290), k(770, 380), k(755, 455)])
    tunnel(im, [k(480, 330), k(480, 420), k(330, 460), k(205, 455)])
    tunnel(im, [k(480, 420), k(630, 460), k(755, 455)])
    for navn, (x, y, w, h) in HJEM_ROM.items():
        cx, cy = k(x, y)
        hule(im, cx, cy, w * 2, h * 2, 1.3 if navn == "spill" else 1.0)
    im.convert("RGB").save(os.path.join(UT, "hjem_bg.jpg"), quality=90)


# Stoppene på banevalget, i skjermenheter (samme tall som scenes/banevalg.lua).
BANEVALG = [(105, 226), (235, 226), (450, 300), (610, 300), (770, 330), (850, 410), (710, 455),
             (545, 470), (380, 490)]
HULL = (335, 246)


def kurve(pts, n=24):
    """Catmull-Rom gjennom punktene (jevn tunnel)."""
    p_ = [pts[0]] + list(pts) + [pts[-1]]
    ut = []
    for i in range(1, len(p_) - 2):
        p0, p1, p2, p3 = (np.array(v, float) for v in p_[i - 1:i + 3])
        for t in np.linspace(0, 1, n, endpoint=False):
            ut.append(tuple(0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                                   + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3)))
    ut.append(tuple(pts[-1]))
    return ut


def banevalg_bg():
    im = Image.new("RGBA", (BW, BH), (0, 0, 0, 255))
    gress = k(0, 250)[1]
    overflate(im, gress, fro=7)
    jord(im, gress, fro=11)
    pts = [k(*p_) for p_ in BANEVALG]
    d = ImageDraw.Draw(im)
    # sti på gresset fra 1 til 2 og videre til hullet (prikker)
    for a_, b_ in ((pts[0], pts[1]), (pts[1], k(*HULL))):
        for t in np.linspace(0, 1, 8)[1:-1]:
            x = a_[0] + (b_[0] - a_[0]) * t
            y = a_[1] + (b_[1] - a_[1]) * t - 18 * math.sin(math.pi * t)
            d.ellipse((x - 8, y - 8, x + 8, y + 8), fill=(255, 255, 255, 235))
    # hullet i gresset og tunnelen videre ned
    hx, hy = k(*HULL)
    vei = kurve([(hx, hy + 10), (hx + 30, hy + 70)] + pts[2:])
    d.line(vei, fill=hexf("1E0C04"), width=96, joint="curve")
    d.line(vei, fill=hexf("3A1C0A"), width=72, joint="curve")
    for (x, y), r in ((vei[-1], 48), ):
        d.ellipse((x - r, y - r, x + r, y + r), fill=hexf("1E0C04"))
        d.ellipse((x - r + 12, y - r + 12, x + r - 12, y + r - 12), fill=hexf("3A1C0A"))
    d.ellipse((hx - 80, hy - 26, hx + 80, hy + 30), fill=hexf("1E0C04"))
    d.ellipse((hx - 66, hy - 16, hx + 66, hy + 22), fill=hexf("120602"))
    # mørkere nedover
    t = np.linspace(0, 1, BH)[:, None]
    a = np.clip((t - 0.5) / 0.5, 0, 1) * 120
    slor = np.zeros((BH, BW, 4), np.uint8)
    slor[..., 3] = (a * np.ones((1, BW))).astype(np.uint8)
    im.alpha_composite(Image.fromarray(slor, "RGBA"))
    # lysende sopp ved de dypeste stoppene
    for i in (5, 7, 8):
        x, y = pts[i]
        sx_, sy_ = x + 120, y - 60
        glod = Image.new("RGBA", im.size, (0, 0, 0, 0))
        ImageDraw.Draw(glod).ellipse((sx_ - 50, sy_ - 50, sx_ + 50, sy_ + 50), fill=(140, 255, 200, 80))
        im.alpha_composite(glod.filter(ImageFilter.GaussianBlur(18)))
        d = ImageDraw.Draw(im)
        d.rectangle((sx_ - 5, sy_, sx_ + 5, sy_ + 34), fill=(225, 214, 180, 255))
        d.pieslice((sx_ - 26, sy_ - 20, sx_ + 26, sy_ + 20), 180, 360, fill=(140, 240, 190, 255))
    im.convert("RGB").save(os.path.join(UT, "banevalg_bg.jpg"), quality=90)


def arena_bg():
    """Arenaen bak Worm athletics: en stor hule under jorda med tribuner,
    publikum (små marker), flagg og lykter. 2400 x 1080 (1200 x 540
    skjermenheter i 2x) og går i ring sidelengs, for lib/minisport.lua
    legger flere etter hverandre og ruller dem sakte."""
    W, H = 2400, 1080
    rng = np.random.default_rng(77)
    # bakvegg: varm jord, mørkere nedover
    im = gradient_bilde(W, H, hexf("6A3E1E"), hexf("2A1406")).convert("RGBA")
    d = ImageDraw.Draw(im)

    def per(n, amp, fro):
        r = np.random.default_rng(fro)
        x = np.arange(W) / W * 2 * math.pi
        y = np.zeros(W)
        for k in range(1, n + 1):
            y += r.normal(0, 1) / k * np.sin(k * x + r.uniform(0, 6.3))
        return y / (np.abs(y).max() + 1e-9) * amp

    # lyse flekker (lys fra lyktene)
    # (tegnes tre ganger så bredt og klippes, så uskarpheten går i ring)
    lys = Image.new("RGBA", (W * 3, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lys)
    for x in range(150, W * 3, 600):
        ld.ellipse((x - 260, 120, x + 260, 560), fill=(255, 190, 110, 60))
    lys = lys.filter(ImageFilter.GaussianBlur(90)).crop((W, 0, 2 * W, H))
    im.alpha_composite(lys)
    d = ImageDraw.Draw(im)

    # tribuner med publikum: små og dempet, så spillerens mark skiller seg ut
    farger = [("F49AA8", "C95574"), ("FFC53D", "C9901E"), ("78CDFA", "2E7FB8"), ("6FD488", "3A9E58"),
              ("A97BF0", "7449C0"), ("FF9A3D", "C9661E")]
    trib = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    td = ImageDraw.Draw(trib)
    rader = ((520, 18), (575, 20), (635, 22), (700, 24), (770, 26))
    for trinn, (y0, st) in enumerate(rader):
        d.rectangle((0, y0 + st * 0.9, W, y0 + st * 0.9 + 60), fill=hexf(["5E3618", "573216", "502C12", "4A2810", "42240E"][trinn]))
        d.rectangle((0, y0 + st * 0.9, W, y0 + st * 0.9 + 6), fill=hexf("8A5A34"))
        x = rng.uniform(0, 30)
        while x < W - st * 2:
            f, m = farger[rng.integers(0, len(farger))]
            mark_ring(td, x + st, y0 + st * 0.2 + rng.uniform(-3, 3), st * 0.55, st * 0.42,
                      hexf(f), hexf(m), (255, 255, 255, 90), ansikt=True, apen=rng.uniform(40, 80))
            x += st * 2.3 + rng.uniform(0, st * 0.8)
    # demp: blekere og mørkere, som om de sitter i halvmørket
    a = np.asarray(trib).astype(float)
    gra = a[..., :3].mean(axis=2, keepdims=True)
    a[..., :3] = (a[..., :3] * 0.45 + gra * 0.55) * 0.62
    im.alpha_composite(Image.fromarray(a.astype(np.uint8), "RGBA"))
    d = ImageDraw.Draw(im)
    # tak med drypp
    tak = 120 + per(6, 40, 3)
    pts = [(0, 0)] + [(x, tak[x]) for x in range(0, W, 8)] + [(W, tak[0]), (W, 0)]
    d.polygon(pts, fill=hexf("3E1F0C"))
    for i in range(14):
        x = (i + rng.uniform(0.2, 0.8)) * W / 14
        y = tak[int(x) % W]
        l = rng.uniform(40, 120)
        b = rng.uniform(18, 34)
        d.polygon([(x - b, y - 4), (x + b, y - 4), (x, y + l)], fill=hexf("3E1F0C"))
    d.line([(x, tak[x] + 2) for x in range(0, W, 8)] + [(W, tak[0] + 2)], fill=hexf("8A5A34"), width=6)
    # flaggsnorer og lykter
    for start in range(0, W, 600):
        a, b = (start, 200), (start + 600, 200)
        pkt = [(a[0] + t * 600, 200 + 70 * math.sin(math.pi * t)) for t in np.linspace(0, 1, 30)]
        d.line(pkt, fill=hexf("2A1406"), width=5)
        for i, t in enumerate(np.linspace(0.08, 0.92, 9)):
            x, y = a[0] + t * 600, 200 + 70 * math.sin(math.pi * t)
            f = hexf(["F05A6E", "FFD054", "78CDFA", "6FD488"][i % 4])
            d.polygon([(x - 16, y), (x + 16, y), (x, y + 38)], fill=f)
        lx = start + 300
        d.line([(lx, tak[lx % W]), (lx, 330)], fill=hexf("2A1406"), width=4)
        d.rounded_rectangle((lx - 22, 330, lx + 22, 380), radius=10, fill=hexf("FFD054"))
        d.rounded_rectangle((lx - 22, 330, lx + 22, 340), radius=4, fill=hexf("3E1F0C"))
    gl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gl)
    for start in range(0, W, 600):
        lx = start + 300
        gd.ellipse((lx - 90, 265, lx + 90, 445), fill=(255, 210, 120, 110))
    im.alpha_composite(gl.filter(ImageFilter.GaussianBlur(30)))  # lyktene er langt fra kantene
    im.convert("RGB").save(os.path.join(UT, "arena_bg.jpg"), quality=88)


def bakgrunner():
    hjem_bg()
    banevalg_bg()
    arena_bg()
    print("bakgrunner skrevet til", UT)


if __name__ == "__main__":
    main()
    bakgrunner()
