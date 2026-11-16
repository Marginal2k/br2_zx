import sys
from PIL import Image, ImageChops
# panel (screen x 200..255, y 0..191) diff on canvas shots (352x320; border 48/64) : python pdiff.py RUN ref shot1 shot2 ...
run=sys.argv[1]; ref=sys.argv[2]
def L(n): return Image.open(f'build/emu/{run}_{n}.png').convert('RGB')
box=(248,64,304,256)
a=L(ref).crop(box)
for n in sys.argv[3:]:
    try: b=L(n).crop(box)
    except Exception as e: print(n,'missing'); continue
    d=ImageChops.difference(a,b); bb=d.getbbox()
    npx=sum(1 for p in d.getdata() if p!=(0,0,0))
    print(f'{n}: panel diff bbox={bb} px={npx}')
