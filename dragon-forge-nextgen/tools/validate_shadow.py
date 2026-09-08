#!/usr/bin/env python3
"""Validate committed Umbra/Shadow exports without rebuilding them."""
import hashlib,json,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];FOLDER=ROOT/'campaign'/'shadow';checks=0
def check(ok,msg):
    global checks;checks+=1
    if not ok:raise AssertionError(msg)
def glb(path):
    blob=path.read_bytes();check(len(blob)>28,'GLB payload')
    magic,version,total=struct.unpack_from('<III',blob,0);check(magic==0x46546C67 and version==2 and total==len(blob),'GLB v2 header')
    n,kind=struct.unpack_from('<II',blob,12);check(kind==0x4E4F534A,'JSON first');return json.loads(blob[20:20+n])
m=json.loads((FOLDER/'manifest.json').read_text());check(m.get('source')=='tools/build_shadow_guardian.py','editable source recorded')
for name,digest in m['files'].items():
    p=FOLDER/name;check(p.is_file(),'committed '+name);check(hashlib.sha256(p.read_bytes()).hexdigest()==digest,'hash '+name)
a=m['asset'];doc=glb(FOLDER/a['file']);prim=doc['meshes'][0]['primitives'][0]
vertices=doc['accessors'][prim['attributes']['POSITION']]['count'];triangles=doc['accessors'][prim['indices']]['count']//3;joints=len(doc['skins'][0]['joints'])
check(vertices==a['vertices'] and 1000<=vertices<=4500,'manifest vertex count in bounded budget')
check(triangles==a['triangles'] and 1200<=triangles<=6000,'manifest triangle count in bounded budget')
check(joints==a['bones'] and 22<=joints<=30,'holed-wolf joint budget')
clips=[x.get('name','') for x in doc['animations']];expected=['idle','walk','claw','breath','wall','burst','guard','hurt','defeat'];check(clips==expected and a['clips']==expected,'nine named clips')
uris=[x.get('uri','') for x in doc.get('images',[])]
for name in ['atlas_base.png','atlas_orm.png','atlas_normal.png','atlas_emission.png']:
    check(name in uris,'GLB references '+name);check((FOLDER/name).is_file(),'texture exists '+name)
check(all((FOLDER/u).resolve().is_relative_to(ROOT) for u in uris),'all image refs stay in project')
check(a['bounds'][0][1]>=0.08 and a['bounds'][1][1]<=2.1,'grounded bounded vertical silhouette')
print(f'SHADOW_EXPORTS: {checks} checks, 0 failures / {vertices} vertices / {triangles} triangles / {joints} joints')
