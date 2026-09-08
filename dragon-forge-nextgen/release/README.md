# Standalone playtest packaging

The current export scope is the complete Reconnection campaign with Prism / Synthesis Resonance,
Lumen / Light Awakening, Null / Void Resonance,
Umbra / Shadow Resonance,
Nox / Venom Resonance, Cairn / Stone Resonance, Forge Trials, Boss Identities, Tempest, the existing soundtrack,
evolution and fusion work. They are not editor launchers or empty test rooms. Campaign
progress uses save schema 11 and retains the existing custom userdata directory. Release
acceptance for this revision is pending until its own workflow results pass. No user
save, credentials, authoring tools or separate font files are bundled. Godot's license
and dependency notices accompany each package.

## Playing

Download a **standalone-playtest** artifact from the successful `Nextgen standalone
playtests` workflow, not the candidate artifacts. Extract its inner platform ZIP.
On Windows run `DragonForge.exe`, keeping its `.pck` and libraries alongside it.
On macOS open `DragonForge.app`; this universal bundle targets Intel and Apple Silicon.
On Linux run `DragonForge.x86_64`. No Godot installation or export template is
needed. The optional `Play-Compatibility` launcher selects OpenGL for troubleshooting.
The default entry is the Reconnection campaign. Up to nine guardians can be owned;
expeditions still use exactly two live field slots. Stabilizing the Singularity directly
awakens Lumen and retains the selected expedition pair. For optional Null recruitment,
recover the preserved Void imprint in its chamber and take it to the Forge. With both
Lumen and Null owned, create Synthesis resonance at the Forge and awaken Prism; all
owned guardians and the selected expedition pair remain intact.

Choose Continue under the same OS account to retain campaign progress. Keep a
backup before a playtest. Save location is the existing custom Godot user directory
`dragon-forge-nextgen-prototype`; the file is `reconnection-campaign.json`.
Moving between operating systems does not copy saves automatically. Valid older
campaign saves migrate in memory; completed campaigns receive earned Light and unfinished
campaigns receive no Light. Migration grants no Synthesis progress. Loading alone
does not rewrite the original bytes.

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
dynamically loaded boss models, guardian variants, Cairn, Nox, Umbra, Null, Lumen, Prism and the soundtrack;
validation rejects missing packed assets.

GitHub Actions downloads exact 4.6.3 release assets from Godot's official repository,
checks their upstream SHA-256 digests, and records the URLs, sizes and hashes. It
exports all platforms on Linux, then checks each ZIP with its own executable on a
native runner. Linux additionally renders actual game captures with software OpenGL.
The standalone workflow has read-only repository permissions and does not create
commits, tags, GitHub Releases or developer signing credentials. An ephemeral built-in
workflow token authenticates only the official public release metadata request. It is
not stored in artifacts or executables. Artifacts expire after 14 days.

## What the checks establish

The gate checks package integrity, executable format, default campaign startup, all
**83** models/maps/recordings loadable from the exported pack, all 22 rooms, five imported bosses,
Fire/Ice/Storm/Stone/Venom/Shadow/Void/Light/Synthesis guardian swaps, runtime audio decoding, schema-5/7/8/9/10-to-11
migration and exact backup preservation. Shared combat acceptance exercises Shadow's
shield-preserving Phase Strike, Void's shield-safe displacement, reflection and drain,
Light's shield-respecting attacks and self-only Restoration, and Synthesis's
shield-preserving status selection, direct beam and displacement.
macOS also checks both architectures and the
ad-hoc signature. Only the runner's native architecture is executed; presence of a
second slice is not a second-architecture playtest. Headless Windows/macOS checks do
not establish rendering performance or physical audio/controller quality.

Forge Trials remain separate from campaign progression. Their automated checks verify
that trial clears do not grant campaign salvage, clear flags, cores, guardian unlocks
or other campaign milestones. This is not a human balance or fun certification.

Release templates do not support the editor-only `--script` flag. Export presets
set the `standalone` feature, selecting `release/entry.tscn` as an export-only
bootstrap. Ordinary launches immediately open the unchanged campaign scene.
Editor Run Project still opens `campaign/main.tscn` directly.

The opt-in `release/export_smoke.gd` Node is dispatched by this bootstrap only
with an explicit `--ci-release-check` argument and absolute report folder. It
instantiates a test-mode world and uses a uniquely named temporary save. It verifies
Umbra, Null, Lumen and Prism are packed and swappable and exercises schema-5/7/8/9/10-to-11 migration without writing
the source save until the explicit test write. It neither loads nor overwrites the
player's campaign. Ordinary startup does not run these tests. Development tests and
validation scenes are excluded from player builds; use the full source project to
inspect characters or rehearse bosses.

Reference documentation:
- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_projects.html
- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_macos.html
- https://docs.godotengine.org/en/4.6/tutorials/export/running_on_macos.html
