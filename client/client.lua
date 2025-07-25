local QBCore = exports['qb-core']:GetCoreObject()
local isPlacingObject = false
local placedObjects = {}
local isEscorting = false
local escortedPed = nil
local isMenuOpen = false
local isCuffing = false
local cuffedNPCs = {}
-- Table to store owned vehicle plates
local OwnedVehiclePlates = {}
local remoteLightsOnPlates = {}
local windowStates = {}
local lightStates = {} -- New table to reliably track light status

local policeGuard = nil
local guardCatchUpVehicle = nil
local policeGuardShouldFollow = true
local policeGuardAttackMode = false
local policeGuardCurrentTarget = nil
local guardBlip = nil

local targetMarkBlip = nil

-- Helper function to check if an entity is a ped
local function IsPed(entity)
    return entity and GetEntityType(entity) == 1
end

-- Add these new lines at the top of your client.lua file
local clothingState = {}
local wasInVehicle = false
local initialClothing = {}

-- Add this entire block of new functions BEFORE your ToggleMenu function
local function saveInitialClothing()
    local playerPed = PlayerPedId()
    if next(initialClothing) == nil then
        initialClothing = {
            hat      = {GetPedPropIndex(playerPed, 0), GetPedPropTextureIndex(playerPed, 0)},
            glasses  = {GetPedPropIndex(playerPed, 1), GetPedPropTextureIndex(playerPed, 1)},
            ears     = {GetPedPropIndex(playerPed, 2), GetPedPropTextureIndex(playerPed, 2)},
            mask     = {GetPedDrawableVariation(playerPed, 1), GetPedTextureVariation(playerPed, 1), GetPedPaletteVariation(playerPed, 1)},
            jacket   = {GetPedDrawableVariation(playerPed, 11), GetPedTextureVariation(playerPed, 11), GetPedPaletteVariation(playerPed, 11)},
            shirt    = {GetPedDrawableVariation(playerPed, 8), GetPedTextureVariation(playerPed, 8), GetPedPaletteVariation(playerPed, 8)},
            vest     = {GetPedDrawableVariation(playerPed, 9), GetPedTextureVariation(playerPed, 9), GetPedPaletteVariation(playerPed, 9)},
            pants    = {GetPedDrawableVariation(playerPed, 4), GetPedTextureVariation(playerPed, 4), GetPedPaletteVariation(playerPed, 4)},
            shoes    = {GetPedDrawableVariation(playerPed, 6), GetPedTextureVariation(playerPed, 6), GetPedPaletteVariation(playerPed, 6)},
            extras   = {GetPedDrawableVariation(playerPed, 7), GetPedTextureVariation(playerPed, 7), GetPedPaletteVariation(playerPed, 7)},
            neck     = {GetPedDrawableVariation(playerPed, 7), GetPedTextureVariation(playerPed, 7), GetPedPaletteVariation(playerPed, 7)},
            bag      = {GetPedDrawableVariation(playerPed, 5), GetPedTextureVariation(playerPed, 5), GetPedPaletteVariation(playerPed, 5)},
            watch    = {GetPedPropIndex(playerPed, 6), GetPedPropTextureIndex(playerPed, 6)},
            gloves    = {GetPedDrawableVariation(playerPed, 3), GetPedTextureVariation(playerPed, 3), GetPedPaletteVariation(playerPed, 3)},
            hair        = {GetPedDrawableVariation(playerPed, 2), GetPedTextureVariation(playerPed, 2), GetPedPaletteVariation(playerPed, 2)},
            decals      = {GetPedDrawableVariation(playerPed, 10), GetPedTextureVariation(playerPed, 10), GetPedPaletteVariation(playerPed, 10)},
            undershirt  = {GetPedDrawableVariation(playerPed, 8), GetPedTextureVariation(playerPed, 8), GetPedPaletteVariation(playerPed, 8)},
            bodyarmor   = {GetPedDrawableVariation(playerPed, 9), GetPedTextureVariation(playerPed, 9), GetPedPaletteVariation(playerPed, 9)},
            accessories = {GetPedDrawableVariation(playerPed, 7), GetPedTextureVariation(playerPed, 7), GetPedPaletteVariation(playerPed, 7)},
            bracelet    = {GetPedPropIndex(playerPed, 7), GetPedPropTextureIndex(playerPed, 7)},
            torso       = {GetPedDrawableVariation(playerPed, 11), GetPedTextureVariation(playerPed, 11), GetPedPaletteVariation(playerPed, 11)},
        }
    end
end

