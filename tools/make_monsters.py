"""2.5D 도트 몬스터·자연물 생성기 (pixel3d 사용)
몬스터: 4프레임 말랑말랑(스쿼시) 애니메이션 / 자연물: 큰 나무(32x48), 바위, 덤불, 그림자
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from pixel3d import ell, box, render, project, rot_x, rot_y, rot_z
from PIL import Image, ImageDraw
out = sys.argv[1]


def eyes2(img, pts, color=(30, 24, 30, 255)):
    px = img.load()
    for (x, y) in pts:
        x, y = int(round(x)), int(round(y))
        for dx, dy in ((0, 0), (0, 1), (1, 0), (1, 1)):
            if 0 <= x + dx < img.width and 0 <= y + dy < img.height:
                px[x + dx, y + dy] = color
        px[x, y] = (255, 255, 255, 255)


def slime_sheet(name, color, size=1.0, crown=False, frames=4, W=24, H=22, spikes=False):
    img = Image.new("RGBA", (W * frames, H), (0, 0, 0, 0))
    origin = (W / 2, H - 2)
    for f in range(frames):
        t = f / frames * math.tau
        sq = 1.0 + 0.12 * math.sin(t)          # 위아래 늘었다 줄었다
        r = 6.2 * size
        parts = [ell((0, r * 0.82 / sq * sq * sq, 0), (r / sq ** 0.5, r * 0.82 * sq, r / sq ** 0.5), color, shine=0.9)]
        # 안쪽 하이라이트 방울
        parts.append(ell((-r * 0.38, r * 1.12 * sq, r * 0.62), (r * 0.2, r * 0.14, r * 0.14), (250, 255, 245), shine=0.0))
        if spikes:
            for a in range(5):
                ang = a / 5 * math.tau
                parts.append(ell((math.cos(ang) * r * 0.75, r * 0.9 * sq + 1.5, math.sin(ang) * r * 0.75), (r * 0.25, r * 0.35, r * 0.25), tuple(int(c * 0.8) for c in color), shine=0.5))
        if crown:
            gold = (236, 190, 60)
            top = r * 1.62 * sq
            parts.append(ell((0, top + 0.6, 0), (r * 0.42, r * 0.1, r * 0.42), gold, shine=0.9))
            for a in range(5):
                ang = a / 5 * math.tau + 0.3
                parts.append(ell((math.cos(ang) * r * 0.36, top + 2.6, math.sin(ang) * r * 0.36), (0.8, 2.0, 0.8), gold, shine=0.9))
            parts.append(ell((0, top + 0.9, r * 0.42), (0.9, 0.9, 0.5), (220, 50, 70), shine=0.9))
        fr = render(parts, W, H, origin)
        ey = r * 0.95 * sq
        pts = []
        for s in (-1, 1):
            x, y = project((s * r * 0.33, ey, r * 0.92), origin)
            pts.append((x, y))
        eyes2(fr, pts)
        img.alpha_composite(fr, (f * W, 0))
    img.save(os.path.join(out, "enemies", name + ".png"))
    print("saved", name)


def golem_sheet():
    W, H = 36, 40
    frames = 4
    img = Image.new("RGBA", (W * frames, H), (0, 0, 0, 0))
    origin = (W / 2, H - 3)
    stone = (138, 126, 112)
    dark = (104, 94, 84)
    glow = (255, 170, 60)
    for f in range(frames):
        t = f / frames * math.tau
        bob = 0.6 * math.sin(t)
        sw = 0.25 * math.sin(t)
        p = []
        for s in (-1, 1):
            p.append(box((s * 3.4, 3.2, 0), (2.4, 3.2, 2.6), dark, rot=rot_x(s * sw)))
        p.append(box((0, 12 + bob, 0), (7.0, 5.6, 4.6), stone, rot=rot_y(0.0)))
        p.append(box((0, 12.5 + bob, 4.7), (2.2, 2.2, 0.3), glow, shine=0.0))
        p.append(box((0, 20 + bob, 0.4), (3.8, 3.0, 3.4), stone))
        for s in (-1, 1):
            p.append(box((s * 9.2, 11 + bob, 0.4), (2.4, 5.4, 2.6), dark, rot=rot_x(-s * sw * 1.4)))
            p.append(ell((s * 7.4, 17.2 + bob, 0), (2.8, 2.4, 2.8), stone, shine=0.2))
        fr = render(p, W, H, origin)
        px = fr.load()
        for s in (-1, 1):
            x, y = project((s * 1.6, 20.5 + bob, 3.9), origin)
            x, y = int(round(x)), int(round(y))
            px[x, y] = (255, 210, 120, 255)
        img.alpha_composite(fr, (f * W, 0))
    img.save(os.path.join(out, "enemies", "golem.png"))
    print("saved golem")


def nature():
    # 큰 나무 32x48 (두 종류)
    for k, (leaf, trunk) in enumerate([((70, 138, 64), (112, 74, 46)), ((88, 150, 70), (120, 82, 50))]):
        parts = [box((0, 5, 0), (2.0, 5.0, 2.0), trunk),
                 ell((0, 0.8, 0), (3.4, 1.0, 3.0), trunk)]
        blobs = [(0, 20, 0, 9.5), (-6, 16, 2, 6.0), (6, 16.5, 1.5, 6.2), (-3, 25, -1, 6.5), (4, 24.5, -2, 6.2), (0, 15, 5, 5.5)]
        if k == 1:
            blobs = [(0, 18, 0, 8.6), (-5, 14, 3, 5.6), (5.5, 14.5, 2, 5.8), (0, 25, -1, 6.8), (0, 13, 6, 4.8)]
        for (x, y, z, r) in blobs:
            parts.append(ell((x, y, z), (r, r * 0.9, r), leaf))
        img = render(parts, 32, 48, (16, 44))
        sh = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
        ImageDraw.Draw(sh).ellipse([5, 40, 26, 47], fill=(20, 16, 30, 90))
        sh.alpha_composite(img)
        sh.save(os.path.join(out, "nature", "tree%d.png" % k))
    # 바위 / 덤불 16x16
    rock = render([ell((0, 3.6, 0), (6.4, 4.4, 5.0), (136, 132, 140), shine=0.2), ell((2.6, 6.4, -1), (3.2, 2.8, 3.0), (150, 146, 154))], 16, 16, (8, 14))
    rock.save(os.path.join(out, "nature", "rock.png"))
    bush = [ell((0, 4.4, 0), (6.6, 4.6, 5.4), (64, 128, 60)), ell((-3, 6.4, 2), (3.2, 3, 3), (80, 146, 70)), ell((3, 6.8, 1), (3.2, 3, 3), (76, 140, 66))]
    for (x, y, z) in ((-2, 7.4, 4.2), (2.6, 5.2, 4.6), (0.4, 9.2, 2.4)):
        bush.append(ell((x, y, z), (0.9, 0.9, 0.9), (214, 60, 70), shine=0.6))
    render(bush, 16, 16, (8, 14)).save(os.path.join(out, "nature", "bush.png"))


def shadows():
    # 바닥 그림자 (반투명 타원) — 크기별
    for name, (w, h) in {"shadow_s": (12, 5), "shadow_m": (18, 7), "shadow_l": (30, 11), "shadow_xl": (70, 18)}.items():
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        px = im.load()
        for y in range(h):
            for x in range(w):
                d = ((x + 0.5 - w / 2) / (w / 2)) ** 2 + ((y + 0.5 - h / 2) / (h / 2)) ** 2
                if d <= 1:
                    px[x, y] = (20, 16, 30, int(110 * (1 - d * 0.55)))
        im.save(os.path.join(out, "effects", name + ".png"))


if __name__ == "__main__":
    os.makedirs(os.path.join(out, "nature"), exist_ok=True)
    slime_sheet("slime", (96, 196, 84))
    slime_sheet("rock_slime", (150, 132, 112), spikes=True)
    slime_sheet("hard_slime", (104, 112, 140), spikes=True)
    slime_sheet("king_slime", (96, 196, 84), size=2.0, crown=True, W=44, H=44)
    golem_sheet()
    nature()
    shadows()
