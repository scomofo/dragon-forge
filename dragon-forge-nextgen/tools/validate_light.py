#!/usr/bin/env python3
"""Validate committed Lumen/Light exports independently, without rebuilding or numpy."""
import hashlib
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'campaign' / 'light'
CHECKS = 0
EXPECTED_CLIPS = {'idle': 1.8, 'walk': .8, 'claw': .32, 'breath': .56,
                  'wall': .68, 'burst': .72, 'guard': 1., 'hurt': .24, 'defeat': .9}
WINDUPS = {'claw': .12, 'breath': .26, 'wall': .32, 'burst': .40}


def check(ok, message):
    global CHECKS
    CHECKS += 1
    if not ok:
        raise AssertionError(message)


def read_glb(path):
    blob = path.read_bytes()
    check(len(blob) > 28, 'GLB payload exists')
    magic, version, total = struct.unpack_from('<III', blob)
    check(magic == 0x46546C67 and version == 2 and total == len(blob), 'GLB v2 header')
    size, kind = struct.unpack_from('<II', blob, 12)
    check(kind == 0x4E4F534A, 'JSON first')
    doc = json.loads(blob[20:20 + size])
    count, kind = struct.unpack_from('<II', blob, 20 + size)
    check(kind == 0x004E4942 and 28 + size + count == total, 'Complete binary chunk')
    return doc, blob[28 + size:]


def access(doc, binary, index):
    item = doc['accessors'][index]
    view = doc['bufferViews'][item['bufferView']]
    count = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[item['type']]
    fmt = '<' + {5126: 'f', 5125: 'I', 5123: 'H'}[item['componentType']] * count
    width = struct.calcsize(fmt)
    start = view.get('byteOffset', 0) + item.get('byteOffset', 0)
    stride = view.get('byteStride', width)
    return [struct.unpack_from(fmt, binary, start + i * stride) for i in range(item['count'])]



manifest = json.loads((FOLDER / 'manifest.json').read_text())
check(manifest.get('source') == 'tools/build_light_guardian.py', 'Editable source recorded')
check(manifest.get('guardian') == 'Lumen', 'Canonical guardian name')
files = {'light_guardian.glb', 'atlas_base.png', 'atlas_orm.png', 'atlas_normal.png', 'atlas_emission.png'}
check(set(manifest['files']) == files, 'Exactly one GLB and four texture atlases')
for name, digest in manifest['files'].items():
    path = FOLDER / name
    check(path.is_file(), 'Committed ' + name)
    check(hashlib.sha256(path.read_bytes()).hexdigest() == digest, 'Hash ' + name)
    if name.endswith('.png'):
        header = path.read_bytes()[:26]
        check(header[:8] == b'\x89PNG\r\n\x1a\n' and header[12:16] == b'IHDR', 'PNG header ' + name)
        check(struct.unpack_from('>II', header, 16) == (1024, 1024), '1024-square atlas ' + name)
        check(header[24] == 8 and header[25] == 2, 'RGB8 atlas ' + name)
asset = manifest['asset']
check(asset['file'] == 'light_guardian.glb', 'Expected GLB file')
doc, binary = read_glb(FOLDER / asset['file'])
check(len(doc['meshes']) == 1 and len(doc['meshes'][0]['primitives']) == 1 and asset['surfaces'] == 1, 'Single bounded render surface')
primitive = doc['meshes'][0]['primitives'][0]
vertices = access(doc, binary, primitive['attributes']['POSITION'])
indices = [i[0] for i in access(doc, binary, primitive['indices'])]
triangles = len(indices) // 3
check(len(vertices) == asset['vertices'] and 1800 <= len(vertices) <= 6000, 'Vertex manifest and budget')
check(triangles == asset['triangles'] and len(indices) % 3 == 0 and 1400 <= triangles <= 6000, 'Triangle manifest and budget')
check(all(0 <= i < len(vertices) for i in indices), 'Indices refer to real vertices')
check(all(math.isfinite(x) for p in vertices for x in p), 'Finite geometry')
joints = doc['skins'][0]['joints']
check(len(joints) == asset['bones'] and len(joints) == 25, 'Biped/pane joint manifest and budget')
names = [doc['nodes'][index]['name'] for index in joints]
required_bones = ['Root', 'Pelvis', 'Chest', 'Neck', 'Head', 'Jaw', 'Emitter'] + [
    part + '.' + side for side in ['L', 'R'] for part in ['Arm', 'Forearm', 'Hand', 'Thigh', 'Shin', 'Foot', 'Wing', 'WingMid', 'WingTip']]
