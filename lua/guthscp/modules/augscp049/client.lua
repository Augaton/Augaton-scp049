local augscp049 = guthscp.modules.augscp049
local config049 = guthscp.configs.augscp049

augscp049.last_scan = nil

net.Receive("scp049-aura-result", function()
    local ent = net.ReadEntity()
    local aura = net.ReadString()
    if not IsValid(ent) then return end

    augscp049.last_scan = {
        ent = ent,
        aura = aura,
        expire = CurTime() + config049.aura_reveal_duration,
    }
end)

function augscp049.GetActiveScan()
    local scan = augscp049.last_scan
    if not scan then return nil end
    if scan.expire < CurTime() or not IsValid(scan.ent) then
        augscp049.last_scan = nil
        return nil
    end
    return scan
end

hook.Add("PreDrawHalos", "augscp049:aura_halo", function()
    if not augscp049.is_scp_049() then return end

    local scan = augscp049.GetActiveScan()
    if not scan then return end

    local data = augscp049.GetAuraData()[scan.aura]
    if not data then return end

    halo.Add({ scan.ent }, data.color, 4, 4, 2, true, true)
end)
