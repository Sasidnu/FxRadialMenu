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
local lightStates = {} -- Track light status reliably

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

-- Clothing system variables
local clothingState = {}
local wasInVehicle = false
local initialClothing = {}

-- Vehicle enumeration helpers
local entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end
    end
}

function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
        local iter, id = initFunc()
        if not id or id == 0 then
            disposeFunc(iter)
            return
        end
        
        local enum = {handle = iter, destructor = disposeFunc}
        setmetatable(enum, entityEnumerator)
        
        local next = true
        repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
        until not next
        
        enum.destructor, enum.handle = nil, nil
        disposeFunc(iter)
    end)
end

function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

-- Clothing system functions
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

    SendNUIMessage({ action = "updateClothingState", clothingState = clothingState })
end

-- Clothing emote table
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
    local playerPed = PlayerPedId()
    if not clothingState[item] or not initialClothing[item] then return end

    local state = clothingState[item]

    -- Check to prevent animation on empty items
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
        -- IMMEDIATE UPDATE: Send clothing state update right after the change
        updateAndSendClothingState()
        -- ALSO send immediate update message
        SendNUIMessage({ 
            action = "immediateUpdate", 
            clothingState = clothingState 
        })
    end

    local emote = ClothingEmotes[item]
    if emote then
        PlayToggleEmote(emote, doToggle)
    else
        doToggle()
    end
end

-- Vehicle Control Functions
local function GetControlVehicle()
    local playerPed = PlayerPedId()
    local vehicle = nil
    
    -- First check if player is in a vehicle
    if IsPedInAnyVehicle(playerPed, false) then
        vehicle = GetVehiclePedIsIn(playerPed, false)
    else
        -- Look for closest vehicle within reasonable distance
        local playerCoords = GetEntityCoords(playerPed)
        local closestDistance = 15.0 -- Max distance for remote control
        
        -- Check all vehicles in area
        for vehicle_handle in EnumerateVehicles() do
            if DoesEntityExist(vehicle_handle) then
                local vehCoords = GetEntityCoords(vehicle_handle)
                local distance = #(playerCoords - vehCoords)
                
                if distance < closestDistance then
                    -- Check if player has line of sight to vehicle
                    local hit, _, _, _, entityHit = GetShapeTestResult(StartShapeTestRay(playerCoords.x, playerCoords.y, playerCoords.z, vehCoords.x, vehCoords.y, vehCoords.z, 10, playerPed, 0))
                    
                    if hit == 0 or entityHit == vehicle_handle then
                        vehicle = vehicle_handle
                        closestDistance = distance
                    end
                end
            end
        end
    end
    
    return vehicle
end

local function GetClosestVehicle()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    return QBCore.Functions.GetClosestVehicle(coords)
end

-- Enhanced Engine Control Function
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
    
    -- Server log
    TriggerServerEvent('fxradialmenu:server:engineAttempt', isInVehicle)
    
    if turnOn then
        if not GetIsVehicleEngineRunning(vehicle) then
            -- Multiple attempts to ensure engine starts
            SetVehicleEngineOn(vehicle, true, false, true)
            SetVehicleUndriveable(vehicle, false)
            
            -- For remote start, try additional methods
            if not isInVehicle then
                -- Method 1: Direct engine start
                SetVehicleEngineOn(vehicle, true, false, true)
                Wait(50)
                
                -- Method 2: Try again with different parameters
                SetVehicleEngineOn(vehicle, true, true, false)
                Wait(50)
                
                -- Method 3: Ensure it's not broken
                SetVehicleFixed(vehicle)
                SetVehicleDeformationFixed(vehicle)
                SetVehicleEngineHealth(vehicle, 1000.0)
                Wait(50)
                
                -- Final attempt
                SetVehicleEngineOn(vehicle, true, false, true)
            end
            
            -- Verify if engine actually started
            Wait(200)
            if GetIsVehicleEngineRunning(vehicle) then
                QBCore.Functions.Notify('Engine started!', 'success')
            else
                QBCore.Functions.Notify('Failed to start engine remotely. Try getting closer.', 'error')
            end
        else
            QBCore.Functions.Notify('Engine is already running!', 'error')
        end
    else
        -- Engine off logic
        if GetIsVehicleEngineRunning(vehicle) then
            SetVehicleEngineOn(vehicle, false, false, true)
            Wait(100)
            -- Double check to ensure it turned off
            if not GetIsVehicleEngineRunning(vehicle) then
                QBCore.Functions.Notify('Engine turned off!', 'success')
            else
                SetVehicleEngineOn(vehicle, false, true, true)
                QBCore.Functions.Notify('Engine turned off!', 'success')
            end
        else
            QBCore.Functions.Notify('Engine is already off!', 'error')
        end
    end
    
    -- Update vehicle states after engine change
    Wait(200)
    UpdateAndSendAllStates()
    -- IMMEDIATE UPDATE: Send vehicle states after engine change
    Wait(100)
    UpdateAndSendAllStates()