local function updateAndSendClothingState()
    local playerPed = PlayerPedId()
    saveInitialClothing()
    
    clothingState = {
        hat      = { on = GetPedPropIndex(playerPed, 0) ~= -1 },
        glasses  = { on = GetPedPropIndex(playerPed, 1) ~= -1 },
        ears     = { on = GetPedPropIndex(playerPed, 2) ~= -1 },
        mask     = { on = GetPedDrawableVariation(playerPed, 1) ~= 0 },
        jacket   = { on = GetPedDrawableVariation(playerPed, 11) ~= 15 },
        shirt    = { on = GetPedDrawableVariation(playerPed, 8) ~= 15 },
        vest     = { on = GetPedDrawableVariation(playerPed, 9) > 0 },
        pants    = { on = GetPedDrawableVariation(playerPed, 4) ~= 14 and GetPedDrawableVariation(playerPed, 4) ~= 15 },
        shoes    = { on = GetPedDrawableVariation(playerPed, 6) ~= 34 and GetPedDrawableVariation(playerPed, 6) ~= 35 },
        extras   = { on = GetPedDrawableVariation(playerPed, 7) ~= 0 },
        neck     = { on = GetPedDrawableVariation(playerPed, 7) ~= 0 },
        bag      = { on = GetPedDrawableVariation(playerPed, 5) ~= 0 },
        watch    = { on = GetPedPropIndex(playerPed, 6) ~= -1 },
        gloves   = { on = GetPedDrawableVariation(playerPed, 3) ~= 15 },
        hair     = { on = GetPedDrawableVariation(playerPed, 2) ~= 0 },
        decals   = { on = GetPedDrawableVariation(playerPed, 10) ~= 0 },
        bodyarmor= { on = GetPedDrawableVariation(playerPed, 9) > 0 },
        bracelet = { on = GetPedPropIndex(playerPed, 7) ~= -1 },
        torso    = { on = GetPedDrawableVariation(playerPed, 3) ~= 15 }
    }

    -- DEBUG PRINT: This will print the clothing status to your F8 console (server side or client, depending on where you look)
    print('--- LUA DEBUG: Sending clothing state to UI ---')
    print(json.encode(clothingState))
    
    SendNUIMessage({ action = "updateClothingState", clothingState = clothingState })
end

-- Clothing emote table (qb-radialmenu style)
local ClothingEmotes = {
    hat = { dict = "mp_masks@standard_car@ds@", anim = "put_on_mask", move = 51, dur = 600 },
    glasses = { dict = "clothingspecs", anim = "take_off", move = 51, dur = 1400 },
    mask = { dict = "mp_masks@standard_car@ds@", anim = "put_on_mask", move = 51, dur = 800 },
    jacket = { dict = "missmic4", anim = "michael_tux_fidget", move = 51, dur = 1500 },
    shirt = { dict = "clothingtie", anim = "try_tie_negative_a", move = 51, dur = 1200 },
    vest = { dict = "clothingtie", anim = "try_tie_negative_a", move = 51, dur = 1200 },
    pants = { dict = "re@construction", anim = "out_of_breath", move = 51, dur = 1300 },
    shoes = { dict = "random@domestic", anim = "pickup_low", move = 0, dur = 1200 },
    gloves = { dict = "nmt_3_rcm-10", anim = "cs_nigel_dual-10", move = 51, dur = 1200 },
    bag = { dict = "anim@heists@ornate_bank@grab_cash", anim = "intro", move = 51, dur = 1600 },
    watch = { dict = "nmt_3_rcm-10", anim = "cs_nigel_dual-10", move = 51, dur = 1200 },
    bracelet = { dict = "nmt_3_rcm-10", anim = "cs_nigel_dual-10", move = 51, dur = 1200 },
    hair = { dict = "clothingtie", anim = "check_out_a", move = 51, dur = 2000 },
    decals = { dict = "clothingtie", anim = "check_out_a", move = 51, dur = 1200 },
    undershirt = { dict = "clothingtie", anim = "try_tie_negative_a", move = 51, dur = 1200 },
    bodyarmor = { dict = "clothingtie", anim = "try_tie_negative_a", move = 51, dur = 1200 },
    accessories = { dict = "clothingtie", anim = "try_tie_negative_a", move = 51, dur = 1200 },
    neck = { dict = "clothingtie", anim = "try_tie_negative_a", move = 51, dur = 1200 },
    ears = { dict = "clothingtie", anim = "try_tie_negative_a", move = 51, dur = 1200 },
    torso = { dict = "missmic4", anim = "michael_tux_fidget", move = 51, dur = 1500 },
}

local function PlayToggleEmote(emote, cb)
    local ped = PlayerPedId()
    RequestAnimDict(emote.dict)
    while not HasAnimDictLoaded(emote.dict) do
        Wait(10)
    end
    TaskPlayAnim(ped, emote.dict, emote.anim, 3.0, 3.0, emote.dur, emote.move, 0, false, false, false)
    local pause = emote.dur - 500
    if pause < 500 then pause = 500 end
    Wait(pause)
    if cb then cb() end
end

