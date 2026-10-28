version "4.10"

// -------------------------------------------------------------
// AUTO-SHOOTING / SMART TARGETING (CROSSHAIR-ON-ENEMY AUTO-FIRE)
// -------------------------------------------------------------

class BF_AutoShootToken : Inventory
{
    Default
    {
        Inventory.MaxAmount 1;
        +INVENTORY.UNDROPPABLE
        +INVENTORY.UNTOSSABLE
    }

    bool isEnabled;

    override void PostBeginPlay()
    {
        Super.PostBeginPlay();
        isEnabled = true; // Enabled by default
    }
}

class BF_AutoShootHandler : EventHandler
{
    private BF_AutoShootToken EnsureToken(PlayerPawn mo)
    {
        if (!mo)
        {
            return null;
        }
        let token = BF_AutoShootToken(mo.FindInventory("BF_AutoShootToken"));
        if (!token)
        {
            token = BF_AutoShootToken(mo.GiveInventoryType("BF_AutoShootToken"));
        }
        return token;
    }

    override void PlayerEntered(PlayerEvent e)
    {
        let p = players[e.PlayerNumber];
        if (p && p.mo)
        {
            let token = EnsureToken(p.mo);
            if (token && token.isEnabled)
            {
                p.mo.A_PrintBold("Auto-Shooting: ENABLED (Press H to toggle)", 3);
            }
        }
    }

    override void PlayerRespawned(PlayerEvent e)
    {
        let p = players[e.PlayerNumber];
        if (p && p.mo)
        {
            EnsureToken(p.mo);
        }
    }

    override void NetworkProcess(ConsoleEvent e)
    {
        if (e.Name ~== "BF_ToggleAutoShoot")
        {
            PlayerInfo p = players[e.Player];
            if (p && p.mo)
            {
                let token = EnsureToken(p.mo);
                if (token)
                {
                    token.isEnabled = !token.isEnabled;
                    if (token.isEnabled)
                    {
                        Console.Printf("\cd[Auto-Shooting: \cdENABLED\c-]");
                        p.mo.A_PrintBold("Auto-Shooting: ENABLED", 2);
                        p.mo.A_StartSound("weapons/aimin", CHAN_AUTO, 0, 0.6);
                    }
                    else
                    {
                        Console.Printf("\cg[Auto-Shooting: \cgDISABLED\c-]");
                        p.mo.A_PrintBold("Auto-Shooting: DISABLED", 2);
                        p.mo.A_StartSound("weapons/aimout", CHAN_AUTO, 0, 0.6);
                    }
                }
            }
        }
    }

    override void WorldTick()
    {
        for (int i = 0; i < MAXPLAYERS; i++)
        {
            if (!playeringame[i] || !players[i].mo || players[i].mo.Health <= 0)
            {
                continue;
            }

            PlayerInfo p = players[i];
            PlayerPawn pawn = p.mo;
            Weapon wep = p.ReadyWeapon;

            if (!wep)
            {
                continue;
            }

            let token = EnsureToken(pawn);
            if (!token || !token.isEnabled)
            {
                continue;
            }

            // Crosshair targeting:
            // 1. Direct bullet slope targeting used by GZDoom weapons
            FTranslatedLineTarget t;
            pawn.BulletSlope(t);

            // 2. If center slope didn't hit, check 3D crosshair cone with forced check
            if (!t.linetarget)
            {
                pawn.AimLineAttack(pawn.Angle, 1800.0, t, 4.0, ALF_CHECK3D | ALF_NOWEAPONCHECK);
            }

            // If a living, visible monster is locked under the crosshair -> FIRE DIRECTLY!
            if (t.linetarget && t.linetarget.bIsMonster && t.linetarget.Health > 0 && pawn.CheckSight(t.linetarget))
            {
                // Safety check: do not suicide with rocket launcher at point-blank range!
                if (wep is "RocketLauncher" && pawn.Distance2D(t.linetarget) < 195.0)
                {
                    continue;
                }

                // If weapon is in ready state, fire weapon directly!
                if (p.WeaponState & WF_WEAPONREADY)
                {
                    pawn.FireWeapon(NULL);
                }
            }
        }
    }
}
