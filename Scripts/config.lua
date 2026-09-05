return {
    -- UE4SS Key name. Examples: "F5", "S", "HOME".
    Key = "F5",
    Shift = false,
    Ctrl = false,
    Alt = false,

    -- "Default": show detailed results when triggered from inventory.
    -- "TextOnly": always use compact text notifications.
    -- "ResultWindow": always show an independently controlled result window.
    ResultDisplay = "Default",

    -- Also stack items ignored through Tab -> R. This never modifies that list.
    IncludeExcludedItems = false,

    -- Also stack items that do not yet exist in ordinary storage.
    IncludeNewItems = true,

    -- Also use an accessible Guild Chest in the current base.
    IncludeGuildChest = false,
    -- Sell only the fixed high-value merchant whitelist before stacking.
    AutoSellValuables = false,
    -- Comma-separated high-value item IDs. Remove an ID to keep that item.
    ValuableSellItems = "Ruby,Sapphire,Eemerald,Diamond,PalItem_ToSell_01,PalItem_ToSell_02,PalItem_ToSell_03,PalItem_ToSell_04,PalItem_ToSell_05",
    -- Sell only the selected current ammunition before stacking.
    AutoSellAmmo = false,
    -- Comma-separated ammunition IDs. Empty protects every ammunition type.
    AmmoSellItems = "",
    -- Sell only the selected current Pal Spheres before stacking.
    AutoSellPalSpheres = false,
    -- Comma-separated Pal Sphere IDs. Empty protects every Pal Sphere type.
    PalSphereSellItems = "",
    -- Sell only the selected current fishing bait before stacking.
    AutoSellFishingBait = false,
    -- Comma-separated fishing-bait IDs. Empty protects every fishing-bait type.
    FishingBaitSellItems = "",
    -- Put cakes in Breeding Farms before cold and ordinary storage.
    BreedingFarmCakeFirst = true,
    -- Put non-cake food in Pal Food Boxes before cold and ordinary storage.
    FoodBoxFirst = true,
    -- Put medical supplies in Medicine Racks before ordinary storage.
    MedicineRackFirst = false,
    -- Use small incubators only after large incubators have no empty slots.
    IncludeSmallIncubators = false,

    -- "IncubatorOnly", "IncubatorThenStorage", or "ManualPlacement".
    PalEggRouting = "IncubatorOnly",

    -- "RecyclerOnly", "RecyclerThenStorage", or "ManualPlacement".
    RelicRouting = "RecyclerOnly",

    -- Keep this many World Tree Holy Water in each Ancient Relic Recycler.
    -- Integer from 1 to 100.
    WorldTreeHolyWaterMinimum = 10,

    -- One-shot development timing capture. Release packages must keep this false.
    PerformanceCapture = false,

    -- Developer logging. Release packages must keep this false.
    Debug = false,
}
