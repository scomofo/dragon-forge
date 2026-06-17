# ADR-0005: `public/assets/` is the Browser Build Asset Source of Truth; Per-Build Art Trees

## Status

Accepted

## Date

2026-06-16

## Last Verified

2026-06-16

## Decision Makers

Reverse-documented from implementation

## Summary

Dragon Forge ships two builds (React/Vite browser, Godot 4.6) that share art but
have incompatible deployment and import requirements. This ADR records the decision
to maintain **three parallel art trees** — `public/assets/` as the tracked source of
truth for the browser build, `dragon-forge-godot/assets/` as the tracked Godot copy
(carrying its `.import` UID sidecars), and a gitignored repo-root `assets/` used only
as art-generator scratch — with all browser runtime references routed through an
`assetUrl()` base-prefix helper and policed by a manifest existence test.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React 18 + Vite (browser build) |
| **Domain** | Core (asset pipeline / build) |
| **Knowledge Risk** | LOW — Vite `base` + `import.meta.env.BASE_URL` and `public/` static-copy semantics are stable, well-documented, and in training data |
| **References Consulted** | `vite.config.js`, `src/utils.js`, `src/sprites.js`, `src/assetManifest.test.js`, `.gitignore`, `CLAUDE.md` (Cross-build notes) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None for the browser build. The Godot half (`.import` sidecar travel) is governed by Godot 4.6 import behavior and is verified by the build opening cleanly with no re-import. |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Any system that references runtime art by URL (battle VFX strips, dragon/egg/NPC/boss sprites, arenas, music) |
| **Blocks** | None |
| **Ordering Note** | Foundational pipeline decision — predates and underpins content-data modules (`gameData`, `singularityBosses`, `sprites`) that emit asset URLs. |

## Context

### Problem Statement

The game is shipped as two parallel implementations of the same simulation that
deliberately reuse the same art. The browser build is deployed to a sub-path
(`/dragon-forge/` on GitHub Pages), so every asset URL must be base-prefixed at
runtime or it 404s in production. The Godot build cannot consume the same files
loosely: Godot 4.6 generates a `.import` sidecar (with a stable resource UID) next
to every imported texture, and those sidecars must travel with the source images or
the project re-imports and breaks UID references. Meanwhile, the art-generation
tooling (the `tools/asset_gen/*` Python/shell pipelines that bake VFX strips and the
fal hand-art pipeline) needs a place to write raw output without polluting either
shippable tree.

Three forces collide: **deploy-path correctness** (browser), **import-sidecar
integrity** (Godot), and **generator scratch isolation** (tooling). A single shared
asset directory cannot satisfy all three.

### Current State

The decision is fully implemented and shipped:

- **Browser source of truth — `public/assets/`** (143 files tracked). Vite copies
  `public/` verbatim to the deploy base at build time. Subtrees in use:
  `dragons/`, `eggs/`, `npc/`, `vfx/`, `arenas/`, `backgrounds/`, `decoration/`,
  `map/`, `music/`, plus `felix_pixel.jpg`.
- **Godot copy — `dragon-forge-godot/assets/`**, tracked as its own tree
  *including* 63 `.import` UID sidecar files (e.g. `ice.png.import`) alongside the
  `.png` sources. It also carries Godot-only subtrees such as `icons/`.
- **Root `assets/` — gitignored** (`.gitignore` line 14: `/assets/`). Present on
  disk as art-generator scratch but contributes 0 tracked files.

Runtime URL resolution is centralized in `assetUrl()` (`src/utils.js`):

```js
const BASE = import.meta.env.BASE_URL || '/';
export function assetUrl(path) {
  if (path.startsWith(BASE)) return path;        // already prefixed
  return BASE + path.replace(/^\//, '');         // strip leading slash, prepend base
}
```

`assetUrl` is consumed across 11 modules — `sprites.js`, `gameData.js`,
`singularityBosses.js`, `soundEngine.js`, and the `*Screen.jsx` shells
(Campaign, Shop, Fusion, Forge, Hatchery). VFX strips are declared compactly via
the `strip()` factory in `sprites.js`, which calls `assetUrl(`/assets/vfx/vfx_<move>.png`)`.

A guard test, `src/assetManifest.test.js`, collects every runtime asset URL from
the content tables (dragons, egg sheets, NPCs, all Singularity bosses + phases, and
`VFX_FRAMES`), maps each back to a `public/` path by stripping the `/dragon-forge/`
base, and asserts `existsSync` on every one — failing the suite if any referenced
file is missing from `public/assets/`.

### Constraints

