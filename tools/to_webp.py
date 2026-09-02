#!/usr/bin/env python3
"""Convert public/assets PNG sprites to same-dimension WebP (~8× smaller)."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'public' / 'assets'

def main():
    converted = 0
    bytes_in = bytes_out = 0
    for png in sorted(ROOT.rglob('*.png')):
        webp = png.with_suffix('.webp')
        im = Image.open(png)
        bytes_in += png.stat().st_size
        if im.mode not in ('RGB', 'RGBA'):
            im = im.convert('RGBA') if 'A' in im.getbands() else im.convert('RGB')
        im.save(webp, format='WEBP', quality=78, method=4)
        bytes_out += webp.stat().st_size
        converted += 1
    print(f'converted={converted} png_mb={bytes_in/1e6:.1f} webp_mb={bytes_out/1e6:.1f}')

if __name__ == '__main__':
    main()
