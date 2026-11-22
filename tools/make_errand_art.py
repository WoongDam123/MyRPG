import sys
from PIL import Image, ImageDraw
out=sys.argv[1]; OUTL=(40,26,20,255)
def save(path,W,H,fn):
    im=Image.new("RGBA",(W,H),(0,0,0,0)); fn(ImageDraw.Draw(im),im); im.save(path)
# 창고(헛간) 64x60
def barn(d,im):
    d.rectangle([4,24,59,58],fill=(150,95,55,255),outline=OUTL)
    for x in range(8,59,6): d.line([x,25,x,57],fill=(125,78,44,255))
    d.polygon([(0,26),(32,2),(63,26)],fill=(120,60,45,255),outline=OUTL)
    for y in range(8,26,5):
        t=(y-2)/24; d.line([32-31*t+1,y,32+31*t-1,y],fill=(95,46,34,255))
    d.rectangle([20,34,43,58],fill=(110,66,36,255),outline=OUTL)
    d.line([20,34,43,58],fill=(230,220,200,255)); d.line([43,34,20,58],fill=(230,220,200,255)); d.line([31,34,31,58],fill=OUTL)
    d.rectangle([28,12,35,19],fill=(60,40,30,255),outline=OUTL)
save(out+"/props/barn.png",64,60,barn)
# 나무 상자(짐) 16x16
def crate(d,im):
    d.rectangle([1,3,14,15],fill=(170,120,70,255),outline=OUTL)
    d.line([1,3,14,15],fill=(130,88,50,255)); d.line([14,3,1,15],fill=(130,88,50,255))
    d.rectangle([1,3,14,5],fill=(140,96,56,255),outline=OUTL)
save(out+"/props/crate.png",16,16,crate)
# 건초 20x16
def hay(d,im):
    d.rounded_rectangle([0,3,19,15],radius=3,fill=(220,190,90,255),outline=(150,120,40,255))
    for x in range(3,18,3): d.line([x,5,x+1,13],fill=(190,160,60,255))
    d.line([0,9,19,9],fill=(150,100,50,255))
save(out+"/props/hay.png",20,16,hay)
# 보물 상자 2프레임 (닫힘/열림) 각 16x16 → 32x16
def chest(d,im):
    for f,opened in enumerate([False,True]):
        o=f*16
        d.rectangle([o+1,7,o+14,15],fill=(150,90,40,255),outline=OUTL)
        d.line([o+1,11,o+14,11],fill=(110,64,28,255))
        if opened:
            d.rectangle([o+1,2,o+14,6],fill=(60,36,18,255),outline=OUTL)
            d.rectangle([o+3,6,o+12,8],fill=(30,20,12,255))
        else:
            d.rectangle([o+1,3,o+14,8],fill=(170,104,48,255),outline=OUTL)
            d.rectangle([o+6,6,o+9,10],fill=(230,200,90,255),outline=OUTL)
save(out+"/props/chest.png",32,16,chest)
# 아이템 아이콘 16x16 x 4: 0 낡은 목검, 1 가죽옷, 2 물약, 3 약초
def icons(d,im):
    # 목검 (대각선)
    for i in range(10):
        x,y=4+i,13-i; d.point((x,y),fill=(196,150,96,255)); d.point((x+1,y),fill=(150,104,60,255))
    d.line([2,9,7,14],fill=(110,70,38,255),width=2); d.point((2,15),fill=(90,60,30,255)); d.point((3,14),fill=(90,60,30,255))
    # 가죽옷
    o=16
    d.polygon([(o+3,3),(o+6,2),(o+8,4),(o+10,2),(o+13,3),(o+15,7),(o+12,8),(o+12,14),(o+4,14),(o+4,8),(o+1,7)],fill=(150,95,55,255),outline=OUTL)
    d.line([o+8,4,o+8,14],fill=(110,66,36,255)); d.line([o+4,10,o+12,10],fill=(190,150,80,255))
    # 물약
    o=32
    d.rectangle([o+6,1,o+9,4],fill=(200,170,120,255),outline=OUTL)
    d.ellipse([o+3,4,o+12,14],fill=(220,60,80,255),outline=OUTL)
    d.point((o+5,7),fill=(255,200,210,255)); d.point((o+5,8),fill=(255,200,210,255))
    # 약초
    o=48
    d.line([o+8,15,o+8,6],fill=(70,120,50,255))
    for (x,y) in [(5,6),(11,5),(6,10),(11,10)]:
        d.ellipse([o+x-2,y-2,o+x+2,y+2],fill=(110,190,80,255),outline=(50,110,40,255))
save(out+"/items/item_icons.png",64,16,icons)
# 가방 버튼 24x24
def bag(d,im):
    d.rounded_rectangle([3,7,20,22],radius=4,fill=(170,110,60,255),outline=OUTL)
    d.arc([7,1,16,12],180,360,fill=OUTL,width=2)
    d.rectangle([3,11,20,14],fill=(140,86,44,255))
    d.rectangle([10,12,13,16],fill=(230,200,90,255),outline=OUTL)
save(out+"/ui/bag.png",24,24,bag)
print("ok")
