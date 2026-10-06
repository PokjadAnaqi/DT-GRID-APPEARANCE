if Config.UseTarget then return end

local currentZone = nil

local Zones = {
    Store = {},
    ClothingRoom = {},
    PlayerOutfitRoom = {}
}

local function RemoveZones()
    for i = 1, #Zones.Store do
        if Zones.Store[i]["remove"] then
            Zones.Store[i]:remove()
        end
    end
    for i = 1, #Zones.ClothingRoom do
        Zones.ClothingRoom[i]:remove()
    end
    for i = 1, #Zones.PlayerOutfitRoom do
        Zones.PlayerOutfitRoom[i]:remove()
    end
end

local function lookupZoneIndexFromID(zones, id)
    for i = 1, #zones do
        if zones[i].id == id then
            return i
        end
    end
end

local function onStoreEnter(data)
    local index = lookupZoneIndexFromID(Zones.Store, data.id)
    local store = Config.Stores[index]

    local jobName = (store.job and client.job.name) or (store.gang and client.gang.name)
    if jobName == (store.job or store.gang) then
        currentZone = {
            name = store.type,
            index = index,
            shopType = store.shopType
        }
        if store.type == "clothing" then
            _currentClothingShopType = store.shopType or "binco"
        end
        if currentZone.name == "clothing" then
            AppearanceUI.ShowInteraction("clothing", string.format(_L("textUI.clothing"), Config.ClothingCost))
        elseif currentZone.name == "barber" then
            AppearanceUI.ShowInteraction("barber", string.format(_L("textUI.barber"), Config.BarberCost))
        elseif currentZone.name == "tattoo" then
            AppearanceUI.ShowInteraction("tattoo", string.format(_L("textUI.tattoo"), Config.TattooCost))
        elseif currentZone.name == "surgeon" then
            AppearanceUI.ShowInteraction("surgeon", string.format(_L("textUI.surgeon"), Config.SurgeonCost))
        end
        Radial.AddOption(currentZone)
    end
end

local function onClothingRoomEnter(data)
    local index = lookupZoneIndexFromID(Zones.ClothingRoom, data.id)
    local clothingRoom = Config.ClothingRooms[index]

    local jobName = clothingRoom.job and client.job.name or client.gang.name
    if jobName == (clothingRoom.job or clothingRoom.gang) then
        if CheckDuty() or clothingRoom.gang then
            currentZone = {
                name = "clothingRoom",
                index = index
            }
            AppearanceUI.ShowInteraction("clothingRoom", _L("textUI.clothingRoom"))
            Radial.AddOption(currentZone)
        end
    end
end

local function onPlayerOutfitRoomEnter(data)
    local index = lookupZoneIndexFromID(Zones.PlayerOutfitRoom, data.id)
    local playerOutfitRoom = Config.PlayerOutfitRooms[index]

    local isAllowed = IsPlayerAllowedForOutfitRoom(playerOutfitRoom)
    if isAllowed then
        currentZone = {
            name = "playerOutfitRoom",
            index = index
        }
        AppearanceUI.ShowInteraction("playerOutfitRoom", _L("textUI.playerOutfitRoom"))
        Radial.AddOption(currentZone)
    end
end

local function onZoneExit()
    currentZone = nil
    Radial.RemoveOption()
    AppearanceUI.HideText()
end

local function SetupZone(store, onEnter, onExit)
    if Config.RCoreTattoosCompatibility and store.type == "tattoo" then
        return {}
    end

    if Config.UseRadialMenu or store.usePoly then
        return lib.zones.poly({
            points = store.points,
            debug = Config.Debug,
            onEnter = onEnter,
            onExit = onExit
        })
    end

    return lib.zones.box({
        coords = store.coords,
        size = store.size,
        rotation = store.rotation,
        debug = Config.Debug,
        onEnter = onEnter,
        onExit = onExit
    })
end

local function SetupStoreZones()
    -- Numeric order must match Config.Stores because enter callbacks resolve the
    -- store again by the zone array index. ipairs avoids pairs reordering.
    for i = 1, #Config.Stores do
        local store = Config.Stores[i]
        Zones.Store[#Zones.Store + 1] = SetupZone(store, onStoreEnter, onZoneExit)
    end
end

local function SetupClothingRoomZones()
    for i = 1, #Config.ClothingRooms do
        Zones.ClothingRoom[#Zones.ClothingRoom + 1] = SetupZone(Config.ClothingRooms[i], onClothingRoomEnter, onZoneExit)
    end
end

local function SetupPlayerOutfitRoomZones()
    for i = 1, #Config.PlayerOutfitRooms do
        Zones.PlayerOutfitRoom[#Zones.PlayerOutfitRoom + 1] = SetupZone(Config.PlayerOutfitRooms[i], onPlayerOutfitRoomEnter, onZoneExit)
    end
end

local function SetupZones()
    SetupStoreZones()
    SetupClothingRoomZones()
    SetupPlayerOutfitRoomZones()
end

local function ZonesLoop()
    Wait(1000)
    while true do
        local sleep = 1000
        if currentZone then
            sleep = 5
            if IsControlJustReleased(0, 38) then
                if currentZone.name == "clothingRoom" then
                    local clothingRoom = Config.ClothingRooms[currentZone.index]
                    local outfits = GetPlayerJobOutfits(clothingRoom.job)
                    TriggerEvent("illenium-appearance:client:openJobOutfitsMenu", outfits)
                elseif currentZone.name == "playerOutfitRoom" then
                    local outfitRoom = Config.PlayerOutfitRooms[currentZone.index]
                    OpenOutfitRoom(outfitRoom)
                elseif currentZone.name == "clothing" then
                    TriggerEvent("illenium-appearance:client:openClothingShopMenu", false, currentZone.shopType)
                elseif currentZone.name == "barber" then
                    OpenBarberShop()
                elseif currentZone.name == "tattoo" then
                    OpenTattooShop()
                elseif currentZone.name == "surgeon" then
                    OpenSurgeonShop()
                end
            end
        end
        Wait(sleep)
    end
end


CreateThread(function()
    SetupZones()
    if not Config.UseRadialMenu then
        ZonesLoop()
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        RemoveZones()
    end
end)

RegisterNetEvent("illenium-appearance:client:OpenClothingRoom", function()
    local clothingRoom = Config.ClothingRooms[currentZone.index]
    local outfits = GetPlayerJobOutfits(clothingRoom.job)
    TriggerEvent("illenium-appearance:client:openJobOutfitsMenu", outfits)
end)

RegisterNetEvent("illenium-appearance:client:OpenPlayerOutfitRoom", function()
    local outfitRoom = Config.PlayerOutfitRooms[currentZone.index]
    OpenOutfitRoom(outfitRoom)
end)