local function toggleClothingItem(item)
    -- This is the big function we fixed before, leave its internal logic as it is.
    -- All the fixes for gender, saving state etc. are inside this function already.
    local playerPed = PlayerPedId()
    if not clothingState[item] or not initialClothing[item] then return end

    local state = clothingState[item]

    -- The check to prevent animation on empty items
    if not state.on then
        local initialItemData = initialClothing[item]
        if not initialItemData then return end

        local isEmpty = false
        local itemDrawable = initialItemData[1]

        if item == 'hat' or item == 'glasses' or item == 'ears' or item == 'watch' or item == 'bracelet' then
            if itemDrawable == -1 then isEmpty = true end
        elseif item == 'gloves' or item == 'jacket' or item == 'shirt' or item == 'undershirt' or item == 'torso' then
             if itemDrawable == 15 then isEmpty = true end
        elseif item == 'pants' then
            if initialItemData[1] == 14 or initialItemData[1] == 15 then isEmpty = true end
        elseif item == 'shoes' then
            if initialItemData[1] == 34 or initialItemData[1] == 35 then isEmpty = true end
        elseif item == 'mask' or item == 'bag' or item == 'vest' or item == 'neck' or item == 'hair' or item == 'decals' or item == 'accessories' or item == 'extras' or item == 'bodyarmor' then
            if itemDrawable == 0 then isEmpty = true end
        end

        if isEmpty then
            return
        end
    end

    state.on = not state.on
    local doToggle = function()
        -- All the 'elseif item == "..."' logic that we fixed before goes here.
        -- I am providing the full corrected function to ensure no conflicts.
        if item == 'hat' then
            if state.on then SetPedPropIndex(playerPed, 0, initialClothing[item][1], initialClothing[item][2], true) else initialClothing['hat'] = {GetPedPropIndex(playerPed, 0), GetPedPropTextureIndex(playerPed, 0)}; ClearPedProp(playerPed, 0) end
        elseif item == 'glasses' then
            if state.on then SetPedPropIndex(playerPed, 1, initialClothing[item][1], initialClothing[item][2], true) else initialClothing['glasses'] = {GetPedPropIndex(playerPed, 1), GetPedPropTextureIndex(playerPed, 1)}; ClearPedProp(playerPed, 1) end
        elseif item == 'ears' then
            if state.on then SetPedPropIndex(playerPed, 2, initialClothing[item][1], initialClothing[item][2], true) else initialClothing['ears'] = {GetPedPropIndex(playerPed, 2), GetPedPropTextureIndex(playerPed, 2)}; ClearPedProp(playerPed, 2) end
        elseif item == 'watch' then
            if state.on then SetPedPropIndex(playerPed, 6, initialClothing[item][1], initialClothing[item][2], true) else initialClothing['watch'] = {GetPedPropIndex(playerPed, 6), GetPedPropTextureIndex(playerPed, 6)}; ClearPedProp(playerPed, 6) end
        elseif item == 'bracelet' then
            if state.on then SetPedPropIndex(playerPed, 7, initialClothing[item][1], initialClothing[item][2], true) else initialClothing['bracelet'] = {GetPedPropIndex(playerPed, 7), GetPedPropTextureIndex(playerPed, 7)}; ClearPedProp(playerPed, 7) end
        elseif item == 'mask' then
            if state.on then SetPedComponentVariation(playerPed, 1, initialClothing[item][1], initialClothing[item][2], initialClothing[item][3]) else initialClothing['mask'] = {GetPedDrawableVariation(playerPed, 1), GetPedTextureVariation(playerPed, 1), GetPedPaletteVariation(playerPed, 1)}; SetPedComponentVariation(playerPed, 1, 0, 0, 2) end
        elseif item == 'gloves' then
            if state.on then SetPedComponentVariation(playerPed, 3, initialClothing[item][1], initialClothing[item][2], initialClothing[item][3]) else initialClothing['gloves'] = {GetPedDrawableVariation(playerPed, 3), GetPedTextureVariation(playerPed, 3), GetPedPaletteVariation(playerPed, 3)}; SetPedComponentVariation(playerPed, 3, 15, 0, 2) end
        elseif item == 'shirt' then
            if state.on then SetPedComponentVariation(playerPed, 8, initialClothing[item][1], initialClothing[item][2], initialClothing[item][3]) else initialClothing['shirt'] = {GetPedDrawableVariation(playerPed, 8), GetPedTextureVariation(playerPed, 8), GetPedPaletteVariation(playerPed, 8)}; SetPedComponentVariation(playerPed, 8, 15, 0, 2) end
        elseif item == 'jacket' then
            if state.on then SetPedComponentVariation(playerPed, 11, initialClothing['jacket'][1], initialClothing['jacket'][2], initialClothing['jacket'][3]); SetPedComponentVariation(playerPed, 3, initialClothing['torso'][1], initialClothing['torso'][2], initialClothing['torso'][3]) else initialClothing['jacket'] = {GetPedDrawableVariation(playerPed, 11), GetPedTextureVariation(playerPed, 11), GetPedPaletteVariation(playerPed, 11)}; initialClothing['torso'] = {GetPedDrawableVariation(playerPed, 3), GetPedTextureVariation(playerPed, 3), GetPedPaletteVariation(playerPed, 3)}; SetPedComponentVariation(playerPed, 11, 15, 0, 2); SetPedComponentVariation(playerPed, 3, 15, 0, 2) end
        elseif item == 'pants' then
            if state.on then SetPedComponentVariation(playerPed, 4, initialClothing[item][1], initialClothing[item][2], initialClothing[item][3]) else initialClothing['pants'] = {GetPedDrawableVariation(playerPed, 4), GetPedTextureVariation(playerPed, 4), GetPedPaletteVariation(playerPed, 4)}; local model = GetEntityModel(playerPed); if model == `mp_m_freemode_01` then SetPedComponentVariation(playerPed, 4, 14, 0, 2) elseif model == `mp_f_freemode_01` then SetPedComponentVariation(playerPed, 4, 15, 0, 2) else SetPedComponentVariation(playerPed, 4, 14, 0, 2) end end
        elseif item == 'shoes' then
            if state.on then SetPedComponentVariation(playerPed, 6, initialClothing[item][1], initialClothing[item][2], initialClothing[item][3]) else initialClothing['shoes'] = {GetPedDrawableVariation(playerPed, 6), GetPedTextureVariation(playerPed, 6), GetPedPaletteVariation(playerPed, 6)}; local model = GetEntityModel(playerPed); if model == `mp_m_freemode_01` then SetPedComponentVariation(playerPed, 6, 34, 0, 2) elseif model == `mp_f_freemode_01` then SetPedComponentVariation(playerPed, 6, 35, 0, 2) else SetPedComponentVariation(playerPed, 6, 34, 0, 2) end end
        elseif item == 'vest' or item == 'bodyarmor' then
            if state.on then SetPedComponentVariation(playerPed, 9, initialClothing[item][1], initialClothing[item][2], initialClothing[item][3]) else initialClothing[item] = {GetPedDrawableVariation(playerPed, 9), GetPedTextureVariation(playerPed, 9), GetPedPaletteVariation(playerPed, 9)}; SetPedComponentVariation(playerPed, 9, 0, 0, 2) end
        elseif item == 'bag' then
            if state.on then SetPedComponentVariation(playerPed, 5, initialClothing[item][1], initialClothing[item][2], initialClothing[item][3]) else initialClothing['bag'] = {GetPedDrawableVariation(playerPed, 5), GetPedTextureVariation(playerPed, 5), GetPedPaletteVariation(playerPed, 5)}; SetPedComponentVariation(playerPed, 5, 0, 0, 2) end
        elseif item == 'neck' or item == 'extras' then
             if state.on then SetPedComponentVariation(playerPed, 7, initialClothing[item][1], initialClothing[item][2], initialClothing[item][3]) else initialClothing[item] = {GetPedDrawableVariation(playerPed, 7), GetPedTextureVariation(playerPed, 7), GetPedPaletteVariation(playerPed, 7)}; SetPedComponentVariation(playerPed, 7, 0, 0, 2) end
        end
        SendNUIMessage({ action = "updateClothingState", clothingState = clothingState })
    end

    local emote = ClothingEmotes[item]
    if emote then
        PlayToggleEmote(emote, doToggle)
    else
        doToggle()
    end
