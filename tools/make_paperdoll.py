"""
32px 손그림 도트 용사 — 종이 인형(레이어) 방식.

각 장비 칸마다 따로 그린 그림(레이어)을 겹쳐서 하나의 용사가 된다.
  body   : 피부·얼굴·기본 옷(평상복)·바지·신발
  hair   : 머리카락
  armor  : 갑옷 (가죽옷 등) — 장착한 방어구에 따라 바뀜
  weapon : 무기 (평소엔 등에, 공격할 땐 손에) — 장착한 무기에 따라 바뀜
  cape   : 망토 — 1차 전직하면 직업 색 망토
  acc    : 장신구 (자갈 마을의 증표 등)

그림 한 장 = 32x32 칸이 가로 9칸(대기2 · 걷기4 · 공격3) × 세로 4줄(아래·왼쪽·오른쪽·위).
명암은 '왼쪽 위에서 오는 빛' 규칙으로 칸마다 밝은/기본/어두운 색을 고르고, 바깥에 윤곽선을 두른다.
"""
import sys, os, math
from PIL import Image

W = H = 32
DIRS = ["down", "left", "right", "up"]
FEET = 30  # 발바닥 줄

# ---------------- 색 (윤곽 o, 어두움 1, 기본 2, 밝음 3, 하이라이트 4) ----------------
def pal(o, d, b, l, h):
    return {"o": o, "1": d, "2": b, "3": l, "4": h}

SKIN = pal((92, 50, 44), (214, 150, 120), (246, 196, 160), (255, 220, 190), (255, 236, 214))
HAIR = pal((52, 30, 24), (92, 54, 36), (128, 78, 48), (164, 106, 64), (200, 144, 90))
SHIRT = pal((54, 58, 82), (88, 108, 150), (112, 140, 190), (148, 176, 220), (190, 210, 240))   # 평상복(푸른 셔츠)
PANTS = pal((40, 32, 36), (70, 58, 60), (94, 80, 80), (120, 104, 100), (140, 124, 118))
SHOES = pal((34, 22, 18), (70, 44, 32), (98, 64, 44), (124, 86, 58), (150, 108, 74))
BELT = pal((40, 26, 18), (96, 62, 34), (130, 88, 48), (160, 114, 64), (230, 196, 90))
LEATHER = pal((52, 30, 18), (110, 66, 36), (146, 92, 50), (178, 122, 68), (206, 156, 96))
STRAP = pal((40, 24, 14), (80, 50, 28), (104, 66, 38), (128, 84, 50), (220, 186, 90))
WOOD = pal((58, 36, 22), (128, 88, 52), (168, 120, 72), (200, 156, 100), (226, 192, 138))
STEEL = pal((44, 46, 60), (130, 136, 156), (176, 182, 200), (214, 220, 234), (248, 250, 255))
GOLD = pal((90, 60, 20), (180, 130, 40), (226, 182, 70), (246, 214, 110), (255, 240, 180))
CAPES = {
    "granite_knight": pal((30, 40, 80), (48, 70, 130), (66, 96, 170), (96, 128, 200), (140, 170, 230)),
    "steel_fighter": pal((70, 20, 22), (130, 34, 36), (172, 48, 48), (206, 74, 70), (236, 120, 110)),
    "quartz_mage": pal((90, 80, 110), (180, 170, 206), (222, 216, 240), (240, 236, 252), (255, 255, 255)),
}
EYE = (40, 28, 40, 255)
WHITE = (255, 255, 255, 255)
BLUSH = (240, 150, 140, 255)
MOUTH = (150, 70, 70, 255)


# ---------------- 그림 그리기 도구 ----------------
class Layer:
    def __init__(self):
        self.px = {}       # (x,y) → (r,g,b,a)

    def put(self, x, y, c):
        if 0 <= x < W and 0 <= y < H:
            self.px[(x, y)] = c if len(c) == 4 else c + (255,)

    def image(self):
        im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        for (x, y), c in self.px.items():
            im.putpixel((x, y), c)
        return im


