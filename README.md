# Brutal Freedoom

A collection of 100% Free and Open Source (FOSS) modular gameplay enhancement mods for **Freedoom** and **GZDoom**.

---

## Available Mods

### 1. `quick-kick`
An off-hand Quick Kick melee attack designed in the visual style of Freedoom Guy:
- **Visuals:** Silver steel armored combat boot with emerald green knee armor and dark rubber tread.
- **Mechanics:** Pushes enemies back, deals melee damage (boosted with Berserk), lowers the ready weapon during the strike, and prevents firing until the kick finishes.
- **Controls:** Default key **`Q`** (customizable in **Options -> Customize Controls -> Brutal Freedoom -> Quick Kick**).

---

## Building

A build script is provided to package any mod into a `.pk3` file:

```bash
# Build all mods (outputs to dist/)
./build.sh

# Or build a specific mod
./build.sh quick-kick
```

Packaged `.pk3` files are saved to `dist/`.

---

## Running with GZDoom

Load with your Freedoom IWAD:

```bash
# Using the built PK3
gzdoom -iwad freedoom2.wad -file dist/quick-kick.pk3

# Or loading the folder directly during development
gzdoom -iwad freedoom2.wad -file quick-kick
```

---

## License

This project is licensed under the **BSD 3-Clause License** (the same license as Freedoom). See [COPYING.txt](COPYING.txt) for details.
