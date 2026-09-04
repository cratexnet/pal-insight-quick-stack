local Ammo = {}

local ICON_ROOT = "/Game/Others/InventoryItemIcon/Texture/T_itemicon_Ammo_"

function Ammo.iconPath(staticId)
    staticId = tostring(staticId or "")
    if not Ammo.set[staticId] then return nil end
    local assetName = "T_itemicon_Ammo_" .. staticId
    return ICON_ROOT .. staticId .. "." .. assetName
end

Ammo.items = {
    "Arrow",
    "Arrow_Fire",
    "Arrow_Poison",
    "ReinforcedArrow",
    "SFArrow",
    "SkyBowArrow",
    "RoughBullet",
    "HandgunBullet",
    "RifleBullet",
    "ShotgunBullet",
    "AssaultRifleBullet",
    "GatlingBullet",
    "ExplosiveBullet",
    "GrenadeBullet",
    "MissileBullet",
    "LaserBullet",
    "LaserGatlingBullet",
    "BeamLauncherBullet",
    "ChargeLaserRifleBullet",
    "ElectricArcAssaultRifleBullet",
    "EnergyLauncherBullet",
    "EnergyShotgunBullet",
    "FlamethrowerBullet",
    "InkBullet",
    "MeteorBullet",
    "OverheatRifleBullet",
    "PalDopingShotBullet",
    "SkyAssaultRifleBullet",
    "SkyGrenadeLauncherBullet",
    "SkyShotgunBullet",
    "SkySubmachineGunBullet",
    "WidePenetrateShotgunBullet",
}

Ammo.set = {}
for _, staticId in ipairs(Ammo.items) do Ammo.set[staticId] = true end

function Ammo.normalizeSellItems(value)
    if type(value) ~= "string" then
        return nil, "AmmoSellItems must be a comma-separated string"
    end
    local selected = {}
    for staticId in value:gmatch("[^,%s]+") do
        if Ammo.set[staticId] then selected[staticId] = true end
    end
    local canonical = {}
    for _, staticId in ipairs(Ammo.items) do
        if selected[staticId] then canonical[#canonical + 1] = staticId end
    end
    return table.concat(canonical, ","), nil
end

function Ammo.sellSet(value)
    local normalized = Ammo.normalizeSellItems(value)
    local selected = {}
    if normalized == nil then return selected end
    for staticId in normalized:gmatch("[^,]+") do selected[staticId] = true end
    return selected
end

function Ammo.keptCount(value)
    local selected = Ammo.sellSet(value)
    local sold = 0
    for _, staticId in ipairs(Ammo.items) do
        if selected[staticId] then sold = sold + 1 end
    end
    return #Ammo.items - sold
end

function Ammo.summary(template, value)
    template = type(template) == "string" and template or "Keep %d / %d"
    local ok, summary = pcall(string.format,
        template, Ammo.keptCount(value), #Ammo.items)
    return ok and summary or (tostring(Ammo.keptCount(value))
        .. " / " .. tostring(#Ammo.items))
end

return Ammo
