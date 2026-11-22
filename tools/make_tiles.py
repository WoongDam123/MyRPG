import sys, random, math
from PIL import Image
out=sys.argv[1]; random.seed(11)
T=16; N=8
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
img.save(out+"/tiles/tiles.png")

