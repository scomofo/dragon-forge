# **🐉 DRAGON FORGE: MASTER TECHNICAL SPECIFICATION**

## **1\. PROJECT OVERVIEW**

* **Concept:** A 16-bit cyber-retro dragon breeding and combat simulator.  
* **Narrative Core:** The player assists **Professor Felix** (mad but benevolent) in stabilizing the Elemental Matrix against **The Singularity**.  
* **Aesthetic:** High-contrast pixel art, charcoal/navy UI (\#111118), 1px black outlines, CRT scanline effects.  
* **Target Stack:** React (Hooks/State), CSS (Pixelated rendering).

## **2\. ASSET ARCHITECTURE & MAPPING**

### **2.1 Battle Arenas (512x256)**

Sprites must be anchored at **y=180px** to align with the perspective lines in the following assets:

| Element | Logic Key | Filename |
| :---- | :---- | :---- |
| **Fire/Magma** | ARENA\_FIRE | magma.jpg |
| **Ice** | ARENA\_ICE | ice.jpg |
| **Static/Lightning** | ARENA\_STORM | lightning.jpg |
| **Stone** | ARENA\_STONE | stone.jpg |
| **Venom/Nature** | ARENA\_VENOM | venom.jpg |
| **Shadow/Void** | ARENA\_SHADOW | shadow.jpg |
| **Null Void** | ARENA\_VOID | shadow.jpg (Filter: grayscale(1) invert(1)) |

### **2.2 Sprite Sheets (2x4 Grid)**

* **Sheet Size:** 1024x1024 total.  
* **Frame Size:** 512px Width x 256px Height.  
* **Animation:** 8-frame loop (Idle: 0-7).  
* **Combat:** Frame 3 is the "Impact/Lunge" frame.

## **3\. CORE SYSTEMS LOGIC**

### **3.1 Quantum Incubation (Gacha)**

* **Rarity Rates:** \* Common (50%): Fire, Ice  
  * Uncommon (30%): Static, Venom, Stone  
  * Rare (15%): Shadow  
  * Exotic (5%): Void  
* **Pity System:** Guarantee a Rare or Exotic unit every 10 pulls. Reset counter to 0 upon any Rare+ pull.  
* **Shiny Protocol:** 2% flat chance per pull. Grant \+20% base stat boost and hue-rotate animation.

### **3.2 Fusion Chamber (Inheritance)**

* **Stat Logic:** Result\_Stat \= ((ParentA \+ ParentB) / 2\) \* 1.1 (10% Fusion Bonus).  
* **Stability Costs:** \* Same Elements: \+25% Stability (Stat Boost).  
  * Opposing Elements (Fire \+ Ice): \-20% Stability (HP Penalty).  
* **Evolution:** Fusing two Stage III adults creates a Stage IV Elder (scale 1.4x, gold drop-shadow).

### **3.3 Combat Engine**

* **Phase Flow:** INIT \-\> TELEGRAPH \-\> IMPACT \-\> RECOIL \-\> RESOLUTION.  
* **Damage Formula:** Damage \= (Atk \* Stage\_Mult \* 2\) \- (Target\_Def \* 0.5).  
* **Stage Multipliers:** I (0.5x), II (0.75x), III (1.0x), IV (1.4x).

## **4\. COMPONENT REQUIREMENTS**

### **TerminalIntro.jsx**

* State-driven typewriter text revealing Professor Felix's "Emergency Broadcast."  
* gameState transition from intro to hatchery via an INITIALIZE\_SIMULATION.EXE button.

### **DragonSprite.jsx**

* Calculates background-position for the 2x4 grid.  
* Handles isShiny (rainbow glow) and isDiscovery (silhouette filter).  
* Responsive scaling based on the Stage prop.

## **5\. CSS UTILITIES (The "Juice")**

/\* Pixel-perfect crisp edges \*/  
.pixelated { image-rendering: pixelated; }

/\* Professor Felix Portrait Frame \*/  
.felix-frame {  
  border: 4px solid \#ffffff;  
  box-shadow: inset \-4px \-4px 0px \#888888;  
  background: \#111118;  
}

/\* Stability Glitch Effect \*/  
.stability-glitch {  
  animation: jitter 0.1s infinite;  
  filter: hue-rotate(90deg) contrast(150%);  
}

## **6\. IMPLEMENTATION TASKS**

1. **Global State:** Use useReducer to track inventory, dataScraps, and singularityPity.  
2. **Asset Linking:** Bridge local .jpg files to the ARENA\_ keys in the logic matrix.  
3. **Hatchery Loop:** Implement the 1x and 10x pull logic with the mathematical pity guard.  
4. **UI Construction:** Build the "Traveler's Journal" (Bestiary) with tab-based navigation.