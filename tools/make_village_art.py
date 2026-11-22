import sys, math, random, importlib.util
from PIL import Image, ImageDraw
out=sys.argv[1]
OUTL=(40,26,20,255)

def house(path, roof, roof_dark, wall, wall_dark, sign=None):
    W,H=80,72; im=Image.new("RGBA",(W,H),(0,0,0,0)); d=ImageDraw.Draw(im)
    # 벽
    d.rectangle([8,32,71,70],fill=wall,outline=OUTL)
    for y in range(36,70,5): d.line([9,y,70,y],fill=wall_dark)
    # 지붕 (사다리꼴 + 기와 줄무늬)
    d.polygon([(2,34),(14,6),(65,6),(77,34)],fill=roof,outline=OUTL)
    for y in range(10,34,5):
        t=(y-6)/28; xl=14-12*t; xr=65+12*t
        d.line([xl+1,y,xr-1,y],fill=roof_dark)
    # 굴뚝
    d.rectangle([56,0,63,12],fill=(120,110,105,255),outline=OUTL)
    # 문
    d.rectangle([33,48,46,70],fill=(110,70,38,255),outline=OUTL); d.point((43,59),fill=(230,200,90,255))
    # 창문
    for x0 in (14,54):
        d.rectangle([x0,42,x0+11,53],fill=(150,200,230,255),outline=OUTL)
        d.line([x0+6,42,x0+6,53],fill=OUTL); d.line([x0,47,x0+11,47],fill=OUTL)
    if sign:
        d.rectangle([28,36,51,45],fill=(200,160,90,255),outline=OUTL)
        sign(d)
    im.save(path)
def potion_sign(d):
    d.rectangle([37,38,42,43],fill=(220,60,80,255)); d.point((39,37),fill=(240,240,240,255)); d.point((40,37),fill=(240,240,240,255))
house(out+"/props/house_player.png",(178,74,52,255),(140,52,38,255),(205,170,120,255),(180,145,100,255))
house(out+"/props/house_shop.png",(64,110,150,255),(46,82,118,255),(215,195,160,255),(190,170,135,255),potion_sign)
house(out+"/props/house_neighbor.png",(110,130,70,255),(84,100,52,255),(200,180,150,255),(176,156,126,255))

def sprite(path,W,H,fn):
    im=Image.new("RGBA",(W,H),(0,0,0,0)); fn(ImageDraw.Draw(im)); im.save(path)
# 우물 24x28
def well(d):
    d.rectangle([3,14,20,26],fill=(140,135,128,255),outline=OUTL)
    for y in (18,22): d.line([4,y,19,y],fill=(110,105,100,255))
    d.rectangle([5,13,18,16],fill=(40,70,110,255))
    d.line([4,2,4,14],fill=(110,70,38,255),width=2); d.line([19,2,19,14],fill=(110,70,38,255),width=2)
    d.polygon([(1,4),(11,0),(22,4)],fill=(178,74,52,255),outline=OUTL)
sprite(out+"/props/well.png",24,28,well)
# 침대 16x28
def bed(d):
    d.rectangle([0,0,15,27],fill=(120,80,45,255),outline=OUTL)
    d.rectangle([2,2,13,8],fill=(240,240,235,255),outline=(170,160,150,255))
    d.rectangle([1,9,14,25],fill=(70,110,170,255),outline=(45,75,125,255))
    for y in range(12,25,4): d.line([2,y,13,y],fill=(95,135,195,255))
sprite(out+"/props/bed.png",16,28,bed)
# 식탁 32x20
def table(d):
    d.rectangle([0,0,31,12],fill=(160,110,62,255),outline=OUTL)
    d.line([1,4,30,4],fill=(140,94,52,255))
    for x in (2,28): d.rectangle([x,12,x+1,19],fill=(110,70,38,255))
    d.ellipse([6,2,13,8],fill=(240,240,235,255),outline=(170,160,150,255)); d.ellipse([19,3,25,8],fill=(200,120,70,255))
sprite(out+"/props/table.png",32,20,table)
# 찬장 20x28
def shelf(d):
    d.rectangle([0,0,19,27],fill=(130,85,48,255),outline=OUTL)
    for y in (9,18): d.line([1,y,18,y],fill=OUTL)
    for i,(x,y,c) in enumerate([(3,4,(220,60,80,255)),(9,3,(80,160,220,255)),(14,5,(230,200,90,255)),(4,13,(160,200,120,255)),(12,12,(240,240,235,255))]):
        d.rectangle([x,y,x+3,y+4],fill=c)
    d.rectangle([2,20,17,25],fill=(110,70,38,255))
