version "4.10"

// -------------------------------------------------------------
// DYNAMIC BLOOD SPLATTER, WALL DECALS & FLOOR SPLATS
// -------------------------------------------------------------

class BF_FloorBloodSplatter : Actor
{
    Default
    {
        Radius 8;
        Height 2;
        +NOBLOCKMAP
        +NOGRAVITY
        +MOVEWITHSECTOR
        +FLATSPRITE
        RenderStyle "Translucent";
        Alpha 0.95;
    }

    override void BeginPlay()
    {
        Super.BeginPlay();

        // Random 360 degree rotation in floor plane
        Angle = frandom[BF_Bld](0, 360);

        // Random scaling so every splatter looks organic and unique
        double sc = frandom[BF_Bld](0.65, 1.15);
        Scale = (sc, sc);

        // Pick one of 4 jagged, irregular splatter shapes!
        int fr = Random[BF_Bld](0, 3);
        if (fr == 0) SetStateLabel("SplatterA");
        else if (fr == 1) SetStateLabel("SplatterB");
        else if (fr == 2) SetStateLabel("SplatterC");
        else SetStateLabel("SplatterD");
    }

    States
    {
    Spawn:
    SplatterA:
        BSPT A 1200; // Remains on floor for ~35 seconds!
        Goto FadeOut;
    SplatterB:
        BSPT B 1200;
        Goto FadeOut;
    SplatterC:
        BSPT C 1200;
        Goto FadeOut;
    SplatterD:
        BSPT D 1200;
        Goto FadeOut;
    FadeOut:
        "####" "#" 2 A_FadeOut(0.02);
        Loop;
    }
}

class BF_BloodDrop : Actor
{
    Default
    {
        Radius 2;
        Height 2;
        Speed 10;
        +MISSILE
        +NOBLOCKMAP
        +MOVEWITHSECTOR
        +BOUNCEONFLOORS
        +BOUNCEONWALLS
        +THRUACTORS
        BounceType "Doom";
        BounceFactor 0.25;
        WallBounceFactor 0.20;
        BounceCount 2;
        Gravity 0.92;
        Scale 0.85;
        RenderStyle "Translucent";
        Alpha 0.95;
    }

    States
    {
    Spawn:
        BLOD ABCD 2;
        Loop;
    Death:
        TNT1 A 0
        {
            // 1. If hitting near floor: spawn persistent floor splatter
            if (Pos.Z <= FloorZ + 4.0)
            {
                Spawn("BF_FloorBloodSplatter", (Pos.X, Pos.Y, FloorZ + 0.1));
            }

            // 2. Spray wall decal backwards into the surface it struck!
            Vector3 backDir = -Vel;
            if (backDir.Length() > 0.1)
            {
                A_SprayDecal("BloodSplat", 64, (0, 0, 0), backDir);
            }
            else
            {
                A_SprayDecal("BloodSplat", 64);
            }
        }
        Stop;
    }
}

