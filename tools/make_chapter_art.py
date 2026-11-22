import sys, math, importlib
from PIL import Image, ImageDraw
out=sys.argv[1]; OUTL=(40,26,20,255)
def save(path,W,H,fn):
    im=Image.new("RGBA",(W,H),(0,0,0,0)); fn(ImageDraw.Draw(im),im); im.save(path)
tools=out.replace("assets","tools")
# ---------- NPC: 촌장, 대지의 정령 (플레이어 그림 생성기 재사용) ----------
src=open(tools+"/make_sprites.py").read().split("img = Image.new")[0]
ns={}; exec(src.replace("out = sys.argv[1]","out=''"),ns)
def npc_sheet(path,pal,extra=lambda f,r:None):
    C=dict(ns['C']); C.update(pal)
    sheet={0:ns['build'](ns['FRONT'],ns['L_STAND']),2:ns['build'](ns['SIDE'],ns['S_STAND']),3:ns['build'](ns['BACK'],ns['L_STAND'])}
    sheet[1]=ns['mirror'](sheet[2])
    im=Image.new("RGBA",(64,16),(0,0,0,0))
    for row,f in sheet.items():
        f=[list(r) for r in f]; extra(f,row)
        for y,line in enumerate(f):
            for x,ch in enumerate(line):
                if C.get(ch): im.putpixel((row*16+x,y),C[ch])
    im.save(path)
def elder(f,row):
    if row==0: f[7]=list("....ohhhhhho....")  # 흰 수염
    for y in (12,13): f[y]=list("....otttttto....")
npc_sheet(out+"/npcs/elder.png",{'h':(235,235,235,255),'t':(110,80,150,255),'b':(200,170,80,255),'p':(110,80,150,255)},elder)
npc_sheet(out+"/npcs/spirit.png",{'h':(250,220,150,255),'s':(240,200,140,255),'t':(200,140,60,255),'b':(255,230,120,255),'p':(170,110,50,255),'o':(110,70,30,255)})
# ---------- 상점 카운터 48x22 ----------
def counter(d,im):
    d.rectangle([0,6,47,21],fill=(150,100,55,255),outline=OUTL)
    d.rectangle([0,2,47,7],fill=(185,135,80,255),outline=OUTL)
    for x in range(6,47,8): d.line([x,9,x,20],fill=(120,80,44,255))
    d.rectangle([6,0,11,3],fill=(220,60,80,255)); d.rectangle([36,0,41,3],fill=(110,190,80,255))
save(out+"/props/counter.png",48,22,counter)
# ---------- 제단 32x28 ----------
def altar(d,im):
    d.polygon([(2,27),(6,14),(26,14),(30,27)],fill=(120,112,104,255),outline=OUTL)
    d.rectangle([4,10,27,15],fill=(150,142,132,255),outline=OUTL)
    d.polygon([(16,0),(21,8),(16,12),(11,8)],fill=(240,170,70,255),outline=(150,90,30,255))
    d.point((15,4),fill=(255,240,200,255))
save(out+"/props/altar.png",32,28,altar)
# ---------- 적: 바위 슬라임, 단단한 바위 슬라임 (슬라임 색만 바꿈) ----------
base=Image.open(out+"/enemies/slime.png").convert("RGBA")
def recolor(img,mapping):
    o=img.copy(); px=o.load()
    for y in range(o.height):
        for x in range(o.width):
            c=px[x,y]
            if c[3] and c[:3] in mapping: px[x,y]=mapping[c[:3]]+(255,)
    return o
m_rock={(98,190,80):(150,130,110),(70,150,60):(115,98,82),(24,70,30):(60,48,40),(200,240,170):(210,200,185)}
m_hard={(98,190,80):(110,115,130),(70,150,60):(80,84,100),(24,70,30):(35,36,48),(200,240,170):(170,200,230)}
recolor(base,m_rock).save(out+"/enemies/rock_slime.png")
recolor(base,m_hard).save(out+"/enemies/hard_slime.png")
# 킹슬라임: 32x32 2프레임 (커다란 초록 슬라임 + 왕관)
K=Image.new("RGBA",(64,32),(0,0,0,0))
for f in range(2):
    sm=base.crop((f*16,0,f*16+16,16)).resize((32,32),Image.NEAREST)
    K.alpha_composite(sm,(f*32,0))
    d=ImageDraw.Draw(K)
    top=8 if f==0 else 12
    d.polygon([(f*32+9,top),(f*32+11,top-6),(f*32+13,top-2),(f*32+16,top-8),(f*32+19,top-2),(f*32+21,top-6),(f*32+23,top)],fill=(240,200,60,255),outline=(140,100,20,255))
    d.point((f*32+16,top-4),fill=(220,60,80,255))
