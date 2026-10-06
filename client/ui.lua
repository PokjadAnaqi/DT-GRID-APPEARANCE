-- DT GRID / Lation Modern UI bridge.
-- Uses Lation UI for Input, Menu and Text UI when Config.LationUI = true.
-- ox_lib remains the zero-config fallback so the appearance resource does not
-- hard-depend on lation_ui being installed or started.

AppearanceUI = AppearanceUI or {}

local RESOURCE = 'lation_ui'
local textVisible = false
local textProvider = nil

local function style()
    return Config.LationUIStyle or {}
end

local function resourceName()
    return style().resource or RESOURCE
end

local function isLationReady()
    return Config.LationUI == true and GetResourceState(resourceName()) == 'started'
end

AppearanceUI.IsLation = isLationReady

local function clone(value)
    if type(value) ~= 'table' then return value end

    local output = {}
    for key, entry in pairs(value) do
        output[key] = clone(entry)
    end
    return output
end

local function fa(icon, fallback)
    icon = icon or fallback
    if type(icon) ~= 'string' or icon == '' then return fallback end
    if icon:match('^https?://') or icon:match('^nui://') or icon:match('%.png$')
        or icon:match('%.webp$') or icon:match('%.jpg$') or icon:match('%.jpeg$')
        or icon:match('%.gif$') or icon:match('%.svg$') then
        return icon
    end

    -- ox_lib commonly accepts short FontAwesome names (e.g. "shirt").
    -- Lation expects a FontAwesome class, so normalize short names.
    if not icon:find('fa%-', 1, false) and not icon:find('fas ', 1, true)
        and not icon:find('far ', 1, true) and not icon:find('fab ', 1, true) then
        icon = ('fas fa-%s'):format(icon)
    elseif icon:sub(1, 3) == 'fa-' then
        icon = 'fas ' .. icon
    end

    return icon
end

local FIELD_ICONS = {
    input = 'fas fa-keyboard',
    number = 'fas fa-hashtag',
    textarea = 'fas fa-align-left',
    checkbox = 'fas fa-square-check',
    toggle = 'fas fa-toggle-on',
    select = 'fas fa-list',
    ['multi-select'] = 'fas fa-list-check',
    slider = 'fas fa-sliders',
    color = 'fas fa-palette',
    date = 'fas fa-calendar-days',
    ['date-range'] = 'fas fa-calendar-week',
}

local function normalizeInputFields(fields)
    local cfg = style()
    local normalized = clone(fields or {})

    for i = 1, #normalized do
        local field = normalized[i]
        if type(field) == 'table' then
            field.type = field.type == 'multi-select' and 'multi-select' or field.type
            field.icon = fa(field.icon, FIELD_ICONS[field.type] or 'fas fa-keyboard')
            field.iconColor = field.iconColor or cfg.inputIconColor or '#C8A04A'
        end
    end

    return normalized
end

---Open an input dialog using Lation UI, with ox_lib fallback.
---@param title string
---@param fields table
---@param options table?
---@return table?
function AppearanceUI.Input(title, fields, options)
    options = options or {}

    if isLationReady() then
        local payload = {
            title = title,
            subtitle = options.subtitle,
            submitText = options.submitText or options.confirmText,
            cancelText = options.cancelText,
            cancel = options.cancel ~= false,
            type = options.type or 'default',
            options = normalizeInputFields(fields),
        }

        local ok, result = pcall(function()
            return exports[resourceName()]:input(payload)
        end)

        if ok then return result end
        print(('^3[illenium-appearance] Lation input failed; falling back to ox_lib: %s^0'):format(tostring(result)))
    end

    return lib.inputDialog(title, fields, options)
end

local function menuHeaderIcon(menu)
    local id = tostring(menu.id or ''):lower()
    local title = tostring(menu.title or ''):lower()

    if id:find('delete', 1, true) or title:find('delete', 1, true) then return 'fas fa-trash-can' end
    if id:find('generate', 1, true) or title:find('code', 1, true) then return 'fas fa-code' end
    if id:find('update', 1, true) then return 'fas fa-pen-to-square' end
    if id:find('management', 1, true) then return 'fas fa-user-gear' end
    if id:find('job', 1, true) or title:find('job', 1, true) then return 'fas fa-briefcase' end
    if id:find('outfit', 1, true) then return 'fas fa-shirt' end
    return 'fas fa-shirt'
end

local function menuOptionIcon(option)
    local title = tostring(option.title or ''):lower()
    local event = tostring(option.event or ''):lower()
    local submenu = tostring(option.menu or ''):lower()

    if event:find('openclothingshop', 1, true) then return 'fas fa-shirt', 'beat', '#C8A04A' end
    if event:find('reloadskin', 1, true) then return 'fas fa-user', 'fade', '#E5E7EB' end
    if event:find('delete', 1, true) or title:find('delete', 1, true) or submenu:find('delete', 1, true) then return 'fas fa-trash-can', 'shake', '#EF4444' end
    if event:find('save', 1, true) or title:find('save', 1, true) then return 'fas fa-floppy-disk', 'beatFade', '#22C55E' end
    if event:find('import', 1, true) or title:find('import', 1, true) then return 'fas fa-file-import', 'bounce', '#38BDF8' end
    if event:find('update', 1, true) or title:find('update', 1, true) or submenu:find('update', 1, true) then return 'fas fa-pen-to-square', 'pulse', '#F59E0B' end
    if event:find('generate', 1, true) or title:find('code', 1, true) or submenu:find('generate', 1, true) then return 'fas fa-code', 'fade', '#A78BFA' end
    if event:find('changeoutfit', 1, true) or title:find('change', 1, true) or submenu:find('change', 1, true) then return 'fas fa-rotate', 'spinPulse', '#06B6D4' end
    if submenu ~= '' then return 'fas fa-folder-open', 'fade', '#C8A04A' end
    return 'fas fa-shirt', 'fade', '#C8A04A'