class BF_BloodSplatterHandler : EventHandler
{
    override void WorldThingDamaged(WorldEvent e)
    {
        Actor victim = e.Thing;
        if (!victim || !victim.bIsMonster || victim.bNoBlood)
        {
            return;
        }

        Vector3 hitPos = e.DamagePosition;
        if (hitPos == (0, 0, 0))
        {
            hitPos = (victim.Pos.X, victim.Pos.Y, victim.Pos.Z + victim.Height * 0.6);
        }

        // 1. Audio feedback: juicy flesh impact sound
        if (e.Damage > 6 && Random[BF_Bld](0, 100) < 75)
        {
            victim.A_StartSound("blood/splat", CHAN_AUTO, 0, 0.55);
        }

        // 2. Spray a blood decal on the wall directly behind the victim!
        Vector3 wallRay = (cos(e.DamageAngle), sin(e.DamageAngle), 0);
        victim.A_SprayDecal("BloodSplat", 140, (0, 0, victim.Height * 0.6), wallRay);

        // 3. Dense 3D Particle Blood Mist & Aerosol Spray
        int numParticles = int(clamp(e.Damage * 1.3, 18, 90));
        for (int i = 0; i < numParticles; i++)
        {
            double pAng = e.DamageAngle + frandom[BF_Bld](-38.0, 38.0);
            double pSpeed = frandom[BF_Bld](3.5, 11.5);
            double pVelZ = frandom[BF_Bld](-1.2, 5.5);

            color pCol = (i % 3 == 0) ? "990606" : ((i % 3 == 1) ? "CC0E0E" : "600000");

            victim.A_SpawnParticle(
                pCol,
                0,
                Random[BF_Bld](14, 28),
                frandom[BF_Bld](6.0, 15.0),
                0,
                hitPos.X - victim.Pos.X + frandom[BF_Bld](-2, 2),
                hitPos.Y - victim.Pos.Y + frandom[BF_Bld](-2, 2),
                hitPos.Z - victim.Pos.Z + frandom[BF_Bld](-2, 2),
                cos(pAng) * pSpeed,
                sin(pAng) * pSpeed,
                pVelZ,
                0, 0, -0.42,
                0.95,
                0.038,
                0.35
            );
        }

        // 4. Physical Blood Droplets (fly to walls and paint decals)
        int numDrops = int(clamp(e.Damage / 5.5, 5, 22));
        for (int i = 0; i < numDrops; i++)
        {
            Actor drop = victim.Spawn("BF_BloodDrop", hitPos);
            if (drop)
            {
                double dAng = e.DamageAngle + frandom[BF_Bld](-30.0, 30.0);
                double dSpeed = frandom[BF_Bld](4.5, 10.0);
                drop.Vel = (cos(dAng) * dSpeed, sin(dAng) * dSpeed, frandom[BF_Bld](1.5, 6.0));
            }
        }

        // 5. Spawn an irregular blood splatter on the floor under the victim
        if (e.Damage > 15 && Random[BF_Bld](0, 100) < 65)
        {
            Actor.Spawn("BF_FloorBloodSplatter", (victim.Pos.X + frandom[BF_Bld](-12, 12),
                                                  victim.Pos.Y + frandom[BF_Bld](-12, 12),
                                                  victim.FloorZ + 0.1));
        }
    }

    override void WorldThingDied(WorldEvent e)
    {
        Actor victim = e.Thing;
        if (!victim || !victim.bIsMonster || victim.bNoBlood)
        {
            return;
        }

        Vector3 deadPos = (victim.Pos.X, victim.Pos.Y, victim.Pos.Z + victim.Height * 0.5);

        // Death blood burst
        int deathParticles = (e.Damage > 50) ? 75 : 40;
        for (int i = 0; i < deathParticles; i++)
        {
            double pAng = frandom[BF_Bld](0, 360);
            double pSpeed = frandom[BF_Bld](2.5, 9.0);
            double pVelZ = frandom[BF_Bld](1.5, 7.5);
            color pCol = (i % 3 == 0) ? "990606" : ((i % 3 == 1) ? "CC0E0E" : "600000");

            victim.A_SpawnParticle(
                pCol,
                0,
                Random[BF_Bld](16, 32),
                frandom[BF_Bld](7.0, 16.0),
                0,
                frandom[BF_Bld](-4, 4), frandom[BF_Bld](-4, 4), frandom[BF_Bld](-4, 4),
                cos(pAng) * pSpeed, sin(pAng) * pSpeed, pVelZ,
                0, 0, -0.42,
                0.95,
                0.035,
                0.40
            );
        }

        // Droplets painting surrounding walls
        int deathDrops = (e.Damage > 50) ? 14 : 7;
        for (int i = 0; i < deathDrops; i++)
        {
            Actor drop = victim.Spawn("BF_BloodDrop", deadPos);
            if (drop)
            {
                double dAng = frandom[BF_Bld](0, 360);
                double dSpeed = frandom[BF_Bld](3.5, 9.0);
                drop.Vel = (cos(dAng) * dSpeed, sin(dAng) * dSpeed, frandom[BF_Bld](2.0, 6.5));
            }
        }

        // Persistent irregular floor splatter under dead body
        Actor.Spawn("BF_FloorBloodSplatter", (victim.Pos.X, victim.Pos.Y, victim.FloorZ + 0.1));
    }
}
