AddCSLuaFile()

if not guthscp then
    error("guthscp049 - fatal error! https://github.com/Guthen/guthscpbase must be installed on the server!")
    return
end

if not scp049 then scp049 = {} end
local augscp049 = guthscp.modules.augscp049
local config049 = guthscp.configs.augscp049

local dist_sqr = 125 * 125 -- second number is the threshold distance between the player and the scp

-----------------------------

if SERVER then
    util.AddNetworkString('scp049-change-zombie')
end


SWEP.Base = "weapon_base"

SWEP.Author = 'RevanAngel'
SWEP.PrintName = 'SCP-049'
SWEP.Instructions = config049.translation_1
SWEP.Category = 'GuthSCP'

SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.Weight = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModelFlip = false

SWEP.ViewModel = 'models/weapons/c_arms.mdl'
SWEP.WorldModel = ''

SWEP.UseHands = true
SWEP.AnimPrefix = "rpg"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1

SWEP.ShouldDropOnDie = false

local openMenu = false
local target
local cd = 0
local soundcd = 0
scp049.Zombies = 0
local ZombieType = scp049.DefaultZombieType

net.Receive('scp049-change-zombie', function(len, ply)
    if not IsValid(ply) or not augscp049.is_scp_049(ply) then 
        return 
    end

    if (ply.nextZombieChange or 0) > CurTime() then
        ply:ChatPrint("Veuillez attendre avant de changer de type à nouveau.")
        return
    end
    ply.nextZombieChange = CurTime() + 1

    local zombieID = net.ReadInt(7)
    local zombieTypes = augscp049.GetZombieTypes049()

    if not zombieTypes[zombieID] then 
        return 
    end

    ply.selectedZombieType049 = zombieID
    
    local name = zombieTypes[zombieID].name
    ply:ChatPrint("Votre prochain zombie sera un : " .. name)
end)

hook.Add('PlayerDeathThink', 'scp049-death', function(ply)
    if ply.scp049Death and ply:scp049Death() then
        return false
    end
end)

hook.Add('PlayerDeath', 'scp049-zombie-death', function(victim, inflictor, attacker)
    if victim:GetNWBool("IsZombie", false) then
        victim:SetNWBool("IsZombie", false)

        scp049.Zombies = math.max(0, scp049.Zombies - 1)
    end
end)

SWEP.LastHealTime = 0

function SWEP:Initialize()
    self:SetHoldType("normal")
end

local function HealZombie(self, target)
    if not IsValid(target) or not target:IsPlayer() or not target:GetNWBool("IsZombie", false) then
        return
    end

    if not self.LastHealTime then
        self.LastHealTime = 0
    end

    local healTime = (guthscp and guthscp.configs and guthscp.configs.augscp049 and guthscp.configs.augscp049.heal_time) or 2

    if CurTime() > self.LastHealTime + healTime then
        local maxHealth = target:GetMaxHealth()
        target:SetHealth(math.min(target:Health() + 1, maxHealth))
        
        if target:Health() < maxHealth then
            if not self.soundcd then
                self.soundcd = 1
            end

            if self.soundcd <= 0 then
                self.Owner:EmitSound('buttons/blip1.wav', 75, (20 + target:Health() / maxHealth * 105))
                self.soundcd = 2
            else
                self.soundcd = self.soundcd - 1
            end
            self.LastHealTime = CurTime()
        end
    end
end

function SWEP:Think()
    if CLIENT then
        if self.Owner:KeyPressed(IN_RELOAD) then
            if not IsValid(SCPZombieMenu) then
                augscp049.ZombieMenu()
            end
        end
    end

    if SERVER then
        local ply = self:GetOwner()
        local shootPos = ply:GetShootPos()
        local endShootPos = shootPos + ply:GetAimVector() * 150

        local tr = util.TraceHull({
            start = shootPos,
            endpos = endShootPos,
            filter = ply,
            mask = MASK_SHOT_HULL
        })

        if not IsValid(tr.Entity) then
            tr = util.TraceLine({
                start = shootPos,
                endpos = endShootPos,
                filter = ply,
                mask = MASK_SHOT_HULL
            })
        end

        local target = tr.Entity

        if self.Owner:KeyDown(IN_ATTACK2) then
            HealZombie(self, target)
        end
    end

    if not IsFirstTimePredicted() then return end
    local trace = self:GetOwner():GetEyeTrace()
    local target = trace.Entity
    local holdType = "normal"
    if target:IsPlayer() and not guthscp.is_scp(target) and target:GetPos():DistToSqr(self:GetOwner():GetPos()) <= dist_sqr and not augscp049.is_scp_049_zombie(target) then
        holdType = "pistol"
    end

    self:SetHoldType(holdType)
end

scp049.Zombies = scp049.Zombies or 0

function augscp049.is_scp_049_zombie(ply)
    return ply:GetNWBool("IsZombie", false)
end

