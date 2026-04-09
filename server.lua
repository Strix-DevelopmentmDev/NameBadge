local playersBadgeState = {}
local playerPlacementCache = {}

local function detectFramework()
    if Config.Framework ~= 'auto' then
        Framework.Type = Config.Framework
        return
    end

    if GetResourceState('es_extended') == 'started' then
        Framework.Type = 'esx'
    elseif GetResourceState('qb-core') == 'started' then
        Framework.Type = 'qb'
    elseif GetResourceState('qbx_core') == 'started' then
        Framework.Type = 'qbox'
    else
        Framework.Type = 'custom'
    end

    print(('[strix_badge] Framework detected: %s'):format(Framework.Type))
end

detectFramework()

local function getPlayerData(source)
    if Framework.Type == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return nil end

        local first = xPlayer.get('firstName') or xPlayer.getName() or 'John'
        local last = xPlayer.get('lastName') or ''
        local job = xPlayer.job and xPlayer.job.name or 'unemployed'
        local grade = xPlayer.job and xPlayer.job.grade or 0
        local jobLabel = xPlayer.job and xPlayer.job.label or job
        local rankLabel = xPlayer.job and xPlayer.job.grade_label or tostring(grade)

        return {
            citizenid = xPlayer.identifier,
            firstname = first,
            lastname = last,
            job = job,
            grade = grade,
            jobLabel = jobLabel,
            rankLabel = rankLabel
        }
    elseif Framework.Type == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return nil end

        local info = Player.PlayerData.charinfo or {}
        local jobData = Player.PlayerData.job or {}

        return {
            citizenid = Player.PlayerData.citizenid,
            firstname = info.firstname or 'John',
            lastname = info.lastname or 'Doe',
            job = jobData.name or 'unemployed',
            grade = jobData.grade and (jobData.grade.level or jobData.grade) or 0,
            jobLabel = jobData.label or (jobData.name or 'Unemployed'),
            rankLabel = jobData.grade and (jobData.grade.name or tostring(jobData.grade.level or 0)) or 'Employee'
        }
    elseif Framework.Type == 'qbox' then
        local Player = exports.qbx_core:GetPlayer(source)
        if not Player then return nil end

        local charinfo = Player.PlayerData.charinfo or {}
        local jobData = Player.PlayerData.job or {}

        return {
            citizenid = Player.PlayerData.citizenid,
            firstname = charinfo.firstname or 'John',
            lastname = charinfo.lastname or 'Doe',
            job = jobData.name or 'unemployed',
            grade = jobData.grade and (jobData.level or jobData.grade.level or 0) or 0,
            jobLabel = jobData.label or (jobData.name or 'Unemployed'),
            rankLabel = jobData.grade and (jobData.grade.name or tostring(jobData.grade.level or 0)) or 'Employee'
        }
    elseif Framework.Type == 'custom' then
        return Config.CustomFramework.getPlayerData(source)
    end

    return nil
end

local function canUseBadge(job)
    if not Config.RestrictJobs then return true end
    return Config.AllowedJobs[job] == true
end

local function getRankLabel(job, grade, fallback)
    if Config.CustomRanks[job] and Config.CustomRanks[job][grade] then
        return Config.CustomRanks[job][grade]
    end

    if Config.UseJobGradesAsRank then
        return fallback or tostring(grade)
    end

    return fallback or 'Employee'
end

local function fetchPlacement(identifier)
    if not Config.SavePlacement then
        return {
            x = Config.DefaultOffset.x,
            y = Config.DefaultOffset.y,
            z = Config.DefaultOffset.z,
            rx = Config.DefaultRotation.x,
            ry = Config.DefaultRotation.y,
            rz = Config.DefaultRotation.z
        }
    end

    local row = MySQL.single.await('SELECT * FROM strix_badge_positions WHERE identifier = ?', { identifier })
    if row then
        return row
    end

    return {
        x = Config.DefaultOffset.x,
        y = Config.DefaultOffset.y,
        z = Config.DefaultOffset.z,
        rx = Config.DefaultRotation.x,
        ry = Config.DefaultRotation.y,
        rz = Config.DefaultRotation.z
    }
