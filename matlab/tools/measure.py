#!/usr/bin/env python3
"""measure.py - MEASURE a render instead of eyeballing it.

REF-13 measured Aditya's 43 photographs in pixels. This measures OURS the same
way, so a colour claim about a render is a number and not an impression.

  python3 measure.py IMG.png                       -> the standard band report
  python3 measure.py IMG.png x0 y0 x1 y1 [label]   -> one rectangle, fractions 0-1

Reports for each patch: mean RGB, HSV saturation %, brightness (0-255) and
LOCAL CONTRAST (std of luminance), because REF-13 s5 measures haze collapsing
contrast 43 -> 21 as well as saturation 53 -> 19.
"""
import sys, colorsys
import numpy as np
from PIL import Image

TARGETS = {
    "sky zenith":   ("REF-13 s1 plains zenith",  (146.4, 171.5, 191.4), 24.2),
    "sky horizon":  ("REF-13 s1 plains horizon", (137.5, 160.2, 172.6), 20.9),
    "vegetation":   ("REF-13 s7 plains green",   (92.3, 116.1, 95.0),   31.0),
}

def stats(a):
    """a: HxWx3 uint8 patch.

    TWO SATURATIONS, and they are different statistics - which matters, because
    REF-13 s7 lists plains green as "92.3 / 116.1 / 95.0, sat 31.0 %" and the
    saturation of THAT TRIPLE is 20.5 %, not 31 %. Averaging RGB over a region
    washes saturation out; averaging each pixel's own saturation does not. So the
    31 % has to be the per-pixel mean, and comparing a render's mean-colour
    saturation against it compares two different things. Both are reported.
    """
    f = a.reshape(-1, 3).astype(float)
    r, g, b = f.mean(0)
    mx, mn = max(r, g, b), min(r, g, b)
    sat = 0.0 if mx == 0 else (mx - mn) / mx * 100          # sat OF THE MEAN COLOUR
    pmx, pmn = f.max(1), f.min(1)
    psat = np.where(pmx > 0, (pmx - pmn) / np.maximum(pmx, 1e-9), 0).mean() * 100
    hue = colorsys.rgb_to_hsv(r/255, g/255, b/255)[0] * 360
    lum = f @ np.array([0.299, 0.587, 0.114])
    return dict(rgb=(r, g, b), sat=sat, psat=psat, hue=hue,
                bright=lum.mean(), contrast=lum.std())

def report(name, s, note=""):
    r, g, b = s["rgb"]
    print(f"  {name:<26s} RGB {r:6.1f}/{g:6.1f}/{b:6.1f}  sat(mean) {s['sat']:5.1f}%  "
          f"sat(pixel) {s['psat']:5.1f}%  hue {s['hue']:5.1f}d  bright {s['bright']:6.1f}  "
          f"contrast {s['contrast']:5.1f}{note}")

def patch(im, x0, y0, x1, y1):
    H, W = im.shape[:2]
    return im[int(y0*H):int(y1*H), int(x0*W):int(x1*W), :3]

def main():
    path = sys.argv[1]
    im = np.asarray(Image.open(path).convert("RGB"))
    H, W = im.shape[:2]
    print(f"\n{path}  {W}x{H}")
    if len(sys.argv) >= 6:
        x0, y0, x1, y1 = (float(v) for v in sys.argv[2:6])
        label = sys.argv[6] if len(sys.argv) > 6 else "patch"
        report(label, stats(patch(im, x0, y0, x1, y1)))
        return
    # standard bands, top to bottom
    bands = [
        ("sky top",        0.30, 0.01, 0.70, 0.06),
        ("sky mid",        0.30, 0.10, 0.70, 0.18),
        ("sky low",        0.35, 0.28, 0.65, 0.36),
        ("canopy left",    0.02, 0.10, 0.25, 0.35),
        ("canopy right",   0.75, 0.10, 0.98, 0.35),
        ("treeline base L",0.02, 0.44, 0.28, 0.52),
        ("road far",       0.45, 0.51, 0.55, 0.55),
        ("road near",      0.35, 0.88, 0.65, 0.98),
        ("shoulder left",  0.05, 0.72, 0.22, 0.80),
        ("verge left",     0.02, 0.62, 0.20, 0.70),
    ]
    for name, *box in bands:
        report(name, stats(patch(im, *box)))
    print("\n  REF-13 targets:")
    for k, (src, rgb, sat) in TARGETS.items():
        print(f"    {k:<14s} {src:<28s} RGB {rgb[0]:5.1f}/{rgb[1]:5.1f}/{rgb[2]:5.1f}  sat {sat:.1f}%")
    print()

main()
