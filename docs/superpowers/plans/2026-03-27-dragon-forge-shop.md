# Shop Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a shop screen with two tabs — BUY (spend DataScraps on items) and FORGE (craft with element cores dropped from battles). Provides a DataScraps sink and rewards battle grinding.

**Architecture:** Shop item and recipe definitions in `shopItems.js`. Inventory stored in persistence (`save.inventory`). Core drops added to BattleScreen victory flow. ShopScreen renders a tabbed interface with item cards. Item effects applied immediately via persistence functions.

**Tech Stack:** React 18, CSS, localStorage

---

## File Map

| File | Responsibility |
|---|---|
| `src/shopItems.js` | Create — buy items, forge recipes, definitions |
| `src/persistence.js` | Modify — inventory in save, buy/forge/core functions |
| `src/ShopScreen.jsx` | Create — shop UI with buy/forge tabs |
| `src/styles/shop.css` | Create — shop layout, tabs, item cards |
| `src/BattleScreen.jsx` | Modify — core drops on victory, XP booster effect |
| `src/NavBar.jsx` | Modify — SHOP tab |
| `src/App.jsx` | Modify — shop routing |
| `src/main.jsx` | Modify — import shop.css |

---

## Task 1: Shop Item Definitions

**Files:**
- Create: `src/shopItems.js`

- [ ] **Step 1: Create src/shopItems.js**

```js
export const ELEMENTS_FOR_CORES = ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow'];

export const CORE_DROP_CHANCE = 0.6; // 60% chance per battle win
export const CORE_DOUBLE_CHANCE = 0.2; // 20% chance for 2 cores instead of 1

export const BUY_ITEMS = [
  {
    id: 'xp_booster',
    name: 'XP Booster',
    description: 'Next 3 battles give 2x XP',
    cost: 150,
    icon: '⚡',
    effect: 'xpBoost',
    stackable: true,
  },
  {
    id: 'shiny_charm',
    name: 'Shiny Charm',
    description: 'Upgrade one owned dragon to shiny',
    cost: 500,
    icon: '✨',
    effect: 'shinyUpgrade',
    stackable: false,
    requiresTarget: true,
  },
  {
    id: 'pity_reset',
    name: 'Pity Reset',
    description: 'Next hatchery pull guaranteed Rare+',
    cost: 100,
    icon: '🎯',
    effect: 'pityReset',
    stackable: false,
  },
  {
    id: 'element_reroll',
    name: 'Element Reroll',
    description: 'Re-roll a dragon\'s fused base stats',
    cost: 200,
    icon: '🔄',
    effect: 'reroll',
    stackable: false,
    requiresTarget: true,
    requiresFused: true,
  },
  {
    id: 'data_fragment',
    name: 'Data Fragment',
    description: 'Grants 50 XP to a chosen dragon',
    cost: 50,
    icon: '💎',
    effect: 'grantXp',
    xpAmount: 50,
    stackable: false,
    requiresTarget: true,
  },
];

export const FORGE_RECIPES = [
  {
    id: 'dragon_essence',
    name: 'Dragon Essence',
    description: 'Grants 200 XP to a dragon of the core\'s element',
    cores: { same: 3 }, // 3 of the same element
    scrapsCost: 0,
    icon: '🧬',
    effect: 'grantXpElement',
    xpAmount: 200,
  },
  {
    id: 'stability_matrix',
    name: 'Stability Matrix',
    description: 'Next fusion has +1 stability tier',
    cores: { different: 3 }, // 3 different elements
    scrapsCost: 100,
    icon: '🔮',
    effect: 'stabilityBoost',
  },
  {
    id: 'elder_shard',
    name: 'Elder Shard',
    description: 'Grants 500 XP to any dragon',
    cores: { any: 5 }, // any 5 cores
    scrapsCost: 300,
    icon: '💠',
    effect: 'grantXp',
    xpAmount: 500,
  },
  {
    id: 'void_fragment',
    name: 'Void Fragment',
    description: 'Free Exotic hatchery pull',
    cores: { allSix: true }, // 1 of each of 6 elements
    scrapsCost: 500,
    icon: '🌀',
    effect: 'exoticPull',
  },
];

export function canAffordBuy(item, save) {
  return save.dataScraps >= item.cost;
}

export function canForge(recipe, save) {
  const inv = save.inventory || {};
  const cores = inv.cores || {};

  if (save.dataScraps < recipe.scrapsCost) return false;

  if (recipe.cores.same) {
    return ELEMENTS_FOR_CORES.some(el => (cores[el] || 0) >= recipe.cores.same);
  }
  if (recipe.cores.different) {
    const owned = ELEMENTS_FOR_CORES.filter(el => (cores[el] || 0) >= 1);
    return owned.length >= recipe.cores.different;
  }
  if (recipe.cores.any) {
    const total = ELEMENTS_FOR_CORES.reduce((sum, el) => sum + (cores[el] || 0), 0);
    return total >= recipe.cores.any;
  }
  if (recipe.cores.allSix) {
    return ELEMENTS_FOR_CORES.every(el => (cores[el] || 0) >= 1);
  }
  return false;
}

export function getForgeableElement(recipe, save) {
  if (!recipe.cores.same) return null;
  const cores = save.inventory?.cores || {};
  return ELEMENTS_FOR_CORES.find(el => (cores[el] || 0) >= recipe.cores.same) || null;
}
```

