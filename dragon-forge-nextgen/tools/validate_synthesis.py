#!/usr/bin/env python3
"""Validate committed Prism/Synthesis exports independently, without rebuilding or numpy."""
import hashlib
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'campaign' / 'synthesis'
CHECKS = 0
EXPECTED_CLIPS = {'idle': 1.8, 'walk': .8, 'claw': .32, 'breath': .56,
                  'wall': .60, 'burst': .76, 'guard': 1.2, 'hurt': .24, 'defeat': .9}
WINDUPS = {'claw': .12, 'breath': .26, 'wall': .28, 'burst': .36}


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
check(manifest.get('source') == 'tools/build_synthesis_guardian.py', 'Editable source recorded')
check(manifest.get('guardian') == 'Prism', 'Canonical guardian name')
files = {'synthesis_guardian.glb', 'atlas_base.png', 'atlas_orm.png', 'atlas_normal.png', 'atlas_emission.png'}
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
check(asset['file'] == 'synthesis_guardian.glb', 'Expected GLB file')
doc, binary = read_glb(FOLDER / asset['file'])
check(len(doc['meshes']) == 1 and len(doc['meshes'][0]['primitives']) == 1 and asset['surfaces'] == 1, 'Single bounded render surface')
primitive = doc['meshes'][0]['primitives'][0]
vertices = access(doc, binary, primitive['attributes']['POSITION'])
indices = [i[0] for i in access(doc, binary, primitive['indices'])]
triangles = len(indices) // 3
check(len(vertices) == asset['vertices'] and 2000 <= len(vertices) <= 5000, 'Vertex manifest and budget')
check(triangles == asset['triangles'] and len(indices) % 3 == 0 and 1000 <= triangles <= 4000, 'Triangle manifest and budget')
check(all(0 <= i < len(vertices) for i in indices), 'Indices refer to real vertices')
check(all(math.isfinite(x) for p in vertices for x in p), 'Finite geometry')
joints = doc['skins'][0]['joints']
check(len(joints) == asset['bones'] and len(joints) == 15, 'Frame/pane joint manifest and budget')
names = [doc['nodes'][index]['name'] for index in joints]
required_bones = ['Root', 'Frame', 'Corner.Top', 'Corner.Right', 'Corner.Bottom', 'Corner.Left', 'Emitter'] + ['Shard.'+str(i) for i in range(4)] + ['Pane.'+str(i) for i in range(4)]
check(set(names) == set(required_bones), 'Original Void skeleton plus four rigid pane joints')
check(not any(part in name.lower() for name in names for part in ['foot', 'leg', 'head', 'jaw', 'wing', 'tail', 'pelvis']), 'No tenth animal anatomy')
weights = access(doc, binary, primitive['attributes']['WEIGHTS_0'])
check(all(abs(sum(row) - 1) < 1e-5 and min(row) >= 0 for row in weights), 'Normalized skin weights')
bounds = [[min(p[i] for p in vertices) for i in range(3)], [max(p[i] for p in vertices) for i in range(3)]]
check(all(abs(bounds[j][i] - asset['bounds'][j][i]) < 1e-5 for j in range(2) for i in range(3)), 'Bounds computed from actual vertices')
check(bounds[0][1] >= .24 and bounds[1][1] <= 2.7, 'Hover clearance and bounded height')
check(2.4 < bounds[1][0] - bounds[0][0] < 2.7 and bounds[1][2] - bounds[0][2] < .8, 'Preserved compact Void diamond silhouette')
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
check(set(uris) == files - {'synthesis_guardian.glb'}, 'Four local texture references')
check(all(Path(uri).name == uri and (FOLDER / uri).resolve().is_relative_to(ROOT) for uri in uris), 'Texture paths stay inside project')
material = doc['materials'][0]
check(material.get('alphaMode', 'OPAQUE') == 'OPAQUE', 'Portable hard opalescent panes without alpha sorting')
check('emissiveTexture' in material and 'normalTexture' in material and 'occlusionTexture' in material, 'Luminous pane emission and full PBR maps')
design = manifest['design']
check(design['plan'] == 'void frame filled with light panes' and design['silhouette'] == 'diamond-frame-pane-fill', 'Art Bible Void+Light design')
check(design['pane_palette'] == 'gold-white' and design['rigid_panes'] and design['pane_count'] == 4, 'Four rigid gold/white fill panes')
check(design['frame_texture_slots'] == list(range(12)) and design['pane_color_slots'] == [12, 13, 14, 15] and design['center'] == [0., 1.28, 0.], 'Recorded frame and pane palette ownership')
check(design['muzzle_joint'] == 'Emitter' and not design['grounded'] and not design['foot_planting'], 'Authored emitter and honest hovering contract')
check(manifest['pane_source'] == 'tools/build_light_guardian.py', 'Actual Light pane recipe retained')
joint_indices = access(doc, binary, primitive['attributes']['JOINTS_0'])
check(all(0 <= i < len(joints) for row in joint_indices for i in row), 'Valid skin joint indices')
check(all(sum(weight > 1e-5 for weight in row) == 1 for row in weights), 'Rigid skinning preserves hard panes and frame')
for i in range(4):
    index = names.index('Pane.'+str(i))
    pane_vertices = [vertex for vertex, row in zip(vertices, joint_indices) if row[0] == index]
    check(len(pane_vertices) >= 90, 'Real pane and leading geometry ' + str(i))
    check(all(abs(v[0]) < .76 and .60 < v[1] < 2.15 and abs(v[2]) < .11 for v in pane_vertices), 'Pane inset inside original frame ' + str(i))
