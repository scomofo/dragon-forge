#!/usr/bin/env python3
"""Dragon Forge art source. Offline parametric mesh/UV/skin/clip authoring.

python tools/build_art.py  (Python 3.11+, numpy, Pillow; never required to play)
Output: portable glTF 2.0 assets, shared PBR atlas and an auditable manifest.
Coordinates: metres, +Y up, actors face -Z. No collision or gameplay code here.
Original geometry/texture recipes; no downloaded models, images or fonts.
"""
from __future__ import annotations
import hashlib, json, math, struct
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art' / 'generated'
OUT.mkdir(parents=True, exist_ok=True)
TAU = math.tau
# Shared 4x4 trim atlas, with generous gutters. Slot numbers are source-editable.
BASALT,SCALE,BONE,EMBER,METAL,COPPER,TEAL,SILVER,CYAN,SOOT,FLOOR,HAZARD,RUBBER,GLASS = range(14)
PALETTE = [(66,52,48),(128,58,32),(215,180,119),(255,114,27),
           (45,59,65),(157,89,48),(43,94,98),(131,151,154),
           (74,224,231),(22,26,30),(66,74,72),(205,149,64),
           (29,30,27),(13,37,42),(90,74,71),(49,56,61)]


def atlas() -> None:
    from paint_surfaces import paint
    paint(OUT)


def unit(a):
    a=np.asarray(a,float); length=np.linalg.norm(a); return a/max(length,1e-12)


def quat(e):
    x,y,z=np.asarray(e)*.5; sx,cx=math.sin(x),math.cos(x);sy,cy=math.sin(y),math.cos(y);sz,cz=math.sin(z),math.cos(z)
    return [sx*cy*cz-cx*sy*sz,cx*sy*cz+sx*cy*sz,cx*cy*sz-sx*sy*cz,cx*cy*cz+sx*sy*sz]


