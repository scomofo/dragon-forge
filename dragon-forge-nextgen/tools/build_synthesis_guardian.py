#!/usr/bin/env python3
"""Offline Prism/Synthesis: the real Void frame filled with real Light panes.

This composes the established authoring recipes, not a tenth animal silhouette.
Void's original frame vertices/joints stay intact. Four separately skinned hard
opalescent Light windows sit inside the frame and retain visible gold leading.
Metres, Y-up, -Z-front. Python/numpy/Pillow are authoring-only dependencies.
"""
from pathlib import Path
import hashlib
import json
import math
import numpy as np
from PIL import Image
import build_art as art
import build_void_guardian as void
import build_light_guardian as light

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'campaign' / 'synthesis'
PALETTE = void.PALETTE[:8] + [void.PALETTE[8], (255, 249, 222), (245, 212, 139),
                            (250, 245, 225), (255, 252, 235), (237, 206, 127),
                            (211, 167, 67), (255, 230, 163)]
DURATIONS = {'idle': 1.8, 'walk': .8, 'claw': .32, 'breath': .56,
             'wall': .60, 'burst': .76, 'guard': 1.2, 'hurt': .24, 'defeat': .9}
WINDUPS = {'claw': .12, 'breath': .26, 'wall': .28, 'burst': .36}