sprite(out+"/props/shelf.png",20,28,shelf)
# 화덕 24x28
def stove(d):
    d.rectangle([0,6,23,27],fill=(150,140,130,255),outline=OUTL)
    for y in range(10,27,4): d.line([1,y,22,y],fill=(125,115,108,255))
    d.rectangle([6,16,17,26],fill=(30,20,20,255)); d.polygon([(8,26),(12,18),(16,26)],fill=(240,140,50,255)); d.polygon([(10,26),(12,21),(14,26)],fill=(255,220,90,255))
    d.rectangle([9,0,14,6],fill=(120,110,105,255),outline=OUTL)
sprite(out+"/props/stove.png",24,28,stove)
# 화분 12x14
def plant(d):
    d.rectangle([3,8,8,13],fill=(180,100,60,255),outline=OUTL)
    d.ellipse([0,0,11,9],fill=(80,150,70,255),outline=(40,90,40,255))
sprite(out+"/props/plant.png",12,14,plant)
# 포탈 4프레임 (32x32 각각) → 128x32
P=Image.new("RGBA",(128,32),(0,0,0,0))
for f in range(4):
    for y in range(32):
        for x in range(32):
            dx,dy=(x-15.5)/14,(y-15.5)/9
            r=math.hypot(dx,dy)
            if r<=1.0:
                ang=math.atan2(dy,dx)
                swirl=(math.sin(ang*3 - r*8 + f*math.pi/2)+1)/2
                if r>0.86: col=(180,150,255,255)
                else:
                    a=int(120+110*swirl)
                    col=(int(60+80*swirl),int(40+90*swirl*(1-r)),int(150+90*swirl),a)
                P.putpixel((f*32+x,y),col)
    for (x,y) in [(8,12),(20,9),(14,20),(24,18)]:
        xx=(x+f*3)%26+3; P.putpixel((f*32+xx,y),(255,255,255,255))
P.save(out+"/props/portal.png")

# NPC: 플레이어 그림 생성기를 불러와 색만 바꿔서 만든다
spec=importlib.util.spec_from_file_location("ms", out.replace("assets","tools")+"/make_sprites.py")
src=open(out.replace("assets","tools")+"/make_sprites.py").read()
src=src.split("img = Image.new")[0]  # 함수·데이터 부분만
ns={}; exec(src.replace("out = sys.argv[1]","out=''"),ns)
def npc_sheet(path, pal, extra):
    C=dict(ns['C']); C.update(pal)
    sheet={0:[ns['build'](ns['FRONT'],ns['L_STAND'])],2:[ns['build'](ns['SIDE'],ns['S_STAND'])],3:[ns['build'](ns['BACK'],ns['L_STAND'])]}
    sheet[1]=[ns['mirror'](sheet[2][0])]
    im=Image.new("RGBA",(64,16),(0,0,0,0))
    for row,frames in sheet.items():
        f=[list(r) for r in frames[0]]
        extra(f,row)
        for y,line in enumerate(f):
            for x,ch in enumerate(line):
                if C.get(ch): im.putpixel((row*16+x,y),C[ch])
    im.save(path)
def mom_extra(f,row):  # 긴 머리 + 치마
    for y in (8,9,10):
        if row in (0,3,2,1): f[y][3]='h' if row!=1 else f[y][3]; f[y][12]='h' if row!=2 else f[y][12]
    for y in (12,13): f[y]=list("...ottttttto...") + ['.'] if False else list("...otttttttto...")
def dad_extra(f,row):  # 수염
    if row==0: f[6]=list("...ohhhhhhhho...")
    if row==2: f[6]=list("...ohhhhhhho....")[:16] if False else list("...ohhssshho....")
    if row==1: f[6]=list("....ohhssshho...")
npc_sheet(out+"/npcs/mom.png",{'h':(150,70,40,255),'t':(170,80,120,255),'b':(240,230,210,255),'p':(150,70,110,255)},mom_extra)
npc_sheet(out+"/npcs/dad.png",{'h':(70,50,35,255),'t':(110,130,70,255),'b':(120,80,45,255),'p':(90,70,50,255)},dad_extra)
npc_sheet(out+"/npcs/neighbor.png",{'h':(220,190,90,255),'t':(200,110,60,255),'b':(120,80,45,255)},lambda f,r:None)
print("ok")
