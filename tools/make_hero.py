"""
2.5D 도트 용사 (그리고 같은 뼈대를 쓰는 NPC) 생성기.
몸을 타원체·상자로 만든 작은 3D 인형을 포즈별로 움직여 pixel3d로 찍는다.
출력: 32x32 칸, 줄 = 방향(아래·왼쪽·오른쪽·위), 칸 = 대기2 + 걷기4 + 공격3
"""
import sys, math, os
sys.path.insert(0, os.path.dirname(__file__))
from pixel3d import ell, box, transform, render, project, rot_x, rot_y, rot_z
from PIL import Image

W = H = 32
ORIGIN = (16, 29)       # 발밑이 찍힐 픽셀
YAWS = {"down": 0.0, "right": math.pi / 2, "up": math.pi}

# ---------------- 외형 (팔레트·장비) ----------------
LOOKS = {
    "hero": dict(skin=(242, 196, 158), hair=(104, 66, 44), top=(52, 92, 168), pants=(66, 58, 60), boots=(96, 62, 40),
                 belt=(150, 100, 52), cape=(178, 46, 50), scarf=(236, 168, 58), blade=(214, 220, 232), hilt=(224, 182, 70),
                 cape_on=True, sword=True, armor=None, shield=False, hair_style="spiky"),
    "granite_knight": dict(skin=(242, 196, 158), hair=(104, 66, 44), top=(128, 128, 136), pants=(70, 70, 80), boots=(84, 84, 96),
                 belt=(90, 70, 50), cape=(52, 86, 160), scarf=(236, 168, 58), blade=(214, 220, 232), hilt=(224, 182, 70),
                 cape_on=True, sword=True, armor=(168, 166, 172), shield=True, hair_style="spiky"),
    "steel_fighter": dict(skin=(236, 188, 150), hair=(104, 66, 44), top=(70, 74, 92), pants=(56, 52, 60), boots=(60, 60, 70),
                 belt=(160, 60, 50), cape=(190, 50, 40), scarf=(200, 70, 50), blade=(225, 230, 240), hilt=(90, 90, 100),
                 cape_on=True, sword=True, armor=(96, 100, 120), shield=False, hair_style="spiky", big_sword=True),
    "quartz_mage": dict(skin=(242, 196, 158), hair=(104, 66, 44), top=(118, 82, 170), pants=(90, 70, 130), boots=(80, 60, 110),
                 belt=(220, 200, 240), cape=(235, 230, 245), scarf=(170, 130, 230), blade=(206, 186, 255), hilt=(160, 120, 220),
                 cape_on=True, sword=True, armor=None, shield=False, hair_style="spiky", robe=True),
    # NPC들
    "mom": dict(skin=(244, 200, 164), hair=(150, 72, 44), top=(178, 84, 124), pants=(150, 70, 110), boots=(110, 70, 50),
                belt=(240, 230, 210), cape=None, scarf=None, cape_on=False, sword=False, armor=None, hair_style="long", robe=True),
    "dad": dict(skin=(226, 176, 140), hair=(72, 52, 38), top=(108, 132, 70), pants=(88, 70, 52), boots=(84, 56, 36),
                belt=(130, 86, 46), cape=None, scarf=None, cape_on=False, sword=False, armor=None, hair_style="short", beard=True),
    "bori": dict(skin=(246, 204, 168), hair=(226, 186, 84), top=(206, 110, 64), pants=(110, 80, 60), boots=(120, 80, 50),
                 belt=(120, 80, 45), cape=None, scarf=(240, 230, 200), cape_on=False, sword=False, armor=None, hair_style="pony", small=True),
    "elder": dict(skin=(226, 182, 150), hair=(236, 236, 236), top=(110, 80, 150), pants=(110, 80, 150), boots=(80, 60, 50),
                  belt=(210, 172, 80), cape=None, scarf=None, cape_on=False, sword=False, armor=None, hair_style="bald", beard=True, robe=True, beard_color=(240, 240, 240)),
    "shopkeeper": dict(skin=(232, 186, 150), hair=(60, 44, 34), top=(220, 214, 196), pants=(80, 66, 56), boots=(84, 56, 36),
                       belt=(70, 120, 160), cape=None, scarf=None, cape_on=False, sword=False, armor=None, hair_style="short", apron=(70, 120, 160), mustache=True),
    "spirit": dict(skin=(255, 214, 150), hair=(255, 236, 170), top=(232, 160, 70), pants=(200, 130, 60), boots=(180, 110, 50),
                   belt=(255, 240, 180), cape=(255, 220, 140), scarf=None, cape_on=True, sword=False, armor=None, hair_style="long", robe=True),
}


