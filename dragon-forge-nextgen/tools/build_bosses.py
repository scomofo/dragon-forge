#!/usr/bin/env python3
"""Original offline campaign boss art. No downloaded models or runtime mesh baking.
Five body plans share one PBR trim atlas, not one recolored mesh. Metres, Y up, -Z front.
Attack clips are normalized: tell ends at contact; strike begins at that identical pose.
"""
from pathlib import Path
import hashlib, json, math
import numpy as np
from PIL import Image
import build_art as art
OUT = Path(__file__).resolve().parents[1] / 'campaign' / 'bosses' / 'assets'
PATTERNS = {'buffer_overflow':['slam','ring'], 'memory_leak':['beam','slam'],
            'stack_overflow':['fan','beam'], 'mirror_admin':['ring','beam','fan'],
            'singularity':['ring','beam','fan']}
PALETTE = [(33,39,48),(110,61,41),(186,165,126),(248,137,38),
           (43,61,76),(168,103,61),(64,132,152),(171,184,204),
           (57,207,220),(14,18,27),(64,43,100),(155,93,218),
           (33,31,48),(149,199,216),(69,49,107),(220,222,255)]

def paint():
    rng = np.random.default_rng(914207)
    maps = {k:Image.new('RGB',(1024,1024)) for k in ['base','orm','normal','emission']}
    y,x = np.mgrid[:256,:256]
    edge = np.minimum.reduce([x,y,255-x,255-y])
    for i,c in enumerate(PALETTE):
        grain=rng.normal(0,1,(256,256)); bands=np.sin(x*.031+np.sin(y*.04))* .03
        seams=(np.abs(np.sin((x+y*.17)*.044))<.03)
        scratches=(rng.random((256,256))>.987)&(edge<22)
        h=.6+bands+grain*.003-seams*.075
        base=np.clip(np.array(c)[None,None,:]*(.97+(h-.6)[:,:,None]*.28)+scratches[:,:,None]*24,0,255).astype('uint8')
        orm=np.empty_like(base);orm[:,:,0]=np.clip(246-seams*24,0,255)
        rough=60 if i==7 else (132 if i in [1,4,5] else 185)
        orm[:,:,1]=np.clip(rough+grain*3+seams*18-scratches*20,0,255);orm[:,:,2]=225 if i==7 else (155 if i in [1,4,5] else 0)
        gy,gx=np.gradient(h);n=np.dstack([-gx*3,-gy*3,np.ones_like(h)]);n/=np.linalg.norm(n,axis=2)[:,:,None]
        normal=np.clip((n*.5+.5)*255,0,255).astype('uint8')
        emission=np.zeros_like(base)
        if i in [3,8,11,15]:emission=np.broadcast_to(np.array(c,dtype='uint8'),base.shape).copy()
        for k,d in [('base',base),('orm',orm),('normal',normal),('emission',emission)]:maps[k].paste(Image.fromarray(d),(i%4*256,i//4*256))
    for k,im in maps.items():im.save(OUT/f'atlas_{k}.png')

def gem(m,at,r,slot,bone):
    x,y,z=at
    m.tube([(x,y-r,z),(x,y,z),(x,y+r,z)],[.008,r,.008],slot=slot,bone=bone,sides=8)

def core(m,at,r,slot,bone):
    x,y,z=at
    m.ring(at,r,.07,slot=7 if slot!=3 else 5,bone=bone,axis='z',segments=20)
    m.plate((x,y,z-.03),r*1.3,r*1.45,normal=(0,0,-1),slot=slot,bone=bone,depth=.065)

def buffer():
    m=art.Mesh('buffer_overflow');root=m.bone('Root',(0,0,0));b=m.bone('Core',(0,1.42,0),root)
    # Broad low storage engine. Track runners, not a humanoid with different colors.
    m.box((0,.68,.05),(1.5,.58,1.68),slot=0,bone=root,bevel=.09)
    for s in [-1,1]:
        m.box((s*.89,.365,.08),(.40,.54,2.10),slot=9,bone=root,bevel=.07)
        for k in range(9):m.box((s*.89,.095,-.83+k*.23),(.48,.10,.15),slot=4,bone=root,bevel=.015)
        for j in range(3):
            axle=m.bone(f'Wheel{s}.{j}',(s*.91,.365,-.62+j*.67),root)
            m.tube([(s*.76,.365,-.62+j*.67),(s*1.15,.365,-.62+j*.67)],[.26,.26],slot=5,bone=axle,sides=12)
            m.box((s*1.16,.365,-.62+j*.67),(.02,.08,.4),slot=7,bone=axle,bevel=.007)
        arm=m.bone('ArmL' if s<0 else 'ArmR',(s*.72,1.42,-.18),b)
        m.tube([(s*.67,1.47,-.10),(s*1.18,1.24,-.38),(s*1.08,.97,-.86)],[.24,.25,.20],slot=5,bone=arm,sides=8)
        m.box((s*1.10,.89,-.99),(.50,.52,.65),slot=1,bone=arm,bevel=.08)
        m.box((s*1.10,.91,-1.34),(.33,.30,.09),slot=3,bone=arm,bevel=.025)
        shell=m.bone('ShellL' if s<0 else 'ShellR',(s*.48,1.68,.10),b)
        for j in range(3):
            m.box((s*.48,1.12+j*.34,.10),( .80,.29,1.12),slot=1 if j%2==0 else 4,bone=shell,bevel=.05)
            m.box((s*.50,1.13+j*.34,-.49),(.65,.09,.07),slot=3,bone=shell,bevel=.02)
        m.tube([(s*.46,1.88,.53),(s*.46,2.37,.53)],[.18,.18],slot=0,bone=shell,sides=10)
        m.ring((s*.46,2.33,.53),.18,.035,slot=5,bone=shell,segments=12)
    core(m,(0,1.43,-.67),.31,3,b)
    head=m.bone('Crown',(0,2.08,-.18),b)
    m.box((0,2.04,-.20),(.64,.24,.52),slot=0,bone=head)
    m.box((0,2.05,-.48),(.43,.065,.06),slot=3,bone=head,bevel=.01)
    return m

def memory():
    m=art.Mesh('memory_leak');r=m.bone('Root',(0,0,0));b=m.bone('Core',(0,1.82,0),r)
    # Cryogenic archive bell; an open cloak with five dangling memory ribbons.
    m.tube([(0,1.44,.06),(0,2.02,.08),(0,2.61,.08)],[.47,.77,.48],[.35,.51,.36],slot=6,bone=b,sides=8)
    c=m.bone('Crown',(0,2.61,.08),b)
    m.tube([(0,2.47,.05),(0,2.79,.08),(0,3.23,.10)],[.76,.43,.015],slot=13,bone=c,sides=8)
    for s in [-1,1]:
        arm=m.bone('ArmL' if s<0 else 'ArmR',(s*.65,2.2,.04),b)
        m.plate((s*.83,1.92,.04),.68,1.63,normal=(s*.8,.1,-.3),slot=13,bone=arm,depth=.11)
        m.tube([(s*.84,2.48,.05),(s*1.16,2.93,.16),(s*1.25,3.2,.1)],[.12,.09,.006],slot=13,bone=arm,sides=7)
    core(m,(0,2.11,-.48),.34,8,b)
    m.plate((0,2.53,-.46),.49,.19,normal=(0,0,-1),slot=9,bone=c,depth=.03)
    for j in range(5):
        x=(j-2)*.27;z=.25 if j%2==0 else -.08
        rib=m.bone(f'Ribbon{j}',(x,1.52,z),b)
        m.tube([(x,1.57,z),(x*1.5,1.1,z+.10),(x*1.15,.58,z+.18),(x*1.6,.25,z+.03)],[.105,.08,.06,.007],slot=6 if j%2 else 13,bone=rib,sides=8)
        gem(m,(x*1.5,.7,z+.10),.10,8,rib)
    for j in range(4):gem(m,((j-1.5)*.31,2.92+.12*(j%2),.15),.15,13,c)
    return m

def stack():
    m=art.Mesh('stack_overflow');r=m.bone('Root',(0,0,0));b=m.bone('Core',(0,1.87,0),r)
    # Floating offset compute tower and three radial emitters.
    gem(m,(0,1.89,0),.57,11,b)
    for j in range(4):
        y=.70+j*.64;layer=m.bone(f'Layer{j}',(0,y,0),b)
        m.box((.12*(-1)**j,y,0),(1.25-j*.055,.31,1.02),slot=4 if j%2==0 else 10,bone=layer,bevel=.07)
        m.ring((0,y+.17,0),.66,.035,slot=11,bone=layer,segments=12)
        for s in [-1,1]:m.box((s*.34,y,-.55),(.14,.1,.065),slot=7,bone=layer,bevel=.008)
    c=m.bone('Crown',(0,2.81,0),b)
    for s in [-1,0,1]:
        arm=m.bone('ArmL' if s<0 else ('ArmR' if s>0 else 'ArmC'),(s*.55,2.39,0),b)
        x=s*1.1;y=2.69+.55*(s==0)
        m.tube([(s*.49,2.35,.03),(x,2.39,0),(x,y,0)],[.14,.12,.08],slot=7,bone=arm,sides=8)
        gem(m,(x,y+.14,0),.27,11,arm)
        m.ring((x,y+.14,0),.30,.025,slot=7,bone=arm,segments=12,axis='z')
    core(m,(0,1.88,-.58),.26,11,b)
    return m

def admin():
    m=art.Mesh('mirror_admin');r=m.bone('Root',(0,0,0));b=m.bone('Core',(0,1.95,0),r)
    # Formal split mantle, angular shoulders, a chest eye and a ceremonial seal.
    m.tube([(0,.44,.10),(0,1.18,.11),(0,1.93,.04),(0,2.32,0)],[.60,.44,.53,.55],[.30,.32,.34,.25],slot=12,bone=b,sides=8)
    c=m.bone('Crown',(0,2.66,-.06),b)
    m.box((0,2.62,-.07),(.47,.59,.37),slot=7,bone=c,bevel=.06)
    m.box((0,2.69,-.28),(.31,.045,.045),slot=11,bone=c,bevel=.008)
    m.ring((0,2.65,.18),.54,.047,slot=7,bone=c,axis='z',segments=16,start=.15,end=math.tau-.15)
    core(m,(0,2.04,-.38),.28,15,b)
    m.plate((0,2.04,-.49),.065,.25,normal=(0,0,-1),slot=9,bone=b,depth=.02)
    for s in [-1,1]:
        arm=m.bone('ArmL' if s<0 else 'ArmR',(s*.52,2.21,0),b)
        m.plate((s*.62,2.35,-.06),.71,.55,normal=(s*.4,.7,-.3),slot=7,bone=arm,depth=.1)
        m.tube([(s*.65,2.2,0),(s*.89,1.85,-.02),(s*.82,1.54,-.33)],[.19,.14,.11],slot=4,bone=arm,sides=8)
        for j in range(3):
            mirror=m.bone(f'Mirror{s}.{j}',(s*(.62+j*.16),2.15-j*.40,.32),b)
            m.plate((s*(.62+j*.16),2.0-j*.40,.31),.55,.70,normal=(s*.28,0,-1),slot=7,bone=mirror,depth=.045,
                    outline=[(-.5,-.5),(.5,-.5),(.5,.5),(-.5,.5)])
            m.plate((s*(.62+j*.16),2.0-j*.40,.25),.41,.51,normal=(s*.28,0,-1),slot=10,bone=mirror,depth=.02)
        # Mantle splits retain a hole under the floating body instead of sliding feet.
        m.plate((s*.41,.82,-.17),.60,1.18,normal=(s*.2,0,-1),slot=7,bone=b,depth=.06)
    seal=m.bone('Seal',(.83,1.62,-.4),b)
    m.ring((.89,1.68,-.48),.34,.07,slot=7,bone=seal,axis='z',segments=8)
    gem(m,(.89,1.68,-.49),.20,11,seal)
    for j in range(3):m.box((-.82,1.75-j*.14,-.4),(.33,.045,.16),slot=7,bone=m.bones.index(next(x for x in m.bones if x[0]=='ArmL')))
    return m

def singularity():
    m=art.Mesh('singularity');r=m.bone('Root',(0,0,0));b=m.bone('Core',(0,1.93,0),r)
    # An empty tetrahedral cage around a star, not another humanoid boss.
    gem(m,(0,1.93,0),.48,15,b)
    m.ring((0,1.93,0),.64,.045,slot=11,bone=b,axis='z',segments=28)
    points=np.array([(0,3.73,0),(-1.42,.94,-.72),(1.42,.94,-.72),(0,.94,1.50)])
    for j,p in enumerate(points):
        shell=m.bone(f'Frame{j}',p,b)
        gem(m,p,.25,14,shell)
        for k in range(j):
            q=points[k];mid=(p+q)*.5
            m.tube([p,mid,q],[.105,.08,.105],slot=0,bone=shell,sides=8)
            m.tube([p*.78+np.array([0,.42,0]),mid*.78+np.array([0,.42,0])],[.025,.025],slot=11,bone=shell,sides=6)
    for j in range(3):
        gyro=m.bone(f'Gyro{j}',(0,1.93,0),b)
        m.ring((0,1.93,0),.89+j*.18,.055,slot=7 if j==1 else 14,bone=gyro,axis='z' if j==1 else 'y',segments=28,start=.18,end=math.tau-.18)
        gem(m,(.89+j*.18,1.93,0),.12,11,gyro)
    return m

def attack_pose(m,kind,q):
    # Last 18% releases the stored pose into contact. Same endpoint is strike[0].
    release=max(0,(q-.82)/.18);load=min(1,q/.82)
    lift=load*(1-release);impact=release
    pose={};name=m.name
    pose['Core']=([(.06 if kind=='beam' else -.09)*lift+.07*impact,0,0],[0,.10*lift-.08*impact,0])
    for label,s in [('ArmL',-1),('ArmR',1),('ArmC',0)]:
        angle=(-.62*lift+.32*impact) if kind=='slam' else (-.17*lift)
        pose[label]=([angle,0,s*(.28*lift if kind in ['fan','ring'] else .04)],[0,0,-.11*impact])
    pose['Crown']=([-.13*lift,0,0],[0,.05*lift,0])
    for label,_,_ in m.bones:
        if label.startswith('Shell'):pose[label]=([0,0,(-1 if label.endswith('L') else 1)*.16*lift],[0,0,0])
        if label.startswith('Ribbon'):pose[label]=([-.23*lift,0,0],[0,0,0])
        if label.startswith('Layer'):pose[label]=([0,(int(label[-1])%2*2-1)*.16*lift,0],[0,.025*int(label[-1])*lift,0])
        if label.startswith('Mirror'):pose[label]=([0,0,(-1 if '-' in label else 1)*.30*lift],[0,0,-.06*impact])
        if label.startswith('Gyro'):pose[label]=([.25*lift if label=='Gyro1' else 0,(int(label[-1])+1)*.24*lift,0],[0,0,0])
        if label.startswith('Frame'):pose[label]=([0,0,0],[0,.07*lift,0])
    return pose

def animate(m):
    durations={'idle':1.8,'walk':.9,'open':1.0,'defeat':.8}
    for kind in PATTERNS[m.name]:durations['tell_'+kind]=1.0;durations['strike_'+kind]=.4
    for clip,duration in durations.items():
        times=np.linspace(0,duration,max(4,int(duration*30)+1));poses=[]
        for t in times:
            q=float(t/duration);pose={};wave=math.sin(q*math.tau)
            if clip.startswith('tell_'):pose=attack_pose(m,clip[5:],q)
            elif clip.startswith('strike_'):
                pose={k:([float(a)*(1-q) for a in v[0]],[float(a)*(1-q) for a in v[1]]) for k,v in attack_pose(m,clip[7:],1.).items()}
            elif clip=='defeat':
                pose['Core']=([.20*q,0,0],[0,-(.38 if m.name=='buffer_overflow' else .80)*q,0])
                for name,_,_ in m.bones:
                    if name.startswith(('Mirror','Layer','Frame')):pose[name]=([0,.45*q,.16*q],[0,-.12*q,0])
            else:
                if m.name!='buffer_overflow':pose['Core']=([0,0,0],[0,.035*wave,0])
                for name,_,_ in m.bones:
                    if name.startswith('Wheel') and clip=='walk':pose[name]=([q*math.tau,0,0],[0,0,0])
                    if name.startswith('Ribbon'):pose[name]=([.035*wave,0,.025*math.sin(q*math.tau+int(name[-1]))],[0,0,0])
                    if name.startswith('Layer'):pose[name]=([0,.045*wave*(-1)**int(name[-1]),0],[0,0,0])
                    if name.startswith('Gyro'):pose[name]=([0,.07*wave,0],[0,0,0])
                    if clip=='open' and name.startswith(('Arm','Shell','Mirror')):
                        s=-1 if name.endswith('L') or '-' in name else 1
                        pose[name]=([.08,0,s*.20],[s*.08,0,0])
            poses.append(pose)
        m.animations[clip]=(times,poses)
    return m

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True);art.OUT=OUT;paint()
    entries=[animate(builder()).export() for builder in [buffer,memory,stack,admin,singularity]]
    files={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.suffix in ['.glb','.png']}
    (OUT/'manifest.json').write_text(json.dumps({'source':'tools/build_bosses.py','assets':entries,'files':files},indent=2)+'\n')
    print(json.dumps(entries,indent=2))
