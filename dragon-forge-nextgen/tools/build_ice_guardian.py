#!/usr/bin/env python3
"""Offline Rime/egg authoring. Adds exports only; never rebakes Magma or shared atlas.
Uses the existing mesh/UV/glTF compiler. Assets ship committed; no build step to play.
"""
import json, math, hashlib, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import build_art as art
from pose_cleanup import matrix, quaternion, between
OUT=Path(__file__).resolve().parents[1]/'campaign'/'guardians'
OUT.mkdir(parents=True,exist_ok=True)
art.OUT=OUT

def paint():
    # Four-channel 1k atlas, hand-directed mineral ridges, frost specks, darker seams.
    rng=np.random.default_rng(69031)
    palette=[(38,70,95),(116,184,209),(222,237,236),(76,220,236), (50,89,120),(123,183,206),(63,120,152),(175,210,224), (108,229,238),(26,45,67),(88,136,160),(213,232,233),(38,62,86),(52,119,151),(122,181,204),(76,100,139)]
    base=Image.new('RGB',(1024,1024));orm=Image.new('RGB',(1024,1024));normal=Image.new('RGB',(1024,1024),(128,128,255));emission=Image.new('RGB',(1024,1024))
    for slot,color in enumerate(palette):
        y,x=np.mgrid[0:256,0:256];noise=rng.normal(0,1,(256,256));grains=np.sin(x*.13+y*.028)*.012
        height=Image.new('L',(256,256),185);d=ImageDraw.Draw(height)
        for i in range(15):
            a=int(rng.integers(0,256));b=int(rng.integers(0,256))
            d.line([(a,0),(a+18,80),(b,170),(b-18,256)],fill=110,width=2)
        h=np.array(height.filter(ImageFilter.GaussianBlur(.8)),float)/255
        variation=.88 +.10*(h-.5)+.08*np.sin(x*.018+y*.012)+noise*.007+grains
        pixels=np.clip(np.array(color)[None,None,:]*variation[:,:,None],0,255).astype('uint8')
        # Edges of each UV island get finer white mineral wear, without baked scene lighting.
        edge=np.minimum.reduce([x,y,255-x,255-y]);frost=(edge<12)&(rng.random((256,256))>.60)
        pixels[frost]=np.minimum(255,pixels[frost].astype(int)+24)
        tile=Image.fromarray(pixels);dx,dy=(slot%4)*256,(slot//4)*256;base.paste(tile,(dx,dy))
        packed=np.zeros((256,256,3),np.uint8);packed[:,:,0]=np.clip(220+h*35,0,255);packed[:,:,1]=np.clip(98+(1-h)*55+noise*3,0,255);packed[:,:,2]=10
        orm.paste(Image.fromarray(packed),(dx,dy))
        gy,gx=np.gradient(h);n=np.dstack([-gx*2,-gy*2,np.ones_like(h)]);n/=np.linalg.norm(n,axis=2)[:,:,None]
        normal.paste(Image.fromarray(np.clip((n*.5+.5)*255,0,255).astype('uint8')),(dx,dy))
        if slot in [3,8]:emission.paste(Image.new('RGB',(256,256),color),(dx,dy))
    for name,image in [('base',base),('orm',orm),('normal',normal),('emission',emission)]:image.save(OUT/f'atlas_{name}.png')

def ice():
    m=art.Mesh('ice_guardian');root=m.bone('Root',(0,0,0));body=m.bone('Body',(0,1.05,.15),root)
    neck=m.bone('Neck',(0,1.11,-.68),body);head=m.bone('Head',(0,1.23,-1.05),neck);jaw=m.bone('Jaw',(0,1.09,-1.17),head)
    m.tube([(0,.98,.95),(0,1.07,.5),(0,1.08,-.05),(0,1.10,-.6),(0,1.16,-.88)], [.32,.56,.58,.48,.28],[.34,.47,.46,.39,.25],slot=0,bone=body,sides=12)
    m.tube([(0,1.18,-.76),(0,1.22,-1.05),(0,1.18,-1.40),(0,1.11,-1.64)], [.27,.36,.30,.22],[.22,.25,.18,.10],slot=1,bone=head,sides=12)
    m.tube([(0,1.03,-1.12),(0,.98,-1.40),(0,.99,-1.59)],[.23,.27,.18],[.09,.065,.04],slot=0,bone=jaw,sides=10)
    m.box((0,1.04,-1.40),(.44,.05,.33),2,head,bevel=.02)
    for side in [-1,1]:
        m.plate((side*.31,1.27,-1.20),.17,.12,normal=(side,0,-.3),slot=8,bone=head,depth=.015)
        m.tube([(side*.24,1.37,-.93),(side*.39,1.64,-.71),(side*.43,1.78,-.52)],[.14,.095,.007],slot=2,bone=head,sides=6)
        for z in [-1.31,-1.47]:m.tube([(side*.2,1.045,z),(side*.20,.97,z)],[.04,.005],slot=2,bone=head,sides=6)
        for row,z in enumerate([-.55,-.10,.35,.80]):
            m.plate((side*(.46 if row!=3 else .35),1.21,z),.45,.51,normal=(side,.5,0),slot=1,bone=body,depth=.11,tint=.94+row*.018)
    for i,z in enumerate([-.68,-.29,.10,.49,.85]):
        m.tube([(0,1.39,z),(0,1.77+(.1 if i==1 else 0),z+.12),(0,1.95,z+.27)],[.17,.12,.004],[.12,.08,.004],slot=1,bone=body,sides=5)
    parent=body
    for i in range(4):
        z=1.0+i*.35;y=.98-i*.15;bone=m.bone(f'Tail{i}',(0,y,z),parent)
        m.tube([(0,y,z),(0,y-.15,z+.36)],[.24-i*.05,.20-i*.045],[.20-i*.035,.16-i*.03],slot=0,bone=bone,sides=10)
        m.tube([(0,y+.11,z+.12),(0,y+.36,z+.32)],[.10-i*.015,.002],slot=1,bone=bone,sides=5)
        parent=bone
    legs=[]
    for key,sign,z in [('FL',-1,-.62),('FR',1,-.62),('RL',-1,.63),('RR',1,.63)]:
        a=m.bone('Thigh.'+key,(sign*.45,1.05,z),body)
        b=m.bone('Hock.'+key,(sign*.60,.59,z-.32),a)
        c=m.bone('Foot.'+key,(sign*.65,.22,z-.03),b)
        m.tube([(sign*.43,.98,z),(sign*.54,.76,z-.16),(sign*.60,.59,z-.32)],[.24,.25,.16],slot=0,bone=a,sides=10)
        m.tube([(sign*.60,.59,z-.32),(sign*.63,.38,z-.18),(sign*.65,.23,z-.03)],[.16,.14,.13],slot=1,bone=b,sides=10)
        m.box((sign*.65,.14,z-.18),(.39,.18,.52),0,c,bevel=.04)
        for j in range(3):
            x=sign*.65+(j-1)*.13
            m.tube([(x,.15,z-.38),(x,.10,z-.60)],[.067,.005],[.045,.005],slot=2,bone=c,sides=6)
        m.plate((sign*.69,.73,z-.11),.4,.45,normal=(sign,.3,-.3),slot=1,bone=a,depth=.10)
        legs.append((key,sign,a,b,c))
    durations={'idle':1.8,'walk':.8,'claw':.32,'breath':.58,'wall':.5,'burst':.44,'guard':.8,'hurt':.24,'defeat':.8}
    for clip,duration in durations.items():
        times=np.linspace(0,duration,max(3,int(duration*30)+1));poses=[]
        for t in times:
            q=t/duration;wave=math.sin(math.pi*q);pose={}
            if clip=='idle':pose['Neck']=([.015*math.sin(q*math.tau),0,0],[0,0,0])
            if clip=='walk':pose['Body']=([0,0,0],[0,.025*(1-math.cos(q*math.tau*2)),0])
            if clip=='claw':pose.update({'Neck':([-.18*wave,0,0],[0,0,-.12*wave]),'Head':([.13*wave,0,0],[0,0,0]),'Jaw':([.36*wave,0,0],[0,0,0])})
            if clip=='breath':pose.update({'Neck':([-.1*wave,0,0],[0,.035*wave,0]),'Head':([-.03*wave,0,0],[0,0,0]),'Jaw':([.48*wave,0,0],[0,0,0])})
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
    for f in sorted(OUT.iterdir()):
        if f.suffix in ['.png','.glb']:manifest['files'][f.name]=hashlib.sha256(f.read_bytes()).hexdigest()
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps(entries,indent=2))
