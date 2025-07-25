local QBCore = exports['qb-core']:GetCoreObject()

-- Vehicle Events
RegisterNetEvent('fxradialmenu:server:putInVehicle', function(targetId, vehicleNetId)
    local sourcePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(targetId)
    local vehicle = NetToVeh(vehicleNetId)

    if vehicle and DoesEntityExist(vehicle) then
        local seatFound = false
        for i = 0, GetVehicleMaxNumberOfPassengers(vehicle) do
            if IsVehicleSeatFree(vehicle, i) then
                TriggerClientEvent('fxradialmenu:client:forceEnterVehicle', targetId, vehicle, i)
                seatFound = true
                break
            end
        end
        if not seatFound then
            TriggerClientEvent('QBCore:Notify', source, "Vehicle is full.", "error")
        end
    end
end)

RegisterNetEvent('fxradialmenu:server:takeOutOfVehicle', function(targetId)
    local targetPed = GetPlayerPed(targetId)
    if targetPed and DoesEntityExist(targetPed) then
        local vehicle = GetVehiclePedIsIn(targetPed, false)
        if vehicle ~= 0 then
            TriggerClientEvent('fxradialmenu:client:forceExitVehicle', targetId)
        end
    end
end)

-- Give Contact Details Event
RegisterNetEvent('fxradialmenu:server:giveContactDetails', function(targetId)
    local sourcePlayer = QBCore.Functions.GetPlayer(source)
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if sourcePlayer and targetPlayer then
        local myNumber = sourcePlayer.PlayerData.charinfo.phone
        local myName = sourcePlayer.PlayerData.charinfo.firstname .. " " .. sourcePlayer.PlayerData.charinfo.lastname
        TriggerClientEvent('chat:addMessage', targetId, {
            template = '<div class="chat-message advert"><b>Contact Details</b><br>{0}: {1}</div>',
            args = { myName, myNumber }
        })
        TriggerClientEvent('QBCore:Notify', source, "You gave your contact details to " .. targetPlayer.PlayerData.charinfo.firstname, "success")
    end
end)

-- Send owned vehicle plates to client
RegisterNetEvent('fxradialmenu:server:requestOwnedVehiclePlates', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plates = {}
    if Player and Player.PlayerData.vehicles then
        for _, v in pairs(Player.PlayerData.vehicles) do
            table.insert(plates, v.plate)
        end
    end
    TriggerClientEvent('fxradialmenu:client:setOwnedVehiclePlates', src, plates)
end)

-- These client events are triggered from the server to force the ped into/out of the vehicle
RegisterNetEvent('fxradialmenu:client:forceEnterVehicle', function(vehicle, seat)
    local ped = PlayerPedId()
    SetPedIntoVehicle(ped, vehicle, seat)
end)

RegisterNetEvent('fxradialmenu:client:forceExitVehicle', function()
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
end)

RegisterNetEvent('fxradialmenu:server:engineAttempt', function(isInside)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local name = Player and Player.PlayerData and Player.PlayerData.charinfo and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname) or ('ID:' .. tostring(src))
    if isInside then
        print(('[FxRadialMenu] %s attempted engine toggle: INSIDE vehicle'):format(name))
    else
        print(('[FxRadialMenu] %s attempted engine toggle: OUTSIDE vehicle'):format(name))
    end
end)