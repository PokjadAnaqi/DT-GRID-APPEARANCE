-- DT GRID APPEARANCE | Custom tattoo streamed-overlay bridge
-- External tattoo builders (GTAX, Atelier) generate the YTD and overlay files.
-- This resource never attempts to hot-load a YTD or replace GTA textures.

local function allowed(source)
    return source == 0 or IsPlayerAceAllowed(source, 'dtgrid.tattoos.admin')
end

local function report(source, message)
    local text = ('[DT GRID APPEARANCE] %s'):format(message)
    if source == 0 then
        print(text)
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'Tattoo Studio', message }
        })
    end
end

local function validName(value, maxLength)
    return type(value) == 'string'
        and #value >= 3
        and #value <= maxLength
        and value:match('^[%w_]+$') ~= nil
end

local function streamResource(collection)
    local config = Config.CustomTattoo or {}
    return type(config.StreamedCollections) == 'table'
        and config.StreamedCollections[collection] or nil
end

local function streamReady(collection)
    local resource = streamResource(collection)
    return type(resource) == 'string' and resource ~= ''
        and GetResourceState(resource) == 'started'
end

exports('IsCustomTattooCollectionReady', streamReady)

RegisterCommand('dtgridtattoo:export', function(source, arguments)
    if not allowed(source) then return end

    local id = tonumber(arguments[1])
    if not id or id < 1 or id % 1 ~= 0 then
        return report(source, 'Usage: dtgridtattoo:export <tattooId>')
    end

    local tattoo = MySQL.single.await([[
        SELECT id, kind, label, image_png, transform_json
        FROM dtgrid_custom_tattoos WHERE id = ? LIMIT 1
    ]], { id })

    if not tattoo then return report(source, 'Tattoo ID not found') end

    local fileName = ('tattoo_exports/tattoo_%d.json'):format(id)
    local contents = json.encode({
        version = 1,
        id = id,
        kind = tattoo.kind,
        label = tattoo.label,
        pngBase64 = tattoo.image_png,
        placementGuide = json.decode(tattoo.transform_json or '{}') or {}
    })

    if not SaveResourceFile(GetCurrentResourceName(), fileName, contents, -1) then
        return report(source, 'Export failed. Check resource write permissions and tattoo_exports directory.')
    end

    report(source, ('Exported %s. Use a 3D tattoo builder to position it before making a FiveM pack.'):format(fileName))
end, false)

RegisterCommand('dtgridtattoo:register', function(source, arguments)
    if not allowed(source) then return end

    local id = tonumber(arguments[1])
    local collection = arguments[2]
    local hashMale = arguments[3]
    local hashFemale = arguments[4]

    if not id or id < 1 or id % 1 ~= 0
        or not validName(collection, 64)
        or not validName(hashMale, 96)
        or not validName(hashFemale, 96) then
        return report(source, 'Usage: dtgridtattoo:register <tattooId> <collection> <hashMale> <hashFemale>')
    end

    if not streamResource(collection) then
        return report(source, 'Collection is not allowlisted in Config.CustomTattoo.StreamedCollections')
    end

    if not streamReady(collection) then
        return report(source, 'Streamed resource is not running. Start the tattoo pack first.')
    end

    -- Manual registration follows a GTA asset build and server restart.
    -- It cannot confirm that already-connected players have downloaded the texture.
    local count = MySQL.update.await([[
        UPDATE dtgrid_custom_tattoos
        SET collection = ?, hash_male = ?, hash_female = ?, render_status = 'ready'
        WHERE id = ? AND render_status = 'pending'
    ]], { collection, hashMale, hashFemale, id })

    if not count or count < 1 then
        return report(source, 'No pending design updated. Check tattoo ID/status.')
    end

    report(source, ('Tattoo #%d registered in %s. Ask players to reconnect before testing.'):format(id, collection))
end, false)

-- ACE example: add_ace group.admin dtgrid.tattoos.admin allow
