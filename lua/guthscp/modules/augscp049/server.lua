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

hook.Add("EntityTakeDamage", "SCP049_JuggernautRedirection", function(target, dmginfo)
    if target:IsPlayer() and augscp049.is_scp_049_zombie(target) and not target:GetNWBool("JuggActive") then
        
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetNWBool("JuggActive") and ply:Alive() then
                local dist = ply:GetPos():DistToSqr(target:GetPos())
                local range = 300 * 300 

                if dist < range then
                    local originalDamage = dmginfo:GetDamage()
                    local redirectedDamage = originalDamage * 0.25
                    
                    ply:TakeDamage(redirectedDamage, dmginfo:GetAttacker(), dmginfo:GetInflictor())
                    
                    dmginfo:SetDamage(0)
                    
                    local ed = EffectData()
                    ed:SetOrigin(target:GetPos() + Vector(0,0,40))
                    util.Effect("ElectricSpark", ed)
                    
                    return
                end
            end
        end
    end
end)
