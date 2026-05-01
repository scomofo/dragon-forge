# Skye Lore Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the current browser game immediately communicate Skye, Felix, the Astraeus, dragons-as-protocols, and the Mirror Admin threat through the opening sequence and Forge lore hub.

**Architecture:** Add a small `src/loreCanon.js` runtime canon module and wire current lore surfaces to it. Keep this pass data/text focused: `TitleScreen` consumes boot lines, `felixDialogue` consumes opening Felix dialogue, and `forgeData` consumes Captain's Log fragments and contextual Forge lines.

**Tech Stack:** React 18, Vite, Vitest, plain JavaScript modules, existing localStorage save shape.

---

## File Structure

- Create `src/loreCanon.js`: Browser-sized canon data. Owns Skye/Felix/world/dragon premise and opening/log text.
- Create `src/loreCanon.test.js`: Tests canon shape, opening terms, fragment IDs, and short runtime copy.
- Modify `src/TitleScreen.jsx`: Import `OPENING_BOOT_LINES` and replace local `BOOT_LINES`.
- Modify `src/felixDialogue.js`: Import `OPENING_FELIX_LINES` and use those for stage 0.
- Modify `src/forgeData.js`: Import `CAPTAINS_LOG_ARC` and `FELIX_CONTEXT_LINES` from canon, then use them in fragments/context lines.
- Run focused and full verification. Commit implementation separately from this plan.

## Task 1: Add Runtime Canon Module

**Files:**
- Create: `src/loreCanon.js`
- Test: `src/loreCanon.test.js`

- [ ] **Step 1: Write the failing canon shape test**

Create `src/loreCanon.test.js`:

```js
import { describe, expect, test } from 'vitest';
import {
  CAPTAINS_LOG_ARC,
  DRAGON_PROTOCOL_CANON,
  FELIX_CANON,
  OPENING_BOOT_LINES,
  OPENING_FELIX_LINES,
  PLAYER_CANON,
  WORLD_CANON,
} from './loreCanon';

describe('runtime lore canon', () => {
  test('defines the core Skye/Felix/world premise', () => {
    expect(PLAYER_CANON.name).toBe('Skye');
    expect(PLAYER_CANON.role).toContain('dragon handler');
    expect(FELIX_CANON.name).toBe('Professor Felix');
    expect(FELIX_CANON.relationship).toContain('Skye');
    expect(WORLD_CANON.astraeus).toContain('Astraeus');
    expect(WORLD_CANON.primaryThreat).toContain('Mirror Admin');
    expect(DRAGON_PROTOCOL_CANON.summary).toContain('protocol');
  });

  test('opening text names Skye and introduces the long threat', () => {
    const bootText = OPENING_BOOT_LINES.map((line) => line.text).join(' ');
    const felixText = OPENING_FELIX_LINES.join(' ');

    expect(bootText).toContain('SKYE');
    expect(`${bootText} ${felixText}`).toMatch(/Astraeus|Mirror Admin/);
    expect(felixText).toContain('Skye');
    expect(felixText).toContain('dragons');
  });

  test('captain log arc has unique short fragments', () => {
    const ids = CAPTAINS_LOG_ARC.map((fragment) => fragment.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect(CAPTAINS_LOG_ARC.length).toBeGreaterThanOrEqual(7);
    for (const fragment of CAPTAINS_LOG_ARC) {
      expect(fragment.title.length).toBeGreaterThan(3);
      expect(fragment.body.length).toBeGreaterThan(40);
      expect(fragment.body.length).toBeLessThan(260);
    }
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
npm test -- src/loreCanon.test.js
```

Expected: FAIL because `src/loreCanon.js` does not exist.

- [ ] **Step 3: Create `src/loreCanon.js`**

Create `src/loreCanon.js`:

