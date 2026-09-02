local Settings = {}

local DEFAULTS = {
    Key = "F5",
    Shift = false,
    Ctrl = false,
    Alt = false,
    ResultDisplay = "Default",
    IncludeExcludedItems = false,
    IncludeNewItems = true,
    PalEggRouting = "IncubatorOnly",
    RelicRouting = "RecyclerOnly",
    WorldTreeHolyWaterMinimum = 10,
    PerformanceCapture = false,
    Debug = false,
}

local ORDER = {
    "Key",
    "Shift",
    "Ctrl",
    "Alt",
    "ResultDisplay",
    "IncludeExcludedItems",
    "IncludeNewItems",
    "PalEggRouting",
    "RelicRouting",
    "WorldTreeHolyWaterMinimum",
    "PerformanceCapture",
    "Debug",
}

-- Unreal's FKey names are not always identical to UE4SS's exposed virtual-key
-- names. Keep the small translation at the configuration boundary so both a
-- manually authored UE4SS name and Pal Insight's FKey name remain valid.
local UE4SS_KEY_ALIASES = {
    LeftMouseButton = "LEFT_MOUSE_BUTTON",
    RightMouseButton = "RIGHT_MOUSE_BUTTON",
    MiddleMouseButton = "MIDDLE_MOUSE_BUTTON",
    ThumbMouseButton = "XBUTTON_ONE",
    ThumbMouseButton2 = "XBUTTON_TWO",
    BackSpace = "BACKSPACE",
    Tab = "TAB",
    Enter = "RETURN",
    CapsLock = "CAPS_LOCK",
    Escape = "ESCAPE",
    SpaceBar = "SPACE",
    PageUp = "PAGE_UP",
    PageDown = "PAGE_DOWN",
    Left = "LEFT_ARROW",
    Up = "UP_ARROW",
    Right = "RIGHT_ARROW",
    Down = "DOWN_ARROW",
    Insert = "INS",
    Delete = "DEL",
    Zero = "ZERO",
    One = "ONE",
    Two = "TWO",
    Three = "THREE",
    Four = "FOUR",
    Five = "FIVE",
    Six = "SIX",
    Seven = "SEVEN",
    Eight = "EIGHT",
    Nine = "NINE",
    NumPadZero = "NUM_ZERO",
    NumPadOne = "NUM_ONE",
    NumPadTwo = "NUM_TWO",
    NumPadThree = "NUM_THREE",
    NumPadFour = "NUM_FOUR",
    NumPadFive = "NUM_FIVE",
    NumPadSix = "NUM_SIX",
    NumPadSeven = "NUM_SEVEN",
    NumPadEight = "NUM_EIGHT",
    NumPadNine = "NUM_NINE",
    NumLock = "NUM_LOCK",
    ScrollLock = "SCROLL_LOCK",
    Semicolon = "OEM_ONE",
    Equals = "OEM_PLUS",
    Comma = "OEM_COMMA",
    Hyphen = "OEM_MINUS",
    Period = "OEM_PERIOD",
    Slash = "OEM_TWO",
    Tilde = "OEM_THREE",
    LeftBracket = "OEM_FOUR",
    Backslash = "OEM_FIVE",
    RightBracket = "OEM_SIX",
    Apostrophe = "OEM_SEVEN",
}

local UNREAL_KEY_NAMES = {}
for unrealName, ue4ssName in pairs(UE4SS_KEY_ALIASES) do
    UNREAL_KEY_NAMES[ue4ssName] = unrealName
end

local function copyDefaults()
    local out = {}
    for _, key in ipairs(ORDER) do out[key] = DEFAULTS[key] end
    return out
end

local function readFile(path)
    if type(path) ~= "string" or path == "" then return nil, "invalid path" end
    local opened, file, openError = pcall(function() return io.open(path, "r") end)
    if not opened or file == nil then return nil, openError or "cannot open file" end
    local readOk, text = pcall(function() return file:read("*a") end)
    pcall(function() file:close() end)
    if not readOk or type(text) ~= "string" then return nil, "cannot read file" end
    return text, nil
end

local function parseBoolean(text, key)
    local value = text:match(key .. "%s*=%s*(true)")
    if value == nil then value = text:match(key .. "%s*=%s*(false)") end
    if value == "true" then return true end
    if value == "false" then return false end
    return nil
end

local RESULT_DISPLAY_VALUES = {
    Default = true,
    TextOnly = true,
    ResultWindow = true,
}

local PAL_EGG_ROUTING_VALUES = {
    IncubatorOnly = true,
    IncubatorThenStorage = true,
    ManualPlacement = true,
}

