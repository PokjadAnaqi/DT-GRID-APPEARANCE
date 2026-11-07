-- DT GRID APPEARANCE | Beta 3 custom tattoo configuration.
-- This file is additive. The existing GTA tattoo shop configuration is unchanged.
Config.CustomTattoo = {
    Enabled = true,
    -- SAFETY: keep this false until a tested multiplayer ped-rendering pipeline exists.
    -- Once true, Save to Library charges exactly 300 cash/DTC for one new design.
    PurchaseEnabled = false,
    -- Only explicitly installed GTA decoration collections can be approved for wearing.
    -- Example: ['dtgrid_custom_overlays'] = 'dtgrid_custom_tattoo_pack'
    StreamedCollections = {},
    Price = 300,
    MoneyType = 'cash',
    Currency = 'DTC',
    MaxDesigns = 20,
    MaxSourceBytes = 2097152,
    MaxEncodedBytes = 360000, -- Compressed/canvas-exported PNG payload, not original local file.
    MaxThumbnailBytes = 40000,
    MaxDimension = 512,
    RequireTattooShop = true,
    ShopDistance = 12.0,
    SaveCooldownSeconds = 10,
    BodyZones = {
        'ZONE_HEAD', 'ZONE_TORSO', 'ZONE_LEFT_ARM',
        'ZONE_RIGHT_ARM', 'ZONE_LEFT_LEG', 'ZONE_RIGHT_LEG'
    }
}