class Mesh:
    def __init__(self,name):
        self.name=name; self.vertices=[]; self.faces=[]; self.uv=[]; self.colors=[];self.joints=[];self.weights=[]
        self.bones=[];self.animations={}
    def bone(self,name,at,parent=None):
        self.bones.append((name,np.array(at,float),parent)); return len(self.bones)-1
    def part(self,vertices,faces,uv,slot,bone=0,weights=None,tint=1.0):
        v=np.array(vertices,float); f=np.array(faces,int)
        # Closed-piece orientation is checked instead of relying on a DCC viewport.
        volume=np.einsum('ij,ij->i',v[f[:,0]],np.cross(v[f[:,1]],v[f[:,2]])).sum()
        if volume<0: f=f[:,::-1]
        start=len(self.vertices); self.vertices.extend(v.tolist()); self.faces.extend((f+start).tolist())
        col,row=slot%4,slot//4
        # PNG/glTF origins both top-left; Godot handles this on import.
        self.uv.extend([[(col+.055+.89*a)/4,(row+.055+.89*b)/4] for a,b in uv])
        self.colors.extend([[tint,tint,tint,1.0] for _ in v])
        for n in range(len(v)):
            ws=weights[n] if weights is not None else [(bone,1.)]
            ws=sorted([(j,w) for j,w in ws if w > 1e-8],key=lambda p:-p[1])[:4]; total=sum(w for _,w in ws)
            self.joints.append([j for j,_ in ws]+[0]*(4-len(ws)))
            self.weights.append([w/total for _,w in ws]+[0.]*(4-len(ws)))
    def tube(self,path,widths,depths=None,slot=BASALT,bone=0,sides=16,weights=None,tint=1.):
        p=np.array(path,float); widths=np.broadcast_to(widths,(len(p),)); depths=widths if depths is None else np.broadcast_to(depths,(len(p),))
        if len(p) > 2 and sides >= 9:
            # Catmull-Rom sweep profiles replace angular runtime cylinders.
            pp=[];ww=[];dd=[];blend=[]
            def cat(a,b,c,d,t): return .5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
            for i in range(len(p)-1):
                for k in range(4):
                    t=k/4; a=max(i-1,0); d=min(i+2,len(p)-1)
                    pp.append(cat(p[a],p[i],p[i+1],p[d],t))
                    ww.append(max(.002,float(cat(widths[a],widths[i],widths[i+1],widths[d],t))))
                    dd.append(max(.002,float(cat(depths[a],depths[i],depths[i+1],depths[d],t))))
                    w={}
                    for j,value in (weights[i] if weights is not None else [(bone,1.)]):w[j]=w.get(j,0)+value*(1-t)
                    for j,value in (weights[i+1] if weights is not None else [(bone,1.)]):w[j]=w.get(j,0)+value*t
                    blend.append(list(w.items()))
            pp.append(p[-1]);ww.append(widths[-1]);dd.append(depths[-1]);blend.append(weights[-1] if weights is not None else [(bone,1.)])
            p=np.array(pp);widths=np.array(ww);depths=np.array(dd);weights=blend
        vs=[];uv=[];ws=[];fs=[];previous=None
        for i,at in enumerate(p):
            tangent=unit(p[min(i+1,len(p)-1)]-p[max(i-1,0)])
            ref=np.array([1.,0,0]) if abs(tangent[0])<.85 else np.array([0.,0,1.])
            if previous is not None and np.linalg.norm(previous-tangent*np.dot(previous,tangent)) > .01: ref=previous
            right=unit(ref-tangent*np.dot(ref,tangent)); other=unit(np.cross(tangent,right)); previous=right
            for j in range(sides+1):
                a=j/sides*TAU;vs.append(at+right*math.cos(a)*widths[i]+other*math.sin(a)*depths[i]); uv.append([j/sides,i/(len(p)-1)])
                ws.append(weights[i] if weights is not None else [(bone,1.)])
        for i in range(len(p)-1):
            for j in range(sides):
                a=i*(sides+1)+j;b=a+sides+1;fs.extend([[a,a+1,b],[a+1,b+1,b]])
        for k in [0,len(p)-1]:
            # Duplicate cap vertices for planar UVs and crisp material normals.
            start=len(vs)
            for j in range(sides):
                vs.append(vs[k*(sides+1)+j]);a=j/sides*TAU
                uv.append([.5+.48*math.cos(a),.5+.48*math.sin(a)])
                ws.append(weights[k] if weights is not None else [(bone,1.)])
            cap=len(vs);vs.append(p[k]);uv.append([.5,.5]);ws.append(weights[k] if weights is not None else [(bone,1.)])
            for j in range(sides):
                a=start+j;b=start+(j+1)%sides;fs.append([cap,b,a] if k==0 else [cap,a,b])
        self.part(vs,fs,uv,slot,bone,ws,tint)
    def plate(self,at,width,length,normal=(0,0,1),up=(0,1,0),slot=SCALE,bone=0,depth=.08,outline=None,tint=1.):
        normal=unit(normal);up=unit(np.array(up)-normal*np.dot(normal,up)); right=unit(np.cross(up,normal));at=np.array(at)
        poly=outline or [(-.46,-.28),(0,-.61),(.46,-.28),(.50,.20),(.28,.47),(-.28,.47),(-.50,.20)]
        vs=[];uv=[];fs=[];num=len(poly)
        for scale,h in [(1.,0),(.86,depth*.68)]:
            for x,y in poly: vs.append(at+right*x*width*scale+up*y*length*scale+normal*h);uv.append([x*scale+.5,.5+y*.8*scale])
        vs.extend([at+normal*depth,at-normal*.015]);uv.extend([[.5,.5],[.5,.5]])
        for j in range(num):
            k=(j+1)%num; fs.extend([[j,k,j+num],[k,k+num,j+num],[j+num,k+num,2*num],[j,2*num+1,k]])
        self.part(vs,fs,uv,slot,bone,tint=tint)
    def box(self,at,size,slot=METAL,bone=0,bevel=.04,tint=1.):
        x,y,z=np.array(size)*.5;b=min(bevel,x*.35,y*.35,z*.35)
        # Chamfered rectangular solid, eight-sided sections and bevelled caps.
        poly=[(-x+b,-z), (x-b,-z),(x,-z+b),(x,z-b),(x-b,z),(-x+b,z),(-x,z-b),(-x,-z+b)]
        vs=[];uv=[];fs=[]
        for yy,s in [(-y,.93),(-y+b,1.),(y-b,1.),(y,.93)]:
            for j in range(9):
                xx,zz=poly[j%8];vs.append(np.array(at)+[xx*s,yy,zz*s]);uv.append([j/8,(yy+y)/(2*y)])
        for row in range(3):
            for j in range(8):
                a=row*9+j;c=a+1;fs.extend([[a,c,a+9],[c,c+9,a+9]])
        for row in [0,3]:
            start=len(vs)
            for j in range(8):
                point=vs[row*9+j];vs.append(point)
                uv.append([.5+(point[0]-at[0])/(2*x),.5+(point[2]-at[2])/(2*z)])
            center=len(vs);vs.append(np.array(at)+[0,-y if row==0 else y,0]);uv.append([.5,.5])
            for j in range(8):
                a=start+j;c=start+(j+1)%8;fs.append([center,a,c] if row==0 else [center,c,a])
        self.part(vs,fs,uv,slot,bone,tint=tint)
    def ring(self,at,radius,thick,slot=METAL,bone=0,segments=32,axis='y',start=0.,end=TAU):
        p=[]
        for i in range(segments+1):
            a=start+(end-start)*i/segments
            off=[math.cos(a)*radius,0,math.sin(a)*radius] if axis=='y' else [math.cos(a)*radius,math.sin(a)*radius,0]
            p.append(np.array(at)+off)
        self.tube(p,thick,slot=slot,bone=bone,sides=6)
    def bolt(self,at,slot=SILVER,r=.045):self.tube([np.array(at)+[0,-.02,0],np.array(at)+[0,.02,0]],r,slot=slot,sides=6)
    def export(self):
        v=np.array(self.vertices,dtype='<f4'); f=np.array(self.faces,dtype='<u4')
        n=np.zeros_like(v);norm=np.cross(v[f[:,1]]-v[f[:,0]],v[f[:,2]]-v[f[:,0]])
        for k in range(3):np.add.at(n,f[:,k],norm)
        n/=np.maximum(np.linalg.norm(n,axis=1)[:,None],1e-8)
        # Explicit tangent frames make normal mapping portable across importers.
        tex=np.asarray(self.uv,float);e1=v[f[:,1]]-v[f[:,0]];e2=v[f[:,2]]-v[f[:,0]]
        d1=tex[f[:,1]]-tex[f[:,0]];d2=tex[f[:,2]]-tex[f[:,0]]
        det=d1[:,0]*d2[:,1]-d1[:,1]*d2[:,0]
        if np.any(abs(det)<1e-12): raise ValueError('Degenerate texture coordinates')
        ta=(e1*d2[:,1,None]-e2*d1[:,1,None])/det[:,None]
        ba=(e2*d1[:,0,None]-e1*d2[:,0,None])/det[:,None]
        tangent=np.zeros_like(v);bitangent=np.zeros_like(v)
        for k in range(3):
            np.add.at(tangent,f[:,k],ta);np.add.at(bitangent,f[:,k],ba)
        tangent-=n*np.sum(n*tangent,axis=1)[:,None]
        lengths=np.linalg.norm(tangent,axis=1)
        for i in np.flatnonzero(lengths<1e-8):
            axis=[1.,0,0] if abs(n[i,0])<.85 else [0.,1,0]
            tangent[i]=unit(np.cross(n[i],axis))
        tangent/=np.maximum(np.linalg.norm(tangent,axis=1)[:,None],1e-8)
        handed=np.where(np.sum(np.cross(n,tangent)*bitangent,axis=1)<0,-1.,1.)
        tangents=np.column_stack([tangent,handed])
        doc={'asset':{'version':'2.0','generator':'Dragon Forge offline art compiler v1'},'scene':0,'scenes':[{'nodes':[0]}],
             'nodes':[{'name':self.name,'children':[]}],'meshes':[], 'accessors':[],'bufferViews':[],
             'images':[{'uri':s+'.png'} for s in ['atlas_base','atlas_orm','atlas_normal','atlas_emission']],
             'samplers':[{'magFilter':9729,'minFilter':9987,'wrapS':33071,'wrapT':33071}],
             'textures':[{'source':i,'sampler':0} for i in range(4)],
             'materials':[{'name':'ForgePBR','pbrMetallicRoughness':{'baseColorTexture':{'index':0},'metallicRoughnessTexture':{'index':1},'metallicFactor':1.,'roughnessFactor':1.},
                           'normalTexture':{'index':2,'scale':.6},'occlusionTexture':{'index':1,'strength':.6},'emissiveTexture':{'index':3},'emissiveFactor':[1.,1.,1.]}]}
        binary=bytearray()
        def access(data,kind,component=5126,bounds=False):
            nonlocal binary
            arr=np.asarray(data,dtype={5126:'<f4',5125:'<u4',5123:'<u2'}[component])
            while len(binary)%4:binary+=b'\0'
            view=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':len(binary),'byteLength':arr.nbytes});binary.extend(arr.tobytes())
            entry={'bufferView':view,'componentType':component,'count':len(arr),'type':kind}
            if bounds:
                columns=arr.reshape(len(arr),-1)
                entry.update(min=columns.min(axis=0).tolist(),max=columns.max(axis=0).tolist())
            doc['accessors'].append(entry);return len(doc['accessors'])-1
        attrs={'POSITION':access(v,'VEC3',bounds=True),'NORMAL':access(n,'VEC3'),'TANGENT':access(tangents,'VEC4'),'TEXCOORD_0':access(self.uv,'VEC2'),'COLOR_0':access(self.colors,'VEC4')}
        meshnode={'name':self.name+'_Mesh','mesh':0}
        if self.bones:
            attrs['JOINTS_0']=access(self.joints,'VEC4',5123);attrs['WEIGHTS_0']=access(self.weights,'VEC4')
            for i,(name,pos,parent) in enumerate(self.bones):
                local=pos if parent is None else pos-self.bones[parent][1]
                doc['nodes'].append({'name':name,'translation':local.tolist(),'children':[]})
                doc['nodes'][0 if parent is None else parent+1]['children'].append(i+1)
            inv=[]
            for _,p,_ in self.bones:
                m=np.eye(4);m[:3,3]=-p;inv.append(m.T.flatten())
            doc['skins']=[{'name':self.name+'_Skin','joints':list(range(1,len(self.bones)+1)),'skeleton':1,'inverseBindMatrices':access(inv,'MAT4')}];meshnode['skin']=0
            doc['animations']=[]
            for clip,(times,poses) in self.animations.items():
                animation={'name':clip,'samplers':[],'channels':[]}; inp=access(np.array(times),'SCALAR',bounds=True)
                for bi,(name,pos,parent) in enumerate(self.bones):
                    local=pos if parent is None else pos-self.bones[parent][1]
                    for channel in ['rotation','translation']:
                        vals=[]
                        for pose in poses:
                            rot,off=pose.get(name,([0,0,0],[0,0,0]));vals.append((quat(rot) if len(rot)==3 else rot) if channel=='rotation' else (local+off).tolist())
                        a=access(vals,'VEC4' if channel=='rotation' else 'VEC3');si=len(animation['samplers']);animation['samplers'].append({'input':inp,'output':a,'interpolation':'LINEAR'})
                        animation['channels'].append({'sampler':si,'target':{'node':bi+1,'path':channel}})
                doc['animations'].append(animation)
        if self.bones:
            doc['scenes'][0]['nodes'].append(len(doc['nodes']))
        else:
            doc['nodes'][0]['children'].append(len(doc['nodes']))
        doc['nodes'].append(meshnode)
        for attribute in attrs.values():
            doc['bufferViews'][doc['accessors'][attribute]['bufferView']]['target']=34962
        index_accessor=access(f.flatten(),'SCALAR',5125)
        doc['bufferViews'][doc['accessors'][index_accessor]['bufferView']]['target']=34963
        doc['meshes'].append({'name':self.name,'primitives':[{'attributes':attrs,'indices':index_accessor,'material':0}]})
        doc['buffers']=[{'byteLength':len(binary)}]
        for node in doc['nodes']:
            if node.get('children') == []: del node['children']
        meta=json.dumps(doc,separators=(',',':')).encode();meta+=b' '*((-len(meta))%4);binary+=b'\0'*((-len(binary))%4)
        blob=struct.pack('<III',0x46546c67,2,28+len(meta)+len(binary))+struct.pack('<II',len(meta),0x4e4f534a)+meta+struct.pack('<II',len(binary),0x004e4942)+binary
        (OUT/(self.name+'.glb')).write_bytes(blob)
        return {'file':self.name+'.glb','triangles':len(f),'vertices':len(v),'surfaces':1,'bones':len(self.bones),'clips':list(self.animations),'bounds':[v.min(0).tolist(),v.max(0).tolist()]}