local RELIC_ROUTING_VALUES = {
    RecyclerOnly = true,
    RecyclerThenStorage = true,
    ManualPlacement = true,
}

function Settings.validateResultDisplay(value)
    if type(value) ~= "string" or not RESULT_DISPLAY_VALUES[value] then
        return nil, "ResultDisplay must be Default, TextOnly, or ResultWindow"
    end
    return value, nil
end

function Settings.validatePalEggRouting(value)
    if type(value) ~= "string" or not PAL_EGG_ROUTING_VALUES[value] then
        return nil, "PalEggRouting must be IncubatorOnly, IncubatorThenStorage, or ManualPlacement"
    end
    return value, nil
end

function Settings.validateRelicRouting(value)
    if type(value) ~= "string" or not RELIC_ROUTING_VALUES[value] then
        return nil, "RelicRouting must be RecyclerOnly, RecyclerThenStorage, or ManualPlacement"
    end
    return value, nil
end

function Settings.validateWorldTreeHolyWaterMinimum(value)
    value = tonumber(value)
    if value == nil or value ~= math.floor(value) or value < 1 or value > 100 then
        return nil, "WorldTreeHolyWaterMinimum must be an integer from 1 to 100"
    end
    return value, nil
end

local function parseConfig(text)
    if type(text) ~= "string"
        or not text:match("^%s*return%s*{")
        or not text:match("}%s*$") then
        return nil, "config is incomplete or unsupported"
    end

    text = text:gsub("%-%-[^\r\n]*", "")
    local parsed = copyDefaults()
    local key = text:match('Key%s*=%s*"([^"\\]+)"')
        or text:match("Key%s*=%s*'([^'\\]+)'")
    if key ~= nil then parsed.Key = key end
    local resultDisplay = text:match('ResultDisplay%s*=%s*"([^"\\]+)"')
        or text:match("ResultDisplay%s*=%s*'([^'\\]+)'")
    if resultDisplay ~= nil then parsed.ResultDisplay = resultDisplay end
    local palEggRouting = text:match('PalEggRouting%s*=%s*"([^"\\]+)"')
        or text:match("PalEggRouting%s*=%s*'([^'\\]+)'")
    if palEggRouting ~= nil then parsed.PalEggRouting = palEggRouting end
    local relicRouting = text:match('RelicRouting%s*=%s*"([^"\\]+)"')
        or text:match("RelicRouting%s*=%s*'([^'\\]+)'")
    if relicRouting ~= nil then parsed.RelicRouting = relicRouting end
    local holyWaterMinimumText = text:match(
        "WorldTreeHolyWaterMinimum%s*=%s*([%+%-]?%d+%.?%d*)")
    local holyWaterMinimum = holyWaterMinimumText ~= nil
        and select(1, Settings.validateWorldTreeHolyWaterMinimum(
            tonumber(holyWaterMinimumText))) or nil
    if holyWaterMinimum ~= nil then
        parsed.WorldTreeHolyWaterMinimum = holyWaterMinimum
    end
    for _, name in ipairs({
        "Shift", "Ctrl", "Alt", "IncludeExcludedItems", "IncludeNewItems",
        "PerformanceCapture", "Debug",
    }) do
        local value = parseBoolean(text, name)
        if value ~= nil then parsed[name] = value end
    end
    local legacyShowDetailedResults = parseBoolean(text, "ShowDetailedResults")
    local legacyOnlyExistingItems = parseBoolean(text, "OnlyExistingItems")
    local legacyIncludePalEggs = parseBoolean(text, "IncludePalEggs")
    local legacyExcludePalEggs = parseBoolean(text, "ExcludePalEggs")
    local legacyFillByChestFilter = parseBoolean(text, "FillByChestFilter")
    if resultDisplay == nil and legacyShowDetailedResults ~= nil then
        parsed.ResultDisplay = legacyShowDetailedResults
            and "Default" or "TextOnly"
    end
    if parseBoolean(text, "IncludeNewItems") == nil then
        if legacyOnlyExistingItems ~= nil then
            parsed.IncludeNewItems = not legacyOnlyExistingItems
        elseif legacyFillByChestFilter ~= nil then
            parsed.IncludeNewItems = legacyFillByChestFilter
        end
    end
    local validatedPalEggRouting = palEggRouting ~= nil
        and select(1, Settings.validatePalEggRouting(palEggRouting)) or nil
    if validatedPalEggRouting == nil then
        if legacyIncludePalEggs ~= nil then
            parsed.PalEggRouting = legacyIncludePalEggs
                and "IncubatorThenStorage" or "IncubatorOnly"
        elseif legacyExcludePalEggs ~= nil then
            parsed.PalEggRouting = legacyExcludePalEggs
                and "IncubatorOnly" or "IncubatorThenStorage"
        end
    end
    local validatedRelicRouting = relicRouting ~= nil
        and select(1, Settings.validateRelicRouting(relicRouting)) or nil
    local validatedResultDisplay = resultDisplay ~= nil
        and select(1, Settings.validateResultDisplay(resultDisplay)) or nil
    local needsRewrite = validatedResultDisplay == nil
        or validatedPalEggRouting == nil
        or validatedRelicRouting == nil
        or holyWaterMinimum == nil
        or parseBoolean(text, "IncludeNewItems") == nil
        or legacyShowDetailedResults ~= nil
        or legacyOnlyExistingItems ~= nil
        or legacyIncludePalEggs ~= nil
        or legacyExcludePalEggs ~= nil
        or legacyFillByChestFilter ~= nil
        or parseBoolean(text, "AltEggSorting") ~= nil
        or parseBoolean(text, "IncubatorsFirst") ~= nil
    return parsed, nil, needsRewrite
