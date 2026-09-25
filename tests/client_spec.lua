local function harness(overrides)
    local h = {
        events = {}, sent = {}, threads = {}, keyMappings = 0,
        attached = false, vehicle = 0, seat = nil,
        carrierExists = true, dead = false, seatFree = true,
    }
    local env = setmetatable({}, { __index = _G })
    h.env = env

    env.RegisterNetEvent = function(name, callback) h.events[name] = callback end
    env.AddEventHandler = function(name, callback) h.events[name] = callback end
    env.RegisterCommand = function() end
    env.RegisterKeyMapping = function() h.keyMappings = h.keyMappings + 1 end
    env.CreateThread = function(callback) h.threads[#h.threads + 1] = callback end
    env.TriggerServerEvent = function(name, ...)
        h.sent[#h.sent + 1] = { name = name, args = { ... } }
    end
    env.GetGameTimer = function() return 10000 end
    env.Wait = function() end
    env.PlayerPedId = function() return 2 end
    env.PlayerId = function() return 2 end
    env.GetPlayerFromServerId = function() return h.carrierExists and 1 or -1 end
    env.GetPlayerPed = function(id) return id end
    env.DoesEntityExist = function(id) return id == 1 or id == 2 or id == 100 end
    env.HasAnimDictLoaded = function() return true end
    env.TaskPlayAnim = function() end
    env.AttachEntityToEntity = function() h.attached = true end
    env.DetachEntity = function() h.attached = false end
    env.StopAnimTask = function() end
    env.ClearPedSecondaryTask = function() end
    env.ClearPedTasks = function() end
    env.ClearPedTasksImmediately = function() end
    env.BeginTextCommandThefeedPost = function() end
    env.AddTextComponentSubstringPlayerName = function() end
    env.EndTextCommandThefeedPostTicker = function() end
    env.NetToVeh = function(id) return id == 100 and 100 or 0 end
    env.GetVehicleMaxNumberOfPassengers = function() return 2 end
    env.IsVehicleSeatFree = function() return h.seatFree end
    env.GetVehiclePedIsIn = function() return h.vehicle end
    env.SetPedIntoVehicle = function(_, vehicle, seat)
        h.vehicle = vehicle
        h.seat = seat
    end
    env.GetPedInVehicleSeat = function(_, seat) return h.seat == seat and 2 or 0 end
    env.IsEntityDead = function() return h.dead end
    env.IsPedDeadOrDying = function() return h.dead end
    env.IsPedFatallyInjured = function() return h.dead end
    env.GetEntityHealth = function() return h.dead and 0 or 100 end
    env.GetPlayerServerId = function() return 2 end
    env.Player = function() return { state = {} } end
    env.GetOffsetFromEntityInWorldCoords = function() return { x = 1, y = 2, z = 3 } end
    env.GetGroundZFor_3dCoord = function() return true, 3 end
    env.vector3 = function(x, y, z) return { x = x, y = y, z = z } end
    env.SetEntityCoordsNoOffset = function() h.moved = true; h.vehicle = 0 end
    env.SetEntityHeading = function() end
    env.GetEntityHeading = function() return 0 end
    env.SetPedCanRagdoll = function() end
    env.SetPedToRagdoll = function() end

    assert(loadfile('config.lua', 't', env))()
    for key, value in pairs(overrides or {}) do env.Config[key] = value end
    assert(loadfile('client.lua', 't', env))()

    function h:call(name, ...)
        assert(self.events[name], name)(...)
    end

    function h:find(name)
        for index = #self.sent, 1, -1 do
            if self.sent[index].name == name then return self.sent[index] end
        end
    end

    return h
end

do
    local h = harness()
    h.carrierExists = false
    h:call('carry_people:client:startCarried', 1, 10)
    assert(h:find('carry_people:server:startFailed'), 'missing carrier did not abort start')
    h.carrierExists = true
    h.sent = {}
    h:call('carry_people:client:startCarried', 1, 10)
    assert(not h.attached and not h:find('carry_people:server:startReady'), 'stale start was accepted')
end

do
    local h = harness()
    h:call('carry_people:client:startCarried', 1, 10)
    assert(h.attached and h:find('carry_people:server:startReady'), 'carry did not start')
    h.sent = {}
    h.seatFree = false
    h:call('carry_people:client:putInVehicle', 10, 100)
    local result = assert(h:find('carry_people:server:putInVehicleResult'))
    assert(result.args[2] == false and h.attached, 'full vehicle changed carry state')
end

do
    local h = harness()
    h:call('carry_people:client:startCarried', 1, 10)
    h.sent = {}
    h:call('carry_people:client:putInVehicle', 10, 100)
    local result = assert(h:find('carry_people:server:putInVehicleResult'))
    assert(result.args[2] == true and h.vehicle == 100 and not h.attached, 'valid placement failed')
    h:call('carry_people:client:putInVehicleSuccess', 10)
    h:call('carry_people:client:stop', 10, false)
    assert(h.vehicle == 100, 'stale stop disturbed completed placement')
end

do
    local h = harness()
    h.dead = true
    h:call('carry_people:client:removeFromVehicle', 100, 5)
    local result = assert(h:find('carry_people:server:removeFromVehicleResult'))
    assert(result.args[2] == false and not h.moved, 'target outside vehicle was moved')
    h.sent = {}
    h.vehicle = 100
    h:call('carry_people:client:removeFromVehicle', 100, 6)
    result = assert(h:find('carry_people:server:removeFromVehicleResult'))
    assert(result.args[2] == true and h.moved, 'valid removal failed')
end

do
    local disabled = harness({ EnableStopKey = false, StopControl = 73 })
    assert(disabled.keyMappings == 0 and #disabled.threads == 2, 'disabled stop key still registered control')
    local enabled = harness({ EnableStopKey = true, StopControl = 73 })
    assert(enabled.keyMappings == 1 and #enabled.threads == 3, 'explicit raw control was not registered')
end

print('client_spec: 5 scenarios passed')
