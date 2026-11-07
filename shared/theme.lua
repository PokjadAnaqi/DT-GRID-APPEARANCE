-- DT GRID APPEARANCE | Apocalypse Industrial
-- Unified presentation for all existing shops. Shop types, events and mechanics stay intact.

local theme = {
    accent = '#c8a04a',
    accentRgb = '200, 160, 74',
    fontSans = 'Space Grotesk',
    fontDisplay = 'Space Grotesk',
    panelBaseHex = '#0c1113',
    panelOpacity = 0.83,
    panelBlur = 15,
    roundedPanel = '7px',
    roundedCard = '5px',
    textPrimary = '#f0f2ed',
    textSecondary = '#c4c9c2',
    textMuted = '#a0aaa3',
}

local function makeTheme()
    local result = {}
    for key, value in pairs(theme) do
        result[key] = value
    end
    return result
end

Config.UI.Themes = {
    creator = makeTheme(),
    ponsonbys = makeTheme(),
    binco = makeTheme(),
    suburban = makeTheme(),
    barber = makeTheme(),
    tattoo = makeTheme(),
    surgeon = makeTheme(),
    wardrobe = makeTheme(),
    clothingroom = makeTheme(),
    playeroutfitroom = makeTheme(),
}

-- Preserve existing configuration hooks for server-specific shop styling.
Config.UI.CustomThemes = Config.UI.CustomThemes or {}

for name, options in pairs(Config.UI.CustomThemes) do
    if type(options) == 'table' then
        local merged = makeTheme()
        for field, value in pairs(options) do
            merged[field] = value
        end
        Config.UI.Themes[name] = merged
    end
end
