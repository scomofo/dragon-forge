# Dragon Forge Campaign Map Design

## Purpose

Dragon Forge needs a real progression map in the current app. The map should make campaign progress visible, give battles a stronger sense of place, and turn enemy encounters into a route through the corrupted elemental matrix rather than a flat list of NPCs.

This feature uses the stronger world-map idea from `dragon-forge-reborn` as inspiration, but it is not a direct port and not a free-roam overworld. The first slice is a hand-authored campaign node map that plugs into the existing Dragon Forge battle flow.

## Scope

Add a new **Campaign Map** screen to the current app.

The first slice includes:

1. A new `MAP` screen available from navigation.
2. A hand-authored route of 8-10 campaign nodes.
3. Visual node states: locked, available, cleared, selected, and boss.
4. Connection lines between nodes.
5. A selected-node detail panel.
6. Owned dragon selection for the selected encounter.
7. A `Begin Battle` action for available nodes.
8. Return-to-map flow after victory or defeat.
9. Node unlocks based on cleared prerequisite nodes.
10. Existing `BATTLES` screen remains available for free battles and daily challenge.

The map should feel like the elemental matrix under siege: corrupted routes, unstable gates, enemy signals, and stabilized nodes. It should not look like a generic stage-select board.

## Non-Goals

- No free movement grid.
- No collision, pathfinding, or tile-by-tile overworld movement.
- No random encounters.
- No new combat rules.
- No new NPC content required for the first slice.
- No replacement of the existing battle select screen.
- No broad save migration beyond a small campaign-clear record if needed.

## Architecture

The feature should be split into three small pieces.

### Campaign Data

Create `src/campaignMap.js` to define the route. Each node should include:

- `id`
- `label`
- `description`
- `npcId`
- `type`: `normal`, `elite`, `boss`, or `story`
- `element`
- `difficulty`
- `position`: percentage-based `{ x, y }` for responsive rendering
- `prerequisiteIds`
- `rewardPreview`

The first route can reuse existing NPCs from `gameData.js`, starting with easier encounters and building toward boss-style nodes.

### Campaign Progression Helper

`campaignMap.js` should also export pure helpers:

- `getCampaignNodeState(node, save)`
- `getCampaignNodeStates(save)`
- `getAvailableCampaignNodes(save)`
- `isCampaignNodeCleared(node, save)`

Node states:

- `cleared`: this campaign node or its mapped NPC has been defeated.
- `available`: all prerequisites are cleared and this node is not cleared.
- `locked`: at least one prerequisite is uncleared.

For the first slice, node clearing can map to existing NPC defeat records where there is a one-to-one node/NPC relationship. If multiple nodes later reuse one NPC, add a small campaign-specific record such as `save.campaign.clearedNodeIds`.

### CampaignMapScreen

Create `src/CampaignMapScreen.jsx`.

Responsibilities:

- Render the map graph.
- Render SVG or CSS connection lines.
- Render nodes by computed state.
- Keep selected node state locally.
- Render selected-node details.
- Render owned dragon choices.
- Disable `Begin Battle` until the node is available and a dragon is selected.
- Call `onBeginCampaignBattle({ nodeId, dragonId, npcId })`.

The screen should not mutate save data directly. It receives `save`, computes display state, and delegates battle launch to `App.jsx`.

## App Flow

Add `MAP` to `SCREENS` in `src/App.jsx`.

Navigation:

- Add `MAP` to `NavBar.jsx`.
- The existing `BATTLES` nav item remains.

Battle launch:

1. Player opens `MAP`.
2. Player selects an available node.
3. Player selects an owned dragon.
4. Player clicks `Begin Battle`.
5. `App.jsx` sets `battleConfig` with:
   - `dragonId`
   - `npcId`
   - `campaignNodeId`
   - `returnScreen: 'map'`
6. App opens the existing `BattleScreen`.

Battle return:

- On victory, existing battle logic records the NPC defeat.
- On defeat, no campaign clear happens.
- After battle end, App refreshes save and returns to `MAP` when `battleConfig.returnScreen === 'map'`.
- Campaign helpers recompute node states from the refreshed save.

## Player Experience

The Campaign Map opens to a full-screen matrix route. Nodes sit on a diagonal or branching path, with visible connections between them.

Node treatment:

- Locked nodes are dimmed, corrupted, and show a lock glyph.
- Available nodes pulse as active signals.
- Cleared nodes show a stable glow and check marker.
- Boss nodes are larger and framed with heavier warning treatment.
- The selected node has a clear focus ring and matching detail panel.

The selected-node detail panel shows:

- Node title.
- Short flavor description.
- Enemy name.
- Element and difficulty.
- Level, if available from NPC data.
- Reward preview.
- Unlock requirement if locked.
- Owned dragon selector.
- `Begin Battle` button when actionable.

The map should teach progression visually: cleared nodes stabilize the route, available nodes invite the next fight, and locked nodes show where the campaign is going.

## Testing

Automated tests should cover pure campaign logic:

- The first node is available when no campaign progress exists.
- Nodes with unmet prerequisites are locked.
- Nodes become available when all prerequisites are cleared.
- Cleared nodes stay selectable and inspectable.
- Boss nodes remain locked until prerequisites are cleared.
- A node mapped to an already-defeated NPC is treated as cleared.

Existing battle tests should continue to pass unchanged.

Manual browser smoke testing should cover:

- Open the new `MAP` screen from nav.
- Select locked, available, cleared, and boss nodes.
- Select an owned dragon.
- Start a battle from an available node.
- Lose or exit from battle and confirm the node remains available.
- Win a battle and confirm App returns to `MAP`.
- Confirm the cleared node changes state and downstream nodes unlock.
- Check mobile/narrow viewport readability in the in-app browser.

## Rollout

Implement in five chunks:

1. Add campaign data and failing helper tests.
2. Implement campaign helper logic.
3. Add `CampaignMapScreen` and CSS.
4. Wire App/Nav/Battle return flow.
5. Build and smoke-test in the in-app browser.

This order keeps progression rules testable before UI work, then uses the existing battle screen instead of introducing a separate combat path.
