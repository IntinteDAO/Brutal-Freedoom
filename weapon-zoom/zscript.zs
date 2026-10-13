version "4.10"

// -------------------------------------------------------------
// WEAPON AIM DOWN SIGHTS (ADS / ZOOM) CONTROLLER
// -------------------------------------------------------------

class BF_AimController : Inventory
{
    Default
    {
        Inventory.MaxAmount 1;
        +INVENTORY.UNDROPPABLE
        +INVENTORY.UNTOSSABLE
    }

    bool isAiming;
    double aimTransition;

    void UpdateAim(PlayerPawn pawn, Weapon wep, bool wantAim)
    {
        if (wantAim)
        {
            if (!isAiming)
            {
                isAiming = true;
                pawn.A_StartSound("weapons/aimin", CHAN_AUTO, 0, 0.40);
            }
        }
        else
        {
            if (isAiming)
            {
                isAiming = false;
                pawn.A_StartSound("weapons/aimout", CHAN_AUTO, 0, 0.35);
            }
        }

        // Smooth transition
        if (isAiming)
        {
            if (aimTransition < 1.0)
            {
                aimTransition = min(1.0, aimTransition + 0.22);
            }
        }
        else
        {
            if (aimTransition > 0.0)
            {
                aimTransition = max(0.0, aimTransition - 0.22);
            }
        }

        // Apply optical zoom
        if (aimTransition > 0.0)
        {
            double baseFOV = pawn.player.DesiredFOV;
            if (baseFOV <= 0)
            {
                baseFOV = 90.0;
            }

            // 1.35x zoom factor
            double zoomFOV = baseFOV * 0.74;
            pawn.player.FOV = baseFOV + (zoomFOV - baseFOV) * aimTransition;

            if (wep)
            {
                wep.FOVScale = pawn.player.FOV / baseFOV;
            }

            let wepPsp = pawn.player.FindPSprite(PSP_WEAPON);
            if (wepPsp && wepPsp.y < 50)
            {
                wepPsp.x = -12.0 * aimTransition;
            }
        }
        else if (!isAiming && aimTransition == 0.0)
        {
            if (pawn.player.FOV != pawn.player.DesiredFOV)
            {
                pawn.player.FOV = pawn.player.DesiredFOV;
                if (wep)
                {
                    wep.FOVScale = 1.0;
                }
                let wepPsp = pawn.player.FindPSprite(PSP_WEAPON);
                if (wepPsp && wepPsp.y < 50)
                {
                    wepPsp.x = 0.0;
                }
            }
        }
    }
}

class BF_AimHandler : EventHandler
{
    private void EnsureAimController(PlayerPawn mo)
    {
        if (mo && !mo.FindInventory("BF_AimController"))
        {
            mo.GiveInventoryType("BF_AimController");
        }
    }

    override void PlayerEntered(PlayerEvent e)
    {
        let p = players[e.PlayerNumber];
        if (p && p.mo)
        {
            EnsureAimController(p.mo);
        }
    }

    override void PlayerRespawned(PlayerEvent e)
    {
        let p = players[e.PlayerNumber];
        if (p && p.mo)
        {
            EnsureAimController(p.mo);
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

            // Check if AltAttack (PPM) is held
            bool altHeld = (p.cmd.buttons & BT_ALTATTACK) != 0;

            // If the weapon has no native AltFire state, ALWAYS clear BT_ALTATTACK from cmd.buttons
            // BEFORE PlayerPawn.Tick runs! This prevents GZDoom from ever blocking primary fire!
            if (wep && wep.FindState("AltFire") == null)
            {
                p.cmd.buttons &= ~BT_ALTATTACK;
            }

            // Ensure attackdown does NOT stick if primary attack (LPM) is not held!
            // This completely unblocks weapons with +WEAPON.NOAUTOFIRE (Rocket Launcher, BFG9000)!
            if (!(p.cmd.buttons & BT_ATTACK))
            {
                p.attackdown = false;
            }

            // Aim / Zoom handling for firearm weapons (Pistol, Shotgun, SSG, Chaingun, Plasma)
            bool canAim = wep && (wep is "Pistol" || wep is "Shotgun" || wep is "SuperShotgun" || wep is "Chaingun" || wep is "PlasmaRifle");

            let ctrl = BF_AimController(pawn.FindInventory("BF_AimController"));
            if (!ctrl)
            {
                ctrl = BF_AimController(pawn.GiveInventoryType("BF_AimController"));
            }

            if (ctrl)
            {
                ctrl.UpdateAim(pawn, wep, altHeld && canAim);
            }
        }
    }
}
