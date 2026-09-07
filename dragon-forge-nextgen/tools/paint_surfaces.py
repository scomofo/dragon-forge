"""Deterministic layered surface repaint; shared UV layout, no downloaded textures.
Broad soot/oxide washes, recessed seams, chipped edges and directional tool marks
are composed separately into color, height, ORM and emission (not baked lighting).
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw


def paint(out: Path) -> None:
    cell = 512
    y, x = np.mgrid[0:cell, 0:cell].astype(np.float32)
    u, v = x / (cell - 1), y / (cell - 1)
    edge = np.minimum.reduce([abs(u-.055), abs(u-.945), abs(v-.055), abs(v-.945)])
    wear = np.exp(-edge * 85)
    palette = [(43,46,47),(150,65,31),(222,193,140),(255,137,38),
               (44,57,64),(152,84,44),(39,86,91),(132,148,151),
               (62,220,227),(21,24,27),(62,70,74),(193,137,56),
               (25,28,28),(14,38,43),(84,66,61),(43,52,59)]
    maps = [np.zeros((cell*4, cell*4, 3), np.uint8) for _ in range(4)]
    for slot, color in enumerate(palette):
        rng = np.random.default_rng(281040 + slot)
        def cloud(grid):
            im=Image.fromarray((rng.random((grid,grid))*255).astype(np.uint8))
            return np.asarray(im.resize((cell,cell),Image.Resampling.BICUBIC),np.float32)/255
        coarse, medium, fine = cloud(5), cloud(19), rng.random((cell,cell)).astype(np.float32)
        wash = .75 + .27*coarse + .07*medium
        rgb = np.array(color, np.float32)[None,None,:] * wash[:,:,None]
        height = np.full_like(u,.5); rough = np.full_like(u,.7); metal = np.zeros_like(u)
        occlusion = np.ones_like(u); emission = np.zeros_like(rgb)
        scratches=Image.new('L',(cell,cell)); brush=ImageDraw.Draw(scratches)
        for _ in range(90 if slot not in [0,1,2] else 27):
            px,py=rng.integers(25,cell-25,2); length=int(rng.integers(3,32))
            brush.line([(int(px),int(py)),(int(px+length),int(py+length*.3))],fill=int(rng.integers(80,220)),width=1)
        scratch=np.asarray(scratches,np.float32)/255
        if slot in [0,1]:
            n=7 if slot==0 else 9
            warp_x=u*n+.18*np.sin(v*23)+.07*np.sin(u*31)
            warp_y=v*n+.16*np.sin(u*19)
            nearest=np.full_like(u,1e6); second=nearest.copy(); flake=np.zeros_like(u)
            for iy in range(-1,n+2):
                for ix in range(-1,n+2):
                    px=ix+rng.uniform(-.32,.32); py=iy+rng.uniform(-.32,.32)
                    d=(warp_x-px)**2+(warp_y-py)**2
                    mask=d<nearest; second=np.where(mask,nearest,np.minimum(second,d))
                    nearest=np.minimum(nearest,d); flake=np.where(mask,rng.uniform(-.12,.13),flake)
            seam=np.exp(-(second-nearest)*47)
            lip=np.exp(-((second-nearest)-.07)**2/.0018)*(1-seam)
            ash=np.clip((coarse-.50)*1.1,0,.22)
            rgb*= (1+flake-seam*.48+lip*.15+wear*.15)[:,:,None]
            rgb+=ash[:,:,None]*np.array([38,35,30])
            height+=-.12*seam+.013*medium+.003*fine
            occlusion=1-.28*seam
            rough=np.clip(.81+.08*coarse-.12*lip+seam*.07,.58,.98)
            if slot==0:
                hot=seam*np.clip((medium-.65)*3,0,.5)*np.clip((coarse-.55)*3,0,1)
                emission=hot[:,:,None]*np.array([125,23,2])
            else:
                edge_chips=wear*np.clip((medium-.35)*3,0,1)
                rgb+=edge_chips[:,:,None]*np.array([44,24,13])
                height-=.02*edge_chips
            rgb+=scratch[:,:,None]*np.array([12,10,8])
        elif slot==2:
            grain=np.sin(u*176+np.sin(v*11)*1.6)+.35*np.sin(u*311+v*7)
            root_stain=np.clip((1-v-.38),0,.55)*(.75+.25*coarse)
            rgb*= (1-root_stain*.43+grain*.018)[:,:,None]
            rgb+=scratch[:,:,None]*np.array([25,22,17]); height+=grain*.006-scratch*.009
            rough=.56+.16*coarse+root_stain*.12
        elif slot in [3,8]:
            pulse=.80+.18*np.sin(u*22)*np.sin(v*11)+.07*medium
            rgb*=pulse[:,:,None]; emission=rgb*.94; rough=np.full_like(u,.5)
        else:
            dirt=np.clip((coarse-.44)*1.25,0,.40)
            chips=wear*np.clip((medium-.36)*3,0,1)
            rgb*= (1-dirt)[:,:,None]
            rgb+=chips[:,:,None]*np.array([40,42,37])+scratch[:,:,None]*np.array([32,34,32])
            height+=.004*np.sin(v*400)+.003*fine-.017*scratch-.025*chips
            metal[:]=.68 if slot in [4,5,7,10,11] else .12
            rough=np.clip(.64+.17*dirt-.22*chips-.10*scratch+.035*medium,.3,.96)
            occlusion=1-.1*dirt
            if slot==5:
                oxide=np.clip((medium-.54)*2.2,0,.48)*(1-chips)
                rgb=rgb*(1-oxide[:,:,None])+np.array([38,91,77])*oxide[:,:,None]
                rough+=oxide*.25; metal*=1-oxide*.9
            if slot==6:
                rgb=rgb*(1-chips[:,:,None]*.5)+np.array([118,125,122])*chips[:,:,None]*.5
                metal+=chips*.45
        dy,dx=np.gradient(height)
        normal=np.stack([-dx*10,dy*10,np.ones_like(u)],axis=2)
        normal/=np.linalg.norm(normal,axis=2)[:,:,None]
        sl=(slice(slot//4*cell,(slot//4+1)*cell),slice(slot%4*cell,(slot%4+1)*cell))
        maps[0][sl]=np.clip(rgb,0,255).astype(np.uint8)
        maps[1][sl]=(np.clip(np.stack([occlusion,rough,metal],2),0,1)*255).astype(np.uint8)
        maps[2][sl]=np.clip((normal*.5+.5)*255,0,255).astype(np.uint8)
        maps[3][sl]=np.clip(emission,0,255).astype(np.uint8)
    for name,pixels in zip(['atlas_base','atlas_orm','atlas_normal','atlas_emission'],maps):
        Image.fromarray(pixels).save(out/(name+'.png'),compress_level=9)