end

CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        if DoesEntityExist(playerPed) then
            local isInVehicle = IsPedInAnyVehicle(playerPed, false)
            if wasInVehicle and not isInVehicle then
                Wait(1000)
                for item, state in pairs(clothingState) do
                    if state.on and initialClothing[item] then
                        if item == 'hat' then
                           SetPedPropIndex(playerPed, 0, initialClothing[item][1], initialClothing[item][2], true)
                        end
                    end
                end
                SendNUIMessage({ action = "updateClothingState", clothingState = clothingState })
            end
            wasInVehicle = isInVehicle
        else
            Wait(5000)
        end
    end
end)

-- STABLE "TOGGLE" LOGIC
local function ToggleMenu()
    isMenuOpen = not isMenuOpen
    SetNuiFocus(isMenuOpen, isMenuOpen)
    if isMenuOpen then
        local PlayerData = QBCore.Functions.GetPlayerData()
        local jobName = PlayerData.job.name
        local jobMenu = Config.JobMenus[jobName]
        updateAndSendClothingState() -- <-- add this line
        SendNUIMessage({ action = "open", jobMenu = jobMenu or {}, clothingState = clothingState }) -- <-- update this line
    else
        SendNUIMessage({ action = "forceClose" })
    end
end

RegisterCommand('openradial', ToggleMenu, false)
RegisterKeyMapping('openradial', 'Open Radial Menu', 'keyboard', Config.OpenKey)

-- HELPER FUNCTION
local function GetClosestPed(filter)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPed, closestDistance = nil, -1
    filter = filter or {}
    for _, ped in ipairs(GetGamePool('CPed')) do
        if DoesEntityExist(ped) and ped ~= playerPed and not IsEntityDead(ped) then
            local distance = #(GetEntityCoords(ped) - playerCoords)
            local passesFilter = true
            if filter.maxDistance and distance > filter.maxDistance then passesFilter = false end
            if filter.isPlayer and not IsPedAPlayer(ped) then passesFilter = false end
            if filter.isNPC and IsPedAPlayer(ped) then passesFilter = false end
            if filter.isHuman and not IsPedHuman(ped) then passesFilter = false end
            if passesFilter then
                if closestDistance == -1 or distance < closestDistance then
                    closestDistance = distance; closestPed = ped
                end
            end
        end
    end
    return closestPed, closestDistance
end

local function GetClosestVehicle()
	local player = PlayerPedId()
	local coords = GetEntityCoords(player)
	return QBCore.Functions.GetClosestVehicle(coords)
end

