# Epics Index

Last Updated: 2026-05-27
Engine: Godot 4.6

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| [Save / Persistence](save-persistence/EPIC.md) | Foundation | Save / Persistence | `design/gdd/save-persistence.md` | 4 | Ready |
| [Input Router](input-router/EPIC.md) | Foundation | Input Router | `design/gdd/input-router.md` | 4 | Ready |
| [Authored Content Registry](authored-content-registry/EPIC.md) | Foundation | Authored Content Loader | `design/gdd/systems-index.md` | 1 | Ready |
| [Scene Flow / Boot Pipeline](scene-flow/EPIC.md) | Foundation | Scene Flow | `docs/architecture/architecture.md` | 2 | Ready |
| [Semantic Events / Payload Contracts](semantic-events/EPIC.md) | Foundation | Semantic Events | `docs/architecture/architecture.md` | 1 | Ready |
| [Dragon Progression](dragon-progression/EPIC.md) | Core | Dragon Progression | `design/gdd/dragon-progression.md` | 7 | Ready |
| [Economy Ledger](economy-ledger/EPIC.md) | Core | Economy Ledger | `design/gdd/shop.md`, `design/gdd/campaign-map.md` | 4 | Ready |
| [Battle Engine](battle-engine/EPIC.md) | Core | Battle Engine | `design/gdd/battle-engine.md` | 7 | Ready |
| [Hatchery](hatchery/EPIC.md) | Core | Hatchery | `design/gdd/hatchery.md` | 7 | Ready |
| [Fusion Engine](fusion-engine/EPIC.md) | Core | Fusion Engine | `design/gdd/fusion-engine.md` | Not yet created | Ready |

## Notes

- Scope intentionally starts with Foundation layer only. Core and Feature epics should follow after these services are ready enough for implementation stories to depend on.
- Foundation epics are split one-per-architecture-module: Save / Persistence, Input Router, Authored Content Loader, Scene Flow, and Semantic Events.
- Core epics were added after Sprint 01 Foundation completion. Dragon Progression, Economy Ledger, Battle Engine, and Hatchery now have story files; Fusion story files are still pending.
- Review mode is currently `full`, but director gates were not spawned as blocking file writers in this Codex pass; run `/gate-check pre-production` after sprint planning if a formal phase decision is needed.
