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
    global IS
    IS = np.zeros((H, W), bool)          # is (til pynten, som ikke skal stå på is)
    for k, (cx, cy) in enumerate(fliser, 1):
        mm = np.asarray(Image.open(os.path.join(MASKER, "level%d_%d.png" % (n, k))))
        x0, y0 = (cx - FW - ox) // 2, (cy - FH - oy) // 2
        rast[y0:y0 + FH, x0:x0 + FW] |= mm > 0
        IS[y0:y0 + FH, x0:x0 + FW] |= mm == 2
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
    """Legger bladene i mønstre langs veien, ikke jevnt:
    - buer over hoppene (viser veien gjennom lufta),
    - korte rekker på bakken med luft imellom,
    - små klaser i søkk,
    - gylne blader (verdt 5) høyt over de lengste hoppene,
    - ungene: en lett i et søkk tidlig, en i toppen av en hoppbue midt i
      banen (må hoppes riktig), og en mot slutten.
    Alt i enheter fra sentrum av flis 1."""
    rast, o, fliser, maal = verden(n)
    p = vei(rast, o, maal)
    if len(p) < 50:
        sys.exit("bane %d: fant ingen vei (%d punkter)" % (n, len(p)))
    rng = np.random.default_rng(100 + n)
    ox, oy = o
    f1 = fliser[0]
    lengde = [0.0]
    for (a, b), (c, d) in zip(p, p[1:]):
        lengde.append(lengde[-1] + math.hypot(c - a, d - b) * 2)
    total = lengde[-1]

    def verdenspunkt(i):
        x, y = p[i]
        return x * 2 + ox, y * 2 + oy

    def over_bakken(i, hoyde):
        x, y = p[i]
        nx, ny = normal(rast, x, y)
        if ny > -0.3:            # bratt vegg: rett opp
            nx, ny = 0.0, -1.0
        wx, wy = verdenspunkt(i)
        return wx + nx * hoyde, wy + ny * hoyde

    def ledig(x, y, avstand=70):
        """Ikke oppå andre ting, og ikke inni bakken."""
        for b in blader + unger:
            if math.hypot(b[0] - x, b[1] - y) < avstand:
                return False
        px, py = int((x - ox) / 2), int((y - oy) / 2)
        H, W = rast.shape
        if 0 <= py < H and 0 <= px < W and rast[max(0, py - 8):py + 8, max(0, px - 8):px + 8].any():
            return False
        return True

    blader, unger = [], []        # blader: [x, y, verdi]

    # -- hoppene: der veien gjør et sprang
    hopp = []
    for i in range(len(p) - 1):
        a, b = verdenspunkt(i), verdenspunkt(i + 1)
        if math.hypot(b[0] - a[0], b[1] - a[1]) > 40 and lengde[i] > 300:
            hopp.append((i, a, b))

    def bue(a, b, t, ekstra=0.0):
        dx = abs(b[0] - a[0])
        h = min(260, max(80, 0.3 * dx)) + ekstra
        x = a[0] + (b[0] - a[0]) * t
        y = a[1] + (b[1] - a[1]) * t - 4 * h * t * (1 - t) - DRAAPE_HOYDE
        return x, y

    for i, a, b in hopp:
        dx = abs(b[0] - a[0])
        lang = math.hypot(b[0] - a[0], b[1] - a[1])
        if dx < 60:
            # smal sprekk: ett blad rett over
            x, y = bue(a, b, 0.5)
            if ledig(x, y):
                blader.append([x, y, 1])
            continue
        k = int(min(7, max(3, lang / 130)))
        for j in range(k):
            t = 0.12 + 0.76 * j / (k - 1)
            x, y = bue(a, b, t)
            if ledig(x, y):
                blader.append([x, y, 1])

    # -- bakken mellom hoppene: rekker med luft imellom, og klaser i søkk
    hoppstart = {i for i, _, _ in hopp}
    # søkk: punkter som ligger lavere enn en rett linje 300 enheter før og etter
    sokk = []
    for i in range(len(p)):
        if lengde[i] < 400 or lengde[i] > total - 300:
            continue
        a = next((k for k in range(i, -1, -1) if lengde[i] - lengde[k] >= 300), None)
        b = next((k for k in range(i, len(p)) if lengde[k] - lengde[i] >= 300), None)
        if a is None or b is None or any(k in hoppstart for k in range(a, b)):
            continue
        ya, yb = verdenspunkt(a)[1], verdenspunkt(b)[1]
        dyp = verdenspunkt(i)[1] - (ya + yb) / 2
        if dyp > 45:
            sokk.append((dyp, i))
    sokk.sort(reverse=True)
    valgte_sokk = []
    for dyp, i in sokk:
        if all(abs(lengde[i] - lengde[k]) > 900 for k in valgte_sokk):
            valgte_sokk.append(i)
    for i in valgte_sokk:
        x, y = over_bakken(i, DRAAPE_HOYDE)
        for dx, dy in ((0, 0), (-55, -45), (55, -45), (0, -90)):
            if ledig(x + dx, y + dy, 45):
                blader.append([x + dx, y + dy, 1])

    # rekker i ulike former, med varierende (av og til lang) avstand
    FORMER = ["flat", "bolge", "stigende", "flat", "bolge"]
    s = 450.0
    while s < total - 250:
        form = FORMER[int(rng.integers(0, len(FORMER)))]
        rekke = int(rng.integers(3, 6))
        for r in range(rekke):
            k = min(range(len(lengde)), key=lambda q: abs(lengde[q] - (s + r * 85)))
            if k in hoppstart or (k - 1) in hoppstart:
                break
            if form == "bolge":
                h = DRAAPE_HOYDE + 45 * (1 - math.cos(r / (rekke - 1) * 2 * math.pi)) / 2
            elif form == "stigende":
                h = DRAAPE_HOYDE + 26 * r          # lokker til et lite hopp på slutten
            else:
                h = DRAAPE_HOYDE
            x, y = over_bakken(k, h)
            if ledig(x, y, 60):
                blader.append([x, y, 1])
        s += rekke * 85 + rng.choice([700, 900, 1200, 1600])

    # -- gylne blader over de to lengste hoppene
    lengst = sorted(hopp, key=lambda h: -abs(h[2][0] - h[1][0]))
    for i, a, b in lengst[:2]:
        if abs(b[0] - a[0]) < 200:
            continue
        x, y = bue(a, b, 0.5, ekstra=90)
        blader.append([x, y, 5])

    # -- ungene
    def naermest(liste, andel, nokkel):
        return min(liste, key=lambda e: abs(lengde[nokkel(e)] - total * andel)) if liste else None

    def ved(andel):
        return min(range(len(lengde)), key=lambda k: abs(lengde[k] - total * andel))

    # 1: i et søkk tidlig (eller på bakken ved 28 %)
    i1 = naermest([k for k in valgte_sokk if lengde[k] < total * 0.5], 0.28, lambda k: k)
    x, y = over_bakken(i1 if i1 is not None else ved(0.28), UNGE_HOYDE + 40)
    unger.append([x, y])
    # 2: i toppen av en hoppbue midt i banen
    h2 = naermest([h for h in hopp if abs(h[2][0] - h[1][0]) >= 150], 0.6, lambda h: h[0])
    if h2:
        x, y = bue(h2[1], h2[2], 0.5, ekstra=30)
    else:
        x, y = over_bakken(ved(0.6), UNGE_HOYDE + 60)
    unger.append([x, y])
    # 3: mot slutten, høyt over bakken (et lite hopp for å nå den)
    x, y = over_bakken(ved(0.9), UNGE_HOYDE + 50)
    unger.append([x, y])
    # -- sjekkpunkter: før de vanskelige partiene (lange hopp og store fall).
    # Marken startes der ved å flytte hele banen (som teststart), så stedet
    # må ha plass til hele marken (x -230..+20 fra halen) uten bakke eller
    # tak, med bakke under hele marken.
    H, W = rast.shape

    def startsted(i):
        """Halen (del1) sitt startpunkt i verden over veipunkt i, eller None."""
        x, y = p[i]
        x0, x1 = x - 118, x + 12            # marken i piksler (2 enheter per piksel)
        if x0 < 0 or x1 >= W:
            return None
        topp = []
        for xx in range(x0, x1 + 1, 2):
            kol = rast[max(0, y - 120):min(H, y + 160), xx]
            treff = np.nonzero(kol)[0]
            if len(treff) == 0:
                return None
            topp.append(max(0, y - 120) + treff[0])
        hoyest = min(topp)
        if max(topp) - hoyest > 70:          # for bratt eller ujevnt
            return None
        sy = hoyest - 24                     # marken litt over bakken
        if rast[max(0, sy - 40):sy + 10, x0:x1 + 1].any():
            return None                      # tak eller bakke i veien
        return x * 2 + ox, sy * 2 + oy

    vanskelige = [h for h in hopp if abs(h[2][0] - h[1][0]) >= 250 or abs(h[2][1] - h[1][1]) >= 500]
    sjekkpunkter = []
    for i, a, b in sorted(vanskelige, key=lambda h: h[0]):
        if lengde[i] < 2500 or lengde[i] > total - 1500:
            continue
        if sjekkpunkter and lengde[i] - sjekkpunkter[-1][2] < max(3000, total / 4.2):
            continue
        funnet = None
        for foran in range(350, 1400, 50):
            k = max(0, min(range(len(lengde)), key=lambda q: abs(lengde[q] - (lengde[i] - foran))))
            if any(q in hoppstart for q in range(max(0, k - 30), k + 1)):
                continue
            st = startsted(k)
            if st:
                funnet = (st, k)
                break
        if funnet:
            (sx, sy), k = funnet
            sjekkpunkter.append((sx, sy, lengde[k]))
        if len(sjekkpunkter) == 3:
            break

    # -- pynt langs bakken (lib/pynt.lua): navn, x, y (foten), størrelse, vinkel
    if n <= 2:
        typer = ["gress"] * 4 + ["blomst_gul", "blomst_rosa", "blomst_hvit"] * 2 + ["sopp", "stein"]
    elif n <= 5:
        typer = ["stein"] * 3 + ["sopp"] * 2 + ["sopp_glod"] * 2 + ["krystall_bla"]
    else:
        typer = ["sopp_glod"] * 3 + ["krystall_bla"] * (4 if n == 7 else 2) + ["krystall_lilla"] * 2 + ["stein"]
    pynt = []
    s_p = 200.0
    while s_p < total - 100:
        k = min(range(len(lengde)), key=lambda q: abs(lengde[q] - s_p))
        s_p += rng.uniform(140, 420)
        if any(q in hoppstart for q in range(max(0, k - 8), k + 8)):
            continue
        x, y = p[k]
        if IS[y:y + 12, max(0, x - 6):x + 6].any():
            continue
        nx, ny = normal(rast, x, y)
        vinkel = math.degrees(math.atan2(nx, -ny)) * 0.5      # planter vokser nesten rett opp
        vinkel = max(-30, min(30, vinkel))
        wx, wy = x * 2 + ox, y * 2 + oy + 10                    # litt ned i bakken
        navn = typer[int(rng.integers(0, len(typer)))]
        pynt.append((navn, wx, wy, rng.uniform(55, 95), vinkel))

    # ingen blader oppå ungene
    blader = [b for b in blader if all(math.hypot(b[0] - u[0], b[1] - u[1]) > 80 for u in unger)]

    def lokal(x, y):
        return round(x - f1[0]), round(y - f1[1])

    with open("lib/samle%d.lua" % n, "w", encoding="utf-8") as f:
        f.write("-- Generert av Util/grafikk/lag_samling.py %d. Ikke rediger for hånd.\n" % n)
        f.write("-- Blader og markeunger i bane %d, i enheter fra sentrum av flis 1.\n" % n)
        f.write("-- blader: { x, y, verdi } (verdi 5 = gyllent blad). Veien er %d enheter lang.\n" % total)
        f.write("return {\n    blader = {\n")
        for x, y, v in blader:
            f.write("        { %d, %d, %d },\n" % (lokal(x, y) + (v,)))
        f.write("    },\n    unger = {\n")
        for x, y in unger:
            f.write("        { %d, %d },\n" % lokal(x, y))
        f.write("    },\n")
        f.write("    -- pynt: { navn, x, y (foten), storrelse, vinkel }\n    pynt = {\n")
        for navn, x, y, st, v in pynt:
            lx, ly = lokal(x, y)
            f.write("        { \"%s\", %d, %d, %d, %d },\n" % (navn, lx, ly, st, v))
        f.write("    },\n")
        f.write("    -- sjekkpunkter: halens startpunkt i verden (som i banefila, uten\n")
        f.write("    -- teststart) og samme punkt fra sentrum av flis 1 (til flagget)\n")
        f.write("    sjekkpunkter = {\n")
        for sx, sy, _ in sjekkpunkter:
            lx, ly = lokal(sx, sy)
            f.write("        { x = %d, y = %d, lx = %d, ly = %d },\n" % (round(sx), round(sy), lx, ly))
        f.write("    },\n}\n")
    sum_verdi = sum(b[2] for b in blader)
    print("bane %d: vei %d enheter, %d hopp, %d blader (verdi %d), %d søkk, %d sjekkpunkter" % (
        n, total, len(hopp), len(blader), sum_verdi, len(valgte_sokk), len(sjekkpunkter)))

    if vis:
        sk = 8
        im = Image.fromarray((rast[::sk, ::sk] * 150).astype(np.uint8)).convert("RGB")
        d = ImageDraw.Draw(im)
        d.line([(x / sk, y / sk) for x, y in p], fill=(255, 200, 0), width=1)
        for x, y, v in blader:
            px, py = (x - ox) / 2 / sk, (y - oy) / 2 / sk
            r = 4 if v > 1 else 2
            d.ellipse((px - r, py - r, px + r, py + r), fill=(255, 215, 0) if v > 1 else (90, 220, 90))
        for x, y in unger:
            px, py = (x - ox) / 2 / sk, (y - oy) / 2 / sk
            d.ellipse((px - 5, py - 5, px + 5, py + 5), fill=(255, 100, 160))
        for sx, sy, _ in sjekkpunkter:
            px, py = (sx - ox) / 2 / sk, (sy - oy) / 2 / sk
            d.rectangle((px - 15, py - 4, px + 1, py + 1), fill=(255, 60, 60))
        mx, my = (maal[0] - ox) / 2 / sk, (maal[1] - oy) / 2 / sk
        d.line([(mx + 132, my - 132), (mx - 132, my + 132)], fill=(0, 255, 0), width=2)
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