end

local function normalizeMenu(menu)
    local cfg = style()
    local normalized = clone(menu)

    normalized.position = normalized.position or cfg.menuPosition or 'offcenter-right'
    normalized.headerIcon = fa(normalized.headerIcon, menuHeaderIcon(normalized))
    normalized.headerIconColor = normalized.headerIconColor or cfg.headerIconColor or '#C8A04A'
    normalized.headerIconAnimation = normalized.headerIconAnimation or cfg.headerIconAnimation or 'pulse'

    for i = 1, #(normalized.options or {}) do
        local option = normalized.options[i]
        if type(option) == 'table' then
            local icon, animation, color = menuOptionIcon(option)
            option.icon = fa(option.icon, icon)
            option.iconColor = option.iconColor or ((cfg.semanticOptionColors ~= false and color) or cfg.optionIconColor) or '#C8A04A'
            option.iconAnimation = option.iconAnimation or animation or cfg.optionIconAnimation or 'fade'
            if option.menu then option.arrow = true end
        end
    end

    return normalized
end

---Register a context menu using Lation UI, with ox_lib fallback.
---@param menu table
function AppearanceUI.RegisterMenu(menu)
    -- Register the ox_lib copy as a hot fallback even while Lation is active.
    lib.registerContext(menu)

    if isLationReady() then
        local normalized = normalizeMenu(menu)
        local ok, err = pcall(function()
            exports[resourceName()]:registerMenu(normalized)
        end)
        if not ok then
            print(('^3[illenium-appearance] Lation menu registration failed; ox_lib fallback is ready: %s^0'):format(tostring(err)))
        end
    end

    return true
end

---@param id string
function AppearanceUI.ShowMenu(id)
    if isLationReady() then
        local ok, err = pcall(function()
            exports[resourceName()]:showMenu(id)
        end)
        if ok then return true end
        print(('^3[illenium-appearance] Lation menu show failed; falling back to ox_lib: %s^0'):format(tostring(err)))
    end

    lib.showContext(id)
    return true
end

function AppearanceUI.HideMenu()
    if isLationReady() then
        pcall(function() exports[resourceName()]:hideMenu() end)
        return
    end

    if lib.hideContext then lib.hideContext(false) end
end

local TEXT_PRESETS = {
    clothing = { title = 'CLOTHING STORE', icon = 'fas fa-shirt', animation = 'beat' },
    barber = { title = 'BARBER', icon = 'fas fa-scissors', animation = 'shake' },
    tattoo = { title = 'TATTOO STUDIO', icon = 'fas fa-pen-nib', animation = 'pulse' },
    surgeon = { title = 'PLASTIC SURGEON', icon = 'fas fa-user-doctor', animation = 'pulse' },
    clothingRoom = { title = 'CLOTHING ROOM', icon = 'fas fa-vest', animation = 'fade' },
    playerOutfitRoom = { title = 'OUTFIT ROOM', icon = 'fas fa-shirt', animation = 'fade' },
}

---Show interaction Text UI.
---@param interaction string
---@param description string
function AppearanceUI.ShowInteraction(interaction, description)
    local cfg = style()
    local customPresets = cfg.interactions or {}
    local preset = customPresets[interaction] or TEXT_PRESETS[interaction] or {
        title = 'INTERACTION', icon = 'fas fa-hand-pointer', iconAnimation = cfg.textIconAnimation or 'beat'
    }

    if isLationReady() then
        -- Avoid unnecessary NUI churn while zone callbacks are re-evaluated.
        if textVisible then pcall(function() exports[resourceName()]:hideText() end) end

        local ok, err = pcall(function()
            exports[resourceName()]:showText({
                title = preset.title,
                description = description,
                position = cfg.textPosition or Config.TextUIOptions.position or 'left-center',
                keybind = Config.UseRadialMenu and nil or 'E',
                icon = preset.icon,
                iconColor = preset.iconColor or cfg.textIconColor or '#C8A04A',
                iconAnimation = preset.iconAnimation or preset.animation or cfg.textIconAnimation or 'beat',
                bgColor = cfg.textBackgroundColor,
                txtColor = cfg.textColor,
            })
        end)

        if ok then
            textVisible = true
            textProvider = 'lation'
            return true
        end

        print(('^3[illenium-appearance] Lation Text UI failed; falling back to ox_lib: %s^0'):format(tostring(err)))
    end

    local prefix = Config.UseRadialMenu and '' or '[E] '
    lib.showTextUI(prefix .. description, Config.TextUIOptions)
    textVisible = true
    textProvider = 'ox'
    return true
end

function AppearanceUI.HideText()
    -- Hide whichever provider displayed the prompt. Also clean both providers so
    -- changing Config.LationUI / restarting lation_ui while inside a zone never
    -- leaves a stale prompt on screen.
    if isLationReady() or textProvider == 'lation' then
        pcall(function() exports[resourceName()]:hideText() end)
    end
    pcall(function() lib.hideTextUI() end)
    textVisible = false
    textProvider = nil
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if isLationReady() then
        pcall(function() exports[resourceName()]:hideText() end)
        pcall(function() exports[resourceName()]:hideMenu() end)
        pcall(function() exports[resourceName()]:closeInput() end)
    end
end)
