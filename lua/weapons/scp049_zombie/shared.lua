if SERVER then
    AddCSLuaFile()
end

-- --- Configuration du SWEP ---
SWEP.PrintName = "SCP-049-2"
SWEP.Author = "RevanAngel"
SWEP.Category = "GuthSCP"
SWEP.Instructions = "G: Attaquer | D: Crier | R: Bondir (Leap)"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Delay = 0.6

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false

-- --- Variables Internes ---
local hitSounds = {
    "npc/zombie/zombie_hit.wav",
    "npc/zombie/zo_attack2.wav",
    "npc/zombie/zo_attack1.wav"
}

local idleSounds = {
    "npc/zombie/zombie_voice_idle1.wav",
    "npc/zombie/zombie_voice_idle11.wav",
    "npc/zombie/zombie_voice_idle10.wav",
    "npc/zombie/zombie_voice_idle9.wav",
    "npc/zombie/zombie_voice_idle8.wav",
    "npc/zombie/zombie_voice_idle7.wav",
}

-- --- Fonctions de Base ---

function SWEP:Initialize()
    self:SetHoldType("normal")
end

function SWEP:Deploy()
    self:SetHoldType("normal")
    return true
end

function SWEP:TranslateActivity(act)
    local activities = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_ZOMBIE,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_ZOMBIE_01,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_ZOMBIE,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01,
        [ACT_MP_JUMP] = ACT_ZOMBIE_LEAPING,
    }
    return activities[act] or act
end

-- --- Attaque (Clic Gauche) ---

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    owner:SetAnimation(PLAYER_ATTACK1)

    if not IsFirstTimePredicted() then return end

    if CLIENT then self:SendWeaponAnim(ACT_VM_PRIMARYATTACK) end

    local range = 85
    local startPos = owner:GetShootPos()
    local endPos = startPos + owner:GetAimVector() * range

    local trace = util.TraceHull({
        start = startPos,
        endpos = endPos,
        filter = owner,
        mins = Vector(-15, -15, -15),
        maxs = Vector(15, 15, 15),
        mask = MASK_SHOT_HULL
    })

    if IsValid(trace.Entity) then
        self:EmitSound(table.Random(hitSounds), 75, 100)

        if SERVER then
            local dmg = DamageInfo()
            dmg:SetDamage(25)
            dmg:SetAttacker(owner)
            dmg:SetInflictor(self)
            dmg:SetDamageType(DMG_CLUB)
            trace.Entity:TakeDamageInfo(dmg)
        end

        local effectData = EffectData()
        effectData:SetOrigin(trace.HitPos)
        effectData:SetNormal(trace.HitNormal)
        util.Effect("BloodImpact", effectData)
    else
        self:EmitSound("npc/zombie/claw_miss1.wav", 75, 100)
    end
end

-- --- Cri (Clic Droit) ---

function SWEP:SecondaryAttack()
    if (self.NextScream or 0) > CurTime() then return end
    self.NextScream = CurTime() + 2
    
    if IsFirstTimePredicted() then
        self:EmitSound(table.Random(idleSounds), 75, 100)
        if SERVER then 
            self:GetOwner():DoAnimationEvent(ACT_GMOD_GESTURE_TAUNT_ZOMBIE) 
        end
    end
end

-- --- Bond / Leap (Touche R) ---

function SWEP:ZombieLeap()
    local owner = self:GetOwner()
    
    if not owner:IsOnGround() then return end
    if (self.NextLeap or 0) > CurTime() then return end
    
    self.NextLeap = CurTime() + 4

    local force = owner:GetAimVector() * 600
    force.z = math.max(force.z, 250) 

    if SERVER then
        owner:SetVelocity(force)
        owner:EmitSound("npc/zombie/zo_attack1.wav", 80, 85)
        owner:DoAnimationEvent(ACT_ZOMBIE_LEAPING)
    end
end

function SWEP:Reload()
    self:ZombieLeap()
end

function SWEP:ShouldDropOnDie() return false end

if CLIENT then
    guthscp.spawnmenu.add_weapon(SWEP, "SCP-049-2 (Zombie)")
end