def magma():
    m=Mesh('magma_guardian');root=m.bone('Root',(0,0,0));hips=m.bone('Pelvis',(0,.94,.12),root);chest=m.bone('Chest',(0,1.65,-.02),hips)
    neck=m.bone('Neck',(0,2.06,-.3),chest);head=m.bone('Head',(0,2.28,-.62),neck);jaw=m.bone('Jaw',(0,2.115,-.59),head)
    # Broad diamond chest, tapered pelvis, leaning reptilian neck. Skin joins are weighted.
    path=[(0,.77,.14),(0,.92,.16),(0,1.14,.16),(0,1.40,.10),(0,1.69,-.02),(0,1.90,-.14),(0,2.12,-.32),(0,2.25,-.47)]
    ws=[[(hips,1)],[(hips,1)],[(hips,.85),(chest,.15)],[(hips,.35),(chest,.65)],[(chest,1)],[(chest,.75),(neck,.25)],[(neck,1)],[(neck,.4),(head,.6)]]
    m.tube(path,[.32,.45,.55,.68,.72,.63,.37,.32],[.29,.36,.44,.49,.46,.36,.29,.27],BASALT,weights=ws,sides=24)
    # Scapular shield-scales make the signature broad diamond readable from gameplay view.
    for side in [-1,1]:
        for row in range(3):
            m.plate((side*(.30-row*.026),1.91-row*.29,.28+row*.06),.76-row*.08,.61,normal=(side*.20,.17,1),slot=SCALE,bone=chest,depth=.11,tint=1-row*.06)
        m.plate((side*.56,1.94,.05),.54,.72,normal=(side*.70,.58,.28),up=(0,0,-1),slot=SCALE,bone=chest,depth=.12)
    # Central dorsal blade row / small molten seams rather than a full-body orange glow.
    for y,z in [(1.97,.24),(1.62,.47),(1.3,.54)]:
        m.tube([(0,y,z),(0,y+.21,z+.16),(0,y+.30,z+.30)],[.15,.10,.008],[.13,.075,.004],SCALE,chest,sides=7)
        m.plate((0,y-.06,z+.04),.10,.25,normal=(0,.25,1),slot=EMBER,bone=chest,depth=.022)
    for i in range(4):m.plate((0,1.09+i*.20,-.29-i*.049),.66+i*.02,.31,normal=(0,-.1,-1),slot=BONE,bone=hips if i==0 else chest,depth=.03,tint=.73)
    # Chest crucible nestled inside a shield-shaped breastplate.
    m.plate((0,1.76,-.445),.63,.59,normal=(0,.18,-1),slot=SOOT,bone=chest,depth=.075)
    m.plate((0,1.76,-.51),.28,.39,normal=(0,.18,-1),slot=EMBER,bone=chest,depth=.04)
    m.tube([(0,2.29,-.35),(0,2.34,-.58),(0,2.32,-.82),(0,2.25,-1.12),(0,2.21,-1.37)], [.24,.42,.37,.27,.195],[.27,.29,.27,.17,.125],SCALE,head,sides=20)
    m.tube([(0,2.02,-.59),(0,2.0,-.91),(0,2.04,-1.23),(0,2.085,-1.35)],[.28,.27,.21,.15],[.09,.075,.06,.025],BASALT,jaw,sides=16)
    # Separate rigid palate and lower cavity: opening the hinge cannot stretch upper mouth vertices.
    m.tube([(0,2.145,-.66),(0,2.14,-1.27)],[.23,.17],[.021,.02],SOOT,head,sides=12)
    # Mouth cavity is dark; enamel teeth and a few ember fissures are visible during breath.
    m.tube([(0,2.07,-.68),(0,2.08,-1.28)],[.245,.18],[.025,.023],SOOT,jaw,sides=12)
    for side in [-1,1]:
        for i in range(4):
            z=-.77-i*.145;x=side*(.265-i*.019)
            m.tube([(x,2.13,z),(x,2.05,z-.024),(x*.91,2.015,z-.035)],[.038,.023,.002],slot=BONE,bone=head,sides=7)
        # Tapered eye sockets, recessed amber slit, bony overhanging brow.
        norm=(side*.9,.10,-.44)
        m.plate((side*.35,2.40,-.76),.23,.34,norm,(0,1,0),SOOT,head,depth=.025)
        m.plate((side*.414,2.415,-.800),.105,.240,norm,(0,0,-1),EMBER,head,depth=.02)
        m.plate((side*.35,2.49,-.72),.24,.49,(side*.7,.68,-.20),(0,0,-1),BASALT,head,depth=.06)
        m.plate((side*.24,2.39,-.54),.31,.52,(side*.4,.6,.8),(0,1,0),SCALE,head,depth=.065)
        horn=[(side*.29,2.51,-.51),(side*.40,2.65,-.39),(side*.53,2.80,-.19),(side*.61,2.91,.04),(side*.57,2.97,.19)]
        m.tube(horn,[.16,.145,.11,.055,.003],slot=BONE,bone=head,sides=12)
        m.tube([(side*.37,2.18,-.45),(side*.57,2.19,-.20),(side*.68,2.30,.03)],[.125,.08,.003],slot=BASALT,bone=head,sides=9)
        m.plate((side*.148,2.265,-1.36),.065,.14,(side*.3,.35,-1),slot=SOOT,bone=head,depth=.012)
        arm=m.bone('Arm.L' if side<0 else 'Arm.R',(side*.66,1.80,-.10),chest)
        fore=m.bone('Forearm.L' if side<0 else 'Forearm.R',(side*.95,1.29,-.17),arm)
        hand=m.bone('Hand.L' if side<0 else 'Hand.R',(side*.88,1.12,-.58),fore)
        m.tube([(side*.56,1.84,-.06),(side*.84,1.63,-.09),(side*.95,1.29,-.17),(side*.93,1.20,-.35),(side*.88,1.12,-.62)], [.27,.285,.205,.205,.22],slot=BASALT,bone=arm,weights=[[(chest,.65),(arm,.35)],[(chest,.12),(arm,.88)],[(arm,.40),(fore,.60)],[(fore,.88),(hand,.12)],[(hand,1)]])
        m.plate((side*.79,1.75,-.035),.68,.60,(side*.76,.55,.2),(0,0,-1),SCALE,arm,depth=.10)
        m.plate((side*1.02,1.32,-.23),.40,.53,(side*.80,.25,.15),(0,1,0),SCALE,fore,depth=.09)
        for d in range(3):
            x=side*.88+(d-1)*.145
            m.tube([(x,1.13,-.58),(x,1.05,-.76),(x,1.02,-.86)],[.075,.060,.045],slot=SCALE,bone=hand,sides=10)
            m.tube([(x,1.04,-.84),(x,1.00,-.98),(x,1.035,-1.08)],[.053,.030,.002],slot=BONE,bone=hand,sides=9)
        thigh=m.bone('Thigh.L' if side<0 else 'Thigh.R',(side*.44,.99,.14),hips)
        hock=m.bone('Hock.L' if side<0 else 'Hock.R',(side*.62,.57,-.10),thigh)
        foot=m.bone('Foot.L' if side<0 else 'Foot.R',(side*.53,.29,.29),hock)
        m.tube([(side*.36,1.01,.16),(side*.57,.85,.12),(side*.62,.59,-.11),(side*.59,.43,.19),(side*.53,.26,.29),(side*.52,.15,-.28)], [.34,.36,.265,.175,.16,.245],[.31,.33,.25,.17,.16,.13],SCALE,weights=[[(hips,.65),(thigh,.35)],[(hips,.12),(thigh,.88)],[(thigh,.35),(hock,.65)],[(hock,1)],[(hock,.3),(foot,.7)],[(foot,1)]],sides=18)
        m.plate((side*.74,.88,.04),.51,.63,(side*.90,.25,.18),(0,1,0),BASALT,thigh,depth=.09)
        for d in range(3):
            x=side*.52+(d-1)*.19
            m.tube([(x,.16,-.18),(x,.145,-.43),(x,.12,-.57)],[.105,.105,.066],[.10,.075,.055],SCALE,foot,sides=12)
            m.tube([(x,.13,-.54),(x,.105,-.70),(x,.09,-.83)],[.072,.042,.002],slot=BONE,bone=foot,sides=10)
    centers=[(0,.99,.44),(0,.86,.86),(.06,.69,1.22),(.13,.56,1.60),(.15,.54,1.98),(.05,.59,2.33),(-.10,.71,2.65)]
    tailbones=[];par=hips
    for i,p in enumerate(centers[:-1]):par=m.bone('Tail%02d'%i,p,par);tailbones.append(par)
    weights=[[(tailbones[min(i,5)],1)] for i in range(7)]
    m.tube(centers,[.31,.27,.21,.17,.13,.085,.005],slot=BASALT,sides=18,weights=weights)
    for i,p in enumerate(centers[1:-1]):
        p=np.array(p);bone=tailbones[min(i+1,5)];r=.26-i*.032
        m.plate(p+[0,r*.50,0],r*1.9,.47,(0,1,.2),(0,0,-1),SCALE,bone,depth=.05)
        m.tube([p+[0,r*.65,.04],p+[0,r+.14,.12],p+[0,r+.22,.27]],[r*.38,r*.24,.003],slot=SCALE,bone=bone,sides=7)
    clips={'idle':1.8,'walk':.8,'claw':.28,'breath':.5,'wall':.44,'burst':.72,'guard':1.,'hurt':.24,'defeat':.8}
    for name,length in clips.items():
        times=np.linspace(0,length,17).tolist()
        wind={'claw':.1,'breath':.22,'wall':.2,'burst':.32}.get(name)
        if wind is not None:times=sorted(set(times+[wind,max(0,wind-.025),min(length,wind+.03)]))
        poses=[]
        for t in times:
            q=t/length;pose={}
            def setp(b,r=(0,0,0),p=(0,0,0)):pose[b]=(list(r),list(p))
            if name=='idle':
                a=math.sin(q*TAU);setp('Chest',(.014*a,0,0),(0,.017*a,0));setp('Head',(-.014*a,0,0))
                for i in range(6):setp('Tail%02d'%i,(0,math.sin(q*TAU-i*.46)*.038,0))
            elif name=='walk':
                a=math.sin(q*TAU);setp('Pelvis',(0,a*.045,0),(0,abs(a)*.035,0));setp('Chest',(-.055,-a*.06,0))
                for side,sign in [('L',1),('R',-1)]:
                    setp('Thigh.'+side,(a*.32*sign,0,0));setp('Hock.'+side,(-max(0,a*sign)*.34,0,0));setp('Foot.'+side,(-a*.18*sign,0,0));setp('Arm.'+side,(-a*.2*sign,0,0))
                for i in range(6):setp('Tail%02d'%i,(0,math.sin(q*TAU-i*.6)*.045,0))
            elif wind is not None:
                a=min(1,t/wind);a=a*a*(3-2*a)
                if t>=wind:
                    rec=(t-wind)/(length-wind);a=1-rec*rec*(3-2*rec)
                # Contact pose is continuous; no hidden hit callbacks in the asset.
                strike=max(0,min(1,(t-wind+.025)/.055)); swing=(1-strike)*-1+strike
                if name=='claw':
                    setp('Chest',(0,swing*.38*a,0));setp('Arm.R',(-.72*a,-.22*a,swing*.48*a));setp('Forearm.R',(-.40*a,.2*a,0));setp('Hand.R',(0,.25*a,0))
                elif name=='breath':
                    setp('Chest',(-.13*a,0,0));setp('Neck',(.18*a,0,0));setp('Head',(-.08*a,0,0));setp('Jaw',(-.50*a,0,0));setp('Arm.L',(0,0,.18*a));setp('Arm.R',(0,0,-.18*a))
                elif name=='wall':
                    setp('Pelvis',(.035*a,0,0),(0,-.09*a,0));setp('Chest',(.21*a,0,0));setp('Arm.L',(-.94*a,0,.2*a));setp('Arm.R',(-.94*a,0,-.2*a));setp('Head',(-.18*a,0,0))
                else:
                    setp('Chest',(-.18*a,0,0));setp('Arm.L',(-.28*a,0,.68*a));setp('Arm.R',(-.28*a,0,-.68*a));setp('Head',(.14*a,0,0));setp('Jaw',(-.38*a,0,0))
            elif name=='guard':
                setp('Chest',(.09,0,0));setp('Arm.L',(-.85,0,.35));setp('Arm.R',(-.85,0,-.35));setp('Forearm.L',(-.35,-.1,0));setp('Forearm.R',(-.35,.1,0));setp('Head',(-.1,0,0))
            elif name=='hurt':
                a=math.sin(q*math.pi)*(1-q);setp('Chest',(-.24*a,0,0));setp('Head',(-.15*a,0,0))
            elif name=='defeat':
                a=q*q*(3-2*q);setp('Root',(0,0,-1.3*a),(0,-.17*a,0));setp('Head',(.25*a,0,0));setp('Jaw',(-.2*a,0,0))
            poses.append(pose)
        m.animations[name]=(times,poses)
    # Sole pads/claws are rigid to the Foot bone; ankle flexion stays above the sole.
    # This prevents the last 10–20% hock blend from shearing contact vertices under IK.
    for vi, vertex in enumerate(m.vertices):
        if vertex[1] <= .21:
            for ji, weight in zip(m.joints[vi], m.weights[vi]):
                if weight >= .65 and m.bones[ji][0].startswith('Foot.'):
                    m.joints[vi] = [ji,0,0,0]
                    m.weights[vi] = [1.,0.,0.,0.]
                    break
    from pose_cleanup import correct
    correct(m, quat)
    return m


