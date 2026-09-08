#!/usr/bin/env python3
"""Offline Umbra/Shadow authoring: negative-space holed wolf, metres/Y-up/-Z-front.
Committed exports are runtime-ready; Python is only an editable authoring path.
"""
from pathlib import Path
import hashlib,json,math
import numpy as np
from PIL import Image
import build_art as art
OUT=Path(__file__).resolve().parents[1]/'campaign'/'shadow'
PALETTE=[(16,15,24),(27,22,39),(43,30,61),(62,39,82),
         (78,48,101),(103,61,129),(133,78,156),(167,102,182),
         (117,92,220),(72,66,156),(54,50,102),(31,29,57),
         (184,154,244),(112,214,237),(48,116,140),(12,12,20)]

def paint():
    rng=np.random.default_rng(47119);maps={k:Image.new('RGB',(1024,1024)) for k in ['base','orm','normal','emission']}
    y,x=np.mgrid[:256,:256];edge=np.minimum.reduce([x,y,255-x,255-y])
    for i,c in enumerate(PALETTE):
        noise=rng.normal(0,1,(256,256));wisps=np.sin(x*.048+y*.027+np.sin(y*.037))*np.sin(y*.061-x*.017)
        tears=(np.abs(wisps)>.88)&(rng.random((256,256))>.70);vein=np.abs(np.sin(x*.021+y*.031+np.sin(x*.013)))<.030
        h=.58+wisps*.018-tears*.06-vein*.025+noise*.003
        rim=(edge<12)&(rng.random((256,256))>.80)
        base=np.clip(np.array(c)[None,None,:]*(.91+(h-.56)[:,:,None]*.48)+rim[:,:,None]*7,0,255).astype('uint8')
        orm=np.empty_like(base);orm[:,:,0]=np.clip(247-tears*25,0,255);orm[:,:,1]=np.clip(188+vein*23+noise*2,0,255);orm[:,:,2]=18 if i in [8,9,12,13,14] else 2
        gy,gx=np.gradient(h);n=np.dstack([-gx*4.2,-gy*4.2,np.ones_like(h)]);n/=np.linalg.norm(n,axis=2)[:,:,None];normal=np.clip((n*.5+.5)*255,0,255).astype('uint8')
        emission=np.zeros_like(base)
        if i in [8,12,13]: emission=np.broadcast_to(np.array(c,dtype='uint8'),base.shape).copy()
        at=(i%4*256,i//4*256)
        for k,d in [('base',base),('orm',orm),('normal',normal),('emission',emission)]:maps[k].paste(Image.fromarray(d),at)
    OUT.mkdir(parents=True,exist_ok=True)
    for k,im in maps.items():im.save(OUT/f'atlas_{k}.png')

def guardian():
    m=art.Mesh('shadow_guardian')
    root=m.bone('Root',(0,0,0));pelvis=m.bone('Pelvis',(0,.77,.45),root);chest=m.bone('Chest',(0,.99,-.30),root)
    neck=m.bone('Neck',(0,1.20,-.72),chest);head=m.bone('Head',(0,1.46,-1.13),neck);jaw=m.bone('Jaw',(0,1.31,-1.40),head)
    # Two disconnected torso masses are intentional. Their missing middle volume is the
    # defining Shadow silhouette: a true hole/gap, not a dark texture painted on a body.
    m.tube([(0,.70,.82),(0,.78,.56),(0,.83,.31)],[.25,.38,.32],[.23,.34,.28],slot=2,bone=pelvis,sides=11)
    m.tube([(0,.87,-.02),(0,.99,-.27),(0,1.10,-.55)],[.30,.43,.31],[.26,.38,.25],slot=3,bone=chest,sides=11)
    # Broken dorsal/ventral crescents frame the missing central body without closing it.
    m.tube([(-.19,1.05,-.02),(-.24,1.27,.10),(-.17,1.35,.33)],[.055,.043,.018],slot=8,bone=chest,sides=6)
    m.tube([( .19,1.05,-.02),( .24,1.27,.10),( .17,1.35,.33)],[.055,.043,.018],slot=8,bone=chest,sides=6)
    m.tube([(-.17,.65,-.01),(-.23,.48,.10),(-.15,.44,.31)],[.050,.038,.014],slot=9,bone=pelvis,sides=6)
    m.tube([( .17,.65,-.01),( .23,.48,.10),( .15,.44,.31)],[.050,.038,.014],slot=9,bone=pelvis,sides=6)
    # A thin floating spine line maintains readable flow while preserving side-on negative space.
    m.tube([(0,1.10,-.02),(0,1.32,.13),(0,1.36,.28)],[.045,.035,.012],slot=12,bone=chest,sides=6)
    # Wolf-like neck/skull with a second intentional cheek gap between upper skull and jaw.
    m.tube([(0,1.07,-.52),(0,1.23,-.77),(0,1.46,-1.08)],[.23,.25,.28],[.20,.22,.23],slot=1,bone=neck,sides=10)
    m.tube([(0,1.48,-1.04),(0,1.51,-1.32),(0,1.45,-1.60)],[.27,.23,.12],[.20,.15,.08],slot=2,bone=head,sides=9)
    m.tube([(0,1.27,-1.20),(0,1.24,-1.47),(0,1.30,-1.63)],[.20,.17,.08],[.055,.045,.018],slot=0,bone=jaw,sides=8)
    # Tall split ears, eye slits and small void-lit facial chips.
    for s in [-1,1]:
        ear=m.bone('Ear.'+('L' if s<0 else 'R'),(s*.18,1.60,-1.02),head)
        m.tube([(s*.17,1.57,-1.03),(s*.30,1.82,-.99),(s*.35,2.03,-.91)],[.11,.075,.005],slot=4,bone=ear,sides=7)
        m.plate((s*.23,1.56,-1.33),.13,.10,normal=(s*.22,.05,-1),slot=13,bone=head,depth=.016)
        m.plate((s*.29,1.42,-1.44),.12,.18,normal=(s*.36,-.02,-1),slot=8,bone=head,depth=.012)
    # Four long, narrow canine limbs. They stay grounded; Shadow is not a flying controller.
    for z,prefix,parent in [(-.34,'F',chest),(.52,'B',pelvis)]:
        for s,name in [(-1,'L'),(1,'R')]:
            upper=m.bone(prefix+'Leg.'+name,(s*.31,.72,z),parent);hock=m.bone(prefix+'Hock.'+name,(s*.46,.38,z-.08),upper);foot=m.bone(prefix+'Foot.'+name,(s*.39,.16,z-.30),hock)
            m.tube([(s*.27,.78,z),(s*.45,.54,z-.03),(s*.46,.35,z-.10)],[.105,.085,.055],slot=1,bone=upper,sides=7)
            m.tube([(s*.46,.36,z-.10),(s*.38,.20,z-.18),(s*.39,.12,z-.41)],[.070,.052,.024],slot=2,bone=hock,sides=7)
            for toe in [-.07,.07]:
                m.tube([(s*.39+toe,.13,z-.39),(s*.40+toe,.095,z-.58)],[.040,.004],slot=12,bone=foot,sides=6)
    # Segmented tail deliberately alternates solid and gap rhythm.
    parent=pelvis
    for i in range(6):
        z=.72+i*.34;y=.73-.03*i;x=.04*math.sin(i*.8)
        bone=m.bone('Tail'+str(i),(x,y,z),parent)
        # leave small discontinuities between pieces to echo the holed torso
        m.tube([(x,y,z+.02),(x+.03*math.sin(i),y-.02,z+.25)],[max(.035,.16-i*.020),max(.012,.12-i*.019)],slot=3 if i%2 else 4,bone=bone,sides=7)
        if i<5:m.plate((x,y+.10,z+.13),.14-i*.012,.22,normal=(0,1,0),up=(0,0,-1),slot=9,bone=bone,depth=.025)
        parent=bone
    durations={'idle':1.6,'walk':.76,'claw':.30,'breath':.52,'wall':.50,'burst':.62,'guard':.72,'hurt':.22,'defeat':.78}
    limbs=['FLeg.L','FLeg.R','BLeg.L','BLeg.R']
    for clip,duration in durations.items():
        times=np.linspace(0,duration,max(4,int(duration*30)+1));poses=[]
        for t in times:
            q=float(t/duration);wave=math.sin(q*math.pi);beat=math.sin(q*math.tau);pose={}
            pose['Chest']=([0,.022*beat if clip in ['idle','walk'] else 0,0],[0,.012*beat if clip=='idle' else 0,0])
            pose['Pelvis']=([0,-.018*beat if clip in ['idle','walk'] else 0,0],[0,0,0])
            if clip=='walk':
                for j,n in enumerate(limbs):pose[n]=([.24*math.sin(q*math.tau+j*math.pi),0,0],[0,0,0])
                pose['Neck']=([-.035*beat,0,0],[0,0,0])
            elif clip=='claw':
                pose['Chest']=([-.07*wave,-.30*wave,0],[0,0,-.08*wave]);pose['FLeg.R']=([-.62*wave,0,.28*wave],[0,0,0]);pose['Head']=([-.12*wave,0,0],[0,0,0])
            elif clip=='breath':
                pose['Neck']=([-.18*wave,0,0],[0,0,-.08*wave]);pose['Head']=([.10*wave,0,0],[0,0,-.10*wave]);pose['Jaw']=([.42*wave,0,0],[0,0,0])
            elif clip=='wall':
                pose['Chest']=([.12*wave,.26*wave,0],[0,.05*wave,0]);pose['Head']=([-.16*wave,0,0],[0,0,0]);pose['Jaw']=([.30*wave,0,0],[0,0,0])
            elif clip=='burst':
                # Phase Strike snaps low, then through the target line; authoritative gameplay still owns the hit.
                pose['Root']=([0,0,0],[0,-.10*wave,-.48*wave]);pose['Chest']=([-.16*wave,.42*wave,0],[0,0,0]);pose['Head']=([.11*wave,0,0],[0,0,0])
            elif clip=='guard':
                pose['Chest']=([.08,0,0],[0,-.04,0]);pose['Head']=([-.08,0,0],[0,0,0]);pose['FLeg.L']=([-.18,0,.12],[0,0,0]);pose['FLeg.R']=([-.18,0,-.12],[0,0,0])
            elif clip=='hurt':pose['Chest']=([0,0,.12*wave],[0,0,.06*wave]);pose['Head']=([-.14*wave,0,0],[0,0,0])
            elif clip=='defeat':pose['Root']=([0,0,-1.05*q],[0,-.14*q,0]);pose['Chest']=([0,0,.34*q],[0,0,0]);pose['Head']=([.18*q,0,0],[0,0,0])
            for i in range(6):pose['Tail'+str(i)]=([0,.07*math.sin(q*math.tau-i*.55),0],[0,0,0])
            poses.append(pose)
        m.animations[clip]=(times,poses)
    return m

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True);art.OUT=OUT;paint();entry=guardian().export()
    files={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.suffix in ['.glb','.png']}
    (OUT/'manifest.json').write_text(json.dumps({'source':'tools/build_shadow_guardian.py','asset':entry,'files':files},indent=2)+'\n')
    print(json.dumps(entry,indent=2))