end

-- Vehicle State Update Function
local function UpdateAndSendAllStates()
    local playerPed = PlayerPedId()
    local states = {}
    local veh

    -- Get current vehicle (in or closest)
    if IsPedInAnyVehicle(playerPed, false) then
        veh = GetVehiclePedIsIn(playerPed, false)
    else
        veh = GetClosestVehicle()
    end

    if veh and DoesEntityExist(veh) then
        local plate = QBCore.Functions.GetPlate(veh)
        
        -- Check if player has keys
        if exports['qb-vehiclekeys']:HasKeys(plate) then
            
            -- Engine States
            local isEngineRunning = GetIsVehicleEngineRunning(veh)
            states['vehicleEngineOn'] = isEngineRunning
            states['vehicleEngineOff'] = not isEngineRunning

            -- Light States - Better detection
            local actualLightState = GetVehicleLightsState(veh)
            local lightsOn = (actualLightState == 1) -- 1 means lights are on
            
            -- Update our tracking table
            lightStates[plate] = lightsOn
            
            -- Set UI states
            states['vehicleLightOn'] = lightsOn
            states['vehicleLightOff'] = not lightsOn

            -- Door States
            local doorMap = { 
                'vehicleDoorFrontLeft', 'vehicleDoorFrontRight', 
                'vehicleDoorRearLeft', 'vehicleDoorRearRight', 
                'vehicleDoorHood', 'vehicleDoorTrunk' 
            }
            for i = 0, 5 do
                if GetVehicleDoorAngleRatio(veh, i) > 0.0 then
                    states[doorMap[i+1]] = true
                end
            end

            -- Window States
            local windowMap = { 
                'vehicleWindowFrontLeft', 'vehicleWindowFrontRight', 
                'vehicleWindowRearLeft', 'vehicleWindowRearRight' 
            }
            if windowStates and windowStates[plate] then
                for i = 0, 3 do
                    if windowStates[plate][i] == "down" then
                        states[windowMap[i+1]] = true
                    end
                end
            end

            -- Seat States (only if player is in vehicle)
            if IsPedInAnyVehicle(playerPed, false) then
                local seatMap = { 
                    [-1] = 'vehicleSeatDriver', 
                    [0] = 'vehicleSeatPassenger', 
                    [1] = 'vehicleSeatRearLeft', 
                    [2] = 'vehicleSeatRearRight' 
                }
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
    end
    
    -- Send states to NUI (both regular and immediate)
    SendNUIMessage({ action = "updateStates", states = states })
    SendNUIMessage({ action = "immediateUpdate", vehicleStates = states })
    print("Sending states to NUI:", json.encode(states))
end

