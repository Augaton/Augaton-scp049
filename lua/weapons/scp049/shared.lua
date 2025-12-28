AddCSLuaFile()

if not guthscp then
    error("guthscp049 - fatal error! guthscpbase must be installed!")
    return
end

local augscp049 = guthscp.modules.augscp049
local config049 = guthscp.configs.augscp049

local dist_sqr = 15625

-- --- NETWORK ---
if SERVER then
    util.AddNetworkString('scp049-change-zombie')

    net.Receive('scp049-change-zombie', function(len, ply)
        if not IsValid(ply) or not augscp049.is_scp_049(ply) then return end
        if (ply.nextZombieChange or 0) > CurTime() then return end
        
        ply.nextZombieChange = CurTime() + 0.5
        local zombieID = net.ReadInt(7)
        local zombieTypes = augscp049.GetZombieTypes049()

        if zombieTypes[zombieID] then 
            ply.selectedZombieType049 = zombieID
        end
    end)
end

-- --- SWEP CONFIG ---
SWEP.PrintName = 'SCP-049'
SWEP.Author = 'Augaton'
SWEP.Instructions = config049.translation_1
SWEP.Category = 'GuthSCP'
SWEP.Slot = 1
SWEP.Base = "weapon_base"
SWEP.Spawnable = true
SWEP.ViewModel = 'models/weapons/c_arms.mdl'
SWEP.WorldModel = ''
SWEP.UseHands = true
SWEP.Primary.ClipSize, SWEP.Secondary.ClipSize = -1, -1
SWEP.Primary.Automatic, SWEP.Secondary.Automatic = false, false

-- --- FUNCTIONS ---

function SWEP:Initialize()
    self:SetHoldType("normal")
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawWorldModel(false)
    end
    return true
end

function SWEP:HealZombie(target)
    if (self.NextHeal or 0) > CurTime() then return end
    self.NextHeal = CurTime() + 0.5

    local maxHP = target:GetMaxHealth()
    if target:Health() < maxHP then
        target:SetHealth(math.min(target:Health() + 4, maxHP))
        target:EmitSound("npc/zombie/zombie_alert".. math.random(1, 3) ..".wav")
    end
end

function SWEP:CallRagdollTarget(owner, target)
    if not IsValid(target) or not target:Alive() then return end
    
    target:SetNoDraw(true)
    target:Lock()
    target:StripWeapons()
    
    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(target:GetModel())
    ragdoll:SetPos(target:GetPos())
    ragdoll:SetAngles(target:GetAngles())
    ragdoll:Spawn()
    ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    
    local phys = ragdoll:GetPhysicsObject()
    if IsValid(phys) then phys:ApplyForceCenter(owner:GetForward() * 1000) end

    target:SetViewEntity(ragdoll)

    timer.Simple(3, function()
        if not IsValid(target) then if IsValid(ragdoll) then ragdoll:Remove() end return end

        target:SetNoDraw(false)
        target:SetPos(ragdoll:GetPos() + Vector(0,0,10))
        if IsValid(ragdoll) then ragdoll:Remove() end

        local zTypes = augscp049.GetZombieTypes049()
        local selectedID = owner.selectedZombieType049 or 1
        local data = zTypes[selectedID] or zTypes[1]

        target:SetModel(data.model)
        target:SetMaxHealth(data.health)
        target:SetHealth(data.health)
        target:SetWalkSpeed(data.speed)
        target:SetRunSpeed(data.speed)
        target:SetNWBool("IsZombie", true)
        
        target:UnLock()
        target:SetViewEntity(target)
        target:Give("scp049_zombie")
        
        target:EmitSound("npc/zombie/zombie_pain5.mp3")
        target:DoAnimationEvent(ACT_HL2MP_ZOMBIE_SLUMP_RISE)
    end)
end

function SWEP:Think()
    if CLIENT then
        if self:GetOwner():KeyPressed(IN_RELOAD) and not IsValid(SCPZombieMenu) then
            augscp049.ZombieMenu()
        end
        return
    end

    local owner = self:GetOwner()
    local tr = owner:GetEyeTrace()
    local ent = tr.Entity
    local isNear = IsValid(ent) and ent:IsPlayer() and ent:GetPos():DistToSqr(owner:GetPos()) < 15625 -- 125 units

    local targetType = isNear and "pistol" or "normal"
    if self:GetHoldType() != targetType then self:SetHoldType(targetType) end

    if owner:KeyDown(IN_ATTACK2) and isNear and augscp049.is_scp_049_zombie(ent) then
        self:HealZombie(ent)
    end
end

function SWEP:PrimaryAttack()
    if not SERVER then return end
    
    local owner = self:GetOwner()

    if owner:GetNWBool("049_Stunned") then 
        owner:ChatPrint("Vous êtes trop affaibli par l'odeur pour opérer !")
        return 
    end

    local tr = owner:GetEyeTrace()
    local target = tr.Entity

    if not IsValid(target) or not (target:IsPlayer() or target:IsNPC()) then return end
    if target:GetPos():DistToSqr(owner:GetPos()) > dist_sqr then return end
    
    -- Checks de sécurité
    if target:GetNWBool("IsZombie") then return end
    if config049.ignore_scps and guthscp.is_scp(target) then return end
    
    self:SetNextPrimaryFire(CurTime() + 2)

    if config049.progressbar then
        if timer.Exists("049_proc_" .. owner:EntIndex()) then return end
        
        owner:SetNWBool("scp049_Infected", true)
        self:SetNWFloat("Progress", 0)

        timer.Create("049_proc_" .. owner:EntIndex(), 0.1, 100, function()
            if not IsValid(self) or not IsValid(target) or target:GetPos():DistToSqr(owner:GetPos()) > dist_sqr then
                timer.Remove("049_proc_" .. owner:EntIndex())
                owner:SetNWBool("scp049_Infected", false)
                return
            end

            local curProg = self:GetNWFloat("Progress", 0)
            self:SetNWFloat("Progress", curProg + (config049.progressbar_speed or 2))

            if self:GetNWFloat("Progress") >= 100 then
                timer.Remove("049_proc_" .. owner:EntIndex())
                owner:SetNWBool("scp049_Infected", false)
                self:CallRagdollTarget(owner, target)
            end
        end)
    else
        self:CallRagdollTarget(owner, target)
    end
end

function SWEP:SecondaryAttack()
    if not SERVER then return end
    local sounds = config049.random_sound
    if #sounds > 0 then
        self:GetOwner():EmitSound(sounds[math.random(#sounds)])
    end
    self:SetNextSecondaryFire(CurTime() + 5)
end

function SWEP:DrawHUD()
    local ply = self:GetOwner()
    if ply:GetNWBool("scp049_Infected") then
        local progress = self:GetNWFloat("Progress", 0)
        local w, h = 200, 20
        local x, y = ScrW() / 2 - w / 2, ScrH() * 0.8
        
        draw.RoundedBox(4, x, y, w, h, Color(0, 0, 0, 200))
        draw.RoundedBox(4, x + 2, y + 2, (w - 4) * (progress / 100), h - 4, Color(255, 0, 0, 255))
        draw.SimpleText("OPÉRATION EN COURS", "DefaultFixed", x + w / 2, y + h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

if CLIENT then
    guthscp.spawnmenu.add_weapon(SWEP, "SCPs")
end