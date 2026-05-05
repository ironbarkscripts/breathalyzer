local framework = nil

if Config.Framework == 'auto' then
    if GetResourceState('qbx_core') == 'started' then
        framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        framework = 'qb'
    end
else
    framework = Config.Framework
end

local function GetPlayer(source)
    if framework == 'qbx' then
        return exports.qbx_core:GetPlayer(source)
    elseif framework == 'qb' then
        return exports['qb-core']:GetPlayer(source)
    end
end

local function GetPlayerJob(source)
    local Player = GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.job.name
end

-- Client-side only: returns the local player's current job name
local function GetLocalJob()
    if IsDuplicityVersion() then return nil end
    if framework == 'qbx' then
        local data = exports.qbx_core:GetPlayerData()
        return data and data.job and data.job.name
    elseif framework == 'qb' then
        local data = exports['qb-core']:GetPlayerData()
        return data and data.job and data.job.name
    end
end

Bridge = {
    GetPlayer    = GetPlayer,
    GetPlayerJob = GetPlayerJob,
    GetLocalJob  = GetLocalJob,
    framework    = framework,
}
