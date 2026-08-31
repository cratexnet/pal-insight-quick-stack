return {
    -- UE4SS Key name. Examples: "F5", "S", "HOME".
    Key = "F5",
    Shift = false,
    Ctrl = false,
    Alt = false,

    -- Route Pal eggs with the custom exclusion-aware path.
    AltEggSorting = true,

    -- Put eligible eggs into free incubators before normal storage.
    IncubatorsFirst = true,

    -- After exact-item storage, allow empty filtered storage that accepts the
    -- item's category.
    FillByChestFilter = true,

    -- One-shot development timing capture. Release packages must keep this false.
    PerformanceCapture = false,

    -- Developer logging. Release packages must keep this false.
    Debug = false,
}
