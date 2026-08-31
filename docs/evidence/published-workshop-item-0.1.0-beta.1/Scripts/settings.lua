local Settings = {}

local DEFAULTS = {
    Key = "F5",
    Shift = false,
    Ctrl = false,
    Alt = false,
    AltEggSorting = true,
    IncubatorsFirst = true,
    FillByChestFilter = true,
    PerformanceCapture = false,
    Debug = false,
}

local ORDER = {
    "Key",
    "Shift",
    "Ctrl",
    "Alt",
    "AltEggSorting",
    "IncubatorsFirst",
    "FillByChestFilter",
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
    for _, name in ipairs({
        "Shift", "Ctrl", "Alt", "AltEggSorting", "IncubatorsFirst",
        "FillByChestFilter", "PerformanceCapture", "Debug",
    }) do
        local value = parseBoolean(text, name)
        if value ~= nil then parsed[name] = value end
    end
    return parsed, nil
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
        "Shift", "Ctrl", "Alt", "AltEggSorting", "IncubatorsFirst",
        "FillByChestFilter", "PerformanceCapture", "Debug",
    }) do
        if type(candidate[name]) == "boolean" then out[name] = candidate[name] end
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
        "    AltEggSorting = " .. tostring(config.AltEggSorting) .. ",",
        "    IncubatorsFirst = " .. tostring(config.IncubatorsFirst) .. ",",
        "    FillByChestFilter = " .. tostring(config.FillByChestFilter) .. ",",
        "    PerformanceCapture = " .. tostring(config.PerformanceCapture) .. ",",
        "    Debug = " .. tostring(config.Debug) .. ",",
        "}",
    }
    return table.concat(lines, "\n") .. "\n"
end

local function writeNewConfig(path, config)
    local opened, file, openError = pcall(function() return io.open(path, "w") end)
    if not opened or file == nil then return false, openError or "cannot open config" end
    local payload = configText(config)
    local wrote, writeResult = pcall(function() return file:write(payload) end)
    local closed, closeResult = pcall(function() return file:close() end)
    if not wrote or writeResult == nil or not closed or closeResult == nil then
        return false, "cannot write config"
    end
    return true, nil
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
    local path = root .. "/Pal/Saved/PalInsightQuickStack-config.lua"
    local text, readError = readFile(path)
    if text == nil then
        local created, createError = writeNewConfig(path, packaged)
        if not created then
            log("cannot create writable config: " .. tostring(createError or readError))
        else
            log("created writable config: " .. path)
        end
        return packaged, path
    end

    local parsed, parseError = parseConfig(text)
    if parsed == nil then
        log("writable config rejected: " .. tostring(parseError))
        return packaged, path
    end
    return normalizeConfig(parsed, log), path
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