def shade_fill(layer, mask, p, light=(-1, -1), outline=True, hl_band=True):
    """마스크 영역을 칠한다: 빛 쪽 가장자리는 밝게, 반대쪽은 어둡게, 바깥은 윤곽선."""
    mask = set(mask)
    lx, ly = light
    for (x, y) in mask:
        lit_edge = (x + lx, y + ly) not in mask
        dark_edge = (x - lx, y - ly) not in mask
        lit2 = (x + 2 * lx, y + 2 * ly) not in mask
        if dark_edge and not lit_edge:
            c = p["1"]
        elif lit_edge and hl_band and (x + lx, y) not in mask and (x, y + ly) not in mask:
            c = p["4"]
        elif lit_edge:
            c = p["3"]
        elif lit2 and hl_band:
            c = p["3"]
        else:
            c = p["2"]
        layer.put(x, y, c)
    if outline:
        for (x, y) in mask:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + dx, y + dy)
                if q not in mask and q not in layer.px:
                    layer.put(q[0], q[1], p["o"])


def rect(x0, y0, x1, y1):
    return {(x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1)}


def rrect(x0, y0, x1, y1):
    """모서리를 깎은 사각형"""
    m = rect(x0, y0, x1, y1)
    for c in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
        m.discard(c)
    return m


def ellipse(cx, cy, rx, ry):
    return {(x, y) for x in range(int(cx - rx - 1), int(cx + rx + 2)) for y in range(int(cy - ry - 1), int(cy + ry + 2))
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0}


def line_pts(x0, y0, x1, y1):
    pts = []
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(n + 1):
        pts.append((round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n)))
    return pts


