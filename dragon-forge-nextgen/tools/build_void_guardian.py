#!/usr/bin/env python3
"""Offline Null/Void authoring: hollow crystal frame, metres/Y-up/-Z-front.

The empty diamond is geometry: no filled faces, core sphere, flesh, limbs or feet.
Faceted tetrahedral corner chips and inset inner-edge glow keep the crystal legible
in both native renderers. Python/numpy/Pillow are authoring-only dependencies.
"""
from pathlib import Path
import hashlib
import json
import math
import numpy as np
from PIL import Image
import build_art as art

OUT = Path(__file__).resolve().parents[1] / 'campaign' / 'void'
PALETTE = [(23, 20, 38), (38, 32, 60), (60, 47, 86), (87, 69, 118),
           (117, 95, 149), (149, 126, 180), (62, 64, 106), (91, 98, 146),
           (161, 119, 239), (202, 177, 255), (115, 206, 225), (194, 238, 248),
           (31, 29, 49), (51, 44, 71), (73, 58, 97), (218, 216, 235)]
DURATIONS = {'idle': 1.8, 'walk': .8, 'claw': .29, 'breath': .56,
             'wall': .42, 'burst': .64, 'guard': 1.2, 'hurt': .24, 'defeat': .9}
WINDUPS = {'claw': .11, 'breath': .26, 'wall': .18, 'burst': .30}
CENTER = np.array([0., 1.28, 0.])
CORNERS = {'Top': np.array([0., 2.29, 0.]),
           'Right': np.array([.87, 1.28, 0.]),
           'Bottom': np.array([0., .48, 0.]),
           'Left': np.array([-.87, 1.28, 0.])}


