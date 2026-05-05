local isTesting = false

local function GetClosestPlayer(maxDistance)
    local ped         = PlayerPedId()
    local coords      = GetEntityCoords(ped)
    local closest     = nil
    local closestDist = maxDistance

    for _, pid in ipairs(GetActivePlayers()) do
        local target = GetPlayerPed(pid)
        if target ~= ped and DoesEntityExist(target) then
            local dist = #(coords - GetEntityCoords(target))
            if dist < closestDist then
                closest     = pid
                closestDist = dist
            end
        end
    end

    return closest
end

local function SpawnBreathalyzerProp()
    Citizen.CreateThread(function()
        local ped    = PlayerPedId()
        local hash   = `prop_inhaler_01`
        local boneId = 28422

        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(50) end

        local coords = GetEntityCoords(ped)
        local prop   = CreateObject(hash, coords.x, coords.y, coords.z, true, false, false)

        AttachEntityToEntity(
            prop, ped,
            GetPedBoneIndex(ped, boneId),
             0.145,   0.021,  -0.060,
            -90.0,  -180.0,  -85.0,
            true, true, false, true, 0, true
        )

        SetModelAsNoLongerNeeded(hash)
        Wait(Config.AnimationDuration)

        if DoesEntityExist(prop) then DeleteEntity(prop) end
    end)
end

local function RunTestAnimation()
    SpawnBreathalyzerProp()
    return lib.progressBar({
        duration     = Config.AnimationDuration,
        label        = 'Conducting breath test...',
        useWhileDead = false,
        canCancel    = false,
        disable = {
            move   = true,
            car    = true,
            combat = true,
        },
        anim = {
            dict  = 'weapons@first_person@aim_rng@generic@projectile@shared@core',
            clip  = 'idlerng_med',
            flags = 49,
        },
    })
end

local function IsAuthorized()
    local job = Bridge.GetLocalJob()
    if not job then return false end
    for _, allowed in ipairs(Config.AllowedJobs) do
        if allowed == job then return true end
    end
    return false
end

local function InitiateTest()
    if isTesting then
        lib.notify({ type = 'error', description = 'Already conducting a test.' })
        return
    end

    if not IsAuthorized() then
        lib.notify({ type = 'error', description = 'You are not authorised to use this device.' })
        return
    end

    local closestPlayer = GetClosestPlayer(Config.MaxTestDistance)
    if not closestPlayer then
        lib.notify({ type = 'error', description = 'No one is close enough to test.' })
        return
    end

    local targetServerId = GetPlayerServerId(closestPlayer)
    isTesting = true

    local completed = RunTestAnimation()
    isTesting = false

    if completed then
        TriggerServerEvent('kg-alcolizer:server:requestTest', targetServerId)
    end
end

RegisterCommand('breathalyzer', function()
    InitiateTest()
end, false)

RegisterKeyMapping('breathalyzer', 'Conduct Breath Test', 'keyboard', 'F7')

-- Dev Mode NPC Testing
Citizen.CreateThread(function()
    if not Config.DevMode then return end
    
    local models = { "mp_m_freemode_01", "mp_f_freemode_01", "a_m_m_business_01", "a_f_m_business_01" } -- Add more as needed
    
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addGlobalPeds({
            {
                name = 'breathalyzer_npc_test',
                icon = 'fas fa-wind',
                label = 'Breath Test [DEV]',
                canInteract = function() return Config.DevMode and IsAuthorized() end,
                onSelect = function(data)
                    if isTesting then return end
                    isTesting = true
                    local completed = RunTestAnimation()
                    isTesting = false
                    if completed then
                        -- Simulate a server result for an NPC
                        local bac = math.random(0, 250) / 1000 -- 0.000 to 0.250
                        TriggerEvent('kg-alcolizer:client:receiveResult', {
                            bac = bac,
                            legalLimit = Config.LegalLimit,
                            overLimit = bac > Config.LegalLimit,
                            suspectName = "[DEV] NPC",
                            officerName = "Local Officer",
                        })
                    end
                end
            }
        })
    end
end)

RegisterNetEvent('kg-alcolizer:client:receiveResult', function(result)
    if not result then return end

    SetNuiFocus(false, false)
    SendNUIMessage({
        type        = 'kg-alcolizer:showResult',
        bac         = result.bac,
        legalLimit  = result.legalLimit,
        overLimit   = result.overLimit,
        suspectName = result.suspectName,
        officerName = result.officerName,
    })

    TriggerEvent('kg-alcolizer:result', result)
end)

RegisterNetEvent('kg-alcolizer:client:onCooldown', function(remaining)
    lib.notify({
        type        = 'error',
        description = ('This person was tested recently — wait %ds.'):format(remaining),
    })
end)

RegisterNetEvent('kg-alcolizer:client:notify', function(msg, notifType)
    lib.notify({ type = notifType or 'inform', description = msg })
end)