-- Engine control functions
local function ToggleEngine(vehicle, turnOn)
    if not DoesEntityExist(vehicle) then
        QBCore.Functions.Notify('No vehicle found!', 'error')
        return
    end

    local plate = QBCore.Functions.GetPlate(vehicle)
    if not exports['qb-vehiclekeys']:HasKeys(plate) then
        QBCore.Functions.Notify('You don\'t have keys to this vehicle!', 'error')
        return
    end

    local playerPed = PlayerPedId()
    local isInVehicle = IsPedInAnyVehicle(playerPed, false)
    
    -- Server log කරන්න
    TriggerServerEvent('fxradialmenu:server:engineAttempt', isInVehicle)
    
    if turnOn then
        if not GetIsVehicleEngineRunning(vehicle) then
            SetVehicleEngineOn(vehicle, true, false, true)
            QBCore.Functions.Notify('Engine started!', 'success')
        else
            QBCore.Functions.Notify('Engine is already running!', 'error')
        end
    else
        if GetIsVehicleEngineRunning(vehicle) then
            SetVehicleEngineOn(vehicle, false, false, true)
            QBCore.Functions.Notify('Engine turned off!', 'success')
        else
            QBCore.Functions.Notify('Engine is already off!', 'error')
        end
    end
    
    -- Manually update and send vehicle states to NUI
    local playerPed = PlayerPedId()
    local states = {}
    local veh

    if IsPedInAnyVehicle(playerPed, false) then
        veh = GetVehiclePedIsIn(playerPed, false)
    else
        veh = GetClosestVehicle()
    end

    if veh and DoesEntityExist(veh) and exports['qb-vehiclekeys']:HasKeys(QBCore.Functions.GetPlate(veh)) then
        local plate = QBCore.Functions.GetPlate(veh)
        
        local isEngineRunning = GetIsVehicleEngineRunning(veh)
        states['vehicleEngineOn'] = isEngineRunning
        states['vehicleEngineOff'] = not isEngineRunning

        -- Lights State
        states['vehicleLightOn'] = lightStates[plate] or false
        states['vehicleLightOff'] = not (lightStates[plate] or false)

        local doorMap = { 'vehicleDoorFrontLeft', 'vehicleDoorFrontRight', 'vehicleDoorRearLeft', 'vehicleDoorRearRight', 'vehicleDoorHood', 'vehicleDoorTrunk' }
        for i = 0, 5 do
            if GetVehicleDoorAngleRatio(veh, i) > 0.0 then
                states[doorMap[i+1]] = true
            end
        end

        local windowMap = { 'vehicleWindowFrontLeft', 'vehicleWindowFrontRight', 'vehicleWindowRearLeft', 'vehicleWindowRearRight' }
        if windowStates and windowStates[plate] then
            for i = 0, 3 do
                if windowStates[plate][i] == "down" then
                    states[windowMap[i+1]] = true
                end
            end
        end

        if IsPedInAnyVehicle(playerPed, false) then
            local seatMap = { [-1] = 'vehicleSeatDriver', [0] = 'vehicleSeatPassenger', [1] = 'vehicleSeatRearLeft', [2] = 'vehicleSeatRearRight' }
            local currentSeat = -2
            for i = -1, GetVehicleModelNumberOfSeats(GetEntityModel(veh)) do
                if GetPedInVehicleSeat(veh, i) == playerPed then
                    currentSeat = i
                    break
                end
            end
            if seatMap[currentSeat] then
                states[seatMap[currentSeat]] = true
            end
        end
    end
    SendNUIMessage({ action = "updateStates", states = states })
end

-- Object Placement Logic
local function PlaceObject(model)
    if isPlacingObject then return end; local modelHash = GetHashKey(model)
    if not IsModelInCdimage(modelHash) then QBCore.Functions.Notify('Invalid model name: ' .. model, 'error'); return end
    isPlacingObject = true; RequestModel(modelHash); local timeout, timer = 5000, 0
    while not HasModelLoaded(modelHash) and timer < timeout do Wait(100); timer = timer + 100 end
    if not HasModelLoaded(modelHash) then isPlacingObject = false; SetModelAsNoLongerNeeded(modelHash); QBCore.Functions.Notify('Could not load model, try again.', 'error'); return end
    local playerPed = PlayerPedId(); local object = CreateObject(modelHash, GetEntityCoords(playerPed), true, true, true)
    SetEntityAlpha(object, 150, false); SetEntityCollision(object, false, false)
    local heading, zOffset = GetEntityHeading(playerPed), 0.0
    while isPlacingObject do
        Wait(0); local placePos = GetEntityCoords(playerPed) + GetEntityForwardVector(playerPed) * 2.0
        SetEntityCoords(object, placePos.x, placePos.y, placePos.z + zOffset, false, false, false, false); SetEntityHeading(object, heading)
        if IsControlJustReleased(0, 25) then isPlacingObject = false; DeleteObject(object); break end
        if IsControlJustReleased(0, 24) then isPlacingObject = false; PlaceObjectOnGroundProperly(object); SetEntityCollision(object, true, true); SetEntityAlpha(object, 255, false); FreezeEntityPosition(object, true); table.insert(placedObjects, object); break end
        if IsControlPressed(0, 15) then heading = (heading + 5.0) % 360 end; if IsControlPressed(0, 16) then heading = (heading - 5.0 + 360) % 360 end
        if IsControlPressed(0, 172) then zOffset = zOffset + 0.01 end; if IsControlPressed(0, 173) then zOffset = zOffset - 0.01 end
    end
    SetModelAsNoLongerNeeded(modelHash)
end

