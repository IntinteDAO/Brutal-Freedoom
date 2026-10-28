version "4.10"

// -------------------------------------------------------------
// HORDE MULTIPLIER & BRUTAL DIFFICULTY SYSTEM
// -------------------------------------------------------------

class BF_HordeHandler : EventHandler
{
    bool isSpawning;

    override void WorldThingSpawned(WorldEvent e)
    {
        if (isSpawning)
        {
            return;
        }

        Actor mo = e.Thing;
        if (!mo || !mo.bIsMonster)
        {
            return;
        }

        // Never duplicate bosses or powerful minibosses!
        if (mo.bBoss || mo is "Cyberdemon" || mo is "SpiderMastermind" || mo is "Archvile" || mo is "BaronOfHell")
        {
            // Boost boss stats slightly on Brutal difficulty without cloning them
            if (skill >= 5)
            {
                mo.Health = int(mo.Health * 1.25);
                mo.Speed *= 1.15;
            }
            return;
        }

        // Active on Brutal difficulty levels (skill >= 5) or when CVAR is enabled
        let cvarHorde = CVar.FindCVar("bf_hordemode");
        bool hordeActive = (skill >= 5) || (cvarHorde && cvarHorde.GetBool());

        if (!hordeActive)
        {
            return;
        }

        // On skill 5 (Brutal Violence): 60% chance to spawn 1 extra monster
        // On skill 6 (Brutal Carnage) or CVAR: spawn 1-2 extra monsters (2-3x horde!)
        int extraCount = 0;
        if (skill >= 6 || (cvarHorde && cvarHorde.GetBool()))
        {
            extraCount = Random[BF_Horde](1, 2);
        }
        else if (skill == 5)
        {
            extraCount = (Random[BF_Horde](0, 100) < 65) ? 1 : 0;
        }

        if (extraCount <= 0)
        {
            return;
        }

        isSpawning = true;
        for (int i = 0; i < extraCount; i++)
        {
            double ang = frandom[BF_Horde](0, 360);
            double dist = frandom[BF_Horde](24.0, 44.0);
            Vector3 newPos = (mo.Pos.X + cos(ang) * dist, mo.Pos.Y + sin(ang) * dist, mo.Pos.Z);

            Actor clone = Actor.Spawn(mo.GetClass(), newPos);
            if (clone)
            {
                clone.Angle = mo.Angle;

                // Validate placement: if inside a wall, try opposite side or discard cleanly
                if (!clone.TestMobjLocation())
                {
                    clone.SetOrigin((mo.Pos.X - cos(ang) * dist, mo.Pos.Y - sin(ang) * dist, mo.Pos.Z), false);
                    if (!clone.TestMobjLocation())
                    {
                        clone.Destroy();
                    }
                }
            }
        }
        isSpawning = false;
    }
}
