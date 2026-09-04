local Valuables = {}

local ICON_ROOT = "/Game/Others/InventoryItemIcon/Texture/T_itemicon_Material_"

Valuables.items = {
    "Ruby",
    "Sapphire",
    "Eemerald",
    "Diamond",
    "PalItem_ToSell_01",
    "PalItem_ToSell_02",
    "PalItem_ToSell_03",
    "PalItem_ToSell_04",
    "PalItem_ToSell_05",
}

Valuables.set = {}
for _, staticId in ipairs(Valuables.items) do
    Valuables.set[staticId] = true
end

Valuables.defaultSellItems = table.concat(Valuables.items, ",")

function Valuables.iconPath(staticId)
    staticId = tostring(staticId or "")
    if not Valuables.set[staticId] then return nil end
    local assetName = "T_itemicon_Material_" .. staticId
    return ICON_ROOT .. staticId .. "." .. assetName
end

function Valuables.normalizeSellItems(value)
    if type(value) ~= "string" then
        return nil, "ValuableSellItems must be a comma-separated string"
    end
    local selected = {}
    for staticId in value:gmatch("[^,%s]+") do
        if Valuables.set[staticId] then selected[staticId] = true end
    end
    local canonical = {}
    for _, staticId in ipairs(Valuables.items) do
        if selected[staticId] then canonical[#canonical + 1] = staticId end
    end
    return table.concat(canonical, ","), nil
end

function Valuables.sellSet(value)
    local normalized = Valuables.normalizeSellItems(value)
    local selected = {}
    if normalized == nil then return selected end
    for staticId in normalized:gmatch("[^,]+") do selected[staticId] = true end
    return selected
end

function Valuables.keptCount(value)
    local selected = Valuables.sellSet(value)
    local sold = 0
    for _, staticId in ipairs(Valuables.items) do
        if selected[staticId] then sold = sold + 1 end
    end
    return #Valuables.items - sold
end

function Valuables.summary(template, value)
    template = type(template) == "string" and template or "Keep %d / %d"
    local ok, summary = pcall(string.format,
        template, Valuables.keptCount(value), #Valuables.items)
    return ok and summary or (tostring(Valuables.keptCount(value))
        .. " / " .. tostring(#Valuables.items))
end

return Valuables
