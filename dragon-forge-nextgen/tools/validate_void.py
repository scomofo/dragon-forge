#!/usr/bin/env python3
"""Validate committed Null/Void exports independently, without rebuilding or numpy."""
import hashlib
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'campaign' / 'void'
CHECKS = 0
EXPECTED_CLIPS = {'idle': 1.8, 'walk': .8, 'claw': .29, 'breath': .56,
                  'wall': .42, 'burst': .64, 'guard': 1.2, 'hurt': .24, 'defeat': .9}
WINDUPS = {'claw': .11, 'breath': .26, 'wall': .18, 'burst': .30}


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


def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def hits(origin, direction, a, b, c):
    # Moller-Trumbore, both face directions: opaque or back-facing filled panes
    # must fail the aperture contract just as front-facing faces would.
    edge1, edge2 = sub(b, a), sub(c, a)
    h = cross(direction, edge2); determinant = dot(edge1, h)
    if abs(determinant) < 1e-8:
        return False
    s = sub(origin, a); u = dot(s, h) / determinant
    if u < 0 or u > 1:
        return False
    q = cross(s, edge1); v = dot(direction, q) / determinant
    return v >= 0 and u + v <= 1 and dot(edge2, q) / determinant > 0


manifest = json.loads((FOLDER / 'manifest.json').read_text())
check(manifest.get('source') == 'tools/build_void_guardian.py', 'Editable source recorded')
check(manifest.get('guardian') == 'Null', 'Canonical guardian name')
files = {'void_guardian.glb', 'atlas_base.png', 'atlas_orm.png', 'atlas_normal.png', 'atlas_emission.png'}
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
check(asset['file'] == 'void_guardian.glb', 'Expected GLB file')
doc, binary = read_glb(FOLDER / asset['file'])
check(len(doc['meshes']) == 1 and len(doc['meshes'][0]['primitives']) == 1 and asset['surfaces'] == 1, 'Single bounded render surface')
primitive = doc['meshes'][0]['primitives'][0]
vertices = access(doc, binary, primitive['attributes']['POSITION'])
indices = [i[0] for i in access(doc, binary, primitive['indices'])]
triangles = len(indices) // 3
check(len(vertices) == asset['vertices'] and 1200 <= len(vertices) <= 4500, 'Vertex manifest and budget')
check(triangles == asset['triangles'] and len(indices) % 3 == 0 and 800 <= triangles <= 3500, 'Triangle manifest and budget')
check(all(0 <= i < len(vertices) for i in indices), 'Indices refer to real vertices')
check(all(math.isfinite(x) for p in vertices for x in p), 'Finite geometry')
joints = doc['skins'][0]['joints']
check(len(joints) == asset['bones'] and 8 <= len(joints) <= 16, 'Crystal joint manifest and budget')
names = [doc['nodes'][index]['name'] for index in joints]
check('Emitter' in names and 'Frame' in names and all('Corner.' + name in names for name in ['Top', 'Right', 'Bottom', 'Left']), 'Authored frame and forward-rim emitter')
check(not any(part in name.lower() for name in names for part in ['foot', 'leg', 'head', 'jaw', 'wing', 'tail', 'pelvis']), 'No animal anatomy in crystal rig')
weights = access(doc, binary, primitive['attributes']['WEIGHTS_0'])
check(all(abs(sum(row) - 1) < 1e-5 and min(row) >= 0 for row in weights), 'Normalized skin weights')
bounds = [[min(p[i] for p in vertices) for i in range(3)], [max(p[i] for p in vertices) for i in range(3)]]
check(all(abs(bounds[j][i] - asset['bounds'][j][i]) < 1e-5 for j in range(2) for i in range(3)), 'Bounds computed from actual vertices')
check(bounds[0][1] >= .24 and bounds[1][1] <= 2.7, 'Hover clearance and bounded height')
check(bounds[1][0] - bounds[0][0] < 2.7 and bounds[1][2] - bounds[0][2] < .8, 'Readable narrow crystal frame silhouette')
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
check(set(uris) == files - {'void_guardian.glb'}, 'Four local texture references')
check(all(Path(uri).name == uri and (FOLDER / uri).resolve().is_relative_to(ROOT) for uri in uris), 'Texture paths stay inside project')
material = doc['materials'][0]
check(material.get('alphaMode', 'OPAQUE') == 'OPAQUE', 'Real negative space without alpha cutout')
check('emissiveTexture' in material and 'normalTexture' in material and 'occlusionTexture' in material, 'Inner glow and full PBR maps')
design = manifest['design']
check(design['plan'] == 'hollow crystal tetra' and design['silhouette'] == 'empty-diamond' and not design['grounded'], 'Art Bible frame-only design metadata')
check(design['aperture_center'] == [0., 1.28, 0.] and design['aperture_radius'] >= .27, 'Declared central aperture')
faces = [tuple(vertices[i] for i in indices[n:n + 3]) for n in range(0, len(indices), 3)]
# A grid through the center catches triangles covering the hole, even if their
# vertices lie outside it; oblique rays also verify an actual open volume.
for direction in [(0., 0., 1.), (.65, .25, 1.), (-.65, .25, 1.)]:
    clear = True
    for x in [-.18, 0., .18]:
        for y in [-.18, 0., .18]:
            origin = (x - direction[0] * 10, 1.28 + y - direction[1] * 10, -10.)
            clear = clear and not any(hits(origin, direction, *face) for face in faces)
    check(clear, 'Open central aperture along ' + str(direction))
print(f'VOID_EXPORTS: {CHECKS} checks, 0 failures / {len(vertices)} vertices / {triangles} triangles / {len(joints)} joints')
