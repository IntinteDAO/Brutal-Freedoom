version "4.10"

// -----------------------------------------------------------------
// PHYSICAL SHELL CASINGS & SMOKE
// -----------------------------------------------------------------

class BF_CasingBase : Actor
{
    Default
    {
        Radius 2;
        Height 2;
        Speed 7;
        +MISSILE
        +NOBLOCKMAP
        +MOVEWITHSECTOR
        +THRUACTORS
        +BOUNCEONFLOORS
        +BOUNCEONCEILINGS
        +BOUNCEONWALLS
        BounceType "Doom";
        BounceFactor 0.52;
        WallBounceFactor 0.48;
        BounceCount 3;
        Gravity 0.85;
        Mass 1;
        Scale 0.85;
    }

    int lifeSpan;

    override void Tick()
    {
        Super.Tick();
        if (Pos.Z <= FloorZ + 1.0 || InStateSequence(CurState, FindState("Death")))
        {
            lifeSpan++;
            // Fade out after ~15 seconds (525 tics)
            if (lifeSpan > 525)
            {
                A_FadeOut(0.05);
            }
        }
    }
}

class BF_PistolCasing : BF_CasingBase
{
    Default
    {
        Scale 0.75;
    }

    States
    {
    Spawn:
        CASN ABCD 2;
        Loop;
    Death:
        CASN C 0
        {
            A_StartSound("weapons/casingtink", CHAN_AUTO, 0, 0.45);
            bBounceOnFloors = false;
            bBounceOnWalls = false;
        }
        CASN C -1;
        Stop;
    }
}

class BF_RifleCasing : BF_CasingBase
{
    Default
    {
        Scale 0.95;
    }

    States
    {
    Spawn:
        CASN ABCD 2;
        Loop;
    Death:
        CASN C 0
        {
            A_StartSound("weapons/casingtink", CHAN_AUTO, 0, 0.40);
            bBounceOnFloors = false;
            bBounceOnWalls = false;
        }
        CASN C -1;
        Stop;
    }
}

class BF_ShotgunCasing : BF_CasingBase
{
    Default
    {
        Scale 1.1;
    }

    States
    {
    Spawn:
        SRED ABCD 2;
        Loop;
    Death:
        SRED C 0
        {
            A_StartSound("weapons/shelldrop", CHAN_AUTO, 0, 0.55);
            bBounceOnFloors = false;
            bBounceOnWalls = false;
        }
        SRED C -1;
        Stop;
    }
}

class BF_MuzzleSmoke : Actor
{
    Default
    {
        Radius 2;
        Height 2;
        +NOBLOCKMAP
        +NOGRAVITY
        +NOTELEPORT
        +FORCEXYBILLBOARD
        RenderStyle "Translucent";
        Alpha 0.40;
        Scale 0.55;
    }

    States
    {
    Spawn:
        SMOK A 2 { A_FadeOut(0.05); Vel.Z += 0.25; }
        SMOK B 2 { A_FadeOut(0.08); Vel.Z += 0.35; }
        SMOK C 2 { A_FadeOut(0.12); Vel.Z += 0.40; }
        SMOK D 2 { A_FadeOut(0.15); Vel.Z += 0.40; }
        Stop;
    }
}

// -----------------------------------------------------------------
// RECOIL TRACKER & WEAPON PHYSICS
// -----------------------------------------------------------------

class BF_RecoilTracker : Inventory
{
    Default
    {
        Inventory.MaxAmount 1;
        +INVENTORY.UNDROPPABLE
        +INVENTORY.UNTOSSABLE
    }

    class<Weapon> lastWeaponClass;
    int lastAmmoAmount;
    double targetRecoveryPitch;
    int recoilHoldTics;
    double wepKickY;

    override void DoEffect()
    {
        Super.DoEffect();

        PlayerPawn pawn = PlayerPawn(Owner);
        if (!pawn || !pawn.player)
        {
            return;
        }

        // 1. Weapon Sprite Kick Recovery
        let wepPsp = pawn.player.FindPSprite(PSP_WEAPON);
        if (wepPsp)
        {
            if (wepKickY > 0.5)
            {
                wepPsp.y = 32 + wepKickY;
                wepKickY *= 0.65;
            }
            else if (wepKickY > 0)
            {
                wepKickY = 0;
                wepPsp.y = 32;
            }
        }

        // 2. Camera Roll (Tilt) Recovery
        if (abs(pawn.Roll) > 0.05)
        {
            pawn.A_SetRoll(pawn.Roll * 0.70, SPF_INTERPOLATE);
        }
        else if (pawn.Roll != 0)
        {
            pawn.A_SetRoll(0, SPF_INTERPOLATE);
        }

        // 3. Camera Pitch Recovery (with peak hold)
        if (recoilHoldTics > 0)
        {
            recoilHoldTics--;
        }
        else if (targetRecoveryPitch > 0.05)
        {
            double step = min(targetRecoveryPitch * 0.28, 0.65);
            pawn.A_SetPitch(pawn.Pitch + step, SPF_FORCECLAMP | SPF_INTERPOLATE);
            targetRecoveryPitch -= step;
        }
        else
        {
            targetRecoveryPitch = 0.0;
        }

        // 4. Weapon Shot Detection
        Weapon wep = pawn.player.ReadyWeapon;
        if (!wep)
        {
            lastWeaponClass = null;
            lastAmmoAmount = 0;
            return;
        }

        int curAmmo = wep.Ammo1 ? wep.Ammo1.Amount : 0;
        class<Weapon> curClass = wep.GetClass();

        // If weapon just changed, synchronize ammo count without firing
        if (curClass != lastWeaponClass)
        {
            lastWeaponClass = curClass;
            lastAmmoAmount = curAmmo;
            return;
        }

        // If ammo was consumed, a shot was fired!
        if (curAmmo < lastAmmoAmount)
        {
            int spent = lastAmmoAmount - curAmmo;
            ApplyWeaponPhysics(pawn, wep, spent);
        }

        lastAmmoAmount = curAmmo;
    }