def person(L, pose):
    """포즈(pose)에 맞춰 사람 모양 부품 목록을 만든다. 정면(+z)을 바라보는 기준."""
    P = []
    bob = pose.get("bob", 0.0)
    lean = pose.get("lean", 0.0)
    sc = 0.86 if L.get("small") else 1.0
    # --- 다리 ---
    for side, swing in ((-1, pose.get("leg", 0.0)), (1, -pose.get("leg", 0.0))):
        hip = (side * 2.1, 7.2, 0)
        leg = [ell((side * 2.1, 4.6, 0), (1.75, 3.4, 1.8), L["pants"], group="leg%d" % side),
               ell((side * 2.2, 1.6, 0.7), (1.9, 1.6, 2.5), L["boots"], group="leg%d" % side)]
        P += transform(leg, rot_x(swing), pivot=hip)
    # --- 몸통 (긴 옷이면 치마처럼) ---
    body = []
    if L.get("robe"):
        body.append(ell((0, 7.0, 0), (4.6, 4.6, 3.6), L["top"], group="body"))
    body.append(ell((0, 10.6 + bob, 0), (4.5, 4.5, 3.3), L["top"], group="body"))
    if L.get("armor"):
        body.append(ell((0, 11.4 + bob, 0.6), (4.3, 3.6, 3.0), L["armor"], group="body", shine=0.5))
        for side in (-1, 1):
            body.append(ell((side * 4.6, 13.6 + bob, 0), (2.2, 1.7, 2.2), L["armor"], group="pauldron%d" % side, shine=0.6))
    if L.get("apron"):
        body.append(ell((0, 8.8 + bob, 1.6), (3.6, 3.8, 2.0), L["apron"], group="body"))
    body.append(ell((0, 8.0 + bob, 0), (4.7, 0.9, 3.5), L["belt"], group="belt", shine=0.2))
    if L.get("scarf"):
        body.append(ell((0, 14.6 + bob, 0.4), (3.8, 1.5, 3.2), L["scarf"], group="scarf"))
    P += transform(body, rot_x(lean), pivot=(0, 7, 0))
    # --- 망토 (등 뒤 얇은 판, 펄럭임) ---
    if L.get("cape_on"):
        flap = pose.get("cape", 0.0)
        cape = [box((0, 8.8, -3.4), (4.4, 5.6, 0.45), L["cape"], group="cape"),
                box((0, 3.8, -4.6), (4.8, 1.4, 0.45), L["cape"], group="cape", rot=rot_x(-0.35))]
        P += transform(cape, rot_x(-0.18 - flap), pivot=(0, 14.5 + bob, -3.0))
    # --- 팔 ---
    arms = {}
    for side in (-1, 1):
        swing = pose.get("arm_r" if side == 1 else "arm_l", 0.0)
        sh = (side * 5.0, 13.6 + bob, 0)
        arm = [ell((side * 5.2, 11.0 + bob, 0), (1.55, 3.3, 1.55), L["armor"] if L.get("armor") else L["top"], group="arm%d" % side),
               ell((side * 5.3, 7.7 + bob, 0.2), (1.45, 1.45, 1.45), L["skin"], group="hand%d" % side)]
        raise_ = pose.get("raise_r", 0.0) if side == 1 else 0.0
        R = rot_x(swing) @ rot_z(side * raise_)
        P += transform(arm, R, pivot=sh)
        arms[side] = (R, sh)
    # --- 방패 (화강 기사) ---
    if L.get("shield"):
        R, sh = arms[-1]
        P += transform([box((-6.6, 9.2 + bob, 0.8), (0.6, 3.2, 2.6), (150, 150, 160), group="shield", shine=0.6),
                        ell((-7.1, 9.2 + bob, 0.8), (0.4, 1.0, 1.0), (224, 182, 70), group="shield", shine=0.8)], R, pivot=sh)
    # --- 머리 ---
    hb = bob * 1.15
    head = [ell((0, 19.6 + hb, 0.3), (6.0, 5.7, 5.5), L["skin"], group="head")]
    hs = L["hair_style"]
    hair = L["hair"]
    if hs != "bald":
        head.append(ell((0, 22.0 + hb, -1.5), (6.3, 4.9, 4.7), hair, group="hair"))
        # 앞머리 (이마만 살짝 덮도록)
        if hs in ("spiky", "short", "pony"):
            for (x, y, z, r) in ((-3.0, 23.4, 3.2, 1.8), (0.4, 24.0, 3.6, 1.9), (3.4, 23.2, 3.0, 1.7), (-5.5, 21.0, 0.8, 1.6), (5.5, 21.0, 0.8, 1.6)):
                head.append(ell((x, y + hb, z), (r, r * 0.9, r * 0.7), hair, group="hair"))
        if hs == "spiky":
            for (x, y, z) in ((-2.6, 26.4, -1.4), (1.8, 26.8, -2.2), (4.4, 25.2, -3.0), (-4.8, 24.6, -3.0), (0.0, 25.0, -5.6)):
                head.append(ell((x, y + hb, z), (1.6, 1.7, 1.6), hair, group="hair"))
        if hs == "long":
            head.append(ell((0, 17.2 + hb, -2.6), (6.0, 6.0, 3.2), hair, group="hair"))
            for x in (-4.6, 4.6):
                head.append(ell((x, 18.4 + hb, 1.2), (1.9, 4.6, 2.2), hair, group="hair"))
        if hs == "pony":
            head.append(ell((0, 20.5 + hb, -6.6), (2.0, 3.6, 2.0), hair, group="hair"))
    else:
        for x in (-5.4, 5.4):
            head.append(ell((x, 19.6 + hb, -0.6), (1.8, 2.2, 2.4), hair, group="hair"))
    if L.get("beard"):
        bc = L.get("beard_color", hair)
        head.append(ell((0, 16.2 + hb, 3.2), (3.6, 2.8, 2.4), bc, group="beard"))
    P += head
    # --- 검 ---
    if L.get("sword"):
        big = L.get("big_sword")
        blen = 7.2 if big else 6.0
        if pose.get("attack") is None:
            # 등에 멘 검: 손잡이가 오른쪽 어깨 위로
            sw = [box((0, blen, 0), (0.75 if big else 0.55, blen, 0.35), L["blade"], group="sword", shine=0.9),
                  box((0, 0, 0), (2.0, 0.55, 0.6), L["hilt"], group="sword", shine=0.7),
                  box((0, -2.0, 0), (0.6, 1.6, 0.6), (80, 56, 40), group="sword")]
            P += transform(sw, rot_z(-0.75) , offset=(3.0, 11.0 + bob, -4.3))
        else:
            # 손에 든 검: 오른손에서 앞으로 휘두름
            R, sh = arms[1]
            hand = R @ (__import__("numpy").array((5.3, 7.7 + bob, 0.2)) - __import__("numpy").array(sh)) + __import__("numpy").array(sh)
            a = pose["attack"]
            sw = [box((0, blen + 1, 0), (0.75 if big else 0.55, blen, 0.35), L["blade"], group="sword", shine=0.9),
                  box((0, 0.6, 0), (2.0, 0.55, 0.6), L["hilt"], group="sword", shine=0.7)]
            P += transform(sw, rot_y(a[0]) @ rot_x(a[1]), offset=tuple(hand))
    return P