reference = manifest['frame_reference']
check(reference['file'] == 'campaign/void/void_guardian.glb' and reference['source'] == 'tools/build_void_guardian.py', 'Actual Void frame reference')
check(hashlib.sha256((ROOT/reference['file']).read_bytes()).hexdigest() == reference['sha256'], 'Referenced Void GLB checksum')
ref_doc, ref_binary = read_glb(ROOT/reference['file'])
ref_primitive = ref_doc['meshes'][0]['primitives'][0]
ref_vertices = access(ref_doc, ref_binary, ref_primitive['attributes']['POSITION'])
ref_indices = [row[0] for row in access(ref_doc, ref_binary, ref_primitive['indices'])]
check(len(ref_vertices) == reference['vertices'] and len(ref_indices)//3 == reference['triangles'] and len(ref_doc['skins'][0]['joints']) == reference['bones'], 'Reference counts derive from actual asset')
check(vertices[:len(ref_vertices)] == ref_vertices and indices[:len(ref_indices)] == ref_indices, 'Void frame geometry retained byte-for-byte as mesh prefix')
check(len(vertices) > len(ref_vertices) and len(indices) > len(ref_indices), 'Real additional pane geometry')
ref_skin_indices = access(ref_doc, ref_binary, ref_primitive['attributes']['JOINTS_0'])
check(joint_indices[:len(ref_vertices)] == ref_skin_indices, 'Original frame skin assignment retained')
ref_names = [ref_doc['nodes'][i]['name'] for i in ref_doc['skins'][0]['joints']]
check(names[:len(ref_names)] == ref_names, 'Original frame skeleton retained')

# Inverse of the Void aperture test: rays must hit the new solid pane geometry,
# including at oblique views. A glow, renamed frame or painted outline fails.
def sub(a, b): return tuple(x-y for x,y in zip(a,b))
def dot(a, b): return sum(x*y for x,y in zip(a,b))
def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def hits(origin, direction, a, b, c):
    edge1, edge2 = sub(b,a), sub(c,a); h = cross(direction,edge2); determinant = dot(edge1,h)
    if abs(determinant) < 1e-8: return False
    s = sub(origin,a); u = dot(s,h)/determinant
    if u < 0 or u > 1: return False
    q = cross(s,edge1); v = dot(direction,q)/determinant
    return v >= 0 and u+v <= 1 and dot(edge2,q)/determinant > 0
pane_faces = [tuple(vertices[i] for i in indices[n:n+3]) for n in range(len(ref_indices),len(indices),3)]
for direction in [(0.,0.,1.),(.65,.25,1.),(-.65,.25,1.)]:
    filled = True
    for x in [-.18,0.,.18]:
        for y in [-.18,0.,.18]:
            origin = (x-direction[0]*10,1.28+y-direction[1]*10,-10.)
            filled = filled and any(hits(origin,direction,*face) for face in pane_faces)
    check(filled, 'Light panes physically fill Void center along '+str(direction))

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
        check(max(p[1] for p in posed) < 3.1, 'Animation height budget ' + clip['name'])

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
for name in ['atlas_base.png', 'atlas_orm.png', 'atlas_normal.png', 'atlas_emission.png']:
    synthesis_rows = list(png_rgb(FOLDER/name))
    void_rows = list(png_rgb(ROOT/'campaign'/'void'/name))
    check(synthesis_rows[:768] == void_rows[:768], 'Void frame texture slots retained byte-for-byte: ' + name)
for name in ['atlas_base.png', 'atlas_emission.png']:
    # The bottom atlas row is reserved for the four Light pane/leading slots;
    # the retained Void frame deliberately keeps its original violet family.
    check(all(row[x] >= row[x+1] >= row[x+2] for y,row in enumerate(png_rgb(FOLDER/name)) if y >= 768 for x in range(0,len(row),3)), 'Every Light pane texel stays gold/white: ' + name)
print(f'SYNTHESIS_EXPORTS: {CHECKS} checks, 0 failures / {len(vertices)} vertices / {triangles} triangles / {len(joints)} joints')