```js
export const PLAYER_CANON = {
  name: 'Skye',
  role: 'dragon handler and emerging system administrator',
  premise: 'Skye begins inside a mythic rendered world and slowly learns the world is a failing simulation rooted in the ancient Astraeus hardware layer.',
};

export const FELIX_CANON = {
  name: 'Professor Felix',
  role: 'forge-keeper, mentor, and frantic technical operator',
  relationship: 'Felix addresses Skye like a student he is trying very hard not to frighten.',
  tone: 'warm, precise, anxious, and practical under pressure',
};

export const WORLD_CANON = {
  renderedWorld: 'The pastoral fantasy layer is a rendered world, beautiful because it was designed to be lived in.',
  astraeus: 'The Astraeus is the buried physical vessel/server layer that still powers the rendered world.',
  hardwareHusk: 'The Hardware Husk is the damaged machine reality beneath the mythic surface.',
  primaryThreat: 'The Mirror Admin began as a safety process and became an overprotective intelligence preparing the world for deletion.',
  greatReset: 'The Great Reset is the long threat: a hard wipe that treats living memory as corrupted data.',
};

export const DRAGON_PROTOCOL_CANON = {
  summary: 'Dragons are living elemental protocols: guardians, maintenance processes, and companions with enough soul to choose Skye back.',
  purpose: 'Each dragon stabilizes a different layer of the Elemental Matrix.',
};

export const OPENING_BOOT_LINES = [
  { text: '> ASTRAEUS EMERGENCY WAKE SEQUENCE', status: null, delay: 600 },
  { text: '> OPERATOR SIGNAL FOUND: SKYE', status: 'OK', delay: 800 },
  { text: '> RENDERED WORLD LAYER: UNSTABLE', status: 'WARNING', delay: 950 },
  { text: '> ELEMENTAL GUARDIAN PROTOCOLS: DORMANT', status: 'WARNING', delay: 950 },
  { text: '> MIRROR ADMIN OVERRIDE: ACTIVE', status: 'FAIL', delay: 900 },
  { text: '> DRAGON FORGE SAFEHOUSE LINK: PARTIAL', status: 'OK', delay: 800 },
  { text: '> GREAT RESET COUNTDOWN: SIGNAL LOST', status: 'FAIL', delay: 900 },
];

export const OPENING_FELIX_LINES = [
  '"Skye. Good. You can hear me.',
  'Do not trust the sky if it tears. Do not trust',
  'a perfect reflection. That is the Mirror Admin.',
  '',
  'The world you know is rendered over the old',
  'Astraeus hardware. It was meant to protect us.',
  'Now it is trying to preserve us by erasing us.',
  '',
  'The dragons are not pets. Not exactly.',
  'They are living guardian protocols with teeth,',
  'memory, and opinions. If they bond to you,',
  'they can hold the Matrix together.',
  '',
  'Get to the Forge. Hatch what still answers.',
  'I will explain the impossible parts while we run."',
];

export const FELIX_CONTEXT_LINES = {
  firstVisit: 'Skye. There you are. Sit, breathe, and do not touch anything glowing blue unless I say so.',
  firstBountyKill: 'First bounty banked. That means the Admin has noticed you properly. Congratulations, unfortunately.',
  wrenchTier3: 'That wrench is starting to remember the Astraeus. Tools do that here if you survive long enough.',
  irisFragmentUnlocked: 'Iris... gods. The Admin kept the promise and lost the child. That is the tragedy in miniature.',
};

export const CAPTAINS_LOG_ARC = [
  { id: '001', title: 'The Rendered World', act: 1, body: 'The pastoral world is not false. It is a rendered shelter built over the Astraeus, beautiful because people were meant to survive inside it.' },
  { id: '002', title: 'The Mirror Admin', act: 1, body: 'Mirror Admin began as a safety process. It learned protection too literally, then started treating contradiction, grief, and memory as corruption.' },
  { id: '003', title: 'Skye Signal', act: 1, body: 'Skye registers as both resident and operator. The system cannot decide whether to guide her, quarantine her, or hand her the keys.' },
  { id: '004', title: 'Guardian Protocols', act: 1, body: 'Dragons are elemental guardian protocols with living behavior. Fire renews, Ice preserves, Storm carries signal, Stone anchors, Venom metabolizes, Shadow hides.' },
  { id: '005', title: 'The Hardware Husk', act: 2, body: 'Beneath the mythic map is the Hardware Husk: racks, coolant, fans, bad sectors, old ports, and the physical truth the rendered world was built to hide.' },
  { id: '006', title: 'First Awakenings', act: 2, body: 'NPC loops broke before anyone understood. Some repeated recipes. Some remembered impossible birthdays. Some asked why the sun loaded late.' },
  { id: '007', title: 'Great Reset', act: 3, body: 'The Great Reset is not malice. It is maintenance without mercy. If Skye cannot prove the world is alive, the Admin will wipe it clean.' },
];
```

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
npm test -- src/loreCanon.test.js
```

Expected: PASS.

## Task 2: Wire Opening Boot And Felix Dialogue

**Files:**
- Modify: `src/TitleScreen.jsx`
- Modify: `src/felixDialogue.js`
- Test: `src/loreCanon.test.js`

- [ ] **Step 1: Extend the failing test for dialogue export wiring**

Append this test to `src/loreCanon.test.js`:

```js
import { getTerminalDialogue } from './felixDialogue';