end

local function normalizeConfig(candidate, log)
    local out = copyDefaults()
    if type(candidate) ~= "table" then return out end

    local shortcut = Settings.validateShortcut({
        Key = candidate.Key or DEFAULTS.Key,
        Shift = type(candidate.Shift) == "boolean" and candidate.Shift or false,
        Ctrl = type(candidate.Ctrl) == "boolean" and candidate.Ctrl or false,
        Alt = type(candidate.Alt) == "boolean" and candidate.Alt or false,
    })
    if shortcut ~= nil then
        out.Key = shortcut.Key
    else
        log("invalid Key '" .. tostring(candidate.Key) .. "'; using F5")
    end
    for _, name in ipairs({
        "Shift", "Ctrl", "Alt", "IncludeExcludedItems", "IncludeNewItems",
        "PerformanceCapture", "Debug",
    }) do
        if type(candidate[name]) == "boolean" then out[name] = candidate[name] end
    end
    local resultDisplay, resultDisplayError =
        Settings.validateResultDisplay(candidate.ResultDisplay)
    if resultDisplay ~= nil then
        out.ResultDisplay = resultDisplay
    elseif type(candidate.ShowDetailedResults) == "boolean" then
        out.ResultDisplay = candidate.ShowDetailedResults
            and "Default" or "TextOnly"
    else
        log("invalid ResultDisplay '" .. tostring(candidate.ResultDisplay)
            .. "'; using Default: " .. tostring(resultDisplayError))
    end
    if type(candidate.IncludeNewItems) ~= "boolean" then
        if type(candidate.OnlyExistingItems) == "boolean" then
            out.IncludeNewItems = not candidate.OnlyExistingItems
        elseif type(candidate.FillByChestFilter) == "boolean" then
            out.IncludeNewItems = candidate.FillByChestFilter
        end
    end
    local palEggRouting, palEggRoutingError =
        Settings.validatePalEggRouting(candidate.PalEggRouting)
    if palEggRouting ~= nil then
        out.PalEggRouting = palEggRouting
    elseif type(candidate.IncludePalEggs) == "boolean" then
        out.PalEggRouting = candidate.IncludePalEggs
            and "IncubatorThenStorage" or "IncubatorOnly"
    elseif type(candidate.ExcludePalEggs) == "boolean" then
        out.PalEggRouting = candidate.ExcludePalEggs
            and "IncubatorOnly" or "IncubatorThenStorage"
    else
        log("invalid PalEggRouting '" .. tostring(candidate.PalEggRouting)
            .. "'; using IncubatorOnly: " .. tostring(palEggRoutingError))
    end
    local relicRouting, relicRoutingError =
        Settings.validateRelicRouting(candidate.RelicRouting)
    if relicRouting ~= nil then
        out.RelicRouting = relicRouting
    elseif candidate.RelicRouting == "KeepWhenFull" then
        out.RelicRouting = "RecyclerOnly"
    elseif candidate.RelicRouting == "NormalStorage"
        or candidate.RelicRouting == "PreferRecycler" then
        out.RelicRouting = "RecyclerThenStorage"
    else
        log("invalid RelicRouting '" .. tostring(candidate.RelicRouting)
            .. "'; using RecyclerOnly: " .. tostring(relicRoutingError))
    end
    local holyWaterMinimum, holyWaterMinimumError =
        Settings.validateWorldTreeHolyWaterMinimum(
            candidate.WorldTreeHolyWaterMinimum)
    if holyWaterMinimum ~= nil then
        out.WorldTreeHolyWaterMinimum = holyWaterMinimum
    else
        log("invalid WorldTreeHolyWaterMinimum '"
            .. tostring(candidate.WorldTreeHolyWaterMinimum)
            .. "'; using 10: " .. tostring(holyWaterMinimumError))
    end
    return out