def sentinel(boss=False):
    m=Mesh('packet_warden' if boss else 'firewall_sentinel');r=m.bone('Root',(0,0,0));p=m.bone('Pelvis',(0,.9,0),r);c=m.bone('Chest',(0,1.5,0),p);h=m.bone('Head',(0,2.13,0),c)
    main=METAL if not boss else BASALT;accent=CYAN if not boss else EMBER
    m.box((0,1.5,.02),(1.08,1.22,.66),main,c,bevel=.15)
    m.plate((0,1.62,-.38),1.12,1.3,(0,0,-1),slot=TEAL if not boss else COPPER,bone=c,depth=.12)
    m.ring((0,1.6,-.52),.25,.07,SOOT,c,segments=16,axis='z');m.plate((0,1.6,-.57),.25,.36,(0,0,-1),slot=accent,bone=c,depth=.03)
    for x in [-.32,0,.32]:m.box((x,1.54,.40),(.16,.79,.12),COPPER,c)
    m.box((0,2.12,0),(.63,.54,.56),main,h,.10);m.plate((0,2.14,-.31),.69,.51,(0,0,-1),slot=main,bone=h,depth=.045)
    m.box((0,2.13,-.375),(.43,.06,.024),accent,h,.01)
    for s in [-1,1]:
        m.plate((s*.37,2.27,.06),.40,.68,(s*.8,.2,-.3),(0,1,0),TEAL if not boss else COPPER,h,.075)
        arm=m.bone('Arm.L' if s<0 else 'Arm.R',(s*.72,1.91,0),c)
        m.box((s*.79,1.72,0),(.47,.53,.68),main,arm,.08)
        m.plate((s*.85,1.82,-.34),.68,.58,(0,0,-1),slot=TEAL if not boss else COPPER,bone=arm,depth=.1)
        m.tube([(s*.8,1.45,.02),(s*.84,.95,-.12)],.14,slot=COPPER,bone=arm,sides=10)
        m.box((s*.84,1.08,-.12),(.44,.55,.46),main,arm,.07)
        if s<0:
            # The sentinel's plated firewall arm has a much broader silhouette than its hammer.
            m.plate((s*.99,1.26,-.43),.80,1.35,(0,0,-1),slot=main,bone=arm,depth=.12)
            m.plate((s*.99,1.27,-.56),.60,1.1,(0,0,-1),slot=TEAL if not boss else COPPER,bone=arm,depth=.05)
            m.box((s*.99,1.26,-.63),(.06,.79,.02),accent,arm,.005)
        else:
            m.box((s*.84,.79,-.19),(.63,.38,.67),main,arm,.09)
            for z in [-.38,-.2,-.02]:m.box((s*.84,.75,z),(.67,.13,.048),SILVER,arm,.015)
        leg=m.bone('Leg.L' if s<0 else 'Leg.R',(s*.33,.89,.04),p)
        m.box((s*.33,.58,0),(.38,.66,.43),main,leg,.05);m.plate((s*.33,.63,-.25),.42,.51,(0,0,-1),slot=TEAL if not boss else COPPER,bone=leg,depth=.07)
        m.box((s*.33,.19,-.16),(.47,.34,.74),main,leg,.055)
        for z in [-.40,-.26]:m.box((s*.33,.24,z),(.37,.12,.055),SILVER,leg,.015)
    if boss:
        # Warden is a second export with crown/fan armour, not a material hue swap.
        for s in [-1,1]:
            for i in range(3):
                m.tube([(s*(.17+i*.15),2.27,.12),(s*(.24+i*.18),2.63+(2-i)*.10,.18),(s*(.3+i*.21),2.79+(2-i)*.10,.19)],[.08,.06,.004],slot=COPPER,bone=h,sides=6)
        m.box((0,1.72,.49),(.88,.97,.17),COPPER,c,.035)
    for name,length in [('idle',1.8),('walk',.9),('tell',1.),('open',1.),('hurt',.24)]:
        times=np.linspace(0,length,17).tolist();poses=[]
        for t in times:
            q=t/length;pose={}
            if name=='walk':
                a=math.sin(q*TAU);pose={'Leg.L':([a*.22,0,0],[0,0,0]),'Leg.R':([-a*.22,0,0],[0,0,0]),'Chest':([0,a*.025,0],[0,abs(a)*.025,0])}
            elif name=='tell':pose={'Arm.L':([-q*1.5,0,.14*q],[0,0,0]),'Arm.R':([-q*1.5,0,-.14*q],[0,0,0]),'Chest':([-.06*q,0,0],[0,0,0])}
            elif name=='open':pose={'Arm.L':([.25,0,.14],[0,0,0]),'Arm.R':([.25,0,-.14],[0,0,0]),'Head':([.12,0,0],[0,0,0])}
            elif name=='hurt':pose={'Chest':([-.2*math.sin(q*math.pi),0,0],[0,0,0])}
            poses.append(pose)
        m.animations[name]=(times,poses)
    return m


