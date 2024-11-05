---@diagnostic disable: undefined-global
local RSGCore = exports['rsg-core']:GetCoreObject()
local playerMiningSkills = {}

MySQL.ready(function()
    MySQL.query([[
        ALTER TABLE players
        ADD COLUMN IF NOT EXISTS mining_level FLOAT DEFAULT 1
    ]])
end)

local function loadPlayerMiningLevel(citizenid)
    local result = MySQL.scalar.await("SELECT mining_level FROM players WHERE citizenid = ?", { citizenid })
    playerMiningSkills[citizenid] = result or CONFIG.PLAYER_MINING_LEVELS_INIT
end

local function savePlayerMiningLevel(citizenid)
    local level = playerMiningSkills[citizenid] or CONFIG.PLAYER_MINING_LEVELS_INIT
    MySQL.update("UPDATE players SET mining_level = ? WHERE citizenid = ?", { level, citizenid })
end

RegisterNetEvent("dvr_miner:getMiningLevel", function()
    local playerId = source
    local Player = RSGCore.Functions.GetPlayer(playerId)
    if not Player then return end
    local citizenId = Player.PlayerData.citizenid

    if not playerMiningSkills[citizenId] then
        loadPlayerMiningLevel(citizenId)
    end

    TriggerClientEvent("dvr_miner:returnMiningLevel", playerId, playerMiningSkills[citizenId])
end)

RegisterNetEvent("dvr_miner:increaseMiningLevel", function()
    local playerId = source
    local Player = RSGCore.Functions.GetPlayer(playerId)
    if not Player then return end
    local citizenId = Player.PlayerData.citizenid

    local currentLevel = playerMiningSkills[citizenId] or CONFIG.PLAYER_MINING_LEVELS_INIT
    local newLevel = currentLevel + CONFIG.PLAYER_MINING_LEVELS_INCREMENT

    if newLevel > CONFIG.PLAYER_MINING_LEVELS_MAX then
        newLevel = CONFIG.PLAYER_MINING_LEVELS_MAX
    else
        playerMiningSkills[citizenId] = newLevel
        savePlayerMiningLevel(citizenId)
    end

    TriggerClientEvent("dvr_miner:returnMiningLevel", playerId, newLevel)
end)

RegisterNetEvent("dvr_miner:rewardResources", function(resources)
    local playerId = source
    for _, resourceName in ipairs(resources) do
        exports["rsg-inventory"]:AddItem(playerId, resourceName, 1)
        TriggerClientEvent('ox_lib:notify', playerId, {
            title = "Miner",
            message = "Vous avez obtenu : " .. resourceName,
            type = "success",
            duration = 5000,
            position = "center-right",
        })
    end
end)