def paint():
    rng = np.random.default_rng(79237)
    maps = {name: Image.new('RGB', (1024, 1024)) for name in ['base', 'orm', 'normal', 'emission']}
    y, x = np.mgrid[:256, :256]
    edge = np.minimum.reduce([x, y, 255 - x, 255 - y])
    for slot, color in enumerate(PALETTE):
        glass = slot in [12, 13]
        metal = slot in [14, 15]
        grain = rng.normal(0, 1, (256, 256))
        mineral = np.sin(x*.061+y*.023)
        facets = np.floor((x+y*.46)/37)%3
        ripple = np.sin(x*.043+np.sin(y*.028))*np.sin(y*.038)
        etch = np.abs(np.sin(x*.028-y*.052)) < .032
        wear = (edge < 12) & (rng.random((256, 256)) > .84)
        h = .55 + (ripple*.009 if glass else facets*.008+mineral*.006) - etch*.018+grain*.001
        shade = (.94+ripple*.025 if glass else .86+facets*.065) + grain*.001
        base = np.clip(np.array(color)[None, None, :]*shade[:, :, None]+wear[:, :, None]*12, 0, 255).astype('uint8')
        orm = np.empty_like(base)
        orm[:, :, 0] = np.clip(250-etch*14, 0, 255)
        orm[:, :, 1] = np.clip((72 if glass else 115 if metal else 105)+wear*25+grain*2, 0, 255)
        orm[:, :, 2] = 10 if glass else 204 if metal else 74
        gy, gx = np.gradient(h)
        n = np.dstack([-gx*3, -gy*3, np.ones_like(h)])
        n /= np.linalg.norm(n, axis=2)[:, :, None]
        normal = np.clip((n*.5+.5)*255, 0, 255).astype('uint8')
        emission = np.zeros_like(base)
        if slot in [8, 9, 10, 11]:
            emission[:] = np.array(color, dtype='uint8')
        elif glass:
            emission[:] = (np.array(color)*(.34 if slot == 12 else .17)).astype('uint8')
        at = (slot%4*256, slot//4*256)
        for name, data in [('base', base), ('orm', orm), ('normal', normal), ('emission', emission)]:
            maps[name].paste(Image.fromarray(data), at)
    OUT.mkdir(parents=True, exist_ok=True)
    for name, picture in maps.items():
        picture.save(OUT/f'atlas_{name}.png')


class LightPanePalette:
    """Use Light's actual rigid-window geometry with dedicated atlas slots."""
    def __init__(self, target): self.target = target
    def part(self, vertices, faces, uv, slot, bone=0, weights=None, tint=1.):
        self.target.part(vertices, faces, uv, {3: 14, 4: 15}.get(slot, slot), bone, weights, tint)


def guardian():
    mesh = void.guardian()
    mesh.name = 'synthesis_guardian'
    mesh.animations.clear()
    frame = next(i for i, entry in enumerate(mesh.bones) if entry[0] == 'Frame')
    center = void.CENTER.copy(); center[2] = -.055
    top = np.array([0., 2.105, -.055])
    right = np.array([.705, 1.28, -.055])
    bottom = np.array([0., .655, -.055])
    left = np.array([-.705, 1.28, -.055])
    corners = [top, right, bottom, left]
    for i in range(4):
        # Shared center with narrow leading seams; the four triangle interiors
        # fill the hole rather than drawing a dark or emissive texture over it.
        points = np.array([center, corners[i], corners[(i+1)%4]])
        at = points.mean(axis=0)
        bone = mesh.bone('Pane.'+str(i), at, frame)
        light.pane(LightPanePalette(mesh), points, 12 if i%2 == 0 else 13, bone,
                   thickness=.050, border=.032, mullion=False)
    for clip, duration in DURATIONS.items():
        times = list(np.linspace(0, duration, max(4, int(duration*30)+1)))
        if clip in WINDUPS:
            contact = WINDUPS[clip]
            times = sorted({round(float(t), 7) for t in times+[contact, max(0, contact-.025), min(duration, contact+.03)]})
        poses = []
        for time in times:
            q = float(time/duration); beat = math.sin(q*math.tau); wave = math.sin(q*math.pi)
            pose = {'Frame': ([0, .055*beat, .015*beat], [0, .035*beat, 0])}
            spread, twist, pane_turn = 0., 0., 0.
            if clip == 'walk':
                pose['Frame'] = ([.08, .07*beat, -.018*beat], [0, .035*beat, -.035])
            elif clip in WINDUPS:
                contact = WINDUPS[clip]/duration
                envelope = q/contact if q <= contact else (1-q)/(1-contact)
                if clip == 'claw':
                    pose['Frame'] = ([0, -.16*envelope, -.09*envelope], [0, 0, -.16*envelope])
                    pose['Corner.Right'] = ([0, 0, -.06*envelope], [.035*envelope, 0, -.09*envelope])
                elif clip == 'breath':
                    # Void Rift presents the frame and four panes as one device.
                    spread = .045*envelope
                    pose['Frame'] = ([-.08*envelope, .07*envelope, 0], [0, .045*envelope, .055*envelope])
                elif clip == 'wall':
                    # Radiant Beam aligns the glass; animation does not hit.
                    pose['Frame'] = ([0, 0, 0], [0, .035*envelope, -.095*envelope])
                    spread = .025*envelope
                    pane_turn = .04*envelope
                else:
                    # Recompile gently articulates the panes back into a single
                    # window. Skinning stays rigid; health is owned by combat.
                    pose['Frame'] = ([0, .12*envelope, 0], [0, .07*envelope, 0])
                    spread = .065*envelope; pane_turn = .19*envelope
            elif clip == 'guard':
                pose['Frame'] = ([0, .04, 0], [0, .025, 0]); spread = .025
            elif clip == 'hurt':
                pose['Frame'] = ([.11*wave, 0, .10*wave], [0, 0, .07*wave])
            elif clip == 'defeat':
                pose['Frame'] = ([0, .22*q, .18*q], [0, -.07*q, 0]); spread = .17*q; twist = .38*q; pane_turn = .30*q
            for j, (name, at) in enumerate(void.CORNERS.items()):
                if 'Corner.'+name not in pose:
                    radial = art.unit(at-void.CENTER)
                    pose['Corner.'+name] = ([0, twist*(-1 if j%2 else 1), twist*.25], (radial*spread).tolist())
            for i in range(4):
                drift = math.sin(q*math.tau+i*math.pi/2)
                pose['Shard.'+str(i)] = ([0, .15*drift, .045*drift], [0, .020*drift, 0])
                pose['Pane.'+str(i)] = ([pane_turn*.3*(-1 if i<2 else 1), pane_turn*(-1 if i%2 else 1), 0], [0, 0, -.025*abs(pane_turn)])
            poses.append(pose)
        mesh.animations[clip] = (times, poses)
    return mesh


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True); art.OUT = OUT
    paint(); asset = guardian().export()
    files = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.suffix in ['.glb', '.png']}
    reference = ROOT/'campaign'/'void'/'void_guardian.glb'
    manifest = {'source': 'tools/build_synthesis_guardian.py', 'guardian': 'Prism',
                'design': {'plan': 'void frame filled with light panes', 'silhouette': 'diamond-frame-pane-fill',
                           'notes': 'Must read as void + light combined, not a tenth animal.',
                           'muzzle_joint': 'Emitter', 'grounded': False, 'foot_planting': False,
                           'pane_count': 4, 'rigid_panes': True, 'pane_palette': 'gold-white',
                           'pane_color_slots': [12, 13, 14, 15], 'center': void.CENTER.tolist()},
                'frame_reference': {'file': 'campaign/void/void_guardian.glb',
                                    'sha256': hashlib.sha256(reference.read_bytes()).hexdigest(),
                                    'source': 'tools/build_void_guardian.py', 'vertices': 2032, 'triangles': 992, 'bones': 11},
                'pane_source': 'tools/build_light_guardian.py',
                'asset': asset, 'clip_durations': DURATIONS, 'action_windups': WINDUPS, 'files': files}
    (OUT/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print(json.dumps(asset, indent=2))
