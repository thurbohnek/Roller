#!/usr/bin/env python3
"""
Plasserer dråpene og de tre markeungene i hver bane (2026-10-28).

Kjør fra roten av repoet, etter Util/grafikk/lag_baner.py (bruker maskene):
    python3 Util/grafikk/lag_samling.py            # alle baner
    python3 Util/grafikk/lag_samling.py 6 --vis    # bane 6, og et bilde til å se over

Skriver lib/samleN.lua. Posisjonene er i spillenheter, regnet fra
sentrum av flis 1 (firkant1), så de flytter seg med banen (også med
teststart). lib/samling.lua leser dem.

Hvordan veien finnes: en "rullende kule" slippes der marken starter
(0, 0) og følger toppen av bakken mot høyre: faller der det er luft
under, klatrer små kanter, og hopper over sprekker smalere enn marken.
Den stopper ved målet. Dråpene legges med jevne mellomrom like over
bakken langs veien, ungene litt høyere på tre steder utover i banen, så
de må tas med vilje.
"""
import math
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw

MASKER = "Util/grafikk/masker"
FW, FH = 3840, 2351          # flisbilde i piksler; 1 piksel = 2 enheter

DRAAPE_AVSTAND = 330         # enheter langs veien mellom dråpene
DRAAPE_HOYDE = 34            # over bakken
UNGE_HOYDE = 70
UNGE_PLASS = (0.30, 0.62, 0.90)   # andel av veien


def fliser_og_maal(n):
    """Flisenes sentrum og målet, i enheter."""
    if n <= 4:
        f = [(3500 + i * 7680, 2300 + i * 4702) for i in range(4)]
        return f, (31000, 18000)
    kilde = open("lib/baneoppsett%d.lua" % n, encoding="utf-8").read()
    if "teststart" in kilde:
        sys.exit("lib/baneoppsett%d.lua har teststart; kjør hule.py %d --oppsett først" % (n, n))
    blokk = kilde.split("fliser")[1].split("}," + "\n    dod")[0]
    f = [(int(a), int(b)) for a, b in re.findall(r"x = (-?\d+), y = (-?\d+)", blokk)][:4]
    m = re.search(r"mal2 = \{ x = (-?\d+), y = (-?\d+)", kilde)
    return f, (int(m.group(1)), int(m.group(2)))


def verden(n):
    """Hele banen som én bool-raster (2 enheter per piksel)."""
    fliser, maal = fliser_og_maal(n)
    ox = min(cx - FW for cx, cy in fliser)
    oy = min(cy - FH for cx, cy in fliser) - 400
    bx = max(cx + FW for cx, cy in fliser)
    by = max(cy + FH for cx, cy in fliser)
    W, H = (bx - ox) // 2 + 2, (by - oy) // 2 + 2
    rast = np.zeros((H, W), bool)
    for k, (cx, cy) in enumerate(fliser, 1):
        m = np.asarray(Image.open(os.path.join(MASKER, "level%d_%d.png" % (n, k)))) > 0
        x0, y0 = (cx - FW - ox) // 2, (cy - FH - oy) // 2
        rast[y0:y0 + FH, x0:x0 + FW] |= m
    return rast, (ox, oy), fliser, maal


def vei(rast, o, maal):
    """Følger toppen av bakken fra start til mål. Liste av (x, y) i piksler."""
    H, W = rast.shape
    ox, oy = o
    x, y = (0 - ox) // 2, (0 - oy) // 2
    mx, my = (maal[0] - ox) / 2, (maal[1] - oy) / 2

    def fast(xx, yy):
        return 0 <= yy < H and 0 <= xx < W and rast[yy, xx]

    punkter = []
    steg = 0
    while steg < 200000:
        steg += 1
        if (x - mx) + (y - my) > 0 or x >= W - 2 or y >= H - 2:
            break
        if fast(x, y):                     # inni bakken: opp til lufta
            while fast(x, y) and y > 0:
                y -= 1
        if not fast(x, y + 1):             # luft under: fall
            while not fast(x, y + 1) and y < H - 2:
                y += 1
            if y >= H - 2:
                break
            punkter.append((x, y))
            continue
        punkter.append((x, y))
        nx = x + 3
        ny = y
        if fast(nx, ny):                   # kant: klatre inntil 45 px
            dy = 0
            while fast(nx, ny - dy) and dy < 45:
                dy += 1
            if fast(nx, ny - dy):          # vegg: let etter bakke litt lenger fram
                hopp = None
                for dx in range(6, 260, 3):
                    for hy in range(0, 160):
                        if not fast(x + dx, y - hy) and fast(x + dx, y - hy + 1):
                            hopp = (x + dx, y - hy)
                            break
                    if hopp:
                        break
                if not hopp:
                    break
                x, y = hopp
                continue
            ny = ny - dy + 1
        elif not fast(nx, ny + 1):
            ned = 0
            while not fast(nx, ny + 1 + ned) and ned < 40:
                ned += 1
            if ned >= 12:
                # kant, kløft eller nesten loddrett fall (over ca. 75 grader): marken hopper/faller videre mot høyre.
                # Lander på nærmeste bakketopp framover (litt over til langt under).
                land = None
                for dx in range(3, 900, 3):
                    xx = x + dx
                    if xx >= W:
                        break
                    yy = max(0, y - 80)
                    while yy < min(H - 1, y + 2800) and not fast(xx, yy):
                        yy += 1
                    if fast(xx, yy) and yy < min(H - 1, y + 2800) and yy > y - 80:
                        # må være en flate, ikke foten av en vegg
                        y2 = max(0, yy - 60)
                        while y2 < H - 1 and not fast(xx + 24, y2):
                            y2 += 1
                        if abs(y2 - yy) < 30:
                            land = (xx, yy - 1)
                            break
                if not land:
                    break
                nx, ny = land
            else:
                ny = ny + ned
        x, y = nx, ny
    return punkter


