# Dragon Forge — Individual Sprite Generation Prompts

## How to Use

Copy each prompt into your AI image generator (ChatGPT/DALL-E, Midjourney, etc.). Each prompt is self-contained with all the specifications needed.

**After generating:** Save each image with the exact filename listed. Drop completed files into `handoff/dragons/` (evolution sprites) or `handoff/npc/` (NPC sprites).

---

## Part 1: Dragon Evolution Sprites (24 total)

### Shared Specifications
- Sheet size: 1024 × 1024 pixels
- Grid: 3 columns × 4 rows = 12 frames
- Frame size: 341 × 256 pixels
- Background: Bright green (#00ff00) chroma key
- All dragons face LEFT
- Dragon feet at roughly y=200px (bottom 56px is ground space)
- All 12 frames are subtle idle animation variations (breathing, particles, tail/wing micro-movements)
- Frame 3 (row 1, col 0 of second row) is the lunge/attack frame
- Style: 16-bit pixel art, 1-2px black outlines, bold saturated colors

---

### Fire (Magma Dragon)

**1. `fire_stage1.png` — Baby Magma Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a BABY fire dragon — a small, cute red-orange lizard with ember sparks around its body, a glowing orange belly, stubby limbs, a big head, and tiny wing buds. No full wings. Colors: primary #ff6622, glow #ff8844, dark #cc2200, accent #ffaa00. The dragon faces LEFT in every frame. Each frame shows a slightly different idle pose (breathing motion, ember particles shifting, tail wiggle). The dragon fills about 40-50% of each frame width. Feet positioned at y=200px within each frame.

**2. `fire_stage2.png` — Juvenile Magma Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a JUVENILE fire dragon — medium-sized with growing horns, visible lava cracks across its skin, small flame-like wings beginning to form, and a longer body than the baby. More angular features. Colors: primary #ff6622, glow #ff8844, dark #cc2200, accent #ffaa00. The dragon faces LEFT. Each frame is a subtle idle variation. Fills about 55-65% of frame width. Feet at y=200px.

**3. `fire_stage3.png` — Adult Magma Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a fully grown ADULT fire dragon — large, powerful magma-bodied dragon with full flame wings spread wide, an ember particle trail, molten cracks glowing across its body, sharp horns, and a powerful stance. Colors: primary #ff6622, glow #ff8844, dark #cc2200, accent #ffaa00. Faces LEFT. Each frame is a subtle idle variation (flames flickering, embers drifting). Fills 70-80% of frame width. Feet at y=200px.

**4. `fire_stage4.png` — Elder Magma Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a MASSIVE ELDER fire dragon — ancient and intimidating with volcanic armor plating, erupting flames from its back and shoulders, a molten crown of lava horns, battle scars visible, enormous flame wings, and heavy ember particle effects everywhere. This is the most impressive and detailed fire dragon. Colors: primary #ff6622, glow #ff8844, dark #cc2200, accent #ffaa00. Faces LEFT. Each frame shows subtle idle variations with intense flame effects. Fills 85-95% of frame width. Feet at y=200px.

---

### Ice (Ice Dragon)

**5. `ice_stage1.png` — Baby Ice Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a BABY ice dragon — small, cute white-blue dragon with frost crystals growing on its back, big blue eyes, stubby limbs, a round body, and tiny crystalline wing buds. Frosty breath vapor visible. Colors: primary #44aaff, glow #66ccff, dark #2288cc, accent #cceeff. Faces LEFT. Each frame is a subtle idle variation. Fills 40-50% of frame width. Feet at y=200px.

**6. `ice_stage2.png` — Juvenile Ice Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a JUVENILE ice dragon — medium-sized with ice spines growing along its back, visible frost breath, crystal wings starting to form, and a longer more elegant body. Colors: primary #44aaff, glow #66ccff, dark #2288cc, accent #cceeff. Faces LEFT. Subtle idle variations. Fills 55-65% of frame width. Feet at y=200px.

**7. `ice_stage3.png` — Adult Ice Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a fully grown ADULT ice dragon — elegant crystalline dragon with full translucent ice wings, a frozen aura surrounding it, ice shards along its spine, a blue glow emanating from within, and a regal stance. Colors: primary #44aaff, glow #66ccff, dark #2288cc, accent #cceeff. Faces LEFT. Idle variations with shimmering crystal effects. Fills 70-80% of frame width. Feet at y=200px.

**8. `ice_stage4.png` — Elder Ice Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a MASSIVE ELDER ice dragon — ancient ice beast with glacier-like armor plating, blizzard snow particles swirling around it, a massive crystal crown atop its head, enormous crystalline wings, and an overwhelming frozen aura. The most impressive and detailed ice dragon. Colors: primary #44aaff, glow #66ccff, dark #2288cc, accent #cceeff. Faces LEFT. Idle variations with intense blizzard effects. Fills 85-95% of frame width. Feet at y=200px.

---

### Storm (Storm Dragon)

**9. `storm_stage1.png` — Baby Storm Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a BABY storm dragon — small, energetic purple-yellow dragon with static electric sparks around its body, spiky fur-like texture, big bright eyes, stubby limbs, and tiny crackling wing buds. Colors: primary #aa66ff, glow #cc88ff, dark #6633aa, accent #ffff44. Faces LEFT. Idle variations with sparking effects. Fills 40-50% of frame width. Feet at y=200px.

**10. `storm_stage2.png` — Juvenile Storm Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a JUVENILE storm dragon — medium-sized with visible lightning vein patterns along its body, crackling electric spines along its back, energy wings forming, and a sleek aerodynamic build. Colors: primary #aa66ff, glow #cc88ff, dark #6633aa, accent #ffff44. Faces LEFT. Idle variations. Fills 55-65% of frame width. Feet at y=200px.

**11. `storm_stage3.png` — Adult Storm Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a fully grown ADULT storm dragon — fast, powerful electric dragon with full lightning-bolt wings, a thundercloud aura surrounding it, electric arcs running along its body, and a sleek aggressive stance. Colors: primary #aa66ff, glow #cc88ff, dark #6633aa, accent #ffff44. Faces LEFT. Idle variations with crackling lightning effects. Fills 70-80% of frame width. Feet at y=200px.

**12. `storm_stage4.png` — Elder Storm Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a MASSIVE ELDER storm dragon — the storm incarnate, with constant lightning bolts arcing from its body, a thunderbolt crown of electric horns, enormous crackling wings, an electric trail behind it, and an awe-inspiring presence. The most impressive and detailed storm dragon. Colors: primary #aa66ff, glow #cc88ff, dark #6633aa, accent #ffff44. Faces LEFT. Intense lightning idle variations. Fills 85-95% of frame width. Feet at y=200px.

---

### Stone (Stone Dragon)

**13. `stone_stage1.png` — Baby Stone Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a BABY stone dragon — small, sturdy brown-gray dragon with a pebble-like skin texture, gemstone eyes, a round compact body, stubby thick limbs, and tiny rocky ridges on its back. Colors: primary #aa8844, glow #ccaa66, dark #665533, accent #44dddd. Faces LEFT. Subtle idle variations. Fills 40-50% of frame width. Feet at y=200px.

**14. `stone_stage2.png` — Juvenile Stone Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a JUVENILE stone dragon — medium-sized with rocky armor plates beginning to form on its shoulders and back, small crystal deposits growing, a very sturdy thick build, and a low powerful stance. Colors: primary #aa8844, glow #ccaa66, dark #665533, accent #44dddd. Faces LEFT. Idle variations. Fills 55-65% of frame width. Feet at y=200px.

**15. `stone_stage3.png` — Adult Stone Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a fully grown ADULT stone dragon — heavily armored dragon with boulder-like shoulders, crystal studs covering its body, earth particle effects around its feet, thick powerful limbs, and an immovable fortress-like presence. Colors: primary #aa8844, glow #ccaa66, dark #665533, accent #44dddd. Faces LEFT. Idle variations with dust/earth particle effects. Fills 70-80% of frame width. Feet at y=200px.

**16. `stone_stage4.png` — Elder Stone Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a MASSIVE ELDER stone dragon — a walking mountain, with massive stone plate armor, glowing gem veins running through its body, earthquake cracks forming beneath it, enormous crystal formations on its shoulders and crown, and an absolutely immovable titan presence. The most impressive stone dragon. Colors: primary #aa8844, glow #ccaa66, dark #665533, accent #44dddd. Faces LEFT. Idle variations with glowing veins. Fills 85-95% of frame width. Feet at y=200px.

---

### Venom (Venom Dragon)

**17. `venom_stage1.png` — Baby Venom Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a BABY venom dragon — small green dragon with dripping toxic liquid, bubble-like particles around it, splotchy bright green coloring, a playful but slightly gross appearance, stubby limbs, and tiny toxic spine buds on its back. Colors: primary #44cc44, glow #66ee66, dark #228822, accent #aa44aa. Faces LEFT. Idle variations with bubbling/dripping effects. Fills 40-50% of frame width. Feet at y=200px.

**18. `venom_stage2.png` — Juvenile Venom Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a JUVENILE venom dragon — medium-sized with toxic spines growing along its back, acid drips from its mouth, splotchy camouflage coloring, developing venom sacs visible on its neck, and a sinuous build. Colors: primary #44cc44, glow #66ee66, dark #228822, accent #aa44aa. Faces LEFT. Idle variations with dripping effects. Fills 55-65% of frame width. Feet at y=200px.

**19. `venom_stage3.png` — Adult Venom Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a fully grown ADULT venom dragon — sinuous, dangerous dragon with dripping toxic wings, a toxic cloud aura, large venom sacs, bright green glowing body, acid dripping from claws and mouth, and a menacing coiled stance. Colors: primary #44cc44, glow #66ee66, dark #228822, accent #aa44aa. Faces LEFT. Idle variations with toxic cloud/drip effects. Fills 70-80% of frame width. Feet at y=200px.

**20. `venom_stage4.png` — Elder Venom Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a MASSIVE ELDER venom dragon — an ancient plague dragon with enormous pulsating venom sacs, a corrosive aura that seems to dissolve the air around it, mutated extra spines, dripping toxic wings, a pool of acid forming beneath it, and a terrifyingly toxic presence. The most impressive venom dragon. Colors: primary #44cc44, glow #66ee66, dark #228822, accent #aa44aa. Faces LEFT. Intense toxic idle variations. Fills 85-95% of frame width. Feet at y=200px.

---

### Shadow (Shadow Dragon)

**21. `shadow_stage1.png` — Baby Shadow Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a BABY shadow dragon — small dark purple dragon with wispy smoke-like edges, bright glowing purple eyes, a slightly transparent quality, tiny void particle effects, and an ethereal cute appearance. Colors: primary #8844aa, glow #aa66cc, dark #330044, accent #ff4466. Faces LEFT. Idle variations with wispy shadow effects. Fills 40-50% of frame width. Feet at y=200px.

**22. `shadow_stage2.png` — Juvenile Shadow Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a JUVENILE shadow dragon — medium-sized with shadow tendrils emerging from its body, partially transparent sections, void particles floating around it, developing dark wings with smoky edges, and an increasingly ghostly appearance. Colors: primary #8844aa, glow #aa66cc, dark #330044, accent #ff4466. Faces LEFT. Idle variations with shadow tendril movement. Fills 55-65% of frame width. Feet at y=200px.

**23. `shadow_stage3.png` — Adult Shadow Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a fully grown ADULT shadow dragon — an elegant dark dragon with full shadow wings that have void-energy edges, a ghostly purple aura, reality-distortion effects around its body, glowing eyes, and a mysterious ethereal presence. Colors: primary #8844aa, glow #aa66cc, dark #330044, accent #ff4466. Faces LEFT. Idle variations with shifting shadow effects. Fills 70-80% of frame width. Feet at y=200px.

**24. `shadow_stage4.png` — Elder Shadow Dragon**
> Create a 1024x1024 pixel sprite sheet with a 3x4 grid (12 frames, each 341x256 pixels) on a bright green (#00ff00) background. 16-bit pixel art style with 1-2px black outlines. The subject is a MASSIVE ELDER shadow dragon — the void incarnate, partially transparent with visible reality-warping distortion effects, an enormous dark crown, shadow wings that seem to tear holes in space, intense void particle effects, and an absolutely terrifying otherworldly presence. The most impressive shadow dragon. Colors: primary #8844aa, glow #aa66cc, dark #330044, accent #ff4466. Faces LEFT. Intense shadow/void idle variations. Fills 85-95% of frame width. Feet at y=200px.

---

## Part 2: NPC Sprites (10 total)

### Shared Specifications
- Size: ~512 × 256 pixels (or similar — match existing NPC sprites)
- Background: Transparent (alpha PNG) or green chroma key (#00ff00)
- Style: 16-bit pixel art, 1-2px black outlines, bold saturated colors
- Each NPC needs an idle sprite and an attack sprite
- NPCs face LEFT (code flips when needed)
- Reference existing NPCs in `assets/npc/` for size and style

---

### Buffer Overflow (Fire element — Easy difficulty)

**25. `buffer_overflow_sprites.png` — Idle**
> Create a 512x256 pixel 16-bit pixel art sprite of a "Buffer Overflow" enemy for a cyber-retro dragon game. It should be a bulky, mechanical construct made of overheating circuit boards and melting data chips, with flames and sparks erupting from cracks in its body. Molten orange-red glow from its core. Heavy, slow-looking, and dangerous. Colors: orange #ff6622, red #cc2200, dark metal gray. Bright green (#00ff00) chroma key background. The creature faces LEFT in a standing idle pose. 1-2px black outlines.

**26. `buffer_overflow_attack.png` — Attack**
> Create a 512x256 pixel 16-bit pixel art sprite of a "Buffer Overflow" enemy in an aggressive ATTACK pose — lunging forward with flames erupting from its body, overheating data chips flying off, and a burst of fire energy from its core. Same design as idle but in a dynamic forward-leaning attack stance. Colors: orange #ff6622, red #cc2200, dark metal gray. Bright green (#00ff00) chroma key background. Faces LEFT. 1-2px black outlines.

---

### Crypto Crab (Ice element — Medium difficulty)

**27. `crypto_crab_sprites.png` — Idle**
> Create a 512x256 pixel 16-bit pixel art sprite of a "Crypto Crab" enemy for a cyber-retro dragon game. It should be a crab-like mechanical creature encased in crystalline ice armor, with glowing blue blockchain-pattern circuits on its shell, frozen pincer claws, and frost particles around it. A digital/organic hybrid. Colors: blue #44aaff, cyan #66ccff, dark blue #2288cc, metal gray. Bright green (#00ff00) chroma key background. Faces LEFT in idle pose. 1-2px black outlines.

**28. `crypto_crab_attack.png` — Attack**
> Create a 512x256 pixel 16-bit pixel art sprite of a "Crypto Crab" enemy in an aggressive ATTACK pose — pincers raised and snapping, ice crystals shattering outward, frost beam charging from its mouth. Dynamic forward-lunging stance. Same design as idle. Colors: blue #44aaff, cyan #66ccff. Bright green (#00ff00) background. Faces LEFT. 1-2px black outlines.

---

### Logic Bomb (Fire element — Hard difficulty)

**29. `logic_bomb_sprites.png` — Idle**
> Create a 512x256 pixel 16-bit pixel art sprite of a "Logic Bomb" enemy for a cyber-retro dragon game. It should be a floating spherical bomb-like entity made of compressed data and fire, with a digital countdown display on its surface, orbiting flame rings, glitch artifacts around its edges, and an ominous pulsing red-orange glow. Dangerous and volatile-looking. Colors: orange #ff6622, red #ff4400, yellow #ffaa00. Bright green (#00ff00) chroma key background. Centered, faces LEFT. 1-2px black outlines.

**30. `logic_bomb_attack.png` — Attack**
> Create a 512x256 pixel 16-bit pixel art sprite of a "Logic Bomb" enemy in an ATTACK pose — expanding outward in a fiery explosion, flame rings expanding, digital data fragments exploding outward, intense red-orange glow at peak intensity. Same core design but mid-detonation. Colors: orange #ff6622, red #ff4400, yellow #ffaa00. Bright green (#00ff00) background. 1-2px black outlines.

---

### Phishing Siren (Venom element — Medium difficulty)

**31. `phishing_siren_sprites.png` — Idle**
> Create a 512x256 pixel 16-bit pixel art sprite of a "Phishing Siren" enemy for a cyber-retro dragon game. It should be a serpentine, alluring but dangerous creature — part digital mermaid, part venomous snake — with toxic green scales, dripping acid, a holographic lure dangling from its head (like an anglerfish), glowing hypnotic eyes, and a coiled toxic tail. Deceptive beauty masking poison. Colors: green #44cc44, bright green #66ee66, dark green #228822, purple accent #aa44aa. Bright green (#00ff00) chroma key background. Faces LEFT. 1-2px black outlines.

**32. `phishing_siren_attack.png` — Attack**
> Create a 512x256 pixel 16-bit pixel art sprite of a "Phishing Siren" enemy in an ATTACK pose — lunging forward with mouth wide open spraying toxic acid, venomous tail whipping, holographic lure flashing bright, toxic cloud erupting from its body. Dynamic aggressive stance. Same design. Colors: green #44cc44, bright green #66ee66. Bright green (#00ff00) background. Faces LEFT. 1-2px black outlines.

---

### Protocol Vulture (Shadow element — Boss difficulty)

**33. `protocol_vulture_sprites.png` — Idle**
> Create a 512x256 pixel 16-bit pixel art sprite of a "Protocol Vulture" enemy for a cyber-retro dragon game. It should be a large, menacing vulture-like creature made of dark energy and corrupted data — with enormous tattered shadow wings, void-energy trailing from its feathers, glowing purple eyes, a hooked beak dripping dark matter, skeletal metallic talons, and an aura of digital corruption and decay. A boss-level threat. Colors: dark purple #8844aa, purple glow #aa66cc, very dark #330044, red accent #ff4466. Bright green (#00ff00) chroma key background. Faces LEFT in a perched/ready idle pose. 1-2px black outlines.

**34. `protocol_vulture_attack.png` — Attack**
> Create a 512x256 pixel 16-bit pixel art sprite of a "Protocol Vulture" enemy in an ATTACK pose — wings fully spread and diving forward, shadow energy erupting from its wings, dark matter blasting from its beak, talons extended, void particles exploding outward. Maximum intimidation. Same design. Colors: dark purple #8844aa, purple glow #aa66cc. Bright green (#00ff00) background. Faces LEFT. 1-2px black outlines.

---

## Delivery Checklist

### Dragon Evolution (drop into `handoff/dragons/`):
```
[ ] fire_stage1.png
[ ] fire_stage2.png
[ ] fire_stage3.png
[ ] fire_stage4.png
[ ] ice_stage1.png
[ ] ice_stage2.png
[ ] ice_stage3.png
[ ] ice_stage4.png
[ ] storm_stage1.png
[ ] storm_stage2.png
[ ] storm_stage3.png
[ ] storm_stage4.png
[ ] stone_stage1.png
[ ] stone_stage2.png
[ ] stone_stage3.png
[ ] stone_stage4.png
[ ] venom_stage1.png
[ ] venom_stage2.png
[ ] venom_stage3.png
[ ] venom_stage4.png
[ ] shadow_stage1.png
[ ] shadow_stage2.png
[ ] shadow_stage3.png
[ ] shadow_stage4.png
```

### NPC Sprites (drop into `handoff/npc/`):
```
[ ] buffer_overflow_sprites.png
[ ] buffer_overflow_attack.png
[ ] crypto_crab_sprites.png
[ ] crypto_crab_attack.png
[ ] logic_bomb_sprites.png
[ ] logic_bomb_attack.png
[ ] phishing_siren_sprites.png
[ ] phishing_siren_attack.png
[ ] protocol_vulture_sprites.png
[ ] protocol_vulture_attack.png
```

Once files are in the handoff folders, let me know and I'll integrate them — updating `gameData.js` stageSprites paths and NPC idle/attack sprite references.
