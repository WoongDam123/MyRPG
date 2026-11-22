import sys, random
from PIL import Image
out = sys.argv[1]
C = {'.':None,'o':(43,29,29),'h':(107,62,38),'s':(242,200,160),'e':(34,34,34),
     't':(58,110,165),'b':(201,162,39),'p':(74,59,42),'f':(59,42,30)}
def head(inner):
    return ["...o"+r+"o..." for r in inner]
def build(face, legs):
    rows = ["................", "....oooooooo....", "...ohhhhhhhho...", "...ohhhhhhhho..."]
    rows += head(face)
    rows += ["....otttttto....", "...osttttttso...", "...osttttttso...",
             "....obbbbbbo....", "....oppppppo...."]
    rows += legs + ["................"]
    for r in rows: assert len(r)==16, (r,len(r))
    assert len(rows)==16
    return rows
L_STAND=["....opo..opo....","....ofo..ofo....","....ooo..ooo...."]
L_A    =["....opo..opo....","....ofo..ooo....","....ooo........."]
L_B    =["....opo..opo....","....ooo..ofo....",".........ooo...."]
S_STAND=["....opo..opo....","....ofo..ofo....","....ooo..ooo...."]
S_A    =["...opo....opo...","...ofo....ofo...","...ooo....ooo..."]
S_B    =[".....opoopo.....",".....ofoofo.....",".....oooooo....."]
FRONT=["hssssssh","sesssses","ssssssss"]
BACK =["hhhhhhhh","hhhhhhhh","hhhhhhhh"]
SIDE =["hhhsssss","hhhssses","hhssssss"]
def mirror(rows): return [r[::-1] for r in rows]
sheet = {
 0: [build(FRONT,L_STAND), build(FRONT,L_A), build(FRONT,L_B)],              # down
 2: [build(SIDE,S_STAND), build(SIDE,S_A), build(SIDE,S_B)],                 # right
 3: [build(BACK,L_STAND), build(BACK,L_A), build(BACK,L_B)],                 # up
}
sheet[1] = [mirror(f) for f in sheet[2]]                                     # left
img = Image.new("RGBA",(48,64),(0,0,0,0))
for row, frames in sheet.items():
    for col, f in enumerate(frames):
        for y,line in enumerate(f):
            for x,ch in enumerate(line):
                if C[ch]: img.putpixel((col*16+x,row*16+y),C[ch]+(255,))
img.save(out+"/sprites/player.png")
random.seed(7)
g = Image.new("RGBA",(16,16),(79,138,60,255))
for _ in range(22):
    x,y=random.randrange(16),random.randrange(16)
    g.putpixel((x,y),random.choice([(66,120,50,255),(96,158,72,255),(70,128,54,255)]))
g.save(out+"/tiles/grass.png")
print("ok")
