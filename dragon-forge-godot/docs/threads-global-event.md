# Threads Global Event Handoff

## Role

Threads are Dragon Forge's Pern-inspired disaster event, adapted into the DragonSim Narrative Architecture.

They are not biological spores. They are corrupted execution threads leaking from the Hardware Husk into the simulation when the server overheats and the skybox fails.

Threads represent system entropy: data rot, hardware stress, bad scheduling, and cooling failure made visible.

## Visual Identity

Threads fall from the skybox as jagged silver-white streaks of code.

Up close:

- Flickering binary strings.
- Torn command fragments.
- White-hot script lines with broken syntax.
- Texture-eating static around impact points.

The sky should feel like it is leaking source code.

## Threat Model

Threads cause de-rendering.

- Trees become wireframe.
- Grass loses texture.
- Buildings flicker into low-resolution shells.
- NPCs suffer memory loss, state corruption, or become Null-Pointers.
- Dragons take Corruption / De-rez damage.

Suggested affected variables:

- `texture_fidelity`
- `code_integrity`
- `npc_awareness`
- `sector_integrity`
- `cpu_load`

## Counter-Measure

Dragons char Threads through Thermal Processing.

Magma Dragon breath should not read as ordinary fire here. It is a Data Purge: a high-temperature cleaning pass that incinerates corrupted script before impact.

Other dragon counters:

- Solar Dragon boosts visibility and reveals Thread fall paths early.
- Static Dragon can short-circuit clustered Threads.
- Lunar Dragon can slow Thread motion in local time bubbles.
- Forest Dragon can anchor key assets so they survive partial de-rendering.

## Mission Link

Threads are the vanguard for Mission 11: The Garbage Collector's Cull.

They pre-clear assets before the Deletion Wall arrives. This makes the Deletion Wall feel less sudden and gives players earlier warning that system maintenance has become hostile.

## Thread Mystery

After discovering the unorthodox manual, Skye and Felix realize that Threads are literal execution threads from the real-world server.

The Hardware Husk is leaking background tasks into the simulation because cooling fans are failing and CPU load is spiking.

By fighting Threads, dragons are not merely protecting villages. They are helping the Hardware Husk manage background tasks and avoid a total system crash.

## Audio Direction

World Layer:

- A distant sizzling rain.
- Fine ash-like hiss.
- Tiny impacts like hot sand on leaves.

System Layer:

- High-frequency digital hiss.
- Static-electric crackle.
- Rapid task-scheduler ticks.
- Glitch chirps when a Thread eats texture fidelity.

## Implementation Notes

Threads should be handled as an Environmental Global Event.

Suggested data shape:

```python
THREAD_EVENT = {
    "origin": "Skybox_Leak",
    "cause": "High_CPU_Load",
    "damage_type": "Corruption_DeRez",
    "sfx": "thread_digital_hiss",
    "mission_link": "mission_11_garbage_collectors_cull"
}
```

Suggested gameplay loop:

1. CPU load rises or cooling failure triggers Threadfall.
2. Skybox leak opens above a region.
3. Thread paths telegraph as silver-white streaks.
4. Player uses dragons to char, slow, reveal, or anchor against Threads.
5. Unblocked impacts reduce texture fidelity and sector integrity.
6. Severe impacts create Null-Pointers or pre-clear terrain for the Deletion Wall.

The event should be readable at overworld scale first, then become a battle or flight challenge when Skye engages.