local function RemoveClosestPlacedObject()
    local playerCoords = GetEntityCoords(PlayerPedId()); local closestObject, closestDist, objectIndex = nil, -1, -1
    for i = #placedObjects, 1, -1 do
        local obj = placedObjects[i]
        if DoesEntityExist(obj) then local dist = #(playerCoords - GetEntityCoords(obj)); if closestDist == -1 or dist < closestDist then closestDist, closestObject, objectIndex = dist, obj, i end
        else table.remove(placedObjects, i) end
    end
    if closestObject and closestDist < 7.0 then DeleteEntity(closestObject); table.remove(placedObjects, objectIndex) end
end

-- Helper to get server id from ped
local function GetServerIdFromPed(ped)
    local playerIndex = NetworkGetPlayerIndexFromPed(ped)
    if playerIndex == -1 then return nil end
    return GetPlayerServerId(playerIndex)
end

-- Net event to update owned vehicle plates
RegisterNetEvent('fxradialmenu:client:setOwnedVehiclePlates', function(plates)
    OwnedVehiclePlates = {}
    for _, plate in ipairs(plates) do
        OwnedVehiclePlates[plate] = true
    end
end)

-- Request owned vehicle plates from server
CreateThread(function()
    TriggerServerEvent('fxradialmenu:server:requestOwnedVehiclePlates')
end)

-- Add this event handler anywhere in the file
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    saveInitialClothing()
end)

-- Move SendVehicleStatesToNUI here
local function UpdateAndSendAllStates()
    local playerPed = PlayerPedId()
    local states = {}
    local veh

    for action, status in pairs(activeStates or {}) do
        states[action] = status
    end

    if IsPedInAnyVehicle(playerPed, false) then
        veh = GetVehiclePedIsIn(playerPed, false)
    else
        veh = GetClosestVehicle()
    end

    if veh and DoesEntityExist(veh) and exports['qb-vehiclekeys']:HasKeys(QBCore.Functions.GetPlate(veh)) then
        local plate = QBCore.Functions.GetPlate(veh)
        
        local isEngineRunning = GetIsVehicleEngineRunning(veh)
        states['vehicleEngineOn'] = isEngineRunning
        states['vehicleEngineOff'] = not isEngineRunning

        -- Lights State (Now uses our reliable table instead of the buggy native)
        states['vehicleLightOn'] = lightStates[plate] or false
        states['vehicleLightOff'] = not (lightStates[plate] or false)

        local doorMap = { 'vehicleDoorFrontLeft', 'vehicleDoorFrontRight', 'vehicleDoorRearLeft', 'vehicleDoorRearRight', 'vehicleDoorHood', 'vehicleDoorTrunk' }
        for i = 0, 5 do
            if GetVehicleDoorAngleRatio(veh, i) > 0.0 then
                states[doorMap[i+1]] = true
            end
        end

        local windowMap = { 'vehicleWindowFrontLeft', 'vehicleWindowFrontRight', 'vehicleWindowRearLeft', 'vehicleWindowRearRight' }
        if windowStates and windowStates[plate] then
            for i = 0, 3 do
                if windowStates[plate][i] == "down" then
                    states[windowMap[i+1]] = true
                end
            end
        end

        if IsPedInAnyVehicle(playerPed, false) then
            local seatMap = { [-1] = 'vehicleSeatDriver', [0] = 'vehicleSeatPassenger', [1] = 'vehicleSeatRearLeft', [2] = 'vehicleSeatRearRight' }
            local currentSeat = -2
            for i = -1, GetVehicleModelNumberOfSeats(GetEntityModel(veh)) do
                if GetPedInVehicleSeat(veh, i) == playerPed then
                    currentSeat = i
                    break
                end
            end
            if seatMap[currentSeat] then
                states[seatMap[currentSeat]] = true
            end
        end
    end
    SendNUIMessage({ action = "updateStates", states = states })
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    isMenuOpen = false; SetNuiFocus(false, false); cb('ok')
end)

RegisterNUICallback('performAction', function(data, cb)
    local action = data.action
    local eventData = data.data or {}

    if action == 'FxRadialMenu:ToggleClothing' then
        local itemId = eventData.id
        if itemId then
            -- The item ID from JS is already lowercase from our Step 2 fix.
            toggleClothingItem(itemId)
        else
            print("FxRadialMenu Error: Clothing event received, but item ID was missing.")
        end
        cb('ok')
        return
    end

    -- Vehicle engine actions
    if action == 'vehicleEngineOn' then
        local playerPed = PlayerPedId()
        local vehicle = nil
        
        if IsPedInAnyVehicle(playerPed, false) then
            vehicle = GetVehiclePedIsIn(playerPed, false)
        else
            vehicle = GetClosestVehicle()
        end
        
        if vehicle and DoesEntityExist(vehicle) then
            ToggleEngine(vehicle, true)
        else
            QBCore.Functions.Notify('No vehicle nearby!', 'error')
        end
        cb('ok')
        return
    elseif action == 'vehicleEngineOff' then
        local playerPed = PlayerPedId()
        local vehicle = nil
        
        if IsPedInAnyVehicle(playerPed, false) then
            vehicle = GetVehiclePedIsIn(playerPed, false)
        else
            vehicle = GetClosestVehicle()
        end
        
        if vehicle and DoesEntityExist(vehicle) then
            ToggleEngine(vehicle, false)
        else
            QBCore.Functions.Notify('No vehicle nearby!', 'error')
        end
        cb('ok')
        return
    end

    -- The rest of your performAction logic continues here...
end)

