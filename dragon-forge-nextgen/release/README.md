# Standalone playtest packaging

These exports contain the complete Reconnection campaign with the Boss Identities,
Tempest, soundtrack, evolution and fusion work. They are not editor launchers or
empty test rooms. Gameplay, save schema 5 and the custom userdata directory are
unchanged. No user save, credentials, editor cache, authoring tools or font files
are bundled. Godot's license and dependency notices accompany each package.

## Playing

Download a **standalone-playtest** artifact from the successful `Nextgen standalone
playtests` workflow, not the candidate artifacts. Extract its inner platform ZIP.
On Windows run `DragonForge.exe`, keeping its `.pck` and libraries alongside it.
On macOS open `DragonForge.app`; this universal bundle targets Intel and Apple Silicon.
On Linux run `DragonForge.x86_64`. No Godot installation or export template is
needed. The optional `Play-Compatibility` launcher selects OpenGL for troubleshooting.
The title still reads BOSS IDENTITIES: this pass packages that game, not new content.

Choose Continue under the same OS account to retain campaign progress. Keep a
backup before a playtest. Save location is the existing custom Godot user directory
`dragon-forge-nextgen-prototype`; the file is `reconnection-campaign.json`.
Moving between operating systems does not copy saves automatically.

Windows is unsigned. macOS uses Godot's built-in ad-hoc signature, not Developer ID
signing or Apple notarization. These private playtest builds may show OS security
warnings. Do not turn off system security or antivirus. For a trusted Mac build,
attempt to open it, then use the per-app Open Anyway option in Privacy & Security
where available. Public distribution still needs proper signing/notarization.

## Building

Use **Godot 4.6.3 Standard** and matching standard export templates. From any folder:

```sh
python /path/to/dragon-forge-nextgen/tools/release/build.py \
  --godot /path/to/godot --output /new/path/outside/project --commit COMMIT_SHA
```

The output directory must not exist; the script will not overwrite prior builds.
Three presets live in `export_presets.cfg`. It imports source assets and generates
`release/build_info.json` for that build before exporting. No prior runtime source
or asset is modified. The GUI Export dialog can also use these presets after metadata
is generated. Runtime dependency discovery includes dynamically loaded boss models,
guardian variants and soundtrack; validation rejects missing packed assets.

GitHub Actions downloads exact 4.6.3 release assets from Godot's official repository,
checks their upstream SHA-256 digests, and records the URLs, sizes and hashes. It
exports all platforms on Linux, then checks each ZIP with its own executable on a
native runner. Linux additionally renders actual game captures with software OpenGL.
The workflow is read-only: no commits, tags, GitHub Releases, secrets or signing
credentials. After merging the workflow to the default branch, Run workflow can
select a branch; PR runs also work without merging. Artifacts expire after 14 days.

## What the checks establish

Package integrity, executable format, default campaign startup, all 53 models/maps/
recordings loadable from the exported pack, all 22 rooms, five imported bosses,
evolved guardian swaps, runtime audio decoding, older-save migration and exact
backup preservation. macOS also checks both architectures and the ad-hoc signature.
Only the runner's native architecture is executed; presence of a second slice is
not a second-architecture playtest. Headless Windows/macOS checks do not establish
rendering performance or physical audio/controller quality.

The opt-in `release/export_smoke.gd` is shipped solely for repeatable pack checks.
It runs only with an explicit `--ci-release-check` argument and absolute report
folder, instantiates a test-mode world, and uses a uniquely named temporary save.
It neither loads nor overwrites the player's campaign. Ordinary startup does not
run these tests. Development tests/validation scenes are excluded from player builds;
use the full source project to inspect characters or rehearse bosses.

Reference documentation:
- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_projects.html
- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_macos.html
- https://docs.godotengine.org/en/4.6/tutorials/export/running_on_macos.html
