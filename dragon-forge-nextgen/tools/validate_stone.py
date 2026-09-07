#!/usr/bin/env python3
"""Validate committed Cairn/Stone assets without rebuilding them."""
import hashlib, json, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'campaign'/'stone'
checks=0

def check(ok,msg):
    global checks
    checks+=1
    if not ok: raise AssertionError(msg)

def glb(path):
    blob=path.read_bytes()
    check(len(blob)>28,'GLB has payload')
    magic,version,total=struct.unpack_from('<III',blob,0)
    check(magic==0x46546C67 and version==2 and total==len(blob),'valid GLB header')
    n,kind=struct.unpack_from('<II',blob,12)
    check(kind==0x4E4F534A,'JSON chunk first')
    return json.loads(blob[20:20+n])

m=json.loads((FOLDER/'manifest.json').read_text())
check(m.get('source')=='tools/build_stone_guardian.py','editable source recorded')
for name,digest in m['files'].items():
    p=FOLDER/name
    check(p.is_file(),'committed '+name)
    check(hashlib.sha256(p.read_bytes()).hexdigest()==digest,'hash '+name)
a=m['asset'];doc=glb(FOLDER/a['file'])
prim=doc['meshes'][0]['primitives'][0]
check(doc['accessors'][prim['attributes']['POSITION']]['count']==a['vertices']==1555,'1555 vertices')
check(doc['accessors'][prim['indices']]['count']//3==a['triangles']==1908,'1908 triangles')
check(len(doc['skins'][0]['joints'])==a['bones']==18,'18 skin joints')
clips=[x.get('name','') for x in doc['animations']]
check(clips==a['clips'] and len(clips)==9,'nine named clips in authored order')
check(len(doc['materials'])>=1,'material assigned')
uris=[x.get('uri','') for x in doc.get('images',[])]
for name in ['atlas_base.png','atlas_orm.png','atlas_normal.png','atlas_emission.png']:
    check(name in uris,'GLB references '+name)
    check((FOLDER/name).is_file(),'referenced texture exists '+name)
check(all((FOLDER/u).resolve().is_relative_to(ROOT) for u in uris),'all image refs remain in project')
check(len(doc.get('animations',[]))==9,'no missing animations')
print(f'STONE_EXPORTS: {checks} checks, 0 failures')
