import sys
from PIL import Image
out=sys.argv[1]
HEART=["..oo...oo..",".oRRo.oRRo.","oRWRRoRRRRo","oRRRRRRRRRo","oRRRRRRRRRo",".oRRRRRRRo.","..oRRRRRo..","...oRRRo...","....oRo....",".....o....."]
def draw(rows, pal, size, off=(0,0)):
    im=Image.new("RGBA",size,(0,0,0,0))
    for y,r in enumerate(rows):
        for x,ch in enumerate(r):
            if pal.get(ch): im.putpixel((x+off[0],y+off[1]),pal[ch])
    return im
draw(HEART,{'o':(60,20,30,255),'R':(230,60,80,255),'W':(255,200,210,255)},(11,10)).save(out+"/items/heart_full.png")
draw(HEART,{'o':(60,20,30,255),'R':(70,50,60,200),'W':(90,70,80,200)},(11,10)).save(out+"/items/heart_empty.png")
COIN=["..oooo..",".oYYYYo.","oYWYYYDo","oYWYYYDo","oYYYYYDo","oYYYYYDo",".oDDDDo.","..oooo.."]
draw(COIN,{'o':(110,70,10,255),'Y':(250,205,60,255),'W':(255,245,190,255),'D':(210,150,30,255)},(8,8)).save(out+"/items/coin.png")