def normal(rast, x, y):
    """Retning ut av bakken (mot lufta) rundt (x, y)."""
    H, W = rast.shape
    r = 14
    y0, y1, x0, x1 = max(0, y - r), min(H, y + r + 1), max(0, x - r), min(W, x + r + 1)
    blokk = rast[y0:y1, x0:x1]
    ys, xs = np.nonzero(blokk)
    if len(xs) == 0:
        return 0.0, -1.0
    gx, gy = x - (xs + x0).mean(), y - (ys + y0).mean()
    l = math.hypot(gx, gy) or 1
    return gx / l, gy / l


def plasser(n, vis=False):
    rast, o, fliser, maal = verden(n)
    p = vei(rast, o, maal)
    if len(p) < 50:
        sys.exit("bane %d: fant ingen vei (%d punkter)" % (n, len(p)))
    # buelengde
    lengde = [0.0]
    for (a, b), (c, d) in zip(p, p[1:]):
        lengde.append(lengde[-1] + math.hypot(c - a, d - b) * 2)
    total = lengde[-1]
    ox, oy = o
    f1 = fliser[0]

    def enheter(i, hoyde):
        x, y = p[i]
        nx, ny = normal(rast, x, y)
        if ny > -0.3:            # bratt vegg: rett opp
            nx, ny = 0.0, -1.0
        ux, uy = x * 2 + ox + nx * hoyde, y * 2 + oy + ny * hoyde
        return round(ux - f1[0]), round(uy - f1[1])

    def indeks(s):
        return min(range(len(lengde)), key=lambda i: abs(lengde[i] - s))

    unger = [enheter(indeks(total * a), UNGE_HOYDE) for a in UNGE_PLASS]
    draaper = []
    s = 500
    while s < total - 200:
        i = indeks(s)
        # ikke rett ved en unge
        if all(abs(lengde[i] - total * a) > 260 for a in UNGE_PLASS):
            draaper.append(enheter(i, DRAAPE_HOYDE))
        s += DRAAPE_AVSTAND
    # målet: fra flis 1 sitt sentrum
    with open("lib/samle%d.lua" % n, "w", encoding="utf-8") as f:
        f.write("-- Generert av Util/grafikk/lag_samling.py %d. Ikke rediger for hånd.\n" % n)
        f.write("-- Dråper og markeunger i bane %d, i enheter fra sentrum av flis 1.\n" % n)
        f.write("-- Veien er %d enheter lang.\n" % total)
        f.write("return {\n    draaper = {\n")
        for x, y in draaper:
            f.write("        { %d, %d },\n" % (x, y))
        f.write("    },\n    unger = {\n")
        for x, y in unger:
            f.write("        { %d, %d },\n" % (x, y))
        f.write("    },\n}\n")
    print("bane %d: vei %d enheter, %d dråper, 3 unger" % (n, total, len(draaper)))

    if vis:
        sk = 8
        H, W = rast.shape
        im = Image.fromarray((rast[::sk, ::sk] * 150).astype(np.uint8)).convert("RGB")
        d = ImageDraw.Draw(im)
        d.line([(x / sk, y / sk) for x, y in p], fill=(255, 200, 0), width=1)
        for x, y in draaper:
            px, py = (x + f1[0] - ox) / 2 / sk, (y + f1[1] - oy) / 2 / sk
            d.ellipse((px - 2, py - 2, px + 2, py + 2), fill=(80, 200, 255))
        for x, y in unger:
            px, py = (x + f1[0] - ox) / 2 / sk, (y + f1[1] - oy) / 2 / sk
            d.ellipse((px - 5, py - 5, px + 5, py + 5), fill=(255, 100, 160))
        mx, my = (maal[0] - ox) / 2 / sk, (maal[1] - oy) / 2 / sk
        d.line([(mx + 132, my - 132), (mx - 132, my + 132)], fill=(0, 255, 0), width=2)
        sx, sy = -ox / 2 / sk, -oy / 2 / sk
        d.ellipse((sx - 4, sy - 4, sx + 4, sy + 4), fill=(255, 0, 0))
        return im


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    vis = "--vis" in sys.argv
    baner = [int(a) for a in args] or list(range(1, 10))
    for n in baner:
        im = plasser(n, vis)
        if im is not None:
            ut = os.environ.get("VIS_MAPPE", ".")
            im.save(os.path.join(ut, "samling%d.png" % n))


if __name__ == "__main__":
    main()
