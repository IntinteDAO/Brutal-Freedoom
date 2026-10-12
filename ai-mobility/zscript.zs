version "4.10"

class BF_MonsterAI : Inventory
{
    Default
    {
        Inventory.MaxAmount 1;
        +INVENTORY.UNDROPPABLE
        +INVENTORY.UNTOSSABLE
    }

    int dodgeCooldown;
    int leapCooldown;

    override void DoEffect()
    {
        Super.DoEffect();

        Actor mo = Owner;
        if (!mo || mo.Health <= 0 || !mo.bIsMonster)
        {
            return;
        }

        if (dodgeCooldown > 0) dodgeCooldown--;
        if (leapCooldown > 0) leapCooldown--;

        Actor target = mo.target;
        if (!target || target.Health <= 0)
        {
            return;
        }

        // 1. MELEE LEAP / CHARGE ATTACK (Pinky/Demon/Worm, Spectre, Imp)
        // Aggressive lunge at player from medium distance
        if (leapCooldown <= 0 && mo.Pos.Z <= mo.FloorZ + 2.0)
        {
            double dist = mo.Distance2D(target);
            if (dist >= 110.0 && dist <= 270.0 && mo.CheckSight(target))
            {
                bool isMelee = (mo is "Demon" || mo is "Spectre" || mo is "DoomImp");
                if (isMelee && Random[BF_AI](0, 100) < 32)
                {
                    double ang = mo.AngleTo(target);
                    mo.Angle = ang;
                    double leapSpeed = 14.5;
                    mo.Vel.X = cos(ang) * leapSpeed;
                    mo.Vel.Y = sin(ang) * leapSpeed;
                    mo.Vel.Z = 4.8;

                    // Play aggression sound
                    if (mo.AttackSound)
                    {
                        mo.A_StartSound(mo.AttackSound, CHAN_VOICE);
                    }
                    else if (mo.SeeSound)
                    {
                        mo.A_StartSound(mo.SeeSound, CHAN_VOICE);
                    }

                    leapCooldown = 70; // ~2.0s cooldown
                    return;
                }
            }
        }

        // 2. PROJECTILE DETECTION & TACTICAL EVASION
        // Senses incoming player rockets, plasma, and projectiles
        if (dodgeCooldown <= 0)
        {
            BlockThingsIterator it = BlockThingsIterator.Create(mo, 230.0);
            while (it.Next())
            {
                Actor th = it.thing;
                if (th && th.bMissile && th.target != mo && th.Vel.Length() > 5.0)
                {
                    Vector3 toMo = mo.Pos - th.Pos;
                    // Check if missile is heading towards the monster
                    if (th.Vel.X * toMo.X + th.Vel.Y * toMo.Y > 0)
                    {
                        double dodgeAngle = mo.Angle + (Random[BF_AI](0, 1) ? 90.0 : -90.0);
                        double dodgeForce = 9.0;
                        mo.Vel.X += cos(dodgeAngle) * dodgeForce;
                        mo.Vel.Y += sin(dodgeAngle) * dodgeForce;
                        dodgeCooldown = 45; // ~1.3s cooldown
                        break;
                    }
                }
            }
        }
    }
}

class BF_AIHandler : EventHandler
{
    override void WorldThingSpawned(WorldEvent e)
    {
        Actor mo = e.Thing;
        if (!mo || !mo.bIsMonster)
        {
            return;
        }

        // Higher aggression and immediate responsiveness
        mo.bMissileMore = true;
        mo.bMissileEvenMore = true;
        mo.bQuickToRetaliate = true;
        mo.ReactionTime = 0;

        // Tuned Brutal speed scaling across monster classes
        if (mo is "Demon" || mo is "Spectre")
        {
            mo.Speed *= 1.50; // Terrifyingly fast melee chaser
        }
        else if (mo is "DoomImp")
        {
            mo.Speed *= 1.35; // Agile jumper and flanker
        }
        else if (mo is "ZombieMan" || mo is "ShotgunGuy" || mo is "ChaingunGuy")
        {
            mo.Speed *= 1.30; // Mobile military hit-and-run
        }
        else if (mo is "Cacodemon" || mo is "LostSoul")
        {
            mo.Speed *= 1.25;
            mo.FloatSpeed *= 1.25;
        }
        else
        {
            mo.Speed *= 1.20;
        }

        // Attach lightweight AI thinker
        if (!mo.FindInventory("BF_MonsterAI"))
        {
            mo.GiveInventoryType("BF_MonsterAI");
        }
    }

    override void WorldThingDamaged(WorldEvent e)
    {
        Actor mo = e.Thing;
        if (!mo || !mo.bIsMonster || mo.Health <= 0)
        {
            return;
        }

        // When shot by player, 40% chance to immediately dodge sideways
        if (e.DamageSource && e.DamageSource.player && Random[BF_AI](0, 100) < 40)
        {
            let ai = BF_MonsterAI(mo.FindInventory("BF_MonsterAI"));
            if (ai && ai.dodgeCooldown <= 0)
            {
                double dodgeAngle = mo.Angle + (Random[BF_AI](0, 1) ? 90.0 : -90.0);
                double dodgeForce = 7.5;
                mo.Vel.X += cos(dodgeAngle) * dodgeForce;
                mo.Vel.Y += sin(dodgeAngle) * dodgeForce;
                ai.dodgeCooldown = 35; // ~1s cooldown
            }
        }
    }
}
