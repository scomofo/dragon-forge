#!/usr/bin/env python3
"""Offline Nox/Venom authoring: low frilled wyrm, metres/Y-up/-Z-front.
Committed exports are runtime-ready; Python is only an editable authoring path.
"""
from pathlib import Path
import hashlib,json,math
import numpy as np
import build_art as art
OUT=Path(__file__).resolve().parents[1]/'campaign'/'venom'
PALETTE=[(24,34,29),(49,72,50),(84,118,58),(136,168,72),
         (38,27,48),(79,45,91),(129,70,139),(183,102,174),
         (145,215,68),(18,24,21),(66,83,47),(181,198,91),
         (31,42,35),(63,96,61),(105,137,70),(198,236,93)]

def paint():
    from creature_detail import paint_hide
    palette=PALETTE.copy()
    palette[3]=(187,176,126);palette[14]=(157,161,47);palette[15]=(12,20,13)
    paint_hide(OUT,palette,skin=(0,1,2),horn=(3,),membrane=(6,),glow=(8,),seed=91331)

def guardian():
    from creature_detail import eye, teeth, membrane, scute_row
    m=art.Mesh('venom_guardian');root=m.bone('Root',(0,0,0));body=m.bone('Body',(0,.78,.18),root)
    neck=m.bone('Neck',(0,1.02,-.52),body);head=m.bone('Head',(0,1.31,-1.05),neck);jaw=m.bone('Jaw',(0,1.16,-1.28),head)
    m.tube([(0,.70,.82),(0,.80,.30),(0,.84,-.18),(0,1.01,-.62)],[.24,.42,.45,.26],[.27,.41,.44,.24],slot=1,sides=24,
           weights=[[(body,1)],[(body,1)],[(body,1)],[(body,.45),(neck,.55)]])
    m.tube([(0,.98,-.54),(0,1.20,-.82),(0,1.32,-1.13),(0,1.27,-1.51)],[.23,.25,.27,.13],[.23,.26,.19,.064],slot=2,bone=head,sides=22)
    m.tube([(0,1.17,-1.10),(0,1.13,-1.35),(0,1.17,-1.51)],[.20,.19,.105],[.058,.045,.017],slot=0,bone=jaw,sides=18)
    m.tube([(0,1.192,-1.11),(0,1.19,-1.48)],[.20,.11],[.017,.012],slot=15,bone=head,sides=12)
    m.tube([(0,1.175,-1.14),(0,1.177,-1.48)],[.18,.10],[.013,.009],slot=15,bone=jaw,sides=12)
    teeth(m,head,jaw,back=-1.15,front=-1.45,y=1.20,width=.184,count=7,scale=.59,slot=3)
    # Bright throat sac and split eye marks.
    m.plate((0,1.03,-.76),.21,.36,normal=(0,.1,-1),slot=8,bone=neck,depth=.023)
    for s in [-1,1]:
        eye(m,(s*.25,1.355,-1.16),(s,.1,-.30),.045,head,hide=2)
        m.plate((s*.085,1.305,-1.51),.029,.064,normal=(s*.4,.3,-1),slot=15,bone=head,depth=.004)
        # Broad radial frill establishes the silhouette.
        frill=m.bone('Frill.'+str(s),(s*.24,1.28,-.78),neck)
        hub=np.array([s*.24,1.28,-.78])
        tips=[(s*.27,1.92,-.61),(s*.67,1.86,-.62),(s*.96,1.54,-.58),
              (s*.92,1.12,-.53),(s*.61,.86,-.50),(s*.27,.93,-.58)]
        membrane(m,hub,tips,lambda p:[(frill,1)],slot=6,thickness=.007,scallop=.13)
        for endpoint in tips:
            end=np.array(endpoint);mid=hub*.5+end*.5+[0,0,-.03]
            m.tube([hub,mid,end],[.027,.018,.003],slot=2,bone=frill,sides=10)
        m.tube([(s*.18,1.45,-1.0),(s*.34,1.70,-.87),(s*.31,1.86,-.79)],[.075,.045,.003],slot=3,bone=head,sides=6)
    # Four low limbs keep Nox grounded while the body reads as a wyrm rather than a quadruped copy.
    for z,prefix in [(-.22,'F'),(.48,'B')]:
        for s,name in [(-1,'L'),(1,'R')]:
            upper=m.bone(prefix+'Leg.'+name,(s*.34,.64,z),body);foot=m.bone(prefix+'Foot.'+name,(s*.48,.22,z-.18),upper)
            m.tube([(s*.34,.66,z),(s*.52,.40,z-.08),(s*.49,.18,z-.24)],[.145,.10,.057],slot=0,sides=16,
                   weights=[[(body,.25),(upper,.75)],[(upper,1)],[(upper,.3),(foot,.7)]])
            for j in range(3):
                x=s*.49+(j-1)*.066
                m.tube([(x,.15,z-.23),(x,.10,z-.36),(x,.085,z-.43)],[.043,.035,.023],slot=2,bone=foot,sides=10)
                m.tube([(x,.086,z-.41),(x,.068,z-.49),(x,.07,z-.54)],[.025,.016,.002],slot=3,bone=foot,sides=9)
    parent=body
    tail_path=[];tail_weights=[];tail_radii=[]
    for i in range(7):
        z=.78+i*.31;y=.72-.035*i;bone=m.bone('Tail'+str(i),(0,y,z),parent)
        r=max(.04,.22-i*.026)
        tail_path.append((0,y,z));tail_weights.append([(bone,1)]);tail_radii.append(r)
        if i<5:m.plate((0,y+.13,z+.13),.21-i*.018,.27,normal=(0,1,0),up=(0,0,-1),slot=3,bone=bone,depth=.038)
        parent=bone
    tail_path.append((0,.47,3.00));tail_weights.append([(parent,1)]);tail_radii.append(.003)
    m.tube(tail_path,tail_radii,slot=1,sides=20,weights=tail_weights)
    for s in [-1,1]:
        scute_row(m,[(s*.31,1.08-i*.04,-.22+i*.22) for i in range(5)],[.20]*5,body,
                  slot=2,normal=(s*.6,.8,0),depth=.018)
    durations={'idle':1.7,'walk':.82,'claw':.34,'breath':.58,'wall':.56,'burst':.72,'guard':.76,'hurt':.24,'defeat':.85}
    limbs=['FLeg.L','FLeg.R','BLeg.L','BLeg.R']
    for clip,duration in durations.items():
        times=np.linspace(0,duration,max(4,int(duration*30)+1));poses=[]
        for t in times:
            q=float(t/duration);wave=math.sin(q*math.pi);beat=math.sin(q*math.tau);pose={}
            pose['Body']=([0,.010*beat if clip=='idle' else 0,0],[0,.008*beat if clip in ['idle','walk'] else 0,0])
            if clip=='walk':
                pose['Body']=([0,.015*beat,0],[0,.021*beat,0])
                for j,n in enumerate(limbs):pose[n]=([.18*math.sin(q*math.tau+j*math.pi),0,0],[0,0,0])
            elif clip=='claw':pose['Head']=([-.24*wave,0,-.10*wave],[0,0,0]);pose['Jaw']=([-.32*wave,0,0],[0,0,0])
            elif clip=='breath':pose['Neck']=([-.14*wave,0,0],[0,0,-.08*wave]);pose['Jaw']=([-.46*wave,0,0],[0,0,0])
            elif clip=='wall':pose['Head']=([.10*wave,0,0],[0,.20*wave,0]);pose['Jaw']=([-.35*wave,0,0],[0,0,0])
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
    from creature_detail import provenance
    (OUT/'manifest.json').write_text(json.dumps({'source':'tools/build_venom_guardian.py','asset':entry,'files':files,**provenance(__file__)},indent=2)+'\n')
    print(json.dumps(entry,indent=2))