def eyes(img, L, yaw, pose, direction):
    """얼굴을 그린다 (눈·볼). 아래/옆을 볼 때만."""
    if direction == "up":
        return
    hb = pose.get("bob", 0.0) * 1.15
    px = img.load()
    eye_c = (34, 26, 34, 255)
    hl = (255, 255, 255, 255)
    if direction == "down":
        for side in (-1, 1):
            x, y = project((side * 2.4, 19.8 + hb, 5.6), ORIGIN, yaw)
            x, y = int(round(x)), int(round(y))
            px[x, y] = hl          # 눈 반짝임
            px[x, y + 1] = eye_c
            px[x - side if False else x, y + 1] = eye_c
            px[x + (1 if side < 0 else -1), y] = eye_c
            px[x + (1 if side < 0 else -1), y + 1] = eye_c
        # 볼
        for side in (-1, 1):
            x, y = project((side * 3.6, 17.9 + hb, 4.9), ORIGIN, yaw)
            c = px[int(round(x)), int(round(y))]
            if c[3]:
                px[int(round(x)), int(round(y))] = (min(255, c[0] + 10), max(0, c[1] - 30), max(0, c[2] - 20), 255)
    else:  # 오른쪽을 볼 때 (왼쪽은 좌우 반전)
        x, y = project((3.0, 19.8 + hb, 4.8), ORIGIN, yaw)
        x, y = int(round(x)), int(round(y))
        px[x, y] = hl
        px[x, y + 1] = eye_c
        px[x - 1, y] = eye_c
        px[x - 1, y + 1] = eye_c


