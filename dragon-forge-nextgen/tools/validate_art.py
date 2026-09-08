#!/usr/bin/env python3
"""Validate shipped art bytes, glTF attributes, joints, clips and external textures.
This is asset validation, not a substitute for Godot import/render tests.
"""
import hashlib, json, math, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art'/'generated'
manifest=json.loads((ART/'manifest.json').read_text())
checks=0

def check(value,message):
    global checks
    checks+=1
    if not value: raise AssertionError(message)

for name,sha in manifest['sha256'].items():
    check('/' not in name and '\\' not in name, 'local filenames only')
    check(hashlib.sha256((ART/name).read_bytes()).hexdigest()==sha,name+' hash')
for record in manifest['assets']:
    path=ART/record['file'];blob=path.read_bytes()
    check(struct.unpack_from('<III',blob)==(0x46546c67,2,len(blob)),path.name+' valid GLB header')
    count,kind=struct.unpack_from('<II',blob,12);check(kind==0x4e4f534a,'JSON chunk')
    doc=json.loads(blob[20:20+count]);n,kind=struct.unpack_from('<II',blob,20+count);data=blob[28+count:]
    check(kind==0x004e4942 and len(data)==n,'binary chunk')
    def accessor(index):
        a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
        components={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
        start=v.get('byteOffset',0)+a.get('byteOffset',0)
        fmt='<'+{5126:'f',5125:'I',5123:'H'}[a['componentType']]*components
        stride=struct.calcsize(fmt);check(start+a['count']*stride<=len(data),'accessor bounds')
        return [struct.unpack_from(fmt,data,start+i*stride) for i in range(a['count'])]
    for image in doc['images']:
        uri=image['uri'];check(uri in manifest['sha256'] and (ART/uri).is_file(),'local texture exists')
    check(len(doc['materials'])==1 and len(doc['meshes'])==1,'one atlas material and combined mesh')
    primitive=doc['meshes'][0]['primitives'][0];attrs=primitive['attributes']
    pos=accessor(attrs['POSITION']);uv=accessor(attrs['TEXCOORD_0']);indices=accessor(primitive['indices'])
    check(len(pos)==record['vertices'] and len(indices)//3==record['triangles'],'catalog matches geometry')
    check(all(math.isfinite(x) for v in pos for x in v),'finite positions')
    check(all(0<=x<=1 for v in uv for x in v),'UV atlas bounds')
    check(all(0<=v[0]<len(pos) for v in indices),'valid triangle indices')
    check(record['triangles']<=22000,'per-asset triangle budget')
    def uv_area(i):
        a,b,c=(uv[indices[i+k][0]] for k in range(3))
        return abs((b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]))
    check(all(uv_area(i)>1e-12 for i in range(0,len(indices),3)), 'non-degenerate triangle UVs')
    for a in doc['accessors']:
        if 'min' in a: check(isinstance(a['min'],list) and isinstance(a['max'],list),'glTF accessor bounds are arrays')
    check(all(node.get('children') != [] for node in doc['nodes']),'no empty children arrays')
    if record['bones']:
        weights=accessor(attrs['WEIGHTS_0']);joints=accessor(attrs['JOINTS_0'])
        check(all(abs(sum(v)-1)<1e-5 and all(0<=x<=1 for x in v) for v in weights),'normalized skin weights')
        check(all(0<=j<record['bones'] for v in joints for j in v),'valid skin joints')
        check(len(doc['skins'][0]['joints'])==record['bones'],'skin bones')
        check({a['name'] for a in doc['animations']}==set(record['clips']),'authored clips')
        for a in doc['animations']:
            for sampler in a['samplers']:
                ts=accessor(sampler['input']);values=accessor(sampler['output'])
                check(len(ts)==len(values) and all(ts[i][0]<ts[i+1][0] for i in range(len(ts)-1)), 'monotonic keys')
                check(all(math.isfinite(x) for v in values for x in v),'finite key values')
print('ART_ASSET_VALIDATION: %d checks, 0 failures'%checks)
