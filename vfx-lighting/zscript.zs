version "4.10"

// -------------------------------------------------------------
// DYNAMIC SPARKS & WALL DEBRIS
// -------------------------------------------------------------

class BF_Spark : Actor
{
    Default
    {
        Radius 2;
        Height 2;
        Speed 10;
        +MISSILE
        +NOBLOCKMAP
        +MOVEWITHSECTOR
        +THRUACTORS
        +BOUNCEONFLOORS
        +BOUNCEONWALLS
        BounceType "Doom";
        BounceFactor 0.65;
        WallBounceFactor 0.60;
        BounceCount 3;
        Gravity 0.85;
        Mass 1;
        RenderStyle "Add";
        Alpha 0.95;
        Scale 0.65;
    }

    int lifeTics;

    override void Tick()
    {
        Super.Tick();
        lifeTics++;
        if (lifeTics > 8)
        {
            A_FadeOut(0.12);
        }
    }

    States
    {
    Spawn:
        SPK1 ABCD 1 Bright;
        Loop;
    Death:
        SPK1 D 1 Bright A_FadeOut(0.2);
        Stop;
    }
}

class BF_WallDebris : Actor
{
    Default
    {
        Radius 2;
        Height 2;
        Speed 5;
        +MISSILE
        +NOBLOCKMAP
        +MOVEWITHSECTOR
        +THRUACTORS
        +BOUNCEONFLOORS
        +BOUNCEONWALLS
        BounceType "Doom";
        BounceFactor 0.40;
        WallBounceFactor 0.35;
        BounceCount 2;
        Gravity 0.90;
        Mass 1;
        Scale 0.70;
    }

    int lifeTics;

    override void Tick()
    {
        Super.Tick();
        lifeTics++;
        if (lifeTics > 55)
        {
            A_FadeOut(0.10);
        }
    }

    States
    {
    Spawn:
        DEBR ABCD 2;
        Loop;
    Death:
        DEBR A 1;
        Stop;
    }
}

class BF_RicochetPuff : BulletPuff
{
    Default
    {
        +NOBLOCKMAP
        +NOGRAVITY
        +ALWAYSPUFF
        +PUFFONACTORS
        VSpeed 1.0;
    }

    override void BeginPlay()
    {
        Super.BeginPlay();

        // Play occasional ricochet ping sound (32% chance)
        if (Random[BF_VFX](0, 100) < 32)
        {
            A_StartSound("weapons/ricochet", CHAN_AUTO, 0, 0.45);
        }

        // Shower of glowing bouncing sparks
        int numSparks = Random[BF_VFX](4, 7);
        for (int i = 0; i < numSparks; i++)
        {
            Actor spk = Spawn("BF_Spark", Pos);
            if (spk)
            {
                double spkAng = frandom[BF_VFX](0, 360);
                double spkSpeed = frandom[BF_VFX](4.0, 10.0);
                spk.Vel = (cos(spkAng) * spkSpeed, sin(spkAng) * spkSpeed, frandom[BF_VFX](2.0, 6.5));
            }
        }

        // Chipped concrete / mortar debris
        for (int i = 0; i < 3; i++)
        {
            Actor deb = Spawn("BF_WallDebris", Pos);
            if (deb)
            {
                double debAng = frandom[BF_VFX](0, 360);
                double debSpeed = frandom[BF_VFX](2.0, 5.5);
                deb.Vel = (cos(debAng) * debSpeed, sin(debAng) * debSpeed, frandom[BF_VFX](1.5, 4.5));
            }
        }
    }
}

// -------------------------------------------------------------
// VOLUMETRIC 3D PARTICLE EXPLOSIONS (NO 2D SPRITES!)
// -------------------------------------------------------------

class BF_ExplosionFX : Actor
{
    Default
    {
        Radius 4;
        Height 4;
        +NOBLOCKMAP
        +NOGRAVITY
        +NOTELEPORT
    }

