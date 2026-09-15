"""Offline anatomical detail and physically paired creature texture channels.

Original parametric art. These functions produce the committed skinned GLBs;
there is no runtime geometry generation or dependency on this Python module.
"""
from pathlib import Path
import math
import hashlib
import io
import PIL
import numpy as np
from PIL import Image


def provenance(source):
    source = Path(source)
    return {'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
            'creature_detail_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            'compiler_sha256': hashlib.sha256(source.with_name('build_art.py').read_bytes()).hexdigest(),
            'authoring_versions': {'numpy': np.__version__, 'Pillow': PIL.__version__}}


def paint_hide(out: Path, palette, *, prefix='atlas', skin=(0, 1), horn=(2,),
               membrane=(), glow=(3, 8), seed=91526):
    """Shared UV layout; fine overlapping scales, keratin and stretched membrane.

    Height, occlusion and roughness use the same masks. No directional light is
    baked into base color. Slots 14/15 are a non-emissive iris and dark mouth/pupil.
    """
    cell = 512
    y, x = np.mgrid[:cell, :cell].astype(np.float32)
    u, v = x / cell, y / cell
    maps = [np.zeros((cell * 4, cell * 4, 3), np.uint8) for _ in range(4)]
    for slot, color in enumerate(palette):
        rng = np.random.default_rng(seed + slot)
        def cloud(n):
            tile = Image.fromarray((rng.random((n, n)) * 255).astype(np.uint8))
            return np.asarray(tile.resize((cell, cell), Image.Resampling.BICUBIC), np.float32) / 255
        broad, fine = cloud(8), cloud(55)
        height = np.full_like(u, .5)
        rough = .66 + .12 * broad
        ao = np.ones_like(u)
        rgb = np.asarray(color)[None, None, :] * (.78 + .27 * broad + .06 * fine)[:, :, None]
        if slot in skin:
            # Staggered, gently warped rows read as small imbricated scales rather
            # than the former large, evenly colored polygon cracks.
            row = v * 35 + .22 * np.sin(u * 19)
            row_id = np.floor(row)
            col = u * 31 + (row_id % 2) * .5 + .16 * np.sin(v * 22)
            a, b = (col % 1 - .5) * 2, (row % 1 - .5) * 2
            radius = np.maximum(abs(a) * .86 + abs(b) * .32, abs(b) * .96)
            dome = np.clip(1 - radius, 0, 1)
            seam = np.clip((radius - .94) * 12, 0, 1)
            lip = np.exp(-((radius - .87) * 21) ** 2)
            pigment = .045 * np.sin(np.floor(col) * 17.17 + row_id * 9.31)
            rgb *= (1 + pigment + dome * .06 - seam * .22)[:, :, None]
            rgb += (broad - .5)[:, :, None] * np.array([15, 12, 8])
            height += dome * .032 - seam * .016 + lip * .003 + (fine - .5) * .010
            ao -= seam * .19
            rough = .57 + broad * .17 + seam * .12 - lip * .09
        elif slot in horn:
            grain = np.sin(u * 182 + np.sin(v * 14) * .8)
            growth = np.sin(v * 88 + u * 4)
            # Pigmented roots, translucent-looking lighter tips; non-metallic.
            rgb *= (.64 + .36 * v + .025 * grain)[:, :, None]
            height += grain * .010 + growth * .003
            rough = .40 + .19 * broad + (1 - v) * .13
        elif slot in membrane:
            folds = np.sin(u * 96 + np.sin(v * 7) * 4)
            veins = np.exp(-np.abs(np.sin(u * 29 - v * 8 + np.sin(v * 9))) * 65)
            rgb *= (.87 + broad * .20 - veins * .22 + folds * .015)[:, :, None]
            height += veins * .025 + folds * .004 + (fine - .5) * .006
            rough = .60 + .11 * broad
        elif slot == 14:
            fibers = np.sin(u * 187 + v * 19) * np.sin(v * 103)
            rgb *= (1 + fibers * .17)[:, :, None]
            rough = np.full_like(u, .23)
        elif slot == 15:
            rough = np.full_like(u, .36)
        else:
            height += (fine - .5) * .016
        dy, dx = np.gradient(height)
        # OpenGL normal map: +Y in tangent space is opposite image row direction.
        normal = np.stack([-dx * 7, dy * 7, np.ones_like(u)], axis=2)
        normal /= np.linalg.norm(normal, axis=2)[:, :, None]
        emission = rgb * .72 if slot in glow else np.zeros_like(rgb)
        sl = (slice(slot // 4 * cell, (slot // 4 + 1) * cell),
              slice(slot % 4 * cell, (slot % 4 + 1) * cell))
        maps[0][sl] = np.clip(rgb, 0, 255).astype(np.uint8)
        maps[1][sl] = (np.clip(np.stack([ao, rough, np.zeros_like(u)], axis=2), 0, 1) * 255).astype(np.uint8)
        maps[2][sl] = np.clip((normal * .5 + .5) * 255, 0, 255).astype(np.uint8)
        maps[3][sl] = np.clip(emission, 0, 255).astype(np.uint8)
    out.mkdir(parents=True, exist_ok=True)
    for name, pixels in zip(['base', 'orm', 'normal', 'emission'], maps):
        # Encode fully before publishing. Some mounted authoring filesystems
        # truncate incremental encoder writes; never hash a partial PNG as final.
        encoded = io.BytesIO()
        Image.fromarray(pixels).save(encoded, format='PNG', compress_level=9)
        data = encoded.getvalue()
        Image.open(io.BytesIO(data)).verify()
        target = out / f'{prefix}_{name}.png'
        temporary = target.with_suffix('.png.tmp')
        temporary.write_bytes(data)
        if temporary.read_bytes() != data:
            raise IOError(f'Incomplete texture write: {temporary}')
        temporary.replace(target)


def eye(m, at, normal, size, bone, hide=0):
    """Recessed almond socket, convex colored iris, vertical pupil and upper lid."""
    p, n = np.array(at), np.array(normal, float)
    n /= np.linalg.norm(n)
    up = np.array([0., 1., 0.])
    up -= n * np.dot(n, up)
    up /= np.linalg.norm(up)
    right = np.cross(up, n)
    almond = [(-.50, 0), (-.25, -.33), (.20, -.28), (.50, .06), (.19, .34), (-.23, .32)]
    m.plate(p, size * 2.5, size * 1.55, n, up, 15, bone, depth=.011, outline=almond)
    center = p + n * .020
    m.tube([center - n * .008, center, center + n * .016],
           [size * .45, size * .84, .003], [size * .29, size * .57, .003],
           slot=14, bone=bone, sides=12)
    m.plate(center + n * .018, size * .23, size * 1.15, n, up, 15, bone, depth=.005,
            outline=[(0,-.50),(.43,-.24),(.48,.21),(0,.50),(-.48,.21),(-.43,-.24)])
    # Eyelid follows the skull, not a luminous floating badge.
    m.tube([p - right * size * 1.25 + up * size * .12,
            p - right * size * .50 + up * size * .65 + n * .009,
            p + right * size * .48 + up * size * .57 + n * .009,
            p + right * size * 1.30 + up * size * .07],
           [size * .22, size * .29, size * .26, .007], slot=hide, bone=bone, sides=10)


def teeth(m, head, jaw, *, back, front, y, width, count=8, scale=1., slot=2):
    """Tapered interlocking teeth follow their own upper/lower jaw bindings."""
    for side in [-1, 1]:
        for i in range(count):
            t = i / max(1, count - 1)
            z = back + (front - back) * t
            x = side * width * (1 - .28 * t)
            length = scale * (.060 + .031 * math.sin(t * math.pi))
            r = scale * .025
            m.tube([(x, y, z), (x * .98, y - length * .65, z - .009),
                    (x * .96, y - length, z - .023)], [r, r * .6, .002],
                   slot=slot, bone=head, sides=7)
            if i < count - 1:
                z += (front - back) / count * .5
                m.tube([(x * .94, y - .10 * scale, z),
                        (x * .93, y - .06 * scale, z - .012),
                        (x * .91, y - .029 * scale, z - .025)],
                       [r * .8, r * .48, .002], slot=slot, bone=jaw, sides=7)


def scute_row(m, points, widths, bone, *, slot=1, normal=(0, 1, 0), up=(0, 0, -1), depth=.025):
    for i, (p, w) in enumerate(zip(points, widths)):
        m.plate(p, w, w * 1.35, normal, up, slot, bone,
                depth=depth, tint=.87 + .11 * math.sin(i * 2.3) ** 2)


def membrane(m, hub, tips, bone_weights, *, slot=6, thickness=.008, scallop=.20):
    """Closed cambered membrane with concave trailing edges; weighted per vertex.

    Each lobe has a real front, back and perimeter. No alpha sorting or backface
    culling dependency; thin surfaces remain visible in both Godot renderers.
    """
    hub = np.asarray(hub, float)
    tips = np.asarray(tips, float)
    for a, b in zip(tips[:-1], tips[1:]):
        normal = np.cross(a - hub, b - hub)
        normal /= max(np.linalg.norm(normal), 1e-8)
        vertices, uv, weights, faces = [], [], [], []
        radial, across = 6, 8
        per_side = 1 + radial * (across + 1)
        for sign in [-1, 1]:
            vertices.append(hub + normal * thickness * sign * .5)
            uv.append([.5, .03])
            weights.append(bone_weights(hub))
            for row in range(1, radial + 1):
                r = row / radial
                for j in range(across + 1):
                    t = j / across
                    edge = a * (1 - t) + b * t
                    edge += (hub - (a + b) * .5) * scallop * math.sin(math.pi * t)
                    p = hub * (1 - r) + edge * r
                    p += normal * (.045 * math.sin(math.pi * r) * math.sin(math.pi * t) + thickness * sign * .5)
                    vertices.append(p)
                    uv.append([.5 + (t - .5) * r * .92, .03 + r * .94])
                    weights.append(bone_weights(p))
        front = []
        for j in range(across):
            front.append([0, 1 + j, 2 + j])
        for row in range(radial - 1):
            for j in range(across):
                c = 1 + row * (across + 1) + j
                d = c + across + 1
                front.extend([[c, d, c + 1], [c + 1, d, d + 1]])
        faces.extend(front)
        faces.extend([[c + per_side, b + per_side, a + per_side] for a, b, c in front])
        # Duplicate the narrow edge strip with its own UVs (nonzero UV area).
        boundary = [0] + [1 + r * (across + 1) for r in range(radial)]
        boundary += [1 + (radial - 1) * (across + 1) + j for j in range(1, across + 1)]
        boundary += [1 + r * (across + 1) + across for r in range(radial - 2, -1, -1)] + [0]
        for i, (a_idx, b_idx) in enumerate(zip(boundary[:-1], boundary[1:])):
            start = len(vertices)
            for idx, tex in [(a_idx,(0,0)),(b_idx,(1,0)),(a_idx+per_side,(0,.1)),(b_idx+per_side,(1,.1))]:
                vertices.append(vertices[idx]); uv.append(tex); weights.append(weights[idx])
            faces.extend([[start,start+2,start+1],[start+1,start+2,start+3]])
        m.part(vertices, faces, uv, slot, weights=weights)


def bat_wing(m, side, wing, tip):
    s = side
    hub = np.array([s * 1.13, 1.64, -.34])
    tips = [[s * 2.10, 1.67, -.47], [s * 1.94, 1.49, .33],
            [s * 1.40, 1.34, .91], [s * .73, 1.29, .95], [s * .27, 1.30, .54]]
    def weights(p):
        t = float(np.clip((abs(p[0]) - .76) / .70, 0, 1))
        t = t * t * (3 - 2 * t)
        return [(wing, 1 - t), (tip, t)]
    membrane(m, hub, tips, weights)
    m.tube([(s*.25,1.47,-.05),(s*.70,1.67,-.22),hub], [.13,.095,.072],
           slot=0, sides=16, weights=[weights(p) for p in [(s*.25,1.47,-.05),(s*.70,1.67,-.22),hub]])
    for i, end in enumerate(tips):
        end = np.array(end)
        mid = hub * .43 + end * .57 + np.array([0, .055, 0])
        path = [hub, mid, end]
        m.tube(path, [.047, .030, .006] if i == 0 else [.029,.018,.004],
               slot=2 if i == 0 else 0, sides=10, weights=[weights(p) for p in path])
    # Wrist thumb/claw, with the same two-bone transition as its membrane.
    path = [hub, hub + [s*.02,.16,-.12], hub + [s*.11,.22,-.24]]
    m.tube(path, [.048,.031,.002], slot=2, sides=10, weights=[weights(p) for p in path])
