local SaleConsumables = {}

local ICON_ROOT = "/Game/Others/InventoryItemIcon/Texture/"

local function makeCatalog(items, settingName, iconPath)
    local catalog = { items = items, set = {}, settingName = settingName }
    for _, staticId in ipairs(items) do catalog.set[staticId] = true end

    function catalog.iconPath(staticId)
        staticId = tostring(staticId or "")
        if not catalog.set[staticId] then return nil end
        return iconPath(staticId)
    end

    function catalog.normalizeSellItems(value)
        if type(value) ~= "string" then
            return nil, settingName .. " must be a comma-separated string"
        end
        local selected = {}
        for staticId in value:gmatch("[^,%s]+") do
            if catalog.set[staticId] then selected[staticId] = true end
        end
        local canonical = {}
        for _, staticId in ipairs(items) do
            if selected[staticId] then canonical[#canonical + 1] = staticId end
        end
        return table.concat(canonical, ","), nil
    end

    function catalog.sellSet(value)
        local normalized = catalog.normalizeSellItems(value)
        local selected = {}
        if normalized == nil then return selected end
        for staticId in normalized:gmatch("[^,]+") do selected[staticId] = true end
        return selected
    end

    function catalog.keptCount(value)
        local selected = catalog.sellSet(value)
        local sold = 0
        for _, staticId in ipairs(items) do
            if selected[staticId] then sold = sold + 1 end
        end
        return #items - sold
    end

    function catalog.summary(template, value)
        template = type(template) == "string" and template or "Keep %d / %d"
        local kept = catalog.keptCount(value)
        local ok, summary = pcall(string.format, template, kept, #items)
        return ok and summary or (tostring(kept) .. " / " .. tostring(#items))
    end

    return catalog
end

SaleConsumables.palSpheres = makeCatalog({
    "PalSphere",
    "PalSphere_Mega",
    "PalSphere_Giga",
    "PalSphere_Tera",
    "PalSphere_Master",
    "PalSphere_Legend",
    "PalSphere_Ultimate",
    "PalSphere_Exotic",
    "PalSphere_Ancient_1",
    "PalSphere_Ancient_2",
}, "PalSphereSellItems", function(staticId)
    local assetName = "T_itemicon_" .. staticId
    return ICON_ROOT .. assetName .. "." .. assetName
end)

SaleConsumables.fishingBait = makeCatalog({
    "FishingBait_1",
    "FishingBait_2",
    "FishingBait_3",
    "FishingBait_3_A",
}, "FishingBaitSellItems", function(staticId)
    local assetName = "T_itemicon_Consume_" .. staticId
    return ICON_ROOT .. assetName .. "." .. assetName
end)

return SaleConsumables
