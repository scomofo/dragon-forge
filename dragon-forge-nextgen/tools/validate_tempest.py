#!/usr/bin/env python3
"""Validate evolved exports AND byte-equivalence of all original geometry/animation.
No third-party modules. Format validation is separately done by the Khronos validator.
"""
import hashlib, json, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'campaign'/'tempest'
checks=0

def check(value,message):
    global checks
    checks+=1
    if not value: raise AssertionError(message)

def read(path):
    blob=path.read_bytes()
    check(struct.unpack_from('<III',blob)==(0x46546c67,2,len(blob)),'valid GLB header')
    n,kind=struct.unpack_from('<II',blob,12)
    check(kind==0x4e4f534a,'JSON chunk type')
    return json.loads(blob[20:20+n]),blob[28+n:]

def accessor(doc,data,index):
    a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
    components={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
    width={5126:4,5125:4,5123:2}[a['componentType']]*components
    assert v.get('byteStride',width)==width,'Expected packed authoring output'
    start=v.get('byteOffset',0)+a.get('byteOffset',0)
    return data[start:start+a['count']*width]

for entry in json.loads((FOLDER/'manifest.json').read_text())['assets']:
    path=FOLDER/entry['file'];parent=ROOT/entry['parent_asset']
    check(path.parent==FOLDER and path.suffix=='.glb','local output filename')
    check(hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256'],'evolved export hash')
    check(hashlib.sha256(parent.read_bytes()).hexdigest()==entry['parent_sha256'],'parent export unchanged')
    doc,data=read(path);base,old=read(parent)
    p=doc['meshes'][0]['primitives'][0];b=base['meshes'][0]['primitives'][0]
    check(doc['accessors'][p['attributes']['POSITION']]['count']>base['accessors'][b['attributes']['POSITION']]['count'],'new evolution geometry exists')
    for attr in b['attributes']:
        old_bytes=accessor(base,old,b['attributes'][attr])
        check(accessor(doc,data,p['attributes'][attr]).startswith(old_bytes),'original '+attr+' preserved byte-for-byte')
    check(accessor(doc,data,p['indices']).startswith(accessor(base,old,b['indices'])),'original triangle order preserved')
    check(doc['skins'][0]['joints']==base['skins'][0]['joints'],'identical skin joint order')
    check(accessor(doc,data,doc['skins'][0]['inverseBindMatrices'])==accessor(base,old,base['skins'][0]['inverseBindMatrices']),'unchanged inverse binds')
    for i in doc['skins'][0]['joints']:
        check(doc['nodes'][i]==base['nodes'][i],'bone name hierarchy and rest position unchanged')
    check(len(doc['animations'])==len(base['animations'])==9,'nine inherited animation clips')
    for anim,original in zip(doc['animations'],base['animations']):
        check(anim['name']==original['name'] and anim['channels']==original['channels'],'animation targets unchanged')
        for sample,old_sample in zip(anim['samplers'],original['samplers']):
            for field in ['input','output']:
                check(accessor(doc,data,sample[field])==accessor(base,old,old_sample[field]),'animation keys preserved')
    for image in doc['images']:
        check((path.parent/image['uri']).resolve().is_relative_to(ROOT) and (path.parent/image['uri']).is_file(),'shared texture inside project')
print(f'TEMPEST_EXPORTS: {checks} checks, 0 failures')
