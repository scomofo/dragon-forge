"""Read-only integrity/UV/skin checks for the committed realism exports (stdlib)."""
import hashlib
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
checks = 0


def check(ok, message):
    global checks
    checks += 1
    if not ok:
        raise AssertionError(message)


def read(path):
    blob = path.read_bytes()
    size = struct.unpack_from('<I', blob, 12)[0]
    return json.loads(blob[20:20 + size]), blob[28 + size:]


def values(doc, binary, index):
    a = doc['accessors'][index]
    view = doc['bufferViews'][a['bufferView']]
    n = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[a['type']]
    fmt = '<' + {5126: 'f', 5125: 'I', 5123: 'H'}[a['componentType']] * n
    start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
    stride = view.get('byteStride', struct.calcsize(fmt))
    return [struct.unpack_from(fmt, binary, start + i * stride) for i in range(a['count'])]


for folder, asset_id in [('art/generated', 'magma_guardian'), ('campaign/guardians', 'ice_guardian'),
                         ('campaign/fusion_assets', 'storm_guardian'), ('campaign/venom', 'venom_guardian')]:
    path = ROOT / folder
    manifest = json.loads((path / 'manifest.json').read_text())
    for field, source in [('source_sha256', manifest['source']),
                          ('compiler_sha256', 'tools/build_art.py'),
                          ('creature_detail_sha256', 'tools/creature_detail.py')]:
        check(hashlib.sha256((ROOT / source).read_bytes()).hexdigest() == manifest[field], asset_id + ' ' + field)
    check(manifest['authoring_versions'] == {'numpy': '2.2.6', 'Pillow': '11.3.0'}, 'Pinned authoring dependencies')
    for filename, digest in manifest.get('files', manifest.get('sha256', {})).items():
        check(hashlib.sha256((path / filename).read_bytes()).hexdigest() == digest, 'Committed bytes: ' + filename)
    doc, binary = read(path / (asset_id + '.glb'))
    prim = doc['meshes'][0]['primitives'][0]
    attrs = prim['attributes']
    positions = values(doc, binary, attrs['POSITION'])
    uv = values(doc, binary, attrs['TEXCOORD_0'])
    weights = values(doc, binary, attrs['WEIGHTS_0'])
    joints = values(doc, binary, attrs['JOINTS_0'])
    triangles = values(doc, binary, prim['indices'])
    check(len(triangles) // 3 <= 22000, asset_id + ' bounded geometry budget')
    check(all(math.isfinite(x) for p in positions for x in p), asset_id + ' finite positions')
    check(all(0 <= x <= 1 for p in uv for x in p), asset_id + ' UVs stay inside the atlas')
    check(all(abs(sum(w) - 1) < 1e-5 and min(w) >= 0 for w in weights), asset_id + ' normalized skin')
    check(all(max(j) < len(doc['skins'][0]['joints']) for j in joints), asset_id + ' valid joints')
    if asset_id == 'storm_guardian':
        names = [doc['nodes'][j]['name'] for j in doc['skins'][0]['joints']]
        transitions = 0
        for p, tex, js, ws in zip(positions, uv, joints, weights):
            if int(tex[0] * 4) + int(tex[1] * 4) * 4 != 6:
                continue
            influences = [names[j] for j, w in zip(js, ws) if w > .05]
            if any(n.startswith('Wing.') for n in influences) and any(n.startswith('WingTip.') for n in influences):
                transitions += 1
        check(transitions >= 40, 'Flight membrane actually blends across the wrist joints')
print(f'CREATURE_DETAIL: {checks} checks, 0 failures')
