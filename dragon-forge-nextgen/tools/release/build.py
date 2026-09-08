#!/usr/bin/env python3
"""Build unsigned/ad-hoc standalone playtests with an installed Godot 4.6.3.
Never changes existing gameplay files or publishes a release. Output must be new.
"""
from __future__ import annotations
import argparse, hashlib, json, os, plistlib, re, shutil, subprocess, zipfile
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[2]
ERROR = re.compile(r'SCRIPT ERROR|Parse Error|^ERROR:|^FAIL ', re.M)
TARGETS = {'Linux': ('Linux Playtest', 'DragonForge.x86_64'),
           'Windows': ('Windows Playtest', 'DragonForge.exe'),
           'macOS': ('macOS Playtest', 'DragonForge.app')}

def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''): h.update(chunk)
    return h.hexdigest()

def run(args: list[str], log: Path, timeout: int = 240) -> None:
    log.parent.mkdir(parents=True, exist_ok=True)
    p = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                       text=True, timeout=timeout, env={**os.environ, 'GODOT_SILENCE_ROOT_WARNING':'1'})
    log.write_text(p.stdout, encoding='utf-8')
    print(p.stdout[-2500:], flush=True)
    if p.returncode or ERROR.search(p.stdout):
        raise RuntimeError(f'Command failed ({p.returncode}); see {log}')

def archive(folder: Path, destination: Path) -> None:
    with zipfile.ZipFile(destination,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for p in sorted(folder.rglob('*')):
            if p.is_symlink(): raise RuntimeError(f'Unexpected package symlink: {p}')
            z.write(p, p.relative_to(folder).as_posix() + ('/' if p.is_dir() else ''))

def main() -> None:
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--godot',required=True)
    ap.add_argument('--output',required=True,type=Path)
    ap.add_argument('--commit',required=True)
    args=ap.parse_args()
    out=args.output.resolve()
    if out.exists() or PROJECT == out or PROJECT in out.parents:
        raise SystemExit('Use a new output directory outside the project.')
    out.mkdir(parents=True)
    logs=out/'evidence';logs.mkdir()
    version=subprocess.check_output([args.godot,'--version'],text=True).strip()
    if not version.startswith('4.6.3.stable.'): raise SystemExit(f'Expected 4.6.3 stable, got {version}')
    assets=sorted('res://'+p.relative_to(PROJECT).as_posix() for p in PROJECT.rglob('*')
                  if p.suffix in ('.glb','.png','.mp3','.wav') and '.godot' not in p.parts and 'artifacts' not in p.parts)
    if len(assets)!=83: raise SystemExit('Expected 33 models, 40 maps and 10 recordings; review inventory before changing this gate.')
    info={'source_commit':args.commit,'engine':version,'assets':assets,
          'build_kind':'standalone-playtest','signing':{'Windows':'unsigned','macOS':'ad-hoc, not notarized'}}
    (PROJECT/'release/build_info.json').write_text(json.dumps(info,indent=2)+'\n')
    run([args.godot,'--headless','--path',str(PROJECT),'--editor','--import'],logs/'import.log')
    legal=out/'legal'
    run([args.godot,'--headless','--path',str(PROJECT),'--script','res://tools/release/licenses.gd','--',str(legal)],logs/'licenses.log')
    for target,(preset,name) in TARGETS.items():
        folder=out/target;folder.mkdir()
        run([args.godot,'--headless','--path',str(PROJECT),'--export-release',preset,str(folder/name)],logs/f'export-{target}.log',600)
        if not (folder/name).exists(): raise RuntimeError(f'Missing {target} executable')
        shutil.copytree(legal,folder/'licenses')
        shutil.copy2(PROJECT/'campaign/audio/manifest.json',folder/'licenses/SOUNDTRACK-PROVENANCE.json')
        (folder/'BUILD_INFO.json').write_text(json.dumps(info,indent=2)+'\n')
        (folder/'README-FIRST.txt').write_text(
            'DRAGON FORGE - RECONNECTION / SYNTHESIS RECOMPILE\n'
            'Standalone playtest: the Godot editor, Python and export templates are NOT needed to play.\n'
            'Extract the complete ZIP; keep the executable beside its PCK and bundled libraries.\n'
            f'Open {name}. Choose Continue for an existing campaign under the same OS account.\n'
            'Back up your previous saves before testing an update. No save is bundled here.\n'
            'Controls: WASD move, mouse aim, 1-4 techniques, Space dodge, Shift guard, E interact,\n'
            'Q repair, Tab swap selected guardians, M map, P guardians, N journal, Esc pause.\n'
            'Audio Settings: title screen or Pause. Original soundtrack included.\n'
            'Compatibility launcher uses OpenGL if Forward+ cannot start on your graphics device.\n'
            'This is not a signed commercial release: Windows is unsigned and macOS is ad-hoc signed,\n'
            'not Apple-notarized. Your OS may show a first-run security warning.\n'
            'Only approve this specific app after checking its source and integrity; do not disable system protections.\n'
            'macOS: after attempting to open the app, use System Settings > Privacy & Security > Open Anyway,\n'
            'where offered. Notarized distribution still requires the developer signing credentials.\n'
            'These packages receive automated startup/resource checks; human balance and target-GPU performance\n'
            'are not certified. Source: https://github.com/scomofo/dragon-forge\n',encoding='utf-8')
        if target=='Windows':
            (folder/'Play-Compatibility.cmd').write_text('@echo off\r\ncd /d "%~dp0"\r\n"%~dp0DragonForge.exe" --rendering-method gl_compatibility %*\r\n',newline='')
        else:
            binary='./DragonForge.x86_64'
            if target=='macOS':
                with (folder/name/'Contents/Info.plist').open('rb') as f: app_info=plistlib.load(f)
                binary='./DragonForge.app/Contents/MacOS/'+app_info['CFBundleExecutable']
            launch=folder/('Play-Compatibility.command' if target=='macOS' else 'Play-Compatibility.sh')
            launch.write_text('#!/bin/sh\nset -eu\ncd "$(dirname "$0")"\nexec "'+binary+'" --rendering-method gl_compatibility "$@"\n')
            launch.chmod(0o755)
        checksums={p.relative_to(folder).as_posix():digest(p) for p in folder.rglob('*') if p.is_file()}
        (folder/'FILES-SHA256.json').write_text(json.dumps(checksums,indent=2)+'\n')
        archive(folder,out/f'Dragon_Forge_Standalone_{target}.zip')
    packages={p.name:digest(p) for p in out.glob('*.zip')}
    (out/'SHA256SUMS.txt').write_text(''.join(f'{v}  {k}\n' for k,v in packages.items()))
    print('EXPORT_BUILD: three packages created; native runtime verification still required.')

if __name__=='__main__': main()
