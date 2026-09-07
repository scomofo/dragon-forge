#!/usr/bin/env python3
"""Read-only local asset integrity, skin and animation-continuity checks. Standard library."""
from pathlib import Path
import hashlib, json, math, struct
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'campaign/bosses/assets'
checks=0

def check(ok, label):
    global checks
    checks+=1
    if not ok: raise AssertionError(label)

def glb(path):
    blob=path.read_bytes();magic,version,size=struct.unpack_from('<III',blob)
    check(magic==0x46546c67 and version==2 and size==len(blob),path.name+' container')
    length,kind=struct.unpack_from('<II',blob,12)
    check(kind==0x4e4f534a,path.name+' JSON chunk')
    doc=json.loads(blob[20:20+length]);offset=20+length
    n,k=struct.unpack_from('<II',blob,offset)
    check(k==0x004e4942,path.name+' binary chunk')
    return doc,blob[offset+8:offset+8+n]

def values(doc, binary, index):
    a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
    fields={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
    fmt='<'+{5126:'f',5125:'I',5123:'H'}[a['componentType']]*fields
    stride=struct.calcsize(fmt);start=v.get('byteOffset',0)+a.get('byteOffset',0)
    return [struct.unpack_from(fmt,binary,start+i*v.get('byteStride',stride)) for i in range(a['count'])]

def main():
    manifest=json.loads((OUT/'manifest.json').read_text())
    check(len(manifest['assets'])==5,'five independently named boss assets')
    check(len(manifest['files'])==9,'five GLBs plus four texture maps')
    for name,digest in manifest['files'].items():
        check(Path(name).name==name and hashlib.sha256((OUT/name).read_bytes()).hexdigest()==digest,'SHA-256 '+name)
    fingerprints=set()
    for meta in manifest['assets']:
        doc,binary=glb(OUT/meta['file']);prim=doc['meshes'][0]['primitives'][0];attrs=prim['attributes']
        v=values(doc,binary,attrs['POSITION']);j=values(doc,binary,attrs['JOINTS_0']);w=values(doc,binary,attrs['WEIGHTS_0'])
        check(all(math.isfinite(x) for row in v for x in row),'finite positions')
        check(all(max(abs(row[0]),abs(row[2]))<3 and -.01<=row[1]<4.2 for row in v),'bounded initial geometry')
        check(len(v)==meta['vertices'],'manifest vertex count')
        joints=doc['skins'][0]['joints'];check(len(joints)==meta['bones'],'manifest skin count')
        check(all(abs(sum(row)-1)<.0001 and min(row)>=0 for row in w),'normalized skin weights')
        check(all(0<=x<len(joints) for row in j for x in row),'valid joint indices')
        check(all(x['uri'].startswith('atlas_') and Path(x['uri']).name==x['uri'] for x in doc['images']),'only local atlas textures')
        fingerprint=hashlib.sha256(repr(v).encode()).hexdigest()
        check(fingerprint not in fingerprints,'not a recolored copy');fingerprints.add(fingerprint)
        clips={x['name']:x for x in doc['animations']}
        check(set(meta['clips'])==set(clips),'manifest clips')
        check({'idle','walk','open','defeat'}.issubset(clips),'complete lifecycle clips')
        for name,clip in clips.items():
            check(all(c['target']['node'] in joints and c['target']['path'] in ['rotation','translation'] for c in clip['channels']),'bone-only clip / '+name)
            if not name.startswith('tell_'): continue
            other=clips['strike_'+name[5:]]
            outputs={ (c['target']['node'],c['target']['path']):values(doc,binary,other['samplers'][c['sampler']]['output'])[0] for c in other['channels']}
            same=True
            for c in clip['channels']:
                last=values(doc,binary,clip['samplers'][c['sampler']]['output'])[-1]
                first=outputs[(c['target']['node'],c['target']['path'])]
                same &= all(abs(a-b)<1e-6 for a,b in zip(first,last))
            check(same,'tell/impact pose continuity / '+name)
    print(f'BOSS_INTEGRITY: {checks} checks, 0 failures')

if __name__=='__main__':main()