- **Deploy sub-path**: browser build is served under `base: '/dragon-forge/'`
  (`vite.config.js`); absolute `/assets/...` strings would resolve to the domain
  root in production and 404.
- **Godot import model**: Godot 4.6 `.import` sidecars carry resource UIDs and must
  be committed next to their source textures; they cannot be regenerated identically
  on another machine without churn.
- **Tooling**: art generators (`tools/asset_gen/make_vfx_strips.py`,
  `gen_vfx_sheets.sh`) write raw output that must not be mistaken for shippable art.
- **Single-developer workflow**: Scott maintains both builds solo; the policy must
  be enforceable by automated test rather than code review discipline.

### Requirements

- Browser asset references must resolve correctly under the production deploy base
  with zero per-call-site awareness of the base path.
- A referenced asset that is absent from the shippable browser tree must fail CI
  (the test run), not ship a 404.
- Godot can import and reference the same conceptual art with its UID sidecars
  intact and version-controlled.
- Raw generator output is isolated from both shippable trees.

## Decision

Maintain **three parallel asset trees**, each with a single, explicit role, and
funnel all browser runtime references through one base-aware helper:

1. **`public/assets/` — tracked browser source of truth.** Anything referenced via
   `assetUrl('/assets/...')` MUST exist here or it 404s in production. Vite serves
   `public/` at the deploy base, so this tree *is* the shipped browser asset set.
2. **`dragon-forge-godot/assets/` — tracked Godot copy.** Kept as its own tree so
   the Godot `.import` UID sidecars travel with their sources. When a sprite is used
   by both builds it is placed in both `public/assets/` and
   `dragon-forge-godot/assets/`.
3. **Repo-root `assets/` — gitignored generator scratch.** Art generators may write
   here freely; nothing here ships. New web art must be copied into `public/assets/`
   to be shipped.