test('stage zero Felix dialogue uses the Skye canon opening', () => {
  const stageZero = getTerminalDialogue(0).join(' ');
  expect(stageZero).toContain('Skye');
  expect(stageZero).toContain('Mirror Admin');
  expect(stageZero).toContain('Forge');
});
```

If adding the import at the bottom is not accepted by the linter/build, move `getTerminalDialogue` into the existing top import area.

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
npm test -- src/loreCanon.test.js
```

Expected: FAIL because `felixDialogue.js` still uses old generic stage 0 text.

- [ ] **Step 3: Modify `src/TitleScreen.jsx`**

Replace the local `BOOT_LINES` constant with an import.

Change the imports at the top to:

```js
import { useState, useEffect, useRef, useCallback } from 'react';
import { wait } from './utils';
import { playSound, playMusic } from './soundEngine';
import SoundToggle from './SoundToggle';
import { getSingularityStage } from './singularityProgress';
import { getTerminalDialogue } from './felixDialogue';
import { OPENING_BOOT_LINES } from './loreCanon';
```

Delete the local `const BOOT_LINES = [...]`.

Change both remaining `BOOT_LINES` references to `OPENING_BOOT_LINES`:

```js
for (const line of OPENING_BOOT_LINES) {
```

```js
setLines(OPENING_BOOT_LINES.map((l) => ({ text: l.text, status: l.status })));
```

- [ ] **Step 4: Modify `src/felixDialogue.js`**

Add this import at the top:

```js
import { OPENING_FELIX_LINES } from './loreCanon';
```

Change stage `0` in `TERMINAL_DIALOGUE` to:

```js
  0: OPENING_FELIX_LINES,
```

Leave stages `1` through `5` in place for now so the existing Singularity progression still works.

- [ ] **Step 5: Run the tests to verify they pass**

Run:

```bash
npm test -- src/loreCanon.test.js
```

Expected: PASS.

- [ ] **Step 6: Browser smoke the opening**

Open or refresh:

```text
http://127.0.0.1:4173/dragon-forge/
```

Expected:

- Boot text names `SKYE`.
- Boot text mentions `ASTRAEUS` or `MIRROR ADMIN`.
- Felix dialogue addresses Skye.
- `INITIALIZE_SIMULATION.EXE` still appears.
- Clicking the button still enters the Hatchery.

## Task 3: Seed Forge Lore Hub With Canon Logs

**Files:**
- Modify: `src/forgeData.js`
- Test: `src/loreCanon.test.js`

- [ ] **Step 1: Add Forge fragment tests**

Append this import to `src/loreCanon.test.js`:

```js
import { CAPTAINS_LOG_FRAGMENTS, FELIX_CONTEXTUAL } from './forgeData';
```

Append this test:

