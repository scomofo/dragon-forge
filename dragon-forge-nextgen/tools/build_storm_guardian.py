#!/usr/bin/env python3
"""Original offline parametric Arc/egg authoring. Committed exports need no runtime build.
Hovering winged drake, not a scaled/recolored Magma or Rime. Reuses the mesh compiler,
not the earlier meshes or animation tracks. Coordinates: metres, Y up, forward -Z.
"""
from pathlib import Path
import hashlib, json, math
import numpy as np
from PIL import Image
import build_art as art
OUT = Path(__file__).resolve().parents[1] / 'campaign' / 'fusion_assets'

def paint():
    rng = np.random.default_rng(73216)
    palette = [(39,36,64),(110,90,152),(200,186,219),(178,143,244),
               (63,69,94),(162,137,80),(55,67,115),(157,172,195),
               (110,213,237),(25,27,43),(72,72,99),(199,168,92),
               (36,34,54),(57,91,128),(100,80,136),(95,102,142)]
    maps = {k:Image.new('RGB',(1024,1024)) for k in ['base','orm','normal','emission']}
    y,x = np.mgrid[:256,:256]; edge=np.minimum.reduce([x,y,255-x,255-y])
    for i,c in enumerate(palette):
        # Large mineral bands and restrained circuit scars, matching all PBR channels.
        noise=rng.normal(0,1,(256,256)); ridges=np.sin(x*.045+y*.016)*.028
        seam = (np.abs(np.sin(x*.026 + np.sin(y*.021))) < .038)
        h=.62+ridges-seam*.19+noise*.005
        wear=(edge<10)*(rng.random((256,256))>.62)
        base=np.clip(np.array(c)[None,None,:]*(.95+(h-.6)[:,:,None]*.30)+wear[:,:,None]*18,0,255).astype('uint8')
        orm=np.empty((256,256,3),np.uint8);orm[:,:,0]=np.clip(240-seam*30,0,255)
        orm[:,:,1]=np.clip(145+seam*35+noise*3,0,255);orm[:,:,2]=110 if i in [4,5,7,11] else 8
        gy,gx=np.gradient(h);n=np.dstack([-gx*3,-gy*3,np.ones_like(h)]);n/=np.linalg.norm(n,axis=2)[:,:,None]
        normal=np.clip((n*.5+.5)*255,0,255).astype('uint8')
        emission=np.zeros_like(base)
        if i in [3,8]:emission=np.broadcast_to(np.array(c,dtype='uint8'),base.shape).copy()
        at=(i%4*256,i//4*256)
        for key,data in [('base',base),('orm',orm),('normal',normal),('emission',emission)]:maps[key].paste(Image.fromarray(data),at)
    for name,image in maps.items():image.save(OUT/f'atlas_{name}.png')

def guardian():
    m=art.Mesh('storm_guardian'); root=m.bone('Root',(0,0,0))
    body=m.bone('Body',(0,1.30,.18),root)
    neck=m.bone('Neck',(0,1.45,-.48),body); head=m.bone('Head',(0,1.72,-.94),neck)
    jaw=m.bone('Jaw',(0,1.58,-1.08),head)
    m.tube([(0,1.24,.94),(0,1.30,.43),(0,1.34,-.08),(0,1.45,-.55)], [.18,.36,.37,.21], [.22,.42,.37,.22],slot=0,bone=body,sides=12)
    m.tube([(0,1.42,-.46),(0,1.68,-.72),(0,1.75,-1.01),(0,1.68,-1.42)], [.19,.21,.29,.16],[.20,.23,.24,.11],slot=1,bone=head,sides=12)
    m.tube([(0,1.54,-1.0),(0,1.52,-1.22),(0,1.53,-1.42)],[.18,.22,.13],[.06,.06,.035],slot=0,bone=jaw,sides=10)
    m.plate((0,1.34,-.32),.35,.48,normal=(0,.2,-1),slot=8,bone=body,depth=.06)
    for s in [-1,1]:
        m.plate((s*.25,1.78,-1.05),.18,.10,normal=(s,0,-.3),slot=8,bone=head,depth=.016)
        m.tube([(s*.18,1.87,-.92),(s*.35,2.13,-.66),(s*.29,2.30,-.54)],[.10,.065,.003],slot=2,bone=head,sides=7)
        m.tube([(s*.24,1.65,-.9),(s*.5,1.72,-.65),(s*.61,1.80,-.45)],[.085,.055,.004],slot=5,bone=head,sides=6)
        arm=m.bone('Talon.'+str(s),(s*.27,1.22,-.2),body)
        m.tube([(s*.28,1.24,-.25),(s*.53,.98,-.47),(s*.48,.85,-.72)],[.115,.085,.055],slot=0,bone=arm,sides=8)
        for j in range(2):m.tube([(s*(.44+j*.09),.88,-.70),(s*(.47+j*.09),.76,-.81)],[.042,.004],slot=2,bone=arm,sides=6)
        # Thick chamfered wing panels keep two-sided visibility and non-degenerate UVs.
        wing=m.bone('Wing.'+str(s),(s*.24,1.44,.04),body)
        tip=m.bone('WingTip.'+str(s),(s*1.20,1.56,.23),wing)
        m.plate((s*.76,1.49,.20),1.45,1.50,normal=(0,1,.10),up=(0,0,-1),slot=1,bone=wing,depth=.075,
                outline=[(-.5,-.48),(.5,-.20),(.40,.5),(-.44,.3)])
        m.plate((s*1.48,1.58,.36),1.20,1.62,normal=(0,1,.10),up=(0,0,-1),slot=6,bone=tip,depth=.045,
                outline=[(-.47,-.48),(.48,-.15),(.2,.5),(-.44,.22)])
        m.tube([(s*.25,1.55,-.31),(s*1.2,1.63,-.48),(s*1.96,1.71,-.47)],[.07,.065,.003],slot=5,bone=wing,sides=6)
        m.tube([(s*1.05,1.68,-.4),(s*1.55,1.70,-.26),(s*1.88,1.73,-.34)],[.04,.035,.002],slot=3,bone=tip,sides=6)
    parent=body
    for i in range(6):
        z=.75+i*.31;y=1.26-.065*i;bone=m.bone('Tail'+str(i),(0,y,z),parent)
        m.tube([(0,y,z),(0,y-.065,z+.33)],[.185-i*.026,.16-i*.025],slot=0,bone=bone,sides=10)
        m.plate((0,y+.12,z+.13),.24-i*.02,.28,normal=(0,1,0),up=(0,0,-1),slot=5 if i%2 else 1,bone=bone,depth=.05)
        parent=bone
    m.ring((0,1.30,.24),.43,.025,slot=3,bone=body,segments=16,axis='z')
    durations={'idle':1.8,'walk':.8,'claw':.33,'breath':.60,'wall':.54,'burst':.76,'guard':.8,'hurt':.24,'defeat':.8}
    for clip,duration in durations.items():
        times=np.linspace(0,duration,max(3,int(duration*30)+1));poses=[]
        for t in times:
            q=t/duration;wave=math.sin(q*math.pi);beat=math.sin(q*math.tau);pose={}
            if clip in ['idle','walk']:
                pose['Body']=([-.055 if clip=='walk' else 0,0,0],[0,.045*beat,0])
            if clip=='claw':pose['Neck']=([-.22*wave,0,0],[0,0,-.13*wave])
            if clip=='breath':pose.update({'Head':([-.10*wave,0,0],[0,0,0]),'Jaw':([.40*wave,0,0],[0,0,0])})
            if clip in ['wall','burst']:pose['Body']=([-.08*wave,0,0],[0,.14*wave,0])
            if clip=='guard':pose['Head']=([.12,0,0],[0,0,0])
            if clip=='hurt':pose['Body']=([0,0,.1*wave],[0,0,.07*wave])
            if clip=='defeat':pose['Body']=([0,0,.45*q],[0,-.76*q,0])
            for s in [-1,1]:
                angle=(.09+.17*beat) if clip in ['idle','walk'] else (.24*wave)
                if clip=='guard':angle=-.5
                if clip=='defeat':angle=.6*q
                pose['Wing.'+str(s)]=([0,0,s*angle],[0,0,0])
                pose['WingTip.'+str(s)]=([0,0,s*angle*.5],[0,0,0])
                pose['Talon.'+str(s)]=([-.38*wave if clip=='claw' else .02*beat,0,0],[0,0,0])
            for i in range(6):pose['Tail'+str(i)]=([0,.045*math.sin(q*math.tau-i*.35),0],[0,0,0])
            poses.append(pose)
        m.animations[clip]=(times,poses)
    return m

def egg():
    m=art.Mesh('storm_egg');m.tube([(0,.1,0),(0,.4,0),(0,.78,0),(0,1.10,0)],[.15,.40,.30,.015],slot=1,sides=8)
    m.ring((0,.48,0),.46,.025,slot=3,segments=16)
    for s in [-1,1]:m.plate((s*.24,.55,-.23),.18,.4,normal=(s*.5,0,-1),slot=8,depth=.028)
    return m

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True);art.OUT=OUT;paint()
    entries=[guardian().export(),egg().export()]
    files={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.suffix in ['.glb','.png']}
    (OUT/'manifest.json').write_text(json.dumps({'source':'tools/build_storm_guardian.py','assets':entries,'files':files},indent=2)+'\n')
    print(json.dumps(entries,indent=2))