- [ ] **Step 2: Commit**

```bash
git add src/shopItems.js
git commit -m "feat: shop item definitions — buy items, forge recipes, core system

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Persistence — Inventory + Shop Functions

**Files:**
- Modify: `src/persistence.js`

- [ ] **Step 1: Add inventory to DEFAULT_SAVE**

After `singularityComplete: false,` add:

```js
  inventory: { cores: {}, xpBoostBattles: 0, stabilityBoost: false },
```

- [ ] **Step 2: Add migration**

In `migrateSave`, add:

```js
  if (save.inventory === undefined) {
    save.inventory = { cores: {}, xpBoostBattles: 0, stabilityBoost: false };
  }
```

- [ ] **Step 3: Add shop persistence functions**

Add after the singularity functions:

```js
export function addCore(element, count = 1) {
  const save = loadSave();
  if (!save.inventory.cores[element]) save.inventory.cores[element] = 0;
  save.inventory.cores[element] += count;
  writeSave(save);
}

export function spendCores(coreMap) {
  const save = loadSave();
  for (const [el, count] of Object.entries(coreMap)) {
    save.inventory.cores[el] = (save.inventory.cores[el] || 0) - count;
    if (save.inventory.cores[el] <= 0) delete save.inventory.cores[el];
  }
  writeSave(save);
}

export function setXpBoost(battles) {
  const save = loadSave();
  save.inventory.xpBoostBattles = battles;
  writeSave(save);
}

export function decrementXpBoost() {
  const save = loadSave();
  if (save.inventory.xpBoostBattles > 0) {
    save.inventory.xpBoostBattles--;
    writeSave(save);
  }
}

export function setStabilityBoost(value) {
  const save = loadSave();
  save.inventory.stabilityBoost = value;
  writeSave(save);
}
```

- [ ] **Step 4: Commit**

```bash
git add src/persistence.js
git commit -m "feat: inventory persistence — cores, XP boost, stability boost, shop functions

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Shop CSS

**Files:**
- Create: `src/styles/shop.css`
- Modify: `src/main.jsx`

- [ ] **Step 1: Create src/styles/shop.css**