check(set(names) == set(required_bones), 'Two arms, two legs, head and two three-part wings')
weights = access(doc, binary, primitive['attributes']['WEIGHTS_0'])
check(all(abs(sum(row) - 1) < 1e-5 and min(row) >= 0 for row in weights), 'Normalized skin weights')
bounds = [[min(p[i] for p in vertices) for i in range(3)], [max(p[i] for p in vertices) for i in range(3)]]
check(all(abs(bounds[j][i] - asset['bounds'][j][i]) < 1e-5 for j in range(2) for i in range(3)), 'Bounds computed from actual vertices')
check(bounds[0][1] >= .20 and bounds[1][1] <= 3.1, 'Hover clearance and bounded height')
check(3.0 < bounds[1][0] - bounds[0][0] < 3.8 and bounds[1][2] - bounds[0][2] < 1.2, 'Wide wing chevron and bounded body depth')
expected = list(EXPECTED_CLIPS)
check([clip.get('name') for clip in doc['animations']] == expected and asset['clips'] == expected, 'Nine named clips in canonical order')
check(manifest['clip_durations'] == EXPECTED_CLIPS and manifest['action_windups'] == WINDUPS, 'Recorded combat clip timing')
for clip in doc['animations']:
    times = [row[0] for row in access(doc, binary, clip['samplers'][0]['input'])]
    check(times[0] == 0 and all(a < b for a, b in zip(times, times[1:])), 'Ordered sample times ' + clip['name'])
    check(abs(times[-1] - EXPECTED_CLIPS[clip['name']]) < 1e-5, 'Clip duration ' + clip['name'])
    if clip['name'] in WINDUPS:
        check(any(abs(t - WINDUPS[clip['name']]) < 1e-5 for t in times), 'Exact authoritative contact sample ' + clip['name'])
    check(all(channel['target']['path'] in ['rotation', 'translation'] for channel in clip['channels']), 'Presentation-only channels ' + clip['name'])
    outputs = [access(doc, binary, sampler['output']) for sampler in clip['samplers']]
    check(all(math.isfinite(x) for rows in outputs for row in rows for x in row), 'Finite samples ' + clip['name'])
    check(any(any(row != rows[0] for row in rows[1:]) for rows in outputs), 'Authored motion ' + clip['name'])
uris = [entry.get('uri', '') for entry in doc.get('images', [])]
check(set(uris) == files - {'light_guardian.glb'}, 'Four local texture references')
check(all(Path(uri).name == uri and (FOLDER / uri).resolve().is_relative_to(ROOT) for uri in uris), 'Texture paths stay inside project')
material = doc['materials'][0]
check(material.get('alphaMode', 'OPAQUE') == 'OPAQUE', 'Portable hard opalescent panes without alpha sorting')
check('emissiveTexture' in material and 'normalTexture' in material and 'occlusionTexture' in material, 'Luminous pane emission and full PBR maps')
design = manifest['design']
check(design['plan'] == 'stained-glass winged biped' and design['silhouette'] == 'wing-chevron-panes', 'Art Bible biped/wing design')
check(design['palette'] == 'gold-white' and design['rigid_panes'] and design['wing_panels'] == 6, 'Six rigid gold/white wing panes')
check(design['muzzle_joint'] == 'Emitter' and not design['grounded'] and not design['foot_planting'], 'Authored emitter and honest hovering contract')
joint_indices = access(doc, binary, primitive['attributes']['JOINTS_0'])
check(all(0 <= i < len(joints) for row in joint_indices for i in row), 'Valid skin joint indices')
check(all(sum(weight > 1e-5 for weight in row) == 1 for row in weights), 'Rigid skinning preserves hard pane shapes')
for side in ['L', 'R']:
    for part in ['Arm', 'Forearm', 'Hand', 'Thigh', 'Shin', 'Foot', 'Wing', 'WingMid', 'WingTip']:
        index = names.index(part + '.' + side)
        count = sum(row[0] == index for row in joint_indices)
        check(count >= 30, 'Actual geometry on ' + part + '.' + side)
    foot_index = names.index('Foot.' + side)
    foot_vertices = [vertex for vertex, indices_row in zip(vertices, joint_indices) if indices_row[0] == foot_index]
    check(min(vertex[1] for vertex in foot_vertices) >= .20, 'Foot visibly clears deck ' + side)

