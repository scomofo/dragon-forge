# Dragon Forge: Traveler's Journal Design Spec

## Overview

A bestiary/collection screen accessible via a "JOURNAL" tab in the NavBar. Split-view layout: left panel shows a 2x3 grid of dragon cards (discovered vs silhouette), right panel shows the selected dragon's detail dossier. 7 milestones with DataScraps rewards track collection progress.

---

## 1. Screen Layout

### 1.1 Split View

- **Left panel (40% width)** — 2x3 grid of dragon cards, always visible
- **Right panel (60% width)** — Detail view for the selected dragon
- Full height of the game area (same as other screens)

### 1.2 Left Panel — Dragon Grid

6 cards in a 2-column, 3-row grid. Each card shows:

**Owned dragons:**
- Animated DragonSprite (small size, stage-appropriate scale)
- Dragon name in element color
- Level and stage text
- Element-colored left border
- Shiny star icon if shiny
- Click to select → highlights with element-colored border

**Undiscovered dragons:**
- Silhouette: DragonSprite with CSS `filter: brightness(0)` (black shape)
- "???" as name in gray
- "UNDISCOVERED" as subtext
- Gray border
- Still clickable (shows "undiscovered" detail on right)

**Footer:** "X/6 DISCOVERED" counter below the grid.

**Default selection:** First owned dragon in element order (fire, ice, storm, stone, venom, shadow). If none owned, first dragon (fire) selected showing undiscovered state.

### 1.3 Right Panel — Detail Dossier

For **owned** dragons:
- Large animated DragonSprite (standard battle size, with shiny glow if applicable)
- Dragon name (element color, large)
- Element tag, Level, Stage
- Stats at current level: HP, ATK, DEF, SPD — displayed as labeled values
- If fusedBaseStats, show "(Fused)" indicator next to stats
- Felix lore quote in italic, dimmer color
- Milestone badges this dragon contributed to (e.g., "First Discovery" if this was the first owned)

For **undiscovered** dragons:
- Large silhouette sprite (brightness(0) filter)
- "???" as name
- "No data available. Discover this dragon in the Hatchery." as lore
- No stats shown

---

## 2. Milestones

### 2.1 Milestone Definitions

| ID | Name | Check | Reward |
|---|---|---|---|
| `first_discovery` | First Discovery | Any 1 dragon owned | 100 DataScraps |
| `elemental_trio` | Elemental Trio | Any 3 dragons owned | 200 DataScraps |
| `full_roster` | Full Roster | All 6 dragons owned | 500 DataScraps |
| `shiny_hunter` | Shiny Hunter | Any 1 shiny dragon | 300 DataScraps |
| `shiny_collector` | Shiny Collector | 3+ shiny dragons | 1000 DataScraps |
| `elder_forged` | Elder Forged | Any dragon level 50+ | 250 DataScraps |
| `fusion_master` | Fusion Master | Any dragon with fusedBaseStats | 200 DataScraps |

### 2.2 Behavior

- On journal screen load, check each unclaimed milestone against the current save state
- If a milestone is newly met: add its ID to `save.milestones`, award DataScraps, show a brief pulse animation on the badge
- Already-claimed milestones display as green with a checkmark
- Unclaimed milestones display as gray with progress text (e.g., "2/3", "0/6")
- Milestones are permanent — once claimed, they stay claimed even if conditions change (e.g., dragon lost to fusion)

### 2.3 Display

Milestones are shown in the right panel below the dragon detail, as a horizontal row of compact badges. Each badge shows:
- Icon/checkmark status
- Milestone name
- Progress or "CLAIMED" text
- Green border if claimed, gray if not

When a milestone is newly claimed on this visit, it gets a brief gold pulse animation and a "+X DataScraps" flash.

---

## 3. Dragon Lore

Felix flavor quotes displayed in the detail panel:

| Dragon | Lore |
|---|---|
| Magma Dragon | "Forged from the planet's molten core. Its breath can melt through starship bulkheads — handle with extreme caution." |
| Ice Dragon | "Crystallized from subzero atmospheric anomalies. The temperature drops 30 degrees in its presence alone." |
| Storm Dragon | "Born from a feedback loop in the planet's electromagnetic field. Faster than anything I've ever recorded." |
| Stone Dragon | "Its hide is denser than compressed titanium. I once watched it walk through a collapsing mine without flinching." |
| Venom Dragon | "Secretes a neurotoxin that can dissolve organic matter in seconds. Keep it away from the lab samples." |
| Shadow Dragon | "This one... shouldn't exist. It reads as a gap in the data — a hole where reality should be. Fascinating." |

Stored in `gameData.js` as a `dragonLore` export keyed by element.

---

## 4. Navigation

- New "JOURNAL" tab in NavBar, always visible (no unlock condition)
- Placed between FUSION (or HATCHERY if fusion not shown) and BATTLES
- Active state styled the same as other tabs

---

## 5. Persistence Changes

Add `milestones: []` to the save structure. Migration in `migrateSave`:

```js
if (save.milestones === undefined) save.milestones = [];
```

New function `claimMilestone(milestoneId, reward)`:
- Adds milestoneId to `save.milestones` array
- Adds reward to `save.dataScraps`
- Writes save

---

## 6. File Changes

| File | Action | Responsibility |
|---|---|---|
| `src/JournalScreen.jsx` | Create | Main journal screen — grid + detail split layout, milestone checking |
| `src/journalMilestones.js` | Create | Milestone definitions array and `checkMilestones(save)` function |
| `src/gameData.js` | Modify | Add `dragonLore` export |
| `src/persistence.js` | Modify | Add `milestones` to save, migration, `claimMilestone` function |
| `src/NavBar.jsx` | Modify | Add JOURNAL tab |
| `src/App.jsx` | Modify | Add journal screen routing |
| `src/styles.css` | Modify | Journal layout, grid cards, detail panel, milestone badge styles |

---

## 7. Out of Scope

- Battle history / win-loss tracking per dragon
- Dragon evolution timeline visualization
- Void element / 7th dragon
- Narrative / Singularity arc
- Journal entries for NPCs