```css
/* === SHOP SCREEN === */

.shop-layout {
  display: flex;
  flex-direction: column;
  height: calc(100vh - 48px);
  padding: 12px;
  padding-top: 48px;
}

.shop-tabs {
  display: flex;
  gap: 4px;
  margin-bottom: 12px;
}

.shop-tab {
  padding: 6px 16px;
  font-family: 'Press Start 2P', monospace;
  font-size: 9px;
  background: #1a1a24;
  color: #666;
  border: 1px solid #333;
  border-radius: 3px 3px 0 0;
  cursor: pointer;
  transition: all 0.15s;
}

.shop-tab.active {
  color: #ff8844;
  border-color: #ff6622;
  border-bottom-color: #1a1a24;
}

.shop-content {
  flex: 1;
  display: flex;
  gap: 12px;
  overflow: hidden;
}

.shop-items {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 8px;
  overflow-y: auto;
  align-content: start;
}

.shop-item-card {
  background: #1a1a24;
  border: 1px solid #333;
  border-radius: 3px;
  padding: 12px;
  cursor: pointer;
  transition: all 0.15s;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.shop-item-card:hover {
  border-color: #555;
}

.shop-item-card.selected {
  border-color: #ff6622;
  box-shadow: 0 0 8px rgba(255, 102, 34, 0.2);
}

.shop-item-card.disabled {
  opacity: 0.4;
  cursor: default;
}

.shop-item-icon {
  font-size: 20px;
  text-align: center;
}

.shop-item-name {
  font-size: 9px;
  line-height: 1.6;
  color: #e0e0e0;
  text-align: center;
}

.shop-item-desc {
  font-size: 7px;
  line-height: 1.8;
  color: #888;
  text-align: center;
}

.shop-item-cost {
  font-size: 8px;
  color: #ffcc00;
  text-align: center;
}

.shop-item-cores {
  font-size: 7px;
  color: #44aaff;
  text-align: center;
}

/* Detail / action panel */
.shop-detail {
  width: 280px;
  background: #1a1a24;
  border: 1px solid #333;
  border-radius: 3px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

.shop-detail-icon {
  font-size: 36px;
}

.shop-detail-name {
  font-size: 12px;
  line-height: 1.6;
  color: #ff8844;
}

.shop-detail-desc {
  font-size: 8px;
  line-height: 2;
  color: #888;
  text-align: center;
}

.shop-buy-btn {
  padding: 8px 20px;
  font-family: 'Press Start 2P', monospace;
  font-size: 9px;
  background: #ff6622;
  color: #fff;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  transition: all 0.15s;
}

.shop-buy-btn:hover {
  background: #ff8844;
  box-shadow: 0 0 10px rgba(255, 102, 34, 0.4);
}

.shop-buy-btn:disabled {
  background: #333;
  color: #555;
  cursor: default;
  box-shadow: none;
}

/* Dragon target picker */
.shop-target-picker {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  justify-content: center;
}

.shop-target-option {
  padding: 3px 8px;
  font-size: 7px;
  background: #111118;
  border: 1px solid #333;
  border-radius: 3px;
  color: #888;
  cursor: pointer;
  transition: all 0.15s;
}

.shop-target-option.selected {
  border-color: #ff6622;
  color: #ff8844;
}

/* Core inventory display */
.shop-cores {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  justify-content: center;
  padding: 8px 0;
}

.shop-core-badge {
  font-size: 8px;
  padding: 3px 8px;
  border: 1px solid #333;
  border-radius: 3px;
  color: #aaa;
  line-height: 1.6;
}

.shop-core-badge.has-cores {
  border-color: #44aaff;
  color: #44aaff;
}

/* Purchase success flash */
.shop-success {
  font-size: 10px;
  color: #44cc44;
  animation: shopSuccessFlash 1.5s ease-out forwards;
}

@keyframes shopSuccessFlash {
  0% { opacity: 1; transform: scale(1); }
  50% { transform: scale(1.1); }
  100% { opacity: 0; transform: scale(1); }
}

@media (max-width: 768px) {
  .shop-content { flex-direction: column; }
  .shop-detail { width: 100%; }
  .shop-items { grid-template-columns: repeat(2, 1fr); }
}
```

- [ ] **Step 2: Add import to main.jsx**

Add after the singularity.css import:

```js
import './styles/shop.css';
```

- [ ] **Step 3: Verify build**

```bash
npm run build
```

- [ ] **Step 4: Commit**

```bash
git add src/styles/shop.css src/main.jsx
git commit -m "feat: shop CSS — item cards, forge grid, tabs, responsive

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: ShopScreen Component

**Files:**
- Create: `src/ShopScreen.jsx`

- [ ] **Step 1: Create src/ShopScreen.jsx**

```jsx
import { useState } from 'react';
import { playSound } from './soundEngine';
import { dragons, elementColors, ELEMENTS } from './gameData';
import { spendScraps, addDragonXp, upgradeDragonShiny, updatePityCounter, setXpBoost, spendCores, setStabilityBoost } from './persistence';
import { BUY_ITEMS, FORGE_RECIPES, canAffordBuy, canForge, getForgeableElement, ELEMENTS_FOR_CORES } from './shopItems';
import NavBar from './NavBar';

