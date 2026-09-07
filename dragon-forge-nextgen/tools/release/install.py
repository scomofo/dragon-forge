#!/usr/bin/env python3
"""Fetch official, pinned Godot 4.6.3 engine/templates; verify release asset digests."""
from __future__ import annotations
import hashlib,json,os,subprocess,zipfile
from pathlib import Path
VERSION='4.6.3-stable'
ROOT=Path(os.environ['RUNNER_TEMP'])/'dragonforge-engine'
ROOT.mkdir(parents=True,exist_ok=True)
release=json.loads(subprocess.check_output(['curl','--fail','--location','--retry','3',
    '--max-time','60',f'https://api.github.com/repos/godotengine/godot-builds/releases/tags/{VERSION}'],text=True))
records=[]
for name in [f'Godot_v{VERSION}_linux.x86_64.zip',f'Godot_v{VERSION}_export_templates.tpz']:
    asset=next(a for a in release['assets'] if a['name']==name)
    expected=asset.get('digest','')
    if not expected.startswith('sha256:'): raise RuntimeError('Missing upstream SHA-256; refusing unchecked download')
    file=ROOT/name
    subprocess.run(['curl','--fail','--location','--retry','3','--max-time','900',asset['browser_download_url'],'-o',str(file)],check=True)
    h=hashlib.sha256()
    with file.open('rb') as f:
        for data in iter(lambda:f.read(1024*1024),b''):h.update(data)
    if 'sha256:'+h.hexdigest()!=expected:raise RuntimeError('Asset checksum mismatch')
    records.append({'file':name,'url':asset['browser_download_url'],'sha256':h.hexdigest(),'bytes':file.stat().st_size})
    with zipfile.ZipFile(file) as z:
        if name.endswith('.zip'):
            engine=ROOT/'godot';engine.write_bytes(z.read(f'Godot_v{VERSION}_linux.x86_64'));engine.chmod(0o755)
        else:
            dest=Path.home()/'.local/share/godot/export_templates/4.6.3.stable';dest.mkdir(parents=True,exist_ok=True)
            for entry in z.infolist():
                path=Path(entry.filename)
                if path.parent.as_posix()!='templates':continue
                n=path.name
                if n in ('version.txt','macos.zip','linux_debug.x86_64','linux_release.x86_64') or (n.startswith('windows_') and 'x86_64' in n):
                    (dest/n).write_bytes(z.read(entry))
            if (dest/'version.txt').read_text().strip()!='4.6.3.stable':raise RuntimeError('Template version mismatch')
            for n in ['macos.zip','linux_release.x86_64','windows_release_x86_64.exe']:
                if not (dest/n).exists():raise RuntimeError('Missing desktop template '+n)
(ROOT/'download-provenance.json').write_text(json.dumps(records,indent=2))
with open(os.environ['GITHUB_ENV'],'a') as f:f.write(f'GODOT={ROOT / "godot"}\n')
print('TEMPLATES: verified official desktop exports installed')
