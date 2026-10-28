#!/usr/bin/env python3
"""
Tegner marken i ny stil (2026-10-28): hale, kroppsledd og hode, i alle
fargene som kan kjøpes i butikken, og hattene.

Kjør fra roten av repoet:
    python3 Util/grafikk/lag_mark.py

Skriver:
    hale.png, del1.png, hode.png      standardmarken (rosa), brukt av banene
    mark/<drakt>/hale.png ...         hver drakt i butikken
    mark/hatt_<navn>.png              hattene

Størrelsene følger visningen i banene (hale 27x17, ledd 34x17, hode 30x25)
ganger 4, så bildet ikke strekkes. Formen innenfor rammen er lagt etter
kollisjonsformene i banene, så marken ser ut som den kolliderer.
Hodet peker mot venstre, halen mot høyre, som i banene.
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SS = 4          # tegnes 4x større og skaleres ned (glatte kanter)
SKALA = 4       # bildet er 4x visningsstørrelsen

# drakt: lys topp, mellom, mørk buk, kontur, ringfarge, mønster
DRAKTER = {
    "rosa":   ("FFB3BE", "F2849A", "C95574", "7A2A3E", "D86A84", None),
    "sol":    ("FFE48A", "FFC53D", "E0951A", "7A4A0A", "E8A52A", None),
    "hav":    ("A8E4FF", "5BB8F0", "2F7FC4", "123E6A", "4A9ADB", None),
    "mynte":  ("B9F2C4", "6FD488", "3A9E58", "17502A", "55B870", None),
    "drue":   ("DCC2FF", "A97BF0", "7449C0", "33195E", "8C5CD8", None),
    "tiger":  ("FFD08A", "FF9A3D", "D8661E", "5A2508", "3A1A08", "striper"),
    "natt":   ("6E7BA8", "3E4A78", "232B4E", "0C1024", "56649A", "stjerner"),
    "regnbue": ("FFFFFF", "F0F0F0", "D8D8D8", "4A3A5A", "C0C0C0", "regnbue"),
}

REGNBUE = ["FF6B6B", "FFB84D", "FFE45C", "6BD98A", "5BB8F0", "A97BF0"]


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def gradient_v(w, h, topp, midt, bunn):
    """Loddrett gradient topp -> midt -> bunn (lys ovenfra)."""
    t = np.linspace(0, 1, h)[:, None]
    a, b, c = (np.array(hexrgb(x), float) for x in (topp, midt, bunn))
    ov = np.where(t < 0.45, 0, 1)
    f1 = np.clip(t / 0.45, 0, 1)
    f2 = np.clip((t - 0.45) / 0.55, 0, 1)
    rgb = (a * (1 - f1) + b * f1)[..., None, :] * (1 - ov[..., None]) + \
          (b * (1 - f2) + c * f2)[..., None, :] * ov[..., None]
    rgb = np.broadcast_to(rgb.reshape(h, 1, 3), (h, w, 3))
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")


def fyll(maske, drakt, w, h):
    lys, mid, mork, kant, ring, monster = drakt
    farge = gradient_v(w, h, lys, mid, mork).convert("RGBA")
    if monster == "regnbue":
        arr = np.zeros((h, w, 3))
        n = len(REGNBUE)
        for i, c in enumerate(REGNBUE):
            y0, y1 = int(h * i / n), int(h * (i + 1) / n) + 1
            arr[y0:y1] = hexrgb(c)
        lysne = np.linspace(1.15, 0.85, h)[:, None, None]
        farge = Image.fromarray(np.clip(arr * lysne, 0, 255).astype(np.uint8)).convert("RGBA")
    ut = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ut.paste(farge, (0, 0), maske)
    return ut


def kontur(maske, farge, bredde):
    m = maske.filter(ImageFilter.MaxFilter(bredde * 2 + 1))
    ut = Image.new("RGBA", maske.size, hexrgb(farge) + (0,))
    ut.putalpha(m)
    return ut


def glans(bilde, maske, x0, y0, x1, y1):
    """Hvit glansstripe øverst."""
    g = Image.new("L", bilde.size, 0)
    ImageDraw.Draw(g).rounded_rectangle((x0, y0, x1, y1), radius=(y1 - y0) // 2, fill=120)
    g = g.filter(ImageFilter.GaussianBlur(SS * 1.5))
    g = Image.composite(g, Image.new("L", g.size, 0), maske)
    hvit = Image.new("RGBA", bilde.size, (255, 255, 255, 0))
    hvit.putalpha(g)
    bilde.alpha_composite(hvit)


def ringer(bilde, maske, xs, drakt, h):
    """Leddringer: en mørk og en lys linje, bare innenfor kroppen."""
    lag = Image.new("RGBA", bilde.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lag)
    r = hexrgb(drakt[4])
    for x in xs:
        d.line([(x, 0), (x, h)], fill=r + (200,), width=int(SS * 2.2))
        d.line([(x + SS * 2.4, 0), (x + SS * 2.4, h)], fill=(255, 255, 255, 70), width=int(SS * 1.4))
    tom = Image.new("RGBA", bilde.size, (0, 0, 0, 0))
    bilde.alpha_composite(Image.composite(lag, tom, maske))


def monster(bilde, maske, drakt, w, h, frø):
    rng = np.random.default_rng(frø)
    lag = Image.new("RGBA", bilde.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lag)
    if drakt[5] == "striper":
        for x in np.arange(-w, w * 2, SS * 16):
            d.polygon([(x, 0), (x + SS * 6, 0), (x + SS * 2, h), (x - SS * 4, h)],
                      fill=hexrgb(drakt[4]) + (170,))
    elif drakt[5] == "stjerner":
        for _ in range(4):
            x, y = rng.uniform(0.15, 0.85) * w, rng.uniform(0.2, 0.6) * h
            r = SS * rng.uniform(1.2, 2.2)
            d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 240, 180, 230))
    tom = Image.new("RGBA", bilde.size, (0, 0, 0, 0))
    bilde.alpha_composite(Image.composite(lag, tom, maske))


def ferdig(bilde, ut_w, ut_h):
    return bilde.resize((ut_w * SKALA, ut_h * SKALA), Image.LANCZOS)


# ------------------------------------------------------------- delene

def ledd(drakt, frø=1):
    """Kroppsledd, vises 34x17. Kapsel som overlapper naboene."""
    k = SS * SKALA
    w, h = 34 * k, 17 * k
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((1.5 * k, 1.2 * k, w - 1.5 * k, h - 1.2 * k),
                                        radius=int(7.3 * k), fill=255)
    b = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    b.alpha_composite(kontur(m, drakt[3], int(0.9 * k)))
    b.alpha_composite(fyll(m, drakt, w, h))
    monster(b, m, drakt, w, h, frø)
    ringer(b, m, [12 * k, 22 * k], drakt, h)
    glans(b, m, 6 * k, 3.4 * k, w - 6 * k, 6.2 * k)
    return ferdig(b, 34, 17)


def hale(drakt):
    """Halen, vises 27x17. Kollisjon: x -13..14, spiss mot høyre."""
    k = SS * SKALA
    w, h = 27 * k, 17 * k
    cy = h / 2
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    # bred mot venstre (mot kroppen), smal og rund mot høyre
    pts = []
    for i in range(41):
        t = i / 40
        x = 1.0 * k + t * 24.5 * k
        r = (7.3 - 4.6 * t ** 1.4) * k
        pts.append((x, cy - r))
    for i in range(40, -1, -1):
        t = i / 40
        x = 1.0 * k + t * 24.5 * k
        r = (7.3 - 4.6 * t ** 1.4) * k
        pts.append((x, cy + r))
    d.polygon(pts, fill=255)
    d.ellipse((1.0 * k - 0.1 * k, cy - 7.3 * k, 1.0 * k + 7 * k, cy + 7.3 * k), fill=255)
    d.ellipse((24.5 * k - 2.7 * k, cy - 2.7 * k, 24.5 * k + 2.7 * k, cy + 2.7 * k), fill=255)
    b = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    b.alpha_composite(kontur(m, drakt[3], int(0.9 * k)))
    b.alpha_composite(fyll(m, drakt, w, h))
    monster(b, m, drakt, w, h, 7)
    ringer(b, m, [9 * k, 16 * k], drakt, h)
    glans(b, m, 4 * k, 3.6 * k, 19 * k, 6.0 * k)
    return ferdig(b, 27, 17)


def hode(drakt):
    """Hodet, vises 30x25, ser mot venstre. Kollisjon: y -11..6 fra midten."""
    k = SS * SKALA
    w, h = 30 * k, 25 * k
    cy = h / 2
    topp, bunn = cy - 11.5 * k, cy + 7 * k
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    # rund snute til venstre, går over i kroppen til høyre
    d.ellipse((0.8 * k, topp, 20 * k, bunn), fill=255)
    d.rounded_rectangle((10 * k, topp + 1.2 * k, w - 0.5 * k, bunn - 1.2 * k), radius=int(7 * k), fill=255)
    b = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    b.alpha_composite(kontur(m, drakt[3], int(0.9 * k)))
    b.alpha_composite(fyll(m.crop((0, 0, w, h)), drakt, w, h))
    monster(b, m, drakt, w, h, 3)
    ringer(b, m, [24 * k], drakt, h)
    glans(b, m, 4 * k, topp + 2.2 * k, 17 * k, topp + 5.2 * k)

    f = ImageDraw.Draw(b)
    kant = hexrgb(drakt[3])
    # kinn
    kinn = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(kinn).ellipse((3.5 * k, cy - 0.5 * k, 9.5 * k, cy + 3.5 * k), fill=(255, 90, 120, 90))
    b.alpha_composite(kinn.filter(ImageFilter.GaussianBlur(k * 0.8)))
    # øye
    ex, ey, er = 9.5 * k, cy - 4.5 * k, 4.3 * k
    f.ellipse((ex - er, ey - er, ex + er, ey + er), fill=(255, 255, 255, 255), outline=kant + (255,), width=int(0.7 * k))
    pr = 2.6 * k
    px, py = ex - 1.1 * k, ey + 0.4 * k
    f.ellipse((px - pr, py - pr, px + pr, py + pr), fill=(28, 18, 22, 255))
    f.ellipse((px - 1.5 * k, py - 1.7 * k, px - 0.2 * k, py - 0.4 * k), fill=(255, 255, 255, 255))
    # smil
    f.arc((2.2 * k, cy - 1.0 * k, 8.2 * k, cy + 3.8 * k), 30, 150, fill=kant + (255,), width=int(0.8 * k))
    return ferdig(b, 30, 25)


# ------------------------------------------------------------- hatter

def hatt(navn):
    """Hatter, 30x24 visning (x4). Settes oppå hodet i banene."""
    k = SS * SKALA
    w, h = 30 * k, 24 * k
    b = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(b)
    mork = (40, 24, 18, 255)
    lw = int(0.9 * k)
    if navn == "fest":
        d.polygon([(8 * k, 22 * k), (22 * k, 22 * k), (15 * k, 2.5 * k)], fill=hexrgb("5BB8F0") + (255,), outline=mork, width=lw)
        for i, c in enumerate(["FFE45C", "FF6B6B", "6BD98A"]):
            y = (17 - i * 5) * k
            d.ellipse((14 * k - 1.6 * k + (i - 1) * 2 * k, y - 1.6 * k, 14 * k + 1.6 * k + (i - 1) * 2 * k, y + 1.6 * k), fill=hexrgb(c) + (255,))
        d.ellipse((12.5 * k, 0, 17.5 * k, 5 * k), fill=hexrgb("FF6B6B") + (255,), outline=mork, width=lw)
    elif navn == "krone":
        pts = [(5 * k, 22 * k), (5 * k, 9 * k), (10 * k, 15 * k), (15 * k, 5 * k), (20 * k, 15 * k), (25 * k, 9 * k), (25 * k, 22 * k)]
        d.polygon(pts, fill=hexrgb("FFC53D") + (255,), outline=mork, width=lw)
        d.rectangle((5 * k, 18 * k, 25 * k, 22 * k), fill=hexrgb("E0951A") + (255,), outline=mork, width=lw)
        for x, c in ((10, "FF6B6B"), (15, "5BB8F0"), (20, "6BD98A")):
            d.ellipse(((x - 1.4) * k, 18.6 * k, (x + 1.4) * k, 21.4 * k), fill=hexrgb(c) + (255,))
    elif navn == "caps":
        d.chord((5 * k, 6 * k, 23 * k, 30 * k), 180, 360, fill=hexrgb("FF6B6B") + (255,), outline=mork, width=lw)
        d.rounded_rectangle((0.5 * k, 16.5 * k, 16 * k, 20.5 * k), radius=int(2 * k), fill=hexrgb("D84A4A") + (255,), outline=mork, width=lw)
        d.ellipse((12.5 * k, 4.8 * k, 15.5 * k, 7.8 * k), fill=hexrgb("FFFFFF") + (255,), outline=mork, width=lw)
    elif navn == "flosshatt":
        d.rounded_rectangle((8 * k, 1 * k, 22 * k, 19 * k), radius=int(1.5 * k), fill=hexrgb("2A2A36") + (255,), outline=mork, width=lw)
        d.rectangle((8 * k + lw, 13 * k, 22 * k - lw, 16 * k), fill=hexrgb("C9405A") + (255,))
        d.rounded_rectangle((3 * k, 18 * k, 27 * k, 22 * k), radius=int(2 * k), fill=hexrgb("2A2A36") + (255,), outline=mork, width=lw)
    elif navn == "blomst":
        cx, cy = 15 * k, 12 * k
        for i in range(6):
            a = i * np.pi / 3
            x, y = cx + np.cos(a) * 5 * k, cy + np.sin(a) * 5 * k
            d.ellipse((x - 4 * k, y - 4 * k, x + 4 * k, y + 4 * k), fill=hexrgb("FFFFFF") + (255,), outline=mork, width=lw)
        d.ellipse((cx - 3.5 * k, cy - 3.5 * k, cx + 3.5 * k, cy + 3.5 * k), fill=hexrgb("FFC53D") + (255,), outline=mork, width=lw)
    elif navn == "lue":
        d.chord((4 * k, 5 * k, 26 * k, 33 * k), 180, 360, fill=hexrgb("5BB8F0") + (255,), outline=mork, width=lw)
        d.rounded_rectangle((3 * k, 16 * k, 27 * k, 22 * k), radius=int(3 * k), fill=hexrgb("FFFFFF") + (255,), outline=mork, width=lw)
        d.ellipse((11.5 * k, 0, 18.5 * k, 7 * k), fill=hexrgb("FFFFFF") + (255,), outline=mork, width=lw)
    return b.resize((30 * SKALA, 24 * SKALA), Image.LANCZOS)


HATTER = ["fest", "krone", "caps", "flosshatt", "blomst", "lue"]


def forhandsvisning(sti):
    """Hele marken i alle drakter, til å se over."""
    ark = Image.new("RGBA", (1200, 110 * len(DRAKTER)), (60, 40, 30, 255))
    for j, navn in enumerate(DRAKTER):
        mappe = "mark/" + navn
        y = 110 * j + 30
        x = 60
        hd = Image.open(mappe + "/hode.png").resize((30 * 4, 25 * 4))
        ark.alpha_composite(hd, (x, y - 8))
        hatt_bilde = Image.open("mark/hatt_%s.png" % HATTER[j % len(HATTER)]).resize((30 * 4, 24 * 4))
        ark.alpha_composite(hatt_bilde, (x + 4, y - 8 - 22 * 4 + 14))
        for i in range(7):
            ld = Image.open(mappe + "/del1.png").resize((34 * 4, 17 * 4))
            ark.alpha_composite(ld, (x + 30 * 4 - 6 + i * 27 * 4 - 3 * 4, y))
        hl = Image.open(mappe + "/hale.png").resize((27 * 4, 17 * 4))
        ark.alpha_composite(hl, (x + 30 * 4 - 6 + 7 * 27 * 4 - 3 * 4, y))
    ark.convert("RGB").save(sti)


def main():
    for navn, drakt in DRAKTER.items():
        mappe = os.path.join("mark", navn)
        os.makedirs(mappe, exist_ok=True)
        hale(drakt).save(os.path.join(mappe, "hale.png"), optimize=True)
        ledd(drakt).save(os.path.join(mappe, "del1.png"), optimize=True)
        hode(drakt).save(os.path.join(mappe, "hode.png"), optimize=True)
    for navn in HATTER:
        hatt(navn).save("mark/hatt_%s.png" % navn, optimize=True)
    # standardmarken brukes direkte av banene
    for f in ("hale.png", "del1.png", "hode.png"):
        Image.open("mark/rosa/" + f).save(f, optimize=True)
    import sys
    if len(sys.argv) > 1:
        forhandsvisning(sys.argv[1])


if __name__ == "__main__":
    main()
