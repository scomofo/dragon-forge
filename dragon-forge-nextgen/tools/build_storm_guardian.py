#!/usr/bin/env python3
"""Original offline parametric Arc/egg authoring. Committed exports need no runtime build.
Hovering winged drake, not a scaled/recolored Magma or Rime. Reuses the mesh compiler,
not the earlier meshes or animation tracks. Coordinates: metres, Y up, forward -Z.
"""
from pathlib import Path
import hashlib, json, math
import numpy as np
import build_art as art
OUT = Path(__file__).resolve().parents[1] / 'campaign' / 'fusion_assets'

def paint():
    from creature_detail import paint_hide
    palette=[(51,51,68),(87,77,108),(181,172,154),(178,143,244),
             (63,69,94),(142,112,70),(102,80,102),(157,172,195),
             (110,213,237),(25,27,43),(72,72,99),(199,168,92),
             (36,34,54),(57,91,128),(177,158,89),(13,15,23)]
    paint_hide(OUT,palette,membrane=(6,),seed=73216)

def guardian():
    from creature_detail import eye, teeth, bat_wing, scute_row
    m=art.Mesh('storm_guardian'); root=m.bone('Root',(0,0,0))
    body=m.bone('Body',(0,1.30,.18),root)
    neck=m.bone('Neck',(0,1.45,-.48),body); head=m.bone('Head',(0,1.72,-.94),neck)
    jaw=m.bone('Jaw',(0,1.58,-1.08),head)
    m.tube([(0,1.24,.94),(0,1.30,.43),(0,1.34,-.08),(0,1.45,-.55)], [.19,.31,.41,.21], [.22,.35,.43,.22],slot=0,sides=24,
           weights=[[(body,1)],[(body,1)],[(body,1)],[(body,.6),(neck,.4)]])
    m.tube([(0,1.42,-.46),(0,1.66,-.72),(0,1.74,-1.01),(0,1.68,-1.43)], [.19,.21,.26,.14],[.20,.22,.21,.075],slot=1,bone=head,sides=24)
    m.tube([(0,1.565,-1.0),(0,1.55,-1.22),(0,1.575,-1.43)],[.18,.195,.12],[.068,.052,.022],slot=0,bone=jaw,sides=18)
    m.tube([(0,1.605,-1.02),(0,1.60,-1.39)],[.185,.125],[.016,.012],slot=15,bone=head,sides=12)
    m.tube([(0,1.584,-1.03),(0,1.590,-1.39)],[.17,.115],[.016,.008],slot=15,bone=jaw,sides=12)
    teeth(m,head,jaw,back=-1.08,front=-1.37,y=1.612,width=.185,count=6,scale=.56)
    m.plate((0,1.34,-.43),.14,.30,normal=(0,.2,-1),slot=8,bone=body,depth=.026)
    for s in [-1,1]:
        eye(m,(s*.239,1.79,-1.045),(s,.16,-.26),.046,head,hide=1)
        m.tube([(s*.18,1.87,-.92),(s*.32,2.06,-.65),(s*.30,2.23,-.48)],[.080,.043,.003],slot=2,bone=head,sides=14)
        m.plate((s*.10,1.72,-1.428),.031,.07,normal=(s*.4,.3,-1),slot=15,bone=head,depth=.004)
        m.tube([(s*.24,1.65,-.9),(s*.5,1.72,-.65),(s*.61,1.80,-.45)],[.085,.055,.004],slot=5,bone=head,sides=6)
        arm=m.bone('Talon.'+str(s),(s*.27,1.22,-.2),body)
        m.tube([(s*.28,1.24,-.25),(s*.45,1.10,-.24),(s*.53,.98,-.47),(s*.48,.85,-.72)],[.145,.13,.078,.05],slot=0,bone=arm,sides=16)
        for j in range(2):m.tube([(s*(.44+j*.09),.88,-.70),(s*(.47+j*.09),.76,-.81)],[.042,.004],slot=2,bone=arm,sides=6)
        # Cambered, scalloped flight membrane and supporting fingers replace slabs.
        wing=m.bone('Wing.'+str(s),(s*.24,1.44,.04),body)
        tip=m.bone('WingTip.'+str(s),(s*1.20,1.56,.23),wing)
        bat_wing(m,s,wing,tip)
    parent=body
    tail_path=[];tail_weights=[]
    for i in range(6):
        z=.75+i*.31;y=1.26-.065*i;bone=m.bone('Tail'+str(i),(0,y,z),parent)
        tail_path.append((0,y,z));tail_weights.append([(bone,1)])
        m.plate((0,y+.12,z+.13),.24-i*.02,.28,normal=(0,1,0),up=(0,0,-1),slot=5 if i%2 else 1,bone=bone,depth=.05)
        parent=bone
    tail_path.append((0,.87,2.64));tail_weights.append([(parent,1)])
    m.tube(tail_path,[.19,.16,.13,.10,.073,.043,.004],slot=0,sides=18,weights=tail_weights)
    scute_row(m,[(0,1.67-i*.038,-.24+i*.20) for i in range(6)], [.22,.24,.23,.21,.18,.14],body,depth=.025)
    durations={'idle':1.8,'walk':.8,'claw':.33,'breath':.60,'wall':.54,'burst':.76,'guard':.8,'hurt':.24,'defeat':.8}
    for clip,duration in durations.items():
        times=np.linspace(0,duration,max(3,int(duration*30)+1));poses=[]
        for t in times:
            q=t/duration;wave=math.sin(q*math.pi);beat=math.sin(q*math.tau);pose={}
            if clip in ['idle','walk']:
                pose['Body']=([-.055 if clip=='walk' else 0,0,0],[0,.045*beat,0])
            if clip=='claw':pose['Neck']=([-.22*wave,0,0],[0,0,-.13*wave])
            if clip=='breath':pose.update({'Head':([-.10*wave,0,0],[0,0,0]),'Jaw':([-.40*wave,0,0],[0,0,0])})
            if clip in ['wall','burst']:pose['Body']=([-.08*wave,0,0],[0,.14*wave,0])
            if clip=='guard':pose['Head']=([.12,0,0],[0,0,0])
            if clip=='hurt':pose['Body']=([0,0,.1*wave],[0,0,.07*wave])
            if clip=='defeat':pose['Body']=([0,0,.45*q],[0,-.76*q,0])
            for s in [-1,1]:
                angle=(.08+.24*beat) if clip in ['idle','walk'] else (.24*wave)
                if clip=='guard':angle=-.5
                if clip=='defeat':angle=.6*q
                pose['Wing.'+str(s)]=([0,0,s*angle],[0,0,0])
                # Distal flight surface trails the power stroke rather than
                # rotating like a second rigid board at the same instant.
                distal=(.045+.13*math.sin(q*math.tau-.60)) if clip in ['idle','walk'] else angle*.5
                pose['WingTip.'+str(s)]=([0,0,s*distal],[0,0,0])
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
    from creature_detail import provenance
    (OUT/'manifest.json').write_text(json.dumps({'source':'tools/build_storm_guardian.py','assets':entries,'files':files,**provenance(__file__)},indent=2)+'\n')
    print(json.dumps(entries,indent=2))
