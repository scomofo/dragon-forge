#!/usr/bin/env python3
"""Add skinned Storm crown, conductor vanes and wing armor; preserve base Arc exactly.
Offline authoring only. Original textures, rig and all nine animation tracks are reused.
"""
from pathlib import Path
import hashlib, json
import build_art as art
import build_storm_guardian as storm
from build_evolutions import rewrite_texture_uris
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'campaign/tempest'
def build():
    m=storm.guardian();m.name='tempest_arc'
    b={name:i for i,(name,_,_) in enumerate(m.bones)}
    for s in [-1,1]:
        # Swept lightning fork beside the existing horns, not covering the eye.
        m.tube([(s*.23,1.93,-.84),(s*.45,2.26,-.56),(s*.41,2.54,-.26)],[.10,.08,.005],slot=5,bone=b['Head'],sides=6)
        m.tube([(s*.41,2.18,-.56),(s*.72,2.38,-.25),(s*.73,2.52,-.10)],[.07,.046,.003],slot=3,bone=b['Head'],sides=6)
        for z in [-.12,.25,.62]:
            m.plate((s*.24,1.65,z),.37,.39,normal=(s*.6,.8,0),up=(0,0,-1),slot=5,bone=b['Body'],depth=.065)
        # Segments follow each wing bone, avoiding a bridge that would shear when flapped.
        m.plate((s*.72,1.60,.14),1.12,.40,normal=(0,1,0),up=(0,0,-1),slot=7,bone=b['Wing.'+str(s)],depth=.025)
        m.plate((s*1.49,1.68,.23),.72,.32,normal=(0,1,0),up=(0,0,-1),slot=5,bone=b['WingTip.'+str(s)],depth=.03)
        m.tube([(s*1.27,1.68,.44),(s*1.77,1.79,.88)],[.06,.003],slot=3,bone=b['WingTip.'+str(s)],sides=5)
    m.tube([(0,1.76,.10),(0,2.04,.35),(0,2.19,.69)],[.105,.10,.004],slot=3,bone=b['Body'],sides=6)
    return m
if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True);art.OUT=OUT
    entry=build().export();path=OUT/entry['file'];rewrite_texture_uris(path,'../fusion_assets')
    entry.update(parent_asset='campaign/fusion_assets/storm_guardian.glb',parent_sha256=hashlib.sha256((ROOT/'campaign/fusion_assets/storm_guardian.glb').read_bytes()).hexdigest(),sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    (OUT/'manifest.json').write_text(json.dumps({'source':'tools/build_tempest.py','assets':[entry]},indent=2)+'\n')
    print(json.dumps(entry,indent=2))
