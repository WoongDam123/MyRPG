import sys, math
from PIL import Image
out = sys.argv[1]
def circle_button(path, fill, ring):
    S=48; im=Image.new("RGBA",(S,S),(0,0,0,0)); c=(S-1)/2
    for y in range(S):
        for x in range(S):
            d=math.hypot(x-c,y-c)
            if d<=23.5: im.putpixel((x,y), ring if d>21 else fill)
    # 칼 아이콘 (대각선)
    blade=(235,240,250,255); hilt=(201,162,39,255); grip=(107,62,38,255)
    for i in range(14):
        x,y=16+i,31-i
        for dx in (0,1): im.putpixel((x+dx,y),blade)
    for i in range(-3,4): im.putpixel((17+i,30+i) if False else (16+i,29+i),hilt)
    for i in range(3): im.putpixel((13+i,34-i),grip); im.putpixel((14+i,34-i),grip)
    im.save(path)
circle_button(out+"/ui/attack_button.png",(255,255,255,70),(255,255,255,150))
circle_button(out+"/ui/attack_button_pressed.png",(255,230,140,140),(255,240,180,220))
# 칼 휘두르기 효과: 오른쪽으로 볼록한 초승달 (24x24)
S=24; im=Image.new("RGBA",(S,S),(0,0,0,0))
for y in range(S):
    for x in range(S):
        d1=math.hypot(x-4,y-11.5); d2=math.hypot(x-1,y-11.5)
        if d1<=14 and d2>11.5 and x>=7:
            a=int(255*min(1,(d1-7)/4)) if d1>7 else 0
            if a>0: im.putpixel((x,y),(255,250,220,a))
im.save(out+"/effects/slash.png")
print("ok")
