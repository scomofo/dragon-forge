# Arena & Forge Background — Art Generation Brief

## Status

| Asset | Status | Current | File |
|-------|--------|---------|------|
| magma (fire) arena | ✅ Done 1024×1024 | — | `assets/arenas/magma.png` |
| lightning (storm) arena | ✅ Done 1024×1024 | — | `assets/arenas/lightning.png` |
| gravity_chamber (final boss) | ⚠️ 696×344 placeholder | — | `assets/arenas/gravity_chamber.png` |
| ice arena | ⚠️ 352×150 placeholder | — | `assets/arenas/ice.png` |
| shadow arena | ⚠️ 704×333 placeholder | — | `assets/arenas/shadow.png` |
| stone arena | ⚠️ 352×150 placeholder | — | `assets/arenas/stone.png` |
| storm arena | ⚠️ 352×150 placeholder | — | `assets/arenas/storm.png` |
| venom arena | ⚠️ 352×150 placeholder | — | `assets/arenas/venom.png` |
| npc_firewall_sentinel | ⚠️ 352×150 placeholder | Stone dungeon, 404 terminal, blue electric arcs | `assets/arenas/npc_firewall_sentinel.png` |
| npc_bit_wraith | ⚠️ 352×150 placeholder | Matrix void, green cascading code, DELete cubes | `assets/arenas/npc_bit_wraith.png` |
| npc_glitch_hydra | ⚠️ 352×150 placeholder | Corrupted stone temple, venom-green glow | `assets/arenas/npc_glitch_hydra.png` |
| npc_recursive_golem | ⚠️ 352×150 placeholder | Stone dungeon with circuit floor and lightning | `assets/arenas/npc_recursive_golem.png` |
| npc_buffer_overflow | ⚠️ 352×150 placeholder | Lava chamber, black platforms, fire barrel | `assets/arenas/npc_buffer_overflow.png` |
| npc_crypto_crab | ⚠️ 352×150 placeholder | Icy cave with frozen server racks | `assets/arenas/npc_crypto_crab.png` |
| npc_logic_bomb | ⚠️ 352×150 placeholder | Steampunk clock-gear workshop | `assets/arenas/npc_logic_bomb.png` |
| npc_phishing_siren | ⚠️ 352×150 placeholder | Deep sea hypno-spiral, grid floor, coral | `assets/arenas/npc_phishing_siren.png` |
| npc_protocol_vulture | ⚠️ 352×150 placeholder | Dark aircraft carrier deck, purple neon, storm clouds | `assets/arenas/npc_protocol_vulture.png` |
| forge_bg | ❌ Missing | CSS-only, no image | `assets/backgrounds/forge_bg.png` (new) |

---

## Shared Specs for All Arena Images

- **Size:** 1024×1024 pixels
- **Style:** 16-bit pixel art, high contrast, bold colours, 1-2px black outlines on all solid elements
- **Perspective:** Interior battlefield — flat ground plane occupies the bottom ~30% of the image; mid-ground scenery in the middle 40%; atmospheric ceiling/sky fills the top 30%
- **No characters or dragons.** Environment only.
- **No text labels or title overlays.** Clean background only.
- **Lighting:** Each arena has a primary light source that casts dramatic shadows. Pick one colour as the dominant glow.

---

## Element Arenas (generic backgrounds, used across battles)

### Ice Arena — `assets/arenas/ice.png`

