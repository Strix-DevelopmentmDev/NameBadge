local badgeStates = {}
local attachedObjects = {}
local placementMode = false
local currentPlacement = nil
local previewObject = nil

local function notify(msg)
    lib.notify({
        title = 'Strix Badge',
        description = msg,
        type = 'inform'
    })
end

RegisterNetEvent('strix_badge:client:notify', function(msg)
    notify(msg)
end)

local function loadModel(model)
    if type(model) == 'string' then
        model = joaat(model)
    end

    if not IsModelInCdimage(model) then return false end
    RequestModel(model)

    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10)
        timeout += 1
        if timeout >= 500 then
            return false
        end
    end

    return model
end

local function drawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(0.30, 0.30)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

local function removeAttachedObject(serverId)
    if attachedObjects[serverId] and DoesEntityExist(attachedObjects[serverId]) then
        DeleteObject(attachedObjects[serverId])
    end
    attachedObjects[serverId] = nil
end

local function attachBadgeToPlayer(serverId, data)
    removeAttachedObject(serverId)

    local player = GetPlayerFromServerId(serverId)
    if player == -1 then return end

    local ped = GetPlayerPed(player)
    if ped == 0 or not DoesEntityExist(ped) then return end

    local model = loadModel(data.prop)
    if not model then return end

    local obj = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
    SetEntityAsMissionEntity(obj, true, true)
    SetModelAsNoLongerNeeded(model)

    AttachEntityToEntity(
        obj,
        ped,
        GetPedBoneIndex(ped, data.bone),
        data.placement.x,
        data.placement.y,
        data.placement.z,
        data.placement.rx,
        data.placement.ry,
        data.placement.rz,
        true, true, false, true, 1, true
    )

    attachedObjects[serverId] = obj
end

local function updateBadge(serverId, data)
    badgeStates[serverId] = data
    if data and data.enabled then
        attachBadgeToPlayer(serverId, data)
    else
        removeAttachedObject(serverId)
    end
end

RegisterNetEvent('strix_badge:client:setBadgeState', function(serverId, data)
    updateBadge(serverId, data)
end)

RegisterNetEvent('strix_badge:client:removeBadgeState', function(serverId)
    badgeStates[serverId] = nil
    removeAttachedObject(serverId)
end)

RegisterNetEvent('strix_badge:client:loadStates', function(states)
    for serverId, data in pairs(states) do
        updateBadge(tonumber(serverId), data)
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('strix_badge:server:requestStates')
end)

RegisterCommand(Config.BadgeCommand, function()
    TriggerServerEvent('strix_badge:server:toggleBadge')
end)

RegisterCommand(Config.PlaceCommand, function()
    TriggerServerEvent('strix_badge:server:requestPlacement')
end)

RegisterCommand(Config.ResetCommand, function()
    TriggerServerEvent('strix_badge:server:resetPlacement')
end)

RegisterNetEvent('strix_badge:client:startPlacement', function(placement)
    if placementMode then return end

    local ped = PlayerPedId()
    local model = loadModel(Config.BadgeProp)
    if not model then return end

    previewObject = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
    SetEntityAlpha(previewObject, 180, false)
    SetEntityCollision(previewObject, false, false)

    currentPlacement = {
        x = placement.x,
        y = placement.y,
        z = placement.z,
        rx = placement.rx,
        ry = placement.ry,
        rz = placement.rz
    }

    AttachEntityToEntity(
        previewObject,
        ped,
        GetPedBoneIndex(ped, Config.BadgeBone),
        currentPlacement.x,
        currentPlacement.y,
        currentPlacement.z,
        currentPlacement.rx,
        currentPlacement.ry,
        currentPlacement.rz,
        true, true, false, true, 1, true
    )

    placementMode = true
    notify(Locale('placement_on'))
end)

CreateThread(function()
    while true do
        if not placementMode then
            Wait(1000)
        else
            Wait(0)

            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)

            if IsControlJustPressed(0, 172) then currentPlacement.z += 0.005 end -- arrow up
            if IsControlJustPressed(0, 173) then currentPlacement.z -= 0.005 end -- arrow down
            if IsControlJustPressed(0, 174) then currentPlacement.x -= 0.005 end -- arrow left
            if IsControlJustPressed(0, 175) then currentPlacement.x += 0.005 end -- arrow right

            if IsControlJustPressed(0, 10) then currentPlacement.y += 0.005 end -- page up
            if IsControlJustPressed(0, 11) then currentPlacement.y -= 0.005 end -- page down

            if IsControlJustPressed(0, 15) then currentPlacement.rz += 2.0 end -- mouse wheel up
            if IsControlJustPressed(0, 14) then currentPlacement.rz -= 2.0 end -- mouse wheel down

            if IsControlJustPressed(0, 191) then -- enter
                placementMode = false

                if previewObject and DoesEntityExist(previewObject) then
                    DeleteObject(previewObject)
                    previewObject = nil
                end

                TriggerServerEvent('strix_badge:server:savePlacement', currentPlacement)
                currentPlacement = nil
            end

            if IsControlJustPressed(0, 177) then -- backspace
                placementMode = false

                if previewObject and DoesEntityExist(previewObject) then
                    DeleteObject(previewObject)
                    previewObject = nil
                end

                currentPlacement = nil
                notify(Locale('placement_cancelled'))
            end

            if previewObject and DoesEntityExist(previewObject) then
                local ped = PlayerPedId()

                AttachEntityToEntity(
                    previewObject,
                    ped,
                    GetPedBoneIndex(ped, Config.BadgeBone),
                    currentPlacement.x,
                    currentPlacement.y,
                    currentPlacement.z,
                    currentPlacement.rx,
                    currentPlacement.ry,
                    currentPlacement.rz,
                    true, true, false, true, 1, true
                )
            end
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local myCoords = GetEntityCoords(PlayerPedId())

        for serverId, data in pairs(badgeStates) do
            local player = GetPlayerFromServerId(serverId)
            if player ~= -1 then
                local ped = GetPlayerPed(player)

                if ped ~= 0 and DoesEntityExist(ped) then
                    local coords = GetEntityCoords(ped)
                    local dist = #(myCoords - coords)

                    if dist < Config.DrawDistance then
                        sleep = 0

                        if not attachedObjects[serverId] or not DoesEntityExist(attachedObjects[serverId]) then
                            attachBadgeToPlayer(serverId, data)
                        end

                        if Config.Use3DText then
                            local textCoords = coords + vec3(0.0, 0.0, 1.05)
                            local label = ('%s\n%s | %s'):format(data.name, data.title, data.job)
                            drawText3D(textCoords, label)
                        end
                    else
                        removeAttachedObject(serverId)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for serverId in pairs(attachedObjects) do
        removeAttachedObject(serverId)
    end

    if previewObject and DoesEntityExist(previewObject) then
        DeleteObject(previewObject)
    end
end)