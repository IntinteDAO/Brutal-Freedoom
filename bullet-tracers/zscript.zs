version "4.10"

// -------------------------------------------------------------
// PHYSICAL BULLET TRACERS (REPLACE HITSCAN WITH 3D PROJECTILES)
// -------------------------------------------------------------

class BF_PlayerTracer : FastProjectile
{
    Default
    {
        Radius 2;
        Height 2;
        Speed 135;
        DamageFunction (Random[BF_Dmg](1, 3) * 5); // Authentic Doom bullet damage
        RenderStyle "Add";
        Alpha 0.95;
        Scale 0.75;
        +MISSILE
        +NOBLOCKMAP
        +FORCEXYBILLBOARD
        SeeSound "";
        DeathSound "";
    }

    States
    {
    Spawn:
        TRCR A 1 Bright;
        Loop;
    Death:
        TNT1 A 0
        {
            Spawn("BulletPuff", Pos);
        }
        Stop;
    }
}

class BF_MonsterTracer : FastProjectile
{
    Default
    {
        Radius 3;
        Height 3;
        Speed 68; // Dodgeable projectile speed! You see the tracer coming and can sidestep!
        DamageFunction (Random[BF_Dmg](1, 3) * 3); // 3 to 9 damage
        RenderStyle "Add";
        Alpha 0.95;
        Scale 0.85;
        +MISSILE
        +NOBLOCKMAP
        +FORCEXYBILLBOARD
        SeeSound "";
        DeathSound "";
    }

    bool playedFlyby;

    override void Tick()
    {
        Super.Tick();

        // Near-miss sound when a bullet snaps close past the player!
        if (!playedFlyby)
        {
            for (int i = 0; i < MAXPLAYERS; i++)
            {
                if (playeringame[i] && players[i].mo && players[i].mo.Health > 0)
                {
                    if (Distance3D(players[i].mo) < 70.0)
                    {
                        playedFlyby = true;
                        A_StartSound("weapons/flyby", CHAN_AUTO, 0, 0.45);
                        break;
                    }
                }
            }
        }
    }

    States
    {
    Spawn:
        MTRC A 1 Bright;
        Loop;
    Death:
        TNT1 A 0
        {
            Spawn("BulletPuff", Pos);
        }
        Stop;
    }
}

// -------------------------------------------------------------
// EVENT HANDLER (INTERCEPT HITSCANS AND SPAWN TRACER PROJECTILES)
// -------------------------------------------------------------

class BF_TracerHandler : EventHandler
{
    override bool WorldHitscanPreFired(WorldEvent e)
    {
        // Never intercept melee attacks (punches, chainsaw, quick-kick, monster bites)
        if (e.AttackLineFlags & LAF_ISMELEEATTACK)
        {
            return false;
        }

        Actor firer = e.Thing;
        if (!firer)
        {
            return false;
        }

        double ang = e.AttackAngle;
        double pitch = e.AttackPitch;

        // Calculate spawn position from firer coordinates
        Vector3 spawnPos = (firer.Pos.X, firer.Pos.Y, firer.Pos.Z + firer.Height * 0.65);
        if (firer.player)
        {
            spawnPos.Z = firer.player.viewz - 4.0;
        }

        // Push forward along firing vector so it clears firer hitbox
        double forwardDist = 18.0;
        spawnPos.X += cos(ang) * cos(pitch) * forwardDist;
        spawnPos.Y += sin(ang) * cos(pitch) * forwardDist;
        spawnPos.Z -= sin(pitch) * forwardDist;

        // Player gunfire (Pistol, Shotgun, SSG, Chaingun)
        if (firer.player)
        {
            Actor tr = firer.Spawn("BF_PlayerTracer", spawnPos);
            if (tr)
            {
                tr.target = firer;
                tr.Angle = ang;
                tr.Pitch = pitch;
                tr.Vel3DFromAngle(tr.Speed, ang, pitch);
            }
            return true; // Cancel instant hitscan!
        }
        // Monster gunfire (Zombieman, Shotgun Guy, Chaingunner, Spider Mastermind)
        else if (firer.bIsMonster)
        {
            Actor tr = firer.Spawn("BF_MonsterTracer", spawnPos);
            if (tr)
            {
                tr.target = firer;
                tr.Angle = ang;
                tr.Pitch = pitch;
                tr.Vel3DFromAngle(tr.Speed, ang, pitch);
            }
            return true; // Cancel instant hitscan!
        }

        return false;
    }
}
