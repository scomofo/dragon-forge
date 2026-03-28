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