end

local function savePlacement(identifier, placement)
    if not Config.SavePlacement then return end

    MySQL.insert.await([[
        INSERT INTO strix_badge_positions (identifier, x, y, z, rx, ry, rz)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            x = VALUES(x),
            y = VALUES(y),
            z = VALUES(z),
            rx = VALUES(rx),
            ry = VALUES(ry),
            rz = VALUES(rz)
    ]], {
        identifier,
        placement.x,
        placement.y,
        placement.z,
        placement.rx,
        placement.ry,
        placement.rz
    })
end

RegisterNetEvent('strix_badge:server:toggleBadge', function()
    local src = source
    local data = getPlayerData(src)
    if not data then return end

    if not canUseBadge(data.job) then
        TriggerClientEvent('strix_badge:client:notify', src, Locale('no_job'))
        return
    end

    if playersBadgeState[src] and playersBadgeState[src].enabled then
        playersBadgeState[src] = nil
        TriggerClientEvent('strix_badge:client:setBadgeState', -1, src, nil)
        TriggerClientEvent('strix_badge:client:notify', src, Locale('badge_off'))
        return
    end

    local placement = fetchPlacement(data.citizenid)
    local rankLabel = getRankLabel(data.job, data.grade, data.rankLabel)

    local badgeData = {
        enabled = true,
        name = (data.firstname or '') .. ' ' .. (data.lastname or ''),
        title = rankLabel,
        job = data.jobLabel or data.job,
        prop = Config.BadgeProp,
        bone = Config.BadgeBone,
        placement = {
            x = placement.x,
            y = placement.y,
            z = placement.z,
            rx = placement.rx,
            ry = placement.ry,
            rz = placement.rz
        }
    }

    playersBadgeState[src] = badgeData
    TriggerClientEvent('strix_badge:client:setBadgeState', -1, src, badgeData)
    TriggerClientEvent('strix_badge:client:notify', src, Locale('badge_on'))
end)

RegisterNetEvent('strix_badge:server:requestPlacement', function()
    local src = source
    local data = getPlayerData(src)
    if not data then return end

    local placement = fetchPlacement(data.citizenid)
    TriggerClientEvent('strix_badge:client:startPlacement', src, {
        x = placement.x,
        y = placement.y,
        z = placement.z,
        rx = placement.rx,
        ry = placement.ry,
        rz = placement.rz
    })
end)

RegisterNetEvent('strix_badge:server:savePlacement', function(placement)
    local src = source
    local data = getPlayerData(src)
    if not data then return end

    savePlacement(data.citizenid, placement)

    if playersBadgeState[src] then
        playersBadgeState[src].placement = placement
        TriggerClientEvent('strix_badge:client:setBadgeState', -1, src, playersBadgeState[src])
    end

    TriggerClientEvent('strix_badge:client:notify', src, Locale('placement_saved'))
end)

RegisterNetEvent('strix_badge:server:resetPlacement', function()
    local src = source
    local data = getPlayerData(src)
    if not data then return end

    local placement = {
        x = Config.DefaultOffset.x,
        y = Config.DefaultOffset.y,
        z = Config.DefaultOffset.z,
        rx = Config.DefaultRotation.x,
        ry = Config.DefaultRotation.y,
        rz = Config.DefaultRotation.z
    }

    savePlacement(data.citizenid, placement)

    if playersBadgeState[src] then
        playersBadgeState[src].placement = placement
        TriggerClientEvent('strix_badge:client:setBadgeState', -1, src, playersBadgeState[src])
    end

    TriggerClientEvent('strix_badge:client:notify', src, Locale('placement_reset'))
end)

AddEventHandler('playerDropped', function()
    local src = source
    if playersBadgeState[src] then
        playersBadgeState[src] = nil
        TriggerClientEvent('strix_badge:client:removeBadgeState', -1, src)
    end
end)

RegisterNetEvent('strix_badge:server:requestStates', function()
    local src = source
    TriggerClientEvent('strix_badge:client:loadStates', src, playersBadgeState)
end)