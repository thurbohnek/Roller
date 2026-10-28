#!/usr/bin/env python3
"""
Maler banene (levelN/1-4.png) på nytt i den nye stilen (2026-10-28).

Kjør fra roten av repoet:
    python3 Util/grafikk/lag_baner.py            # alle baner
    python3 Util/grafikk/lag_baner.py 3 7        # bare bane 3 og 7

FORMEN ENDRES IKKE. Hvor det er bakke, hentes fra masken i
Util/grafikk/masker/levelN_K.png (0 = luft, 1 = bakke, 2 = is). Masken
lages første gang (eller med --ny-maske) fra flisbildet og
kollisjonsformene i lib/shapedefs*.lua: bare det som både er tegnet og har
kollisjon regnes som bakke (pynt uten kollisjon, som himmelblokka i bane
1, tas bort), og is er der kollisjonen har friksjon under 1 (is = 0,05).
Grafikken og fysikken stemmer derfor overens, og banene spilles som før.

Lages bane 5-9 på nytt med Util/baner/hule.py, må masken lages på nytt:
    python3 Util/baner/hule.py 7
    python3 Util/grafikk/lag_baner.py 7 --ny-maske

STIL
Bane 1-2 ligger på enga: gress på toppen og lys, varm jord. Bane 3-9 er
under jorda: en varm lyskant på toppen av rulleflata og jord som går over
i kaldere, mørkere stein jo dypere banen er. Is er lys blå med glans.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as nd

W, H = 3840, 2351
MASKER = "Util/grafikk/masker"

SHAPEDEFS = {1: "lib/shapedefs.lua"}
for _n in range(2, 10):
    SHAPEDEFS[_n] = "lib/shapedefs%d.lua" % _n


def hexf(h):
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], float)


# ------------------------------------------------------------- masker

def kollisjon(bane):
    """Kollisjonspolygonene for flis 1-4: {k: [(punkter, friksjon), ...]}."""
    from lupa import LuaRuntime
    lua = LuaRuntime()
    kilde = open(SHAPEDEFS[bane], encoding="utf-8").read()
    data = lua.execute(kilde)
    fys = data.physicsData(1.0)
    ut = {}
    for k in range(1, 5):
        liste = []
        body = fys.data[str(k)]
        if body is None:
            continue
        for fi in body.values():
            sh = fi["shape"]
            if sh is None:
                continue
            v = list(sh.values())
            pts = [(v[i] / 2 + 1920, v[i + 1] / 2 + 1175.5) for i in range(0, len(v), 2)]
            liste.append((pts, float(fi["friction"] or 0.3)))
        ut[k] = liste
    return ut


def lag_maske(bane, k, polygoner):
    bilde = Image.open("level%d/%d.png" % (bane, k)).convert("RGBA")
    if bilde.size != (W, H):        # bane 1 var lagret i dobbel størrelse
        bilde = bilde.resize((W, H), Image.LANCZOS)
    bilde = np.asarray(bilde)
    tegnet = bilde[..., 3] > 127
    koll = Image.new("L", (W, H), 0)
    isen = Image.new("L", (W, H), 0)
    dk, di = ImageDraw.Draw(koll), ImageDraw.Draw(isen)
    for pts, fr in polygoner:
        dk.polygon(pts, fill=255)
        if fr < 1:
            di.polygon(pts, fill=255)
    koll = np.asarray(koll) > 0
    isen = np.asarray(isen) > 0
    naer = nd.binary_dilation(koll, iterations=12)
    # kollisjonen er alltid bakke (tetter tynne sømmer i tegningen)
    fast = (tegnet & naer) | koll
    # sømmer smalere enn marken (ca. 8 px) lukkes; dit kommer den uansett ikke
    fast |= nd.binary_closing(fast, structure=np.ones((3, 3)), iterations=4)
    lukket = nd.binary_fill_holes(fast)
    lab, n = nd.label(lukket & ~fast)
    if n:
        st = nd.sum(lukket & ~fast, lab, range(1, n + 1))
        fast |= np.isin(lab, 1 + np.nonzero(st < 3000)[0])
    # små løse biter (pynt, støv) tas bort
    lab, n = nd.label(fast)
    if n:
        st = nd.sum(fast, lab, range(1, n + 1))
        fast &= np.isin(lab, 1 + np.nonzero(st >= 400)[0])
    m = np.zeros((H, W), np.uint8)
    m[fast] = 1
    m[fast & nd.binary_dilation(isen, iterations=6)] = 2
    return m


def hent_maske(bane, k, ny=False, poly=None):
    sti = os.path.join(MASKER, "level%d_%d.png" % (bane, k))
    if os.path.exists(sti) and not ny:
        return np.asarray(Image.open(sti))
    if poly is None:
        poly = kollisjon(bane)
    m = lag_maske(bane, k, poly.get(k, []))
    os.makedirs(MASKER, exist_ok=True)
    Image.fromarray(m, "L").save(sti, optimize=True)
    return m


# ------------------------------------------------------------- stil

def tema(bane):
    """Farger per bane. t = 0 (bane 3) .. 1 (bane 9) for undergrunnen."""
    if bane <= 2:
        return dict(overflate=True,
                    kant=hexf("3A1E0C"),
                    topp=hexf("A86A3C"), dyp=hexf("6A3E1E"),
                    stein_lys=hexf("C08A5A"), stein_mork=hexf("5A3418"))
    t = (bane - 3) / 6.0

    def blend(a, b):
        return hexf(a) * (1 - t) + hexf(b) * t
    return dict(overflate=False,
                kant=blend("2A1206", "141210"),
                lys=blend("F0B070", "B8C4CC"),      # lyskant på toppen
                topp=blend("8E5630", "5A5650"),
                dyp=blend("4A2610", "24211F"),
                stein_lys=blend("A87048", "7A7672"),
                stein_mork=blend("3A1C0A", "1C1A18"))


def lerp(a, b, t):
    return a[None, None, :] * (1 - t[..., None]) + b[None, None, :] * t[..., None]


def avstand_fra_toppen(fast):
    """Vertikal avstand ned fra nærmeste luft over, per piksel."""
    rader = np.arange(H)[:, None] * np.ones((1, W), int)
    luft_rad = np.where(~fast, rader, -10 ** 6)
    siste = np.maximum.accumulate(luft_rad, axis=0)
    return rader - siste


def tegn(bane, k, m, fro):
    rng = np.random.default_rng(fro)
    T = tema(bane)
    fast = m > 0
    is_ = m == 2
    inn = nd.distance_transform_edt(fast)
    ned = avstand_fra_toppen(fast).astype(float)

    # grunnfarge: lys nær toppen av massen, mørk dypt inne
    t = np.clip(np.minimum(ned / 600.0, 1) * 0.75 + np.clip(inn / 400.0, 0, 1) * 0.25, 0, 1)
    # jevnes ut så kanter under overheng ikke gir loddrette striper
    vekt = nd.gaussian_filter(fast.astype(float), 40) + 1e-6
    t = nd.gaussian_filter(t * fast, 40) / vekt
    rgb = lerp(T["topp"], T["dyp"], t)
    # litt mørkere langs sider og underkant (ikke på toppen)
    rgb *= (1 - 0.18 * np.clip(1 - inn / 40.0, 0, 1) * (ned > 60))[..., None]

    # myk, stor variasjon (flekker i jorda)
    st = rng.normal(0, 1, (H // 32 + 2, W // 32 + 2))
    st = nd.zoom(nd.gaussian_filter(st, 2.2), 32, order=1)[:H, :W]
    rgb *= (1 + 0.06 * st)[..., None]

    # steiner
    lag = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lag)
    ys, xs = np.nonzero(inn > 40)
    if len(xs):
        for _ in range(int(len(xs) / 16000)):
            i = rng.integers(0, len(xs))
            cx, cy = xs[i], ys[i]
            rx, ry = rng.uniform(10, 34), rng.uniform(7, 22)
            lys = rng.random() < 0.5
            f = T["stein_lys"] if lys else T["stein_mork"]
            d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=tuple(int(v) for v in f) + (110,))
            if lys:
                d.arc((cx - rx + 3, cy - ry + 2, cx + rx - 3, cy + ry - 2), 200, 300,
                      fill=(255, 255, 255, 60), width=3)
    sa = np.asarray(lag).astype(float)
    a = sa[..., 3:4] / 255 * (inn[..., None] > 30)
    rgb = rgb * (1 - a) + sa[..., :3] * a

    # toppen av rulleflata
    if T["overflate"]:
        gress1, gress2, gress3 = hexf("8EDB72"), hexf("5BC46A"), hexf("3C9A4B")
        g = (ned < 22) & (inn < 40)
        rgb[g] = gress2
        rgb[(ned < 7) & g] = gress1
        rgb[(ned >= 16) & g] = gress3
        # mørk skygge rett under gresset
        s = (ned >= 22) & (ned < 34) & (inn < 50)
        rgb[s] *= 0.82
    else:
        lysband = (ned < 9) & (inn < 30)
        rgb[lysband] = T["lys"]
        ov = (ned >= 9) & (ned < 26) & (inn < 40)
        f = np.clip((ned - 9) / 17, 0, 1)
        rgb[ov] = rgb[ov] * f[ov][:, None] + T["lys"] * 0.75 * (1 - f[ov][:, None])

    # is: lys, blank stripe langs kanten, og glanslinjer
    if is_.any():
        isk = is_ & (inn < 28)
        f = np.clip(inn / 28, 0, 1)
        isf = lerp(hexf("E8FBFF"), hexf("4FA8CF"), f)
        rgb[isk] = isf[isk]
        glans = isk & (inn > 5) & (inn < 8)
        rgb[glans] = hexf("FFFFFF")

    # kontur
    kant = (inn < 3.2) & fast
    rgb[kant & ~is_] = T["kant"]
    rgb[kant & is_] = hexf("2E7FB8")

    # myk kant mot luft
    alfa = nd.gaussian_filter(fast.astype(float), 0.9)
    alfa = np.clip((alfa - 0.25) / 0.5, 0, 1)
    ut = np.zeros((H, W, 4), np.uint8)
    ut[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    ut[..., 3] = (alfa * 255).astype(np.uint8)
    im = Image.fromarray(ut, "RGBA")

    # gresstrå over kanten på enga (bare pynt, utenfor kollisjonen)
    if T["overflate"]:
        dd = ImageDraw.Draw(im)
        topp = fast & ~np.vstack([np.zeros((1, W), bool), fast[:-1]])
        ty, tx = np.nonzero(topp & ~is_)
        for i in rng.choice(len(tx), size=min(len(tx), len(tx) // 7), replace=False) if len(tx) else []:
            x, y = tx[i], ty[i]
            h = rng.uniform(8, 20)
            b = rng.uniform(-5, 5)
            farge = (91, 196, 106, 255) if rng.random() < 0.6 else (60, 154, 75, 255)
            dd.line([(x, y + 2), (x + b, y - h)], fill=farge, width=3)
    return im


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    ny = "--ny-maske" in sys.argv
    baner = [int(a) for a in args] or list(range(1, 10))
    for n in baner:
        poly = None
        if ny or not all(os.path.exists(os.path.join(MASKER, "level%d_%d.png" % (n, k))) for k in range(1, 5)):
            poly = kollisjon(n)
        for k in range(1, 5):
            m = hent_maske(n, k, ny, poly)
            im = tegn(n, k, m, 1000 * n + k)
            im.save("level%d/%d.png" % (n, k), optimize=True)
            print("level%d/%d.png" % (n, k), "bakke %.1f %%" % (100 * (m > 0).mean()),
                  "is %d px" % (m == 2).sum())


if __name__ == "__main__":
    main()
