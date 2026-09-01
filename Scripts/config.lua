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