def kit():
    all=[]
    m=Mesh('deck_panel')
    m.box((0,-.04,0),(3.96,.14,3.96),METAL,bevel=.03)
    # Four shallow inset plates, low drainage gutters and corner bolts. Walkable top < 0.08m.
    for x in [-.98,.98]:
        for z in [-.98,.98]:
            m.box((x,.025,z),(1.86,.07,1.86),FLOOR,bevel=.025)
            for dx in [-.73,.73]:
                for dz in [-.73,.73]:m.bolt((x+dx,.068,z+dz),r=.037)
    for z in [-1.94,1.94]:
        m.box((0,.047,z),(2.84,.025,.035),COPPER,bevel=.005)
        for x in [-1.56,1.56]:m.box((x,.055,z),(.30,.025,.043),HAZARD,bevel=.006)
    all.append(m)
    m=Mesh('bulkhead')
    m.box((0,1.65,0),(1.44,3.3,1.60),METAL,bevel=.11)
    for y in [.16,3.14]:m.box((0,y,0),(1.51,.20,1.66),COPPER,bevel=.035)
    # Inward-facing sloped armour and dark vent cavities, visible from either side.
    for side in [-1,1]:
        for y in [.55,1.31,2.07,2.77]:
            m.plate((side*.73,y,0),1.44,.65,(side,0,0),(0,1,0),TEAL,depth=.065)
            m.box((side*.78,y+.12,0),(.05,.06,.81),CYAN,bevel=.009)
        for z in [-.70,.70]:m.box((side*.72,1.65,z),(.10,2.67,.11),SILVER,bevel=.015)
    all.append(m)
    m=Mesh('relay_conduit')
    m.tube([(0,0,0),(0,.12,0),(0,.22,0),(0,.35,0)],[.75,.79,.68,.62],slot=METAL,sides=12)
    m.tube([(0,.28,0),(0,1.44,0)],[.23,.17],slot=CYAN,sides=12)
    for s in [-1,1]:
        m.box((s*.48,.87,0),(.20,1.20,.40),TEAL,bevel=.045)
        m.box((s*.48,1.16,-.23),(.075,.54,.03),COPPER,bevel=.01)
        m.ring((0,.32+s*.0,0),.56,.046,COPPER,segments=24)
    m.ring((0,1.5,0),.57,.08,METAL,segments=24);m.ring((0,1.51,0),.45,.026,CYAN,segments=24)
    for a in range(0,360,60):
        q=math.radians(a);m.bolt((math.cos(q)*.6,.36,math.sin(q)*.6),r=.045)
    all.append(m)
    for name,em in [('incubator',EMBER),('core_socket',CYAN)]:
        m=Mesh(name);m.tube([(0,-.015,0),(0,.13,0),(0,.24,0)],[1.44,1.5,1.38],slot=METAL,sides=24)
        m.ring((0,.245,0),1.22,.04,em,segments=48);m.ring((0,.23,0),1.41,.045,COPPER,segments=32)
        m.tube([(0,.21,0),(0,.34,0)],[.67,.61],slot=SOOT,sides=12)
        for a in [-.15,TAU/3-.15,TAU*2/3-.15]:
            x,z=math.cos(a),math.sin(a)
            m.tube([(x*1.14,.20,z*1.14),(x*1.12,.54,z*1.12),(x*.91,.89,z*.91)], [.16,.14,.075],slot=COPPER,sides=8)
            m.plate((x*1.2,.31,z*1.2),.42,.49,(x,.4,z),(0,1,0),TEAL,depth=.05)
        for a in range(0,360,30):
            q=math.radians(a);m.bolt((math.cos(q)*1.33,.25,math.sin(q)*1.33),r=.038)
        if name=='core_socket':m.tube([(0,.32,0),(0,.6,0),(0,.68,0)],[.56,.52,.43],slot=TEAL,sides=8)
        all.append(m)
    m=Mesh('magma_egg')
    m.tube([(0,.23,0),(0,.35,0),(0,.7,0),(0,1.01,0),(0,1.26,0),(0,1.42,0)],[.1,.47,.56,.51,.33,.008],slot=BASALT,sides=20)
    for row,(y,r) in enumerate([(.46,.49),(.73,.55),(1.0,.49),(1.20,.34)]):
        for i in range(7):
            a=(i+(row%2)*.5)/7*TAU;x,z=math.cos(a),math.sin(a)
            m.plate((x*r,y,z*r),.42,.38,(x,.25,z),(0,1,0),SCALE,depth=.035)
    m.ring((0,.61,0),.56,.015,EMBER,segments=28);all.append(m)
    m=Mesh('furnace')
    m.box((0,1.4,0),(1.62,2.8,1.72),METAL,bevel=.16)
    m.plate((0,1.65,-.91),1.41,1.88,(0,0,-1),slot=COPPER,depth=.1)
    m.box((0,1.49,-1.04),(.84,1.25,.05),SOOT,bevel=.06)
    for x in [-.28,0,.28]:m.box((x,1.5,-1.075),(.13,.91,.035),EMBER,bevel=.015)
    for y in [.35,2.65]:m.box((0,y,-.05),(1.8,.24,1.83),COPPER,bevel=.045)
    for side in [-1,1]:
        m.tube([(side*.73,.30,.22),(side*.97,.48,.22),(side*.97,2.39,.22),(side*.72,2.66,.22)],.115,slot=COPPER,sides=10)
        for y in [.70,1.1,1.5,1.9]:m.box((side*.81,y,0),(.11,.065,.74),SOOT,bevel=.01)
    all.append(m)
    m=Mesh('anvil')
    m.box((0,.3,0),(1.3,.6,.90),METAL,bevel=.09);m.box((0,.9,0),(.74,.65,.65),COPPER,bevel=.08)
    m.tube([(-1.08,1.38,0),(-.43,1.4,0),(.48,1.4,0),(.98,1.46,0)],[.045,.29,.30,.06],[.02,.22,.22,.03],SILVER,sides=8)
    m.ring((0,.67,0),.44,.045,EMBER,segments=16);all.append(m)
    m=Mesh('breach_arch')
    for s in [-1,1]:
        m.box((s*3.42,1.54,0),(.35,3.1,.79),METAL,bevel=.06)
        m.box((s*3.20,1.54,-.02),(.065,2.72,.75),CYAN,bevel=.01)
        m.tube([(s*3.42,2.92,0),(s*3.33,3.54,0),(s*2.64,4.14,0),(s*1.39,4.57,0),(0,4.71,0)],[.20,.25,.28,.26,.26], [.39,.38,.35,.34,.34],TEAL,sides=8)
        m.tube([(s*3.42,2.98,-.4),(s*3.30,3.52,-.4),(s*2.62,4.08,-.38),(s*1.39,4.49,-.37),(0,4.64,-.37)],.045,slot=COPPER,sides=8)
    m.plate((0,4.48,-.36),.64,.77,(0,0,-1),slot=COPPER,depth=.10);all.append(m)
    m=Mesh('relay_pylon')
    m.tube([(0,-1,0),(0,0,0),(0,5.7,0),(0,6.5,0)],[1.08,1.12,.86,.33],[.89,.86,.70,.4],METAL,sides=8)
    for s in [-1,1]:
        m.box((s*.77,2.6,-.23),(.35,5.2,1.1),TEAL,bevel=.08)
        m.box((s*.66,2.8,-.82),(.056,3.95,.06),CYAN,bevel=.01)
        for y in [.5,1.1,1.7,2.3,2.9,3.5,4.1,4.7]:m.box((s*.81,y,.44),(.55,.17,.74),COPPER,bevel=.026)
    m.ring((0,.15,0),1.13,.12,COPPER,segments=16);all.append(m)
    m=Mesh('warden_dais')
    m.tube([(0,.036,0),(0,.065,0)],[4.25,4.20],slot=METAL,sides=12)
    for r in [3.5,4.05]:m.ring((0,.08,0),r,.026,COPPER,segments=72)
    for a in range(12):
        t=a/12*TAU;m.plate((math.cos(t)*3.77,.08,math.sin(t)*3.77),.35,.45,(0,1,0),(math.sin(t),0,-math.cos(t)),CYAN,depth=.007)
    m.plate((0,.08,0),2.8,3.2,(0,1,0),(0,0,1),TEAL,depth=.01);all.append(m)
    m=Mesh('cable_tray')
    m.box((0,0,0),(.50,.10,4),METAL,bevel=.025)
    for x in [-.17,0,.17]:m.tube([(x,.07,-2),(x,.07,2)],.054,slot=COPPER,sides=8)
    for z in [-1.6,-.8,0,.8,1.6]:m.box((0,.092,z),(.50,.10,.08),METAL,bevel=.014)
    all.append(m)
    return all


def main():
    atlas();report=[m.export() for m in [magma(),sentinel(),sentinel(True),*kit()]]
    files={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.suffix in ('.png','.glb')}
    manifest={'version':2,'source':'tools/build_art.py','pose_source_sha256':hashlib.sha256(Path(__file__).with_name('pose_cleanup.py').read_bytes()).hexdigest(),'paint_source_sha256':hashlib.sha256(Path(__file__).with_name('paint_surfaces.py').read_bytes()).hexdigest(),'source_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'units':'metres','up':'+Y','forward':'-Z','atlas_size':[2048,2048],'textures':['base color','occlusion/roughness/metallic','OpenGL normal','emission'],'assets':report,'sha256':files}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps(report,indent=2));print('ART_BUILD: %d assets, %d triangles'%(len(report),sum(a['triangles'] for a in report)))
if __name__=='__main__':main()
