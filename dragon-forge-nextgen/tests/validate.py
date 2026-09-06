#!/usr/bin/env python3
"""Static packaging checks only; run.gd is the authoritative native test suite."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
missing = []
for source in root.rglob('*'):
    if source.suffix not in {'.gd', '.tscn', '.godot'}:
        continue
    for resource in re.findall(r'(?:preload\(|path=|run/main_scene=)"res://([^"\n]+)"', source.read_text()):
        if not (root / resource).is_file():
            missing.append((str(source.relative_to(root)), resource))
assert not missing, f'Missing resources: {missing}'
config = (root / 'project.godot').read_text()
assert '[autoload]' not in config, 'Must not load existing runtime autoloads'
assert 'dragon-forge-nextgen-prototype' in config, 'Separate save namespace required'
assert (root / 'tests/run.gd').is_file()
print('Static packaging checks passed (not a GDScript compilation test).')
