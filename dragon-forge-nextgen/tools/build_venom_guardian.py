#!/usr/bin/env python3
"""Offline Nox/Venom authoring: low frilled wyrm, metres/Y-up/-Z-front.
Committed exports are runtime-ready; Python is only an editable authoring path.
"""
from pathlib import Path
import hashlib,json,math
import numpy as np
from PIL import Image
import build_art as art
OUT=Path(__file__).resolve().parents[1]/'campaign'/'venom'
PALETTE=[(24,34,29),(49,72,50),(84,118,58),(136,168,72),
         (38,27,48),(79,45,91),(129,70,139),(183,102,174),
         (145,215,68),(18,24,21),(66,83,47),(181,198,91),
         (31,42,35),(63,96,61),(105,137,70),(198,236,93)]

def paint():
    rng=np.random.default_rng(91331);maps={k:Image.new('RGB',(1024,1024)) for k in ['base','orm','normal','emission']}
    y,x=np.mgrid[:256,:256];edge=np.minimum.reduce([x,y,255-x,255-y])
    for i,c in enumerate(PALETTE):
        noise=rng.normal(0,1,(256,256));scales=np.sin(x*.082+np.sin(y*.041))*np.sin(y*.071)
        pits=(np.abs(scales)>.91)&(rng.random((256,256))>.74);vein=np.abs(np.sin(x*.028-y*.019+np.sin(y*.023)))<.035
        h=.61+scales*.025-pits*.055-vein*.035+noise*.004
        wear=(edge<9)&(rng.random((256,256))>.83)
        base=np.clip(np.array(c)[None,None,:]*(.94+(h-.6)[:,:,None]*.38)+wear[:,:,None]*9,0,255).astype('uint8')
        orm=np.empty_like(base);orm[:,:,0]=np.clip(244-pits*20,0,255);orm[:,:,1]=np.clip(178+vein*25+noise*2,0,255);orm[:,:,2]=35 if i in [5,6,7,11] else 3
        gy,gx=np.gradient(h);n=np.dstack([-gx*4,-gy*4,np.ones_like(h)]);n/=np.linalg.norm(n,axis=2)[:,:,None];normal=np.clip((n*.5+.5)*255,0,255).astype('uint8')
        emission=np.zeros_like(base)
        if i in [8,15]:emission=np.broadcast_to(np.array(c,dtype='uint8'),base.shape).copy()
        at=(i%4*256,i//4*256)
        for k,d in [('base',base),('orm',orm),('normal',normal),('emission',emission)]:maps[k].paste(Image.fromarray(d),at)
    for k,im in maps.items():im.save(OUT/f'atlas_{k}.png')

def guardian():
    m=art.Mesh('venom_guardian');root=m.bone('Root',(0,0,0));body=m.bone('Body',(0,.78,.18),root)
    neck=m.bone('Neck',(0,1.02,-.52),body);head=m.bone('Head',(0,1.31,-1.05),neck);jaw=m.bone('Jaw',(0,1.16,-1.28),head)
    m.tube([(0,.70,.82),(0,.80,.30),(0,.84,-.18),(0,1.01,-.62)],[.24,.46,.43,.26],[.27,.52,.45,.24],slot=1,bone=body,sides=12)
    m.tube([(0,.98,-.54),(0,1.20,-.82),(0,1.34,-1.13),(0,1.27,-1.48)],[.23,.27,.31,.15],[.23,.28,.24,.10],slot=2,bone=head,sides=11)
    m.tube([(0,1.15,-1.12),(0,1.09,-1.35),(0,1.12,-1.52)],[.19,.21,.09],[.065,.055,.025],slot=0,bone=jaw,sides=9)
    # Bright throat sac and split eye marks.
    m.plate((0,1.03,-.71),.42,.55,normal=(0,.1,-1),slot=8,bone=neck,depth=.045)
    for s in [-1,1]:
        m.plate((s*.22,1.38,-1.19),.16,.09,normal=(s*.25,.05,-1),slot=8,bone=head,depth=.014)
        # Broad radial frill establishes the silhouette.
        frill=m.bone('Frill.'+str(s),(s*.24,1.28,-.78),neck)
        m.plate((s*.58,1.35,-.72),.86,1.22,normal=(s*.85,.05,-.18),up=(0,1,0),slot=6,bone=frill,depth=.038,
                outline=[(-.48,-.48),(.50,-.22),(.38,.48),(-.22,.42)])
        m.tube([(s*.18,1.45,-1.0),(s*.34,1.70,-.87),(s*.31,1.86,-.79)],[.075,.045,.003],slot=3,bone=head,sides=6)
    # Four low limbs keep Nox grounded while the body reads as a wyrm rather than a quadruped copy.
    for z,prefix in [(-.22,'F'),(.48,'B')]:
        for s,name in [(-1,'L'),(1,'R')]:
            upper=m.bone(prefix+'Leg.'+name,(s*.34,.64,z),body);foot=m.bone(prefix+'Foot.'+name,(s*.48,.22,z-.18),upper)
            m.tube([(s*.34,.66,z),(s*.52,.40,z-.08),(s*.49,.18,z-.24)],[.11,.09,.045],slot=0,bone=upper,sides=7)
            m.tube([(s*.49,.18,z-.24),(s*.51,.10,z-.48)],[.075,.012],slot=3,bone=foot,sides=6)
    parent=body
    for i in range(7):
        z=.78+i*.31;y=.72-.035*i;bone=m.bone('Tail'+str(i),(0,y,z),parent)
        r=max(.04,.22-i*.026)
        m.tube([(0,y,z),(0,y-.035,z+.34)],[r,max(.018,r-.025)],slot=1 if i%2 else 2,bone=bone,sides=9)
        if i<5:m.plate((0,y+.13,z+.13),.21-i*.018,.27,normal=(0,1,0),slot=3,bone=bone,depth=.038)
        parent=bone
    durations={'idle':1.7,'walk':.82,'claw':.34,'breath':.58,'wall':.56,'burst':.72,'guard':.76,'hurt':.24,'defeat':.85}
    limbs=['FLeg.L','FLeg.R','BLeg.L','BLeg.R']
    for clip,duration in durations.items():
        times=np.linspace(0,duration,max(4,int(duration*30)+1));poses=[]
        for t in times:
            q=float(t/duration);wave=math.sin(q*math.pi);beat=math.sin(q*math.tau);pose={}
            pose['Body']=([0,.018*beat if clip=='idle' else 0,0],[0,.025*beat if clip in ['idle','walk'] else 0,0])
            if clip=='walk':
                pose['Body']=([0,.02*abs(beat),0],[0,.06*beat,0])
                for j,n in enumerate(limbs):pose[n]=([.18*math.sin(q*math.tau+j*math.pi),0,0],[0,0,0])
            elif clip=='claw':pose['Head']=([-.24*wave,0,-.10*wave],[0,0,0]);pose['Jaw']=([.32*wave,0,0],[0,0,0])
            elif clip=='breath':pose['Neck']=([-.14*wave,0,0],[0,0,-.08*wave]);pose['Jaw']=([.46*wave,0,0],[0,0,0])
            elif clip=='wall':pose['Head']=([.10*wave,0,0],[0,.20*wave,0]);pose['Jaw']=([.35*wave,0,0],[0,0,0])
            elif clip=='burst':pose['Body']=([-.07*wave,0,0],[0,.18*wave,0]);pose['Neck']=([-.24*wave,0,0],[0,0,-.15*wave])
            elif clip=='guard':pose['Head']=([.12,0,0],[0,0,0]);pose['Neck']=([.08,0,0],[0,0,0])
            elif clip=='hurt':pose['Body']=([0,0,.10*wave],[0,0,.08*wave])
            elif clip=='defeat':pose['Body']=([0,0,.30*q],[0,-.62*q,.12*q])
            for s in [-1,1]:
                angle=.08*beat if clip in ['idle','walk'] else (.30*wave if clip in ['breath','wall','burst'] else 0)
                if clip=='guard':angle=-.34
                pose['Frill.'+str(s)]=([0,s*angle,0],[0,0,0])
            for i in range(7):pose['Tail'+str(i)]=([0,.06*math.sin(q*math.tau-i*.42),0],[0,0,0])
            poses.append(pose)
        m.animations[clip]=(times,poses)
    return m

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True);art.OUT=OUT;paint();entry=guardian().export()
    files={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.suffix in ['.glb','.png']}
    (OUT/'manifest.json').write_text(json.dumps({'source':'tools/build_venom_guardian.py','asset':entry,'files':files},indent=2)+'\n')
    print(json.dumps(entry,indent=2))
