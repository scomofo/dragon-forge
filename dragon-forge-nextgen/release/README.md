# Standalone playtest packaging

These exports contain the complete Reconnection campaign with Cairn / Stone Resonance,
the Boss Identities, Tempest, soundtrack, evolution and fusion work. They are not
editor launchers or empty test rooms. Gameplay, save schema 6 and the custom userdata
directory are unchanged. No user save, credentials, authoring tools or font files are
bundled. Godot's license and dependency notices accompany each package.

## Playing

Download a **standalone-playtest** artifact from the successful `Nextgen standalone
playtests` workflow, not the candidate artifacts. Extract its inner platform ZIP.
On Windows run `DragonForge.exe`, keeping its `.pck` and libraries alongside it.
On macOS open `DragonForge.app`; this universal bundle targets Intel and Apple Silicon.
On Linux run `DragonForge.x86_64`. No Godot installation or export template is
needed. The optional `Play-Compatibility` launcher selects OpenGL for troubleshooting.
The title reads **STONE RESONANCE**. Cairn is the fourth owned guardian; expeditions
still use exactly two live field slots.

Choose Continue under the same OS account to retain campaign progress. Keep a
backup before a playtest. Save location is the existing custom Godot user directory
`dragon-forge-nextgen-prototype`; the file is `reconnection-campaign.json`.
Moving between operating systems does not copy saves automatically.

Windows is unsigned. macOS uses Godot's built-in ad-hoc signature, not Developer ID
signing or Apple notarization. These playtest builds may show OS security warnings.
Do not turn off system security or antivirus. For a trusted Mac build, attempt to
open it, then use the per-app Open Anyway option in Privacy & Security where
available. Public distribution still needs proper signing/notarization.

## Building

Use **Godot 4.6.3 Standard** and matching standard export templates. From any folder:

```sh
python /path/to/dragon-forge-nextgen/tools/release/build.py \
  --godot /path/to/godot --output /new/path/outside/project --commit COMMIT_SHA
```

The output directory must not exist; the script will not overwrite prior builds.
Three presets live in `export_presets.cfg`. Both desktop S3TC/BPTC and Apple
Silicon ETC2/ASTC texture import formats are enabled in project settings. The build
imports source assets and generates `release/build_info.json` before exporting.
No prior gameplay source or asset is modified. The GUI Export dialog can also use
these presets after metadata is generated. Runtime dependency discovery includes
dynamically loaded boss models, guardian variants, Cairn and the soundtrack;
validation rejects missing packed assets.

GitHub Actions downloads exact 4.6.3 release assets from Godot's official repository,
checks their upstream SHA-256 digests, and records the URLs, sizes and hashes. It
exports all platforms on Linux, then checks each ZIP with its own executable on a
native runner. Linux additionally renders actual game captures with software OpenGL.
The workflow has read-only repository permissions, with no commits, tags, GitHub
Releases or developer signing credentials. An ephemeral built-in workflow token
authenticates only the official public release metadata request, avoiding shared
runner anonymous API rate limits. It is not stored in artifacts or executables.
After merging the workflow to the default branch, Run workflow can select a branch;
PR runs also work without merging. Artifacts expire after 14 days.

## What the checks establish

Package integrity, executable format, default campaign startup, all **58** models/maps/
recordings loadable from the exported pack, all 22 rooms, five imported bosses,
Fire/Ice/Storm/Stone guardian swaps, runtime audio decoding, schema-5-to-6 migration
and exact backup preservation. macOS also checks both architectures and the ad-hoc
signature. Only the runner's native architecture is executed; presence of a second
slice is not a second-architecture playtest. Headless Windows/macOS checks do not
establish rendering performance or physical audio/controller quality.

Release templates do not support the editor-only `--script` flag. Export presets
set the `standalone` feature, selecting `release/entry.tscn` as an export-only
bootstrap. Ordinary launches immediately open the unchanged campaign scene.
Editor Run Project still opens `campaign/main.tscn` directly.

The opt-in `release/export_smoke.gd` Node is dispatched by this bootstrap only
with an explicit `--ci-release-check` argument and absolute report folder. It
instantiates a test-mode world and uses a uniquely named temporary save. It verifies
Cairn is packed and swappable and exercises schema-5-to-6 migration without writing
the source save until the explicit test write. It neither loads nor overwrites the
player's campaign. Ordinary startup does not run these tests. Development tests and
validation scenes are excluded from player builds; use the full source project to
inspect characters or rehearse bosses.

Reference documentation:
- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_projects.html
- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_macos.html
- https://docs.godotengine.org/en/4.6/tutorials/export/running_on_macos.html
