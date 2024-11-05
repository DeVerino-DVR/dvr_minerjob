---@diagnostic disable: undefined-global, param-type-mismatch, redundant-parameter, trailing-space
local playerMiningLevel = CONFIG.PLAYER_MINING_LEVELS_INIT

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent("dvr_miner:getMiningLevel")
end)

local function hasRequiredTool(playerId, requiredTool)
    if CONFIG.DEBUG then
        return true
    end
    
    local hasItem = exports["rsg-inventory"]:HasItem(playerId, requiredTool)
    return hasItem
end

local function getRandomResources(miningLevel)
    if miningLevel < 1.0 then
        return {}
    end

    local validResources = {}
    for _, resource in ipairs(CONFIG.REWARS) do
        if miningLevel >= resource.levelRequired then
            table.insert(validResources, resource)
        end
    end

    local collectedResources = {}
    for _, resource in ipairs(validResources) do
        local roll = math.random(0, 100) + (miningLevel * 2)
        if roll <= resource.chance then
            table.insert(collectedResources, resource.name)
        end
    end

    return collectedResources
end

local function startMining()
    local playerPed = PlayerPedId()
    local resources = getRandomResources(playerMiningLevel)

    if #resources > 0 then
        TaskStartScenarioInPlace(playerPed, joaat('WORLD_HUMAN_PICKAXE_WALL'), 30000, true, false, false, false)
        if lib.progressBar({
            duration = 30000,
            label = 'Vous minez ...',
            useWhileDead = false,
            canCancel = true,
        }) then
            local eligibleResources = {}
            for _, resource in ipairs(resources) do
                if hasRequiredTool(resource.requiredTool) then
                    table.insert(eligibleResources, resource)
                else
                    lib.notify({
                        title = "Outil requis",
                        message = "Vous avez besoin de : " .. resource.requiredTool .. " pour miner " .. resource.name,
                        type = "warning",
                        duration = 5000,
                        position = "center-right",
                    })
                end
            end

            if #eligibleResources > 0 then
                TriggerServerEvent("dvr_miner:rewardResources", eligibleResources)
                TriggerServerEvent("dvr_miner:increaseMiningLevel")
            else
                TriggerServerEvent("dvr_miner:increaseMiningLevel")
                lib.notify({
                    title = "XP uniquement",
                    message = "Vous avez gagné de l'expérience sans obtenir de ressources.",
                    type = "info",
                    duration = 5000,
                    position = "center-right",
                })
            end

            ClearPedTasksImmediately(playerPed)
        else
            return ClearPedTasksImmediately(playerPed)
        end
    else
        if playerMiningLevel < 1.0 then
            TaskStartScenarioInPlace(playerPed, joaat('WORLD_HUMAN_PICKAXE_WALL'), 40000, true, false, false, false)
            if lib.progressBar({
                duration = 40000,
                label = 'Vous minez ...',
                useWhileDead = false,
                canCancel = true,
            }) then
                lib.notify({
                    title = "Gain d'expérience",
                    message = "Vous avez gagné de l'expérience mais pas de ressources.",
                    type = "info",
                    duration = 5000,
                    position = "center-right",
                })
                TriggerServerEvent("dvr_miner:increaseMiningLevel")
                ClearPedTasksImmediately(playerPed)
            else
                return ClearPedTasksImmediately(playerPed)
            end
        else
            lib.notify({
                title = "Pas de ressources",
                message = "Aucune ressource trouvée.",
                type = "error",
                duration = 5000,
                position = "center-right",
            })
        end
    end
end

CreateThread(function()
    for _, coords in ipairs(CONFIG.MINER_COORDS) do
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 2.0,
            options = {
                {
                    name = 'miner_zone',
                    event = 'dvr_miner:startMining',
                    label = 'Miner ici',
                    distance = 1.5,
                    onSelect = function()
                        startMining()
                    end,
                }
            }
        })
    end
end)

RegisterNetEvent("dvr_miner:returnMiningLevel", function(level)
    playerMiningLevel = level
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        TriggerServerEvent("dvr_miner:getMiningLevel")
    end
end)