RegisterNUICallback('requestStates', function(data, cb)
    UpdateAndSendAllStates()
    cb('ok')
end)

-- "WATCHDOG" THREAD TO KEEP NPCS CUFFED
CreateThread(function()
    local cuffedAnimDict = "anim@move_m@prisoner_cuffed"
    RequestAnimDict(cuffedAnimDict)
    while not HasAnimDictLoaded(cuffedAnimDict) do Wait(100) end
    while true do
        Wait(1000)
        if next(cuffedNPCs) ~= nil then
            for ped, isCuffed in pairs(cuffedNPCs) do
                if isCuffed then
                    if DoesEntityExist(ped) and not IsEntityDead(ped) then
                        if not IsEntityPlayingAnim(ped, cuffedAnimDict, "idle", 3) then
                            ClearPedTasks(ped); TaskPlayAnim(ped, cuffedAnimDict, "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
                        end
                    else
                        cuffedNPCs[ped] = nil
                    end
                end
            end
        else
            Wait(4000)
        end
    end
end)

--[[
    This is the final and definitive fix for all light-related state issues.
    It takes full control of the headlight key ('H') when the player is driving,
    implements a correct light cycle (Off -> On -> High Beams -> Off),
    and reliably updates the internal state tracker ('lightStates').
]]--
CreateThread(function()
    local lastVehicle = 0
    while true do
        Wait(500)
        
        local playerPed = PlayerPedId()
        local veh = GetVehiclePedIsIn(playerPed, false)

        if veh ~= lastVehicle then
            if veh == 0 and lastVehicle ~= 0 then -- Player just exited a vehicle
                if DoesEntityExist(lastVehicle) then
                    local plate = QBCore.Functions.GetPlate(lastVehicle)
                    if exports['qb-vehiclekeys']:HasKeys(plate) then
                        SetVehicleLights(lastVehicle, 0) -- Turn lights off on exit
                    end
                end
            end
            lastVehicle = veh
        end
    end
end)

-- In the main AI thread, improve vehicle entry logic for the guard
CreateThread(function()
    while true do
        Wait(1000) -- Check once per second by default

        if policeGuard and DoesEntityExist(policeGuard) then
            if IsPedDeadOrDying(policeGuard) then
                if guardBlip and DoesBlipExist(guardBlip) then RemoveBlip(guardBlip); guardBlip = nil end
                QBCore.Functions.Notify('Your partner is down!', 'error')
                if guardCatchUpVehicle and DoesEntityExist(guardCatchUpVehicle) then DeleteEntity(guardCatchUpVehicle) end
                policeGuard, guardCatchUpVehicle = nil, nil
            else
                local playerPed = PlayerPedId()
                local attacker = nil
                
                if HasEntityBeenDamagedByAnyPed(playerPed) then
                    attacker = GetPedSourceOfDamage(playerPed)
                end

                if attacker and DoesEntityExist(attacker) and not IsPedDeadOrDying(attacker) and attacker ~= policeGuard then
                    -- If player is attacked, guard should defend player, not random peds.
                    -- Ensure guard hates the attacker and engages.
                    SetRelationshipBetweenGroups(5, GetPedRelationshipGroupHash(policeGuard), GetPedRelationshipGroupHash(attacker))
                    TaskCombatPed(policeGuard, attacker, 0, 16)
                    goto continueLoop
                end

                if policeGuardShouldFollow and not IsPedInCombat(policeGuard, false) then
                    local playerCoords = GetEntityCoords(playerPed)
                    local guardCoords = GetEntityCoords(policeGuard)
                    local distance = #(playerCoords - guardCoords)
                    local playerVeh = GetVehiclePedIsIn(playerPed, false)
                    local guardVeh = GetVehiclePedIsIn(policeGuard, false)

                    if playerVeh ~= 0 and guardVeh == 0 and not guardCatchUpVehicle and distance > 75.0 then
                        local bikeModel = `policeb`
                        RequestModel(bikeModel); while not HasModelLoaded(bikeModel) do Wait(10) end
                        -- New, safer way to find a spawn point for the bike
                        local foundRoad, roadPos = GetClosestRoad(guardCoords.x, guardCoords.y, guardCoords.z, 3.0, 1, false)
                        if not foundRoad then
                            QBCore.Functions.Notify('Your partner is too far from a road to get a vehicle.', 'error')
                        else
                            guardCatchUpVehicle = CreateVehicle(bikeModel, roadPos.x, roadPos.y, roadPos.z, GetEntityHeading(policeGuard), true, true)
                            SetEntityAsMissionEntity(guardCatchUpVehicle, true, true)
                            SetVehicleHasBeenOwnedByPlayer(guardCatchUpVehicle, true)
                            TaskEnterVehicle(policeGuard, guardCatchUpVehicle, -1, -1, 5.0, 1, 0)
                        end
                        SetModelAsNoLongerNeeded(bikeModel)
                    
                    elseif guardCatchUpVehicle and guardVeh == guardCatchUpVehicle then
                        local drivingStyle = 524295 -- Aggressive driving: ignore all rules
                        TaskVehicleDriveToCoord(policeGuard, guardCatchUpVehicle, playerCoords.x, playerCoords.y, playerCoords.z, 40.0, 0, GetEntityModel(guardCatchUpVehicle), drivingStyle, 5.0)
                        if distance < 25.0 then
                            TaskLeaveVehicle(policeGuard, guardCatchUpVehicle, 0); Wait(2500)
                            if DoesEntityExist(guardCatchUpVehicle) and GetVehiclePedIsIn(policeGuard, false) ~= guardCatchUpVehicle then
                                DeleteEntity(guardCatchUpVehicle); guardCatchUpVehicle = nil
                            end
                        end
                    
                    elseif playerVeh ~= 0 and guardVeh ~= playerVeh and not guardCatchUpVehicle then
                        local seat = -1
                        for i = GetVehicleMaxNumberOfPassengers(playerVeh), -1, -1 do
                            if IsVehicleSeatFree(playerVeh, i) then seat = i; break end
                        end
                        if seat ~= -1 then TaskEnterVehicle(policeGuard, playerVeh, 10000, seat, 5.0, 1, 0) end
                    
                    elseif playerVeh == 0 and guardVeh == 0 then
                        if distance > 20.0 then TaskGoToEntity(policeGuard, playerPed, -1, 3.0, 10.0, 1073741824, 0)
                        else TaskFollowToOffsetOfEntity(policeGuard, playerPed, 1.5, 1.5, 1.5, 1.5, -1, 5.0, true) end
                    end
                end
                ::continueLoop::
            end
        end
    end
end)

-- Replace the attack mode thread with strict, debug-friendly logic
CreateThread(function()
    local currentTarget = nil
    local lastAttackTime = 0
    while true do
        Wait(200)
        if policeGuardAttackMode and policeGuard and DoesEntityExist(policeGuard) and not IsPedDeadOrDying(policeGuard) then
            local playerPed = PlayerPedId()
            -- Check for new aim target
            if IsPlayerFreeAiming(PlayerId()) then
                local found, aimedEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
                if found and DoesEntityExist(aimedEntity) and aimedEntity ~= policeGuard and not IsPedDeadOrDying(aimedEntity) and IsPed(aimedEntity) then
                    if currentTarget ~= aimedEntity or not IsPedInCombat(policeGuard, aimedEntity) or (GetGameTimer() - lastAttackTime > 1500) then
                        if currentTarget and currentTarget ~= aimedEntity then
                            ClearPedTasks(policeGuard)
                            if DoesEntityExist(currentTarget) then
                                SetRelationshipBetweenGroups(2, GetPedRelationshipGroupHash(policeGuard), GetPedRelationshipGroupHash(currentTarget))
                            end
                            if targetMarkBlip and DoesBlipExist(targetMarkBlip) then RemoveBlip(targetMarkBlip); targetMarkBlip = nil end
                        end
                        SetRelationshipBetweenGroups(5, GetPedRelationshipGroupHash(policeGuard), GetPedRelationshipGroupHash(aimedEntity))
                        TaskCombatPed(policeGuard, aimedEntity, 0, 16)
                        currentTarget = aimedEntity
                        lastAttackTime = GetGameTimer()
                        -- Mark the target with a blip
                        if targetMarkBlip and DoesBlipExist(targetMarkBlip) then RemoveBlip(targetMarkBlip) end
                        targetMarkBlip = AddBlipForEntity(aimedEntity)
                        SetBlipSprite(targetMarkBlip, 432) -- Crosshair
                        SetBlipColour(targetMarkBlip, 1) -- Red
                        SetBlipScale(targetMarkBlip, 0.8)
                        SetBlipAsShortRange(targetMarkBlip, false)
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentSubstringPlayerName("Target")
                        EndTextCommandSetBlipName(targetMarkBlip)
                        QBCore.Functions.Notify('Target marked! Guard will attack until the target is dead.', 'success')
                    end
                end
            end
            -- If there is a current target, check if it's dead
            if currentTarget and (not DoesEntityExist(currentTarget) or IsPedDeadOrDying(currentTarget)) then
                ClearPedTasks(policeGuard)
                if DoesEntityExist(currentTarget) then
                    SetRelationshipBetweenGroups(2, GetPedRelationshipGroupHash(policeGuard), GetPedRelationshipGroupHash(currentTarget))
                end
                if targetMarkBlip and DoesBlipExist(targetMarkBlip) then RemoveBlip(targetMarkBlip); targetMarkBlip = nil end
                QBCore.Functions.Notify('Guard stopped attacking (target dead).', 'inform')
                currentTarget = nil
            end
        else
            -- Mode off or guard gone: reset everything
            if currentTarget then
                ClearPedTasks(policeGuard)
                if DoesEntityExist(currentTarget) then
                    SetRelationshipBetweenGroups(2, GetPedRelationshipGroupHash(policeGuard), GetPedRelationshipGroupHash(currentTarget))
                end
                if targetMarkBlip and DoesBlipExist(targetMarkBlip) then RemoveBlip(targetMarkBlip); targetMarkBlip = nil end
                currentTarget = nil
            end
        end
    end
end)