export default function ShopScreen({ onNavigate, save, refreshSave }) {
  const [tab, setTab] = useState('buy');
  const [selectedItemId, setSelectedItemId] = useState(null);
  const [targetDragonId, setTargetDragonId] = useState(null);
  const [successMsg, setSuccessMsg] = useState(null);

  const cores = save.inventory?.cores || {};
  const ownedDragons = ELEMENTS.filter(el => save.dragons[el]?.owned);

  const handleBuy = (item) => {
    if (!canAffordBuy(item, save)) return;

    if (item.requiresTarget && !targetDragonId) return;

    playSound('scrapsEarned');
    spendScraps(item.cost);

    switch (item.effect) {
      case 'xpBoost':
        setXpBoost((save.inventory?.xpBoostBattles || 0) + 3);
        break;
      case 'shinyUpgrade':
        if (targetDragonId) upgradeDragonShiny(targetDragonId);
        break;
      case 'pityReset':
        updatePityCounter(9);
        break;
      case 'grantXp':
        if (targetDragonId) addDragonXp(targetDragonId, item.xpAmount);
        break;
      case 'reroll': {
        // Re-roll fused base stats — generate random variation
        if (targetDragonId) {
          const dragon = dragons[targetDragonId];
          const base = save.dragons[targetDragonId].fusedBaseStats || dragon.baseStats;
          const rerolled = {};
          for (const stat of Object.keys(base)) {
            const variance = Math.floor(base[stat] * 0.2);
            rerolled[stat] = base[stat] + Math.floor(Math.random() * variance * 2) - variance;
          }
          // Write via persistence
          const s = JSON.parse(localStorage.getItem('dragonforge_save'));
          s.dragons[targetDragonId].fusedBaseStats = rerolled;
          localStorage.setItem('dragonforge_save', JSON.stringify(s));
        }
        break;
      }
    }

    refreshSave();
    setSuccessMsg(`${item.name} purchased!`);
    setTargetDragonId(null);
    setTimeout(() => setSuccessMsg(null), 1500);
  };

  const handleForge = (recipe) => {
    if (!canForge(recipe, save)) return;

    playSound('fusionBurst');
    spendScraps(recipe.scrapsCost);

    // Consume cores
    const coresToSpend = {};
    if (recipe.cores.same) {
      const el = getForgeableElement(recipe, save);
      if (el) coresToSpend[el] = recipe.cores.same;
    } else if (recipe.cores.different) {
      let count = 0;
      for (const el of ELEMENTS_FOR_CORES) {
        if ((cores[el] || 0) >= 1 && count < recipe.cores.different) {
          coresToSpend[el] = 1;
          count++;
        }
      }
    } else if (recipe.cores.any) {
      let remaining = recipe.cores.any;
      for (const el of ELEMENTS_FOR_CORES) {
        const available = cores[el] || 0;
        const take = Math.min(available, remaining);
        if (take > 0) {
          coresToSpend[el] = take;
          remaining -= take;
        }
        if (remaining <= 0) break;
      }
    } else if (recipe.cores.allSix) {
      for (const el of ELEMENTS_FOR_CORES) {
        coresToSpend[el] = 1;
      }
    }

    spendCores(coresToSpend);

    // Apply effect
    switch (recipe.effect) {
      case 'grantXpElement': {
        const el = getForgeableElement(recipe, save);
        if (el) addDragonXp(el, recipe.xpAmount);
        break;
      }
      case 'grantXp':
        if (targetDragonId) addDragonXp(targetDragonId, recipe.xpAmount);
        break;
      case 'stabilityBoost':
        setStabilityBoost(true);
        break;
      case 'exoticPull':
        // Set pity to max so next pull is guaranteed Rare+, and we'll handle exotic in hatchery
        updatePityCounter(9);
        break;
    }

    refreshSave();
    setSuccessMsg(`${recipe.name} forged!`);
    setTargetDragonId(null);
    setTimeout(() => setSuccessMsg(null), 1500);
  };

  const selectedItem = tab === 'buy'
    ? BUY_ITEMS.find(i => i.id === selectedItemId)
    : FORGE_RECIPES.find(r => r.id === selectedItemId);

  const canAct = tab === 'buy'
    ? selectedItem && canAffordBuy(selectedItem, save) && (!selectedItem.requiresTarget || targetDragonId)
    : selectedItem && canForge(selectedItem, save) && (!selectedItem.effect?.includes('grantXp') || selectedItem.cores.same || targetDragonId);

  return (
    <div>
      <NavBar activeScreen="shop" onNavigate={onNavigate} save={save} />

      <div className="shop-layout">
        {/* Tabs */}
        <div className="shop-tabs">
          <button className={`shop-tab ${tab === 'buy' ? 'active' : ''}`} onClick={() => { setTab('buy'); setSelectedItemId(null); }}>
            BUY
          </button>
          <button className={`shop-tab ${tab === 'forge' ? 'active' : ''}`} onClick={() => { setTab('forge'); setSelectedItemId(null); }}>
            FORGE
          </button>
        </div>

        {/* Core inventory */}
        <div className="shop-cores">
          {ELEMENTS_FOR_CORES.map(el => {
            const count = cores[el] || 0;
            const color = elementColors[el];
            return (
              <div key={el} className={`shop-core-badge ${count > 0 ? 'has-cores' : ''}`} style={{ borderColor: count > 0 ? color.primary : undefined, color: count > 0 ? color.glow : undefined }}>
                {el.toUpperCase()} ×{count}
              </div>
            );
          })}
        </div>

        <div className="shop-content">
          {/* Item grid */}
          <div className="shop-items">
            {(tab === 'buy' ? BUY_ITEMS : FORGE_RECIPES).map(item => {
              const affordable = tab === 'buy' ? canAffordBuy(item, save) : canForge(item, save);
              return (
                <div
                  key={item.id}
                  className={`shop-item-card ${selectedItemId === item.id ? 'selected' : ''} ${!affordable ? 'disabled' : ''}`}
                  onClick={() => { if (affordable) { playSound('buttonClick'); setSelectedItemId(item.id); setTargetDragonId(null); } }}
                  tabIndex={0}
                  role="button"
                  onKeyDown={(e) => { if ((e.key === 'Enter' || e.key === ' ') && affordable) { e.preventDefault(); setSelectedItemId(item.id); } }}
                >
                  <div className="shop-item-icon">{item.icon}</div>
                  <div className="shop-item-name">{item.name}</div>
                  <div className="shop-item-desc">{item.description}</div>
                  {item.cost !== undefined && <div className="shop-item-cost">{item.cost > 0 ? `${item.cost} ◆` : 'FREE'}</div>}
                  {item.scrapsCost !== undefined && item.scrapsCost > 0 && <div className="shop-item-cost">{item.scrapsCost} ◆</div>}
                </div>
              );
            })}
          </div>

          {/* Detail panel */}
          <div className="shop-detail">
            {selectedItem ? (
              <>
                <div className="shop-detail-icon">{selectedItem.icon}</div>
                <div className="shop-detail-name">{selectedItem.name}</div>
                <div className="shop-detail-desc">{selectedItem.description}</div>

                {/* Target picker for items that need it */}
                {selectedItem.requiresTarget && (
                  <div className="shop-target-picker">
                    {ownedDragons
                      .filter(el => !selectedItem.requiresFused || save.dragons[el].fusedBaseStats)
                      .map(el => (
                        <div
                          key={el}
                          className={`shop-target-option ${targetDragonId === el ? 'selected' : ''}`}
                          onClick={() => { playSound('buttonClick'); setTargetDragonId(el); }}
                        >
                          {dragons[el].name}
                        </div>
                      ))}
                  </div>
                )}

                {/* Elder Shard needs target too */}
                {selectedItem.effect === 'grantXp' && !selectedItem.requiresTarget && tab === 'forge' && (
                  <div className="shop-target-picker">
                    {ownedDragons.map(el => (
                      <div
                        key={el}
                        className={`shop-target-option ${targetDragonId === el ? 'selected' : ''}`}
                        onClick={() => { playSound('buttonClick'); setTargetDragonId(el); }}
                      >
                        {dragons[el].name}
                      </div>
                    ))}
                  </div>
                )}

                <button
                  className="shop-buy-btn"
                  disabled={!canAct}
                  onClick={() => tab === 'buy' ? handleBuy(selectedItem) : handleForge(selectedItem)}
                >
                  {tab === 'buy' ? `BUY — ${selectedItem.cost} ◆` : `FORGE${selectedItem.scrapsCost > 0 ? ` — ${selectedItem.scrapsCost} ◆` : ''}`}
                </button>

                {successMsg && <div className="shop-success">{successMsg}</div>}
              </>
            ) : (
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', flex: 1, color: '#444', fontSize: 9, textAlign: 'center', lineHeight: 2 }}>
                Select an item to view details
              </div>
            )}
          </div>
        </div>

        {/* XP Boost status */}
        {save.inventory?.xpBoostBattles > 0 && (
          <div style={{ fontSize: 7, color: '#44cc44', textAlign: 'center', padding: 4 }}>
            ⚡ XP Booster active: {save.inventory.xpBoostBattles} battles remaining
          </div>
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/ShopScreen.jsx
git commit -m "feat: ShopScreen — buy items and forge with cores

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: NavBar + App Routing

**Files:**
- Modify: `src/NavBar.jsx`
- Modify: `src/App.jsx`

- [ ] **Step 1: Add SHOP tab to NavBar**

After the JOURNAL button and before the SINGULARITY button, add:

```jsx
        <button
          className={`nav-tab ${activeScreen === 'shop' ? 'active' : ''}`}
          onClick={() => onNavigate('shop')}
        >
          SHOP
        </button>
```

- [ ] **Step 2: Update App.jsx**

Add import:
```js
import ShopScreen from './ShopScreen';
```

Add to SCREENS:
```js
  SHOP: 'shop',
```

Add to handleNavigate after journal case:
```js
    } else if (target === 'shop') {
      playMusic('hatchery');
      setScreen(SCREENS.SHOP);
    }
```

Add render in JSX after JournalScreen block:
```jsx
      {screen === SCREENS.SHOP && (
        <ShopScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
      )}
```

- [ ] **Step 3: Verify build**

```bash
npm run build
```

- [ ] **Step 4: Commit**

```bash
git add src/NavBar.jsx src/App.jsx
git commit -m "feat: SHOP tab in NavBar + App routing

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: BattleScreen — Core Drops + XP Boost

**Files:**
- Modify: `src/BattleScreen.jsx`

- [ ] **Step 1: Add imports**

Add to persistence imports:
```js
import { loadSave, saveDragonProgress, addScraps, recordNpcDefeat, recordSingularityDefeat, markSingularityComplete, addCore, decrementXpBoost } from './persistence';
```

Add:
```js
import { CORE_DROP_CHANCE, CORE_DOUBLE_CHANCE } from './shopItems';
```

- [ ] **Step 2: Add core drop and XP boost to victory handler**

In `handleMoveSelect`, find the victory block where `xpGained` is calculated (the `calculateXpGain` call). After calculating `xpGained`, add XP boost check:

```js
        let xpGained = calculateXpGain(state.npc.baseXP || 50, state.playerLevel, state.npc.level);
        if (save.inventory?.xpBoostBattles > 0) {
          xpGained *= 2;
          decrementXpBoost();
        }
```

After the `refreshSave()` call in the victory block, add core drops:

```js
        // Core drops
        const npcElement = state.npc.element;
        if (Math.random() < CORE_DROP_CHANCE) {
          const coreCount = Math.random() < CORE_DOUBLE_CHANCE ? 2 : 1;
          addCore(npcElement, coreCount);
        }
```

- [ ] **Step 3: Verify build and tests**

```bash
npm test
npm run build
```

- [ ] **Step 4: Commit**

```bash
git add src/BattleScreen.jsx
git commit -m "feat: core drops on battle victory + XP booster effect

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Final Verification

- [ ] **Step 1: Run tests and build**

```bash
npm test
npm run build
```

- [ ] **Step 2: Manual playthrough**

- SHOP tab visible in NavBar
- BUY tab: shows 5 items with costs, can purchase with DataScraps
- FORGE tab: shows 4 recipes with core costs
- Win a battle — core drops appear in inventory
- XP Booster doubles XP for next 3 battles
- Shiny Charm upgrades target dragon
- Push

- [ ] **Step 3: Push**

```bash
git push origin master
```