# Evaluate the actual skinned geometry at clip endpoints, midpoint and contact.
# Finite channels alone cannot catch a broken inverse bind or runaway hierarchy.
parents = {child: index for index, node in enumerate(doc['nodes']) for child in node.get('children', [])}
binds = access(doc, binary, doc['skins'][0]['inverseBindMatrices'])
def matrix(rotation, translation):
    x, y, z, w = rotation
    return [[1-2*y*y-2*z*z, 2*x*y-2*z*w, 2*x*z+2*y*w, translation[0]],
            [2*x*y+2*z*w, 1-2*x*x-2*z*z, 2*y*z-2*x*w, translation[1]],
            [2*x*z-2*y*w, 2*y*z+2*x*w, 1-2*x*x-2*y*y, translation[2]], [0., 0., 0., 1.]]
def multiply(a, b): return [[sum(a[r][k]*b[k][c] for k in range(4)) for c in range(4)] for r in range(4)]
identity = matrix((0, 0, 0, 1), (0, 0, 0))
for clip in doc['animations']:
    times = [row[0] for row in access(doc, binary, clip['samplers'][0]['input'])]
    sample_indices = {0, len(times)//2, len(times)-1}
    if clip['name'] in WINDUPS:
        sample_indices.add(min(range(len(times)), key=lambda i: abs(times[i]-WINDUPS[clip['name']])))
    for sample in sorted(sample_indices):
        translations = {index: node.get('translation', (0, 0, 0)) for index, node in enumerate(doc['nodes'])}
        rotations = {index: (0, 0, 0, 1) for index in translations}
        for channel in clip['channels']:
            sampler = clip['samplers'][channel['sampler']]
            value = access(doc, binary, sampler['output'])[sample]
            (rotations if channel['target']['path'] == 'rotation' else translations)[channel['target']['node']] = value
        globals_cache = {}
        def global_matrix(index):
            if index not in globals_cache:
                local = matrix(rotations[index], translations[index])
                globals_cache[index] = multiply(global_matrix(parents[index]), local) if index in parents else local
            return globals_cache[index]
        skin = [multiply(global_matrix(node), [[binds[i][c*4+r] for c in range(4)] for r in range(4)]) for i, node in enumerate(joints)]
        posed = []
        for vertex, ji, weight in zip(vertices, joint_indices, weights):
            # The rigid-panes contract above guarantees exactly one active joint.
            m = skin[ji[0]]; p = tuple(sum(m[r][c]*vertex[c] for c in range(3))+m[r][3] for r in range(3)); posed.append(p)
        check(all(math.isfinite(v) and abs(v) < 5 for p in posed for v in p), 'Finite bounded skinning ' + clip['name'] + ' sample ' + str(sample))
        check(max(p[1] for p in posed) < 3.5, 'Animation height budget ' + clip['name'])

# Decode the two color atlases using only stdlib; no rebuild/Pillow dependency.
# The order R >= G >= B permits white and gold while rejecting violet/blue.
def png_rgb(path):
    import zlib
    payload = path.read_bytes(); offset = 8; packed = bytearray()
    while offset < len(payload):
        size = struct.unpack_from('>I', payload, offset)[0]; kind = payload[offset+4:offset+8]
        if kind == b'IDAT': packed.extend(payload[offset+8:offset+8+size])
        offset += size+12
    decoded = zlib.decompress(packed); stride = 1024*3; previous = bytearray(stride)
    for y in range(1024):
        start = y*(stride+1); kind = decoded[start]; row = bytearray(decoded[start+1:start+1+stride])
        for x in range(stride):
            left = row[x-3] if x >= 3 else 0; up = previous[x]; upper_left = previous[x-3] if x >= 3 else 0
            if kind == 1: row[x] = (row[x]+left)&255
            elif kind == 2: row[x] = (row[x]+up)&255
            elif kind == 3: row[x] = (row[x]+(left+up)//2)&255
            elif kind == 4:
                p = left+up-upper_left; a,b,c = abs(p-left),abs(p-up),abs(p-upper_left)
                predictor = left if a <= b and a <= c else up if b <= c else upper_left
                row[x] = (row[x]+predictor)&255
            elif kind != 0: raise AssertionError('Unsupported PNG filter')
        yield row; previous = row
for name in ['atlas_base.png', 'atlas_emission.png']:
    check(all(row[x] >= row[x+1] >= row[x+2] for row in png_rgb(FOLDER/name) for x in range(0,len(row),3)), 'Every pixel stays gold/white: ' + name)
print(f'LIGHT_EXPORTS: {CHECKS} checks, 0 failures / {len(vertices)} vertices / {triangles} triangles / {len(joints)} joints')