def thick_line(x0, y0, x1, y1, w=2):
    m = set()
    for (x, y) in line_pts(x0, y0, x1, y1):
        for dx in range(w):
            for dy in range(w):
                m.add((x + dx - (w - 1) // 2, y + dy - (w - 1) // 2))
    return m


# ---------------- 포즈 ----------------
def poses():
    """대기 2 + 걷기 4 + 공격 3. 값: bob(몸 들썩), legL/legR(다리 들기·내딛기), arm(팔 흔들기), atk(공격 단계)"""
    P = [dict(bob=0, legL=0, legR=0, arm=0, atk=None), dict(bob=1, legL=0, legR=0, arm=0, atk=None)]
    P += [dict(bob=0, legL=1, legR=0, arm=1, atk=None), dict(bob=-1, legL=0, legR=0, arm=0, atk=None),
          dict(bob=0, legL=0, legR=1, arm=-1, atk=None), dict(bob=-1, legL=0, legR=0, arm=0, atk=None)]
    P += [dict(bob=0, legL=0, legR=0, arm=0, atk=0), dict(bob=1, legL=1, legR=0, arm=0, atk=1), dict(bob=1, legL=1, legR=0, arm=0, atk=2)]
    return P


# ---------------- 얼굴 (손으로 찍은 픽셀) ----------------
FACE_DOWN = [
    "...oooooooo...",
    "..o22222222o..",
    ".o2222222222o.",
    "o222222222222o",
    "o222222222222o",
    "o22ee2222ee22o",
    "o22ew2222we22o",
    "o22ee2222ee22o",
    "o1b22222222b1o",
    "o11222mm22211o",
    ".o1122222211o.",
    "..oo111111oo..",
    "....oooooo....",
]
FACE_SIDE = [   # 오른쪽을 봄
    "..ooooooo....",
    ".o2222222o...",
    "o222222222o..",
    "o2222222222o.",
    "o2222222222o.",
    "o22222222ee2o",
    "o22222222we2o",
    "o22222222ee2o",
    "o122222222b2o",
    "o1122222222o.",
    ".o112222222o.",
    "..oo1111ooo..",
    "....oooo.....",
]
FACE_UP = [
    "...oooooooo...",
    "..o22222222o..",
    ".o2222222222o.",
    "o222222222222o",
    "o222222222222o",
    "o222222222222o",
    "o222222222222o",
    "o222222222222o",
    "o122222222221o",
    "o112222222211o",
    ".o1122222211o.",
    "..oo111111oo..",
    "....oooooo....",
]


def stamp(layer, rows, x0, y0, p, special=None):
    special = special or {}
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            if ch in special:
                layer.put(x0 + x, y0 + y, special[ch])
            elif ch in p:
                layer.put(x0 + x, y0 + y, p[ch])


FACE_SPECIAL = {"e": EYE, "w": WHITE, "b": BLUSH, "m": MOUTH}


# ---------------- 몸 ----------------
def draw_body(d, P, shirt=None, pants=None, skin=None):
    """피부·얼굴·평상복·바지·신발"""
    global SHIRT, PANTS, SKIN
    _saved = (SHIRT, PANTS, SKIN)
    SHIRT = shirt or SHIRT; PANTS = pants or PANTS; SKIN = skin or SKIN
    try:
        return _draw_body(d, P)
    finally:
        SHIRT, PANTS, SKIN = _saved


def _draw_body(d, P):
    L = Layer()
    b = P["bob"]
    # 다리 (바지 + 신발)
    if d in ("down", "up"):
        for side, lift in ((-1, P["legL"]), (1, P["legR"])):
            x0 = 12 if side < 0 else 17
            top = 25
            bottom = FEET - lift
            shade_fill(L, rect(x0, top, x0 + 2, bottom - 2), PANTS)
            shoe = rrect(x0 - (1 if side < 0 else 0), bottom - 2, x0 + 2 + (0 if side < 0 else 1), bottom)
            shade_fill(L, shoe, SHOES)
    else:
        # 옆모습: 다리 두 개가 앞뒤로 벌어짐
        stride = 2 if (P["legL"] or P["legR"]) else 0
        if P["atk"] is not None:
            stride = 2
        sgn = 1 if P["legL"] else -1
        for k, off in ((0, -stride * sgn), (1, stride * sgn)):
            x0 = 14 + off
            col = PANTS if k == 1 else {kk: tuple(max(0, c - 18) for c in vv) for kk, vv in PANTS.items()}
            shade_fill(L, rect(x0, 25, x0 + 2, FEET - 2), col)
            shade_fill(L, rrect(x0, FEET - 2, x0 + 4, FEET), SHOES)
    # 몸통 (평상복)
    if d == "right":
        torso = rrect(12, 17 + b, 19, 24 + b)
    else:
        torso = rrect(11, 17 + b, 20, 24 + b)
    shade_fill(L, torso, SHIRT)
    # 옷깃·단추 (앞모습)
    if d == "down":
        for (x, y) in ((14, 17 + b), (15, 18 + b), (16, 18 + b), (17, 17 + b)):
            L.put(x, y, SHIRT["4"])
        L.put(15, 20 + b, SHIRT["1"]); L.put(16, 22 + b, SHIRT["1"])
    # 허리띠
    for x in range(11 if d != "right" else 12, (21 if d != "right" else 20)):
        L.put(x, 23 + b, BELT["2"] if x % 3 else BELT["1"])
    if d == "down":
        L.put(15, 23 + b, BELT["4"]); L.put(16, 23 + b, BELT["4"])
    # 팔 (소매 + 손) — 공격 중 오른팔은 무기 쪽에서 그림
    arms = []
    if d in ("down", "up"):
        arms = [(-1, 9), (1, 21)]
    else:
        arms = [(1, 14)]
    for side, x0 in arms:
        if P["atk"] is not None and ((d == "down" and side == 1) or (d == "up" and side == -1) or d == "right"):
            continue
        swing = P["arm"] * side if d in ("down", "up") else 0
        sx = x0 + (P["arm"] * 2 if d == "right" else 0)
        y0 = 18 + b
        shade_fill(L, rrect(sx, y0, sx + 1, y0 + 3 + swing), SHIRT)
        shade_fill(L, rrect(sx, y0 + 4 + swing, sx + 1, y0 + 5 + swing), SKIN)
    # 머리
    if d == "down":
        stamp(L, FACE_DOWN, 9, 5 + b, SKIN, FACE_SPECIAL)
    elif d == "right":
        stamp(L, FACE_SIDE, 10, 5 + b, SKIN, FACE_SPECIAL)
        L.put(10, 11 + b, SKIN["1"])  # 귀 그림자
    else:
        stamp(L, FACE_UP, 9, 5 + b, SKIN, FACE_SPECIAL)
    return L


def attack_hand(d, P):
    """공격 단계별 손 위치와 칼 방향(끝점)"""
    b = P["bob"]
    a = P["atk"]
    if d == "down":
        return [((22, 14 + b), (27, 6)), ((22, 21 + b), (27, 29)), ((19, 24 + b), (10, 30))][a]
    if d == "right":
        return [((14, 16 + b), (8, 8)), ((19, 19 + b), (30, 17)), ((19, 22 + b), (28, 29))][a]
    return [((10, 15 + b), (5, 7)), ((15, 15 + b), (16, 1)), ((20, 15 + b), (27, 6))][a]


def draw_attack_arm(L, d, P, sleeve):
    (hx, hy), _ = attack_hand(d, P)
    sx = 21 if d == "down" else (15 if d == "right" else 10)
    sy = 18 + P["bob"]
    shade_fill(L, thick_line(sx, sy, hx, hy, 2), sleeve)
    shade_fill(L, rrect(hx - 1, hy - 1, hx + 1, hy + 1), SKIN)


# ---------------- 머리카락 ----------------
def draw_hair(d, P, style="spiky", colors=None):
    global HAIR
    _saved = HAIR
    HAIR = colors or HAIR
    try:
        return _draw_hair(d, P, style)
    finally:
        HAIR = _saved


def _draw_hair(d, P, style):
    L = Layer()
    b = P["bob"]
    hx, hy = 9, 5 + b
    m = set()
    if d == "down":
        m |= ellipse(hx + 7, hy + 3, 7.8, 5.0)
        m = {(x, y) for (x, y) in m if not (y >= hy + 2 and hx + 1 <= x <= hx + 12)}
        # 앞머리: 이마 위로 들쭉날쭉 (눈은 가리지 않게)
        for x in range(hx + 1, hx + 13):
            depth = [4, 5, 4, 3, 4, 5, 5, 4, 3, 4, 5, 4][x - hx - 1]
            for y in range(hy + 1, hy + depth):
                m.add((x, y))
        # 옆머리 (귀 앞으로 살짝)
        m |= rect(hx - 1, hy + 2, hx + 1, hy + 9) | rect(hx + 12, hy + 2, hx + 14, hy + 9)
        # 삐죽 머리
        for (x, y) in ((hx + 3, hy - 3), (hx + 4, hy - 3), (hx + 7, hy - 4), (hx + 8, hy - 3), (hx + 11, hy - 2), (hx + 1, hy - 1)):
            m |= {(x, y), (x, y + 1)}
    elif d == "right":
        m |= ellipse(hx + 5.5, hy + 3, 7.2, 5.0)
        m = {(x, y) for (x, y) in m if not (y >= hy + 2 and x >= hx + 6)}
        m |= rect(hx, hy + 2, hx + 4, hy + 10)       # 뒷머리
        m |= rect(hx + 5, hy + 2, hx + 5, hy + 6)    # 귀 앞 구레나룻
        for x in range(hx + 6, hx + 13):
            depth = [4, 5, 4, 3, 4, 3, 2][x - hx - 6]
            for y in range(hy + 1, hy + depth):
                m.add((x, y))
        for (x, y) in ((hx + 2, hy - 3), (hx + 5, hy - 4), (hx + 8, hy - 3), (hx - 1, hy + 1)):
            m |= {(x, y), (x, y + 1), (x + 1, y + 1)}
    else:
        m |= ellipse(hx + 7, hy + 5, 7.6, 7.4)
        for (x, y) in ((hx + 3, hy - 3), (hx + 7, hy - 4), (hx + 11, hy - 3), (hx + 1, hy - 1), (hx + 13, hy)):
            m |= {(x, y), (x, y + 1)}
        m -= {(x, y) for (x, y) in m if y > hy + 11}
    # --- 머리 모양 변형 ---
    if style == "long":
        if d == "down":
            m |= rect(hx - 1, hy + 2, hx + 1, hy + 13) | rect(hx + 12, hy + 2, hx + 14, hy + 13)
        elif d == "right":
            m |= rect(hx - 1, hy + 2, hx + 4, hy + 13)
        else:
            m |= rrect(hx, hy + 6, hx + 13, hy + 14)
    if style in ("short", "long", "bald", "pony"):
        m -= {(x, y) for (x, y) in m if y < hy - 1}       # 삐죽 머리 없음
    if style == "bald":
        if d == "down":
            m = rect(hx - 1, hy + 4, hx, hy + 8) | rect(hx + 13, hy + 4, hx + 14, hy + 8)
        elif d == "right":
            m = rrect(hx, hy + 4, hx + 3, hy + 9)
        else:
            m = rrect(hx, hy + 6, hx + 13, hy + 10)
    if style == "pony":
        if d == "right":
            m |= rrect(hx - 4, hy + 3, hx - 1, hy + 10)
        elif d == "up":
            m |= rrect(hx + 5, hy + 9, hx + 8, hy + 15)
        else:
            m |= rect(hx - 2, hy + 4, hx - 1, hy + 8) | rect(hx + 14, hy + 4, hx + 15, hy + 8)
    shade_fill(L, m, HAIR)
    # 머릿결 하이라이트 줄기
    strands = {"down": [(hx + 4, hy), (hx + 5, hy + 1), (hx + 9, hy - 1), (hx + 10, hy)],
               "right": [(hx + 4, hy), (hx + 5, hy + 1), (hx + 8, hy)],
               "up": [(hx + 4, hy + 2), (hx + 5, hy + 3), (hx + 9, hy + 1), (hx + 10, hy + 2), (hx + 7, hy + 6)]}[d]
    for (x, y) in strands:
        if (x, y) in L.px:
            L.put(x, y, HAIR["4"])
    return L


# ---------------- 갑옷: 가죽옷 ----------------
def draw_leather(d, P):
    L = Layer()
    b = P["bob"]
    if d == "right":
        shade_fill(L, rrect(12, 17 + b, 19, 22 + b), LEATHER)
        shade_fill(L, rrect(13, 16 + b, 17, 18 + b), LEATHER)  # 어깨
    else:
        shade_fill(L, rrect(11, 17 + b, 20, 22 + b), LEATHER)
        for sx in (9, 20):
            shade_fill(L, rrect(sx, 16 + b, sx + 2, 18 + b), LEATHER)  # 어깨받이
    if d == "down":
        # 가슴 끈과 버클
        for (x, y) in line_pts(12, 17 + b, 19, 22 + b):
            L.put(x, y, STRAP["2"])
        L.put(16, 19 + b, STRAP["4"]); L.put(15, 20 + b, STRAP["4"])
        for x in range(13, 19, 2):
            L.put(x, 22 + b, LEATHER["1"])  # 바느질
    elif d == "up":
        for (x, y) in line_pts(12, 22 + b, 19, 17 + b):
            L.put(x, y, STRAP["2"])
    else:
        for y in range(18 + b, 22 + b):
            L.put(16, y, STRAP["2"])
    return L


# ---------------- 갑옷: 철 갑옷 ----------------
def draw_iron(d, P):
    L = Layer()
    b = P["bob"]
    if d == "right":
        shade_fill(L, rrect(12, 17 + b, 19, 23 + b), STEEL)
        shade_fill(L, ellipse(15.5, 17.5 + b, 3.2, 2.2), STEEL)        # 어깨 판
        for y in (19 + b, 21 + b):
            for x in range(13, 19):
                L.put(x, y, STEEL["1"]) if x % 2 else None
    else:
        shade_fill(L, rrect(11, 17 + b, 20, 23 + b), STEEL)
        for cx in (9.5, 21.5):
            shade_fill(L, ellipse(cx, 17.5 + b, 2.6, 2.0), STEEL)       # 둥근 어깨 판
        if d == "down":
            for y in range(18 + b, 23 + b):
                L.put(15, y, STEEL["1"]); L.put(16, y, STEEL["3"])     # 가운데 이음새
            for (x, y) in ((12, 18 + b), (19, 18 + b), (12, 22 + b), (19, 22 + b)):
                L.put(x, y, GOLD["3"])                                  # 리벳
            for x in range(12, 20):
                L.put(x, 21 + b, STEEL["1"])
        else:
            for x in range(12, 20):
                L.put(x, 20 + b, STEEL["1"])
    return L


# ---------------- 무기 ----------------
WEAPONS = {
    "wooden_sword": dict(blade=WOOD, guard=WOOD, grip=SHOES, length=10),
    "iron_sword": dict(blade=STEEL, guard=GOLD, grip=SHOES, length=11),
}


def draw_weapon(d, P, kind, sleeve):
    L = Layer()
    wpn = WEAPONS[kind]
    b = P["bob"]
    if P["atk"] is None:
        # 등에 멘 칼
        if d == "down":
            shade_fill(L, thick_line(20, 15 + b, 24, 10 + b, 2), wpn["blade"])
            shade_fill(L, thick_line(19, 13 + b, 22, 16 + b, 1), wpn["guard"])
        elif d == "right":
            shade_fill(L, thick_line(9, 26 + b, 14, 12 + b, 2), wpn["blade"])
            shade_fill(L, thick_line(12, 14 + b, 16, 14 + b, 1), wpn["guard"])
            shade_fill(L, thick_line(14, 12 + b, 15, 10 + b, 1), wpn["grip"])
        else:
            shade_fill(L, thick_line(11, 27 + b, 20, 13 + b, 2), wpn["blade"])
            shade_fill(L, thick_line(18, 13 + b, 22, 15 + b, 1), wpn["guard"])
            shade_fill(L, thick_line(20, 12 + b, 22, 10 + b, 1), wpn["grip"])
        return L
    (hx, hy), (tx, ty) = attack_hand(d, P)
    shade_fill(L, thick_line(hx, hy, tx, ty, 2), wpn["blade"])
    # 날 끝 반짝
    L.put(tx, ty, wpn["blade"]["4"])
    # 손잡이 가로대
    ang = math.atan2(ty - hy, tx - hx)
    gx, gy = math.cos(ang + math.pi / 2) * 2, math.sin(ang + math.pi / 2) * 2
    shade_fill(L, thick_line(round(hx - gx), round(hy - gy), round(hx + gx), round(hy + gy), 1), wpn["guard"])
    # 공격하는 팔도 이 레이어에 (무기와 같은 순서로 그려지도록)
    draw_attack_arm(L, d, P, sleeve)
    return L


# ---------------- 망토 ----------------
def draw_cape(d, P, job):
    L = Layer()
    p = CAPES[job]
    b = P["bob"]
    sway = 1 if (P["legL"] or P["legR"]) else 0
    if d == "down":
        m = rect(10, 17 + b, 21, 27) - rect(12, 25, 19, 27)
        shade_fill(L, m, p)
    elif d == "right":
        m = set()
        for y in range(17 + b, 29):
            w = 3 + (y - 17) // 4
            for x in range(12 - w - sway, 13):
                m.add((x, y))
        shade_fill(L, m, p)
    else:
        m = rrect(10, 16 + b, 21, 28)
        shade_fill(L, m, p)
        for y in range(19 + b, 28, 1):
            L.put(13, y, p["1"]); L.put(18, y, p["1"])  # 주름
        for x in range(10, 22):
            L.put(x, 16 + b, p["4"]) if (x, 16 + b) in L.px else None
    return L


# ---------------- 장신구: 자갈 마을의 증표 ----------------
def draw_token(d, P):
    L = Layer()
    if d != "down":
        return L
    b = P["bob"]
    for (x, y) in line_pts(13, 17 + b, 15, 19 + b) + line_pts(18, 17 + b, 16, 19 + b):
        L.put(x, y, (150, 60, 60, 255))
    shade_fill(L, rrect(15, 19 + b, 16, 20 + b), GOLD, outline=True)
    return L


# ---------------- 수염·앞치마 (NPC용) ----------------
def draw_beard(L, d, P, colors):
    if d == "up":
        return
    b = P["bob"]
    if d == "down":
        m = rect(12, 15 + b, 19, 18 + b) - {(12, 18 + b), (19, 18 + b), (12, 15 + b), (19, 15 + b)}
        m -= {(15, 15 + b), (16, 15 + b)}   # 입
    else:
        m = rect(17, 15 + b, 21, 18 + b) - {(21, 18 + b), (17, 15 + b)}
    shade_fill(L, m, colors)


def draw_apron(L, d, P, colors):
    if d == "up":
        return
    b = P["bob"]
    m = rrect(12, 19 + b, 19, 26) if d == "down" else rrect(15, 19 + b, 19, 26)
    shade_fill(L, m, colors)


# ---------------- 시트 만들기 ----------------
def build_sheet(draw):
    """draw(direction, pose) → Layer. 왼쪽 줄은 오른쪽을 좌우 반전."""
    sheet = Image.new("RGBA", (W * 9, H * 4), (0, 0, 0, 0))
    for i, P in enumerate(poses()):
        for d in ("down", "right", "up"):
            im = draw(d, P).image()
            sheet.alpha_composite(im, (i * W, DIRS.index(d) * H))
            if d == "right":
                sheet.alpha_composite(im.transpose(Image.FLIP_LEFT_RIGHT), (i * W, DIRS.index("left") * H))
    return sheet


# NPC: 몸 색·머리 모양을 바꿔 한 장(대기 한 칸 × 4방향 = 128x32)으로
NPCS = {
    "mom": dict(shirt=pal((80, 30, 60), (150, 60, 104), (186, 88, 134), (214, 124, 164), (236, 168, 196)),
                pants=pal((70, 30, 54), (130, 56, 96), (160, 76, 120), (186, 104, 146), (206, 140, 170)),
                hair=pal((70, 30, 20), (126, 56, 34), (164, 80, 46), (196, 110, 64), (226, 150, 96)), style="long"),
    "dad": dict(shirt=pal((40, 52, 28), (82, 104, 54), (108, 134, 72), (138, 164, 96), (176, 198, 130)),
                pants=pal((44, 34, 24), (80, 64, 46), (104, 84, 60), (128, 106, 78), (150, 128, 96)),
                hair=pal((36, 26, 20), (64, 46, 34), (86, 62, 44), (110, 82, 58), (140, 108, 80)), style="short", beard=True),
    "neighbor": dict(shirt=pal((90, 40, 20), (176, 90, 48), (214, 120, 66), (236, 156, 96), (250, 196, 140)),
                     hair=pal((110, 80, 20), (196, 156, 60), (230, 194, 90), (246, 222, 130), (255, 244, 190)), style="pony"),
    "elder": dict(shirt=pal((50, 34, 76), (96, 70, 136), (124, 94, 168), (154, 124, 196), (190, 164, 222)),
                  pants=pal((50, 34, 76), (96, 70, 136), (124, 94, 168), (154, 124, 196), (190, 164, 222)),
                  hair=pal((120, 120, 130), (200, 200, 206), (232, 232, 236), (246, 246, 250), (255, 255, 255)), style="bald", beard=True),
    "shopkeeper": dict(shirt=pal((90, 86, 76), (200, 194, 176), (226, 220, 202), (242, 238, 224), (255, 255, 248)),
                       hair=pal((30, 22, 18), (56, 42, 32), (76, 58, 44), (98, 78, 60), (124, 102, 80)), style="short",
                       apron=pal((24, 50, 70), (52, 100, 136), (72, 128, 168), (100, 156, 196), (140, 190, 222)), beard=True),
    "spirit": dict(shirt=pal((140, 80, 20), (220, 150, 60), (246, 186, 90), (255, 216, 130), (255, 240, 190)),
                   pants=pal((140, 80, 20), (220, 150, 60), (246, 186, 90), (255, 216, 130), (255, 240, 190)),
                   skin=pal((150, 100, 50), (240, 196, 130), (255, 220, 160), (255, 236, 190), (255, 248, 220)),
                   hair=pal((170, 130, 60), (250, 220, 150), (255, 236, 180), (255, 246, 210), (255, 255, 240)), style="long"),
}


def npc_sheet(spec):
    P = poses()[0]
    out = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    for i, d in enumerate(DIRS):
        dd = "right" if d == "left" else d
        L = draw_body(dd, P, spec.get("shirt"), spec.get("pants"), spec.get("skin"))
        if spec.get("apron"):
            draw_apron(L, dd, P, spec["apron"])
        im = L.image()
        if spec.get("beard"):
            B = Layer(); draw_beard(B, dd, P, spec["hair"]); im.alpha_composite(B.image())
        im.alpha_composite(draw_hair(dd, P, spec["style"], spec["hair"]).image())
        if d == "left":
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
        out.alpha_composite(im, (i * W, 0))
    return out


def main(out):
    os.makedirs(out, exist_ok=True)

    def body(d, P):
        L = draw_body(d, P)
        return L
    build_sheet(body).save(os.path.join(out, "body.png"))
    build_sheet(draw_hair).save(os.path.join(out, "hair.png"))
    build_sheet(draw_leather).save(os.path.join(out, "armor_leather_armor.png"))
    build_sheet(draw_iron).save(os.path.join(out, "armor_iron_armor.png"))
    for kind in WEAPONS:
        build_sheet(lambda d, P, k=kind: draw_weapon(d, P, k, SHIRT)).save(os.path.join(out, "weapon_%s.png" % kind))
    # 공격할 때 무기가 없으면 맨손 팔만
    def fist(d, P):
        L = Layer()
        if P["atk"] is not None:
            draw_attack_arm(L, d, P, SHIRT)
        return L
    build_sheet(fist).save(os.path.join(out, "weapon_none.png"))
    for job in CAPES:
        build_sheet(lambda d, P, j=job: draw_cape(d, P, j)).save(os.path.join(out, "cape_%s.png" % job))
    build_sheet(draw_token).save(os.path.join(out, "acc_adult_token.png"))
    npc_dir = os.path.join(out, "npcs")
    os.makedirs(npc_dir, exist_ok=True)
    for name, spec in NPCS.items():
        npc_sheet(spec).save(os.path.join(npc_dir, name + ".png"))
    print("ok")


if __name__ == "__main__":
    main(sys.argv[1])