All browser runtime URLs are produced by `assetUrl(path)`, which prepends
`import.meta.env.BASE_URL` (driven by Vite's `base`) exactly once. Content/data
modules store `/assets/...`-rooted paths and call `assetUrl` at the boundary.

The contract is enforced at test time by `assetManifest.test.js`, which proves every
content-table asset URL resolves to a real file under `public/`.

### Architecture

```
                 art generators (tools/asset_gen/*)
                              │  write raw output
                              ▼
            ┌─────────────────────────────────────┐
            │  /assets/   (repo root, GITIGNORED)  │  scratch only — never ships
            └─────────────────────────────────────┘
                              │  hand-copy shippable art
              ┌───────────────┴────────────────┐
              ▼                                 ▼
   ┌──────────────────────┐         ┌────────────────────────────────┐
   │  public/assets/      │         │  dragon-forge-godot/assets/    │
   │  (TRACKED — browser  │         │  (TRACKED — Godot copy,        │
   │   source of truth)   │         │   .png + .import UID sidecars) │
   └──────────┬───────────┘         └──────────────┬─────────────────┘
              │ vite copy at build (base=/dragon-forge/)   │ Godot import
              ▼                                            ▼
   ┌──────────────────────┐                    ┌────────────────────────┐
   │  dist/assets/...     │                    │  Godot resource cache  │
   └──────────┬───────────┘                    └────────────────────────┘
              │
   content tables store "/assets/..." paths
              │  assetUrl(path)  →  BASE + path  (BASE = /dragon-forge/)
              ▼
   runtime <img src="/dragon-forge/assets/...">  (no 404)

   assetManifest.test.js  ──► asserts every content URL existsSync under public/
```

### Key Interfaces

```js
// src/utils.js — the single base-resolution boundary
const BASE = import.meta.env.BASE_URL || '/';   // '/dragon-forge/' in this build
function assetUrl(path: string): string;         // idempotent; prefixes once

// src/sprites.js — content declares root-relative paths, resolves at decl time
const strip = (move, frames = 4) => ({
  strip: { src: assetUrl(`/assets/vfx/vfx_${move}.png`), frames },
});

// src/assetManifest.test.js — the enforced contract
function publicPath(assetUrl: string): string;   // strips /dragon-forge/ + leading /
//   it('references files that exist under public assets'): missing == []
```

**Authoring contract for content/runtime code:**
- Store and pass `/assets/...`-rooted paths in data modules.
- Resolve them with `assetUrl()` at the point a real URL is needed (data-module
  declaration time or screen render); never hand-concatenate the base.
- Any new asset URL added to a content table must have a corresponding file in
  `public/assets/`, or `assetManifest.test.js` fails.
- A sprite used by both builds is added to **both** `public/assets/` and
  `dragon-forge-godot/assets/` (the Godot copy with its `.import` sidecar).

### Implementation Guidelines

- Keep `assetUrl` idempotent — the early `path.startsWith(BASE)` return guards
  against double-prefixing when a value is passed through twice.
- Never write a literal `/dragon-forge/...` or a bare `/assets/...` into an
  `<img src>` / `background-image` — go through `assetUrl`.
- When adding a new content category to the manifest test, extend
  `collectAssetUrls()` so the new URLs are covered by the existence assertion.
- Godot `.import` sidecars are tracked deliberately; do not gitignore them and do
  not regenerate them gratuitously (they churn UIDs).

## Alternatives Considered

### Alternative 1: Single shared `assets/` tree consumed by both builds

- **Description**: One tracked `assets/` directory at the repo root; both Vite and
  Godot read from it; Vite configured to serve it from the deploy base.
- **Pros**: One copy of each image; no duplication; "obvious" mental model.
- **Cons**: Vite's static-copy convention is `public/` — serving an arbitrary root
  folder at the deploy base requires custom config or a `publicDir` override and
  still doesn't place files at the sub-path cleanly. Godot would scatter `.import`
  sidecars into the shared tree, polluting the browser source. Generator scratch
  would land in a tracked directory.
- **Estimated Effort**: Lower up front, higher ongoing (constant sidecar/scratch
  noise in diffs).
- **Rejection Reason**: Conflates three incompatible roles (browser ship, Godot
  import, generator scratch) in one directory; sidecar pollution and deploy-path
  friction outweigh the dedup benefit.

### Alternative 2: Hardcode the deploy base into asset paths

- **Description**: Store fully-qualified `/dragon-forge/assets/...` strings directly
  in content tables; no `assetUrl` helper.
- **Pros**: No indirection; `<img src>` works as-is in production.
- **Cons**: Breaks the Vite dev server (which serves at `/`), breaks tests and any
  non-prod base, and hardwires the deploy path into dozens of data rows — changing
  the deploy path becomes a find-and-replace across content.
- **Estimated Effort**: Trivial now, expensive on any base change.
- **Rejection Reason**: Couples content data to a deploy detail; `import.meta.env.BASE_URL`
  exists precisely to avoid this. Low reversibility.

### Alternative 3: Build-time asset import (Vite `import` / `new URL(...)` bundling)

- **Description**: `import sprite from './assets/x.png'` so Vite fingerprints and
  rewrites URLs; no `public/` directory.
- **Pros**: Hashed filenames, dead-asset detection at build, automatic base
  handling.
- **Cons**: Sprites are referenced by computed keys from data tables (e.g.
  `vfx_${move}.png`, per-dragon stage sprites), which static `import` cannot express
  without an import map; the same files must also be plain on disk for the Godot
  copy; the manifest existence test (simple, fast, build-tool-agnostic) would have to
  be replaced with bundler-coupled checks.
- **Estimated Effort**: High — requires restructuring data-driven asset lookup.
- **Rejection Reason**: Data-driven, runtime-keyed asset selection fits the
  `public/` + `assetUrl` model far better than static bundled imports; the chosen
  approach also keeps the asset existence guard trivial and engine-agnostic.

## Consequences

### Positive

- Browser asset references resolve correctly under the `/dragon-forge/` deploy base
  with no per-call-site awareness — one helper owns base resolution.
- A missing shippable asset is caught by `assetManifest.test.js` before deploy,
  turning silent production 404s into red CI.
- Godot's `.import` UID sidecars are version-controlled with their sources, so the
  Godot project opens without re-import churn on any machine.
- Generator scratch is fully isolated; raw output never sneaks into a shippable
  tree or a diff.
- Clear, single-purpose roles make the policy enforceable by a solo developer.

### Negative

- Art shared by both builds is **duplicated** on disk (browser copy + Godot copy)
  and must be kept in sync manually when a shared sprite changes.
- The three-tree rule is a convention a contributor must learn; writing new web art
  only to root `assets/` (the natural generator output location) ships nothing.
- `assetUrl` is an indirection every runtime asset reference must remember to use;
  a raw string slips through silently in dev (base `/`) and only 404s in prod.

### Neutral

- Content tables store root-relative `/assets/...` paths rather than final URLs;
  the base is applied at the boundary.
- The Godot tree carries extra files (`.import` sidecars, Godot-only `icons/`) that
  have no browser counterpart — expected, not a defect.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Shared sprite updated in `public/assets/` but not in `dragon-forge-godot/assets/` (drift) | Medium | Medium | CLAUDE.md cross-build note mandates dual placement; consider a future sync/diff check between trees |
| New web art written only to gitignored root `assets/` — ships nothing | Medium | Low | `assetManifest.test.js` fails if the URL is wired into a content table without the `public/` file |
| Raw asset URL bypasses `assetUrl`; works in dev (base `/`), 404s in prod | Low | Medium | Centralized helper + manifest test; lint/grep for literal `/assets/` in JSX is a possible reinforcement |
| Godot `.import` sidecar accidentally gitignored or deleted | Low | Medium | Sidecars are committed deliberately; headless `sim_smoke.gd` / opening the project surfaces re-import |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a | n/a (build-time/path concern, no runtime cost) | No runtime budget impact |
| Memory | n/a | n/a | No change |
| Load Time | n/a | Unchanged — `public/` files are served statically; `assetUrl` is a string concat | No regression |
| Network (if applicable) | n/a | Same asset payload as any static-served build | No change |

`assetUrl` is a single string operation per reference with negligible cost. The
manifest test runs only in CI/local test, never at runtime.

## Migration Plan

This ADR documents an already-shipped decision; no migration is pending. The
historical transition (recorded in `.gitignore` comments) was:

1. Repo-root `assets/` master was **untracked** (`.gitignore: /assets/`), demoting
   it to generator scratch.
2. `public/assets/` was established as the tracked browser source of truth; Vite
   serves it at `base: '/dragon-forge/'`.
3. `dragon-forge-godot/assets/` was kept as a separate tracked tree with `.import`
   sidecars committed.
4. `assetManifest.test.js` was added to enforce that content-table URLs resolve
   under `public/`.

**Rollback plan**: Reverting to a single shared tree would mean re-tracking root
`assets/`, pointing Vite's `publicDir`/`base` at it, removing the Godot copy, and
deleting the manifest test — a substantial regression that reintroduces the
deploy-path and sidecar-pollution problems this ADR solves. Not recommended.

## Validation Criteria

- [x] `assetManifest.test.js` passes: every content-table asset URL exists under
  `public/` (dragons, eggs, NPCs, bosses + phases, VFX strips).
- [x] Production build references resolve under `/dragon-forge/assets/...` (no 404s)
  because `assetUrl` prepends `import.meta.env.BASE_URL`.
- [x] Root `assets/` contributes 0 tracked files (`git ls-files assets/` empty);
  `public/assets/` and `dragon-forge-godot/assets/` are tracked (143 / 63+ files).
- [x] Godot project opens without re-importing (sidecars committed with sources).
- [ ] (Ongoing) No shared-sprite drift between `public/assets/` and the Godot copy.

## GDD Requirements Addressed

<!-- This section is MANDATORY. Every ADR must trace back to at least one GDD
     requirement, or explicitly state it is a foundational decision with no GDD
     dependency. Traceability is audited by /architecture-review. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/vfx-animation-accessibility.md` | VFX Overlay | `VFX_FRAMES` maps each move to a 4-frame strip at `public/assets/vfx/vfx_<move>.png`; "VFX strip asset not found / 404 → silent miss" must be the only failure mode | This ADR makes `public/assets/vfx/` the tracked source of truth and `assetManifest.test.js` asserts every `VFX_FRAMES[*].strip.src` exists under `public/`, converting a would-be production 404 into a CI failure |
| `design/gdd/vfx-animation-accessibility.md` | VFX Overlay | Strips must be addressable by computed `vfx_<move>.png` filename and resolve correctly on the deployed sub-path | The `strip()` factory routes each path through `assetUrl()`, which applies the `/dragon-forge/` base once, guaranteeing correct production resolution without per-strip path literals |

> If this is a foundational decision with no direct GDD dependency, write:
> "Foundational — no GDD requirement. Enables: [list what GDD systems this
> decision unlocks or constrains]"

Foundational note: beyond the VFX system above, this is an infrastructure decision
that enables every art-referencing system (dragon/egg/NPC/boss sprites, arenas,
music) to ship correctly on the deploy sub-path.

## Related

- `src/utils.js` — `assetUrl()` base-resolution boundary (the contract's enforcement point)
- `src/sprites.js` — `strip()` factory and `VFX_FRAMES` (representative consumer)
- `src/assetManifest.test.js` — the enforced existence guard for browser assets
- `vite.config.js` — `base: '/dragon-forge/'` (the source of `import.meta.env.BASE_URL`)
- `.gitignore` (lines 11–18) — codifies the three-tree tracking policy
- `CLAUDE.md` (Cross-build notes) — operational rule that shared art goes in both `public/assets/` and `dragon-forge-godot/assets/`
- `design/gdd/vfx-animation-accessibility.md` — primary GDD consumer of the VFX asset paths