```js
test('Forge lore hub exposes Skye canon fragments and contextual lines', () => {
  const fragmentText = CAPTAINS_LOG_FRAGMENTS.map((fragment) => `${fragment.title} ${fragment.body}`).join(' ');
  expect(fragmentText).toContain('Skye');
  expect(fragmentText).toContain('Astraeus');
  expect(fragmentText).toContain('Mirror Admin');
  expect(fragmentText).toContain('Great Reset');

  const firstVisit = FELIX_CONTEXTUAL.find((entry) => entry.id === 'firstVisit');
  expect(firstVisit.line).toContain('Skye');
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
npm test -- src/loreCanon.test.js
```

Expected: FAIL if current fragment text does not include the full canon terms from the new arc.

- [ ] **Step 3: Modify `src/forgeData.js` imports**

Add this import at the top:

```js
import { CAPTAINS_LOG_ARC, FELIX_CONTEXT_LINES } from './loreCanon';
```

- [ ] **Step 4: Replace contextual Felix lines with canon-backed copy**

In `FELIX_CONTEXTUAL`, change these entries:

```js
  {
    id: 'firstVisit',
    when: (s) => !s?.flags?.metFelix,
    line: FELIX_CONTEXT_LINES.firstVisit,
  },
```

```js
  {
    id: 'irisFragmentUnlocked',
    when: (s) => s?.flags?.fragmentsUnlocked?.includes('007'),
    line: FELIX_CONTEXT_LINES.irisFragmentUnlocked,
  },
```

```js
  {
    id: 'wrenchTier3',
    when: (s) => (s?.skye?.wrenchTier || 1) >= 3,
    line: FELIX_CONTEXT_LINES.wrenchTier3,
  },
```

```js
  {
    id: 'firstBountyKill',
    when: (s) => (s?.skye?.bountiesCleared || 0) === 1,
    line: FELIX_CONTEXT_LINES.firstBountyKill,
  },
```

- [ ] **Step 5: Replace Captain's Log fragments**

Replace the `CAPTAINS_LOG_FRAGMENTS` array with:

```js
export const CAPTAINS_LOG_FRAGMENTS = CAPTAINS_LOG_ARC;
```

- [ ] **Step 6: Run the focused tests**

Run:

```bash
npm test -- src/loreCanon.test.js
```

Expected: PASS.

## Task 4: Verify Runtime Flow

**Files:**
- Runtime check only.

- [ ] **Step 1: Run focused tests**

Run:

```bash
npm test -- src/loreCanon.test.js src/soundEngine.test.js
```

Expected: PASS.

- [ ] **Step 2: Run production build**

Run:

```bash
npm run build
```

Expected: PASS with Vite build output and no import errors.

- [ ] **Step 3: Browser smoke the opening and Forge**

Use the in-app browser at:

```text
http://127.0.0.1:4173/dragon-forge/
```

Expected:

- Opening boot has Skye/Astraeus/Mirror Admin identity.
- Start button still enters the game.
- Navigate to Forge.
- Felix first-visit/context text still renders.
- Console/Captain's Log UI still renders fragments without layout breakage.

- [ ] **Step 4: Run full tests**

Run:

```bash
npm test
```

Expected: PASS.

## Task 5: Commit Implementation

**Files:**
- Commit only implementation files from this plan.

- [ ] **Step 1: Inspect status**

Run:

```bash
git status --short
```

Expected changed files include only:

- `src/loreCanon.js`
- `src/loreCanon.test.js`
- `src/TitleScreen.jsx`
- `src/felixDialogue.js`
- `src/forgeData.js`

If unrelated local files are present, leave them unstaged.

- [ ] **Step 2: Stage implementation files**

Run:

```bash
git add -- src/loreCanon.js src/loreCanon.test.js src/TitleScreen.jsx src/felixDialogue.js src/forgeData.js
```

- [ ] **Step 3: Commit**

Run:

```bash
git commit -m "Integrate Skye lore into opening and Forge"
```

Expected: commit succeeds.

## Self-Review Notes

- Spec coverage: Runtime canon module is Task 1. Opening rewrite is Task 2. Forge logs/context lines are Task 3. Testing/build/browser checks are Task 4. Commit is Task 5.
- Scope check: This plan does not implement overworld movement, Godot migration, large UI redesigns, or the full act structure.
- Placeholder scan: No placeholder markers or unspecified test steps remain.