    override void BeginPlay()
    {
        Super.BeginPlay();

        // 1. Core fireball sphere: fast, glowing 3D flame particles (NO SPRITES!)
        for (int i = 0; i < 95; i++)
        {
            double theta = frandom[BF_Exp](0, 360);
            double phi = frandom[BF_Exp](-85, 85);
            double spd = frandom[BF_Exp](3.5, 12.0);

            double vx = cos(phi) * cos(theta) * spd;
            double vy = cos(phi) * sin(theta) * spd;
            double vz = sin(phi) * spd;

            color pCol = (i < 30) ? "FFFFFF" : ((i < 65) ? "FFDD33" : "FF5511");
            int pLife = Random[BF_Exp](14, 28);
            double pSize = frandom[BF_Exp](12.0, 26.0);

            A_SpawnParticle(
                pCol,
                SPF_FULLBRIGHT,
                pLife,
                pSize,
                0,
                0, 0, 0,
                vx, vy, vz,
                -vx * 0.04, -vy * 0.04, -vz * 0.04 + 0.15,
                1.0,
                0.038,
                1.3
            );
        }

        // 2. Billowing rising dark smoke cloud
        for (int i = 0; i < 55; i++)
        {
            double theta = frandom[BF_Exp](0, 360);
            double spd = frandom[BF_Exp](1.5, 6.0);
            double vx = cos(theta) * spd;
            double vy = sin(theta) * spd;
            double vz = frandom[BF_Exp](2.2, 7.0);

            color sCol = (Random[BF_Exp](0, 1) == 0) ? "444444" : "222222";
            int sLife = Random[BF_Exp](35, 65);
            double sSize = frandom[BF_Exp](18.0, 35.0);

            A_SpawnParticle(
                sCol,
                0,
                sLife,
                sSize,
                0,
                0, 0, 4.0,
                vx, vy, vz,
                -vx * 0.03, -vy * 0.03, 0.14,
                0.80,
                0.015,
                1.9
            );
        }

        // 3. Glowing burning shrapnel / sparks flying in 3D
        int numSparks = Random[BF_Exp](18, 28);
        for (int i = 0; i < numSparks; i++)
        {
            Actor spk = Spawn("BF_Spark", Pos + (0, 0, 8));
            if (spk)
            {
                double sAng = frandom[BF_Exp](0, 360);
                double sSpd = frandom[BF_Exp](7.0, 17.0);
                spk.Vel = (cos(sAng) * sSpd, sin(sAng) * sSpd, frandom[BF_Exp](3.0, 13.0));
            }
        }

        // 4. Concrete and metal fragments flying out
        for (int i = 0; i < 8; i++)
        {
            Actor deb = Spawn("BF_WallDebris", Pos + (0, 0, 8));
            if (deb)
            {
                double dAng = frandom[BF_Exp](0, 360);
                double dSpd = frandom[BF_Exp](4.0, 11.0);
                deb.Vel = (cos(dAng) * dSpd, sin(dAng) * dSpd, frandom[BF_Exp](2.0, 8.5));
            }
        }

        // 5. Heavy camera shockwave
        A_QuakeEx(4.5, 4.5, 4.5, 8, 0, 300, "", QF_RELATIVE);
    }

    States
    {
    Spawn:
        TNT1 A 65;
        Stop;
    }
}

// -------------------------------------------------------------
// ROCKET WITHOUT 2D SPRITE EXPLOSION
// -------------------------------------------------------------

class BF_Rocket : Rocket
{
    States
    {
    Death:
        TNT1 A 0
        {
            A_Explode();
            A_StartSound("weapons/rocklx", CHAN_AUTO);
            Spawn("BF_ExplosionFX", Pos);
        }
        TNT1 A 2;
        Stop;
    }
}

// -------------------------------------------------------------
// EXPLOSIVE BARREL WITHOUT 2D SPRITE EXPLOSION
// -------------------------------------------------------------

class BF_ExplosiveBarrel : ExplosiveBarrel
{
    States
    {
    Death:
        TNT1 A 0
        {
            A_Scream();
            A_Explode();
            Spawn("BF_ExplosionFX", Pos + (0, 0, 16));
        }
        TNT1 A 2;
        Stop;
    }
}

// -------------------------------------------------------------
// VOLUMETRIC IMP / SERPENTIPEDE 3D FIREBALL (NO 2D SPRITES!)
// -------------------------------------------------------------