-- Menu Toggle Function
local function ToggleMenu()
    isMenuOpen = not isMenuOpen
    SetNuiFocus(isMenuOpen, isMenuOpen)
    if isMenuOpen then
        local PlayerData = QBCore.Functions.GetPlayerData()
        local jobName = PlayerData.job.name
        local jobMenu = Config.JobMenus[jobName]
        -- FORCE immediate state updates when opening menu
        updateAndSendClothingState()
        UpdateAndSendAllStates()
        SendNUIMessage({ action = "open", jobMenu = jobMenu or {}, clothingState = clothingState })
        -- Send additional updates after a short delay
        CreateThread(function()
            Wait(300)
            updateAndSendClothingState()
            UpdateAndSendAllStates()
        end)
    else
        SendNUIMessage({ action = "forceClose" })
    end
end

RegisterCommand('openradial', ToggleMenu, false)
RegisterKeyMapping('openradial', 'Open Radial Menu', 'keyboard', Config.OpenKey)

-- Helper Functions
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
            toggleClothingItem(itemId)
        else
            print("FxRadialMenu Error: Clothing event received, but item ID was missing.")
        end
        cb('ok')
        return
    end

    -- Vehicle engine actions
    if action == 'vehicleEngineOn' then
        local vehicle = GetControlVehicle()
        
        if vehicle and DoesEntityExist(vehicle) then
            local plate = QBCore.Functions.GetPlate(vehicle)
            if exports['qb-vehiclekeys']:HasKeys(plate) then
                ToggleEngine(vehicle, true)
            else
                QBCore.Functions.Notify('You don\'t have keys to this vehicle!', 'error')
            end
        else
            QBCore.Functions.Notify('No vehicle nearby or vehicle too far!', 'error')
        end
        cb('ok')
        return
        
    elseif action == 'vehicleEngineOff' then
        local vehicle = GetControlVehicle()
        
        if vehicle and DoesEntityExist(vehicle) then
            local plate = QBCore.Functions.GetPlate(vehicle)
            if exports['qb-vehiclekeys']:HasKeys(plate) then
                ToggleEngine(vehicle, false)
            else
                QBCore.Functions.Notify('You don\'t have keys to this vehicle!', 'error')
            end
        else
            QBCore.Functions.Notify('No vehicle nearby or vehicle too far!', 'error')
        end
        cb('ok')
        return
    end

    -- Vehicle light actions
    if action == 'vehicleLightOn' then
        local vehicle = GetControlVehicle()
        if vehicle and DoesEntityExist(vehicle) then
            local plate = QBCore.Functions.GetPlate(vehicle)
            if exports['qb-vehiclekeys']:HasKeys(plate) then
                SetVehicleLights(vehicle, 2) -- Force lights on
                lightStates[plate] = true
                QBCore.Functions.Notify('Lights turned on!', 'success')
                -- IMMEDIATE UPDATE
                Wait(50)
                UpdateAndSendAllStates()
            else
                QBCore.Functions.Notify('You don\'t have keys to this vehicle!', 'error')
            end
        else
            QBCore.Functions.Notify('No vehicle nearby!', 'error')
        end
        cb('ok')
        return
        
    elseif action == 'vehicleLightOff' then
        local vehicle = GetControlVehicle()
        if vehicle and DoesEntityExist(vehicle) then
            local plate = QBCore.Functions.GetPlate(vehicle)
            if exports['qb-vehiclekeys']:HasKeys(plate) then
                SetVehicleLights(vehicle, 1) -- This allows normal H key function
                SetVehicleLights(vehicle, 0) -- Then turn completely off
                lightStates[plate] = false
                QBCore.Functions.Notify('Lights turned off!', 'success')
                -- IMMEDIATE UPDATE
                Wait(50)
                UpdateAndSendAllStates()
            else
                QBCore.Functions.Notify('You don\'t have keys to this vehicle!', 'error')
            end
        else
            QBCore.Functions.Notify('No vehicle nearby!', 'error')
        end
        cb('ok')
        return
    end

    -- Vehicle door actions
    local doorActions = {
        vehicleDoorFrontLeft = 0,
        vehicleDoorFrontRight = 1,
        vehicleDoorRearLeft = 2,
        vehicleDoorRearRight = 3,
        vehicleDoorHood = 4,
        vehicleDoorTrunk = 5
    }
    
    if doorActions[action] then
        local vehicle = GetControlVehicle()
        if vehicle and DoesEntityExist(vehicle) then
            local plate = QBCore.Functions.GetPlate(vehicle)
            if exports['qb-vehiclekeys']:HasKeys(plate) then
                local doorIndex = doorActions[action]
                local isOpen = GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0.0
                
                if isOpen then
                    SetVehicleDoorShut(vehicle, doorIndex, false)
                    QBCore.Functions.Notify('Door closed!', 'success')
                else
                    SetVehicleDoorOpen(vehicle, doorIndex, false, false)
                    QBCore.Functions.Notify('Door opened!', 'success')
                end
                -- IMMEDIATE UPDATE
                Wait(50)
                UpdateAndSendAllStates()
            else
                QBCore.Functions.Notify('You don\'t have keys to this vehicle!', 'error')
            end
        else
            QBCore.Functions.Notify('No vehicle nearby!', 'error')
        end
        cb('ok')
        return
    end

    -- Vehicle window actions
    local windowActions = {
        vehicleWindowFrontLeft = 0,
        vehicleWindowFrontRight = 1,
        vehicleWindowRearLeft = 2,
        vehicleWindowRearRight = 3
    }
    
    if windowActions[action] then
        local vehicle = GetControlVehicle()
        if vehicle and DoesEntityExist(vehicle) then
            local plate = QBCore.Functions.GetPlate(vehicle)
            if exports['qb-vehiclekeys']:HasKeys(plate) then
                local windowIndex = windowActions[action]
                
                -- Initialize window states for this vehicle if not exists
                if not windowStates[plate] then
                    windowStates[plate] = {}
                end
                
                local currentState = windowStates[plate][windowIndex] or "up"
                
                if currentState == "up" then
                    RollDownWindow(vehicle, windowIndex)
                    windowStates[plate][windowIndex] = "down"
                    QBCore.Functions.Notify('Window rolled down!', 'success')
                else
                    RollUpWindow(vehicle, windowIndex)
                    windowStates[plate][windowIndex] = "up"
                    QBCore.Functions.Notify('Window rolled up!', 'success')
                end
                -- IMMEDIATE UPDATE
                Wait(50)
                UpdateAndSendAllStates()
            else
                QBCore.Functions.Notify('You don\'t have keys to this vehicle!', 'error')
            end
        else
            QBCore.Functions.Notify('No vehicle nearby!', 'error')
        end
        cb('ok')
        return
    end

    -- Vehicle lock actions
    if action == 'vehicleLock' then
        local vehicle = GetControlVehicle()
        if vehicle and DoesEntityExist(vehicle) then
            local plate = QBCore.Functions.GetPlate(vehicle)
            if exports['qb-vehiclekeys']:HasKeys(plate) then
                SetVehicleDoorsLocked(vehicle, 2) -- Locked
                QBCore.Functions.Notify('Vehicle locked!', 'success')
            else
                QBCore.Functions.Notify('You don\'t have keys to this vehicle!', 'error')
            end
        else
            QBCore.Functions.Notify('No vehicle nearby!', 'error')
        end
        cb('ok')
        return
        
    elseif action == 'vehicleUnlock' then
        local vehicle = GetControlVehicle()
        if vehicle and DoesEntityExist(vehicle) then
            local plate = QBCore.Functions.GetPlate(vehicle)
            if exports['qb-vehiclekeys']:HasKeys(plate) then
                SetVehicleDoorsLocked(vehicle, 1) -- Unlocked
                QBCore.Functions.Notify('Vehicle unlocked!', 'success')
            else
                QBCore.Functions.Notify('You don\'t have keys to this vehicle!', 'error')
            end
        else
            QBCore.Functions.Notify('No vehicle nearby!', 'error')
        end
        cb('ok')
        return
    end

    -- Vehicle seat actions (only work when inside vehicle)
    local seatActions = {
        vehicleSeatDriver = -1,
        vehicleSeatPassenger = 0,
        vehicleSeatRearLeft = 1,
        vehicleSeatRearRight = 2
    }
    
    if seatActions[action] then
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local targetSeat = seatActions[action]
            
            if IsVehicleSeatFree(vehicle, targetSeat) then
                SetPedIntoVehicle(playerPed, vehicle, targetSeat)
                QBCore.Functions.Notify('Moved to seat!', 'success')
                -- IMMEDIATE UPDATE
                Wait(50)
                UpdateAndSendAllStates()
            else
                QBCore.Functions.Notify('Seat is occupied!', 'error')
            end
        else
            QBCore.Functions.Notify('You must be inside a vehicle to change seats!', 'error')
        end
        cb('ok')
        return
    end

    -- Player interaction actions
    if action == 'putInVehicle' then
        local closestPed, distance = GetClosestPed({maxDistance = 3.0, isPlayer = true})
        if closestPed then
            local closestVehicle = GetClosestVehicle()
            if closestVehicle and DoesEntityExist(closestVehicle) then
                local serverId = GetServerIdFromPed(closestPed)
                if serverId then
                    TriggerServerEvent('fxradialmenu:server:putInVehicle', serverId, VehToNet(closestVehicle))
                end
            end
        else
            QBCore.Functions.Notify('No player nearby!', 'error')
        end
        cb('ok')
        return
    end

    if action == 'takeOutOfVehicle' then
        local closestPed, distance = GetClosestPed({maxDistance = 3.0, isPlayer = true})
        if closestPed then
            local serverId = GetServerIdFromPed(closestPed)
            if serverId then
                TriggerServerEvent('fxradialmenu:server:takeOutOfVehicle', serverId)
            end
        else
            QBCore.Functions.Notify('No player nearby!', 'error')
        end
        cb('ok')
        return
    end

    if action == 'giveContactDetails' then
        local closestPed, distance = GetClosestPed({maxDistance = 3.0, isPlayer = true})
        if closestPed then
            local serverId = GetServerIdFromPed(closestPed)
            if serverId then
                TriggerServerEvent('fxradialmenu:server:giveContactDetails', serverId)
            end
        else
            QBCore.Functions.Notify('No player nearby!', 'error')
        end
        cb('ok')
        return
    end

    -- Object spawning actions
    if action == 'spawnObject' then
        local model = data.model
        if model then
            PlaceObject(model)
        end
        cb('ok')
        return
    end

    if action == 'removeClosestObject' then
        RemoveClosestPlacedObject()
        cb('ok')
        return
    end

    -- Police Guard Actions
    if action == 'policeSpawnGuard' then
        if policeGuard and DoesEntityExist(policeGuard) then
            QBCore.Functions.Notify('You already have a partner!', 'error')
        else
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            
            RequestModel(`s_m_y_cop_01`)
            while not HasModelLoaded(`s_m_y_cop_01`) do Wait(10) end
            
            policeGuard = CreatePed(4, `s_m_y_cop_01`, coords.x + 2, coords.y, coords.z, heading, true, false)
            SetEntityAsMissionEntity(policeGuard, true, true)
            SetPedRelationshipGroupHash(policeGuard, GetHashKey("COP"))
            SetPedArmour(policeGuard, 100)
            GiveWeaponToPed(policeGuard, GetHashKey("WEAPON_PISTOL"), 200, false, true)
            SetPedCombatAttributes(policeGuard, 46, true)
            SetPedCombatRange(policeGuard, 2)
            
            guardBlip = AddBlipForEntity(policeGuard)
            SetBlipSprite(guardBlip, 1)
            SetBlipColour(guardBlip, 3)
            SetBlipScale(guardBlip, 0.8)
            SetBlipAsShortRange(guardBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName("Police Partner")
            EndTextCommandSetBlipName(guardBlip)
            
            QBCore.Functions.Notify('Partner called for backup!', 'success')
        end
        cb('ok')
        return
    end

    if action == 'policeDismissGuard' then
        if policeGuard and DoesEntityExist(policeGuard) then
            if guardBlip and DoesBlipExist(guardBlip) then RemoveBlip(guardBlip); guardBlip = nil end
            if guardCatchUpVehicle and DoesEntityExist(guardCatchUpVehicle) then DeleteEntity(guardCatchUpVehicle) end
            DeleteEntity(policeGuard)
            policeGuard, guardCatchUpVehicle = nil, nil
            policeGuardAttackMode = false
            QBCore.Functions.Notify('Partner dismissed!', 'success')
        else
            QBCore.Functions.Notify('No partner to dismiss!', 'error')
        end
        cb('ok')
        return
    end

    if action == 'policeToggleGuardFollow' then
        if policeGuard and DoesEntityExist(policeGuard) then
            policeGuardShouldFollow = not policeGuardShouldFollow
            if policeGuardShouldFollow then
                QBCore.Functions.Notify('Partner will follow you!', 'success')
            else
                QBCore.Functions.Notify('Partner will stay in position!', 'inform')
                ClearPedTasks(policeGuard)
            end
        else
            QBCore.Functions.Notify('No partner available!', 'error')
        end
        cb('ok')
        return
    end

    if action == 'policeGuardAttackTarget' then
        if policeGuard and DoesEntityExist(policeGuard) then
            policeGuardAttackMode = not policeGuardAttackMode
            if policeGuardAttackMode then
                QBCore.Functions.Notify('Attack mode ON! Aim at a target to command your partner.', 'success')
            else
                QBCore.Functions.Notify('Attack mode OFF!', 'inform')
                ClearPedTasks(policeGuard)
                if targetMarkBlip and DoesBlipExist(targetMarkBlip) then RemoveBlip(targetMarkBlip); targetMarkBlip = nil end
            end
        else
            QBCore.Functions.Notify('No partner available!', 'error')
        end
        cb('ok')
        return
    end

    if action == 'policeGuardStop' then
        if policeGuard and DoesEntityExist(policeGuard) then
            ClearPedTasks(policeGuard)
            policeGuardAttackMode = false
            if targetMarkBlip and DoesBlipExist(targetMarkBlip) then RemoveBlip(targetMarkBlip); targetMarkBlip = nil end
            QBCore.Functions.Notify('Partner stopped all actions!', 'success')
        else
            QBCore.Functions.Notify('No partner available!', 'error')
        end
        cb('ok')
        return
    end

    -- Add other job-specific actions here
    if action == 'jailPlayer' then
        QBCore.Functions.Notify('Jail system not implemented yet!', 'error')
        cb('ok')
        return
    end

    if action == 'checkPlayerStatus' then
        local closestPed, distance = GetClosestPed({maxDistance = 3.0, isPlayer = true})
        if closestPed then
            QBCore.Functions.Notify('Player status check - implement your logic here!', 'inform')
        else
            QBCore.Functions.Notify('No player nearby!', 'error')
        end
        cb('ok')
        return
    end

    if action == 'escortPlayer' then
        local closestPed, distance = GetClosestPed({maxDistance = 3.0, isPlayer = true})
        if closestPed then
            QBCore.Functions.Notify('Escort player - implement your logic here!', 'inform')
        else
            QBCore.Functions.Notify('No player nearby!', 'error')
        end
        cb('ok')
        return
    end

    if action == 'searchPlayer' then
        local closestPed, distance = GetClosestPed({maxDistance = 3.0, isPlayer = true})
        if closestPed then
            QBCore.Functions.Notify('Search player - implement your logic here!', 'inform')
        else
            QBCore.Functions.Notify('No player nearby!', 'error')
        end
        cb('ok')
        return
    end

    -- EMS Actions
    if action == 'revivePlayer' then
        local closestPed, distance = GetClosestPed({maxDistance = 3.0, isPlayer = true})
        if closestPed then
            QBCore.Functions.Notify('Revive player - implement your logic here!', 'inform')
        else
            QBCore.Functions.Notify('No player nearby!', 'error')
        end
        cb('ok')
        return
    end

    if action == 'healPlayer' then
        local closestPed, distance = GetClosestPed({maxDistance = 3.0, isPlayer = true})
        if closestPed then
            QBCore.Functions.Notify('Heal player - implement your logic here!', 'inform')
        else
            QBCore.Functions.Notify('No player nearby!', 'error')
        end
        cb('ok')
        return
    end

    if action == 'getStretcher' then
        TriggerEvent('qb-radialmenu:client:TakeStretcher')
        cb('ok')
        return
    end

    -- Mechanic Actions
    if action == 'mechanic:repair' then
        local vehicle = GetControlVehicle()
        if vehicle and DoesEntityExist(vehicle) then
            SetVehicleFixed(vehicle)
            SetVehicleDeformationFixed(vehicle)
            SetVehicleEngineHealth(vehicle, 1000.0)
            QBCore.Functions.Notify('Vehicle repaired!', 'success')
        else
            QBCore.Functions.Notify('No vehicle nearby!', 'error')
        end
        cb('ok')
        return
    end

    if action == 'mechanic:clean' then
        local vehicle = GetControlVehicle()
        if vehicle and DoesEntityExist(vehicle) then
            SetVehicleDirtLevel(vehicle, 0.0)
            QBCore.Functions.Notify('Vehicle cleaned!', 'success')
        else
            QBCore.Functions.Notify('No vehicle nearby!', 'error')
        end
        cb('ok')
        return
    end

    if action == 'mechanic:tow' then
        QBCore.Functions.Notify('Tow system not implemented yet!', 'error')
        cb('ok')
        return
    end

    -- House Actions
    if action == 'setHouseLocation' then
        local locationType = data.locationType
        if locationType then
            QBCore.Functions.Notify('Set house ' .. locationType .. ' - implement your logic here!', 'inform')
        end
        cb('ok')
        return
    end

    if action == 'giveHouseKey' then
        QBCore.Functions.Notify('Give house key - implement your logic here!', 'inform')
        cb('ok')
        return
    end

    if action == 'removeHouseKey' then
        QBCore.Functions.Notify('Remove house key - implement your logic here!', 'inform')
        cb('ok')
        return
    end

    if action == 'decorateHouse' then
        QBCore.Functions.Notify('Decorate house - implement your logic here!', 'inform')
        cb('ok')
        return
    end

    if action == 'toggleDoorLock' then
        QBCore.Functions.Notify('Toggle door lock - implement your logic here!', 'inform')
        cb('ok')
        return
    end

    -- Other citizen actions
    if action == 'robPlayer' then
        QBCore.Functions.Notify('Rob player - implement your logic here!', 'inform')
        cb('ok')
        return
    end

    if action == 'toggleCuff' then
        QBCore.Functions.Notify('Toggle cuff - implement your logic here!', 'inform')
        cb('ok')
        return
    end

    if action == 'takeHostage' then
        QBCore.Functions.Notify('Take hostage - implement your logic here!', 'inform')
        cb('ok')
        return
    end

    if action == 'kidnapPlayer' then
        QBCore.Functions.Notify('Kidnap player - implement your logic here!', 'inform')
        cb('ok')
        return
    end

    if action == 'sellHotdog' then
        QBCore.Functions.Notify('Sell hotdog - implement your logic here!', 'inform')
        cb('ok')
        return
    end

    if action == 'getInTrunk' then
        TriggerEvent('qb-trunk:client:GetIn')
        cb('ok')
        return
    end

    if action == 'sellCannabis' then
        QBCore.Functions.Notify('Sell cannabis - implement your logic here!', 'inform')
        cb('ok')
        return
    end
    
    cb('ok')
end)

