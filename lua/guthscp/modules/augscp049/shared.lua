local augscp049 = guthscp.modules.augscp049
local config049 = guthscp.configs.augscp049

augscp049.filter = guthscp.players_filter:new("scp049")
augscp049.filter_zombies = guthscp.players_filter:new("scp049_zombie")

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

    augscp049.filter.event_added:add_listener("scp049:setup", function(ply)
        ply:SetSlowWalkSpeed(config049.walk_speed)
        ply:SetWalkSpeed(config049.walk_speed)
        ply:SetRunSpeed(config049.run_speed)
    end)

    augscp049.filter_zombies:listen_disconnect()
    augscp049.filter_zombies:listen_weapon_users("scp049_zombie")

    augscp049.filter_zombies.event_removed:add_listener("scp049_zombie:died", function(ply)
        for _, v in ipairs(augscp049.filter:get_entities()) do
            v:ChatPrint("One of your zombies is dead")
        end
    end)
end

function augscp049.is_scp_049(ply)
    if CLIENT and not ply then ply = LocalPlayer() end
    return augscp049.filter:is_in(ply)
end

function augscp049.is_scp_049_zombie(ply)
    if CLIENT and not ply then ply = LocalPlayer() end
    return augscp049.filter_zombies:is_in(ply)
end

function augscp049.GetZombieTypes049()
    return {
        [1] = {
            name = config049.scout_name,
            model = config049.scout_model,
            health = config049.scout_health,
            speed = config049.scout_speed,
        },
        [2] = {
            name = config049.jugg_name,
            model = config049.jugg_model,
            health = config049.jugg_health,
            speed = config049.jugg_speed,
        },
        [3] = {
            name = config049.normal_name,
            model = config049.normal_model,
            health = config049.normal_health,
            speed = config049.normal_speed,
        },
    }
end

augscp049.DefaultZombieType = 2 -- Le type par défaut (Normal)