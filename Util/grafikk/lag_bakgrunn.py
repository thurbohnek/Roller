#!/usr/bin/env python3
"""
Bakgrunnene bak banene i ny stil (2026-10-28).

Kjør fra roten av repoet:
    python3 Util/grafikk/lag_bakgrunn.py          # alle baner
    python3 Util/grafikk/lag_bakgrunn.py 3 --vis  # bane 3, og et bilde til å se over

Skriver per bane N:
    background/baneN_1.png   nærmeste stripe (kameralag 3, var back_cave)
    background/baneN_2.png   midterste       (lag 4, var back_cave1)
    background/baneN_3.png   fjerneste       (lag 5, var back_cave2)
    background/baneN_bunn.jpg flata bakerst  (lag 6, var dirt1)

Stripene har samme oppbygning som de gamle (1000x3000, vises 2000x6000,
dreid etter bakken og lagt etter hverandre): vegg øverst og nederst, og
et gjennomsiktig bånd i midten der grotta er. Båndet ligger på samme
høyde som før, så banefilene bare bytter filnavn. Stripene går i hverandre
sidelengs (alt er periodisk med 1000 px).

Bane 1-2 er på enga: himmel bakerst, og åser i stedet for vegger.
Bane 3-9 er under jorda: varme jordvegger med søyler i grotta, mørkere
og kaldere for hver bane.
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 1000, 3000
TAN = math.tan(math.radians(31))

# båndet (grotta) per lag, som andel av høyden, målt fra de gamle stripene
BAND = {1: (0.394, 0.624), 2: (0.410, 0.607), 3: (0.439, 0.568)}


def hexf(h):
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], float)


def mix(a, b, t):
    return a * (1 - t) + b * t


def periodisk(rng, n=6, amp=1.0):
    """Tilfeldig glatt kurve over x = 0..W-1 som går i hverandre."""
    x = np.arange(W) / W * 2 * math.pi
    y = np.zeros(W)
    for k in range(1, n + 1):
        y += rng.normal(0, 1) / k ** 1.3 * np.sin(k * x + rng.uniform(0, 6.3))
    return y / (np.abs(y).max() + 1e-9) * amp


def stoy(rng, skala, w=W, h=H):
    """Glatt støy som går i hverandre sidelengs."""
    gw, gh = max(2, w // skala), max(2, h // skala + 2)
    g = rng.normal(0, 1, (gh, gw))
    g = np.concatenate([g, g[:, :1]], axis=1)
    from scipy import ndimage as nd
    z = nd.zoom(g, (h / gh * 1.02, (w + skala) / (gw + 1) * 1.0), order=3)[:h, :w]
    return z / (np.abs(z).max() + 1e-9)


def farger(n, lag):
    """Farger for vegg i bane n, lag 1 (nær) .. 3 (fjern)."""
    t = (n - 3) / 6.0
    lys = mix(hexf("7A4A28"), hexf("4A4844"), t)
    mork = mix(hexf("2C160A"), hexf("161514"), t)
    kant = mix(hexf("D8955A"), hexf("8E9AA4"), t)
    dempe = [1.0, 0.72, 0.5][lag - 1]
    taake = mix(hexf("1A0E06"), hexf("0E0E10"), t)
    return (mix(taake, lys, dempe), mix(taake, mork, dempe), mix(taake, kant, dempe * 0.9))


def hule_stripe(n, lag, rng):
    b0, b1 = BAND[lag]
    topp = b0 * H + periodisk(rng, 7, 45)
    bunn = b1 * H + periodisk(rng, 7, 45)
    yy = np.arange(H)[:, None]
    vegg = (yy < topp[None, :]) | (yy > bunn[None, :])

    # søyler i grotta: timeglass fra tak til gulv, skrå så de står loddrett i spillet
    sm = Image.new("L", (W * 3, H), 0)
    d = ImageDraw.Draw(sm)
    antall = [2, 3, 4][lag - 1]
    for i in range(antall):
        xb = (i + rng.uniform(0.15, 0.85)) * W / antall + W
        y_a, y_b = int(b0 * H - 60), int(b1 * H + 60)
        bredde_topp = rng.uniform(55, 95) * (1.1 - 0.2 * lag)
        midt = rng.uniform(0.15, 0.55)
        pts_v, pts_h = [], []
        for j in range(41):
            s = j / 40
            y = y_a + s * (y_b - y_a)
            x = xb - (y_b - y) * TAN * 0.6
            br = bredde_topp * (midt + (1 - midt) * (2 * s - 1) ** 2) + 6
            br *= 1 + 0.12 * math.sin(s * 9 + i)
            pts_v.append((x - br / 2, y))
            pts_h.append((x + br / 2, y))
        d.polygon(pts_v + pts_h[::-1], fill=255)
    sm = np.asarray(sm) > 0
    soyle = sm[:, W:2 * W] | sm[:, :W] | sm[:, 2 * W:]
    fast = vegg | soyle

    from scipy import ndimage as nd
    avst = nd.distance_transform_edt(fast)
    lys, mork, kant = farger(n, lag)
    # mørkere innover i veggen, lysere kant mot grotta
    t = np.clip(avst / 260, 0, 1) ** 0.7
    rgb = lys[None, None] * (1 - t[..., None]) + mork[None, None] * t[..., None]
    st = stoy(rng, 60)
    rgb *= (1 + 0.07 * st)[..., None]
    rand = np.clip(1 - avst / 14, 0, 1)
    rgb = rgb * (1 - 0.65 * rand[..., None]) + kant[None, None] * 0.65 * rand[..., None]
    kontur = (avst > 0) & (avst < 3)
    rgb[kontur] = mork * 0.7

    # steiner i veggen (bare nær laget)
    if lag == 1:
        bilde = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
        d = ImageDraw.Draw(bilde, "RGBA")
        ys, xs = np.nonzero(avst > 40)
        for _ in range(55):
            i = rng.integers(0, len(xs))
            cx, cy, r = xs[i], ys[i], rng.uniform(8, 22)
            d.ellipse((cx - r, cy - r * 0.7, cx + r, cy + r * 0.7),
                      fill=tuple(int(v) for v in mix(mork, lys, 0.5)) + (120,))
        rgb = np.asarray(bilde)[..., :3].astype(float)

    alfa = nd.gaussian_filter(fast.astype(float), 1.0)
    ut = np.zeros((H, W, 4), np.uint8)
    ut[..., :3] = np.clip(rgb, 0, 255)
    ut[..., 3] = np.clip(alfa * 255, 0, 255)
    return Image.fromarray(ut, "RGBA")


def eng_stripe(n, lag, rng):
    """Åser nederst, himmel (gjennomsiktig) over. Sky på det fjerneste laget."""
    b0, b1 = BAND[lag]
    # åstoppen ligger litt inn i båndet, så åsene ses bak banen
    hoyde = [0.0, 0.05, 0.10][lag - 1]
    topp = (b1 - hoyde) * H + periodisk(rng, 2, [60, 80, 100][lag - 1])
    yy = np.arange(H)[:, None]
    fast = yy > topp[None, :]
    from scipy import ndimage as nd
    ned = (yy - topp[None, :]).clip(0)
    # Fjerne åser: grønne som går mot blått jo lenger unna, uten brun jord,
    # så de ikke kan forveksles med bakken marken ruller på.
    topp_f = [hexf("8CC98A"), hexf("A6D2AE"), hexf("BFDCD2")][lag - 1]
    bunn_f = [hexf("6FA88A"), hexf("8DBBAA"), hexf("A9C9CC")][lag - 1]
    t = np.clip(ned / 500, 0, 1)
    rgb = topp_f[None, None] * (1 - t[..., None]) + bunn_f[None, None] * t[..., None]
    gress = topp_f
    rgb *= (1 + 0.02 * stoy(rng, 80))[..., None]
    lysrand = (ned > 0) & (ned < 8)
    rgb[lysrand] = mix(gress, hexf("FFFFFF"), 0.35)
    alfa = nd.gaussian_filter(fast.astype(float), 1.0)
    ut = np.zeros((H, W, 4), np.uint8)
    ut[..., :3] = np.clip(rgb, 0, 255)
    ut[..., 3] = np.clip(alfa * 255, 0, 255)
    bilde = Image.fromarray(ut, "RGBA")
    if lag == 3:
        # skyer høyt oppe
        sky = Image.new("RGBA", (W * 3, H), (0, 0, 0, 0))
        for k in range(3):
            # hver sky i sitt eget lag, spredt jevnt bortover så de ikke overlapper
            en = Image.new("RGBA", (W * 3, H), (0, 0, 0, 0))
            d = ImageDraw.Draw(en)
            cx = W * (k + 0.5) / 3 + rng.uniform(-60, 60) + W
            cy = rng.uniform(0.12, b0 - 0.05) * H
            for j in range(9):
                dx = (j - 4) * 32 + rng.uniform(-10, 10)
                r = rng.uniform(55, 95) * (1 - abs(j - 4) / 7)
                d.ellipse((cx + dx - r, cy - r, cx + dx + r, cy + r * 0.6), fill=(255, 255, 255, 235))
            d.rectangle((cx - 200, cy + 10, cx + 200, cy + 80), fill=(0, 0, 0, 0))
            sky.alpha_composite(en)
        sky = sky.filter(ImageFilter.GaussianBlur(2))
        a = np.asarray(sky)
        samlet = np.maximum(np.maximum(a[:, :W], a[:, W:2 * W]), a[:, 2 * W:])
        skybilde = Image.fromarray(samlet, "RGBA")
        skybilde.alpha_composite(bilde)
        bilde = skybilde
    return bilde


def bunn(n):
    w, h = 500, 500
    yy = np.linspace(0, 1, h)[:, None, None]
    if n <= 2:
        a, b = hexf("6FB8F0"), hexf("D8F0FF")
    else:
        t = (n - 3) / 6.0
        a, b = mix(hexf("2A1408"), hexf("0C0B0C"), t), mix(hexf("1A0C04"), hexf("060606"), t)
    rgb = np.broadcast_to(a * (1 - yy) + b * yy, (h, w, 3))
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")


def lagre_png(bilde, sti):
    # 256 farger holder fint for glatte flater og gjør filene små
    q = bilde.quantize(colors=256, method=Image.FASTOCTREE, dither=Image.NONE)
    q.save(sti, optimize=True)


def lag(n, vis=False):
    rng = np.random.default_rng(500 + n)
    striper = []
    for lag_nr in (1, 2, 3):
        s = eng_stripe(n, lag_nr, rng) if n <= 2 else hule_stripe(n, lag_nr, rng)
        lagre_png(s, "background/bane%d_%d.png" % (n, lag_nr))
        striper.append(s)
    b = bunn(n)
    b.save("background/bane%d_bunn.jpg" % n, quality=90)
    print("bane %d: bakgrunn ferdig" % n)
    if vis:
        # tre striper side om side for hvert lag, over hverandre, på bunnfargen
        ark = Image.new("RGBA", (W * 3, H), (0, 0, 0, 255))
        ark.paste(b.resize((W * 3, H)).convert("RGBA"))
        for s in striper[::-1]:
            for i in range(3):
                ark.alpha_composite(s, (i * W, 0))
        return ark.resize((W * 3 // 4, H // 4)).rotate(-31, expand=True)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    vis = "--vis" in sys.argv
    for n in [int(a) for a in args] or range(1, 10):
        im = lag(n, vis)
        if im is not None:
            im.convert("RGB").save(os.path.join(os.environ.get("VIS_MAPPE", "."), "bakgrunn%d.jpg" % n))


if __name__ == "__main__":
    main()