RegisterNUICallback('requestStates', function(data, cb)
    UpdateAndSendAllStates()
    cb('ok')
end)

-- Event Handlers
RegisterNetEvent('fxradialmenu:client:setOwnedVehiclePlates', function(plates)
    OwnedVehiclePlates = {}
    for _, plate in ipairs(plates) do
        OwnedVehiclePlates[plate] = true
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    saveInitialClothing()
    TriggerServerEvent('fxradialmenu:server:requestOwnedVehiclePlates')
end)

-- Threads
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

-- Improved Light Control Thread
CreateThread(function()
    local lastVehicle = 0
    local lastLightState = 0
    
    while true do
        Wait(100) -- Check more frequently for better responsiveness
        
        local playerPed = PlayerPedId()
        local veh = GetVehiclePedIsIn(playerPed, false)

        if veh ~= 0 and DoesEntityExist(veh) then
            local plate = QBCore.Functions.GetPlate(veh)
            
            if exports['qb-vehiclekeys']:HasKeys(plate) then
                -- Check current light state
                local currentLightState = GetVehicleLightsState(veh)
                
                -- If light state changed, update our tracking
                if currentLightState ~= lastLightState then
                    if currentLightState == 1 then
                        -- Lights are on
                        lightStates[plate] = true
                    else
                        -- Lights are off
                        lightStates[plate] = false
                    end
                    lastLightState = currentLightState
                    
                    -- Update UI if menu is open
                    if isMenuOpen then
                        UpdateAndSendAllStates()
                    end
                end
            end
        end
        
        -- Handle vehicle change
        if veh ~= lastVehicle then
            lastVehicle = veh
            lastLightState = 0 -- Reset light state tracking
        end
    end
end)