function SWEP:CallRagdollTarget(owner, target)
    if augscp049.is_scp_049_zombie(target) then
        return
    end

    local zombietypes = augscp049.GetZombieTypes049()

    target:SetNoDraw(true)
    target:Lock()
    target:StripWeapons()
    target:SetCollisionGroup(COLLISION_GROUP_WORLD)
    
    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(target:GetModel())
    ragdoll:SetPos(target:GetPos())
    ragdoll:SetAngles(target:GetAngles())
    ragdoll:Spawn()
    ragdoll:Activate()

    local phys = ragdoll:GetPhysicsObject()
    if IsValid(phys) then
        phys:ApplyForceCenter(owner:GetForward() * 500 * 500)
    end

    target:SetViewEntity(ragdoll)

    timer.Simple(2.8, function()
        if IsValid(target) and IsValid(ragdoll) then

            target:SetNoDraw(false)
            target:SetPos(ragdoll:GetPos())
            ragdoll:Remove()

            local zombieData = zombietypes[ZombieType]
            if not zombieData then
                print("ZombieType is not defined correctly taking the first one.")
                zombieData = zombietypes[1]
            end

            target:SetModel(zombieData.model)
            target:SetMaxHealth(zombieData.health)
            target:SetHealth(zombieData.health)
            target:SetWalkSpeed(zombieData.speed)
            target:SetRunSpeed(zombieData.speed)
            target:SetNWBool("IsZombie", true)
            target:StripWeapons()
            target:Give("augscp049_zombie")

            scp049.Zombies = scp049.Zombies + 1

            target:EmitSound("npc/zombie/zombie_pain5.mp3")
            target:DoAnimationEvent(ACT_HL2MP_ZOMBIE_SLUMP_RISE)
            target:SetCollisionGroup(COLLISION_GROUP_NONE)
        end
    end)

    timer.Simple(4, function()
        if IsValid(target) then
            target:UnLock()
            target:SetViewEntity(target)
        end
    end)
end

function SWEP:PrimaryAttack()
    if SERVER then
        local ply = self:GetOwner()
        local shootPos = ply:GetShootPos()
        local endShootPos = shootPos + ply:GetAimVector() * 150

        local tr = util.TraceHull({
            start = shootPos,
            endpos = endShootPos,
            filter = ply,
            mask = MASK_SHOT_HULL
        })

        if not IsValid(tr.Entity) then
            tr = util.TraceLine({
                start = shootPos,
                endpos = endShootPos,
                filter = ply,
                mask = MASK_SHOT_HULL
            })
        end

        local target = tr.Entity
        self:SetNextPrimaryFire(CurTime() + 3)
        
        if IsValid(target) and (target:IsPlayer() or target:IsNPC()) then
            if augscp049.is_scp_049_zombie(target) then
                guthscp.player_message( self:GetOwner(), config049.translation_3 )
                return
            end
        
            local ignoreSCPs = guthscp.configs.augscp049.ignore_scps
            if ignoreSCPs and guthscp.is_scp(target) then
                return
            end
        
            local ignoreTeams = guthscp.configs.augscp049.ignore_teams
            local targetTeam = target:Team()
            local teamKeyName = guthscp.get_team_keyname(targetTeam)
            
            if ignoreTeams[teamKeyName] then
                return
            end
        
            scp049.Zombies = scp049.Zombies or 0
            if scp049.Zombies >= guthscp.configs.augscp049.zb_limits and guthscp.configs.augscp049.zb_limits ~= 0 then
                guthscp.player_message( self:GetOwner(), config049.translation_4 )
                return
            end

            if config049.progressbar then
                self:SetNWFloat("Progress", 0) -- Initialize progress

                guthscp.player_message( self:GetOwner(), config049.translation_progress_start )
                self:GetOwner():SetNWBool("scp049_Infected", true)

                timer.Create("ProgressTimer", 0.1, 50, function()
                    if IsValid(self) and IsValid(target) and target:GetPos():DistToSqr(self:GetOwner():GetPos()) <= dist_sqr then -- Check that the SWEP and target are still valid
                        local progress = math.min(self:GetNWFloat("Progress", 0) + config049.progressbar_speed, 100)
                        self:SetNWFloat("Progress", progress)
                        if progress >= 100 then
                            timer.Remove("ProgressTimer")
                            self:GetOwner():SetNWBool("scp049_Infected", false)
                            self:CallRagdollTarget(self:GetOwner(), target)
                            guthscp.player_message( self:GetOwner(), config049.translation_progress_finish )
                        end
                    else
                        guthscp.player_message( self:GetOwner(), config049.translation_progress_stop )
                        timer.Remove("ProgressTimer") -- Remove timer if SWEP or target is no longer valid
                        self:GetOwner():SetNWBool("scp049_Infected", false)
                    end
                end)
            else
                self:CallRagdollTarget(self:GetOwner(), target)
            end
        end
    end
end

function SWEP:DrawHUD()
	
    local ply = self:GetOwner()
	if not IsValid( ply ) or not ply:Alive() then return end

    if ply:GetNWBool("scp049_Infected") then
        if IsValid(wep) and augscp049.is_scp_049(ply) then
            local progress = wep:GetNWFloat("Progress", 0)

            surface.SetDrawColor(50, 50, 50, 220)
            surface.DrawRect(ScrW() * 0.5 - 100, ScrH() * 0.9, 200, 20)

            surface.SetDrawColor(0, 255, 0, 220)
            surface.DrawRect(ScrW() * 0.5 - 100, ScrH() * 0.9, progress * 2, 20)
        end
    end
	
end

SWEP.NextSecondaryAttack = 0

function SWEP:SecondaryAttack()
	if not SERVER then return end

	local ply = self:GetOwner()
    -- Play random sound
    local sounds = config049.random_sound
    if #sounds == 0 then return end

    ply:EmitSound(sounds[math.random(#sounds)], nil, nil)

	self:SetNextSecondaryFire( CurTime() + 5.0 )
end

function SWEP:Reload()
    if SERVER then
        net.Start('scp049-change-zombie')
        net.Send(self.Owner)
    end
end

function SWEP:ShouldDropOnDie()
    return false
end

function SWEP:Deploy()
    if CLIENT or not IsValid(self:GetOwner()) then return true end
    self:GetOwner():DrawWorldModel(false)
    return true
end

function SWEP:Deploy()
    return true
end

if CLIENT then
    guthscp.spawnmenu.add_weapon(SWEP, "SCP-049 SWEP")
end