if SERVER then
    AddCSLuaFile()
end

local augscp049 = guthscp.modules.augscp049

-- --- Configuration du SWEP ---
SWEP.PrintName = "SCP-049-2"
SWEP.Author = "Augaton"
SWEP.Category = "GuthSCP"
SWEP.Instructions = "G: Attaquer | D: Crier | R: Abilité (zombies légendaires)"

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

            -- Passif lifesteal : soin sur coup porté à un être vivant
            if (trace.Entity:IsPlayer() or trace.Entity:IsNPC()) and owner.scp049_passive == "lifesteal" then
                local heal = augscp049.Passives.lifesteal.heal_per_hit
                local maxhp = owner:GetMaxHealth()
                if owner:Health() < maxhp then
                    owner:SetHealth(math.min(owner:Health() + heal, maxhp))
                end
            end
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

-- --- Abilities ---

-- Cooldowns et Durées
SWEP.Abilities = {
    ["scout"] = { cd = 4 },
    ["normal"] = { duration = 7, cd = 18, speed_mult = 1.5 },
    ["juggernaut"] = { duration = 5, cd = 20, range = 300 },
    ["brute"] = { cd = 12, range = 220, damage = 35, knockback = 260 }
}

function SWEP:Reload()
    local owner = self:GetOwner()
    if not IsValid(owner) or (self.NextAbility or 0) > CurTime() then return end

    -- Seuls les zombies légendaires possèdent une abilité active
    local data = augscp049.GetZombieById(owner:GetNWString("scp049_zombie_id"))
    local type = data and data.ability
    if not type then return end

    local cfg = self.Abilities[type]
    if not cfg then return end

    -- --- SCOUT : LEAP ---
    if type == "scout" then
        if not owner:IsOnGround() then return end
        self.NextAbility = CurTime() + cfg.cd
        
        local force = owner:GetAimVector() * 700
        force.z = math.max(force.z, 300)
        
        if SERVER then
            owner:SetVelocity(force)
            owner:EmitSound("npc/zombie/zo_attack1.wav", 80, 110)
            owner:DoAnimationEvent(ACT_ZOMBIE_LEAPING)
        end

    -- --- NORMAL : ACCÉLÉRATION ---
    elseif type == "normal" then
        self.NextAbility = CurTime() + cfg.cd
        local oldSpeed = owner:GetRunSpeed()
        
        owner:SetRunSpeed(oldSpeed * cfg.speed_mult)
        owner:EmitSound("npc/zombie/zombie_alert1.wav", 75, 120)
        
        if SERVER then
            owner:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 50), 0.5, 0)
            timer.Simple(cfg.duration, function()
                if IsValid(owner) then owner:SetRunSpeed(oldSpeed) end
            end)
        end

    -- --- JUGGERNAUT : TANK (REDIRECTION) ---
    elseif type == "juggernaut" then
        self.NextAbility = CurTime() + cfg.cd
        
        if SERVER then
            owner:SetNWBool("JuggActive", true)
            owner:EmitSound("npc/zombie/zombie_die2.wav", 85, 80)
            
            -- Effet visuel simple
            owner:SetColor(Color(255, 100, 100)) 

            timer.Simple(cfg.duration, function()
                if IsValid(owner) then
                    owner:SetNWBool("JuggActive", false)
                    owner:SetColor(Color(255, 255, 255))
                end
            end)
        end

    -- --- BRUTE : SLAM (AoE) ---
    elseif type == "brute" then
        self.NextAbility = CurTime() + cfg.cd

        if SERVER then
            owner:EmitSound("npc/zombie/zombie_die1.wav", 90, 85)
            owner:DoAnimationEvent(ACT_GMOD_GESTURE_TAUNT_ZOMBIE)

            local center = owner:WorldSpaceCenter()
            for _, e in ipairs(ents.FindInSphere(center, cfg.range)) do
                if IsValid(e) and e ~= owner and (e:IsPlayer() or e:IsNPC())
                    and not augscp049.is_scp_049_zombie(e) and not augscp049.is_scp_049(e) then

                    local dmg = DamageInfo()
                    dmg:SetDamage(cfg.damage)
                    dmg:SetAttacker(owner)
                    dmg:SetInflictor(self)
                    dmg:SetDamageType(DMG_CLUB)
                    e:TakeDamageInfo(dmg)

                    if e:IsPlayer() then
                        local dir = e:GetPos() - center
                        dir.z = 0
                        dir:Normalize()
                        e:SetVelocity(dir * cfg.knockback + Vector(0, 0, 150))
                    end
                end
            end

            local ed = EffectData()
            ed:SetOrigin(center)
            ed:SetScale(cfg.range)
            util.Effect("ThumperDust", ed)
        end
    end
end

function SWEP:ShouldDropOnDie() return false end

if CLIENT then
    guthscp.spawnmenu.add_weapon(SWEP, "SCPs-Extra")
end