> 1024×1024 pixel art battle arena. An ancient underground ice cave. The floor is polished glacier-blue ice with deep fracture cracks glowing from within (#44aaff). Enormous stalactites hang from the vaulted ceiling; frozen server towers and data stacks are encased in translucent ice along the walls. The rear wall is a solid wall of ice with blue-white glowing circuitry frozen inside it. The ground reflects everything above, creating a mirror-floor effect. Scattered ice shards on the floor catch light. Colour palette: #cceeff (bright ice), #44aaff (arc blue), #2266aa (deep ice), #0a1a2e (void shadow), #ffffff (specular). 16-bit pixel art style. No characters.

### Shadow Arena — `assets/arenas/shadow.png`

> 1024×1024 pixel art battle arena. A corrupted void dimension. The floor is cracked black stone with purple energy leaking through the cracks (#6600cc). Tall fractured pillars line the sides, their surfaces glitching with purple-black static. The background wall is a massive render-tear — the fabric of the digital world peeling away to reveal swirling void underneath. Floating corrupted data-shards hover in the mid-ground. Colour palette: #08000f (deepest void), #1a003a (dark purple), #6600cc (corruption purple), #9933ff (active glitch), #220055 (shadow stone). 16-bit pixel art. No characters.

### Stone Arena — `assets/arenas/stone.png`

> 1024×1024 pixel art battle arena. An ancient underground bunker with circuit-board stone floors. Cracked stone tiles with embedded blue circuit traces cover the ground; the patterns glow faintly where current still flows. Collapsed stone columns stand either side; the rear wall is massive hewn rock with carved rune-like server-rack symbols. Fracture lines in the wall emit blue-white electric sparks. The ceiling is vaulted stone with hanging cable bundles. Colour palette: #1a1410 (dark stone), #2a2418 (mid stone), #3c3020 (floor), #4488cc (circuit glow), #aaccff (spark white). 16-bit pixel art. No characters.

### Storm Arena — `assets/arenas/storm.png`

> 1024×1024 pixel art battle arena. A shattered floating platform above a storm layer. The floor is broken dark stone tiles hovering in mid-air with gaps showing storm clouds below. Constant branching lightning bolts in electric blue and violet arc across the background. The sky is purple-black storm clouds lit from within by lightning. Rain streaks across the scene at an angle. Crackling electricity pools along the platform edges. Colour palette: #0a0a1f (void sky), #1a1040 (storm purple), #7b5fff (electric violet), #44ccff (arc blue), #2a2a4a (storm stone), #ffffff (lightning white). 16-bit pixel art. No characters.

### Venom Arena — `assets/arenas/venom.png`

> 1024×1024 pixel art battle arena. A corrupted jungle temple overrun by toxic vines and glitching data corruption. Stone temple floor covered in luminous green toxic puddles (#33ff66). Ancient stone walls are cracked and overgrown with neon-green vines that pulse with data-corruption glow. Hanging tendrils of toxic plant matter frame the sides. The rear wall is a stone archway filled with a glowing venom-green void. Spore particles drift upward from the floor. Colour palette: #0a1a08 (deep jungle), #1a2a10 (mid green), #2a4a18 (wall stone), #33ff66 (toxic glow), #66cc44 (venom mid). 16-bit pixel art. No characters.

---

## NPC Arenas (preserve the theme of the current placeholder)

### Firewall Sentinel — `assets/arenas/npc_firewall_sentinel.png`
*Theme: Stone dungeon hallway, 404 error terminal, electric blue arcs — the firewall's last checkpoint*

> 1024×1024 pixel art battle arena. A stone dungeon corridor, the last checkpoint of a crashed firewall. The floor is rough flagstone with electric-blue circuit traces glowing in the cracks. The rear wall has a large embedded terminal screen displaying "404 ERROR" in blocky pixel font, framed by flickering blue electricity. Stone archway columns line the sides with blue energy conduits running up them. Particle sparks fall from the ceiling where the firewall is burning out. Colour palette: #181818 (dungeon black), #2a2a2a (stone grey), #1a2a40 (deep blue), #3366ff (arc blue), #88aaff (spark blue), #ffffff (electric white). 16-bit pixel art style. No characters, no text except "404 ERROR" on the terminal screen.

### Bit Wraith — `assets/arenas/npc_bit_wraith.png`
*Theme: Matrix void — digital cyberspace with cascading green code rain, floating corrupted cubes*

> 1024×1024 pixel art battle arena. A deep cyberspace void — a digital dimension the Bit Wraith inhabits. The floor is a translucent dark grid on black, with neon-green (#00ff44) glowing grid lines. Tall floating data-cubes drift in the mid-ground, their surfaces showing corrupted text ("DEL", "NULL", "0x00"). Behind them, cascading columns of green binary rain fall from the top of the image. The background is pure black with distant green data-stream lines. Colour palette: #000000 (void), #001a08 (dark green shadow), #003010 (mid green), #00ff44 (neon data), #44ff88 (highlight), #0a4020 (cube surface). 16-bit pixel art style. No characters.

### Glitch Hydra — `assets/arenas/npc_glitch_hydra.png`
*Theme: Corrupted stone temple, venom-green glitch corruption spreading across ancient ruins*

> 1024×1024 pixel art battle arena. An ancient stone temple that has been consumed by digital glitch corruption. Stone temple floor — cracked tiles covered in venom-green toxic glitch slime (#44ff44). Stone pillars on the sides have chunks corrupted — replaced by glitching pixel blocks in neon green and black. Vines of corrupted data (rendered as twisted neon strands) grow from the floor cracks. The rear archway door pulses with unstable green-black energy. Corrupted terminal panels hang from the walls, screens showing static. Colour palette: #0a1a08 (deep temple), #1a2a10 (stone), #2a1a00 (ancient stone), #44ff44 (glitch green), #88ff66 (venom mid), #000000 (glitch void). 16-bit pixel art. No characters.

### Recursive Golem — `assets/arenas/npc_recursive_golem.png`
*Theme: Stone dungeon with circuit floor — the golem's construction chamber, electric arcs in the walls*

> 1024×1024 pixel art battle arena. The Recursive Golem's construction chamber — a massive stone dungeon where ancient technology and rock meet. The floor is cracked stone with glowing blue circuit-board patterns beneath the surface, as if the dungeon is built on living machinery. Fractured stone columns stand at the sides with blue lightning arcing between them at mid-height. The rear wall is a massive relief of stacked stone blocks with circuit conduits running between them, sparking at junctions. Scattered stone rubble on the floor. Colour palette: #1a1208 (dark stone), #2a1e10 (mid stone), #3a2a18 (floor), #2255aa (circuit blue), #66aaff (arc blue), #ffffff (spark). 16-bit pixel art. No characters.

### Buffer Overflow — `assets/arenas/npc_buffer_overflow.png`
*Theme: Lava forge chamber — black stone platforms over rivers of lava, fire barrel centrepiece*

> 1024×1024 pixel art battle arena. A volcanic lava chamber where memory has overflowed into fire. The floor is black stone platforms floating above channels of flowing lava (#ff6600, #ff3300). Cracks in the stone glow orange-red with lava underneath. A large industrial fire barrel sits at the rear centre, blazing flames reaching upward. Stone walls are scorched black; ember particles drift upward. The ceiling is soot-covered with glowing orange heat. Colour palette: #0a0500 (soot black), #1a0800 (dark stone), #ff3300 (lava red), #ff6600 (lava orange), #ffcc00 (fire yellow), #330000 (shadow). 16-bit pixel art. No characters.

### Crypto Crab — `assets/arenas/npc_crypto_crab.png`
*Theme: Icy server cave — frozen server towers trapped in glacier, crystal cave ceiling*

> 1024×1024 pixel art battle arena. An arctic data vault — a natural ice cave where server infrastructure has been frozen solid. The floor is polished ice with hairline cracks. Tall server rack towers stand at the sides, encased from floor up in solid glacier-blue ice (#66ccff), their rack lights still blinking dimly through the ice. The ceiling is a natural cave with stalactites and an ice-blue glow. The rear wall is a wall of packed ice with server hardware frozen inside it. Icy mist hovers near the floor. Colour palette: #0a1520 (deep ice), #1a2a3a (cave shadow), #2255aa (ice blue), #66ccff (glacier), #aaddff (bright ice), #ffffff (frost glint). 16-bit pixel art. No characters.

### Logic Bomb — `assets/arenas/npc_logic_bomb.png`
*Theme: Steampunk clockwork workshop — massive golden gears, ticking clock face, brass machinery*

> 1024×1024 pixel art battle arena. A steampunk clockwork chamber where logic has been wound into mechanical inevitability. The floor is dark brass-grated metal plating. An enormous clock face dominates the rear wall — cracked glass face with golden hands pointing to midnight. Massive interlocking gear wheels (brass, copper #cc8833) fill the sides and ceiling, slowly turning. Steam vents at the floor level emit white puffs. Hanging pendulums and cable chains frame the mid-ground. Colour palette: #1a1008 (dark workshop), #2a1a0a (wood/iron floor), #cc8833 (brass), #ffaa44 (gold), #884422 (copper rust), #ffffff (steam). 16-bit pixel art. No characters.

### Phishing Siren — `assets/arenas/npc_phishing_siren.png`
*Theme: Deep sea hypno-realm — giant spiral vortex, luminous coral, grid-floor, psychedelic deep sea*

> 1024×1024 pixel art battle arena. A digital deep-sea realm where the Phishing Siren lures victims. The floor is a neon-green grid (#00ff88) receding into the distance with perspective lines converging at the rear. In the background, two enormous concentric spiral vortexes in neon green and teal rotate slowly, creating a hypnotic focal point. Luminous coral formations and digital sea-plants grow from the floor edges. Bioluminescent particles drift upward. The overall palette is dark deep-ocean with neon accents. Colour palette: #000a0f (deep ocean void), #001a10 (dark teal), #003322 (mid sea), #00ff88 (neon teal), #00cc66 (coral glow), #44ffcc (particle). 16-bit pixel art. No characters.

### Protocol Vulture — `assets/arenas/npc_protocol_vulture.png`
*Theme: Shadow aircraft carrier deck — dark airship hull, purple neon trim, storm clouds, void sky*

> 1024×1024 pixel art battle arena. The top deck of a vast shadow airship cutting through storm clouds. The floor is dark metallic hull plating — dark grey panels with purple neon trim lines (#9933ff) running along joints and edges. The rear of the deck curves upward into the ship's superstructure, a looming dark silhouette. Storm clouds fill the background sky — dark grey-purple, lit from below by the ship's running lights. The horizon glows faint purple. Distant void-black sky above. Colour palette: #080810 (night sky), #101018 (hull black), #1a1a2a (deck metal), #9933ff (purple neon), #6600cc (deep violet), #ccaaff (distant light). 16-bit pixel art. No characters.

---

## Gravity Chamber — `assets/arenas/gravity_chamber.png` (upgrade from 696×344)

> 1024×1024 pixel art battle arena. A zero-gravity singularity containment chamber. The floor is chrome-dark metal panels with glowing purple seams (#9933ff) that create a receding grid. The walls and ceiling curve away suggesting a vast cubic void. Floating debris — shattered circuits, fractured stone chunks, broken server blades — drift in suspension. A massive singularity rift tears through the rear centre: a swirling void of deep blue-black with violet-white corona. Pulsing purple energy rings expand outward from the rift. Colour palette: #08050f (deep void), #1a0a2e (purple-black), #9933ff (singularity), #4400cc (deep violet), #44aaff (energy arc), #222233 (chrome panel). 16-bit pixel art. No characters.

---

## Forge Background — `assets/backgrounds/forge_bg.png` (new)

**CSS integration** (once generated, update `src/styles/forge.css` line 10):
```css
.forge-screen {
  background:
    linear-gradient(180deg, rgba(26,18,8,0.78) 0%, rgba(42,29,20,0.65) 60%, rgba(58,42,31,0.60) 100%),
    url('/assets/backgrounds/forge_bg.png') center / cover no-repeat;
}
```

> 1024×1024 pixel art interior background. The interior of Felix's Forge — a sci-fi underground blacksmith workshop fused with dragon-tech. The rear wall is rough stone with embedded circuit-board patterns glowing faintly orange (#ff5a1f). A massive stone anvil silhouette dominates the left background, underlit by ember orange from below. The floor is dark metal plate with a subtle grid. The ceiling has exposed cable bundles running wall-to-wall, and conduit pipes with small gauge lights. Scattered forge equipment: cable-wrapped columns, glowing canisters, a workbench with dragon-tech tools. The right side has a jagged render-breach (a rough diagonal tear in the wall showing a jungle glimpse behind it — green beyond the dark). Colour palette: #0a0804 (floor black), #1a1208 (wall dark), #2a1d14 (mid brown), #3a2a1f (warm stone), #ff5a1f (ember orange glow), #5edcff (console cyan accent), #5cff8a (console green accent). 16-bit pixel art style, no characters.

---

## How to integrate

1. Generate each image at 1024×1024 using the prompt above
2. Save with the exact filename listed in the Status table
3. Drop into `assets/arenas/` (or `assets/backgrounds/` for the forge)
4. No code changes needed for any arena — they're already wired
5. For the forge background only: apply the CSS snippet above to `src/styles/forge.css`
