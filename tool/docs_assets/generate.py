#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Genera los SVG animados del README (icono vivo + «cómo funciona»).

Uso:  python3 tool/docs_assets/generate.py
Salida: docs/assets/icon.svg, icon-animated.svg, icon.png (si hay rsvg-convert)
        docs/assets/anim/{write,palm,shape,lasso}.{en,es}.svg
Sin dependencias: SVG/SMIL escrito a mano (GitHub lo reproduce dentro de <img>).
"""
import math, random, re, shutil, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/assets"
ANIM = OUT / "anim"
FONT = "system-ui,-apple-system,'Segoe UI',Roboto,sans-serif"
W, H = 640, 360
BG, PAPER, LINE = "#EEF3FF", "#FFFFFF", "#DCE5FB"
BRAND, NAVY, INK, RED, GREEN = "#3B6CF0", "#1F2A5C", "#FF9F43", "#E5484D", "#2FB67C"

TXT = {
    "write": {"en": ("Real pressure", "Width follows how hard you press"),
              "es": ("Presión real", "El grosor sigue la fuerza del lápiz"),
              "gauge": {"en": "pressure", "es": "presión"}},
    "palm": {"en": ("Palm rejection", "Resting your hand never leaves a mark"),
             "es": ("Rechazo de palma", "Apoyar la mano nunca deja marcas"),
             "tag": {"en": "palm ignored", "es": "palma ignorada"}},
    "shape": {"en": ("Shapes", "Hold at the end of the stroke to straighten it"),
              "es": ("Figuras", "Mantén al final del trazo para enderezarlo"),
              "tag": {"en": "hold…", "es": "mantén…"}},
    "lasso": {"en": ("Lasso", "Select and move strokes together"),
              "es": ("Lazo", "Selecciona y mueve trazos a la vez"),
              "tag": {"en": "selection", "es": "selección"}},
}


def f(v):
    return f"{v:.1f}".rstrip("0").rstrip(".")


def anim(attr, values, kt, dur, **kw):
    extra = "".join(f' {k.replace("_", "")}="{v}"' for k, v in kw.items())
    return (f'<animate attributeName="{attr}" values="{";".join(values)}" '
            f'keyTimes="{";".join(f(k) if k not in (0, 1) else str(int(k)) for k in kt)}" '
            f'dur="{dur}s" repeatCount="indefinite"{extra}/>')


def nib(scale=0.11, l="#7FA2FF", r="#3B6CF0", collar="#2A4FD6", band="#1F3FA8", eye="#FFFFFF"):
    """Plumilla del icono con la PUNTA en el origen (para animateMotion)."""
    d = 330 * math.sqrt(0.5) * scale  # punta tras rotate(45)
    return (f'<g transform="translate({f(d)} {f(-d)}) scale({scale}) rotate(45)">'
            f'<path d="M0,-190 L-150,-190 L-150,-110 C-150,-20 -70,110 0,330 Z" fill="{l}"/>'
            f'<path d="M0,-190 L150,-190 L150,-110 C150,-20 70,110 0,330 Z" fill="{r}"/>'
            f'<rect x="-172" y="-300" width="344" height="120" rx="36" fill="{collar}"/>'
            f'<rect x="-172" y="-212" width="344" height="32" rx="12" fill="{band}"/>'
            f'<circle cx="0" cy="-30" r="34" fill="{eye}"/>'
            f'<path d="M0,-30 L0,320" stroke="{eye}" stroke-width="16" stroke-linecap="round"/></g>')


def frame(key, lang, body, tag_label=""):
    title, sub = TXT[key][lang]
    rules = "".join(f'<path d="M24 {y}H{W-24}" stroke="{LINE}" stroke-width="1.5"/>' for y in range(96, 300, 34))
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
            f'role="img" aria-label="{title}: {sub}">'
            f'<rect width="{W}" height="{H}" rx="22" fill="{BG}"/>'
            f'<rect x="12" y="12" width="{W-24}" height="{H-24}" rx="14" fill="{PAPER}"/>{rules}'
            f'<text x="30" y="46" font-family="{FONT}" font-size="22" font-weight="700" fill="{NAVY}">{title}</text>'
            f'<text x="30" y="68" font-family="{FONT}" font-size="14" fill="#5B6798">{sub}</text>'
            f'{body}</svg>')


def poly_len(pts):
    return sum(math.dist(a, b) for a, b in zip(pts, pts[1:]))


def pen_run(pts, dur, kt_end, stroke, width, label_fade=True):
    """Trazo uniforme que se dibuja con la plumilla delante. Devuelve (svg, longitud)."""
    n = len(pts)
    ln = poly_len(pts)
    d = "M" + " L".join(f"{f(x)},{f(y)}" for x, y in pts)
    # fracciones acumuladas por longitud → dash y movimiento perfectamente sincronizados
    acc = [0.0]
    for a, b in zip(pts, pts[1:]):
        acc.append(acc[-1] + math.dist(a, b))
    kts = [a / ln * kt_end for a in acc] + [1]
    motion = ";".join(f"{f(x)},{f(y)}" for x, y in pts) + ";" + f"{f(pts[-1][0])},{f(pts[-1][1])}"
    ktxt = ";".join(f"{k:.4f}" for k in kts)
    ink = (f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" '
           f'stroke-linejoin="round" stroke-dasharray="{f(ln)}" stroke-dashoffset="{f(ln)}">'
           f'<animate attributeName="stroke-dashoffset" values="{f(ln)};0;0" keyTimes="0;{kt_end};1" dur="{dur}s" repeatCount="indefinite"/></path>')
    pen = (f'<g><animateMotion dur="{dur}s" repeatCount="indefinite" calcMode="linear" '
           f'values="{motion}" keyTimes="{ktxt}"/>{nib()}</g>')
    return ink, pen, ln


# ───────────────────────── escenas ─────────────────────────
def scene_write(lang):
    N = 120
    xs = [56 + (W - 112) * i / (N - 1) for i in range(N)]
    t = [i / (N - 1) for i in range(N)]
    ys = [222 + 52 * math.sin(2 * math.pi * 2.3 * u) * (0.55 + 0.45 * math.sin(math.pi * u)) for u in t]
    p = [0.12 + 0.88 * abs(math.sin(2 * math.pi * 1.15 * u + 0.5)) ** 1.2 for u in t]
    wd = [2.5 + 15 * q for q in p]
    L, R = [], []
    for i in range(N):
        a, b = max(i - 1, 0), min(i + 1, N - 1)
        dx, dy = xs[b] - xs[a], ys[b] - ys[a]
        m = math.hypot(dx, dy) or 1
        nx, ny = -dy / m, dx / m
        L.append((xs[i] + nx * wd[i] / 2, ys[i] + ny * wd[i] / 2))
        R.append((xs[i] - nx * wd[i] / 2, ys[i] - ny * wd[i] / 2))
    poly = " ".join(f"{f(x)},{f(y)}" for x, y in L + R[::-1])
    dur, end = 5, 0.72
    kts = [u * end for u in t] + [1]
    motion = ";".join(f"{f(x)},{f(y)}" for x, y in zip(xs, ys)) + f";{f(xs[-1])},{f(ys[-1])}"
    ktxt = ";".join(f"{k:.4f}" for k in kts)
    gk = [i / 29 * end for i in range(30)] + [1]
    gv = [f(20 + 150 * p[round(i / 29 * (N - 1))]) for i in range(30)] + [f(20 + 150 * p[-1])]
    fade = anim("opacity", ["1", "1", "0", "0"], [0, 0.88, 0.97, 1], dur)
    body = (f'<clipPath id="r"><rect x="0" y="80" width="0" height="260">'
            f'<animate attributeName="width" values="0;{W};{W}" keyTimes="0;{end};1" dur="{dur}s" repeatCount="indefinite"/></rect></clipPath>'
            f'<g>{fade}<polygon points="{poly}" fill="{NAVY}" clip-path="url(#r)"/>'
            f'<g><animateMotion dur="{dur}s" repeatCount="indefinite" calcMode="linear" values="{motion}" keyTimes="{ktxt}"/>{nib()}</g></g>'
            f'<text x="440" y="344" font-family="{FONT}" font-size="12" fill="#5B6798" text-anchor="end">{TXT["write"]["gauge"][lang]}</text>'
            f'<rect x="450" y="334" width="170" height="10" rx="5" fill="{LINE}"/>'
            f'<rect x="450" y="334" height="10" rx="5" fill="{INK}" width="40">{anim("width", gv, gk, dur)}</rect>')
    return frame("write", lang, body)


def scene_palm(lang):
    pts = [(60 + i * 12, 170 + 14 * math.sin(i * 0.55)) for i in range(0, 46)]
    ink, pen, _ = pen_run(pts, 6, 0.8, NAVY, 5)
    dur = 6
    palm = (f'<g opacity="0">{anim("opacity", ["0", "0", "1", "1", "0", "0"], [0, 0.22, 0.3, 0.7, 0.78, 1], dur)}'
            f'<ellipse cx="300" cy="268" rx="70" ry="46" fill="#8C9BC8" opacity=".35"/>'
            f'<circle cx="300" cy="268" r="22" fill="none" stroke="{RED}" stroke-width="3">'
            f'<animate attributeName="r" values="14;50" dur="1.1s" repeatCount="indefinite"/>'
            f'<animate attributeName="opacity" values="1;0" dur="1.1s" repeatCount="indefinite"/></circle>'
            f'<g transform="translate(300 268)"><circle r="17" fill="{RED}"/>'
            f'<path d="M-6 -6L6 6M6 -6L-6 6" stroke="#fff" stroke-width="3.5" stroke-linecap="round"/></g>'
            f'<text x="300" y="332" font-family="{FONT}" font-size="14" font-weight="600" fill="{RED}" text-anchor="middle">{TXT["palm"]["tag"][lang]}</text></g>')
    fade = anim("opacity", ["1", "1", "0", "0"], [0, 0.9, 0.98, 1], dur)
    return frame("palm", lang, f'<g>{fade}{ink}{pen}</g>{palm}')


def scene_shape(lang):
    random.seed(7)
    x0, y0, x1, y1 = 190, 150, 450, 300
    corners = [(x0, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0)]
    pts = []
    for a, b in zip(corners, corners[1:]):
        for k in range(14):
            u = k / 14
            pts.append((a[0] + (b[0] - a[0]) * u + random.uniform(-5, 5), a[1] + (b[1] - a[1]) * u + random.uniform(-5, 5)))
    pts.append((x0 + 4, y0 - 3))
    dur, end = 6, 0.42
    ink, pen, _ = pen_run(pts, dur, end, NAVY, 5)
    ex, ey = pts[-1]
    show = lambda vals: anim("opacity", vals, [0, end, 0.56, 0.62, 0.9, 0.97, 1], dur)
    wobbly = f'<g>{show(["1", "1", "1", "0", "0", "0", "0"])}{ink}</g>'
    pen_g = f'<g>{show(["1", "1", "1", "1", "0", "0", "0"])}{pen}</g>'
    ring = (f'<circle cx="{f(ex)}" cy="{f(ey)}" r="16" fill="none" stroke="{BRAND}" stroke-width="4" stroke-linecap="round" '
            f'stroke-dasharray="101" stroke-dashoffset="101" opacity="0">'
            f'{anim("stroke-dashoffset", ["101", "101", "0", "0"], [0, end, 0.56, 1], dur)}'
            f'{anim("opacity", ["0", "1", "1", "0", "0"], [0, end, 0.56, 0.6, 1], dur)}</circle>')
    label = (f'<text x="{f(ex + 14)}" y="{f(ey + 34)}" font-family="{FONT}" font-size="14" font-weight="600" fill="{BRAND}" opacity="0">'
             f'{anim("opacity", ["0", "1", "1", "0", "0"], [0, end, 0.56, 0.6, 1], dur)}{TXT["shape"]["tag"][lang]}</text>')
    clean = (f'<rect x="{x0}" y="{y0}" width="{x1-x0}" height="{y1-y0}" rx="3" fill="none" stroke="{BRAND}" stroke-width="5" opacity="0">'
             f'{anim("opacity", ["0", "0", "1", "1", "0", "0"], [0, 0.58, 0.64, 0.9, 0.97, 1], dur)}</rect>')
    return frame("shape", lang, wobbly + pen_g + ring + label + clean)


def scene_lasso(lang):
    dur = 7
    strokes = (f'<g fill="none" stroke="{NAVY}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round">'
               f'<circle cx="190" cy="190" r="34"/><path d="M270 220l24-52 24 52 24-52 24 52"/></g>')
    other = (f'<path d="M470 250l36-64 36 64z" fill="none" stroke="{NAVY}" stroke-width="5" stroke-linejoin="round"/>')
    moved = (f'<g>{anim("opacity", ["1", "1"], [0, 1], dur)}'
             f'<animateTransform attributeName="transform" type="translate" additive="replace" '
             f'values="0 0;0 0;0 0;70 -34;70 -34;0 0;0 0" keyTimes="0;0.4;0.5;0.66;0.8;0.9;1" dur="{dur}s" repeatCount="indefinite"/>{strokes}</g>')
    loop_d = "M150 140C230 100 380 120 390 200C396 262 230 266 160 242C118 226 112 160 150 140Z"
    lasso = (f'<path d="{loop_d}" fill="none" stroke="{BRAND}" stroke-width="3" stroke-linecap="round" stroke-dasharray="6 7" opacity="0">'
             f'<animate attributeName="stroke-dashoffset" values="0;-26" dur="0.6s" repeatCount="indefinite"/>'
             f'{anim("opacity", ["0", "1", "1", "0", "0"], [0, 0.04, 0.3, 0.36, 1], dur)}</path>')
    box = (f'<g opacity="0">{anim("opacity", ["0", "0", "1", "1", "0", "0"], [0, 0.34, 0.4, 0.8, 0.9, 1], dur)}'
           f'<animateTransform attributeName="transform" type="translate" values="0 0;0 0;0 0;70 -34;70 -34;0 0;0 0" keyTimes="0;0.4;0.5;0.66;0.8;0.9;1" dur="{dur}s" repeatCount="indefinite"/>'
           f'<rect x="146" y="140" width="204" height="102" rx="6" fill="{BRAND}" fill-opacity=".08" stroke="{BRAND}" stroke-width="2" stroke-dasharray="6 5"/>'
           + "".join(f'<circle cx="{x}" cy="{y}" r="7" fill="#fff" stroke="{BRAND}" stroke-width="2.5"/>' for x, y in
                     [(146, 140), (350, 140), (146, 242), (350, 242)])
           + f'<text x="248" y="262" font-family="{FONT}" font-size="14" font-weight="600" fill="{BRAND}" text-anchor="middle" dy="14">{TXT["lasso"]["tag"][lang]}</text></g>')
    return frame("lasso", lang, other + moved + lasso + box)


# ───────────────────────── icono ─────────────────────────
def icon_files():
    src = (ROOT / "assets/icon/icon_full.svg").read_text()
    shutil.copy(ROOT / "assets/icon/icon_full.svg", OUT / "icon.svg")
    m = re.search(r'<path d="(M318,706[^"]+)"\s+fill="none" stroke="url\(#ink\)" stroke-width="44"[^>]*/>', src)
    nums = re.findall(r"-?\d+(?:\.\d+)?", m.group(1))
    abs_d = m.group(1)
    rel = [float(v) - (318 if i % 2 == 0 else 706) for i, v in enumerate(nums)]
    rel_d = "M{},{} C{},{} {},{} {},{} C{},{} {},{} {},{} C{},{} {},{} {},{} C{},{} {},{} {},{}".format(*[f(v) for v in rel])
    dur = 5
    kt = "0;0.5;0.72;0.9;1"
    ink = (f'<path d="{abs_d}" pathLength="1" fill="none" stroke="url(#ink)" stroke-width="44" stroke-linecap="round" '
           f'stroke-linejoin="round" stroke-dasharray="1 1.01" stroke-dashoffset="1.01">'
           f'<animate attributeName="stroke-dashoffset" values="1.01;0;0;1.01;1.01" keyTimes="{kt}" dur="{dur}s" repeatCount="indefinite" calcMode="spline" keySplines=".4 0 .6 1;0 0 1 1;.5 0 .5 1;0 0 1 1"/></path>')
    anim_nib = (f'<animateMotion path="{rel_d}" keyPoints="0;1;1;0;0" keyTimes="{kt}" dur="{dur}s" repeatCount="indefinite" '
                f'calcMode="spline" keySplines=".4 0 .6 1;0 0 1 1;.5 0 .5 1;0 0 1 1"/>')
    out = src.replace(m.group(0), ink)
    out = out.replace('<g transform="translate(560 470) rotate(45)" filter="url(#shadow)">',
                      f'<g>{anim_nib}<g transform="translate(560 470) rotate(45)" filter="url(#shadow)">')
    # cierra el <g> añadido justo tras la plumilla (último </g> antes del cierre del grupo escalado)
    idx = out.rindex("</g>\n    </g>\n  </g>")
    out = out[:idx] + "</g></g>\n    </g>\n  </g>" + out[idx + len("</g>\n    </g>\n  </g>"):]
    (OUT / "icon-animated.svg").write_text(out)
    if shutil.which("rsvg-convert"):
        subprocess.run(["rsvg-convert", "-w", "512", str(OUT / "icon.svg"), "-o", str(OUT / "icon.png")], check=True)


def main():
    ANIM.mkdir(parents=True, exist_ok=True)
    icon_files()
    for name, fn in (("write", scene_write), ("palm", scene_palm), ("shape", scene_shape), ("lasso", scene_lasso)):
        for lang in ("en", "es"):
            (ANIM / f"{name}.{lang}.svg").write_text(fn(lang))
    print("OK:", *sorted(p.name for p in OUT.rglob("*") if p.is_file()))


if __name__ == "__main__":
    main()