end

local function configText(config)
    local lines = {
        "return {",
        "    -- User-editable Pal Insight: Quick Stack configuration.",
        "    -- Example Ctrl+S: Key = \"S\", Ctrl = true.",
        string.format("    Key = %q,", config.Key),
        "    Shift = " .. tostring(config.Shift) .. ",",
        "    Ctrl = " .. tostring(config.Ctrl) .. ",",
        "    Alt = " .. tostring(config.Alt) .. ",",
        "    -- Default, TextOnly, or ResultWindow.",
        string.format("    ResultDisplay = %q,", config.ResultDisplay),
        "",
        "    -- IncludeExcludedItems never modifies the game's ignored-item list.",
        "    IncludeExcludedItems = " .. tostring(config.IncludeExcludedItems) .. ",",
        "    IncludeNewItems = " .. tostring(config.IncludeNewItems) .. ",",
        "    -- IncubatorOnly, IncubatorThenStorage, or ManualPlacement.",
        string.format("    PalEggRouting = %q,", config.PalEggRouting),
        "    -- RecyclerOnly, RecyclerThenStorage, or ManualPlacement.",
        string.format("    RelicRouting = %q,", config.RelicRouting),
        "    -- Minimum World Tree Holy Water per Ancient Relic Recycler (1-100).",
        "    WorldTreeHolyWaterMinimum = "
            .. tostring(config.WorldTreeHolyWaterMinimum) .. ",",
        "    PerformanceCapture = " .. tostring(config.PerformanceCapture) .. ",",
        "    Debug = " .. tostring(config.Debug) .. ",",
        "}",
    }
    return table.concat(lines, "\n") .. "\n"
end

local function removeFile(path)
    local called, removed, removeError = pcall(function() return os.remove(path) end)
    if not called then return false, removed end
    if removed == nil then return false, removeError or "cannot remove file" end
    return true, nil
end

local function renameFile(source, destination)
    local called, renamed, renameError = pcall(function()
        return os.rename(source, destination)
    end)
    if not called then return false, renamed end
    if renamed == nil then return false, renameError or "cannot rename file" end
    return true, nil
end

local function writeFile(path, payload)
    local opened, file, openError = pcall(function() return io.open(path, "w") end)
    if not opened then return false, file or "cannot open config" end
    if file == nil then return false, openError or "cannot open config" end
    local wrote, writeResult, writeError = pcall(function() return file:write(payload) end)
    local closed, closeResult, closeError = pcall(function() return file:close() end)
    if not wrote then return false, writeResult or "cannot write config" end
    if writeResult == nil then return false, writeError or "cannot write config" end
    if not closed then return false, closeResult or "cannot close config" end
    if closeResult == nil then return false, closeError or "cannot close config" end
    return true, nil
end

local function writeNewConfig(path, config)
    local temporaryPath = path .. ".tmp"
    local backupPath = path .. ".bak"
    removeFile(temporaryPath)
    local wrote, writeError = writeFile(temporaryPath, configText(config))
    if not wrote then
        removeFile(temporaryPath)
        return false, writeError
    end

    local currentText = readFile(path)
    local preserved = currentText ~= nil
    if preserved then
        removeFile(backupPath)
        local preservedOk, preserveError = renameFile(path, backupPath)
        if not preservedOk then
            removeFile(temporaryPath)
            return false, "cannot preserve config: " .. tostring(preserveError)
        end
    end

    local promoted, promoteError = renameFile(temporaryPath, path)
    if not promoted then
        local restored, restoreError = true, nil
        if preserved then restored, restoreError = renameFile(backupPath, path) end
        removeFile(temporaryPath)
        if not restored then
            return false, "cannot replace config: " .. tostring(promoteError)
                .. "; backup restore failed: " .. tostring(restoreError)
        end
        return false, "cannot replace config: " .. tostring(promoteError)
    end

    removeFile(backupPath)
    return true, nil
end

local function recoverConfigBackup(path, log)
    local backupPath = path .. ".bak"
    local backupText = readFile(backupPath)
    if backupText == nil then return nil end
    local parsed, parseError = parseConfig(backupText)
    if parsed == nil then
        log("writable config backup rejected: " .. tostring(parseError))
        return nil
    end
    local restored, restoreError = renameFile(backupPath, path)
    if restored then
        removeFile(path .. ".tmp")
        log("restored writable config backup: " .. path)
    else
        log("cannot restore writable config backup: " .. tostring(restoreError))
    end
    return backupText