class BF_ImpFireball : DoomImpBall
{
    override void Tick()
    {
        Super.Tick();

        // While in flight, render 3D fire & smoke particles!
        if (Pos.Z > FloorZ && !InStateSequence(CurState, FindState("Death")))
        {
            // Core flame particles (3D spherical fire)
            for (int i = 0; i < 5; i++)
            {
                double pAng = frandom[BF_ImpF](0, 360);
                double pRad = frandom[BF_ImpF](1.0, 5.0);
                double pZ = frandom[BF_ImpF](-3.0, 3.0);
                color pCol = (i < 2) ? "FFFFFF" : ((i < 4) ? "FFDD33" : "FF5511");

                A_SpawnParticle(
                    pCol,
                    SPF_FULLBRIGHT,
                    Random[BF_ImpF](5, 10),
                    frandom[BF_ImpF](7.0, 13.0),
                    0,
                    cos(pAng) * pRad, sin(pAng) * pRad, pZ,
                    -Vel.X * 0.12 + frandom[BF_ImpF](-0.5, 0.5),
                    -Vel.Y * 0.12 + frandom[BF_ImpF](-0.5, 0.5),
                    -Vel.Z * 0.12 + frandom[BF_ImpF](-0.2, 0.6),
                    0, 0, 0.05,
                    1.0,
                    0.09,
                    0.4
                );
            }

            // Drifting smoke trail
            if (Random[BF_ImpF](0, 1) == 0)
            {
                A_SpawnParticle(
                    "333333",
                    0,
                    Random[BF_ImpF](14, 24),
                    frandom[BF_ImpF](8.0, 15.0),
                    0,
                    frandom[BF_ImpF](-3, 3), frandom[BF_ImpF](-3, 3), frandom[BF_ImpF](-2, 2),
                    -Vel.X * 0.18, -Vel.Y * 0.18, 0.2,
                    0, 0, 0.08,
                    0.55,
                    0.035,
                    0.7
                );
            }
        }
    }

    States
    {
    Spawn:
        BAL1 AB 4 Bright;
        Loop;
    Death:
        TNT1 A 0
        {
            A_StartSound("imp/shotx", CHAN_AUTO);

            // Volumetric impact explosion particles & sparks!
            for (int i = 0; i < 35; i++)
            {
                double theta = frandom[BF_ImpF](0, 360);
                double phi = frandom[BF_ImpF](-80, 80);
                double spd = frandom[BF_ImpF](2.0, 7.5);
                double vx = cos(phi) * cos(theta) * spd;
                double vy = cos(phi) * sin(theta) * spd;
                double vz = sin(phi) * spd;
                color pCol = (i < 12) ? "FFFFFF" : ((i < 24) ? "FFDD44" : "FF4411");

                A_SpawnParticle(
                    pCol,
                    SPF_FULLBRIGHT,
                    Random[BF_ImpF](10, 20),
                    frandom[BF_ImpF](8.0, 16.0),
                    0,
                    0, 0, 0,
                    vx, vy, vz,
                    -vx * 0.05, -vy * 0.05, -vz * 0.05 + 0.1,
                    1.0,
                    0.05,
                    0.8
                );
            }

            // Flying fiery sparks
            for (int i = 0; i < 6; i++)
            {
                Actor spk = Spawn("BF_Spark", Pos);
                if (spk)
                {
                    double sAng = frandom[BF_ImpF](0, 360);
                    double sSpd = frandom[BF_ImpF](3.0, 8.0);
                    spk.Vel = (cos(sAng) * sSpd, sin(sAng) * sSpd, frandom[BF_ImpF](1.5, 6.0));
                }
            }
        }
        BAL1 CDE 4 Bright;
        Stop;
    }
}

// -------------------------------------------------------------
// EVENT HANDLER (REPLACE BULLETPUFF, ROCKET, BARREL & IMPBALL)
// -------------------------------------------------------------

class BF_VFXHandler : EventHandler
{
    override void CheckReplacement(ReplaceEvent e)
    {
        if (e.Replacee == "BulletPuff")
        {
            e.Replacement = "BF_RicochetPuff";
        }
        else if (e.Replacee == "Rocket")
        {
            e.Replacement = "BF_Rocket";
        }
        else if (e.Replacee == "ExplosiveBarrel")
        {
            e.Replacement = "BF_ExplosiveBarrel";
        }
        else if (e.Replacee == "DoomImpBall")
        {
            e.Replacement = "BF_ImpFireball";
        }
    }
}
