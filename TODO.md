# Dragon Forge — To Do

## Completed
- [x] Intro page: all text repeats — fixed (StrictMode guard)
- [x] Egg animations are janky — fixed (simplified render cycle)
- [x] Fusion screen: dragon tiles off-center — fixed (centered grid)
- [x] VFX impact frames overlay target — fixed (positioned on target side)
- [x] Felix portrait metadata/bg — fixed (object-position + bg color)
- [x] Dragon sizing — fixed (display size increased to 320x250)
- [x] Code review fixes — XP off-by-one, hatchery skip, 7/6 counter, scraps guard, dead code, CSS cleanup

## From Handoff Guides

### Dragon Evolution Sprites (DRAGON_EVOLUTION_SPRITE_GUIDE.md)
- [ ] Generate 24 sprite sheets (6 elements × 4 stages) — Baby, Juvenile, Adult, Elder
- [ ] Integrate per-stage sprites into DragonSprite (code supports stage scaling, needs per-stage sprite paths)
- [ ] Update gameData.js dragons to have per-stage spriteSheet paths instead of single sheet

### New NPCs (in handoff/arenas/)
- [ ] Integrate 5 new NPC enemies: Buffer Overflow, Crypto Crab, Logic Bomb, Phishing Siren, Protocol Vulture
- [ ] Add to gameData.js with stats, moves, difficulty tiers, arenas
- [ ] Add to BattleSelectScreen NPC picker

### Element-Specific Arenas (in handoff/arenas/)
- [ ] Integrate 6 element arenas: fire, ice, storm, stone, venom, shadow
- [ ] Replace NPC-keyed arenas with element-keyed arenas (NPC fights in their element's arena)
- [ ] Copy from handoff/arenas/ to assets/arenas/

### Special Arenas (in handoff/arenas/)
- [ ] Integrate special arenas: asteroid_field, crystal, grave_of_first_dragon, gravity_chamber
- [ ] Design which content uses these (boss fights? special events?)

### Egg Sprites (EGG_SPRITE_GUIDE.md)
- [ ] Egg spritesheet JSON metadata exists in handoff/eggs/ — may need integration
- [ ] Individual egg PNGs available per element — could enhance hatchery reveal

## Art Assets Not Yet Used
- [ ] Gene Scrambler effect (06_11_29 PM) — fusion screen VFX
- [ ] Forge/workshop props (06_43_18 PM) — shop screen items
- [ ] Sci-fi lab equipment (07_08_33 PM) — shop/fusion decoration
- [ ] Dragon Bounties RPG sheet (05_48_15 PM) — character sprites, NPC portraits

## Future Features
- [ ] Shop screen — spend DataScraps on items/boosts (use forge prop art)
- [ ] Responsive design — media queries for mobile/tablet
- [ ] Keyboard navigation / accessibility
- [ ] Split styles.css into per-screen modules
