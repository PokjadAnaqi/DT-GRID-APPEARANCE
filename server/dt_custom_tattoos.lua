local purchases = {}
local lastPurchase = {}
local tableReady = false

local function settings()
    return Config.CustomTattoo or {}
end

local function playerId(src)
    local id = Framework.GetPlayerID(src)
    return id and tostring(id) or nil
end

local function fail(reason)
    return { ok = false, reason = reason }
end

local function clamp(number, minimum, maximum, fallback)
    if type(number) ~= 'number' or number ~= number then return fallback end
    return math.max(minimum, math.min(maximum, number))
end

local validZone = {
    ZONE_HEAD = true, ZONE_TORSO = true,
    ZONE_LEFT_ARM = true, ZONE_RIGHT_ARM = true,
    ZONE_LEFT_LEG = true, ZONE_RIGHT_LEG = true
}

local validFont = {
    ['Space Grotesk'] = true, ['Impact'] = true,
    ['Georgia'] = true, ['Courier New'] = true, ['Arial'] = true
}

local function normalizeTransform(data)
    if type(data) ~= 'table' or not validZone[data.zone] then return nil end
    local text = type(data.text) == 'string' and data.text:sub(1, 80) or ''
    local font = validFont[data.font] and data.font or 'Space Grotesk'
    local color = type(data.color) == 'string' and data.color or '#121212'
    if not color:match('^#%x%x%x%x%x%x$') then color = '#121212' end

    return {
        zone = data.zone,
        x = clamp(data.x, 0, 1, 0.5),
        y = clamp(data.y, 0, 1, 0.5),
        scale = clamp(data.scale, 0.06, 0.85, 0.25),
        rotation = clamp(data.rotation, 0, 360, 0),
        opacity = clamp(data.opacity, 0.1, 1, 1),
        font = font,
        fontSize = clamp(data.fontSize, 16, 128, 48),
        color = color,
        text = text
    }
end

