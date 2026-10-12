
version "4.10"

class BF_KickController : CustomInventory
{
    Default
    {
        Inventory.MaxAmount 1;
        +INVENTORY.UNDROPPABLE
        +INVENTORY.UNTOSSABLE
        DefaultStateUsage SUF_ACTOR|SUF_OVERLAY|SUF_WEAPON|SUF_ITEM;
    }

    const PSP_KICK = 7331;
    int kickCooldown;
    bool hasSwung;
    bool hasHit;

    override void DoEffect()
    {
        Super.DoEffect();
        if (kickCooldown > 0)
        {
            kickCooldown--;
        }

        if (!Owner || !Owner.player)
        {
            return;
        }

        let psp = Owner.player.FindPSprite(PSP_KICK);
        if (psp && psp.CurState != null)
        {
            // Disable shooting during kick
            Owner.player.WeaponState &= ~(WF_WEAPONREADY | WF_WEAPONREADYALT);
            Owner.player.cmd.buttons &= ~(BT_ATTACK | BT_ALTATTACK);

            // Lower weapon slightly during kick ("na lewo od kopnięcia / obok broni")
            let wepPsp = Owner.player.FindPSprite(PSP_WEAPON);
            if (wepPsp)
            {
                wepPsp.y = 60;
            }
            let flashPsp = Owner.player.FindPSprite(PSP_FLASH);
            if (flashPsp)
            {
                flashPsp.y = 60;
            }

            // Frame 0: KICK A - Swing sound
            if (psp.Frame == 0 && !hasSwung)
            {
                hasSwung = true;
                Owner.A_StartSound("weapons/kickwhoosh", CHAN_AUTO);
            }
            // Frame 2: KICK C - Melee impact
            else if (psp.Frame == 2 && !hasHit)
            {
                hasHit = true;
                DoKickImpact();
            }
        }
        else
        {
            // Restore weapon when kick is not active
            let wepPsp = Owner.player.FindPSprite(PSP_WEAPON);
            if (wepPsp && wepPsp.y > 32)
            {
                wepPsp.y = 32;
                Owner.player.WeaponState |= WF_WEAPONREADY;
            }
            let flashPsp = Owner.player.FindPSprite(PSP_FLASH);
            if (flashPsp && flashPsp.y > 32)
            {
                flashPsp.y = 32;
            }
        }
    }

    void TryKick()
    {
        if (!Owner || !Owner.player || Owner.Health <= 0)
        {
            return;
        }

        if (kickCooldown > 0)
        {
            return;
        }

        let psp = Owner.player.FindPSprite(PSP_KICK);
        if (psp && psp.CurState != null)
        {
            return;
        }

        kickCooldown = 13;
        hasSwung = false;
        hasHit = false;

        // Lower weapon slightly during kick
        let wepPsp = Owner.player.FindPSprite(PSP_WEAPON);
        if (wepPsp)
        {
            wepPsp.y = 60;
        }
        Owner.player.WeaponState &= ~(WF_WEAPONREADY | WF_WEAPONREADYALT);
        Owner.player.cmd.buttons &= ~(BT_ATTACK | BT_ALTATTACK);

        Owner.player.SetPsprite(PSP_KICK, FindState("KickStart"));
        let kickPsp = Owner.player.FindPSprite(PSP_KICK);
        if (kickPsp)
        {
            kickPsp.Caller = self;
            kickPsp.bAddWeapon = false;
            kickPsp.x = 0;
            kickPsp.y = 0;
        }
    }

    private void DoKickImpact()
    {
        PlayerPawn pawn = PlayerPawn(Owner);
        if (!pawn || !pawn.player)
        {
            return;
        }

        double kickRange = 76.0;
        double kickAngle = pawn.Angle;
        double kickPitch = pawn.Pitch;

        FTranslatedLineTarget t;
        pawn.AimLineAttack(kickAngle, kickRange, t, 0.0, ALF_CHECK3D);

        if (t.linetarget)
        {
            Actor victim = t.linetarget;
            int dmg = Random[BFKick](35, 55);

            if (pawn.FindInventory("PowerStrength"))
            {
                dmg = int(dmg * 2.5);
            }

            victim.DamageMobj(pawn, pawn, dmg, 'Melee', DMG_THRUSTLESS);
            pawn.A_StartSound("weapons/kickflesh", CHAN_AUTO);
            victim.TraceBleed(dmg, pawn);

            double knockForce = 12.0;
            if (victim.Mass > 0)
            {
                knockForce = clamp(2600.0 / victim.Mass, 4.0, 18.0);
            }
            victim.Vel.X += cos(kickAngle) * knockForce;
            victim.Vel.Y += sin(kickAngle) * knockForce;
            victim.Vel.Z += 3.5;

            pawn.A_QuakeEx(1.8, 1.8, 1.8, 3, 0, 128, "", QF_RELATIVE);
        }
        else
        {
            Actor puff;
            int actDmg;
            [puff, actDmg] = pawn.LineAttack(kickAngle, kickRange, kickPitch, 0, 'Hitscan', 'BulletPuff', LAF_ISMELEEATTACK, t);

            if (t.unlinked || puff != null)
            {
                pawn.A_StartSound("weapons/kickhit", CHAN_AUTO);
                pawn.A_QuakeEx(1.2, 1.2, 1.2, 2, 0, 64, "", QF_RELATIVE);
            }
        }
    }

    States
    {
    Use:
        TNT1 A 0
        {
            if (invoker)
            {
                BF_KickController(invoker).TryKick();
            }
        }
        Fail;

    KickStart:
        KICK A 2;
        KICK B 2;
        KICK C 3;
        KICK D 2;
        KICK E 2;
        TNT1 A 1;
        Stop;
    }
}

class BF_QuickKickHandler : EventHandler
{
    private void EnsureKickItem(PlayerPawn mo)
    {
        if (mo && !mo.FindInventory("BF_KickController"))
        {
            mo.GiveInventoryType("BF_KickController");
        }
    }

    override void PlayerEntered(PlayerEvent e)
    {
        let p = players[e.PlayerNumber];
        if (p && p.mo)
        {
            EnsureKickItem(p.mo);
        }
    }

    override void PlayerRespawned(PlayerEvent e)
    {
        let p = players[e.PlayerNumber];
        if (p && p.mo)
        {
            EnsureKickItem(p.mo);
        }
    }

    override void NetworkProcess(ConsoleEvent e)
    {
        if (e.Name ~== "BF_Kick")
        {
            let p = players[e.Player];
            if (p && p.mo && p.mo.Health > 0)
            {
                let ctrl = BF_KickController(p.mo.FindInventory("BF_KickController"));
                if (!ctrl)
                {
                    ctrl = BF_KickController(p.mo.GiveInventoryType("BF_KickController"));
                }
                if (ctrl)
                {
                    ctrl.TryKick();
                }
            }
        }
    }
}