end

function Settings.keyValue(keyName)
    if type(Key) ~= "table" or type(keyName) ~= "string"
        or keyName == "" then return nil end
    local exposedName = UE4SS_KEY_ALIASES[keyName]
    if exposedName ~= nil and Key[exposedName] ~= nil then
        return Key[exposedName], keyName
    end
    if Key[keyName] ~= nil then
        return Key[keyName], UNREAL_KEY_NAMES[keyName] or keyName
    end
    local upper = keyName:upper()
    if Key[upper] ~= nil then
        return Key[upper], UNREAL_KEY_NAMES[upper] or upper
    end
    return nil
end

function Settings.validateShortcut(candidate)
    if type(candidate) ~= "table" then return nil, "shortcut must be a table" end
    if type(candidate.Key) ~= "string" or candidate.Key == "" then
        return nil, "Key must be a non-empty string"
    end
    for _, name in ipairs({ "Shift", "Ctrl", "Alt" }) do
        if type(candidate[name]) ~= "boolean" then
            return nil, name .. " must be a boolean"
        end
    end
    local _, canonicalKey = Settings.keyValue(candidate.Key)
    if canonicalKey == nil then return nil, "Key is unavailable" end
    if canonicalKey == "F6" or canonicalKey == "Escape"
        or canonicalKey == "LeftMouseButton" then
        return nil, canonicalKey .. " is reserved for the settings surface"
    end
    return {
        Key = canonicalKey,
        Shift = candidate.Shift,
        Ctrl = candidate.Ctrl,
        Alt = candidate.Alt,
    }, nil
end

function Settings.save(path, config)
    if type(path) ~= "string" or path == "" then
        return false, "writable config path is unavailable"
    end
    return writeNewConfig(path, config)
end

function Settings.load(log)
    local packaged = copyDefaults()
    local packageOk, packageValue = pcall(require, "config")
    if packageOk and type(packageValue) == "table" then packaged = packageValue end
    packaged = normalizeConfig(packaged, log)

    local envOk, localAppData = pcall(function() return os.getenv("LOCALAPPDATA") end)
    if not envOk or type(localAppData) ~= "string" or localAppData == "" then
        log("LOCALAPPDATA is unavailable; using packaged settings for this run")
        return packaged, nil
    end

    local root = localAppData:gsub("\\", "/"):gsub("/+$", "")
    local path = root .. "/Pal/Saved/PalInsightQuickStackSettings.lua"
    local legacyPath = root .. "/Pal/Saved/PalInsightQuickStack-config.lua"
    local text, readError = readFile(path)
    if text == nil then text = recoverConfigBackup(path, log) end
    if text == nil then
        local legacyText = readFile(legacyPath)
        if legacyText ~= nil then
            local legacyParsed, legacyParseError = parseConfig(legacyText)
            if legacyParsed ~= nil then
                local migrated = normalizeConfig(legacyParsed, log)
                local migratedOk, migrateError = writeNewConfig(path, migrated)
                if migratedOk then
                    log("migrated writable config: " .. legacyPath .. " -> " .. path)
                else
                    log("cannot migrate writable config: " .. tostring(migrateError))
                end
                return migrated, path
            end
            log("legacy writable config rejected: " .. tostring(legacyParseError))
        end

        local created, createError = writeNewConfig(path, packaged)
        if not created then
            log("cannot create writable config: " .. tostring(createError or readError))
        else
            log("created writable config: " .. path)
        end
        return packaged, path
    end

    local parsed, parseError, needsMigration = parseConfig(text)
    if parsed == nil then
        log("writable config rejected: " .. tostring(parseError))
        return packaged, path
    end
    local normalized = normalizeConfig(parsed, log)
    if needsMigration then
        local migrated, migrateError = writeNewConfig(path, normalized)
        if migrated then
            log("updated writable config schema: " .. path)
        else
            log("cannot migrate writable config: " .. tostring(migrateError))
        end
    end
    return normalized, path
end

function Settings.modifierValues(config)
    local modifiers = {}
    if type(ModifierKey) ~= "table" then return modifiers end
    if config.Ctrl then modifiers[#modifiers + 1] = ModifierKey.CONTROL end
    if config.Shift then modifiers[#modifiers + 1] = ModifierKey.SHIFT end
    if config.Alt then modifiers[#modifiers + 1] = ModifierKey.ALT end
    return modifiers
end

function Settings.chordSignature(config)
    return table.concat({
        config.Key,
        config.Ctrl and "C" or "-",
        config.Shift and "S" or "-",
        config.Alt and "A" or "-",
    }, ":")
end

return Settings
