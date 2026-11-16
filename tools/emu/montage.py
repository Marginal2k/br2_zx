import sys
from PIL import Image
name=sys.argv[1]; shots=sys.argv[2].split(','); cols=int(sys.argv[3]) if len(sys.argv)>3 else 4
ims=[Image.open(f'build/emu/{name}_{n}.png').crop((40,70,320,290)) for n in shots]
rows=(len(ims)+cols-1)//cols
W=Image.new('RGB',(280*cols,220*rows))
for i,im in enumerate(ims): W.paste(im,((i%cols)*280,(i//cols)*220))
W.save(f'build/emu/{name}_sheet.png')
