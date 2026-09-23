#!/usr/bin/env python3
"""Offline Cairn / Stone guardian authoring. Block-golem, metres/Y-up/-Z-front.

Detail pass (Sept 2026): glowing fault-seam eyes, rocky maw, toe/finger blocks,
strata slabs, emissive fault cracks and joint bands raise the golem to the
revised-guardian detail tier while keeping its deliberate blocky silhouette.
Committed exports are runtime-ready; no Python/Blender dependency is needed to play.
"""
from pathlib import Path
import hashlib,json,math
import numpy as np
from PIL import Image
import build_art as art
OUT=Path(__file__).resolve().parents[1]/'campaign'/'stone'
PALETTE=[(66,60,52),(104,91,72),(157,134,96),(203,174,117),
         (47,49,49),(91,82,67),(126,113,89),(184,158,105),
         (218,186,118),(31,33,34),(75,68,58),(143,117,76),
         (48,44,39),(112,102,82),(169,147,104),(236,205,137)]

def paint():
    rng=np.random.default_rng(44021);maps={k:Image.new('RGB',(1024,1024)) for k in ['base','orm','normal','emission']}
    y,x=np.mgrid[:256,:256];edge=np.minimum.reduce([x,y,255-x,255-y])
    for i,c in enumerate(PALETTE):
        grain=rng.normal(0,1,(256,256));fault=(np.abs(np.sin(x*.034+y*.011+np.sin(y*.022)))<.028)
        strata=np.sin(y*.075+x*.008)*.035;h=.61+strata+grain*.004-fault*.10
        chips=(edge<14)&(rng.random((256,256))>.93)
        base=np.clip(np.array(c)[None,None,:]*(.96+(h-.6)[:,:,None]*.35)+chips[:,:,None]*13,0,255).astype('uint8')
        orm=np.empty_like(base);orm[:,:,0]=np.clip(248-fault*18,0,255);orm[:,:,1]=np.clip(205+fault*24+grain*2,0,255);orm[:,:,2]=40 if i in [3,7,8,11,15] else 0
        gy,gx=np.gradient(h);n=np.dstack([-gx*4,-gy*4,np.ones_like(h)]);n/=np.linalg.norm(n,axis=2)[:,:,None];normal=np.clip((n*.5+.5)*255,0,255).astype('uint8')
        emission=np.zeros_like(base)
        if i in [8,15]: emission=np.broadcast_to(np.array(c,dtype='uint8'),base.shape).copy()
        at=(i%4*256,i//4*256)
        for k,d in [('base',base),('orm',orm),('normal',normal),('emission',emission)]:maps[k].paste(Image.fromarray(d),at)
    for k,im in maps.items():im.save(OUT/f'atlas_{k}.png')

def guardian():
    m=art.Mesh('stone_guardian')
    root=m.bone('Root',(0,0,0));core=m.bone('Core',(0,1.30,0),root);head=m.bone('Head',(0,2.18,-.30),core);jaw=m.bone('Jaw',(0,1.98,-.61),head)
    # Massive square torso with glowing fault seams.
    m.box((0,1.35,.05),(1.30,1.38,.90),slot=0,bone=core,bevel=.10)
    m.box((0,1.42,-.44),(.92,.88,.10),slot=1,bone=core,bevel=.04)
    m.ring((0,1.45,-.52),.32,.055,slot=8,bone=core,axis='z',segments=12)
    m.box((0,2.17,-.28),(.78,.62,.68),slot=4,bone=head,bevel=.08)
    m.box((0,2.17,-.65),(.48,.09,.06),slot=8,bone=head,bevel=.01)
    m.box((0,1.96,-.59),(.54,.18,.42),slot=1,bone=jaw,bevel=.04)
    # Glowing fault-seam eyes: the golem reads as awake, not as masonry.
    for s in [-1,1]:
        m.plate((s*.19,2.38,-.625),.15,.05,normal=(0,.12,-1),slot=8,bone=head,depth=.02)
    # Rocky maw: box teeth flank the emissive mouth slit above and below.
    for x in [-.21,-.09,.09,.21]:
        m.box((x,2.27,-.64),(.06,.12,.06),slot=2,bone=head,bevel=.015)
        m.box((x,2.06,-.64),(.06,.12,.06),slot=2,bone=jaw,bevel=.015)
    # Two crown stones, asymmetric enough to read in silhouette, plus fragments.
    m.box((-.25,2.63,-.18),(.25,.48,.31),slot=2,bone=head,bevel=.04);m.box((.24,2.52,-.16),(.22,.29,.28),slot=6,bone=head,bevel=.04)
    for cx,cy,cz,sx,sy,sz in [(-.05,2.78,-.15,.12,.20,.14),(.44,2.44,-.20,.10,.16,.12),(-.44,2.48,-.10,.09,.15,.11)]:
        m.box((cx,cy,cz),(sx,sy,sz),slot=2,bone=head,bevel=.03)
    # Torso strata slabs and emissive fault cracks on the front face.
    for s in [-1,1]:
        for y in [1.02,1.35,1.68]:
            m.box((s*.68,y,.05),(.10,.30,.74),slot=3,bone=core,bevel=.03)
    for cx,cy,sx,sy in [(-.22,1.15,.06,.55),(.18,1.55,.06,.40),(0,1.35,.50,.06)]:
        m.box((cx,cy,-.41),(sx,sy,.03),slot=8,bone=core,bevel=.01)
    # Back crystal cluster (emissive).
    for cx,cy,s in [(-.16,1.72,.13),(.14,1.86,.11),(0,1.58,.10)]:
        m.box((cx,cy,.53),(s,s*2.4,s),slot=15,bone=core,bevel=.04)
    for s,name in [(-1,'L'),(1,'R')]:
        shoulder=m.bone('Shoulder'+name,(s*.78,1.82,-.02),core)
        upper=m.bone('Arm'+name,(s*.92,1.54,-.04),shoulder)
        fore=m.bone('Forearm'+name,(s*1.08,1.12,-.16),upper)
        hand=m.bone('Hand'+name,(s*1.08,.72,-.36),fore)
        m.box((s*.79,1.82,-.02),(.60,.52,.70),slot=6,bone=shoulder,bevel=.09)
        m.box((s*.79,2.14,-.02),(.52,.14,.62),slot=6,bone=shoulder,bevel=.03)
        m.box((s*.98,1.49,-.08),(.45,.58,.50),slot=0,bone=upper,bevel=.07)
        m.box((s*1.08,1.08,-.16),(.48,.62,.54),slot=5,bone=fore,bevel=.07)
        m.box((s*1.36,1.08,-.16),(.08,.50,.46),slot=3,bone=fore,bevel=.03)
        m.box((s*1.08,1.08,-.46),(.40,.50,.08),slot=3,bone=fore,bevel=.03)
        m.ring((s*1.02,1.30,-.10),.30,.035,slot=6,bone=fore,axis='y',segments=16)
        m.box((s*1.08,.66,-.39),(.58,.48,.66),slot=2,bone=hand,bevel=.08)
        m.ring((s*1.08,.68,-.75),.19,.035,slot=8,bone=hand,axis='z',segments=8)
        for j in [-1,0,1]:
            m.box((s*1.08+j*.15,.38,-.70),(.10,.26,.12),slot=2,bone=hand,bevel=.03)
        for j in [-1,1]:
            m.box((s*1.08+j*.14,.82,-.735),(.13,.13,.05),slot=5,bone=hand,bevel=.02)
        leg=m.bone('Leg'+name,(s*.38,.72,.14),root);shin=m.bone('Shin'+name,(s*.38,.38,.12),leg);foot=m.bone('Foot'+name,(s*.38,.10,-.16),shin)
        m.box((s*.38,.72,.12),(.55,.56,.62),slot=1,bone=leg,bevel=.07)
        m.ring((s*.38,.55,.13),.30,.035,slot=1,bone=leg,axis='y',segments=16)
        m.box((s*.38,.36,.10),(.49,.52,.55),slot=0,bone=shin,bevel=.06)
        m.box((s*.38,.36,-.20),(.42,.44,.08),slot=3,bone=shin,bevel=.03)
        m.box((s*.38,.12,-.16),(.62,.24,.92),slot=5,bone=foot,bevel=.06)
        for j in [-1,0,1]:
            m.box((s*.38+j*.17,.10,-.66),(.13,.13,.20),slot=5,bone=foot,bevel=.03)
    # Fault plates on the back/hips.
    for x,z in [(-.48,.52),(0,.60),(.48,.52)]:m.box((x,1.48,z),(.29,.66,.16),slot=3,bone=core,bevel=.025)
    durations={'idle':1.8,'walk':.9,'claw':.40,'breath':.64,'wall':.58,'burst':.82,'guard':.8,'hurt':.24,'defeat':.8}
    for clip,duration in durations.items():
        times=np.linspace(0,duration,max(4,int(duration*30)+1));poses=[]
        for t in times:
            q=float(t/duration);wave=math.sin(q*math.pi);beat=math.sin(q*math.tau);pose={}
            if clip=='idle': pose['Core']=([0,0,.018*beat],[0,.018*beat,0])
            elif clip=='walk':
                pose['Core']=([.03*beat,0,0],[0,.045*abs(beat),0])
                for s,name in [(-1,'L'),(1,'R')]:
                    pose['Leg'+name]=([s*.25*beat,0,0],[0,0,0]);pose['Arm'+name]=([-s*.20*beat,0,0],[0,0,0])
            elif clip=='claw':pose['ArmR']=([-.68*wave,0,-.20*wave],[0,0,-.12*wave]);pose['Core']=([-.08*wave,0,.08*wave],[0,0,0])
            elif clip=='breath':pose['Core']=([-.14*wave,0,0],[0,0,-.10*wave]);pose['Jaw']=([.25*wave,0,0],[0,0,0])
            elif clip=='wall':
                for name in ['ArmL','ArmR']:pose[name]=([-.42*wave,0,(-.45 if name.endswith('L') else .45)*wave],[0,0,0])
            elif clip=='burst':
                pose['Core']=([-.10*wave,0,0],[0,.18*wave,0]);pose['ArmL']=([-.78*wave,0,-.15*wave],[0,0,-.16*wave]);pose['ArmR']=([-.78*wave,0,.15*wave],[0,0,-.16*wave])
            elif clip=='guard':
                pose['ArmL']=([-.62,0,-.34],[0,.10,-.18]);pose['ArmR']=([-.62,0,.34],[0,.10,-.18]);pose['Core']=([.08,0,0],[0,-.05,0])
            elif clip=='hurt':pose['Core']=([0,0,.14*wave],[0,0,.06*wave])
            elif clip=='defeat':pose['Core']=([0,0,.45*q],[0,-.82*q,.18*q])
            poses.append(pose)
        m.animations[clip]=(times,poses)
    return m

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True);art.OUT=OUT;paint();entry=guardian().export()
    files={q.name:hashlib.sha256(q.read_bytes()).hexdigest() for q in sorted(OUT.iterdir()) if q.suffix in ['.glb','.png']}
    (OUT/'manifest.json').write_text(json.dumps({'source':'tools/build_stone_guardian.py','asset':entry,'files':files},indent=2)+'\n')
    print(json.dumps(entry,indent=2))
