local augscp049 = guthscp.modules.augscp049
local config049 = guthscp.configs.augscp049

local disableJump = config049.disable_jump
local isImmortal = config049.scp049_immortal

hook.Add("SetupMove", "augscp049:no_move", function(ply, mv, cmd)
    if not disableJump then return end
    if not augscp049.is_scp_049(ply) then return end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end

    if mv:KeyPressed(IN_JUMP) then
        mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
    end
end)

hook.Add("EntityTakeDamage", "augscp049:prevent_damage", function(target, dmginfo)
    if not isImmortal then return end
    
    if target:IsPlayer() and augscp049.is_scp_049(target) then
        dmginfo:SetDamage(0)
        dmginfo:ScaleDamage(0)
        return true
    end
end)
