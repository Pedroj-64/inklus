#!/usr/bin/env python3
# SPDX-License-Identifier: CC0-1.0
"""Genera los paquetes oficiales de Inklus (stickers + plantillas con imagen).

    python3 tool/generate_packs.py      # desde marketplace/

Requiere pycairo (`pip install pycairo`). Dibujos 100 % originales, vectoriales,
exportados a PNG. Es determinista: volver a ejecutarlo da los mismos archivos
(salvo cambios de la versión de cairo/fuentes).
"""
import math
import os

import cairo

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'packs')

# Estilo común de los stickers: contorno oscuro grueso, rellenos planos.
S = 512           # lado del sticker en px
LW = 18           # grosor del contorno
INK = (0.12, 0.16, 0.22)
WHITE = (1, 1, 1)


def hexc(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


C = {k: hexc(v) for k, v in {
    'red': '#EF4444', 'orange': '#F97316', 'yellow': '#FACC15', 'green': '#22C55E',
    'teal': '#14B8A6', 'blue': '#3B82F6', 'sky': '#7DD3FC', 'indigo': '#6366F1',
    'purple': '#A855F7', 'pink': '#F472B6', 'brown': '#A16207', 'gray': '#CBD5E1',
    'paper': '#F8FAFC', 'cream': '#FEF3C7', 'dark': '#334155', 'skin': '#FDE68A',
}.items()}


# ---------------------------------------------------------------- utilidades

def new(w=S, h=S):
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    ctx = cairo.Context(surf)
    ctx.set_line_join(cairo.LINE_JOIN_ROUND)
    ctx.set_line_cap(cairo.LINE_CAP_ROUND)
    return surf, ctx


def fs(ctx, fill, lw=LW):
    """Rellena (si hay color) y contornea el camino actual."""
    if fill is not None:
        ctx.set_source_rgb(*fill)
        ctx.fill_preserve()
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(lw)
    ctx.stroke()


def rrect(ctx, x, y, w, h, r):
    ctx.new_sub_path()
    ctx.arc(x + w - r, y + r, r, -math.pi / 2, 0)
    ctx.arc(x + w - r, y + h - r, r, 0, math.pi / 2)
    ctx.arc(x + r, y + h - r, r, math.pi / 2, math.pi)
    ctx.arc(x + r, y + r, r, math.pi, 3 * math.pi / 2)
    ctx.close_path()


def circle(ctx, x, y, r):
    ctx.new_sub_path()
    ctx.arc(x, y, r, 0, 2 * math.pi)


def poly(ctx, pts, close=True):
    ctx.move_to(*pts[0])
    for p in pts[1:]:
        ctx.line_to(*p)
    if close:
        ctx.close_path()


def line(ctx, x1, y1, x2, y2, lw=LW, color=INK):
    ctx.move_to(x1, y1)
    ctx.line_to(x2, y2)
    ctx.set_source_rgb(*color)
    ctx.set_line_width(lw)
    ctx.stroke()


def star_pts(cx, cy, ro, ri, n=5, rot=-math.pi / 2):
    return [(cx + (ro if i % 2 == 0 else ri) * math.cos(rot + i * math.pi / n),
             cy + (ro if i % 2 == 0 else ri) * math.sin(rot + i * math.pi / n))
            for i in range(2 * n)]


def glyph(ctx, text, cx, cy, size, color=INK, bold=True, font='Noto Sans'):
    ctx.select_font_face(font, cairo.FONT_SLANT_NORMAL,
                         cairo.FONT_WEIGHT_BOLD if bold else cairo.FONT_WEIGHT_NORMAL)
    ctx.set_font_size(size)
    xb, yb, w, h, _, _ = ctx.text_extents(text)
    ctx.move_to(cx - w / 2 - xb, cy - h / 2 - yb)
    ctx.set_source_rgb(*color)
    ctx.show_text(text)


def text(ctx, s, x, y, size, color=INK, bold=False, align='left', font='Noto Sans'):
    ctx.select_font_face(font, cairo.FONT_SLANT_NORMAL,
                         cairo.FONT_WEIGHT_BOLD if bold else cairo.FONT_WEIGHT_NORMAL)
    ctx.set_font_size(size)
    xb, _, w, _, _, _ = ctx.text_extents(s)
    if align == 'center':
        x -= w / 2 + xb
    elif align == 'right':
        x -= w + xb
    ctx.move_to(x, y)
    ctx.set_source_rgb(*color)
    ctx.show_text(s)


def tile(ctx, fill):
    """Fondo de baldosa redondeada (stickers de símbolos)."""
    rrect(ctx, 56, 56, 400, 400, 96)
    fs(ctx, fill)


def face(ctx, fill):
    circle(ctx, 256, 256, 190)
    fs(ctx, fill)


def eyes(ctx, y=220, dx=70, r=20):
    for x in (256 - dx, 256 + dx):
        circle(ctx, x, y, r)
        ctx.set_source_rgb(*INK)
        ctx.fill()


def cloud(ctx, cx, cy, s, fill=WHITE):
    ctx.new_path()
    for x, y, r in ((-70, 10, 62), (0, -30, 85), (80, 5, 68)):
        circle(ctx, cx + x * s, cy + y * s, r * s)
    rrect(ctx, cx - 132 * s, cy + 0 * s, 280 * s, 72 * s, 36 * s)
    # contorno de la unión: rellenar con contorno y luego relleno encima
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(LW * 2)
    ctx.stroke_preserve()
    ctx.set_source_rgb(*fill)
    ctx.fill()


# ---------------------------------------------------------------- estudio

def st_book(ctx):
    poly(ctx, [(96, 140), (256, 170), (256, 410), (96, 380)])
    fs(ctx, C['blue'])
    poly(ctx, [(416, 140), (256, 170), (256, 410), (416, 380)])
    fs(ctx, C['sky'])
    for i in range(3):
        y = 220 + i * 50
        line(ctx, 296, y - 4, 376, y - 18, 12)


def st_pencil(ctx):
    ctx.save()
    ctx.translate(256, 256)
    ctx.rotate(-math.pi / 4)
    rrect(ctx, -170, -48, 70, 96, 20)
    fs(ctx, C['pink'])
    ctx.rectangle(-110, -48, 40, 96)
    fs(ctx, C['gray'])
    ctx.rectangle(-70, -48, 200, 96)
    fs(ctx, C['yellow'])
    poly(ctx, [(130, -48), (210, 0), (130, 48)])
    fs(ctx, C['cream'])
    poly(ctx, [(183, -16), (210, 0), (183, 16)])
    ctx.set_source_rgb(*INK)
    ctx.fill()
    line(ctx, -70, 0, 130, 0, 10)
    ctx.restore()


def st_bulb(ctx):
    ctx.arc(256, 210, 130, math.radians(140), math.radians(40))
    ctx.line_to(306, 350)
    ctx.line_to(206, 350)
    ctx.close_path()
    fs(ctx, C['yellow'])
    rrect(ctx, 200, 350, 112, 70, 18)
    fs(ctx, C['gray'])
    line(ctx, 210, 385, 302, 385, 10)
    ctx.move_to(210, 210)
    ctx.curve_to(220, 160, 250, 150, 270, 150)
    ctx.set_source_rgb(*WHITE)
    ctx.set_line_width(18)
    ctx.stroke()
    for a in (-150, -90, -30):
        r = math.radians(a)
        line(ctx, 256 + 160 * math.cos(r), 210 + 160 * math.sin(r),
             256 + 200 * math.cos(r), 210 + 200 * math.sin(r), 16)


def st_cap(ctx):
    poly(ctx, [(160, 250), (352, 250), (352, 350)], close=False)
    ctx.curve_to(300, 390, 212, 390, 160, 350)
    ctx.close_path()
    fs(ctx, C['dark'])
    poly(ctx, [(256, 110), (470, 200), (256, 290), (42, 200)])
    fs(ctx, C['indigo'])
    line(ctx, 256, 200, 420, 260, 10)
    line(ctx, 420, 260, 420, 360, 10)
    circle(ctx, 420, 370, 18)
    fs(ctx, C['yellow'], 10)


def st_backpack(ctx):
    ctx.arc(256, 140, 60, math.pi, 0)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(LW + 6)
    ctx.stroke()
    rrect(ctx, 120, 130, 272, 300, 80)
    fs(ctx, C['red'])
    rrect(ctx, 170, 290, 172, 110, 30)
    fs(ctx, C['orange'])
    line(ctx, 190, 330, 322, 330, 12)
    line(ctx, 160, 200, 160, 260, 12, WHITE)


def st_calculator(ctx):
    rrect(ctx, 126, 70, 260, 372, 40)
    fs(ctx, C['dark'])
    rrect(ctx, 160, 106, 192, 80, 16)
    fs(ctx, C['green'])
    text(ctx, '3.14', 336, 166, 46, INK, True, 'right', 'Noto Sans Mono')
    cols = [C['gray'], C['gray'], C['orange']]
    for r in range(3):
        for c in range(3):
            rrect(ctx, 160 + c * 68, 214 + r * 68, 52, 52, 12)
            fs(ctx, cols[c], 10)


def st_clipboard(ctx):
    rrect(ctx, 116, 90, 280, 350, 30)
    fs(ctx, C['brown'])
    rrect(ctx, 146, 130, 220, 280, 14)
    fs(ctx, WHITE)
    rrect(ctx, 196, 66, 120, 60, 18)
    fs(ctx, C['gray'])
    for i in range(3):
        y = 190 + i * 70
        poly(ctx, [(172, y), (186, y + 16), (210, y - 14)], close=False)
        ctx.set_source_rgb(*C['green'])
        ctx.set_line_width(14)
        ctx.stroke()
        line(ctx, 236, y, 336, y, 12, C['dark'])


def st_glasses(ctx):
    for x in (160, 352):
        circle(ctx, x, 270, 84)
        fs(ctx, C['sky'])
    ctx.arc(256, 280, 36, math.pi * 1.15, math.pi * 1.85)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(LW)
    ctx.stroke()
    line(ctx, 78, 250, 40, 200)
    line(ctx, 434, 250, 472, 200)
    ctx.move_to(118, 240)
    ctx.curve_to(124, 222, 136, 212, 152, 208)
    ctx.set_source_rgb(*WHITE)
    ctx.set_line_width(14)
    ctx.stroke()


def st_alarm(ctx):
    line(ctx, 170, 400, 140, 440, LW + 4)
    line(ctx, 342, 400, 372, 440, LW + 4)
    for x, a in ((140, -1), (372, 1)):
        ctx.arc(x, 130, 56, math.pi if a < 0 else -math.pi / 2,
                -math.pi / 2 if a < 0 else 0)
        ctx.line_to(x, 130)
        ctx.close_path()
        fs(ctx, C['orange'])
    circle(ctx, 256, 280, 160)
    fs(ctx, C['red'])
    circle(ctx, 256, 280, 118)
    fs(ctx, WHITE, 10)
    line(ctx, 256, 280, 256, 196, 16)
    line(ctx, 256, 280, 316, 310, 16)


def st_notebook(ctx):
    rrect(ctx, 136, 76, 260, 360, 28)
    fs(ctx, C['green'])
    rrect(ctx, 186, 136, 160, 64, 12)
    fs(ctx, WHITE, 10)
    for i in range(6):
        y = 110 + i * 56
        rrect(ctx, 110, y, 52, 22, 11)
        fs(ctx, C['gray'], 10)


# ---------------------------------------------------------------- planner

def st_check(ctx):
    circle(ctx, 256, 256, 180)
    fs(ctx, C['green'])
    poly(ctx, [(170, 262), (232, 324), (348, 196)], close=False)
    ctx.set_source_rgb(*WHITE)
    ctx.set_line_width(44)
    ctx.stroke()


def st_cross(ctx):
    circle(ctx, 256, 256, 180)
    fs(ctx, C['red'])
    for a, b in (((186, 186), (326, 326)), ((326, 186), (186, 326))):
        line(ctx, *a, *b, 44, WHITE)


def st_star(ctx):
    poly(ctx, star_pts(256, 270, 200, 86))
    fs(ctx, C['yellow'])


def st_heart(ctx):
    ctx.move_to(256, 430)
    ctx.curve_to(60, 300, 60, 110, 180, 110)
    ctx.curve_to(220, 110, 246, 136, 256, 170)
    ctx.curve_to(266, 136, 292, 110, 332, 110)
    ctx.curve_to(452, 110, 452, 300, 256, 430)
    ctx.close_path()
    fs(ctx, C['pink'])


def st_arrow(ctx):
    poly(ctx, [(70, 206), (290, 206), (290, 120), (450, 256), (290, 392), (290, 306), (70, 306)])
    fs(ctx, C['blue'])


def st_arrow_curve(ctx):
    ctx.move_to(110, 380)
    ctx.curve_to(110, 200, 220, 150, 330, 150)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(84)
    ctx.stroke()
    ctx.move_to(110, 380)
    ctx.curve_to(110, 200, 220, 150, 330, 150)
    ctx.set_source_rgb(*C['purple'])
    ctx.set_line_width(48)
    ctx.stroke()
    poly(ctx, [(320, 70), (450, 150), (320, 230)])
    fs(ctx, C['purple'])


def st_exclaim(ctx):
    poly(ctx, [(256, 60), (470, 430), (42, 430)])
    fs(ctx, C['orange'])
    line(ctx, 256, 180, 256, 320, 40)
    circle(ctx, 256, 380, 22)
    ctx.set_source_rgb(*INK)
    ctx.fill()


def st_pin(ctx):
    line(ctx, 256, 300, 256, 460, 20)
    ctx.move_to(176, 300)
    ctx.line_to(336, 300)
    ctx.line_to(306, 220)
    ctx.line_to(306, 140)
    ctx.line_to(206, 140)
    ctx.line_to(206, 220)
    ctx.close_path()
    fs(ctx, C['red'])
    rrect(ctx, 176, 70, 160, 70, 30)
    fs(ctx, C['red'])


def st_flag(ctx):
    line(ctx, 130, 70, 130, 450, LW + 6)
    ctx.move_to(130, 90)
    ctx.curve_to(220, 50, 300, 150, 400, 100)
    ctx.line_to(400, 280)
    ctx.curve_to(300, 330, 220, 230, 130, 270)
    ctx.close_path()
    fs(ctx, C['teal'])


def st_calendar(ctx):
    rrect(ctx, 90, 110, 332, 320, 36)
    fs(ctx, WHITE)
    ctx.new_path()
    ctx.move_to(90, 210)
    ctx.line_to(90, 146)
    ctx.arc(126, 146, 36, math.pi, 3 * math.pi / 2)
    ctx.line_to(386, 110)
    ctx.arc(386, 146, 36, -math.pi / 2, 0)
    ctx.line_to(422, 210)
    ctx.close_path()
    fs(ctx, C['red'])
    for x in (170, 342):
        line(ctx, x, 80, x, 140, LW + 6)
    for r in range(3):
        for c in range(4):
            rrect(ctx, 128 + c * 68, 240 + r * 60, 44, 38, 8)
            ctx.set_source_rgb(*(C['red'] if (r, c) == (1, 2) else C['gray']))
            ctx.fill()


def st_clock(ctx):
    circle(ctx, 256, 256, 180)
    fs(ctx, C['sky'])
    for i in range(12):
        a = i * math.pi / 6
        r1 = 140 if i % 3 else 120
        line(ctx, 256 + r1 * math.cos(a), 256 + r1 * math.sin(a),
             256 + 156 * math.cos(a), 256 + 156 * math.sin(a), 12)
    line(ctx, 256, 256, 256, 150, 18)
    line(ctx, 256, 256, 330, 256, 18)
    circle(ctx, 256, 256, 16)
    ctx.fill()


def st_bookmark(ctx):
    poly(ctx, [(150, 70), (362, 70), (362, 440), (256, 360), (150, 440)])
    fs(ctx, C['indigo'])
    poly(ctx, star_pts(256, 190, 60, 26))
    fs(ctx, C['yellow'], 10)


# ---------------------------------------------------------------- clima y ánimo

def st_sun(ctx):
    for i in range(8):
        a = i * math.pi / 4
        line(ctx, 256 + 150 * math.cos(a), 256 + 150 * math.sin(a),
             256 + 210 * math.cos(a), 256 + 210 * math.sin(a), LW + 8, C['orange'])
    circle(ctx, 256, 256, 116)
    fs(ctx, C['yellow'])


def st_cloud(ctx):
    cloud(ctx, 256, 250, 1.2)


def st_partly(ctx):
    for i in range(5):
        a = math.pi + i * math.pi / 4.5
        line(ctx, 200 + 110 * math.cos(a), 200 + 110 * math.sin(a),
             200 + 160 * math.cos(a), 200 + 160 * math.sin(a), LW + 6, C['orange'])
    circle(ctx, 200, 200, 80)
    fs(ctx, C['yellow'])
    cloud(ctx, 290, 300, 1.0)


def st_rain(ctx):
    for x in (170, 256, 342):
        ctx.move_to(x, 330)
        ctx.curve_to(x - 24, 380, x - 24, 410, x, 410)
        ctx.curve_to(x + 24, 410, x + 24, 380, x, 330)
        fs(ctx, C['blue'], 12)
    cloud(ctx, 256, 200, 1.1, C['gray'])


def st_snow(ctx):
    for k in range(3):
        a = k * math.pi / 3
        line(ctx, 256 - 190 * math.cos(a), 256 - 190 * math.sin(a),
             256 + 190 * math.cos(a), 256 + 190 * math.sin(a), LW + 6, C['sky'])
    for k in range(6):
        a = k * math.pi / 3
        bx, by = 256 + 120 * math.cos(a), 256 + 120 * math.sin(a)
        for d in (-0.7, 0.7):
            line(ctx, bx, by, bx + 50 * math.cos(a + d), by + 50 * math.sin(a + d), 16, C['sky'])
    circle(ctx, 256, 256, 30)
    fs(ctx, WHITE, 12)


def st_storm(ctx):
    cloud(ctx, 256, 190, 1.1, C['dark'])
    poly(ctx, [(270, 270), (200, 370), (250, 370), (220, 460), (320, 340), (268, 340), (300, 270)])
    fs(ctx, C['yellow'])


def st_moon(ctx):
    # media luna: disco menos otro disco desplazado (par-impar)
    ctx.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
    clip_a = (236, 266, 180)
    clip_b = (330, 190, 150)
    ctx.save()
    circle(ctx, *clip_b)
    ctx.rectangle(0, 0, S, S)
    ctx.clip()
    circle(ctx, *clip_a)
    fs(ctx, C['yellow'])
    ctx.restore()
    ctx.set_fill_rule(cairo.FILL_RULE_WINDING)
    # contorno del borde interior
    ctx.save()
    circle(ctx, *clip_a)
    ctx.clip()
    circle(ctx, *clip_b)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(LW)
    ctx.stroke()
    ctx.restore()
    poly(ctx, star_pts(400, 330, 40, 17))
    fs(ctx, C['cream'], 10)


def st_rainbow(ctx):
    cols = [C['red'], C['orange'], C['yellow'], C['green'], C['blue']]
    for i, c in enumerate(cols):
        ctx.arc(256, 380, 210 - i * 34, math.pi, 0)
        ctx.set_source_rgb(*INK)
        ctx.set_line_width(40)
        ctx.stroke()
    for i, c in enumerate(cols):
        ctx.arc(256, 380, 210 - i * 34, math.pi, 0)
        ctx.set_source_rgb(*c)
        ctx.set_line_width(26)
        ctx.stroke()
    cloud(ctx, 90, 380, 0.55)
    cloud(ctx, 422, 380, 0.55)


def st_happy(ctx):
    face(ctx, C['yellow'])
    eyes(ctx)
    ctx.arc(256, 280, 90, math.radians(20), math.radians(160))
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(LW)
    ctx.stroke()


def st_sad(ctx):
    face(ctx, C['sky'])
    eyes(ctx)
    ctx.arc(256, 390, 80, math.radians(-150), math.radians(-30))
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(LW)
    ctx.stroke()
    ctx.move_to(186, 250)
    ctx.curve_to(170, 290, 202, 290, 186, 250)
    fs(ctx, C['blue'], 8)


def st_neutral(ctx):
    face(ctx, C['gray'])
    eyes(ctx)
    line(ctx, 190, 330, 322, 330)


def st_surprised(ctx):
    face(ctx, C['orange'])
    eyes(ctx, 210, 70, 24)
    circle(ctx, 256, 330, 44)
    fs(ctx, C['dark'])


def st_sleepy(ctx):
    face(ctx, C['purple'])
    for x in (186, 326):
        ctx.arc(x, 220, 34, math.radians(20), math.radians(160))
        ctx.set_source_rgb(*INK)
        ctx.set_line_width(LW - 4)
        ctx.stroke()
    circle(ctx, 256, 330, 24)
    fs(ctx, C['dark'], 10)
    glyph(ctx, 'z', 400, 130, 80)


def st_love(ctx):
    face(ctx, C['pink'])
    for x in (186, 326):
        ctx.save()
        ctx.translate(x - 256, 220 - 270)
        ctx.scale(1, 1)
        ctx.move_to(256, 300)
        ctx.curve_to(206, 266, 206, 226, 236, 226)
        ctx.curve_to(246, 226, 254, 232, 256, 242)
        ctx.curve_to(258, 232, 266, 226, 276, 226)
        ctx.curve_to(306, 226, 306, 266, 256, 300)
        ctx.close_path()
        ctx.restore()
        fs(ctx, C['red'], 8)
    ctx.arc(256, 290, 80, math.radians(20), math.radians(160))
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(LW)
    ctx.stroke()


# ---------------------------------------------------------------- ciencia y mates

def st_atom(ctx):
    for k in range(3):
        ctx.save()
        ctx.translate(256, 256)
        ctx.rotate(k * math.pi / 3)
        ctx.scale(1, 0.38)
        ctx.arc(0, 0, 190, 0, 2 * math.pi)
        ctx.restore()
        ctx.set_source_rgb(*C['blue'])
        ctx.set_line_width(LW)
        ctx.stroke()
    circle(ctx, 256, 256, 38)
    fs(ctx, C['red'])


def st_flask(ctx):
    ctx.move_to(216, 80)
    ctx.line_to(216, 200)
    ctx.line_to(110, 400)
    ctx.curve_to(100, 430, 116, 440, 140, 440)
    ctx.line_to(372, 440)
    ctx.curve_to(396, 440, 412, 430, 402, 400)
    ctx.line_to(296, 200)
    ctx.line_to(296, 80)
    ctx.close_path()
    fs(ctx, WHITE)
    ctx.move_to(166, 300)
    ctx.line_to(346, 300)
    ctx.line_to(402, 400)
    ctx.curve_to(412, 430, 396, 440, 372, 440)
    ctx.line_to(140, 440)
    ctx.curve_to(116, 440, 100, 430, 110, 400)
    ctx.close_path()
    fs(ctx, C['green'])
    line(ctx, 190, 80, 322, 80)
    for x, y, r in ((226, 360, 16), (290, 390, 12), (262, 250, 14)):
        circle(ctx, x, y, r)
        fs(ctx, WHITE, 8)


def st_dna(ctx):
    n = 60
    for phase, col in ((0, C['blue']), (math.pi, C['pink'])):
        for i in range(n + 1):
            t = i / n
            y = 70 + t * 372
            x = 256 + 110 * math.sin(t * 2 * math.pi * 1.5 + phase)
            (ctx.move_to if i == 0 else ctx.line_to)(x, y)
        ctx.set_source_rgb(*INK)
        ctx.set_line_width(LW + 16)
        ctx.stroke_preserve()
        ctx.set_source_rgb(*col)
        ctx.set_line_width(16)
        ctx.stroke()
    for i in range(1, 9):
        t = i / 9
        y = 70 + t * 372
        x1 = 256 + 110 * math.sin(t * 3 * math.pi)
        x2 = 256 + 110 * math.sin(t * 3 * math.pi + math.pi)
        if abs(x1 - x2) > 40:
            line(ctx, min(x1, x2) + 20, y, max(x1, x2) - 20, y, 10)


def st_magnet(ctx):
    ctx.arc(256, 230, 150, math.pi, 0)
    ctx.line_to(406, 420)
    ctx.line_to(316, 420)
    ctx.line_to(316, 230)
    ctx.arc_negative(256, 230, 60, 0, math.pi)
    ctx.line_to(196, 420)
    ctx.line_to(106, 420)
    ctx.close_path()
    fs(ctx, C['red'])
    for x in (106, 316):
        ctx.rectangle(x, 350, 90, 70)
        fs(ctx, C['gray'])


def symbol(ch, fill, size=230, font='Noto Sans'):
    def draw(ctx):
        tile(ctx, fill)
        glyph(ctx, ch, 256, 256, size, INK, True, font)
    return draw


def st_tube(ctx):
    ctx.save()
    ctx.translate(256, 256)
    ctx.rotate(0.35)
    ctx.move_to(-60, -170)
    ctx.line_to(-60, 140)
    ctx.arc_negative(0, 140, 60, math.pi, 0)
    ctx.line_to(60, -170)
    ctx.close_path()
    ctx.restore()
    fs(ctx, WHITE)
    ctx.save()
    ctx.translate(256, 256)
    ctx.rotate(0.35)
    ctx.move_to(-60, 20)
    ctx.line_to(-60, 140)
    ctx.arc_negative(0, 140, 60, math.pi, 0)
    ctx.line_to(60, 20)
    ctx.close_path()
    ctx.restore()
    fs(ctx, C['purple'])
    ctx.save()
    ctx.translate(256, 256)
    ctx.rotate(0.35)
    rrect(ctx, -84, -200, 168, 40, 16)
    ctx.restore()
    fs(ctx, C['gray'])
    for x, y, r in ((330, 130, 22), (380, 80, 14)):
        circle(ctx, x, y, r)
        fs(ctx, C['purple'], 10)


def path_symbol(fill, draw_path):
    """Símbolo dibujado como trazo (no depende de las fuentes instaladas)."""
    def draw(ctx):
        tile(ctx, fill)
        draw_path(ctx)
        ctx.set_source_rgb(*INK)
        ctx.set_line_width(34)
        ctx.stroke()
    return draw


def p_infinity(ctx):
    for i in range(121):
        t = i / 120 * 2 * math.pi
        d = 1 + math.sin(t) ** 2
        x, y = 256 + 150 * math.cos(t) / d, 256 + 150 * math.sin(t) * math.cos(t) / d
        (ctx.move_to if i == 0 else ctx.line_to)(x, y)
    ctx.close_path()


def p_sqrt(ctx):
    poly(ctx, [(120, 280), (170, 250), (230, 380), (300, 130), (400, 130)], close=False)


def p_integral(ctx):
    ctx.move_to(320, 130)
    ctx.curve_to(300, 90, 256, 100, 256, 170)
    ctx.line_to(256, 340)
    ctx.curve_to(256, 410, 212, 420, 192, 380)


STICKER_PACKS = {
    'stickers-estudio': ('Estudio', 'Libro, lápiz, bombilla, birrete, mochila, calculadora y más para tus apuntes.',
                         ['estudio', 'escuela'], {
        'libro': st_book, 'lapiz': st_pencil, 'bombilla': st_bulb, 'birrete': st_cap,
        'mochila': st_backpack, 'calculadora': st_calculator, 'portapapeles': st_clipboard,
        'gafas': st_glasses, 'despertador': st_alarm, 'cuaderno': st_notebook,
    }),
    'stickers-agenda': ('Agenda', 'Marcas, flechas, estrellas y avisos para organizar tu planner.',
                        ['organización', 'agenda'], {
        'hecho': st_check, 'pendiente': st_cross, 'estrella': st_star, 'corazon': st_heart,
        'flecha': st_arrow, 'flecha-curva': st_arrow_curve, 'aviso': st_exclaim,
        'chincheta': st_pin, 'bandera': st_flag, 'calendario': st_calendar,
        'reloj': st_clock, 'marcador': st_bookmark,
    }),
    'stickers-clima-animo': ('Clima y ánimo', 'Tiempo del día y caritas para tu diario o registro de ánimo.',
                             ['diario', 'emociones'], {
        'sol': st_sun, 'nube': st_cloud, 'sol-y-nubes': st_partly, 'lluvia': st_rain,
        'nieve': st_snow, 'tormenta': st_storm, 'luna': st_moon, 'arcoiris': st_rainbow,
        'feliz': st_happy, 'triste': st_sad, 'neutral': st_neutral, 'sorpresa': st_surprised,
        'sueno': st_sleepy, 'enamorado': st_love,
    }),
    'stickers-ciencia': ('Ciencia y mates', 'Átomo, matraz, ADN, imán, tubo de ensayo y símbolos matemáticos para tus apuntes.',
                         ['ciencia', 'matemáticas', 'estudio'], {
        'atomo': st_atom, 'matraz': st_flask, 'adn': st_dna, 'iman': st_magnet,
        'tubo-ensayo': st_tube,
        'pi': symbol('π', C['sky']), 'sumatorio': symbol('Σ', C['yellow']),
        'integral': path_symbol(C['green'], p_integral), 'raiz': path_symbol(C['pink'], p_sqrt),
        'infinito': path_symbol(C['purple'], p_infinity), 'mas-menos': symbol('±', C['orange']),
        'delta': symbol('Δ', C['teal']),
    }),
}


# ---------------------------------------------------------------- plantillas

TW, TH = 1786, 2526      # A4 a 1,5× de la hoja de Inklus (1191 × 1684)
LINE = hexc('#9DB6D9')
LINE_SOFT = hexc('#D5E1EF')
HEAD = hexc('#5B7BA6')
DAYS = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']


def page():
    surf, ctx = new(TW, TH)
    ctx.set_source_rgb(1, 1, 1)
    ctx.paint()
    return surf, ctx


def hl(ctx, x1, y, x2, color=LINE, lw=2):
    line(ctx, x1, y, x2, y, lw, color)


def vl(ctx, x, y1, y2, color=LINE, lw=2):
    line(ctx, x, y1, x, y2, lw, color)


def box(ctx, x, y, w, h, color=LINE, lw=3, r=18):
    rrect(ctx, x, y, w, h, r)
    ctx.set_source_rgb(*color)
    ctx.set_line_width(lw)
    ctx.stroke()


def title(ctx, s, y=170):
    text(ctx, s, 120, y, 72, HEAD, True)
    hl(ctx, 120, y + 40, TW - 120, HEAD, 4)


def tpl_weekly():
    surf, ctx = page()
    title(ctx, 'Semana')
    text(ctx, 'del ______ al ______', TW - 120, 170, 40, HEAD, False, 'right')
    m, top, gap = 120, 260, 30
    w = (TW - 2 * m - gap) / 2
    h = (TH - top - 120 - 3 * gap) / 4
    cells = DAYS + ['Notas']
    for i, name in enumerate(cells):
        x = m + (i % 2) * (w + gap)
        y = top + (i // 2) * (h + gap)
        box(ctx, x, y, w, h)
        text(ctx, name, x + 30, y + 64, 42, HEAD, True)
        yy = y + 120
        while yy < y + h - 30:
            if name == 'Notas':
                xx = x + 40
                while xx < x + w - 20:
                    circle(ctx, xx, yy, 3)
                    ctx.set_source_rgb(*LINE)
                    ctx.fill()
                    xx += 44
                yy += 44
            else:
                hl(ctx, x + 30, yy, x + w - 30, LINE_SOFT)
                yy += 58
    return surf


def tpl_daily():
    surf, ctx = page()
    title(ctx, 'Hoy')
    text(ctx, '___ / ___ / ______', TW - 120, 170, 40, HEAD, False, 'right')
    m, top = 120, 270
    split = 1040
    # horario
    text(ctx, 'Horario', m, top + 40, 40, HEAD, True)
    y0, rows = top + 80, 16
    rh = (TH - 140 - y0) / rows
    for i in range(rows + 1):
        y = y0 + i * rh
        hl(ctx, m, y, split - 40, LINE if i % 1 == 0 else LINE_SOFT)
        if i < rows:
            text(ctx, f'{6 + i:02d}:00', m + 6, y + 44, 30, HEAD)
            hl(ctx, m + 130, y + rh / 2, split - 40, LINE_SOFT, 1)
    vl(ctx, m + 120, y0, y0 + rows * rh)
    # columna derecha
    x, w = split + 20, TW - m - split - 20
    sections = [('Prioridades', 3, 'num'), ('Tareas', 9, 'check'), ('Notas', 0, '')]
    y = top
    heights = [460, 900, TH - 140 - top - 460 - 900 - 60]
    for (name, n, kind), h in zip(sections, heights):
        box(ctx, x, y, w, h)
        text(ctx, name, x + 30, y + 62, 40, HEAD, True)
        for k in range(n):
            yy = y + 140 + k * ((h - 170) / max(n, 1))
            if kind == 'num':
                text(ctx, f'{k + 1}.', x + 36, yy + 10, 36, HEAD, True)
            else:
                box(ctx, x + 32, yy - 26, 36, 36, LINE, 3, 6)
            hl(ctx, x + 90, yy + 14, x + w - 30, LINE_SOFT)
        y += h + 30
    return surf


def tpl_habits():
    surf, ctx = page()
    title(ctx, 'Hábitos del mes')
    text(ctx, 'Mes: __________', TW - 120, 170, 40, HEAD, False, 'right')
    m, top = 120, 300
    namew = 420
    days = 31
    cw = (TW - 2 * m - namew) / days
    rows = 16
    rh = (TH - 180 - top - 60) / rows
    for d in range(days):
        text(ctx, str(d + 1), m + namew + d * cw + cw / 2, top + 36, 24, HEAD, d % 7 == 6, 'center')
    y0 = top + 60
    for r in range(rows + 1):
        hl(ctx, m, y0 + r * rh, TW - m, LINE, 2)
    vl(ctx, m, y0, y0 + rows * rh)
    for d in range(days + 1):
        vl(ctx, m + namew + d * cw, y0, y0 + rows * rh, LINE if d % 7 == 0 else LINE_SOFT, 3 if d % 7 == 0 else 2)
    text(ctx, 'Hábito', m + 20, y0 - 18, 30, HEAD, True)
    text(ctx, 'Rellena un cuadro cada día que lo cumplas.', m, TH - 130, 32, HEAD)
    return surf


def tpl_meeting():
    surf, ctx = page()
    title(ctx, 'Reunión')
    m = 120
    fields = ['Fecha', 'Asistentes', 'Tema']
    y = 300
    for f in fields:
        text(ctx, f + ':', m, y, 40, HEAD, True)
        hl(ctx, m + 260, y + 8, TW - m, LINE)
        y += 90
    box(ctx, m, y, TW - 2 * m, 900)
    text(ctx, 'Notas', m + 30, y + 62, 40, HEAD, True)
    yy = y + 130
    while yy < y + 880:
        hl(ctx, m + 30, yy, TW - m - 30, LINE_SOFT)
        yy += 60
    y += 940
    half = (TW - 2 * m - 30) / 2
    for i, name in enumerate(['Decisiones', 'Próximos pasos']):
        x = m + i * (half + 30)
        box(ctx, x, y, half, TH - 140 - y)
        text(ctx, name, x + 30, y + 62, 40, HEAD, True)
        yy = y + 140
        while yy < TH - 170:
            if i == 1:
                box(ctx, x + 30, yy - 30, 36, 36, LINE, 3, 6)
            hl(ctx, x + (90 if i else 30), yy + 10, x + half - 30, LINE_SOFT)
            yy += 70
    return surf


def tpl_engineering():
    """Papel de ingeniería: cuadrícula 5×5 con línea gruesa cada 5, verde suave."""
    surf, ctx = page()
    green = hexc('#86B49A')
    soft = hexc('#CFE3D6')
    cell = 36
    m = 130
    cols = int((TW - 2 * m) / cell)
    rows = int((TH - 2 * m - 80) / cell)
    x0 = (TW - cols * cell) / 2
    y0 = m + 80
    for c in range(cols + 1):
        vl(ctx, x0 + c * cell, y0, y0 + rows * cell, green if c % 5 == 0 else soft, 3 if c % 5 == 0 else 1.5)
    for r in range(rows + 1):
        hl(ctx, x0, y0 + r * cell, x0 + cols * cell, green if r % 5 == 0 else soft, 3 if r % 5 == 0 else 1.5)
    hl(ctx, x0, y0 - 30, x0 + cols * cell, green, 3)
    text(ctx, 'Proyecto: ____________', x0, y0 - 50, 34, green)
    text(ctx, 'Fecha: ________   Hoja ___ / ___', x0 + cols * cell, y0 - 50, 34, green, False, 'right')
    return surf


def tpl_isometric():
    """Puntos isométricos (triángulos de 48 px): perspectiva y dibujo técnico."""
    surf, ctx = page()
    s = 48
    hgt = s * math.sqrt(3) / 2
    ctx.set_source_rgb(*hexc('#8EA6C8'))
    r = 0
    y = 80.0
    while y < TH - 60:
        x = 80 + (s / 2 if r % 2 else 0)
        while x < TW - 60:
            circle(ctx, x, y, 3.2)
            x += s
        y += hgt
        r += 1
    ctx.fill()
    return surf


def tpl_hex():
    """Cuadrícula hexagonal (química orgánica, juegos, mapas)."""
    surf, ctx = page()
    r = 44
    w = math.sqrt(3) * r
    ctx.set_source_rgb(*LINE_SOFT)
    ctx.set_line_width(2)
    row = 0
    y = 40.0
    while y < TH + r:
        x = 40 + (w / 2 if row % 2 else 0)
        while x < TW + w:
            for k in range(6):
                a = math.pi / 6 + k * math.pi / 3
                px, py = x + r * math.cos(a), y + r * math.sin(a)
                (ctx.move_to if k == 0 else ctx.line_to)(px, py)
            ctx.close_path()
            x += w
        y += 1.5 * r
        row += 1
    ctx.stroke()
    return surf


def tpl_polar():
    """Papel polar: círculos concéntricos y radios cada 15°."""
    surf, ctx = page()
    cx, cy = TW / 2, TH / 2
    R = TW / 2 - 140
    for i in range(1, 11):
        circle(ctx, cx, cy, R * i / 10)
        ctx.set_source_rgb(*(LINE if i % 5 == 0 else LINE_SOFT))
        ctx.set_line_width(3 if i % 5 == 0 else 2)
        ctx.stroke()
    for k in range(24):
        a = k * math.pi / 12
        line(ctx, cx, cy, cx + R * math.cos(a), cy - R * math.sin(a), 3 if k % 6 == 0 else 1.5,
             LINE if k % 6 == 0 else LINE_SOFT)
        if k % 2 == 0:
            text(ctx, f'{k * 15}°', cx + (R + 50) * math.cos(a), cy - (R + 50) * math.sin(a) + 12,
                 30, HEAD, False, 'center')
    return surf


TEMPLATE_PACKS = {
    'agenda-imprimible': ('Agenda imprimible', 'Semana, día con horario, hábitos de 31 días y acta de reunión.',
                          ['organización', 'agenda'], [
        ('Semana', 'semana', tpl_weekly), ('Día con horario', 'dia', tpl_daily),
        ('Hábitos (31 días)', 'habitos', tpl_habits), ('Reunión', 'reunion', tpl_meeting),
    ]),
    'papel-ingenieria': ('Papel de ingeniería', 'Cuadrícula de ingeniería, puntos isométricos, hexágonos y papel polar.',
                         ['ingeniería', 'ciencia'], [
        ('Ingeniería', 'ingenieria', tpl_engineering), ('Isométrico', 'isometrico', tpl_isometric),
        ('Hexagonal', 'hexagonal', tpl_hex), ('Polar', 'polar', tpl_polar),
    ]),
}


# ---------------------------------------------------------------- vistas previas

PW, PH = 640, 400


def preview_stickers(paths, out):
    surf, ctx = new(PW, PH)
    ctx.set_source_rgb(*hexc('#F1F5F9'))
    ctx.paint()
    n = min(len(paths), 8)
    cols, rows = 4, 2
    cs = 140
    gx = (PW - cols * cs) / (cols + 1)
    gy = (PH - rows * cs) / (rows + 1)
    for i, p in enumerate(paths[:n]):
        img = cairo.ImageSurface.create_from_png(p)
        ctx.save()
        ctx.translate(gx + (i % cols) * (cs + gx), gy + (i // cols) * (cs + gy))
        ctx.scale(cs / S, cs / S)
        ctx.set_source_surface(img, 0, 0)
        ctx.paint()
        ctx.restore()
    surf.write_to_png(out)


def preview_templates(paths, out):
    surf, ctx = new(PW, PH)
    ctx.set_source_rgb(*hexc('#E2E8F0'))
    ctx.paint()
    n = len(paths)
    gap = 24
    pw = (PW - gap * (n + 1)) / n
    ph = pw * TH / TW
    top = (PH - ph) / 2
    for i, p in enumerate(paths):
        img = cairo.ImageSurface.create_from_png(p)
        x = gap + i * (pw + gap)
        ctx.save()
        ctx.translate(x, top)
        ctx.scale(pw / TW, ph / TH)
        ctx.set_source_surface(img, 0, 0)
        ctx.get_source().set_filter(cairo.FILTER_BEST)
        ctx.paint()
        ctx.restore()
        ctx.rectangle(x, top, pw, ph)
        ctx.set_source_rgb(*hexc('#94A3B8'))
        ctx.set_line_width(1)
        ctx.stroke()
    surf.write_to_png(out)


# ---------------------------------------------------------------- manifiestos

def manifest(pack_id, name, desc, ptype, tags, extra):
    import json
    m = {'id': pack_id, 'name': name, 'description': desc, 'type': ptype,
         'author': 'Inklus', 'license': 'CC0-1.0', 'version': '1.0.0', 'tags': tags, **extra,
         'preview': f'packs/{pack_id}/preview.png'}
    with open(os.path.join(ROOT, pack_id, 'manifest.json'), 'w', encoding='utf-8') as f:
        json.dump(m, f, ensure_ascii=False, indent=2)
        f.write('\n')


def main():
    for pid, (name, desc, tags, items) in STICKER_PACKS.items():
        d = os.path.join(ROOT, pid)
        os.makedirs(d, exist_ok=True)
        refs = []
        for fname, draw in items.items():
            surf, ctx = new()
            draw(ctx)
            surf.write_to_png(os.path.join(d, f'{fname}.png'))
            refs.append(f'packs/{pid}/{fname}.png')
        preview_stickers([os.path.join(d, f'{f}.png') for f in items], os.path.join(d, 'preview.png'))
        manifest(pid, name, desc, 'stickers', tags, {'stickers': refs})
        print('✔', pid, len(refs), 'stickers')
    for pid, (name, desc, tags, items) in TEMPLATE_PACKS.items():
        d = os.path.join(ROOT, pid)
        os.makedirs(d, exist_ok=True)
        tpls, files = [], []
        for tname, fname, draw in items:
            path = os.path.join(d, f'{fname}.png')
            draw().write_to_png(path)
            files.append(path)
            tpls.append({'name': tname, 'image': f'packs/{pid}/{fname}.png', 'infinite': False})
        preview_templates(files, os.path.join(d, 'preview.png'))
        manifest(pid, name, desc, 'template', tags, {'templates': tpls})
        print('✔', pid, len(tpls), 'plantillas')


if __name__ == '__main__':
    main()
