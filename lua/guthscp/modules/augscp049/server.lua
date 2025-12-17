local augscp049 = guthscp.modules.augscp049
local config049 = guthscp.configs.augscp049

hook.Add("SetupMove", "augscp049:no_move", function(ply, mv, cmd)
    if not augscp049.is_scp_049(ply) then return end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end

    if guthscp.configs.augscp049.disable_jump then
        mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
    end
end)

-- Hook pour gérer les dégâts des SCP-049
hook.Add("PlayerShouldTakeDamage", "augscp049:no_damage", function(ply)
    if config049.scp049_immortal and augscp049.is_scp_049(ply) then
        return false
    end
end)