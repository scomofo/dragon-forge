#!/usr/bin/env python3
"""Offline Rime/egg authoring. Adds exports only; never rebakes Magma or shared atlas.
Uses the existing mesh/UV/glTF compiler. Assets ship committed; no build step to play.
"""
import json, math, hashlib, sys
from pathlib import Path
import numpy as np
import build_art as art
from pose_cleanup import matrix, quaternion, between
OUT=Path(__file__).resolve().parents[1]/'campaign'/'guardians'
OUT.mkdir(parents=True,exist_ok=True)
art.OUT=OUT

def paint():
    from creature_detail import paint_hide
    palette=[(48,73,85),(117,157,167),(207,222,213),(76,220,236),
             (50,89,120),(123,183,206),(63,120,152),(175,210,224),
             (108,229,238),(26,45,67),(88,136,160),(213,232,233),
             (38,62,86),(52,119,151),(116,172,192),(12,23,28)]
    paint_hide(OUT,palette,glow=(3,8),seed=69031)

def ice():
    from creature_detail import eye, teeth, scute_row
    m=art.Mesh('ice_guardian');root=m.bone('Root',(0,0,0));body=m.bone('Body',(0,1.05,.15),root)
    neck=m.bone('Neck',(0,1.11,-.68),body);head=m.bone('Head',(0,1.23,-1.05),neck);jaw=m.bone('Jaw',(0,1.09,-1.17),head)
    m.tube([(0,.98,.95),(0,1.07,.5),(0,1.08,-.05),(0,1.10,-.6),(0,1.16,-.88)], [.30,.51,.58,.45,.26],[.31,.40,.48,.40,.23],slot=0,
           sides=24,weights=[[(body,1)],[(body,1)],[(body,1)],[(body,.65),(neck,.35)],[(neck,.55),(head,.45)]])
    m.tube([(0,1.18,-.76),(0,1.23,-1.05),(0,1.18,-1.40),(0,1.13,-1.65)], [.25,.32,.25,.17],[.22,.22,.13,.075],slot=1,bone=head,sides=24)
    m.tube([(0,1.05,-1.09),(0,1.01,-1.36),(0,1.04,-1.62)],[.23,.23,.15],[.075,.055,.026],slot=0,bone=jaw,sides=20)
    m.tube([(0,1.075,-1.10),(0,1.075,-1.61)],[.22,.15],[.018,.012],slot=15,bone=head,sides=12)
    m.tube([(0,1.055,-1.15),(0,1.065,-1.59)],[.20,.14],[.015,.010],slot=15,bone=jaw,sides=12)
    teeth(m,head,jaw,back=-1.14,front=-1.56,y=1.085,width=.223,count=7,scale=.63)
    for side in [-1,1]:
        eye(m,(side*.297,1.295,-1.16),(side,.16,-.27),.050,head,hide=1)
        m.tube([(side*.23,1.37,-.93),(side*.34,1.57,-.73),(side*.41,1.75,-.50)],[.102,.063,.004],slot=2,bone=head,sides=12)
        m.tube([(side*.25,1.22,-.98),(side*.30,1.125,-1.10),(side*.22,1.09,-1.31)],[.10,.081,.02],slot=1,bone=head,sides=16)
        m.plate((side*.128,1.17,-1.65),.035,.08,normal=(side*.4,.2,-1),slot=15,bone=head,depth=.004)
        for row,z in enumerate([-.55,-.10,.35,.80]):
            m.plate((side*(.46 if row!=3 else .35),1.21,z),.45,.51,normal=(side,.5,0),slot=1,bone=body,depth=.11,tint=.94+row*.018)
    for i,z in enumerate([-.68,-.29,.10,.49,.85]):
        m.tube([(0,1.39,z),(0,1.77+(.1 if i==1 else 0),z+.12),(0,1.95,z+.27)],[.17,.12,.004],[.12,.08,.004],slot=7,bone=body,sides=7)
    parent=body
    tail_path=[];tail_weights=[]
    for i in range(4):
        z=1.0+i*.35;y=.98-i*.15;bone=m.bone(f'Tail{i}',(0,y,z),parent)
        tail_path.append((0,y,z));tail_weights.append([(bone,1)])
        m.tube([(0,y+.11,z+.12),(0,y+.36,z+.32)],[.10-i*.015,.002],slot=1,bone=bone,sides=5)
        parent=bone
    tail_path.append((0,.42,2.48));tail_weights.append([(parent,1)])
    m.tube(tail_path,[.25,.20,.14,.09,.004],[.20,.16,.12,.075,.003],slot=0,sides=20,weights=tail_weights)
    legs=[]
    for key,sign,z in [('FL',-1,-.62),('FR',1,-.62),('RL',-1,.63),('RR',1,.63)]:
        a=m.bone('Thigh.'+key,(sign*.45,1.05,z),body)
        b=m.bone('Hock.'+key,(sign*.60,.59,z-.32),a)
        c=m.bone('Foot.'+key,(sign*.65,.22,z-.03),b)
        m.tube([(sign*.43,.98,z),(sign*.54,.76,z-.16),(sign*.60,.59,z-.32),
                (sign*.63,.38,z-.18),(sign*.65,.23,z-.03)],
               [.26,.27,.155,.12,.125],slot=0,sides=20,
               weights=[[(body,.35),(a,.65)],[(a,1)],[(a,.45),(b,.55)],[(b,1)],[(b,.30),(c,.70)]])
        m.tube([(sign*.65,.18,z+.03),(sign*.65,.14,z-.18),(sign*.65,.12,z-.35)],
               [.13,.19,.16],[.105,.09,.062],slot=0,bone=c,sides=16)
        for j in range(3):
            x=sign*.65+(j-1)*.13
            m.tube([(x,.13,z-.23),(x,.11,z-.37),(x,.09,z-.44)],[.075,.07,.042],[.07,.05,.038],slot=1,bone=c,sides=12)
            m.tube([(x,.105,z-.41),(x,.083,z-.53),(x,.068,z-.60)],[.045,.026,.002],slot=2,bone=c,sides=10)
        m.plate((sign*.69,.73,z-.11),.4,.45,normal=(sign,.3,-.3),slot=1,bone=a,depth=.10)
        legs.append((key,sign,a,b,c))
    for sign in [-1,1]:
        for row in range(3):
            scute_row(m,[(sign*(.40-row*.025),1.40+row*.015,z) for z in [-.34,-.09,.16,.41,.66]],
                      [.22]*5,body,slot=1,normal=(sign*.65,.75,0),depth=.022)
    durations={'idle':1.8,'walk':.8,'claw':.32,'breath':.58,'wall':.5,'burst':.44,'guard':.8,'hurt':.24,'defeat':.8}
    for clip,duration in durations.items():
        times=np.linspace(0,duration,max(3,int(duration*30)+1));poses=[]
        for t in times:
            q=t/duration;wave=math.sin(math.pi*q);pose={}
            if clip=='idle':pose['Neck']=([.015*math.sin(q*math.tau),0,0],[0,0,0])
            if clip=='walk':pose['Body']=([0,0,0],[0,.025*(1-math.cos(q*math.tau*2)),0])
            if clip=='claw':pose.update({'Neck':([-.18*wave,0,0],[0,0,-.12*wave]),'Head':([.13*wave,0,0],[0,0,0]),'Jaw':([-.32*wave,0,0],[0,0,0])})
            if clip=='breath':pose.update({'Neck':([-.1*wave,0,0],[0,.035*wave,0]),'Head':([-.03*wave,0,0],[0,0,0]),'Jaw':([-.44*wave,0,0],[0,0,0])})
            if clip in ['wall','burst']:pose.update({'Body':([0,0,0],[0,-.065*wave,0]),'Neck':([-.12*wave,0,0],[0,0,0])})
            if clip=='guard':pose.update({'Body':([0,0,0],[0,-.05,0]),'Head':([.1,0,0],[0,0,0])})
            if clip=='hurt':pose['Body']=([0,.06*wave,0],[0,0,.02*wave])
            if clip=='defeat':pose['Body']=([0,0,q*.50],[0,-.65*q,0])
            for i in range(4):pose[f'Tail{i}']=([0,(.03 if clip in ['idle','walk'] else .1)*math.sin(q*math.tau+i*.5),0],[0,0,0])
            # Bake simple planar leg IK; preserve limb lengths and level sole pads.
            if clip!='defeat':
                def trs():
                    out=[]
                    for name,pos,parent in m.bones:
                        r,off=pose.get(name,([0,0,0],[0,0,0]));v=np.eye(4);v[:3,:3]=matrix(art.quat(r) if len(r)==3 else r);v[:3,3]=pos-(m.bones[parent][1] if parent is not None else 0)+off
                        out.append(v if parent is None else out[parent]@v)
                    return out
                def rotate(i,rot):
                    parent=m.bones[i][2];pose[m.bones[i][0]]=(quaternion(trs()[parent][:3,:3].T@rot),pose.get(m.bones[i][0],([0,0,0],[0,0,0]))[1])
                for key,sign,a,b,c in legs:
                    target=m.bones[c][1].copy()
                    if clip=='walk':
                        phase=(q+(.5 if key in ['FR','RL'] else 0))%1
                        if phase<.58:target[2]+=-.25+.5*phase/.58
                        else:
                            swing=(phase-.58)/.42;target[2]+=.25-.5*swing;target[1]+=.12*math.sin(swing*math.pi)
                    tr=trs();h,k,f=[tr[i][:3,3] for i in [a,b,c]];l1=np.linalg.norm(k-h);l2=np.linalg.norm(f-k);d=target-h;dist=np.clip(np.linalg.norm(d),.02,l1+l2-.002);axis=art.unit(d);pole=np.array([sign*.3,0,-1.]);pole=art.unit(pole-axis*np.dot(axis,pole));along=(l1*l1-l2*l2+dist*dist)/(2*dist);knee=h+axis*along+pole*math.sqrt(max(0,l1*l1-along*along))
                    rotate(a,between(k-h,knee-h)@tr[a][:3,:3]);tr=trs();k,f=[tr[i][:3,3] for i in [b,c]];rotate(b,between(f-k,h+axis*dist-k)@tr[b][:3,:3]);rotate(c,np.eye(3))
            poses.append(pose)
        m.animations[clip]=(times,poses)
    return m

def egg():
    m=art.Mesh('ice_egg');m.tube([(0,.1,0),(0,.25,0),(0,.65,0),(0,.95,0),(0,1.18,0)],[.16,.36,.44,.33,.025],[.16,.36,.44,.33,.025],slot=1,sides=8)
    for side in [-1,1]:m.plate((side*.27,.64,-.25),.30,.48,normal=(side*.5,0,-1),slot=2,depth=.04)
    m.plate((0,.62,-.42),.21,.40,normal=(0,0,-1),slot=8,depth=.03)
    return m

if __name__=='__main__':
    paint();entries=[ice().export(),egg().export()]
    manifest={'source':'tools/build_ice_guardian.py','identity':'Ice Dragon: faceted quadruped; Rime is its campaign call name.','assets':entries,'files':{}}
    from creature_detail import provenance
    manifest.update(provenance(__file__))
    for f in sorted(OUT.iterdir()):
        if f.suffix in ['.png','.glb']:manifest['files'][f.name]=hashlib.sha256(f.read_bytes()).hexdigest()
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps(entries,indent=2))
