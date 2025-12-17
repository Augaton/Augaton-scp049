if SERVER then
    AddCSLuaFile()
end

SWEP.PrintName = "SCP-049-2"
SWEP.Author = "RevanAngel"
SWEP.Category = "GuthSCP"
SWEP.Purpose = "Clique droit pour attaquer! R pour crier!"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.UseHands = true
SWEP.WorldModel = ""

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Delay = 0.5
SWEP.Primary.Ammo = ""
SWEP.PrimaryAttackAnimation = "attack"
SWEP.SecondaryAttackAnimation = "attack2"
SWEP.ReloadAnimation = "reload"
SWEP.UseHands = true

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Delay = 0.5
SWEP.Secondary.Ammo = ""

SWEP.PrimaryAttackSound = Sound("npc/zombie/claw_miss1.wav")
SWEP.SecondaryAttackSound = Sound("npc/zombie/claw_strike1.wav")
SWEP.ReloadSound = Sound("weapons/fists/reload.wav")

function SWEP:Initialize()

	self:SetHoldType( "normal" )
	
	self.ActivityTranslate[ ACT_MP_STAND_IDLE ]					= ACT_HL2MP_IDLE_ZOMBIE
	self.ActivityTranslate[ ACT_MP_WALK ]						= ACT_HL2MP_WALK_ZOMBIE_01
	self.ActivityTranslate[ ACT_MP_RUN ]						= ACT_HL2MP_RUN_ZOMBIE
	self.ActivityTranslate[ ACT_MP_CROUCH_IDLE ]				= ACT_HL2MP_IDLE_CROUCH_ZOMBIE
	self.ActivityTranslate[ ACT_MP_CROUCHWALK ]					= ACT_HL2MP_WALK_CROUCH_ZOMBIE_01
	self.ActivityTranslate[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ]	= ACT_GMOD_GESTURE_RANGE_ZOMBIE
	self.ActivityTranslate[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ]	= ACT_GMOD_GESTURE_RANGE_ZOMBIE
	self.ActivityTranslate[ ACT_MP_JUMP ]						= ACT_ZOMBIE_LEAPING
	self.ActivityTranslate[ ACT_RANGE_ATTACK1 ]					= ACT_GMOD_GESTURE_RANGE_ZOMBIE

end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

    local range = 80
    local radius = 15

    local startPos = self.Owner:GetShootPos()
    local endPos = startPos + self.Owner:GetAimVector() * range

    local minBounds = Vector(-radius, -radius, -radius)
    local maxBounds = Vector(radius, radius, radius)

    local trace = util.TraceHull({
        start = startPos,
        endpos = endPos,
        filter = self.Owner,
        mins = minBounds,
        maxs = maxBounds
    })

    if IsValid(trace.Entity) and not trace.Entity:IsNPC() then
        if SERVER then
            trace.Entity:TakeDamage(20, self.Owner, self)
            local attackSounds = {
                "npc/zombie/zombie_hit.wav",
                "npc/zombie/zo_attack2.wav",
                "npc/zombie/zo_attack1.wav"
            }
            local attackSound = table.Random(attackSounds)
            self.Owner:EmitSound(attackSound)
        end

        local effectData = EffectData()
        effectData:SetStart(startPos)
        effectData:SetOrigin(trace.HitPos)
        effectData:SetNormal(trace.HitNormal)
        util.Effect("BloodImpact", effectData)
    else
        self:EmitSound("npc/zombie/claw_miss1.wav")
    end
end


function SWEP:SecondaryAttack()
    if SERVER and IsValid(self.Owner) then
        self.Owner:DoAnimationEvent(ACT_GMOD_GESTURE_TAUNT_ZOMBIE)
        
        if self.SoundPlaying then return end

        local sounds = {
            "npc/zombie/zombie_voice_idle1.wav",
            "npc/zombie/zombie_voice_idle11.wav",
            "npc/zombie/zombie_voice_idle10.wav",
            "npc/zombie/zombie_voice_idle9.wav",
            "npc/zombie/zombie_voice_idle8.wav",
            "npc/zombie/zombie_voice_idle7.wav",
            "npc/zombie/zombie_voice_idle6.wav",
            "npc/zombie/zombie_voice_idle5.wav",
            "npc/zombie/zombie_voice_idle4.wav",
        }

        local randomSound = sounds[math.random(1, #sounds)]

        self.Owner:EmitSound(randomSound)

        self.SoundPlaying = true

        timer.Simple(SoundDuration(randomSound), function()
            self.SoundPlaying = false
        end)
    end
end


function SWEP:Reload()
    if SERVER and IsValid(self.Owner) then
        if not self.IsReloading then
            self.IsReloading = true
            
            local reloadSounds = {
                "npc/zombie_poison/pz_call1.wav"
            }
            local reloadSound = table.Random(reloadSounds)
            
            self.Owner:EmitSound(reloadSound)
            
            self.Owner:DoAnimationEvent(ACT_GMOD_GESTURE_TAUNT_ZOMBIE)

            local reloadDelay = 1
            timer.Simple(reloadDelay, function()
                self.IsReloading = false
            end)
        end
    end
end

function SWEP:ShouldDropOnDie()
    return false
end

function SWEP:Holster()
    return true
end

function SWEP:Deploy()
    return true
end

if CLIENT then
    guthscp.spawnmenu.add_weapon(SWEP, "SCP-049 SWEP")
end