-- Decode only the PNG signature and IHDR. We never write untrusted bytes to a resource.
local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function decodedHeader(encoded)
    local value = 0
    local bits = 0
    local output = {}

    for index = 1, math.min(#encoded, 48) do
        local character = encoded:sub(index, index)
        local position = alphabet:find(character, 1, true)
        if not position then break end
        value = (value * 64 + position - 1) % 16777216
        bits = bits + 6
        if bits >= 8 then
            bits = bits - 8
            output[#output + 1] = string.char(math.floor(value / (2 ^ bits)) % 256)
            value = value % (2 ^ bits)
        end
    end
    return table.concat(output)
end

local function validPng(encoded, limit)
    if type(encoded) ~= 'string' or #encoded < 44 or #encoded > limit then return false end
    if not encoded:match('^[A-Za-z0-9+/]+=?=?$') then return false end
    local head = decodedHeader(encoded)
    if head:sub(1, 8) ~= '\137PNG\r\n\26\n' or head:sub(13, 16) ~= 'IHDR' then return false end
    if #head < 24 then return false end
    local bytes = { head:byte(17, 24) }
    local width = bytes[1] * 16777216 + bytes[2] * 65536 + bytes[3] * 256 + bytes[4]
    local height = bytes[5] * 16777216 + bytes[6] * 65536 + bytes[7] * 256 + bytes[8]
    return width >= 1 and height >= 1
        and width <= settings().MaxDimension and height <= settings().MaxDimension
end

local function nearShop(src)
    if not settings().RequireTattooShop then return true end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local position = GetEntityCoords(ped)
    for _, store in pairs(Config.Stores or {}) do
        if store.type == 'tattoo' and store.coords then
            local point = vector3(store.coords.x, store.coords.y, store.coords.z)
            if #(position - point) <= (settings().ShopDistance or 12.0) then return true end
        end
    end
    return false
end

local function refund(src, amount)
    -- Best-effort compensating transaction. Failure is printed for manual reconciliation.
    if GetResourceState('qbx_core') == 'started' then
        local ok, result = pcall(function()
            return exports.qbx_core:AddMoney(src, 'cash', amount, 'dtgrid-tattoo-refund')
        end)
        if ok and result ~= false then return true end
    end
    if GetResourceState('qb-core') == 'started' then
        local ok, result = pcall(function()
            local player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
            return player and player.Functions.AddMoney('cash', amount, 'dtgrid-tattoo-refund')
        end)
        if ok and result then return true end
    end
    if GetResourceState('es_extended') == 'started' then
        local ok, result = pcall(function()
            local player = exports.es_extended:getSharedObject().GetPlayerFromId(src)
            if not player then return false end
            player.addAccountMoney('money', amount)
            return true
        end)
        if ok and result then return true end
    end
    if GetResourceState('ox_inventory') == 'started' then
        local ok, result = pcall(function() return exports.ox_inventory:AddItem(src, 'cash', amount) end)
        if ok and result then return true end
    end
    return false
end

local function asPublicRow(row)
    local transform = json.decode(row.transform_json or '{}') or {}
    return {
        id = row.id,
        kind = row.kind,
        label = row.label,
        thumbnail = 'data:image/png;base64,' .. (row.thumbnail_png or ''),
        zone = transform.zone or 'ZONE_TORSO',
        transform = transform,
        renderStatus = row.render_status,
        createdAt = row.created_at,
        paid = row.paid == 1 or row.paid == true,
    }
end

CreateThread(function()
    local success, errorMessage = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `dtgrid_custom_tattoos` (
                `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                `citizenid` VARCHAR(80) NOT NULL,
                `kind` VARCHAR(8) NOT NULL,
                `label` VARCHAR(64) NOT NULL,
                `image_png` MEDIUMTEXT NOT NULL,
                `thumbnail_png` TEXT NOT NULL,
                `transform_json` JSON NOT NULL,
                `collection` VARCHAR(64) DEFAULT NULL,
                `hash_male` VARCHAR(96) DEFAULT NULL,
                `hash_female` VARCHAR(96) DEFAULT NULL,
                `render_status` ENUM('pending', 'ready') NOT NULL DEFAULT 'pending',
                `paid` TINYINT(1) NOT NULL DEFAULT 0,
                `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                INDEX `idx_dtgrid_custom_tattoos_owner` (`citizenid`, `paid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]])
    end)
    tableReady = success
    if not success then print(('[DT GRID APPEARANCE] Custom tattoo schema failed: %s'):format(errorMessage)) end
end)

lib.callback.register('dtgrid:tattoos:list', function(source)
    local owner = playerId(source)
    local config = settings()
    if not owner or not tableReady then return fail('Library is not ready') end
    local rows = MySQL.query.await([[
        SELECT id, kind, label, thumbnail_png, transform_json, render_status, created_at, paid
        FROM dtgrid_custom_tattoos
        WHERE citizenid = ?
        ORDER BY id DESC LIMIT 100
    ]], { owner }) or {}
    local library = {}
    for i = 1, #rows do library[i] = asPublicRow(rows[i]) end
    return {
        ok = true,
        library = library,
        price = config.Price,
        purchaseEnabled = config.PurchaseEnabled == true,
        maxDesigns = config.MaxDesigns
    }
end)

lib.callback.register('dtgrid:tattoos:purchase', function(src, request)
    local config = settings()
    if not config.Enabled then return fail('Tattoo editor is disabled') end
    if not tableReady then return fail('Tattoo storage unavailable') end
    if not nearShop(src) then return fail('Visit a Tattoo Studio to save your design') end

    local owner = playerId(src)
    if not owner then return fail('Character session is not ready') end
    if purchases[owner] then return fail('Previous purchase is still being processed') end
    local now = os.time()
    if now - (lastPurchase[owner] or 0) < (config.SaveCooldownSeconds or 10) then
        return fail('Please wait before saving another design')
    end
    if type(request) ~= 'table' then return fail('Invalid request') end
    if request.kind ~= 'image' and request.kind ~= 'text' then return fail('Invalid tattoo type') end
    if type(request.label) ~= 'string' then return fail('Invalid tattoo label') end
    local label = request.label:sub(1, 64):match('^%s*(.-)%s*$')
    if not label or #label < 2 then return fail('Tattoo name is too short') end
    local transform = normalizeTransform(request.transform)
    if not transform then return fail('Invalid tattoo placement') end
    if request.kind == 'text' and #transform.text < 1 then return fail('Text cannot be empty') end
    if not validPng(request.image, config.MaxEncodedBytes or 360000)
        or not validPng(request.thumbnail, config.MaxThumbnailBytes or 40000) then
        return fail('Invalid or oversized PNG')
    end

    purchases[owner] = true
    local debited = false
    local refunded = false
    local ok, response = pcall(function()
        local count = MySQL.scalar.await(
            'SELECT COUNT(*) FROM dtgrid_custom_tattoos WHERE citizenid = ?',
            { owner }
        ) or 0
        if count >= (config.MaxDesigns or 20) then return fail('Personal library is full') end
        local price = config.Price or 300
        if config.PurchaseEnabled and not Framework.HasMoney(src, config.MoneyType or 'cash', price) then
            return fail(('Insufficient balance: %d %s required'):format(price, config.Currency or 'DTC'))
        end

        local id = MySQL.insert.await([[
            INSERT INTO dtgrid_custom_tattoos
                (citizenid, kind, label, image_png, thumbnail_png, transform_json, paid)
            VALUES (?, ?, ?, ?, ?, ?, 0)
        ]], { owner, request.kind, label, request.image, request.thumbnail, json.encode(transform) })
        if not id then return fail('Could not reserve library storage') end
        if not config.PurchaseEnabled then
            -- Free beta-testing draft. It cannot be worn or published as a paid tattoo.
            return { ok = true, id = id, price = 0, renderStatus = 'draft' }
        end
        if playerId(src) ~= owner then
            MySQL.update.await('DELETE FROM dtgrid_custom_tattoos WHERE id = ? AND paid = 0', { id })
            return fail('Character changed during the transaction')
        end
        if not Framework.RemoveMoney(src, config.MoneyType or 'cash', price) then
            MySQL.update.await('DELETE FROM dtgrid_custom_tattoos WHERE id = ? AND paid = 0', { id })
            return fail('Payment rejected: balance unchanged')
        end
        debited = true
        local updateOk, changed = pcall(MySQL.update.await,
            'UPDATE dtgrid_custom_tattoos SET paid = 1 WHERE id = ? AND citizenid = ? AND paid = 0',
            { id, owner }
        )
        if not updateOk or not changed or changed < 1 then
            refunded = refund(src, price)
            if not refunded then
                print(('[DT GRID APPEARANCE] REFUND REQUIRED: char=%s tattoo=%s amount=%d')
                    :format(owner, id, price))
            end
            return fail('Could not finish purchase; check transaction log')
        end
        return { ok = true, id = id, price = price, renderStatus = 'pending' }
    end)
    purchases[owner] = nil
    if not ok then
        if debited and not refunded and not refund(src, config.Price or 300) then
            print(('[DT GRID APPEARANCE] REFUND REQUIRED after exception: char=%s amount=%s')
                :format(owner, config.Price or 300))
        end
        print(('[DT GRID APPEARANCE] Tattoo purchase failed: %s'):format(response))
        return fail('Tattoo purchase failed; ask staff to check transaction status')
    end
    if response.ok then lastPurchase[owner] = now end
    return response
end)

-- The tattoo can only be applied after its custom .ytd/.xml overlay is registered,
-- tested and linked in the database by the server owner.
lib.callback.register('dtgrid:tattoos:getReady', function(src, tattooId)
    local owner = playerId(src)
    local id = tonumber(tattooId)
    if not owner or not id then return fail('Invalid tattoo') end
    local tattoo = MySQL.single.await([[
        SELECT id, label, transform_json, collection, hash_male, hash_female
        FROM dtgrid_custom_tattoos
        WHERE id = ? AND citizenid = ? AND paid = 1 AND render_status = 'ready'
    ]], { id, owner })
    if not tattoo or not tattoo.collection or not tattoo.hash_male or not tattoo.hash_female then
        return fail('This tattoo is awaiting its streamed overlay')
    end
    local transform = json.decode(tattoo.transform_json or '{}') or {}
    return {
        ok = true,
        tattoo = {
            name = 'DTGRID_TATTOO_' .. tostring(tattoo.id),
            label = tattoo.label,
            zone = transform.zone or 'ZONE_TORSO',
            collection = tattoo.collection,
            hashMale = tattoo.hash_male,
            hashFemale = tattoo.hash_female,
            opacity = transform.opacity or 1
        }
    }
end)

AddEventHandler('playerDropped', function()
    local owner = playerId(source)
    if owner then purchases[owner] = nil end
end)
