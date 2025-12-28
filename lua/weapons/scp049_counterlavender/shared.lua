SWEP.PrintName = "Spray à la Lavande"
SWEP.Instructions = "Maintenir LMB : Vaporiser sur 049\nLe Docteur doit être exposé 2 secondes pour être neutralisé."
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

local DISTANCE_SPRAY = 150

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    self:SetNextPrimaryFire(CurTime() + 0.1)

    if CLIENT then
        local effect = EffectData()
        effect:SetOrigin(owner:GetShootPos() + owner:GetAimVector() * 10)
        effect:SetNormal(owner:GetAimVector())
        effect:SetScale(1)
        util.Effect("vortigaunt_glow_beam", effect)
        return
    end

    owner:EmitSound("ambient/levels/canals/faucet_drip.wav", 60, 150)

    local tr = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * DISTANCE_SPRAY,
        filter = owner
    })

    local target = tr.Entity
    if IsValid(target) and target:IsPlayer() and augscp049.is_scp_049(target) then
        target.LavenderExposure = (target.LavenderExposure or 0) + 0.1

        if target.LavenderExposure >= 1.5 then
            self:ApplyStun(target)
            target.LavenderExposure = 0 
        end
    end
end

function SWEP:ApplyStun(target)
    if target:GetNWBool("049_Stunned") then return end

    target:SetNWBool("049_Stunned", true)
    target:EmitSound("npc/049/cough.wav")

    -- On le paralyse
    target:SetRunSpeed(60)
    target:SetWalkSpeed(60)

    timer.Simple(7, function()
        if IsValid(target) then
            target:SetNWBool("049_Stunned", false)
            target:SetRunSpeed(config049.run_speed)
            target:SetWalkSpeed(config049.walk_speed)
        end
    end)
end