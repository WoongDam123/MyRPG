"""
pixel3d — 작은 3D 모형을 2.5D 도트 그림으로 찍어 내는 렌더러.

모형은 타원체(ellipsoid)와 상자(box)로 만든다. 위에서 비스듬히(3/4 시점) 내려다보는
정사영 카메라로 한 픽셀에 광선 하나씩 쏘아 가장 앞의 면을 찾고,
왼쪽 위에서 오는 빛으로 명암 단계(램프)를 골라 칠한 뒤, 윤곽선과 경계선을 넣는다.

좌표: x = 오른쪽, y = 위, z = 화면 쪽(앞). 캐릭터는 +z 쪽을 바라보는 것이 기본(=아래 방향).
"""
import math
import warnings
import numpy as np
warnings.filterwarnings("ignore")
from PIL import Image

PITCH = math.radians(30)          # 카메라가 내려다보는 각도
LIGHT = np.array([-0.55, 0.78, 0.45])
LIGHT = LIGHT / np.linalg.norm(LIGHT)


def rot_x(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def _clamp(v):
    return max(0, min(255, int(round(v))))


def make_ramp(base, steps=5):
    """기본색 하나로 어두운 → 밝은 색 단계를 만든다. 어두운 쪽은 푸르게, 밝은 쪽은 따뜻하게(색상 이동)."""
    r, g, b = base
    out = []
    for i in range(steps):
        t = i / (steps - 1)            # 0 = 가장 어두움, 1 = 가장 밝음
        k = 0.42 + 0.78 * t
        cool = (1 - t) * 0.18
        warm = t * 0.10
        out.append((
            _clamp(r * k * (1 - cool * 0.6) + 255 * warm * 0.35),
            _clamp(g * k * (1 - cool * 0.25) + 255 * warm * 0.25),
            _clamp(b * k * (1 + cool * 0.55) + 255 * warm * 0.05),
        ))
    return out


class Part:
    def __init__(self, kind, center, size, color, rot=None, group=None, shine=0.0):
        self.kind = kind                       # "ell" 타원체 / "box" 상자
        self.c = np.array(center, dtype=float)
        self.s = np.array(size, dtype=float)   # 타원체: 반지름 / 상자: 반 크기
        self.R = rot if rot is not None else np.eye(3)
        self.ramp = make_ramp(color) if isinstance(color, tuple) else color
        self.group = group if group is not None else id(self)
        self.shine = shine                     # 금속 반짝임


def ell(center, radii, color, rot=None, group=None, shine=0.0):
    return Part("ell", center, radii, color, rot, group, shine)


def box(center, half, color, rot=None, group=None, shine=0.0):
    return Part("box", center, half, color, rot, group, shine)


def transform(parts, R, offset=(0, 0, 0), pivot=(0, 0, 0)):
    """부품들을 pivot 기준으로 회전 R 후 offset만큼 옮긴다 (팔 흔들기 등)."""
    pivot = np.array(pivot, dtype=float)
    out = []
    for p in parts:
        q = Part(p.kind, R @ (p.c - pivot) + pivot + np.array(offset, dtype=float), p.s, p.ramp, R @ p.R, p.group, p.shine)
        out.append(q)
    return out


def render(parts, w, h, origin_px, yaw=0.0, outline=(28, 20, 26), mirror=False, light=LIGHT):
    """부품 목록을 w×h 그림으로 찍는다. origin_px = 발밑(0,0,0)이 놓일 픽셀 위치."""
    Ry = rot_y(yaw)
    cp, sp = math.cos(PITCH), math.sin(PITCH)
    d = np.array([0.0, -sp, -cp])          # 광선 방향 (화면 안쪽)
    right = np.array([1.0, 0, 0])
    up = np.array([0.0, cp, -sp])
    ys, xs = np.mgrid[0:h, 0:w]
    u = (xs + 0.5 - origin_px[0])
    v = -(ys + 0.5 - origin_px[1])
    O = (u[..., None] * right + v[..., None] * up) - d * 200.0   # 각 픽셀 광선의 시작점
    depth = np.full((h, w), np.inf)
    color = np.zeros((h, w, 3))
    gid = np.full((h, w), -1, dtype=np.int64)
    shade_idx = np.zeros((h, w), dtype=int)
    part_of = np.full((h, w), -1)
    ramps = {}
    for idx, p in enumerate(parts):
        R = Ry @ p.R
        c = Ry @ p.c
        Rt = R.T
        o = (O - c) @ Rt.T          # 부품 기준 좌표
        dl = Rt @ d
        if p.kind == "ell":
            o2 = o / p.s
            d2 = dl / p.s
            a = d2 @ d2
            b = 2 * (o2 @ d2)
            cc = (o2 * o2).sum(-1) - 1
            disc = b * b - 4 * a * cc
            hit = disc >= 0
            t = np.where(hit, (-b - np.sqrt(np.maximum(disc, 0))) / (2 * a), np.inf)
            pl = o + np.where(hit, t, 0.0)[..., None] * dl
            nl = pl / (p.s ** 2)
        else:
            inv = 1.0 / np.where(np.abs(dl) < 1e-9, 1e-9, dl)
            t1 = (-p.s - o) * inv
            t2 = (p.s - o) * inv
            tmin = np.minimum(t1, t2).max(-1)
            tmax = np.maximum(t1, t2).min(-1)
            hit = tmax >= np.maximum(tmin, 0)
            t = np.where(hit, tmin, np.inf)
            axis = np.minimum(t1, t2).argmax(-1)
            nl = np.zeros_like(o)
            sign = -np.sign(np.take_along_axis(dl[None, None, :].repeat(h, 0).repeat(w, 1), axis[..., None], -1))[..., 0]
            for k in range(3):
                nl[..., k] = np.where(axis == k, sign, 0)
        n = nl @ R.T
        n = n / np.maximum(np.linalg.norm(n, axis=-1, keepdims=True), 1e-9)
        closer = hit & (t < depth)
        if not closer.any():
            continue
        diff = np.clip(n @ light, 0, 1)
        lum = 0.18 + 0.82 * diff
        spec = 0.0
        if p.shine:
            hv = light - d
            hv = hv / np.linalg.norm(hv)
            spec = np.clip(n @ hv, 0, 1) ** 24 * p.shine
        lum = np.nan_to_num(np.clip(lum + spec, 0, 1.0))
        si = np.clip((lum * len(p.ramp)).astype(int), 0, len(p.ramp) - 1)
        depth = np.where(closer, t, depth)
        gid = np.where(closer, p.group if isinstance(p.group, int) else hash(p.group) & 0xFFFFFFF, gid)
        shade_idx = np.where(closer, si, shade_idx)
        ramps_key = idx
        ramps[ramps_key] = p.ramp
        color_layer = np.array(p.ramp)[si]
        color = np.where(closer[..., None], color_layer, color)
        part_of = np.where(closer, idx, part_of)
    if not np.isfinite(depth).any():
        return Image.new("RGBA", (w, h), (0, 0, 0, 0))
    filled = np.isfinite(depth)
    img = np.zeros((h, w, 4), dtype=np.uint8)
    img[..., :3] = color.astype(np.uint8)
    img[..., 3] = np.where(filled, 255, 0)
    # 부품 경계선: 옆 픽셀이 다른 무리(group)이고 훨씬 뒤에 있으면, 앞 픽셀을 한 단계 어둡게
    for dy, dx in ((0, 1), (1, 0), (0, -1), (-1, 0)):
        nb_g = np.roll(np.roll(gid, dy, 0), dx, 1)
        nb_d = np.roll(np.roll(depth, dy, 0), dx, 1)
        edge = filled & (nb_g != gid) & np.isfinite(nb_d) & (nb_d - depth > 2.2)
        for yy, xx in zip(*np.where(edge)):
            ramp = ramps[part_of[yy, xx]]
            k = max(0, shade_idx[yy, xx] - 2)
            img[yy, xx, :3] = ramp[k]
    # 바깥 윤곽선: 비어 있는 픽셀 중 옆에 그림이 있으면 어두운 색
    a = img[..., 3] > 0
    border = np.zeros_like(a)
    for dy, dx in ((0, 1), (1, 0), (0, -1), (-1, 0)):
        border |= np.roll(np.roll(a, dy, 0), dx, 1)
    border &= ~a
    for yy, xx in zip(*np.where(border)):
        # 이웃 색을 아주 어둡게 섞은 윤곽선 (색 있는 윤곽)
        cols = []
        for dy, dx in ((0, 1), (1, 0), (0, -1), (-1, 0)):
            y2, x2 = yy + dy, xx + dx
            if 0 <= y2 < h and 0 <= x2 < w and a[y2, x2]:
                cols.append(img[y2, x2, :3].astype(float))
        m = np.mean(cols, axis=0)
        img[yy, xx, :3] = (m * 0.28 + np.array(outline) * 0.72).astype(np.uint8)
        img[yy, xx, 3] = 255
    im = Image.fromarray(img, "RGBA").copy()
    if mirror:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    return im


def project(point, origin_px, yaw=0.0):
    """3D 점이 그림의 어느 픽셀에 찍히는지 (눈 같은 작은 장식을 그릴 때)."""
    p = rot_y(yaw) @ np.array(point, dtype=float)
    cp, sp = math.cos(PITCH), math.sin(PITCH)
    up = np.array([0.0, cp, -sp])
    u = p[0]
    v = p @ up
    return (origin_px[0] + u - 0.5, origin_px[1] - v - 0.5)


def visible(parts, point, yaw=0.0):
    """그 점이 앞쪽을 향하고 있는지 대략 판단 (눈이 보이는 방향인지)."""
    p = rot_y(yaw) @ np.array(point, dtype=float)
    return p[2] > 0
