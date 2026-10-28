version "4.10"

// -------------------------------------------------------------
// DYNAMIC CAMERA ROLL / STRAFE TILT
// -------------------------------------------------------------

class BF_CameraTiltTracker : Inventory
{
    Default
    {
        Inventory.MaxAmount 1;
        +INVENTORY.UNDROPPABLE
        +INVENTORY.UNTOSSABLE
    }

    double currentRoll;

    override void DoEffect()
    {
        Super.DoEffect();

        PlayerPawn pawn = PlayerPawn(Owner);
        if (!pawn || !pawn.player || pawn.Health <= 0)
        {
            return;
        }

        PlayerInfo p = pawn.player;

        // Dynamic Camera Roll (Strafe Tilt)
        // Tilts camera smoothly when strafing left (A) or right (D)
        double targetRoll = 0.0;
        if (p.cmd.sidemove < -100 || (p.cmd.buttons & BT_MOVELEFT))
        {
            targetRoll -= 2.4;
        }
        else if (p.cmd.sidemove > 100 || (p.cmd.buttons & BT_MOVERIGHT))
        {
            targetRoll += 2.4;
        }

        // Springy smooth interpolation
        currentRoll += (targetRoll - currentRoll) * 0.22;
        if (abs(currentRoll - targetRoll) < 0.05 && targetRoll == 0.0)
        {
            currentRoll = 0.0;
        }

        pawn.A_SetRoll(currentRoll, SPF_INTERPOLATE);
    }
}

class BF_CameraTiltHandler : EventHandler
{
    private void EnsureTracker(PlayerPawn mo)
    {
        if (mo && !mo.FindInventory("BF_CameraTiltTracker"))
        {
            mo.GiveInventoryType("BF_CameraTiltTracker");
        }
    }

    override void PlayerEntered(PlayerEvent e)
    {
        let p = players[e.PlayerNumber];
        if (p && p.mo)
        {
            EnsureTracker(p.mo);
        }
    }

    override void PlayerRespawned(PlayerEvent e)
    {
        let p = players[e.PlayerNumber];
        if (p && p.mo)
        {
            EnsureTracker(p.mo);
        }
    }
}
