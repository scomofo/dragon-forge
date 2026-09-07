#!/usr/bin/env python3
"""Author two evolved forms, preserving every young vertex, joint, weight and clip.
Only adds skinned crown/armor/crystal geometry. Shared textures are referenced, not
copied or repainted. Run offline with tools/art-requirements.txt; never needed to play.
"""
from __future__ import annotations
import hashlib
import json
import struct
from pathlib import Path
import build_art as art
import build_ice_guardian as ice

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'campaign' / 'evolutions'


def rewrite_texture_uris(path: Path, prefix: str) -> None:
    data = path.read_bytes()
    size = struct.unpack_from('<I', data, 12)[0]
    document = json.loads(data[20:20+size])
    binary_chunk = data[20+size:]
    for image in document['images']:
        image['uri'] = prefix + '/' + image['uri']
    document['asset']['generator'] = 'Dragon Forge evolution authoring v1'
    meta = json.dumps(document, separators=(',', ':')).encode()
    meta += b' ' * (-len(meta) % 4)
    path.write_bytes(struct.pack('<III', 0x46546c67, 2, 20+len(meta)+len(binary_chunk)) + struct.pack('<II', len(meta), 0x4e4f534a) + meta + binary_chunk)


def crowned_magma():
    m = art.magma()
    m.name = 'magma_evolved'
    bone = {name: i for i, (name, _, _) in enumerate(m.bones)}
    head, chest = bone['Head'], bone['Chest']
    # Furnace crown: three swept basalt/copper vanes instead of scaling the whole dragon.
    for x, height in [(-.20, 3.14), (0, 3.34), (.20, 3.14)]:
        m.tube([(x,2.56,-.40),(x*1.45,2.78,-.19),(x*1.50,height,.19)], [.105,.095,.006], [.12,.065,.004],slot=art.SCALE,bone=head,sides=7)
        m.plate((x,2.63,-.41),.075,.18,normal=(0,.3,-1),slot=art.EMBER,bone=head,depth=.018)
    for sign in [-1,1]:
        # Rigid shoulder mantles remain clear of the animated elbows and guard hands.
        m.plate((sign*.57,2.015,.045),.62,.78,normal=(sign*.55,.76,.22),up=(0,0,-1),slot=art.SCALE,bone=chest,depth=.15)
        m.tube([(sign*.65,2.03,.22),(sign*.84,2.17,.45),(sign*.94,2.29,.70)],[.15,.10,.007],slot=art.BONE,bone=chest,sides=9)
        # Radiating copper rim on the crucible, without obscuring the existing glowing core.
        m.plate((sign*.24,1.76,-.50),.16,.54,normal=(sign*.10,.18,-1),slot=art.COPPER,bone=chest,depth=.07)
        for y,z in [(1.87,.42),(1.62,.57)]:
            m.plate((sign*.38,y,z),.65,.54,normal=(sign*.3,.30,1),slot=art.SCALE,bone=chest,depth=.14)
    return m


def aurora_rime():
    m = ice.ice()
    m.name = 'rime_evolved'
    bone = {name: i for i, (name, _, _) in enumerate(m.bones)}
    head, body = bone['Head'], bone['Body']
    # Low quadruped silhouette retained, with a wide antler crest and layered ice fans.
    for sign in [-1,1]:
        m.tube([(sign*.24,1.38,-.96),(sign*.58,1.66,-.74),(sign*.91,1.95,-.45),(sign*1.06,2.08,-.12)],[.15,.125,.065,.004],slot=2,bone=head,sides=6)
        m.tube([(sign*.55,1.66,-.73),(sign*.64,2.04,-.60),(sign*.65,2.22,-.35)],[.095,.066,.003],slot=1,bone=head,sides=5)
        for i,z in enumerate([-.46,-.02,.42,.75]):
            m.tube([(sign*.20,1.39,z),(sign*.40,1.77,z+.13),(sign*.48,1.92-i*.04,z+.30)],[.16,.125,.004],[.19,.10,.004],slot=1,bone=body,sides=5)
            m.plate((sign*.45,1.32,z),.48,.49,normal=(sign,.50,.10),slot=2,bone=body,depth=.07,tint=.85)
        m.plate((sign*.30,1.37,-1.00),.19,.27,normal=(sign,.4,-.2),slot=8,bone=head,depth=.025)
    return m


def main() -> None:
    OUT.mkdir(parents=True,exist_ok=True)
    art.OUT = OUT
    assets = []
    for build, parent, prefix in [(crowned_magma,'art/generated/magma_guardian.glb','../../art/generated'), (aurora_rime,'campaign/guardians/ice_guardian.glb','../guardians')]:
        m = build()
        entry = m.export()
        path = OUT / entry['file']
        rewrite_texture_uris(path,prefix)
        entry['parent_asset'] = parent
        entry['parent_sha256'] = hashlib.sha256((ROOT/parent).read_bytes()).hexdigest()
        entry['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
        assets.append(entry)
    (OUT/'manifest.json').write_text(json.dumps({'source':'tools/build_evolutions.py','scope':'Additional skinned crown/armor geometry; existing skeletons, clips and sole vertices retained.','assets':assets},indent=2)+'\n')
    print(json.dumps(assets,indent=2))

if __name__ == '__main__':
    main()