K.save(out+"/enemies/king_slime.png")
# 대지의 수호자(골렘) 2프레임 24x24
G=Image.new("RGBA",(48,24),(0,0,0,0)); d=ImageDraw.Draw(G)
for f in range(2):
    o=f*24; dy=0 if f==0 else 1
    d.rectangle([o+5,6+dy,o+18,19+dy],fill=(130,120,108,255),outline=(50,44,40,255))
    d.rectangle([o+8,1+dy,o+15,7+dy],fill=(150,140,128,255),outline=(50,44,40,255))
    d.point((o+10,4+dy),fill=(255,190,80,255)); d.point((o+13,4+dy),fill=(255,190,80,255))
    d.rectangle([o+1,8+dy+f,o+5,16+dy+f],fill=(115,106,96,255),outline=(50,44,40,255))
    d.rectangle([o+18,8+dy-f,o+22,16+dy-f],fill=(115,106,96,255),outline=(50,44,40,255))
    d.rectangle([o+6,19,o+10,23],fill=(100,92,84,255),outline=(50,44,40,255)); d.rectangle([o+13,19,o+17,23],fill=(100,92,84,255),outline=(50,44,40,255))
    d.line([o+9,11+dy,o+14,15+dy],fill=(255,170,60,255))
G.save(out+"/enemies/golem.png")
# ---------- 아이템 아이콘 확장: 4 열쇠, 5 대지의 결정, 6 성인의 증표 ----------
icons=Image.open(out+"/items/item_icons.png").convert("RGBA")
I=Image.new("RGBA",(16*7,16),(0,0,0,0)); I.alpha_composite(icons,(0,0)); d=ImageDraw.Draw(I)
o=64; d.ellipse([o+1,2,o+7,8],outline=(200,160,40,255),width=2); d.line([o+6,7,o+14,13],fill=(200,160,40,255),width=2); d.line([o+11,12,o+12,10],fill=(200,160,40,255),width=2); d.line([o+13,14,o+14,12],fill=(200,160,40,255),width=2)
o=80; d.polygon([(o+8,1),(o+13,6),(o+11,14),(o+5,14),(o+3,6)],fill=(240,160,60,255),outline=(130,70,20,255)); d.line([o+8,2,o+8,13],fill=(255,210,130,255)); d.point((o+6,5),fill=(255,250,220,255))
o=96; d.ellipse([o+2,4,o+13,15],fill=(200,170,80,255),outline=(120,90,30,255)); d.line([o+5,1,o+7,5],fill=(170,60,60,255),width=2); d.line([o+11,1,o+9,5],fill=(170,60,60,255),width=2); d.rectangle([o+6,8,o+9,11],fill=(140,110,60,255))
I.save(out+"/items/item_icons.png")
# ---------- 스킬 아이콘 16x16 x 6: 0 돌진, 1 대지 베기, 2 단단한 몸, 3 방패 막기, 4 회전 베기, 5 수정 탄환 ----------
S=Image.new("RGBA",(96,16),(0,0,0,0)); d=ImageDraw.Draw(S)
def bg(o,c): d.rounded_rectangle([o,0,o+15,15],radius=3,fill=c)
bg(0,(70,90,130,255)); d.polygon([(4,4),(9,8),(4,12)],fill=(230,240,255,255)); d.polygon([(8,4),(13,8),(8,12)],fill=(190,210,240,255))
bg(16,(130,80,60,255))
for i in range(9): d.point((19+i,12-i),fill=(235,235,235,255)); d.point((20+i,12-i),fill=(180,180,190,255))
d.line([18,10,21,13],fill=(200,160,60,255),width=2)
bg(32,(140,60,70,255)); d.polygon([(36,6),(38,4),(40,6),(42,4),(44,6),(40,11)],fill=(240,90,110,255))
bg(48,(90,100,110,255)); d.polygon([(52,3),(60,3),(60,9),(56,13),(52,9)],fill=(180,170,150,255),outline=(60,55,50,255)); d.line([56,4,56,11],fill=(120,110,100,255))
bg(64,(120,70,40,255)); d.arc([67,3,77,13],20,340,fill=(255,230,170,255),width=2); d.polygon([(76,3),(78,6),(74,6)],fill=(255,230,170,255))
bg(80,(90,60,130,255)); d.polygon([(88,2),(92,8),(88,14),(84,8)],fill=(220,200,255,255),outline=(140,110,200,255)); d.line([88,3,88,13],fill=(255,255,255,255))
S.save(out+"/ui/skill_icons.png")
# ---------- 수정 탄환 10x10 ----------
def crystal(d,im):
    d.polygon([(5,0),(9,5),(5,9),(1,5)],fill=(220,200,255,255),outline=(130,100,200,255)); d.point((4,3),fill=(255,255,255,255))
save(out+"/effects/crystal.png",10,10,crystal)
# ---------- 원형 충격(회전 베기·방패) 48x48 ----------
def ring(d,im):
    d.ellipse([2,2,45,45],outline=(255,240,200,255),width=3); d.ellipse([8,8,39,39],outline=(255,220,150,140),width=2)
save(out+"/effects/ring.png",48,48,ring)
print("ok")
