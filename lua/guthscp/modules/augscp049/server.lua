local augscp049 = guthscp.modules.augscp049
local config049 = guthscp.configs.augscp049

util.AddNetworkString("scp049-scan-aura")
util.AddNetworkString("scp049-aura-result")

local disableJump = config049.disable_jump
local isImmortal = config049.scp049_immortal
local scanRangeSqr = config049.aura_scan_range * config049.aura_scan_range

-- --- AURAS ---
local function pick_aura()
    local data = augscp049.GetAuraData()
    local entries = {
        { key = augscp049.AURA.CLEAN,     weight = data.clean.weight },
        { key = augscp049.AURA.SUSPECT,   weight = data.suspect.weight },
        { key = augscp049.AURA.CONFIRMED, weight = data.confirmed.weight },
    }

    local total = 0
    for i = 1, #entries do total = total + entries[i].weight end
    if total <= 0 then return augscp049.AURA.SUSPECT end

    local roll = math.random() * total
    local acc = 0
    for i = 1, #entries do
        acc = acc + entries[i].weight
        if roll <= acc then return entries[i].key end
    end
    return augscp049.AURA.SUSPECT
end

function augscp049.GetAura(ply)
    if not IsValid(ply) then return nil end
    if not ply.scp049_aura then ply.scp049_aura = pick_aura() end
    return ply.scp049_aura
end

hook.Add("PlayerSpawn", "augscp049:assign_aura", function(ply)
    if not IsValid(ply) then return end
    ply.scp049_aura = pick_aura()
end)

net.Receive("scp049-scan-aura", function(len, ply)
    if not IsValid(ply) or not augscp049.is_scp_049(ply) then return end
    if (ply.scp049_next_scan or 0) > CurTime() then return end
    ply.scp049_next_scan = CurTime() + config049.aura_scan_cooldown

    local tr = ply:GetEyeTrace()
    local target = tr.Entity
    if not IsValid(target) or not target:IsPlayer() then return end
    if target:GetPos():DistToSqr(ply:GetPos()) > scanRangeSqr then return end
    if target:GetNWBool("IsZombie") then return end
    if config049.ignore_scps and guthscp.is_scp(target) then return end

    local aura = augscp049.GetAura(target)

    net.Start("scp049-aura-result")
        net.WriteEntity(target)
        net.WriteString(aura)
    net.Send(ply)
end)

-- --- PASSIFS ---
-- Le passif d'un zombie est défini dans le roster (zombies.lua) et stocké sur
-- le joueur (ply.scp049_passive), lu côté serveur uniquement.

-- regen : soin passif périodique
-- Différé d'un tick : augscp049.Passives est défini dans shared.lua, l'ordre
-- de chargement des fichiers du module n'est pas garanti.
timer.Simple(0, function()
    local regen = augscp049.Passives.regen
    timer.Create("augscp049:regen_passive", regen.regen_delay, 0, function()
        local zombies = augscp049.filter_zombies:get_entities()
        for i = 1, #zombies do
            local z = zombies[i]
            if IsValid(z) and z:Alive() and z.scp049_passive == "regen" then
                local maxhp = z:GetMaxHealth()
                if z:Health() < maxhp then
                    z:SetHealth(math.min(z:Health() + regen.regen_amount, maxhp))
                end
            end
        end
    end)
end)

-- armor : réduction passive des dégâts
hook.Add("EntityTakeDamage", "augscp049:armor_passive", function(target, dmginfo)
    if not target:IsPlayer() or not augscp049.is_scp_049_zombie(target) then return end

    if target.scp049_passive == "armor" then
        dmginfo:ScaleDamage(augscp049.Passives.armor.damage_scale)
    end
end)

-- --- HOOKS EXISTANTS ---

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

-- juggernaut (abilité légendaire) : redirection des dégâts des zombies alliés proches
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
                    ed:SetOrigin(target:GetPos() + Vector(0, 0, 40))
                    util.Effect("ElectricSpark", ed)

                    return
                end
            end
        end
    end
end)
