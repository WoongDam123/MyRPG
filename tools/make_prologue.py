import sys, math, random
from PIL import Image
out=sys.argv[1]
# 미지의 존재: 32x44 두건 쓴 실루엣, 별빛 눈
W,H=32,44; im=Image.new("RGBA",(W,H),(0,0,0,0))
for y in range(H):
    for x in range(W):
        cx=15.5
        if y<16:   # 두건(머리)
            inside = math.hypot((x-cx)/8.5,(y-11)/9.5)<=1
        else:      # 망토: 아래로 퍼짐
            half=8+ (y-16)*0.32
            inside = abs(x-cx)<=half and y<=H-2
        if inside:
            t=y/H
            c=(int(40+50*t),int(20+20*t),int(80+70*t),255)
            # 가장자리 빛
            if y>=16 and abs(abs(x-cx)-(8+(y-16)*0.32))<1: c=(150,120,230,255)
            if y<16 and abs(math.hypot((x-cx)/8.5,(y-11)/9.5)-1)<0.13: c=(150,120,230,255)
            im.putpixel((x,y),c)
# 얼굴 그림자 + 눈
for y in range(8,16):
    for x in range(10,22):
        if math.hypot((x-15.5)/5.5,(y-12)/4.5)<=1: im.putpixel((x,y),(10,6,24,255))
for (x,y) in [(13,12),(18,12)]:
    im.putpixel((x,y),(255,250,210,255)); im.putpixel((x,y+1),(200,220,255,255))
random.seed(3)
for _ in range(14):
    x,y=random.randrange(6,26),random.randrange(18,42)
    if im.getpixel((x,y))[3]: im.putpixel((x,y),(220,210,255,255))
im.save(out+"/prologue/being.png")
# 속성 구슬 24x24
def orb(name, base, light, dark, deco):
    S=24; o=Image.new("RGBA",(S,S),(0,0,0,0)); c=11.5
    for y in range(S):
        for x in range(S):
            d=math.hypot(x-c,y-c)
            if d<=10.5:
                if d>9.5: col=dark
                else:
                    k=max(0,1-math.hypot(x-8,y-8)/12)
                    col=tuple(int(base[i]*(1-k)+light[i]*k) for i in range(3))+(255,)
                o.putpixel((x,y),col)
    deco(o); o.putpixel((7,6),(255,255,255,255)); o.putpixel((8,6),(255,255,255,255)); o.putpixel((7,7),(255,255,255,255))
    o.save(out+f"/prologue/orb_{name}.png")
def solid_deco(o):
    for (x,y) in [(12,10),(13,11),(14,12),(11,13),(15,14),(10,15),(13,15)]: o.putpixel((x,y),(90,55,25,255))
def liquid_deco(o):
    for x in range(5,19):
        y=int(14+1.5*math.sin(x*0.8)); o.putpixel((x,y),(190,230,255,255))
def cosmo_deco(o):
    for (x,y) in [(14,9),(10,14),(16,15),(13,17),(7,12)]: o.putpixel((x,y),(255,245,200,255))
orb("solid",(170,110,50),(250,205,130),(80,45,20,255),solid_deco)
orb("liquid",(40,110,200),(150,215,255),(15,45,100,255),liquid_deco)
orb("cosmo",(90,40,150),(200,150,255),(35,15,70,255),cosmo_deco)
