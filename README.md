# Brutal Freedoom

A collection of 100% Free and Open Source (FOSS) modular gameplay enhancement mods for **Freedoom** and **GZDoom**.

---

## Available Mods

### 1. `quick-kick`
An off-hand Quick Kick melee attack designed in the visual style of Freedoom Guy:
- **Visuals:** Silver steel armored combat boot with emerald green knee armor and dark rubber tread.
- **Mechanics:** Pushes enemies back, deals melee damage (boosted with Berserk), lowers the ready weapon during the strike, and prevents firing until the kick finishes.
- **Controls:** Default key **`Q`** (customizable in **Options -> Customize Controls -> Brutal Freedoom -> Quick Kick**).

### 2. `ai-mobility`
Aggressive AI overhaul enhancing monster behavior and mobility:
- **Higher Speed & Aggression:** Monsters move 25–50% faster, react instantly (`ReactionTime = 0`), and attack more frequently (`+MISSILEMORE`, `+MISSILEEVENMORE`).
- **Tactical Dodging:** Monsters detect incoming player missiles and perform evasive sideways dashes.
- **Hit Reaction Evasion:** When shot, monsters have a chance to immediately strafe out of the player's crosshair.
- **Leap & Charge Attacks:** Melee monsters (Pinky/Demon/Worm, Spectre, Imp) aggressively leap through the air at the player when within charge distance (creating the perfect opportunity to counter with a Quick Kick!).

---

## Building

A build script is provided to package any mod into a `.pk3` file:

```bash
# Build all mods (outputs to dist/)
./build.sh

# Or build a specific mod
./build.sh quick-kick
./build.sh ai-mobility
```

Packaged `.pk3` files are saved to `dist/`.

---

## Running with GZDoom

Load with your Freedoom IWAD:

```bash
# Run with both mods
gzdoom -iwad freedoom2.wad -file dist/quick-kick.pk3 -file dist/ai-mobility.pk3

# Or during development, load directly from folders
gzdoom -iwad freedoom2.wad -file quick-kick -file ai-mobility
```

---

## License

This project is licensed under the **BSD 3-Clause License** (the same license as Freedoom). See [COPYING.txt](COPYING.txt) for details.
