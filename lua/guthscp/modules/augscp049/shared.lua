local augscp049 = guthscp.modules.augscp049
local config049 = guthscp.configs.augscp049

augscp049.filter = guthscp.players_filter:new("scp049")
augscp049.filter_zombies = guthscp.players_filter:new("scp049_zombie")

-- --- AURAS ---
-- vert (clean) : pas de peste, ne peut pas être réanimé
-- rouge (suspect) : suspicion, réanimable, ratio rareté x1
-- mauve (confirmed) : peste confirmée, réanimable, ratio rareté x2
augscp049.AURA = {
    CLEAN = "clean",
    SUSPECT = "suspect",
    CONFIRMED = "confirmed",
}

local aura_data_cache

function augscp049.GetAuraData()
    if aura_data_cache then return aura_data_cache end

    aura_data_cache = {
        clean = {
            color = Color(40, 220, 60),
            label = config049.aura_clean_label,
            can_revive = false,
            rarity_mult = 0,
            weight = config049.aura_clean_weight,
        },
        suspect = {
            color = Color(225, 45, 45),
            label = config049.aura_suspect_label,
            can_revive = true,
            rarity_mult = 1,
            weight = config049.aura_suspect_weight,
        },
        confirmed = {
            color = Color(175, 35, 240),
            label = config049.aura_confirmed_label,
            can_revive = true,
            rarity_mult = 2,
            weight = config049.aura_confirmed_weight,
        },
    }
    return aura_data_cache
end

-- --- TIERS DE RARETÉ ---
function augscp049.GetTierWeights()
    return {
        common = config049.tier_common_weight,
        rare = config049.tier_rare_weight,
        epic = config049.tier_epic_weight,
        legendary = config049.tier_legendary_weight,
    }
end

-- --- PASSIFS (traits passifs) ---
-- Valeurs d'équilibrage gardées ici (hors menu) pour garder la config simple.
-- L'attribution d'un passif à un zombie se fait dans zombies.lua (roster).
augscp049.Passives = {
    regen = { regen_amount = 5, regen_delay = 1 },   -- soin passif / seconde
    armor = { damage_scale = 0.7 },                  -- -30% dégâts subis
    lifesteal = { heal_per_hit = 8 },                -- soin par coup porté
}

-- --- REGISTRE DES ZOMBIES ---
-- Le roster est défini dans zombies.lua (augscp049.ZombieRoster).
-- Ici on le groupe par tier (en cache) pour le tirage de rareté.
local zombie_types_cache
local zombie_by_id_cache

function augscp049.GetZombieTypes049()
    if not zombie_types_cache then
        zombie_types_cache = { common = {}, rare = {}, epic = {}, legendary = {} }
        local roster = augscp049.ZombieRoster or {}
        for i = 1, #roster do
            local z = roster[i]
            local list = zombie_types_cache[z.tier]
            if list then list[#list + 1] = z end
        end
    end
    return zombie_types_cache
end

-- Lookup par id, mis en cache car appelé dans des hooks fréquents.
function augscp049.GetZombieById(id)
    if not id or id == "" then return nil end

    if not zombie_by_id_cache then
        zombie_by_id_cache = {}
        local roster = augscp049.ZombieRoster or {}
        for i = 1, #roster do
            zombie_by_id_cache[roster[i].id] = roster[i]
        end
    end

    return zombie_by_id_cache[id]
end

-- Tirage pondéré générique
local function weighted_pick(entries)
    local total = 0
    for i = 1, #entries do total = total + entries[i].weight end
    if total <= 0 then return nil end

    local roll = math.random() * total
    local acc = 0
    for i = 1, #entries do
        acc = acc + entries[i].weight
        if roll <= acc then return entries[i].value end
    end
    return entries[#entries].value
end

-- Tire un type de zombie selon l'aura.
-- Le ratio de l'aura amplifie les tiers rares (mauve x2, rouge x1).
-- Le tier est tiré au sort, puis un zombie pré-configuré du tier (stats fixes).
function augscp049.RollZombieType(aura_key)
    local aura = augscp049.GetAuraData()[aura_key]
    if not aura or not aura.can_revive then return nil end

    local weights = augscp049.GetTierWeights()
    local types = augscp049.GetZombieTypes049()

    local tier_entries = {}
    for tier, w in pairs(weights) do
        if types[tier] and #types[tier] > 0 then
            local effective = (tier == "common") and w or (w * aura.rarity_mult)
            tier_entries[#tier_entries + 1] = { value = tier, weight = effective }
        end
    end

    local tier = weighted_pick(tier_entries)
    if not tier then return nil end

    local pool = types[tier]
    return pool[math.random(#pool)]
end

if CLIENT then
    surface.CreateFont('scp-sweps1', {
        font = 'Arial',
        size = ScrW() * 0.014,
        weight = 500,
        antialias = true,
    })
end

if SERVER then
    augscp049.filter:listen_disconnect()
    augscp049.filter:listen_weapon_users("scp049")

    local walkSpeed = config049.walk_speed
    local runSpeed = config049.run_speed

    augscp049.filter.event_added:add_listener("scp049:setup", function(ply)
        if not IsValid(ply) then return end
        ply:SetSlowWalkSpeed(walkSpeed)
        ply:SetWalkSpeed(walkSpeed)
        ply:SetRunSpeed(runSpeed)
    end)

    augscp049.filter_zombies:listen_disconnect()
    augscp049.filter_zombies:listen_weapon_users("scp049_zombie")

    augscp049.filter_zombies.event_removed:add_listener("scp049_zombie:died", function(ply)
        local scps = augscp049.filter:get_entities()
        if #scps == 0 then return end

        for i = 1, #scps do
            local v = scps[i]
            if IsValid(v) then
                v:ChatPrint("One of your zombies is dead")
            end
        end
    end)
end

function augscp049.is_scp_049(ply)
    ply = ply or (CLIENT and LocalPlayer() or nil)
    return ply and augscp049.filter:is_in(ply) or false
end

function augscp049.is_scp_049_zombie(ply)
    ply = ply or (CLIENT and LocalPlayer() or nil)
    return ply and augscp049.filter_zombies:is_in(ply) or false
end
