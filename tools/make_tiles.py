import sys, random, math
from PIL import Image
out=sys.argv[1]; random.seed(11)
T=16; N=17
img=Image.new("RGBA",(T*N,T),(0,0,0,0))
def tile(i): return i*T
def px(i,x,y,c):
    if 0<=x<T and 0<=y<T: img.putpixel((tile(i)+x,y),c)
GR=(79,138,60,255)
def grass(i, n, cols):
    for y in range(T):
        for x in range(T): px(i,x,y,GR)
    for _ in range(n):
        px(i,random.randrange(T),random.randrange(T),random.choice(cols))
# 0 잔디, 1 잔디(풀잎), 2 꽃
grass(0,22,[(66,120,50,255),(96,158,72,255)])
grass(1,10,[(66,120,50,255)])
for _ in range(6):
    x,y=random.randrange(1,15),random.randrange(2,15)
    px(1,x,y,(110,170,80,255)); px(1,x,y-1,(110,170,80,255))
grass(2,12,[(66,120,50,255)])
for (x,y,c) in [(3,4,(240,240,240,255)),(11,3,(250,210,70,255)),(7,10,(240,110,120,255)),(13,12,(240,240,240,255)),(2,13,(250,210,70,255))]:
    px(2,x,y,c); px(2,x-1,y,c); px(2,x+1,y,c); px(2,x,y-1,c); px(2,x,y+1,c); px(2,x,y,(250,220,90,255))
# 3 흙길
for y in range(T):
    for x in range(T): px(3,x,y,(196,160,104,255))
for _ in range(20): px(3,random.randrange(T),random.randrange(T),random.choice([(176,140,88,255),(210,178,122,255)]))
# 4 물
for y in range(T):
    for x in range(T): px(4,x,y,(64,128,200,255))
for (x,y) in [(2,3),(3,3),(4,3),(9,8),(10,8),(11,8),(4,12),(5,12)]: px(4,x,y,(140,190,240,255))
# 5 나무 (위에서 본 둥근 나무 + 줄기)
for y in range(T):
    for x in range(T):
        d=math.hypot(x-7.5,y-6.5)
        if d<=7.2: px(5,x,y,(28,70,38,255) if d>6.2 else ((60,120,60,255) if (x+y)%5 else (50,105,52,255)))
for (x,y) in [(5,4),(6,4),(5,5),(9,7),(10,7),(4,8)]: px(5,x,y,(90,160,80,255))
for y in range(12,16):
    for x in range(6,10): px(5,x,y,(92,60,36,255) if 6<x<9 else (60,38,24,255))
# 6 바위
for y in range(T):
    for x in range(T):
        d=math.hypot((x-7.5)/1.0,(y-9)/0.8)
        if d<=6.5: px(6,x,y,(60,60,68,255) if d>5.6 else (140,140,150,255))
for (x,y) in [(5,7),(6,7),(5,8)]: px(6,x,y,(185,185,195,255))
# 7 덤불

for y in range(T):
    for x in range(T):
        d=math.hypot(x-7.5,(y-9)/0.85)
        if d<=6.5: px(7,x,y,(36,84,40,255) if d>5.5 else (70,135,62,255))
for (x,y) in [(5,7),(9,8),(7,11)]: px(7,x,y,(200,60,60,255))
# 8 가로 울타리 / 14 세로 울타리
WOOD=(150,100,55,255); WD=(95,60,30,255); WL=(185,135,80,255)
for x in range(T):
    for y in (6,7,11,12):
        px(8,x,y,WD if y in (7,12) else WOOD)
for x0 in (2,12):
    for y in range(3,15):
        for x in (x0,x0+1): px(8,x,y,WD if x==x0+1 or y==14 else WL)
for y in range(T):
    for x in (6,7,8,9): px(14,x,y,WD if x in (6,9) else WOOD)
for y0 in (3,11):
    for y in (y0,y0+1):
        for x in range(4,12): px(14,x,y,WD if y==y0+1 else WL)
# 9 나무 바닥
for y in range(T):
    for x in range(T):
        c=(168,118,72,255) if (y//4)%2==0 else (156,108,64,255)
        if y%4==3: c=(120,82,48,255)
        if (x+ (y//4)*7)%16==0: c=(120,82,48,255)
        px(9,x,y,c)
# 10 벽 윗면(어두운 천장선) / 11 벽면(회벽 + 나무 걸레받이)
for y in range(T):
    for x in range(T): px(10,x,y,(62,46,40,255) if y<14 else (40,28,24,255))
for y in range(T):
    for x in range(T):
        c=(222,208,180,255)
        if y>=12: c=(120,82,48,255) if y<15 else (80,54,30,255)
        elif (x+y*3)%11==0: c=(208,192,162,255)
        px(11,x,y,c)
# 12 밭 (갈아엎은 흙 + 새싹)
for y in range(T):
    for x in range(T): px(12,x,y,(110,76,46,255) if y%4<2 else (130,92,58,255))
for (x,y) in [(3,4),(11,4),(7,12),(14,12),(3,12)]:
    px(12,x,y,(90,170,70,255)); px(12,x-1,y-1,(110,190,80,255)); px(12,x+1,y-1,(110,190,80,255))
# 13 자갈길
for y in range(T):
    for x in range(T): px(13,x,y,(150,140,125,255))
random.seed(13)
for _ in range(16):
    cx,cy=random.randrange(1,15),random.randrange(1,15); r=random.choice([1,1,2])
    col=random.choice([(185,178,165,255),(120,112,100,255),(170,162,148,255)])
    for y in range(cy-r,cy+r):
        for x in range(cx-r,cx+r+1): px(13,x,y,col)
# 15 동굴 바닥 / 16 동굴 벽(바위)
random.seed(15)
for y in range(T):
    for x in range(T): px(15,x,y,(84,76,70,255))
for _ in range(26): px(15,random.randrange(T),random.randrange(T),random.choice([(70,63,58,255),(98,90,82,255)]))
for (x,y) in [(3,5),(4,5),(11,11),(12,11),(12,12)]: px(15,x,y,(60,54,50,255))
for y in range(T):
    for x in range(T):
        c=(66,58,54,255) if y<12 else (46,40,38,255)
        if y<12 and (x*7+y*3)%13==0: c=(88,78,72,255)
        if y in (5,6) and x in range(2,7): c=(52,46,44,255)
        if y==9 and x in range(9,14): c=(52,46,44,255)
        px(16,x,y,c)
for (x,y) in [(4,3),(12,6)]: px(16,x,y,(140,180,210,255))  # 광석 반짝
img.save(out+"/tiles/tiles.png")

