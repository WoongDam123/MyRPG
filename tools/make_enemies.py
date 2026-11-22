import sys, math
from PIL import Image
out = sys.argv[1]
# 슬라임 2프레임 (16x16): 0 = 기본, 1 = 납작하게 눌린 모습
OUT=(24,70,30,255); BODY=(98,190,80,255); DARK=(70,150,60,255); HI=(200,240,170,255); EYE=(20,30,20,255)
img = Image.new("RGBA", (32, 16), (0,0,0,0))
for f,(w,h) in enumerate([(6.5,5.5),(7.5,4.5)]):
    cy = 15 - h - 0.5
    for y in range(16):
        for x in range(16):
            dx=(x-7.5)/w; dy=(y-cy)/h
            if y>15: continue
            d=math.hypot(dx,dy if y<cy else dy*0.6)
            if d<=1.0 and y<=15:
                c = OUT if d>0.82 or y==15 else (DARK if y>cy+h*0.4 else BODY)
                img.putpixel((f*16+x,y),c)
    ey=int(cy)
    for ex in (5,10):
        img.putpixel((f*16+ex,ey),EYE); img.putpixel((f*16+ex,ey+1),EYE)
    img.putpixel((f*16+5,int(cy-h*0.5)+1),HI); img.putpixel((f*16+6,int(cy-h*0.5)+1),HI)
img.save(out+"/enemies/slime.png")