def paint():
    rng = np.random.default_rng(57229)
    maps = {k: Image.new('RGB', (1024, 1024)) for k in ['base', 'orm', 'normal', 'emission']}
    y, x = np.mgrid[:256, :256]
    for i, color in enumerate(PALETTE):
        # Cut mineral facets, shallow etched grain and occasional worn edge chips.
        # No cracks/glow painted into the empty center: it has no surfaces at all.
        cut = np.sin(x * .061 + y * .023)
        facets = np.floor((x + y * .46) / 37) % 3
        grain = rng.normal(0, 1, (256, 256))
        etch = np.abs(np.sin(x * .028 - y * .052)) < .032
        edge = np.minimum.reduce([x, y, 255 - x, 255 - y])
        chips = (edge < 12) & (rng.random((256, 256)) > .84)
        h = .55 + facets * .008 + cut * .006 - etch * .025 + grain * .001
        base = np.clip(np.array(color)[None, None, :] *
                       (.86 + facets[:, :, None] * .065) + chips[:, :, None] * 19, 0, 255).astype('uint8')
        orm = np.empty_like(base)
        orm[:, :, 0] = np.clip(250 - etch * 13, 0, 255)
        orm[:, :, 1] = np.clip(103 + facets * 13 + etch * 22 + grain * 2, 0, 255)
        orm[:, :, 2] = 74 if i < 8 or i >= 12 else 16
        gy, gx = np.gradient(h)
        normals = np.dstack([-gx * 3.2, -gy * 3.2, np.ones_like(h)])
        normals /= np.linalg.norm(normals, axis=2)[:, :, None]
        normal = np.clip((normals * .5 + .5) * 255, 0, 255).astype('uint8')
        emission = np.zeros_like(base)
        if i in [8, 9, 10, 11]:
            emission[:] = np.array(color, dtype='uint8')
        at = (i % 4 * 256, i // 4 * 256)
        for key, data in [('base', base), ('orm', orm), ('normal', normal), ('emission', emission)]:
            maps[key].paste(Image.fromarray(data), at)
    OUT.mkdir(parents=True, exist_ok=True)
    for key, picture in maps.items():
        picture.save(OUT / f'atlas_{key}.png')


def beam(mesh, start, end, radius, slot, bone, bevel=True):
    """Flat-shaded cut crystal strut; every face has its own UVs and normals."""
    start, end = np.asarray(start, float), np.asarray(end, float)
    axis = art.unit(end - start)
    ref = [0., 0., 1.] if abs(axis[2]) < .9 else [1., 0., 0.]
    right = art.unit(np.cross(axis, ref))
    up = art.unit(np.cross(axis, right))
    sections = [(0., .68), (.12, 1.), (.88, 1.), (1., .68)] if bevel else [(0., 1.), (1., 1.)]
    rings = [[start + (end - start) * fraction +
              (right * math.cos(j * math.pi / 2) + up * math.sin(j * math.pi / 2)) * radius * width
              for j in range(4)] for fraction, width in sections]
    vertices, faces, uvs = [], [], []
    for k in range(len(rings) - 1):
        for j in range(4):
            n = len(vertices)
            vertices.extend([rings[k][j], rings[k][(j + 1) % 4], rings[k + 1][(j + 1) % 4], rings[k + 1][j]])
            faces.extend([[n, n + 1, n + 2], [n, n + 2, n + 3]])
            uvs.extend([[0, 0], [1, 0], [1, 1], [0, 1]])
    for k in [0, len(rings) - 1]:
        n = len(vertices)
        vertices.extend(rings[k]); uvs.extend([[0, .5], [.5, 1], [1, .5], [.5, 0]])
        faces.extend([[n, n + 2, n + 1], [n, n + 3, n + 2]] if k == 0 else
                     [[n, n + 1, n + 2], [n, n + 2, n + 3]])
    mesh.part(vertices, faces, uvs, slot, bone)


def tetra(mesh, at, size, slot, bone):
    at = np.asarray(at, float)
    points = [at + np.array(p) * size for p in [(0, 1, 0), (-.8, -.5, -.46), (.8, -.5, -.46), (0, -.5, .92)]]
    vertices, faces, uvs = [], [], []
    for face in [(0, 1, 2), (0, 2, 3), (0, 3, 1), (1, 3, 2)]:
        n = len(vertices); vertices.extend([points[i] for i in face])
        faces.append([n, n + 1, n + 2]); uvs.extend([[.5, 0], [0, 1], [1, 1]])
    mesh.part(vertices, faces, uvs, slot, bone)


def guardian():
    mesh = art.Mesh('void_guardian')
    root = mesh.bone('Root', (0, 0, 0))
    frame = mesh.bone('Frame', CENTER, root)
    bones = {name: mesh.bone('Corner.' + name, at, frame) for name, at in CORNERS.items()}
    # Emitter follows the leading rim, preserving a useful spell origin without
    # adding a head, mouth or bright core that fills the signature aperture.
    mesh.bone('Emitter', (.87, 1.28, -.32), bones['Right'])
    names = list(CORNERS)
    for j, name in enumerate(names):
        other = names[(j + 1) % 4]
        a, b = CORNERS[name], CORNERS[other]
        middle = (a + b) * .5
        for depth in [-.21, .21]:
            z = np.array([0., 0., depth])
            # Small mid-edge break keeps the frame segmented when corners move.
            for p, q, owner in [(a, middle - (b - a) * .018, name),
                                (b, middle + (b - a) * .018, other)]:
                beam(mesh, p + z, q + z, .085 if depth < 0 else .063, 2 + j % 3, bones[owner])
                inward = art.unit(CENTER - (p + q) * .5) * .090
                beam(mesh, p + z + inward, q + z + inward, .016, 9 if depth < 0 else 8, bones[owner], False)
        beam(mesh, a + [0, 0, -.23], a + [0, 0, .23], .091, 6, bones[name])
        # Angular mineral growth belongs to the rim only, never the empty core.
        outward = art.unit(a - CENTER)
        for depth in [-.22, .22]:
            tetra(mesh, a + outward * .038 + [0, 0, depth], .125, 5 if depth < 0 else 3, bones[name])
        tetra(mesh, a + outward * .19, .085, 10, bones[name])
    # Four disconnected, hollow satellite rhombi reinforce the empty diamond
    # motif; none is placed inside the central aperture or touches the floor.
    satellites = [(-1.20, 1.30, .04), (1.20, 1.30, .04), (-.45, 2.30, .10), (.45, 2.30, .10)]
    for i, at in enumerate(satellites):
        bone = mesh.bone('Shard.' + str(i), at, frame)
        vertices = [np.array(at) + p for p in [np.array([0, .14, 0]), np.array([.075, 0, 0]), np.array([0, -.14, 0]), np.array([-.075, 0, 0])]]
        for j in range(4):
            beam(mesh, vertices[j], vertices[(j + 1) % 4], .022, 8 if i % 2 else 10, bone, False)
    for clip, duration in DURATIONS.items():
        times = list(np.linspace(0, duration, max(4, int(duration * 30) + 1)))
        if clip in WINDUPS:
            windup = WINDUPS[clip]
            times = sorted({round(float(t), 7) for t in times + [windup, max(0, windup - .025), min(duration, windup + .03)]})
        poses = []
        for t in times:
            q = float(t / duration); wave = math.sin(q * math.pi); beat = math.sin(q * math.tau)
            pose = {'Frame': ([0, .065 * beat, .018 * beat], [0, .048 * beat, 0])}
            spread, twist = 0., 0.
            if clip == 'walk':
                pose['Frame'] = ([.10, .09 * beat, -.025 * beat], [0, .045 * beat, -.04])
            elif clip in WINDUPS:
                contact = WINDUPS[clip] / duration
                # Windup/impact/recovery are authored around the exact combat
                # times; the animation never dispatches a hit or changes state.
                envelope = q / contact if q <= contact else (1 - q) / (1 - contact)
                if clip == 'claw':
                    pose['Frame'] = ([0, -.20 * envelope, -.12 * envelope], [0, 0, -.20 * envelope])
                    pose['Corner.Right'] = ([0, 0, -.10 * envelope], [.10 * envelope, 0, -.16 * envelope])
                elif clip == 'breath':
                    spread = .16 * envelope
                    pose['Frame'] = ([-.12 * envelope, 0, 0], [0, .07 * envelope, .08 * envelope])
                elif clip == 'wall':
                    spread = .09 * envelope
                    pose['Frame'] = ([0, .12 * envelope, 0], [0, .04 * envelope, 0])
                else:
                    spread = -.08 * envelope
                    twist = .16 * envelope
                    pose['Frame'] = ([0, -.24 * envelope, 0], [0, .10 * envelope, 0])
            elif clip == 'guard':
                # A stable open-frame pose, safe to hold throughout Reflect.
                pose['Frame'] = ([0, .04, 0], [0, .025, 0]); spread = .075
            elif clip == 'hurt':
                pose['Frame'] = ([.13 * wave, 0, .13 * wave], [0, 0, .10 * wave])
            elif clip == 'defeat':
                pose['Frame'] = ([0, .28 * q, .20 * q], [0, -.10 * q, 0]); spread = .23 * q; twist = .65 * q
            for j, (name, at) in enumerate(CORNERS.items()):
                if 'Corner.' + name in pose:
                    continue
                radial = art.unit(at - CENTER)
                pose['Corner.' + name] = ([0, twist * (-1 if j % 2 else 1), twist * .4], (radial * spread).tolist())
            for i in range(4):
                drift = math.sin(q * math.tau + i * math.pi / 2)
                pose['Shard.' + str(i)] = ([0, .20 * drift, .06 * drift], [0, .028 * drift, 0])
            poses.append(pose)
        mesh.animations[clip] = (times, poses)
    return mesh


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    art.OUT = OUT
    paint()
    entry = guardian().export()
    files = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
             for p in sorted(OUT.iterdir()) if p.suffix in ['.glb', '.png']}
    manifest = {'source': 'tools/build_void_guardian.py', 'guardian': 'Null',
                'design': {'plan': 'hollow crystal tetra', 'silhouette': 'empty-diamond',
                           'notes': 'Frame only, inner glow, no flesh.',
                           'aperture_center': CENTER.tolist(), 'aperture_radius': .27,
                           'muzzle_joint': 'Emitter', 'grounded': False},
                'asset': entry, 'clip_durations': DURATIONS, 'action_windups': WINDUPS,
                'files': files}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(entry, indent=2))
