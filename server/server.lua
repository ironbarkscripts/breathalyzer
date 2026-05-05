-- Per-suspect cooldown: [serverId] = os.time() of last test
local cooldowns   = {}

-- Last known result per suspect; readable via the getLastResult export
local lastResults = {}

local function HasAllowedJob(source)
    local job = Bridge.GetPlayerJob(source)
    if not job then return false end
    for _, allowed in ipairs(Config.AllowedJobs) do
        if allowed == job then return true end
    end
    return false
end

local function GetPlayerDistance(src1, src2)
    local ped1 = GetPlayerPed(src1)
    local ped2 = GetPlayerPed(src2)
    if not ped1 or not ped2 then return 999.0 end
    local c1 = GetEntityCoords(ped1)
    local c2 = GetEntityCoords(ped2)
    return #(vector3(c1.x, c1.y, c1.z) - vector3(c2.x, c2.y, c2.z))
end

local function LogTest(officerName, suspectName, bac, legalLimit, overLimit, coords)
    if not Config.EnableLogging then return end

    local ts     = os.date('%Y-%m-%d %H:%M:%S')
    local status = overLimit and 'OVER LIMIT' or 'CLEAR'
    local line   = ('[%s] [kg-alcolizer] Officer: %s | Suspect: %s | BAC: %.3f | Limit: %.3f | %s | Coords: %.1f, %.1f, %.1f'):format(
        ts, officerName, suspectName, bac, legalLimit, status,
        coords.x, coords.y, coords.z
    )

    print(line)

    if Config.LogToFile then
        local f = io.open(Config.LogFilePath, 'a')
        if f then
            f:write(line .. '\n')
            f:close()
        end
    end
end

RegisterNetEvent('kg-alcolizer:server:requestTest', function(targetId)
    local officerId = source

    if not HasAllowedJob(officerId) then
        TriggerClientEvent('kg-alcolizer:client:notify', officerId,
            'You are not authorised to use this device.', 'error')
        return
    end

    local suspectPlayer = Bridge.GetPlayer(targetId)
    if not suspectPlayer then
        TriggerClientEvent('kg-alcolizer:client:notify', officerId,
            'Suspect not found.', 'error')
        return
    end

    local dist = GetPlayerDistance(officerId, targetId)
    if dist > (Config.MaxTestDistance + 2.0) then
        TriggerClientEvent('kg-alcolizer:client:notify', officerId,
            'Suspect is too far away.', 'error')
        return
    end

    local now = os.time()
    if cooldowns[targetId] and (now - cooldowns[targetId]) < Config.TestCooldown then
        local remaining = Config.TestCooldown - (now - cooldowns[targetId])
        TriggerClientEvent('kg-alcolizer:client:onCooldown', officerId, remaining)
        return
    end

    local rawAlcohol = suspectPlayer.PlayerData.metadata.alcohol
    local bac        = tonumber(rawAlcohol) or 0.0
    local overLimit = bac > Config.LegalLimit

    local officerPlayer = Bridge.GetPlayer(officerId)
    local officerName   = officerPlayer
        and (officerPlayer.PlayerData.charinfo.firstname .. ' ' .. officerPlayer.PlayerData.charinfo.lastname)
        or  'Unknown Officer'

    local suspectName = suspectPlayer.PlayerData.charinfo.firstname
        .. ' ' .. suspectPlayer.PlayerData.charinfo.lastname

    local coords = GetEntityCoords(GetPlayerPed(officerId))

    LogTest(officerName, suspectName, bac, Config.LegalLimit, overLimit, coords)

    lastResults[targetId] = {
        bac         = bac,
        legalLimit  = Config.LegalLimit,
        overLimit   = overLimit,
        officerId   = officerId,
        officerName = officerName,
        suspectId   = targetId,
        suspectName = suspectName,
        timestamp   = now,
    }

    cooldowns[targetId] = now

    TriggerClientEvent('kg-alcolizer:client:receiveResult', officerId, lastResults[targetId])
end)

exports('getLastResult', function(suspectServerId)
    return lastResults[tonumber(suspectServerId)]
end)

-- Dev Mode Command: Set BAC for testing without drinking alcohol.
-- Usage: /setbac <serverid> <value>   e.g. /setbac 1 0.09
RegisterCommand('setbac', function(source, args)
    if not Config.DevMode then
        if source ~= 0 then
            TriggerClientEvent('kg-alcolizer:client:notify', source, 'Dev mode is disabled.', 'error')
        else
            print('[kg-alcolizer] Dev mode is disabled.')
        end
        return
    end

    local targetId = tonumber(args[1])
    local bac      = tonumber(args[2])

    if not targetId or not bac then
        if source ~= 0 then
            TriggerClientEvent('kg-alcolizer:client:notify', source, 'Usage: /setbac <id> <value>', 'info')
        else
            print('[kg-alcolizer] Usage: setbac <id> <value>')
        end
        return
    end

    local p = Bridge.GetPlayer(targetId)
    if not p then
        if source ~= 0 then
            TriggerClientEvent('kg-alcolizer:client:notify', source, 'Player not found.', 'error')
        else
            print('[kg-alcolizer] Player not found: ' .. tostring(targetId))
        end
        return
    end

    p.Functions.SetMetaData('alcohol', bac)
    
    if source ~= 0 then
        TriggerClientEvent('kg-alcolizer:client:notify', source, ('Set BAC for ID %d to %.2f'):format(targetId, bac), 'success')
    else
        print(('[kg-alcolizer] Set BAC for ID %d to %.2f'):format(targetId, bac))
    end
end, true)