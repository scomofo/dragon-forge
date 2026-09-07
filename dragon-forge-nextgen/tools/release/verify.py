#!/usr/bin/env python3
"""Verify the exact ZIP and run its own executable, without an editor or source tree."""
from __future__ import annotations
import argparse,hashlib,json,os,platform,plistlib,re,stat,struct,subprocess,zipfile
from pathlib import Path
ERROR=re.compile(r'SCRIPT ERROR|Parse Error|^ERROR:|^FAIL ',re.M)

def main()->None:
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('package',type=Path)
    ap.add_argument('output',type=Path)
    ap.add_argument('--render',action='store_true')
    args=ap.parse_args()
    out=args.output.resolve()
    if out.exists():raise SystemExit('Use a new verification directory.')
    out.mkdir(parents=True)
    files=out/'game';files.mkdir()
    with zipfile.ZipFile(args.package) as z:
        for item in z.infolist():
            p=Path(item.filename)
            if p.is_absolute() or '..' in p.parts or stat.S_ISLNK(item.external_attr>>16):raise ValueError('Unsafe ZIP entry')
            z.extract(item,files)
            if os.name!='nt' and item.external_attr>>16:
                (files/p).chmod((item.external_attr>>16)&0o777)
    hashes=json.loads((files/'FILES-SHA256.json').read_text())
    for name,expected in hashes.items():
        if hashlib.sha256((files/name).read_bytes()).hexdigest()!=expected:raise RuntimeError('Mismatch: '+name)
    name=platform.system()
    executable=files/({'Linux':'DragonForge.x86_64','Windows':'DragonForge.exe','Darwin':'DragonForge.app/Contents/MacOS/DragonForge'}[name])
    if name=='Darwin':
        with (files/'DragonForge.app/Contents/Info.plist').open('rb') as f: app_info=plistlib.load(f)
        executable=files/'DragonForge.app/Contents/MacOS'/app_info['CFBundleExecutable']
        arch=subprocess.check_output(['lipo','-archs',str(executable)],text=True)
        if not {'x86_64','arm64'}.issubset(set(arch.split())):raise RuntimeError('Not universal')
        subprocess.run(['codesign','--verify','--deep','--strict','--verbose=2',str(files/'DragonForge.app')],check=True)
    elif name=='Windows':
        data=executable.read_bytes();offset=struct.unpack_from('<I',data,0x3c)[0]
        if data[:2]!=b'MZ' or data[offset:offset+4]!=b'PE\0\0' or struct.unpack_from('<H',data,offset+4)[0]!=0x8664:raise RuntimeError('Invalid Windows x64 executable')
    else:
        data=executable.read_bytes()[:20]
        if data[:4]!=b'\x7fELF' or struct.unpack_from('<H',data,18)[0]!=62:raise RuntimeError('Invalid Linux x64 executable')
    # CI/local checks use isolated userdata. Never touch a developer's actual campaign.
    home=out/'isolated-user';home.mkdir()
    env={**os.environ,'HOME':str(home),'XDG_DATA_HOME':str(home/'data'),
         'XDG_CONFIG_HOME':str(home/'config'),'APPDATA':str(home/'AppData/Roaming'),
         'LOCALAPPDATA':str(home/'AppData/Local'),'USERPROFILE':str(home),'GODOT_SILENCE_ROOT_WARNING':'1'}
    for label,extra in [('normal-start',['--quit-after','8']),('package-check',['--script','res://release/export_smoke.gd','--','--ci-release-check','--expect-export','--report-dir='+str(out/'report')])]:
        log=out/(label+'.log')
        command=[str(executable),'--headless','--log-file',str(log),*extra]
        p=subprocess.run(command,cwd=files,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180)
        text=p.stdout+(log.read_text(errors='replace') if log.exists() else '')
        (out/(label+'-console.log')).write_text(p.stdout,encoding='utf-8')
        if p.returncode or ERROR.search(text):raise RuntimeError(f'{label} failed: {p.returncode}\n{text[-6000:]}')
        if label=='package-check' and not re.search(r'EXPORT_SMOKE: \d+ checks, 0 failures',text):raise RuntimeError('Missing completion marker')
        print(text[-1000:])
    if args.render:
        log=out/'render.log'
        cmd=[str(executable),'--rendering-method','gl_compatibility','--audio-driver','Dummy','--log-file',str(log),
             '--script','res://release/export_smoke.gd','--','--ci-release-check','--expect-export','--report-dir='+str(out/'render')]
        p=subprocess.run(['xvfb-run','-a',*cmd],cwd=files,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=240)
        text=p.stdout+log.read_text(errors='replace')
        (out/'render-console.log').write_text(p.stdout)
        if p.returncode or ERROR.search(text) or not re.search(r'EXPORT_SMOKE: \d+ checks, 0 failures',text):raise RuntimeError('Exported renderer check failed\n'+text[-6000:])
    result={'package':args.package.name,'sha256':hashlib.sha256(args.package.read_bytes()).hexdigest(),'os':name,
            'machine':platform.machine(),'verified_files':len(hashes),'render_test':args.render,
            'note':'Own executable startup + prepared-state pack checks. Not target-GPU performance or human-playthrough certification.'}
    (out/'VERIFIED.json').write_text(json.dumps(result,indent=2))
    print('NATIVE_PACKAGE: verified '+args.package.name)

if __name__=='__main__':main()