    private void ApplyWeaponPhysics(PlayerPawn pawn, Weapon wep, int spent)
    {
        double kick = 0.0;
        double rollKick = 0.0;
        double wepKick = 0.0;

        double ang = pawn.Angle;
        Vector3 spawnPos = pawn.Vec3Angle(18.0, ang - 35.0, pawn.Height * 0.62);
        Vector3 ejectVel = (pawn.Vel * 0.4) + AngleToVector(ang - 85.0, 4.5) + (0, 0, 3.2);
        Vector3 muzzlePos = pawn.Vec3Angle(28.0, ang + 4.0, pawn.Height * 0.65);

        if (wep is "SuperShotgun")
        {
            kick = 7.5;
            rollKick = 2.2;
            wepKick = 22.0;
            pawn.A_QuakeEx(3.5, 3.5, 3.5, 6, 0, 128, "", QF_RELATIVE);
            pawn.Vel -= AngleToVector(ang, 3.5);

            SpawnCasing("BF_ShotgunCasing", spawnPos, ejectVel);
            SpawnCasing("BF_ShotgunCasing", spawnPos + (0, 0, 2), ejectVel * 0.85);

            SpawnSmoke(muzzlePos, pawn.Vel);
            SpawnSmoke(muzzlePos + (0, 0, 2), pawn.Vel);
        }
        else if (wep is "Shotgun")
        {
            kick = 4.2;
            rollKick = 1.4;
            wepKick = 14.0;
            pawn.A_QuakeEx(2.0, 2.0, 2.0, 4, 0, 80, "", QF_RELATIVE);

            SpawnCasing("BF_ShotgunCasing", spawnPos, ejectVel);
            SpawnSmoke(muzzlePos, pawn.Vel);
        }
        else if (wep is "Chaingun")
        {
            kick = 1.1;
            rollKick = (Random[BF_Recoil](0, 1) ? 0.4 : -0.4);
            wepKick = 4.0;
            pawn.A_QuakeEx(0.8, 0.8, 0.8, 2, 0, 64, "", QF_RELATIVE);
            pawn.Angle += (Random2[BF_Recoil]() * 0.25 / 255.0);

            SpawnCasing("BF_RifleCasing", spawnPos, ejectVel);
            if (Random[BF_Smoke](0, 1) == 0)
            {
                SpawnSmoke(muzzlePos, pawn.Vel);
            }
        }
        else if (wep is "Pistol")
        {
            kick = 2.4;
            rollKick = (Random[BF_Recoil](0, 1) ? 0.5 : -0.5);
            wepKick = 7.0;

            SpawnCasing("BF_PistolCasing", spawnPos, ejectVel);
            SpawnSmoke(muzzlePos, pawn.Vel);
        }
        else if (wep is "RocketLauncher")
        {
            kick = 5.5;
            rollKick = 1.8;
            wepKick = 16.0;
            pawn.A_QuakeEx(4.0, 4.0, 4.0, 7, 0, 160, "", QF_RELATIVE);
            pawn.Vel -= AngleToVector(ang, 3.8);
            SpawnSmoke(muzzlePos, pawn.Vel);
        }
        else if (wep is "PlasmaRifle")
        {
            kick = 0.75;
            rollKick = (Random[BF_Recoil](0, 1) ? 0.3 : -0.3);
            wepKick = 3.0;
        }

        if (kick > 0.0)
        {
            pawn.A_SetPitch(pawn.Pitch - kick, SPF_FORCECLAMP | SPF_INTERPOLATE);
            if (rollKick != 0.0)
            {
                pawn.A_SetRoll(pawn.Roll + rollKick, SPF_INTERPOLATE);
            }
            targetRecoveryPitch += kick * 0.75;
            recoilHoldTics = 2;
            wepKickY = wepKick;
        }
    }

    private void SpawnCasing(class<Actor> casingType, Vector3 pos, Vector3 vel)
    {
        Actor c = Owner.Spawn(casingType, pos);
        if (c)
        {
            c.Vel = vel + (Random2[BF_Cas]() * 0.003, Random2[BF_Cas]() * 0.003, Random2[BF_Cas]() * 0.003);
            c.target = Owner;
        }
    }

    private void SpawnSmoke(Vector3 pos, Vector3 baseVel)
    {
        Actor s = Owner.Spawn("BF_MuzzleSmoke", pos);
        if (s)
        {
            s.Vel = (baseVel * 0.3) + (Random2[BF_Smk]() * 0.002, Random2[BF_Smk]() * 0.002, 0.3);
        }
    }
}

class BF_RecoilHandler : EventHandler
{
    private void EnsureRecoilTracker(PlayerPawn mo)
    {
        if (mo && !mo.FindInventory("BF_RecoilTracker"))
        {
            mo.GiveInventoryType("BF_RecoilTracker");
        }
    }

    override void PlayerEntered(PlayerEvent e)
    {
        let p = players[e.PlayerNumber];
        if (p && p.mo)
        {
            EnsureRecoilTracker(p.mo);
        }
    }

    override void PlayerRespawned(PlayerEvent e)
    {
        let p = players[e.PlayerNumber];
        if (p && p.mo)
        {
            EnsureRecoilTracker(p.mo);
        }
    }
}