def poses():
    """대기 2 + 걷기 4 + 공격 3"""
    out = []
    out.append(dict(bob=0.0, cape=0.0))
    out.append(dict(bob=-0.45, cape=0.05))
    for i in range(4):
        ph = i * math.pi / 2
        s = math.sin(ph)
        out.append(dict(leg=0.55 * s, arm_l=0.45 * s, arm_r=-0.45 * s, bob=0.45 * abs(math.cos(ph)) - 0.2,
                        cape=0.22 + 0.12 * abs(s)))
    out.append(dict(attack=(0.0, -2.9), raise_r=0.35, arm_r=-2.7, lean=-0.12, cape=0.05, leg=0.2))   # 치켜듦
    out.append(dict(attack=(0.0, -1.3), raise_r=0.1, arm_r=-1.3, lean=0.15, cape=0.4, leg=-0.3))    # 내려침
    out.append(dict(attack=(0.0, -0.4), raise_r=0.0, arm_r=-0.5, lean=0.2, cape=0.35, leg=-0.35))   # 마무리
    return out


def sheet(look_name):
    L = LOOKS[look_name]
    ps = poses()
    rows = {"down": 0, "left": 1, "right": 2, "up": 3}
    img = Image.new("RGBA", (W * len(ps), H * 4), (0, 0, 0, 0))
    for d in ("down", "right", "up"):
        yaw = YAWS[d]
        for i, pose in enumerate(ps):
            parts = person(L, pose)
            fr = render(parts, W, H, ORIGIN, yaw=yaw)
            eyes(fr, L, yaw, pose, d)
            img.alpha_composite(fr, (i * W, rows[d] * H))
            if d == "right":
                img.alpha_composite(fr.transpose(Image.FLIP_LEFT_RIGHT), (i * W, rows["left"] * H))
    return img


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    names = sys.argv[2:] if len(sys.argv) > 2 else list(LOOKS.keys())
    for n in names:
        im = sheet(n)
        im.save(os.path.join(out, n + ".png"))
        print("saved", n)