-- Cuffed NPCs Thread
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

-- Police Guard AI Thread
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
                        local drivingStyle = 524295
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

-- Police Guard Attack Mode Thread
CreateThread(function()
    local currentTarget = nil
    local lastAttackTime = 0
    while true do
        Wait(200)
        if policeGuardAttackMode and policeGuard and DoesEntityExist(policeGuard) and not IsPedDeadOrDying(policeGuard) then
            local playerPed = PlayerPedId()
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
                        if targetMarkBlip and DoesBlipExist(targetMarkBlip) then RemoveBlip(targetMarkBlip) end
                        targetMarkBlip = AddBlipForEntity(aimedEntity)
                        SetBlipSprite(targetMarkBlip, 432)
                        SetBlipColour(targetMarkBlip, 1)
                        SetBlipScale(targetMarkBlip, 0.8)
                        SetBlipAsShortRange(targetMarkBlip, false)
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentSubstringPlayerName("Target")
                        EndTextCommandSetBlipName(targetMarkBlip)
                        QBCore.Functions.Notify('Target marked! Guard will attack until the target is dead.', 'success')
                    end
                end
            end
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

-- Request owned vehicle plates on resource start
CreateThread(function()
    TriggerServerEvent('fxradialmenu:server:requestOwnedVehiclePlates')
end)

-- 7. CREATE a continuous update thread for real-time syncing
CreateThread(function()
    while true do
        Wait(1000) -- Check every second
        if isMenuOpen then
            -- Continuously update states while menu is open
            updateAndSendClothingState()
            UpdateAndSendAllStates()
        else
            Wait(4000) -- Sleep longer when menu is closed
        end
    end
end)
