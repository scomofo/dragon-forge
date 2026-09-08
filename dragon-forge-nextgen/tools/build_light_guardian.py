#!/usr/bin/env python3
"""Offline Lumen/Light authoring: gold/white stained-glass winged biped.

Metres, +Y up, -Z forward. Cut opalescent panes have real thickness and rigid
skinning; separate worn gold borders articulate at mechanical joints. No purple
palette, procedural runtime meshes, external models or foot-planting claim.
"""
from pathlib import Path
import hashlib
import json
import math
import numpy as np
from PIL import Image
import build_art as art

OUT = Path(__file__).resolve().parents[1] / 'campaign' / 'light'
PALETTE = [(70, 55, 25), (111, 82, 32), (163, 122, 47), (211, 167, 67),
           (240, 205, 119), (255, 230, 163), (215, 210, 190), (244, 239, 218),
           (255, 252, 235), (237, 206, 127), (248, 226, 171), (255, 250, 229),
           (91, 76, 45), (135, 111, 57), (188, 153, 83), (226, 220, 202)]
DURATIONS = {'idle': 1.8, 'walk': .8, 'claw': .32, 'breath': .56,
             'wall': .68, 'burst': .72, 'guard': 1., 'hurt': .24, 'defeat': .9}
WINDUPS = {'claw': .12, 'breath': .26, 'wall': .32, 'burst': .40}


