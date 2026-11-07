-- Separate from illenium's existing GTA tattoo callbacks; no event names are replaced.
RegisterNUICallback('dtgrid_tattoos_get_library', function(_, callback)
    local result = lib.callback.await('dtgrid:tattoos:list', false)
    callback(result or { ok = false, reason = 'Library unavailable' })
end)

RegisterNUICallback('dtgrid_tattoos_purchase', function(data, callback)
    if type(data) ~= 'table' then
        callback({ ok = false, reason = 'Invalid tattoo' })
        return
    end
    local result = lib.callback.await('dtgrid:tattoos:purchase', false, data)
    callback(result or { ok = false, reason = 'Request timed out' })
end)

RegisterNUICallback('dtgrid_tattoos_ready', function(data, callback)
    local id = type(data) == 'table' and data.id or nil
    local result = lib.callback.await('dtgrid:tattoos:getReady', false, id)
    callback(result or { ok = false, reason = 'Tattoo unavailable' })
end)
