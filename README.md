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

### 3. `recoil-physics`
Visceral weapon recoil and physical brass casing system:
- **Camera Recoil & Peak Hold:** Punchy vertical kick with momentary peak hold and springy recovery (calibrated per weapon from Pistol up to Super Shotgun).
- **Camera Roll & Shake:** Subtle camera tilts and screen shakes on heavy discharges.
- **Weapon Sprite Kickback:** The weapon in the player's hands physically jerks back and springs forward upon firing.
- **3D Brass Casings & Shells:** Fully simulated bouncing brass casings (Pistol/Chaingun) and red 12-gauge shotgun shells (with dual ejection on SSG), complete with metallic bounce audio.
- **Muzzle Smoke:** Translucent powder smoke puffs drifting from the barrel after each shot.

### 4. `vfx-lighting`
Real-time dynamic lights and volumetric particle effects:
- **Real-Time Dynamic Lighting (GLDEFS):** Weapon muzzle flashes light up dark corridors with warm, realistic light; flying projectiles and explosions dynamically illuminate surrounding architecture.
- **Ricochet Sparks & Wall Debris:** Bullets striking solid walls produce a shower of glowing 3D bouncing sparks, chipped concrete fragments, and ricochet pings.
- **Volumetric 3D Explosions (No 2D Sprites):** Rocket and explosive barrel detonations replace flat 2D billboard sprites with an expanding 3D spherical fireball, billowing rising smoke, burning shrapnel, and heavy shockwaves.
- **Enhanced Fireballs:** Imp / Serpentipede fireballs feature a blazing core enhanced with dynamic 3D flame particles, smoke trails, and a volumetric impact blast.

### 5. `weapon-zoom`
Tactical Aim-Down-Sights (ADS) optical zoom for firearms:
- **Optical Zoom (1.35x):** Hold Right Mouse Button (Mouse 2) with firearms (Pistol, Shotguns, Chaingun, Plasma) for smooth optical magnification.
- **Automatic Sensitivity Scaling:** Mouse sensitivity scales down smoothly with the zoom factor for steady aim at long distances.
- **Clean Input Integration:** Non-zooming heavy weapons (Rocket Launcher, BFG9000) are never blocked by Right Mouse Button.
- **Audio Feedback:** Subtle tactical mechanical clicks and fabric rustles on aim-in and aim-out (`weapons/aimin` and `weapons/aimout`).

### 6. `bullet-tracers`
Physical bullet projectile system replacing instant hitscans:
- **Visible Bullet Tracers:** Eliminates invisible instant hitscans; bullets fly as high-velocity glowing tracer streaks with dynamic real-time lighting in flight.
- **Player Gunfire:** Pistol, Chaingun, and Shotguns fire blazing golden tracers (`Speed 135`) that produce ricochets and sparks on impact.
- **Dodgeable Monster Gunfire:** Zombie soldiers, Shotgun Guys, and Chaingunners fire visible orange-red projectiles (`Speed 68`). You can see incoming rounds coming down corridors and actively sidestep or take cover!
- **Supersonic Flyby Audio:** Bullets whipping past the player's head produce realistic near-miss flyby cracks (`weapons/flyby`).

### 7. `camera-tilt`
Kinetic camera roll during player movement:
- **Strafe Tilt:** Camera smoothly and springily tilts 2.4° in the direction of movement when strafing left (`A`) or right (`D`).
- **Smooth Recovery:** Softly returns to level upon releasing the strafe keys, adding weight and momentum to movement without interfering with aiming or crouching.

### 8. `blood-splatter`
Directional blood spray and persistent environmental gore:
- **Directional 3D Blood Spray:** Gunfire impacts eject a dense cloud of crimson blood mist behind the target along the trajectory of the bullet.
- **Persistent Wall Decals:** Droplets striking walls paint permanent, irregular blood decals (`BloodSplat`) on surfaces behind enemies.
- **Jagged Floor Splatters:** Blood landing on the floor forms organic, jagged, starburst splats randomly rotated 360° that persist on the ground.
- **Death Blood Geyser:** Slaying monsters triggers a violent fountain of blood and splatter covering surrounding walls and floors.
- **Flesh Impact Audio:** Crisp, wet flesh impact squelches (`blood/splat`) on hit.

---

## Building

A build script is provided to package any mod into a `.pk3` file:

```bash
# Build all mods (outputs to dist/)
./build.sh

# Or build a specific mod
./build.sh quick-kick
./build.sh ai-mobility
./build.sh recoil-physics
./build.sh vfx-lighting
./build.sh weapon-zoom
./build.sh bullet-tracers
./build.sh camera-tilt
./build.sh blood-splatter
```

Packaged `.pk3` files are saved to `dist/`.

---

## Running with GZDoom

Load with your Freedoom IWAD:

```bash
# Run with all modules
gzdoom -iwad freedoom2.wad \
    -file dist/quick-kick.pk3 \
    -file dist/ai-mobility.pk3 \
    -file dist/recoil-physics.pk3 \
    -file dist/vfx-lighting.pk3 \
    -file dist/weapon-zoom.pk3 \
    -file dist/bullet-tracers.pk3 \
    -file dist/camera-tilt.pk3 \
    -file dist/blood-splatter.pk3

# Or during development, load directly from folders
gzdoom -iwad freedoom2.wad \
    -file quick-kick \
    -file ai-mobility \
    -file recoil-physics \
    -file vfx-lighting \
    -file weapon-zoom \
    -file bullet-tracers \
    -file camera-tilt \
    -file blood-splatter
```

---

## License

This project is licensed under the **BSD 3-Clause License** (the same license as Freedoom). See [COPYING.txt](COPYING.txt) for details.