def paint():
    rng = np.random.default_rng(68231)
    maps = {name: Image.new('RGB', (1024, 1024)) for name in ['base', 'orm', 'normal', 'emission']}
    y, x = np.mgrid[:256, :256]
    edge = np.minimum.reduce([x, y, 255 - x, 255 - y])
    for slot, color in enumerate(PALETTE):
        grain = rng.normal(0, 1, (256, 256))
        glass = slot in [6, 7, 8, 9, 10, 11, 15]
        ripple = np.sin(x * .043 + np.sin(y * .028)) * np.sin(y * .038)
        cuts = (np.abs(np.sin(x * .022 - y * .013)) < .019)
        wear = (edge < 14) & (rng.random((256, 256)) > .78)
        h = .55 + ripple * (.009 if glass else .003) - cuts * .017 + grain * .001
        # One scalar modulates R/G/B together: every albedo texel remains in the
        # canonical gold/white family, even in worn and etched regions.
        shade = .94 + ripple * .025 + grain * .001 - cuts * .018
        base = np.clip(np.array(color)[None, None, :] * shade[:, :, None] + wear[:, :, None] * 10, 0, 255).astype('uint8')
        orm = np.empty_like(base)
        orm[:, :, 0] = np.clip(250 - cuts * 16, 0, 255)
        orm[:, :, 1] = np.clip((72 if glass else 115) + wear * 34 + grain * 2, 0, 255)
        orm[:, :, 2] = 10 if glass else 204
        gy, gx = np.gradient(h)
        n = np.dstack([-gx * 3, -gy * 3, np.ones_like(h)])
        n /= np.linalg.norm(n, axis=2)[:, :, None]
        normal = np.clip((n * .5 + .5) * 255, 0, 255).astype('uint8')
        emission = np.zeros_like(base)
        if glass:
            emission[:] = (np.array(color) * (.34 if slot in [8, 11] else .17)).astype('uint8')
        at = (slot % 4 * 256, slot // 4 * 256)
        for name, data in [('base', base), ('orm', orm), ('normal', normal), ('emission', emission)]:
            maps[name].paste(Image.fromarray(data), at)
    OUT.mkdir(parents=True, exist_ok=True)
    for name, picture in maps.items():
        picture.save(OUT / f'atlas_{name}.png')


def beam(mesh, start, end, radius, slot, bone):
    """Flat-faced rectangular gold leading strip with planar UVs."""
    start, end = np.asarray(start, float), np.asarray(end, float)
    axis = art.unit(end - start)
    ref = [0., 0., 1.] if abs(axis[2]) < .9 else [1., 0., 0.]
    right = art.unit(np.cross(axis, ref)); up = art.unit(np.cross(axis, right))
    rings = [[at + (right * math.cos(j * math.pi / 2) + up * math.sin(j * math.pi / 2)) * radius for j in range(4)] for at in [start, end]]
    vertices, faces, uv = [], [], []
    for j in range(4):
        n = len(vertices)
        vertices.extend([rings[0][j], rings[0][(j + 1) % 4], rings[1][(j + 1) % 4], rings[1][j]])
        faces.extend([[n, n + 1, n + 2], [n, n + 2, n + 3]])
        uv.extend([[0, 0], [1, 0], [1, 1], [0, 1]])
    for k in [0, 1]:
        n = len(vertices); vertices.extend(rings[k]); uv.extend([[0, .5], [.5, 1], [1, .5], [.5, 0]])
        faces.extend([[n, n + 2, n + 1], [n, n + 3, n + 2]] if k == 0 else [[n, n + 1, n + 2], [n, n + 2, n + 3]])
    mesh.part(vertices, faces, uv, slot, bone)


def pane(mesh, points, slot, bone, thickness=.045, border=.025, mullion=True):
    """Filled hard pane with front/back faces, thickness, and a gold perimeter.

    All vertices use one joint; individual panes rotate rather than stretch.
    No alpha blend or refraction dependency is needed by Compatibility.
    """
    points = np.asarray(points, float)
    if sum(np.cross(points[i], points[(i + 1) % len(points)])[2] for i in range(len(points))) > 0:
        points = points[::-1]
    center = points.mean(axis=0)
    lo, hi = points[:, :2].min(axis=0), points[:, :2].max(axis=0)
    def uv(p): return ((p[:2] - lo) / np.maximum(hi - lo, .001)).tolist()
    vertices, faces, uvs = [], [], []
    for direction in [-1, 1]:
        z = np.array([0., 0., direction * thickness / 2])
        for j in range(len(points)):
            n = len(vertices)
            triangle = [center + z, points[j] + z, points[(j + 1) % len(points)] + z]
            if direction > 0: triangle = triangle[::-1]
            vertices.extend(triangle); faces.append([n, n + 1, n + 2]); uvs.extend([uv(p) for p in triangle])
    for j in range(len(points)):
        a, b = points[j], points[(j + 1) % len(points)]
        z = np.array([0., 0., thickness / 2]); n = len(vertices)
        vertices.extend([a - z, a + z, b + z, b - z]); uvs.extend([[0, 0], [1, 0], [1, 1], [0, 1]])
        faces.extend([[n, n + 1, n + 2], [n, n + 2, n + 3]])
        beam(mesh, a, b, border, 3, bone)
    mesh.part(vertices, faces, uvs, slot, bone)
    if mullion:
        # A real gold divider splits the opalescent window into facets.
        beam(mesh, points[0] + [0, 0, -.032], points[len(points) // 2] + [0, 0, -.032], border * .55, 4, bone)


def guardian():
    mesh = art.Mesh('light_guardian')
    root = mesh.bone('Root', (0, 0, 0))
    hips = mesh.bone('Pelvis', (0, 1.10, .08), root)
    chest = mesh.bone('Chest', (0, 1.70, .03), hips)
    neck = mesh.bone('Neck', (0, 2.00, -.06), chest)
    head = mesh.bone('Head', (0, 2.22, -.23), neck)
    jaw = mesh.bone('Jaw', (0, 2.10, -.40), head)
    mesh.bone('Emitter', (0, 2.18, -.78), head)
    # Mechanical body with an opalescent breast window and real gold leading.
    mesh.tube([(0, 1.01, .09), (0, 1.24, .06), (0, 1.37, .04)], [.23, .26, .21], [.18, .20, .18], slot=1, bone=hips, sides=8)
    mesh.tube([(0, 1.31, .04), (0, 1.65, .03), (0, 1.93, .03)], [.21, .36, .28], [.19, .23, .19], slot=2, bone=chest, sides=8)
    pane(mesh, [(-.23, 1.78, -.205), (0, 1.95, -.205), (.23, 1.78, -.205), (.19, 1.48, -.205), (0, 1.36, -.205), (-.19, 1.48, -.205)], 8, chest, border=.023)
    pane(mesh, [(-.16, 1.22, -.13), (0, 1.31, -.13), (.16, 1.22, -.13), (0, 1.00, -.13)], 9, hips, border=.02)
    mesh.tube([(0, 1.91, -.01), (0, 2.06, -.12)], [.13, .115], slot=3, bone=neck, sides=8)
    # A faceted dragon mask, separate jaw, eye panes and a white/gold crest.
    mesh.tube([(0, 2.23, -.12), (0, 2.26, -.35), (0, 2.21, -.60), (0, 2.18, -.73)], [.19, .20, .125, .075], [.16, .17, .085, .05], slot=7, bone=head, sides=8)
    mesh.tube([(0, 2.08, -.35), (0, 2.075, -.58), (0, 2.12, -.71)], [.135, .115, .055], [.045, .035, .015], slot=3, bone=jaw, sides=7)
    for sign, side in [(-1, 'L'), (1, 'R')]:
        mesh.plate((sign * .184, 2.29, -.42), .13, .18, normal=(sign * .8, .05, -.4), slot=0, bone=head, depth=.017)
        mesh.plate((sign * .194, 2.30, -.43), .062, .125, normal=(sign * .8, .05, -.4), slot=11, bone=head, depth=.014)
        mesh.tube([(sign * .12, 2.37, -.18), (sign * .18, 2.57, -.08), (sign * .22, 2.65, .02)], [.068, .04, .004], slot=5, bone=head, sides=6)
        # Two arms, with visible gaps at rigid shoulder/elbow articulations.
        arm = mesh.bone('Arm.' + side, (sign * .34, 1.84, .01), chest)
        fore = mesh.bone('Forearm.' + side, (sign * .52, 1.42, -.08), arm)
        hand = mesh.bone('Hand.' + side, (sign * .54, 1.13, -.23), fore)
        mesh.tube([(sign * .33, 1.83, .01), (sign * .49, 1.48, -.06)], [.14, .105], slot=3, bone=arm, sides=8)
        mesh.plate((sign * .37, 1.78, -.13), .31, .41, normal=(sign * .3, 0, -1), slot=7, bone=arm, depth=.05)
        mesh.tube([(sign * .52, 1.41, -.08), (sign * .54, 1.18, -.20)], [.105, .125], slot=2, bone=fore, sides=8)
        mesh.plate((sign * .55, 1.32, -.235), .24, .30, normal=(sign * .2, 0, -1), slot=10, bone=fore, depth=.05)
        mesh.box((sign * .54, 1.105, -.23), (.20, .15, .19), slot=3, bone=hand, bevel=.025)
        for digit in [-1, 0, 1]:
            x = sign * .54 + digit * .058
            mesh.tube([(x, 1.10, -.28), (x, 1.03, -.38)], [.034, .008], slot=5, bone=hand, sides=5)
        # Two segmented legs and actual boot-like feet hover clear of the deck.
        thigh = mesh.bone('Thigh.' + side, (sign * .18, 1.10, .08), hips)
        shin = mesh.bone('Shin.' + side, (sign * .24, .69, .09), thigh)
        foot = mesh.bone('Foot.' + side, (sign * .24, .31, -.015), shin)
        mesh.tube([(sign * .18, 1.075, .075), (sign * .24, .74, .075)], [.15, .12], slot=7, bone=thigh, sides=8)
        mesh.plate((sign * .24, .70, -.02), .25, .22, normal=(0, 0, -1), slot=4, bone=shin, depth=.045)
        mesh.tube([(sign * .24, .65, .07), (sign * .24, .35, -.01)], [.105, .085], slot=2, bone=shin, sides=8)
        mesh.plate((sign * .24, .49, -.05), .18, .32, normal=(0, 0, -1), slot=8, bone=shin, depth=.025)
        mesh.box((sign * .24, .27, -.13), (.21, .105, .38), slot=5, bone=foot, bevel=.018)
        # Three separate rigid windows form each upward-pointing wing chevron.
        wing = mesh.bone('Wing.' + side, (sign * .36, 1.94, .27), chest)
        middle = mesh.bone('WingMid.' + side, (sign * .83, 2.47, .25), wing)
        tip = mesh.bone('WingTip.' + side, (sign * 1.29, 2.73, .22), middle)
        def points(p): return [(sign * x * .86, y, z) for x, y, z in p]
        pane(mesh, points([(.42, 1.94, .28), (.92, 2.51, .28), (1.02, 2.0, .28), (.72, 1.59, .28)]), 9, wing, border=.032)
        pane(mesh, points([(.98, 2.47, .25), (1.48, 2.72, .25), (1.46, 2.12, .25), (1.15, 1.70, .25), (1.03, 2.00, .25)]), 7, middle, border=.032)
        pane(mesh, points([(1.53, 2.73, .22), (2.04, 2.92, .22), (1.81, 2.36, .22), (1.47, 1.93, .22)]), 11, tip, border=.031)
        beam(mesh, (sign * .34, 1.92, .27), (sign * .80, 2.47, .27), .043, 3, wing)
        beam(mesh, (sign * .83, 2.47, .25), (sign * 1.26, 2.70, .25), .043, 4, middle)
    for clip, duration in DURATIONS.items():
        times = list(np.linspace(0, duration, max(4, int(duration * 30) + 1)))
        if clip in WINDUPS:
            contact = WINDUPS[clip]
            times = sorted({round(float(t), 7) for t in times + [contact, max(0, contact - .025), min(duration, contact + .03)]})
        poses = []
        for time in times:
            q = float(time / duration); beat = math.sin(q * math.tau); wave = math.sin(q * math.pi)
            pose = {'Root': ([0, 0, 0], [0, .026 * beat if clip in ['idle', 'walk'] else 0, 0]),
                    'Chest': ([.014 * beat, 0, 0], [0, 0, 0])}
            wing_open, wing_back = .025 * beat, .035 * beat
            if clip == 'walk':
                # Deliberate hovering glide; feet do not claim floor locking.
                pose['Chest'] = ([.065, 0, 0], [0, 0, 0])
                for sign, side in [(-1, 'L'), (1, 'R')]:
                    pose['Thigh.' + side] = ([.08 * beat * sign, 0, 0], [0, 0, 0])
                    pose['Shin.' + side] = ([.05, 0, 0], [0, 0, 0])
                    pose['Arm.' + side] = ([.09, 0, sign * .035], [0, 0, 0])
                wing_open = .035 * beat; wing_back = .065
            elif clip in WINDUPS:
                contact = WINDUPS[clip] / duration
                envelope = q / contact if q <= contact else (1 - q) / (1 - contact)
                if clip == 'claw':
                    pose['Chest'] = ([0, -.18 * envelope, 0], [0, 0, -.055 * envelope])
                    pose['Arm.R'] = ([-.75 * envelope, 0, -.18 * envelope], [0, 0, 0])
                    pose['Forearm.R'] = ([-.24 * envelope, 0, 0], [0, 0, 0])
                elif clip == 'breath':
                    pose['Neck'] = ([-.11 * envelope, 0, 0], [0, 0, -.03 * envelope])
                    pose['Head'] = ([.08 * envelope, 0, 0], [0, 0, -.04 * envelope])
                    pose['Jaw'] = ([.32 * envelope, 0, 0], [0, 0, 0])
                    wing_back = -.10 * envelope
                elif clip == 'wall':
                    # Solar Flare: radial, open-wing release; no forward bite.
                    wing_open = -.13 * envelope; wing_back = -.12 * envelope
                    pose['Chest'] = ([-.09 * envelope, 0, 0], [0, .04 * envelope, 0])
                    for sign, side in [(-1, 'L'), (1, 'R')]:
                        pose['Arm.' + side] = ([0, 0, sign * .73 * envelope], [0, 0, 0])
                        pose['Forearm.' + side] = ([-.10 * envelope, 0, 0], [0, 0, 0])
                else:
                    # Restoration: hands gather inward over the breast window;
                    # the closed-wing pose is visual, never a healing callback.
                    wing_open = .09 * envelope; wing_back = .27 * envelope
                    pose['Head'] = ([.12 * envelope, 0, 0], [0, 0, 0])
                    for sign, side in [(-1, 'L'), (1, 'R')]:
                        pose['Arm.' + side] = ([-.28 * envelope, 0, -sign * .35 * envelope], [0, 0, 0])
                        pose['Forearm.' + side] = ([-.84 * envelope, 0, 0], [0, 0, 0])
            elif clip == 'guard':
                wing_back = .16
                for sign, side in [(-1, 'L'), (1, 'R')]:
                    pose['Arm.' + side] = ([-.34, 0, sign * .14], [0, 0, 0])
                    pose['Forearm.' + side] = ([-.60, 0, 0], [0, 0, 0])
            elif clip == 'hurt':
                pose['Chest'] = ([.10 * wave, 0, .09 * wave], [0, 0, .05 * wave]); wing_back = .11 * wave
            elif clip == 'defeat':
                pose['Root'] = ([0, 0, -.23 * q], [0, -.03 * q, 0])
                pose['Chest'] = ([.32 * q, 0, 0], [0, -.05 * q, 0])
                pose['Head'] = ([.26 * q, 0, 0], [0, 0, 0]); wing_back = .40 * q; wing_open = .10 * q
            for sign, side in [(-1, 'L'), (1, 'R')]:
                pose['Wing.' + side] = ([0, sign * wing_back, sign * wing_open], [0, 0, 0])
                pose['WingMid.' + side] = ([0, sign * wing_back * .32, sign * wing_open * .3], [0, 0, 0])
                pose['WingTip.' + side] = ([0, sign * wing_back * .22, sign * wing_open * .2], [0, 0, 0])
            poses.append(pose)
        mesh.animations[clip] = (times, poses)
    return mesh


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True); art.OUT = OUT
    paint(); asset = guardian().export()
    files = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.suffix in ['.glb', '.png']}
    manifest = {'source': 'tools/build_light_guardian.py', 'guardian': 'Lumen',
                'design': {'plan': 'stained-glass winged biped', 'silhouette': 'wing-chevron-panes',
                           'notes': 'Hard panes. Gold/white only — no storm-violet.', 'palette': 'gold-white',
                           'muzzle_joint': 'Emitter', 'grounded': False, 'foot_planting': False,
                           'wing_panels': 6, 'rigid_panes': True},
                'asset': asset, 'clip_durations': DURATIONS, 'action_windups': WINDUPS, 'files': files}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(asset, indent=2))
