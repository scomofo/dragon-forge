#!/usr/bin/env python3
"""Execute the reviewed Venom integrator with its project root corrected."""
from pathlib import Path
src = Path(__file__).with_name('integrate_venom_runtime.py')
code = src.read_text()
old = "ROOT = Path(__file__).resolve().parents[2]"
new = "ROOT = Path(__file__).resolve().parents[1]"
assert code.count(old) == 1, "unexpected Venom integrator root declaration"
namespace = {"__file__": str(src), "__name__": "__main__"}
exec(compile(code.replace(old, new, 1), str(src), "exec"), namespace)
