local P = require("palworld")
local Settings = require("settings")
local Localization = require("localization")
local InputOwner = require("pal_insight_bridge")
local SteamVote = require("steam_vote")
local Ammo = require("ammo")
Ammo.valuables = require("valuables")
Ammo.saleConsumables = require("sale_consumables")

local SettingsUI = {}
SettingsUI.releaseNotes = require("release_notes")

local VIS_VISIBLE = 0
local VIS_COLLAPSED = 1
local VIS_HIT_TEST_INVISIBLE = 3
local ALIGN_FILL = 0
local ALIGN_LEFT = 1
local ALIGN_CENTER = 2
local ALIGN_RIGHT = 3
local TEXT_LEFT = 0
local TEXT_CENTER = 1
local TEXT_RIGHT = 2
local POLL_MS = 80
local PREVIEW_KEY_FUNCTION = "/Script/UMG.UserWidget:OnPreviewKeyDown"
local KEY_UP_FUNCTION = "/Script/UMG.UserWidget:OnKeyUp"
local MOUSE_MOVE_FUNCTION = "/Script/UMG.UserWidget:OnMouseMove"
local MOUSE_LEAVE_FUNCTION = "/Script/UMG.UserWidget:OnMouseLeave"

local COLORS = {
    white = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 },
    shield = { R = 0.0, G = 0.0, B = 0.0, A = 0.0 },
    modal = { R = 0.0, G = 0.0, B = 0.0, A = 0.64 },
    window = { R = 0.006, G = 0.008, B = 0.011, A = 0.78 },
    chrome = { R = 0.027, G = 0.033, B = 0.040, A = 0.72 },
    content = { R = 0.031, G = 0.037, B = 0.045, A = 0.88 },
    section = { R = 0.059, G = 0.071, B = 0.082, A = 0.90 },
    control = { R = 0.093, G = 0.112, B = 0.127, A = 0.88 },
    controlHover = { R = 0.147, G = 0.175, B = 0.198, A = 0.94 },
    rowHover = { R = 0.468, G = 0.515, B = 0.552, A = 0.14 },
    rowFocus = { R = 0.058, G = 0.105, B = 0.138, A = 0.88 },
    controlFocus = { R = 0.060, G = 0.156, B = 0.227, A = 0.96 },
    surfaceSelected = { R = 0.140, G = 0.176, B = 0.207, A = 0.92 },
    controlPressed = { R = 0.056, G = 0.070, B = 0.084, A = 0.98 },
    controlDisabled = { R = 0.047, G = 0.054, B = 0.063, A = 0.64 },
    outline = { R = 0.716, G = 0.807, B = 0.855, A = 0.15 },
    border = { R = 0.761, G = 0.807, B = 0.839, A = 0.54 },
    borderFocus = { R = 0.292, G = 0.610, B = 0.730, A = 1.0 },
    accent = { R = 0.209, G = 0.533, B = 0.665, A = 1.0 },
    accentHover = { R = 0.288, G = 0.580, B = 0.699, A = 1.0 },
    actionInfo = { R = 0.209, G = 0.533, B = 0.665, A = 1.0 },
    actionWarning = { R = 0.807, G = 0.451, B = 0.102, A = 1.0 },
    actionDanger = { R = 0.800, G = 0.390, B = 0.380, A = 1.0 },
    currentVersion = { R = 0.353, G = 0.773, B = 0.412, A = 1.0 },
    stateCapture = { R = 0.209, G = 0.533, B = 0.665, A = 1.0 },
    checkboxHover = { R = 0.930, G = 0.947, B = 0.956, A = 1.0 },
    text = { R = 0.930, G = 0.947, B = 0.956, A = 1.0 },
    muted = { R = 0.631, G = 0.680, B = 0.708, A = 1.0 },
    textMuted = { R = 0.361, G = 0.407, B = 0.440, A = 1.0 },
    textOnAccent = { R = 0.004, G = 0.009, B = 0.012, A = 1.0 },
    danger = { R = 1.0, G = 0.72, B = 0.48, A = 1.0 },
    transparent = { R = 0.0, G = 0.0, B = 0.0, A = 0.0 },
}

local SIZE = {
    row = 36.0,
    control = 32.0,
    checkbox = 40.0,
    number = 104.0,
    choice = 260.0,
    binding = 180.0,
    button = 36.0,
    contentMinimum = 240.0,
    windowOutline = 1.0,
    scrollbarThickness = 9.0,
    scrollbarPadding = 2.0,
    scrollbarGutter = 13.0,
    modalOption = 40.0,
    pageEdge = 12.0,
    headerAction = 36.0,
    headerActionGap = 8.0,
    headerActionIconBox = 20.0,
    settingsTabs = 38.0,
    settingsTabGap = 6.0,
    footer = 112.0,
    footerHelpHeader = 28.0,
    footerHelpActionGap = 4.0,
    footerHelpKeyGap = 2.0,
    footerHelpSeparatorGap = 4.0,
    footerHelpRowGap = 8.0,
    footerHelpGroupGap = 12.0,
    footerKeyGuide = 28.0,
    inlineShortcutMinWidth = 28.0,
    inlineShortcutMaxWidth = 180.0,
    aboutWidth = 620.0,
    aboutHeight = 620.0,
    aboutSectionGap = 12.0,
    aboutCardPaddingY = 12.0,
    aboutLinkHeight = 52.0,
    aboutLinkIcon = 28.0,
    aboutLinkIconColumn = 36.0,
    aboutLinkGap = 8.0,
    aboutCommunityWidth = 160.0,
    aboutProductLinkHeight = 30.0,
    aboutProductLinkGapPixels = 3.0,
    aboutProductLinkIcon = 20.0,
    aboutProductCardHeight = 174.0,
    aboutProductCurrentOutline = 1.0,
    aboutCreatorLinkWidth = 140.0,
    aboutPreviewThumbnailWidth = 160.0,
    aboutPreviewThumbnailHeight = 90.0,
    aboutPreviewMaxWidth = 960.0,
    aboutPrimaryActionWidth = 120.0,
    aboutRosterWidth = 620.0,
    aboutRosterMaxHeight = 500.0,
    aboutSupportActionWidth = 136.0,
    aboutSupportActionHeight = 40.0,
    aboutSupportLogoWidth = 124.0,
    aboutSupportLogoHeight = 35.0,
    releaseNotesIndexWidth = 116.0,
    releaseNotesPickerRowHeight = 38.0,
}

local FONT_SIZE = {
    [11] = 9, [12] = 10, [13] = 11, [14] = 12,
    [15] = 13, [16] = 13, [18] = 15, [20] = 16,
}

local SETTING_KEYS = {
    "Key", "Shift", "Ctrl", "Alt", "ResultDisplay",
    "IncludeExcludedItems", "IncludeNewItems", "IncludeGuildChest",
    "AutoSellValuables", "ValuableSellItems", "AutoSellAmmo", "AmmoSellItems",
    "AutoSellPalSpheres", "PalSphereSellItems",
    "AutoSellFishingBait", "FishingBaitSellItems",
    "KeepSaleItemsWhenNoMerchant",
    "BreedingFarmCakeFirst", "FoodBoxFirst", "MedicineRackFirst",
    "IncludeSmallIncubators", "PalEggRouting",
    "RelicRouting", "WorldTreeHolyWaterMinimum", "PerformanceCapture", "Debug",
}

local DEFAULTS = {
    Key = "F5",
    Shift = false,
    Ctrl = false,
    Alt = false,
    ResultDisplay = "Default",
    IncludeExcludedItems = false,
    IncludeNewItems = true,
    IncludeGuildChest = false,
    AutoSellValuables = false,
    ValuableSellItems = Ammo.valuables.defaultSellItems,
    AutoSellAmmo = false,
    AmmoSellItems = "",
    AutoSellPalSpheres = false,
    PalSphereSellItems = "",
    AutoSellFishingBait = false,
    FishingBaitSellItems = "",
    KeepSaleItemsWhenNoMerchant = true,
    BreedingFarmCakeFirst = true,
    FoodBoxFirst = true,
    MedicineRackFirst = false,
    IncludeSmallIncubators = false,
    PalEggRouting = "IncubatorOnly",
    RelicRouting = "RecyclerOnly",
    WorldTreeHolyWaterMinimum = 10,
}

function SettingsUI.isItemPicker(control)
    if type(control) ~= "table" then return false end
    return control.kind == "ammoPicker" or control.kind == "valuablePicker"
        or control.kind == "palSpherePicker"
        or control.kind == "fishingBaitPicker"
end

local ABOUT_URLS = {
    website = "https://cratex.app?utm_source=quick-stack&utm_medium=mod&utm_campaign=about",
    calculator = "https://cratex.app/games/palworld/breeding?utm_source=quick-stack&utm_medium=mod&utm_campaign=about",
    palInsight = "https://www.nexusmods.com/palworld/mods/4638",
    palInsightWorkshop =
        "https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118",
    palInsightCurseForge =
        "https://www.curseforge.com/palworld/blueprint-code-mods/pal-insight",
    quickStackNexus = "https://www.nexusmods.com/palworld/mods/5474",
    quickStackWorkshop =
        "https://steamcommunity.com/sharedfiles/filedetails/?id=3792968111",
    quickStackCurseForge =
        "https://www.curseforge.com/palworld/lua-code-mods/pal-insight-quick-stack",
    x = "https://x.com/cratexnet",
    discord = "https://discord.gg/JWhE4TKsBN",
    bmc = "https://buymeacoffee.com/cratexnet",
}

-- Static public credits only. Platform identities remain separate and are
-- ordered by each person's first useful public Quick Stack feedback.
local ABOUT_CREDITS = {
    thanks = {
        nexus = { "moogiemode", "Krounj" },
        steam = {
            { name = "lainverse", utf8Prefix = { 0xF0, 0x9F, 0xA6, 0x84 } },
        },
    },
    supporters = { nexus = {}, steam = {} },
}

local NUMBER_KEY_DIGITS = {
    Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
    Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
    NumPadZero = "0", NumPadOne = "1", NumPadTwo = "2",
    NumPadThree = "3", NumPadFour = "4", NumPadFive = "5",
    NumPadSix = "6", NumPadSeven = "7", NumPadEight = "8",
    NumPadNine = "9",
}

local state = {
    version = "",
    config = nil,
    configPath = nil,
    registerShortcut = nil,
    shortcutConflict = nil,
    readHostedControllerSnapshot = nil,
    ackHostedControllerSnapshot = nil,
    publishHostedCloseBlocked = nil,
    log = nil,
    onApplied = nil,
    onClosed = nil,
    open = false,
    lifecycle = "closed",
    mode = nil,
    generation = 0,
    windowSession = 0,
    closeRecoveryDeadline = 0.0,
    closeRecoveryRetryAt = 0.0,
    closeRecoveryReason = nil,
    nextContextCheckAt = 0.0,
    widget = nil,
    widgetTree = nil,
    root = nil,
    windowCache = { ready = false },
    controller = nil,
    controls = {},
    allFocusEntries = {},
    settingsPages = {},
    settingsTabButtons = {},
    settingsTabPreviousButton = nil,
    settingsTabNextButton = nil,
    settingsPageOrder = { "general", "automaticSale", "specialItems" },
    activeSettingsPage = "general",
    settingsPageScrollOffsets = {},
    buildingPageId = nil,
    statusText = nil,
    modeText = nil,
    footerHelp = nil,
    footerGuideRecords = nil,
    footerGuideSignature = nil,
    footerMode = nil,
    gamepadKeyGuideFamily = "xinput",
    shortcutWarningText = nil,
    shortcutControl = nil,
    headerActionHint = nil,
    aboutOverlay = nil,
    aboutCloseWidget = nil,
    aboutOpen = false,
    aboutRevision = 0,
    aboutReturnFocusIndex = nil,
    aboutActions = {},
    aboutFocusIndex = 1,
    aboutDefaultFocusIndex = nil,
    aboutPreferredColumn = 1,
    aboutActionHint = nil,
    aboutScroll = nil,
    aboutRosterOverlays = {},
    aboutRosterCloseWidgets = {},
    aboutRosterCloseActions = {},
    aboutRosterOpen = false,
    aboutRosterMode = nil,
    aboutPreviewOverlay = nil,
    aboutPreviewCloseWidget = nil,
    aboutPreviewCloseAction = nil,
    aboutPreviewOpen = false,
    aboutPreviewSourceIndex = nil,
    aboutTextures = {},
    releaseNotesOverlay = nil,
    releaseNotesOpen = false,
    releaseNotesRevision = 0,
    releaseNotesReturnFocusIndex = nil,
    releaseNotesFocusPane = 1,
    releaseNotesPickerIndex = 1,
    releaseNotesSelectedIndex = 1,
    releaseNotesButtons = {},
    releaseNotesPickerButtons = {},
    releaseNotesPickerScroll = nil,
    releaseNotesScroll = nil,
    releaseNotesContent = nil,
    releaseNotesContentWidth = 360.0,
    steamVoteControl = nil,
    steamVoteBox = nil,
    steamVoteNoneWidget = nil,
    steamVoteNoneSurface = nil,
    steamVoteUpSurface = nil,
    steamVoteDisplayStatus = nil,
    steamVotePendingUp = false,
    pendingDownvoteAcknowledgement = false,
    steamVoteTextures = {},
    steamVotePalTexture = nil,
    steamVotePalVisuals = {},
    steamVotePalVisualReady = false,
    steamVotePalRetryAt = 0,
    steamVoteActionVisuals = {},
    pollPending = false,
    pollGeneration = 0,
    pollLastTickAt = 0.0,
    pollLoopHandle = nil,
    pollGameThreadCallback = nil,
    gamepadBackDown = false,
    gamepadAcceptDown = false,
    controllerInputOwner = nil,
    controllerDown = {},
    controllerInputSources = {},
    lastHostedControllerEdgeRevision = nil,
    nativeControllerInitialized = false,
    axisArmed = { x = true, y = true },
    axisValues = { x = 0.0, y = 0.0 },
    navigationRepeat = nil,
    navigationRepeatInitialMs = 450,
    navigationRepeatIntervalMs = 75,
    controllerKeys = {
        "Gamepad_DPad_Up", "Gamepad_DPad_Down",
        "Gamepad_DPad_Left", "Gamepad_DPad_Right",
        "Gamepad_LeftStick_Up", "Gamepad_LeftStick_Down",
        "Gamepad_LeftStick_Left", "Gamepad_LeftStick_Right",
        "Gamepad_LeftShoulder", "Gamepad_RightShoulder",
        "Gamepad_FaceButton_Bottom", "Gamepad_FaceButton_Right",
    },
    controllerPollKeys = {
        "Gamepad_DPad_Up", "Gamepad_DPad_Down",
        "Gamepad_DPad_Left", "Gamepad_DPad_Right",
        "Gamepad_LeftShoulder", "Gamepad_RightShoulder",
        "Gamepad_FaceButton_Bottom", "Gamepad_FaceButton_Right",
    },
    hostedControllerButtons = {
        { mask = 0x0001, key = "Gamepad_DPad_Up" },
        { mask = 0x0002, key = "Gamepad_DPad_Down" },
        { mask = 0x0004, key = "Gamepad_DPad_Left" },
        { mask = 0x0008, key = "Gamepad_DPad_Right" },
        { mask = 0x0100, key = "Gamepad_LeftShoulder" },
        { mask = 0x0200, key = "Gamepad_RightShoulder" },
        { mask = 0x1000, key = "Gamepad_FaceButton_Bottom" },
        { mask = 0x2000, key = "Gamepad_FaceButton_Right" },
    },
    triggerSurfaces = {},
    directActionButtons = {},
    headerActionVisuals = {},
    contentWidth = 640.0,
    scroll = nil,
    nestedOverlay = nil,
    nestedCardBox = nil,
    nestedOutline = nil,
    nestedPanel = nil,
    nestedTitle = nil,
    nestedMessage = nil,
    nestedContent = nil,
    nestedScroll = nil,
    nestedOptionWidth = nil,
    nestedDefaultWidth = nil,
    nestedDefaultMaxHeight = nil,
    nestedOptionCapacity = nil,
    downvoteDialogWidth = nil,
    downvoteDialogMaxHeight = nil,
    modalOptions = {},
    activeChoice = nil,
    choiceReturnFocusIndex = nil,
    ammoPopulateToken = 0,
    pointerAction = nil,
    pendingAboutPointerClose = nil,
    modalIndex = 1,
    focusEntries = {},
    focusIndex = 1,
    lastInputDevice = "keyboard",
    pollFailureSignature = nil,
    previewKeyHookReady = false,
    previewKeyHookPreId = nil,
    previewKeyHookPostId = nil,
    keyUpHookReady = false,
    keyUpHookPreId = nil,
    keyUpHookPostId = nil,
    mouseMoveHookReady = false,
    mouseMoveHookPreId = nil,
    mouseMoveHookPostId = nil,
    mouseLeaveHookReady = false,
    mouseLeaveHookPreId = nil,
    mouseLeaveHookPostId = nil,
    selectorSelectedKeyHookReady = false,
    selectorSelectedKeyHookPreId = nil,
    selectorSelectedKeyHookPostId = nil,
    selectorChordProgrammatic = false,
    shortcutFocusRestoreToken = 0,
    shortcutFocusRestoreCallback = nil,
    toggleEventsSuppressed = false,
    synchronousNavigationUntil = {},
    shortcutCaptureCancelKey = nil,
    shortcutCaptureCancelUntil = 0.0,
    numberEdit = nil,
    numberEditorOps = {},
    lastPrepareDiagnostics = nil,
    trailingReleaseUntil = {},
    deferredInputClose = nil,
    deferredInputCloseCallback = nil,
}

local closeChoiceModal
local Deferred = {}

local staticObjects = {}
local currentStrings

local function log(message)
    if type(state.log) == "function" then state.log(tostring(message)) end
end

local function registerDirectActionButton(button)
    if P.isValid(button) then
        state.directActionButtons[#state.directActionButtons + 1] = button
    end
    return button
end

local function slateColor(color)
    return { SpecifiedColor = color, ColorUseRule = 0 }
end

local function tintBrush(brush, color)
    if brush == nil then return brush end
    brush.TintColor = slateColor(color)
    return brush
end

local function staticObject(path)
    local cached = staticObjects[path]
    if P.isValid(cached) then return cached end
    cached = P.staticObject(path)
    if cached ~= nil then staticObjects[path] = cached end
    return cached
end

local function construct(tree, classPath)
    local classObject = staticObject(classPath)
    if classObject == nil or type(StaticConstructObject) ~= "function" then
        return nil
    end
    local ok, object = pcall(StaticConstructObject, classObject, tree)
    return ok and P.isValid(object) and object or nil
end

local function setTextStyle(widget, size, color, justification)
    local ok = pcall(function()
        local font = widget.Font
        local requested = tonumber(size) or 16
        font.Size = FONT_SIZE[requested] or math.max(8,
            math.floor((requested * 0.75) + 0.5) + 1)
        widget.Font = font
        widget:SetFont(font)
        widget:SetJustification(justification or TEXT_LEFT)
        widget:SetColorAndOpacity(slateColor(color or COLORS.text))
        widget:SetShadowOffset({ X = 0.0, Y = 0.0 })
        widget:SetShadowColorAndOpacity(COLORS.transparent)
    end)
    return ok
end

local function makeText(tree, value, size, color, justification)
    local widget = construct(tree, "/Script/UMG.TextBlock")
    if widget == nil then return nil end
    local ok = pcall(function()
        widget:SetText(FText(tostring(value or "")))
        setTextStyle(widget, size or 15, color, justification)
    end)
    return ok and widget or nil
end

do
    local function styleEditableNumber(input)
        if not P.isValid(input) then return false end
        return pcall(function()
            input:SetIsEnabled(true)
            local style = input.WidgetStyle
            local textStyle = style.TextStyle
            local font = textStyle.Font
            font.Size = FONT_SIZE[14]
            textStyle.Font = font
            textStyle.ColorAndOpacity = slateColor(COLORS.text)
            style.TextStyle = textStyle
            style.ForegroundColor = slateColor(COLORS.text)
            style.FocusedForegroundColor = slateColor(COLORS.textOnAccent)
            style.ReadOnlyForegroundColor = slateColor(COLORS.text)
            style.BackgroundColor = slateColor(COLORS.white)
            style.BackgroundImageNormal = tintBrush(
                style.BackgroundImageNormal, COLORS.control)
            style.BackgroundImageHovered = tintBrush(
                style.BackgroundImageHovered, COLORS.controlHover)
            style.BackgroundImageFocused = tintBrush(
                style.BackgroundImageFocused, COLORS.accent)
            input.WidgetStyle = style
            input:SetJustification(TEXT_CENTER)
            input:SetForegroundColor(COLORS.text)
        end)
    end
    state.numberEditorOps.styleEditableNumber = styleEditableNumber
end

local function setPadding(slot, left, top, right, bottom)
    if slot == nil then return end
    pcall(function()
        slot:SetPadding({
            Left = left or 0, Top = top or 0,
            Right = right or 0, Bottom = bottom or 0,
        })
    end)
end

local function setFill(slot)
    if slot == nil then return end
    pcall(function() slot:SetSize({ SizeRule = 1, Value = 1.0 }) end)
end

local function setTextWrap(widget, roleOrWidth)
    if not P.isValid(widget) then return false end
    local contentWidth = tonumber(state.contentWidth) or 640.0
    local wrapWidth = tonumber(roleOrWidth)
    if wrapWidth == nil then
        local role = tostring(roleOrWidth or "")
        local rowPadding = 24.0 + 20.0
        if role == "binding" then
            wrapWidth = contentWidth - rowPadding - SIZE.binding
        elseif role == "choice" then
            wrapWidth = contentWidth - rowPadding - SIZE.choice
        elseif role == "number" then
            wrapWidth = contentWidth - rowPadding - SIZE.number
        elseif role == "toggle" then
            wrapWidth = contentWidth - rowPadding - SIZE.checkbox
        elseif role == "section" then
            wrapWidth = contentWidth - 24.0
        else
            wrapWidth = contentWidth - rowPadding
        end
    end
    wrapWidth = math.max(1.0, wrapWidth)
    return pcall(function()
        widget:SetAutoWrapText(false)
        widget.WrapTextAt = wrapWidth
    end)
end

local function align(slot, horizontal, vertical)
    if slot == nil then return end
    pcall(function()
        slot:SetHorizontalAlignment(horizontal or ALIGN_FILL)
        slot:SetVerticalAlignment(vertical or ALIGN_FILL)
    end)
end

local function mixLinearColor(first, second, amount)
    amount = math.max(0.0, math.min(1.0, tonumber(amount) or 0.0))
    return {
        R = first.R + (second.R - first.R) * amount,
        G = first.G + (second.G - first.G) * amount,
        B = first.B + (second.B - first.B) * amount,
        A = first.A + (second.A - first.A) * amount,
    }
end

local function darkenLinearColor(color, amount)
    local t = math.max(0.0, math.min(1.0, tonumber(amount) or 0.0))
    return {
        R = color.R * (1.0 - t),
        G = color.G * (1.0 - t),
        B = color.B * (1.0 - t),
        A = color.A,
    }
end

local function styleSurfaceButton(button, normal, hovered, pressed, disabled,
        foregrounds, contentPadding)
    if not P.isValid(button) then return false end
    return pcall(function()
        local style = button.WidgetStyle
        style.Normal = tintBrush(style.Normal, normal)
        style.Hovered = tintBrush(style.Hovered, hovered or normal)
        style.Pressed = tintBrush(style.Pressed, pressed or hovered or normal)
        style.Disabled = tintBrush(style.Disabled, disabled or normal)
        foregrounds = foregrounds or {}
        style.NormalForeground = slateColor(
            foregrounds.normal or COLORS.text)
        style.HoveredForeground = slateColor(
            foregrounds.hovered or COLORS.text)
        style.PressedForeground = slateColor(
            foregrounds.pressed or COLORS.textOnAccent)
        style.DisabledForeground = slateColor(
            foregrounds.disabled or COLORS.textMuted)
        contentPadding = contentPadding or {
            Left = 0, Top = 0, Right = 0, Bottom = 0,
        }
        style.NormalPadding = contentPadding
        style.PressedPadding = contentPadding
        button.WidgetStyle = style
        button:SetBackgroundColor(COLORS.white)
    end)
end

local function styleToggle(toggle)
    return pcall(function()
        toggle:SetIsEnabled(true)
        local style = toggle.WidgetStyle
        local uncheckedPressed = darkenLinearColor(COLORS.checkboxHover, 0.10)
        local checkedPressed = darkenLinearColor(COLORS.accent, 0.10)
        style.UncheckedImage = tintBrush(style.UncheckedImage, COLORS.border)
        style.UncheckedHoveredImage = tintBrush(
            style.UncheckedHoveredImage, COLORS.checkboxHover)
        style.UncheckedPressedImage = tintBrush(
            style.UncheckedPressedImage, uncheckedPressed)
        style.CheckedImage = tintBrush(style.CheckedImage, COLORS.accent)
        style.CheckedHoveredImage = tintBrush(
            style.CheckedHoveredImage, COLORS.accent)
        style.CheckedPressedImage = tintBrush(
            style.CheckedPressedImage, checkedPressed)
        style.UncheckedForeground = slateColor(COLORS.muted)
        style.CheckedForeground = slateColor(COLORS.text)
        style.CheckedHoveredForeground = slateColor(COLORS.text)
        style.CheckedPressedForeground = slateColor(COLORS.text)
        style.HoveredForeground = slateColor(COLORS.text)
        style.PressedForeground = slateColor(COLORS.text)
        toggle.WidgetStyle = style
    end)
end

local function styleShortcutSelector(selector, focused, selecting)
    return pcall(function()
        selector:SetIsEnabled(true)
        local normal = selecting and COLORS.stateCapture
            or focused and COLORS.controlFocus or COLORS.control
        local hovered = selecting and COLORS.stateCapture
            or focused and mixLinearColor(
                COLORS.controlFocus, COLORS.borderFocus, 0.22)
            or COLORS.controlHover
        local style = selector.WidgetStyle
        style.Normal = tintBrush(style.Normal, normal)
        style.Hovered = tintBrush(style.Hovered, hovered)
        style.Pressed = tintBrush(style.Pressed, COLORS.controlPressed)
        style.Disabled = tintBrush(style.Disabled, COLORS.controlDisabled)
        style.NormalForeground = slateColor(COLORS.transparent)
        style.HoveredForeground = slateColor(COLORS.transparent)
        style.PressedForeground = slateColor(COLORS.transparent)
        style.DisabledForeground = slateColor(COLORS.transparent)
        selector.WidgetStyle = style
        local textStyle = selector.TextStyle
        textStyle.ColorAndOpacity = slateColor(COLORS.transparent)
        selector.TextStyle = textStyle
    end)
end

local function makeTrigger(tree, label, width, warning, indicatorText, height,
        modalOption)
    local box = construct(tree, "/Script/UMG.SizeBox")
    local surface = construct(tree, "/Script/UMG.Button")
    local text = makeText(tree, label, 14,
        warning and COLORS.actionWarning or COLORS.text,
        indicatorText ~= nil and TEXT_LEFT or TEXT_CENTER)
    if box == nil or surface == nil or text == nil then return nil end
    local content
    local indicator
    local indicatorBox
    local contentPadding = modalOption == true
        and { Left = 12, Top = 4, Right = 12, Bottom = 4 }
        or { Left = 0, Top = 0, Right = 0, Bottom = 0 }
    if indicatorText ~= nil then
        content = construct(tree, "/Script/UMG.HorizontalBox")
        indicatorBox = construct(tree, "/Script/UMG.SizeBox")
        indicator = makeText(tree, indicatorText, 11, COLORS.muted, TEXT_CENTER)
        if content == nil or indicatorBox == nil or indicator == nil then
            return nil
        end
    end
    local ok = pcall(function()
        box:SetWidthOverride(width or 170.0)
        box:SetHeightOverride(height or SIZE.control)
        surface.bIsFocusable = modalOption ~= true
        styleSurfaceButton(surface, COLORS.control, COLORS.controlHover,
            COLORS.controlPressed, COLORS.controlDisabled, {
                normal = COLORS.text,
                hovered = COLORS.text,
                pressed = COLORS.text,
            }, contentPadding)
        if content ~= nil then
            local labelSlot = content:AddChild(text)
            setFill(labelSlot)
            setPadding(labelSlot, 12, 0, 8, 0)
            align(labelSlot, ALIGN_LEFT, ALIGN_CENTER)
            indicatorBox:SetWidthOverride(36.0)
            local indicatorSlot = indicatorBox:AddChild(indicator)
            align(indicatorSlot, ALIGN_CENTER, ALIGN_CENTER)
            local indicatorBoxSlot = content:AddChild(indicatorBox)
            align(indicatorBoxSlot, ALIGN_CENTER, ALIGN_CENTER)
            local contentSlot = surface:AddChild(content)
            align(contentSlot, ALIGN_FILL, ALIGN_CENTER)
        else
            local textSlot = surface:AddChild(text)
            align(textSlot, ALIGN_CENTER, ALIGN_CENTER)
        end
        local surfaceSlot = box:AddChild(surface)
        align(surfaceSlot, ALIGN_FILL, ALIGN_FILL)
    end)
    if not ok then return nil end
    local record = {
        box = box, widget = surface, surface = surface, text = text,
        indicator = indicator,
        contentPadding = contentPadding,
        warning = warning == true, directButton = true,
    }
    registerDirectActionButton(surface)
    state.triggerSurfaces[#state.triggerSurfaces + 1] = record
    return record
end

local function styleHeaderButton(button, role, focused, hovered, pressed,
        neutralForeground)
    if not P.isValid(button) then return false end
    local roleColor = role == "about" and COLORS.actionInfo
        or role == "primary" and COLORS.accent
        or role == "thanks" and COLORS.actionWarning
        or role == "supporters" and COLORS.actionInfo
        or role == "reset" and COLORS.actionWarning
        or role == "close" and COLORS.actionDanger
        or COLORS.actionInfo
    local brand = role == "brand"
    local primary = role == "primary"
    local roster = role == "thanks" or role == "supporters"
    local neutral = role == "aboutLink"
    local productLink = role == "productLink"
    local normal, hover, press
    local normalForeground, hoverForeground, pressForeground
    if brand then
        normal = focused and COLORS.controlHover or COLORS.transparent
        hover = normal
        press = COLORS.controlPressed
        normalForeground = COLORS.text
        hoverForeground = COLORS.text
        pressForeground = COLORS.text
    elseif primary then
        normal = focused and mixLinearColor(
            COLORS.accent, COLORS.white, 0.14) or COLORS.accent
        hover = mixLinearColor(COLORS.accent, COLORS.white, 0.10)
        press = darkenLinearColor(COLORS.accent, 0.12)
        normalForeground = COLORS.textOnAccent
        hoverForeground = COLORS.textOnAccent
        pressForeground = COLORS.textOnAccent
    elseif productLink then
        normal = focused and COLORS.controlFocus or COLORS.control
        hover = COLORS.controlHover
        press = COLORS.controlPressed
        normalForeground = COLORS.text
        hoverForeground = COLORS.text
        pressForeground = COLORS.text
    elseif roster then
        local selected = mixLinearColor(COLORS.control, roleColor, 0.36)
        normal = focused and selected or COLORS.control
        hover = mixLinearColor(COLORS.control, roleColor, 0.30)
        press = darkenLinearColor(hover, 0.10)
        normalForeground = COLORS.text
        hoverForeground = COLORS.text
        pressForeground = COLORS.text
    elseif neutral then
        normal = focused and COLORS.controlFocus or COLORS.control
        hover = COLORS.controlHover
        press = COLORS.controlPressed
        normalForeground = COLORS.text
        hoverForeground = COLORS.text
        pressForeground = COLORS.text
    else
        normal = focused and mixLinearColor(
            COLORS.control, COLORS.borderFocus, 0.24) or COLORS.control
        hover = mixLinearColor(COLORS.control, roleColor,
            role == "steamVote" and 0.28 or 0.30)
        press = role == "steamVote" and COLORS.controlPressed
            or mixLinearColor(COLORS.controlPressed, roleColor, 0.34)
        normalForeground = COLORS.text
        hoverForeground = (role == "steamVote" or neutralForeground == true)
            and COLORS.text or roleColor
        pressForeground = (role == "steamVote" or neutralForeground == true)
            and COLORS.text or roleColor
    end
    local display = pressed and press or hovered and hover or normal
    local displayForeground = pressed and pressForeground
        or hovered and hoverForeground or normalForeground
    return pcall(function()
        local style = button.WidgetStyle
        style.Normal = tintBrush(style.Normal, display)
        style.Hovered = tintBrush(style.Hovered, hover)
        style.Pressed = tintBrush(style.Pressed, press)
        style.Disabled = tintBrush(style.Disabled, COLORS.controlDisabled)
        style.NormalForeground = slateColor(displayForeground)
        style.HoveredForeground = slateColor(hoverForeground)
        style.PressedForeground = slateColor(pressForeground)
        style.DisabledForeground = slateColor(COLORS.textMuted)
        button.WidgetStyle = style
        button:SetBackgroundColor(COLORS.white)
    end)
end

local function makeIconTrigger(tree, glyph, tooltip, role, neutralForeground)
    local box = construct(tree, "/Script/UMG.SizeBox")
    local button = construct(tree, "/Script/UMG.Button")
    local iconBox = construct(tree, "/Script/UMG.SizeBox")
    local size = role == "close" and 27 or role == "reset" and 17 or 18
    local translation = role == "close" and { X = 1.0, Y = -6.0 }
        or role == "reset" and { X = 1.0, Y = 1.0 }
        or { X = 0.0, Y = -1.0 }
    local icon = makeText(tree, glyph, size, COLORS.text, TEXT_CENTER)
    if box == nil or button == nil or iconBox == nil or icon == nil then
        return nil
    end
    local ok = pcall(function()
        box:SetWidthOverride(SIZE.headerAction)
        box:SetHeightOverride(SIZE.headerAction)
        button.bIsFocusable = true
        button:SetToolTipText(FText(tooltip or ""))
        local style = button.WidgetStyle
        style.NormalPadding = { Left = 0, Top = 0, Right = 0, Bottom = 0 }
        style.PressedPadding = { Left = 0, Top = 0, Right = 0, Bottom = 0 }
        button.WidgetStyle = style
        icon:SetColorAndOpacity({
            SpecifiedColor = COLORS.text,
            ColorUseRule = 2,
        })
        iconBox:SetWidthOverride(SIZE.headerActionIconBox)
        iconBox:SetHeightOverride(SIZE.headerActionIconBox)
        icon:SetRenderTranslation(translation)
        align(iconBox:AddChild(icon), ALIGN_CENTER, ALIGN_CENTER)
        align(button:AddChild(iconBox), ALIGN_CENTER, ALIGN_CENTER)
        styleHeaderButton(button, role, false, false, false)
        align(box:AddChild(button), ALIGN_FILL, ALIGN_FILL)
    end)
    if not ok then return nil end
    local record = {
        box = box, widget = button, surface = button, text = icon,
        visualButton = button, directButton = true,
        role = role, tooltip = tooltip or "",
        neutralForeground = neutralForeground == true,
    }
    registerDirectActionButton(button)
    state.headerActionVisuals[#state.headerActionVisuals + 1] = record
    return record
end

local function makeHeaderActionCell(tree, buttonBox)
    if not P.isValid(buttonBox) then return nil end
    local cell = construct(tree, "/Script/UMG.SizeBox")
    if cell == nil then return nil end
    local ok = pcall(function()
        cell:SetWidthOverride(SIZE.headerAction)
        cell:SetHeightOverride(SIZE.headerAction)
        align(cell:AddChild(buttonBox), ALIGN_CENTER, ALIGN_CENTER)
    end)
    return ok and cell or nil
end

local function addHeaderActionGap(tree, parent)
    if not P.isValid(parent) then return false end
    local gap = construct(tree, "/Script/UMG.SizeBox")
    if gap == nil then return false end
    return pcall(function()
        gap:SetWidthOverride(SIZE.headerActionGap)
        parent:AddChild(gap)
    end)
end

local function steamVoteTexture(fileName)
    local cached = state.steamVoteTextures[fileName]
    if P.isValid(cached) then return cached end
    local path = SteamVote.assetPath(fileName)
    local rendering = staticObject("/Script/Engine.Default__KismetRenderingLibrary")
    local controller = P.currentController()
    local world
    if P.isValid(controller) then pcall(function() world = controller:GetWorld() end) end
    if type(path) ~= "string" or rendering == nil or not P.isValid(world) then
        return nil
    end
    local texture
    pcall(function() texture = rendering:ImportFileAsTexture2D(world, path) end)
    if P.isValid(texture) then state.steamVoteTextures[fileName] = texture end
    return P.isValid(texture) and texture or nil
end

local function steamVotePalTexture()
    if P.isValid(state.steamVotePalTexture) then return state.steamVotePalTexture end
    if type(LoadAsset) ~= "function" then return nil end
    local asset = "T_WeaselDragon_icon_normal"
    local path = "/Game/Pal/Texture/PalIcon/Normal/" .. asset .. "." .. asset
    local texture
    pcall(function() texture = LoadAsset(path) end)
    if P.isValid(texture) then state.steamVotePalTexture = texture end
    return P.isValid(texture) and texture or nil
end

local function makeSteamVoteContent(tree, thumbAsset, includePal)
    local row = construct(tree, "/Script/UMG.HorizontalBox")
    if row == nil then return nil end
    if includePal == true then
        local avatarBox = construct(tree, "/Script/UMG.SizeBox")
        local avatar = construct(tree, "/Script/UMG.Image")
        local texture = steamVotePalTexture()
        if avatarBox ~= nil and avatar ~= nil then
            avatarBox:SetWidthOverride(26.0)
            avatarBox:SetHeightOverride(26.0)
            avatar:SetRenderTransformPivot({ X = 0.5, Y = 0.5 })
            avatar:SetRenderScale({ X = -1.0, Y = 1.0 })
            avatar:SetRenderTranslation({ X = 0.0, Y = -1.0 })
            if P.isValid(texture) then
                avatar:SetBrushFromTexture(texture, false)
            else
                avatarBox:SetVisibility(VIS_COLLAPSED)
            end
            align(avatarBox:AddChild(avatar), ALIGN_FILL, ALIGN_FILL)
            local avatarSlot = row:AddChild(avatarBox)
            setPadding(avatarSlot, 0, 0, 4, 0)
            align(avatarSlot, ALIGN_CENTER, ALIGN_CENTER)
            state.steamVotePalVisuals[#state.steamVotePalVisuals + 1] = {
                box = avatarBox, image = avatar,
            }
        end
    end
    local thumbBox = construct(tree, "/Script/UMG.SizeBox")
    local thumb = construct(tree, "/Script/UMG.Image")
    local thumbTexture = steamVoteTexture(thumbAsset)
    if thumbBox == nil or thumb == nil or not P.isValid(thumbTexture) then return nil end
    thumbBox:SetWidthOverride(22.0)
    thumbBox:SetHeightOverride(22.0)
    thumb:SetBrushFromTexture(thumbTexture, false)
    align(thumbBox:AddChild(thumb), ALIGN_FILL, ALIGN_FILL)
    align(row:AddChild(thumbBox), ALIGN_CENTER, ALIGN_CENTER)
    return row
end

local function refreshSteamVotePalVisuals()
    if state.steamVotePalVisualReady == true then return true end
    -- os.clock() measures process CPU time, so a one-second retry could remain
    -- blocked for minutes during normal gameplay. Use wall time for asset retry.
    local now = os.time()
    if now < (tonumber(state.steamVotePalRetryAt) or 0) then return false end
    state.steamVotePalRetryAt = now + 1.0
    local texture = steamVotePalTexture()
    if not P.isValid(texture) then return false end
    local ready = false
    for _, record in ipairs(state.steamVotePalVisuals or {}) do
        if P.isValid(record.box) and P.isValid(record.image) then
            pcall(function()
                record.image:SetBrushFromTexture(texture, false)
                record.image:SetRenderTransformPivot({ X = 0.5, Y = 0.5 })
                record.box:SetVisibility(VIS_VISIBLE)
            end)
            ready = true
        end
    end
    state.steamVotePalVisualReady = ready
    return ready
end

local function makeSteamVoteAction(tree, content, tooltip)
    local button = construct(tree, "/Script/UMG.Button")
    if button == nil or content == nil then
        return nil
    end
    local ok = pcall(function()
        button.bIsFocusable = true
        button:SetToolTipText(FText(tooltip or ""))
        local style = button.WidgetStyle
        local padding = { Left = 4, Top = 3, Right = 4, Bottom = 3 }
        style.NormalPadding = padding
        style.PressedPadding = padding
        button.WidgetStyle = style
        styleHeaderButton(button, "steamVote", false, false, false)
        align(button:AddChild(content), ALIGN_CENTER, ALIGN_CENTER)
    end)
    if not ok then return nil end
    local record = {
        widget = button, surface = button, visualButton = button,
        directButton = true, role = "steamVote", tooltip = tooltip or "",
    }
    registerDirectActionButton(button)
    state.steamVoteActionVisuals[#state.steamVoteActionVisuals + 1] = record
    return record
end

local function setSteamVoteLocked(locked)
    pcall(function()
        if P.isValid(state.steamVoteNoneWidget) then
            state.steamVoteNoneWidget:SetIsEnabled(locked ~= true)
        end
    end)
end

local function applySteamVoteVisual(status, force)
    local control = state.steamVoteControl
    if type(control) ~= "table" then return false end
    local statuses = SteamVote.statuses
    setSteamVoteLocked(state.steamVotePendingUp == true
        or status == statuses.settingUp)
    if status == statuses.querying or status == statuses.settingUp then
        status = state.steamVoteDisplayStatus or statuses.noVote
    elseif status ~= statuses.up and status ~= statuses.down then
        status = statuses.noVote
    end
    if not force and state.steamVoteDisplayStatus == status then return false end
    state.steamVoteDisplayStatus = status
    pcall(function()
        if P.isValid(state.steamVoteBox) then
            state.steamVoteBox:SetVisibility(
                status == statuses.down and VIS_COLLAPSED or VIS_VISIBLE)
        end
        state.steamVoteNoneSurface:SetVisibility(
            status == statuses.noVote and VIS_VISIBLE or VIS_COLLAPSED)
        state.steamVoteUpSurface:SetVisibility(
            status == statuses.up and VIS_VISIBLE or VIS_COLLAPSED)
        if P.isValid(state.steamVoteNoneWidget) then
            local strings = currentStrings()
            state.steamVoteNoneWidget:SetToolTipText(FText(strings.voteLike))
        end
    end)
    control.widget = status == statuses.noVote and state.steamVoteNoneWidget
        or state.steamVoteUpSurface
    control.hiddenFromFocus = status == statuses.down
    control.passive = status == statuses.up
    local strings = currentStrings()
    control.tooltip = status == statuses.up and strings.voteThanks
        or status == statuses.noVote and strings.voteLike or ""
    if state.open == true and type(state.rebuildSettingsFocusEntries) == "function" then
        state.rebuildSettingsFocusEntries()
    end
    return true
end

local function pollSteamVote()
    if not SteamVote.polling() then return false end
    local status = SteamVote.poll()
    local statuses = SteamVote.statuses
    if state.steamVotePendingUp == true
        and (status == statuses.noVote or status == statuses.down) then
        state.steamVotePendingUp = false
        if SteamVote.setUp() then status = SteamVote.status() or statuses.settingUp end
    elseif status == statuses.up then
        state.steamVotePendingUp = false
    end
    local applied = applySteamVoteVisual(status, false)
    if not SteamVote.polling() and type(state.activeChoice) == "table"
        and state.activeChoice.kind == "steamVoteChecking" then
        closeChoiceModal(false)
        if SteamVote.resolvedStatus() == statuses.down then
            Deferred.openDownvoteAcknowledgement()
        end
    end
    return applied
end

local function activateSteamVote()
    local status = SteamVote.status()
    local statuses = SteamVote.statuses
    if status == statuses.up then return true end
    if state.steamVotePendingUp == true then return true end
    if status == statuses.querying then
        state.steamVotePendingUp = true
        setSteamVoteLocked(true)
        return true
    end
    if status == statuses.settingUp then
        setSteamVoteLocked(true)
        return true
    end
    if SteamVote.setUp() then
        applySteamVoteVisual(SteamVote.status() or statuses.settingUp, false)
        return true
    end
    return false
end

local function makeSteamVoteControl(tree, strings)
    if not SteamVote.present() then return nil end
    local box = construct(tree, "/Script/UMG.SizeBox")
    local overlay = construct(tree, "/Script/UMG.Overlay")
    local none = makeSteamVoteAction(tree,
        makeSteamVoteContent(tree, "thumb-up-outline.png", false), strings.voteLike)
    local upSurface = construct(tree, "/Script/UMG.Border")
    local upContent = makeSteamVoteContent(tree, "thumb-up-filled.png", true)
    if box == nil or overlay == nil or none == nil
        or upSurface == nil or upContent == nil then return nil end
    upSurface:SetBrushColor(COLORS.control)
    upSurface:SetPadding({ Left = 4, Top = 3, Right = 4, Bottom = 3 })
    upSurface:SetToolTipText(FText(strings.voteThanks or ""))
    align(upSurface:AddChild(upContent), ALIGN_CENTER, ALIGN_CENTER)
    align(overlay:AddChildToOverlay(none.surface), ALIGN_FILL, ALIGN_FILL)
    align(overlay:AddChildToOverlay(upSurface), ALIGN_FILL, ALIGN_FILL)
    box:SetWidthOverride(64.0)
    box:SetHeightOverride(SIZE.button)
    align(box:AddChild(overlay), ALIGN_FILL, ALIGN_FILL)
    state.steamVoteBox = box
    state.steamVoteNoneWidget = none.widget
    state.steamVoteNoneSurface = none.surface
    state.steamVoteUpSurface = upSurface
    state.steamVoteControl = { kind = "steamVote", widget = none.widget,
        tooltip = strings.voteLike or "" }
    none.control = state.steamVoteControl
    applySteamVoteVisual(SteamVote.status(), true)
    return box
end

local function makeRow(tree, body, label, role, indent)
    local rowBox = construct(tree, "/Script/UMG.SizeBox")
    local rowSurface = construct(tree, "/Script/UMG.Button")
    local frame = construct(tree, "/Script/UMG.Border")
    local row = construct(tree, "/Script/UMG.HorizontalBox")
    local labelWidget = makeText(tree, label, 15, COLORS.text, TEXT_LEFT)
    if rowBox == nil or rowSurface == nil or frame == nil
        or row == nil or labelWidget == nil then return nil end
    setTextWrap(labelWidget, role)
    local ok = pcall(function()
        rowBox:SetMinDesiredHeight(SIZE.row)
        rowSurface.bIsFocusable = false
        styleSurfaceButton(rowSurface, COLORS.transparent, COLORS.rowHover,
            COLORS.rowHover, COLORS.transparent, {
                normal = COLORS.text,
                hovered = COLORS.text,
                pressed = COLORS.text,
            })
        frame:SetBrushColor(COLORS.transparent)
        frame:SetPadding({
            Left = 12 + (tonumber(indent) or 0),
            Top = 4, Right = 12, Bottom = 4,
        })
        local labelSlot = row:AddChild(labelWidget)
        setFill(labelSlot)
        align(labelSlot, ALIGN_LEFT, ALIGN_CENTER)
        local rowSlot = frame:AddChild(row)
        align(rowSlot, ALIGN_FILL, ALIGN_FILL)
        local frameSlot = rowSurface:AddChild(frame)
        align(frameSlot, ALIGN_FILL, ALIGN_FILL)
        local surfaceSlot = rowBox:AddChild(rowSurface)
        align(surfaceSlot, ALIGN_FILL, ALIGN_FILL)
        local bodySlot = body:AddChild(rowBox)
        align(bodySlot, ALIGN_FILL, ALIGN_FILL)
    end)
    return ok and {
        box = rowBox, surface = rowSurface, frame = frame,
        row = row, label = labelWidget,
    } or nil
end

local function addSection(tree, body, title, topGap)
    local section = construct(tree, "/Script/UMG.Border")
    local titleWidget = makeText(tree, title, 15, COLORS.accent, TEXT_LEFT)
    if section == nil or titleWidget == nil then return false end
    setTextWrap(titleWidget, "section")
    local ok = pcall(function()
        section:SetBrushColor(COLORS.section)
        section:SetPadding({ Left = 12, Top = 4, Right = 12, Bottom = 4 })
        local titleSlot = section:AddChild(titleWidget)
        align(titleSlot, ALIGN_LEFT, ALIGN_CENTER)
        local slot = body:AddChild(section)
        align(slot, ALIGN_FILL, ALIGN_FILL)
        setPadding(slot, 0, topGap or 0, 0, 4)
    end)
    return ok
end

state.makeSettingsTabArrow = function(tree, glyph)
    local box = construct(tree, "/Script/UMG.SizeBox")
    local button = construct(tree, "/Script/UMG.Button")
    local label = makeText(tree, glyph, 20, COLORS.muted, TEXT_CENTER)
    if box == nil or button == nil or label == nil then return nil, nil end
    local ok = pcall(function()
        box:SetWidthOverride(36.0)
        box:SetHeightOverride(SIZE.settingsTabs - 6.0)
        button.bIsFocusable = false
        label:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        styleSurfaceButton(button, COLORS.transparent, COLORS.controlHover,
            COLORS.controlPressed, COLORS.controlDisabled, {
                normal = COLORS.muted,
                hovered = COLORS.text,
                pressed = COLORS.textOnAccent,
            })
        align(button:AddChild(label), ALIGN_FILL, ALIGN_CENTER)
        align(box:AddChild(button), ALIGN_FILL, ALIGN_FILL)
    end)
    if not ok then return nil, nil end
    registerDirectActionButton(button)
    return box, button
end

state.refreshSettingsTabs = function()
    for _, record in ipairs(state.settingsTabButtons or {}) do
        if P.isValid(record.widget) then
            local selected = record.pageId == state.activeSettingsPage
            local hovered = false
            local pressed = false
            pcall(function() hovered = record.widget:IsHovered() == true end)
            pcall(function() pressed = record.widget:IsPressed() == true end)
            local signature = tostring(selected) .. ":" .. tostring(hovered)
                .. ":" .. tostring(pressed)
            if signature ~= record.visualSignature then
                record.visualSignature = signature
                local normal = selected and COLORS.surfaceSelected
                    or COLORS.transparent
                local hover = selected and COLORS.surfaceSelected
                    or COLORS.controlHover
                styleSurfaceButton(record.widget, normal, hover,
                    COLORS.controlPressed, COLORS.controlDisabled, {
                        normal = selected and COLORS.text or COLORS.muted,
                        hovered = COLORS.text,
                        pressed = COLORS.textOnAccent,
                    })
                if P.isValid(record.text) then
                    record.text:SetColorAndOpacity(slateColor(
                        selected and COLORS.text or COLORS.muted))
                end
            end
        end
    end
end

local function refreshTriggerSurfaces()
    for _, record in ipairs(state.triggerSurfaces or {}) do
        if P.isValid(record.widget) and P.isValid(record.surface) then
            local focused = false
            local hovered = false
            pcall(function() hovered = record.widget:IsHovered() == true end)
            -- Match Pal Insight: the virtual selection survives device changes;
            -- mouse hover is only a transient visual on another control.
            if type(record.control) == "table"
                and record.control.focusIndex == state.focusIndex then
                focused = true
            end
            local capture = record.selected == true
                and type(record.control) == "table"
                and record.control.kind == "number"
            local selected = record.selected == true and not capture
            local warning = record.warning == true
            local signature = capture and "capture"
                or focused and "focus"
                or selected and "selected"
                or hovered and "hover" or "normal"
            if signature ~= record.visualSignature then
                record.visualSignature = signature
                local normal = capture and COLORS.stateCapture
                    or (focused or selected) and (warning
                        and COLORS.actionWarning or COLORS.controlFocus)
                    or warning and mixLinearColor(
                        COLORS.control, COLORS.actionWarning, 0.12)
                    or COLORS.control
                local hover = capture and COLORS.stateCapture
                    or warning and COLORS.actionWarning
                    or (focused or selected) and mixLinearColor(
                        COLORS.controlFocus, COLORS.borderFocus, 0.22)
                    or COLORS.controlHover
                local foreground = capture and COLORS.textOnAccent
                    or warning and (focused or selected or hovered)
                        and COLORS.textOnAccent
                    or warning and COLORS.actionWarning
                    or COLORS.text
                styleSurfaceButton(record.surface, normal, hover,
                    COLORS.controlPressed, COLORS.controlDisabled, {
                        normal = foreground,
                        hovered = foreground,
                        pressed = COLORS.textOnAccent,
                    }, record.contentPadding)
                pcall(function()
                    record.text:SetColorAndOpacity(slateColor(foreground))
                    if P.isValid(record.indicator) then
                        record.indicator:SetColorAndOpacity(slateColor(
                            (focused or selected) and COLORS.borderFocus
                                or COLORS.muted))
                    end
                end)
            end
        end
    end
    for _, records in ipairs({
            state.headerActionVisuals or {},
            state.steamVoteActionVisuals or {},
        }) do
        for _, record in ipairs(records) do
            if P.isValid(record.widget) and P.isValid(record.visualButton) then
                local active = true
                if record.role == "steamVote" and type(record.control) == "table" then
                    active = P.objectAddress(record.control.widget)
                        == P.objectAddress(record.widget)
                end
                local focused = active and type(record.control) == "table"
                    and record.control.focusIndex == state.focusIndex
                    and state.lastInputDevice ~= "mouse"
                if active and ((record == (state.aboutRosterCloseActions or {})[
                            state.aboutRosterMode]
                        and state.aboutRosterOpen == true)
                    or (record == state.aboutPreviewCloseAction
                        and state.aboutPreviewOpen == true))
                    and state.lastInputDevice ~= "mouse" then focused = true end
                local hovered = false
                local pressed = false
                if active then
                    pcall(function() hovered = record.widget:IsHovered() == true end)
                    pcall(function() pressed = record.widget:IsPressed() == true end)
                end
                local signature = pressed and "pressed"
                    or focused and "focus" or hovered and "hover" or "normal"
                if signature ~= record.visualSignature then
                    record.visualSignature = signature
                    styleHeaderButton(record.visualButton, record.role,
                        focused, hovered, pressed, record.neutralForeground)
                end
            end
        end
    end
    for index, record in ipairs(state.aboutActions or {}) do
        if P.isValid(record.widget) and P.isValid(record.visualButton) then
            local focused = state.aboutOpen == true
                and state.aboutRosterOpen ~= true
                and state.aboutPreviewOpen ~= true
                and index == state.aboutFocusIndex
                and state.lastInputDevice ~= "mouse"
            local hovered = false
            local pressed = false
            if state.aboutOpen == true and state.aboutRosterOpen ~= true
                and state.aboutPreviewOpen ~= true then
                pcall(function() hovered = record.widget:IsHovered() == true end)
                pcall(function() pressed = record.widget:IsPressed() == true end)
            end
            local signature = pressed and "pressed"
                or focused and "focus" or hovered and "hover" or "normal"
            if signature ~= record.visualSignature then
                record.visualSignature = signature
                styleHeaderButton(record.visualButton,
                    record.role or "about", focused, hovered, pressed)
            end
        end
    end
    state.refreshSettingsTabs()
    if P.isValid(state.aboutActionHint) then
        local hint = ""
        if state.aboutOpen == true and state.aboutRosterOpen ~= true
            and state.aboutPreviewOpen ~= true
            and state.lastInputDevice ~= "mouse" then
            local action = (state.aboutActions or {})[
                tonumber(state.aboutFocusIndex) or 1]
            if type(action) == "table" then
                hint = tostring(action.tooltip or action.label or "")
            end
        end
        pcall(function() state.aboutActionHint:SetText(FText(hint)) end)
    end
    if P.isValid(state.headerActionHint) then
        local hint = ""
        if state.lastInputDevice ~= "mouse" then
            for _, control in ipairs(state.controls or {}) do
                if control.kind == "steamVote" or control.kind == "releaseNotes"
                    or control.kind == "about"
                    or control.kind == "reset" or control.kind == "close" then
                    if control.focusIndex == state.focusIndex then
                        hint = tostring(control.tooltip or "")
                        break
                    end
                end
            end
        end
        pcall(function() state.headerActionHint:SetText(FText(hint)) end)
    end
end

local function addControlToRow(row, widget, gap)
    local slot = row:AddChild(widget)
    setPadding(slot, gap or 8, 0, 0, 0)
    align(slot, ALIGN_RIGHT, ALIGN_CENTER)
    return slot
end

local function selectedChord(selector)
    if not P.isValid(selector) then return nil end
    local chord
    local ok = pcall(function() chord = selector.SelectedKey end)
    if not ok or chord == nil then return nil end
    local keyName
    ok = pcall(function()
        local key = chord.Key
        local raw = key ~= nil and key.KeyName or nil
        keyName = P.nameString(raw)
    end)
    if not ok or type(keyName) ~= "string" or keyName == ""
        or keyName == "None" or keyName == "Empty" then return nil end
    return {
        Key = keyName,
        Shift = chord.bShift == true,
        Ctrl = chord.bCtrl == true,
        Alt = chord.bAlt == true,
    }
end

local function setSelectorChord(selector, chord)
    if not P.isValid(selector) or type(chord) ~= "table"
        or type(FName) ~= "function" then return false end
    state.selectorChordProgrammatic = true
    local ok = pcall(function()
        selector:SetSelectedKey({
            Key = { KeyName = FName(chord.Key) },
            bShift = chord.Shift == true,
            bCtrl = chord.Ctrl == true,
            bAlt = chord.Alt == true,
            bCmd = false,
        })
    end)
    state.selectorChordProgrammatic = false
    return ok
end

local function chordSignature(chord)
    if type(chord) ~= "table" then return "" end
    return table.concat({
        tostring(chord.Key or ""), chord.Ctrl and "C" or "-",
        chord.Shift and "S" or "-", chord.Alt and "A" or "-",
    }, ":")
end

local function chordLabel(chord)
    if type(chord) ~= "table" then return "" end
    local parts = {}
    if chord.Ctrl == true then parts[#parts + 1] = "Ctrl" end
    if chord.Shift == true then parts[#parts + 1] = "Shift" end
    if chord.Alt == true then parts[#parts + 1] = "Alt" end
    parts[#parts + 1] = tostring(chord.Key or "")
    return table.concat(parts, " + ")
end

local function refreshShortcutDisplay(control, selecting)
    if type(control) ~= "table" then return end
    if P.isValid(control.text) then
        local label = selecting == true and "…" or chordLabel({
            Key = state.config.Key,
            Shift = state.config.Shift,
            Ctrl = state.config.Ctrl,
            Alt = state.config.Alt,
        })
        if label ~= control.displayLabel then
            control.displayLabel = label
            pcall(function() control.text:SetText(FText(label)) end)
        end
    end
    local focused = selecting == true
    local hovered = false
    if P.isValid(control.widget) then
        pcall(function() hovered = control.widget:IsHovered() == true end)
    end
    if control.focusIndex == state.focusIndex then focused = true end
    local signature = focused and "focus" or hovered and "hover" or "normal"
    if selecting == true then signature = "capture" end
    if P.isValid(control.widget) and signature ~= control.visualSignature then
        control.visualSignature = signature
        styleShortcutSelector(control.widget, focused, selecting == true)
        if P.isValid(control.text) then
            pcall(function()
                control.text:SetColorAndOpacity(slateColor(
                    selecting == true and COLORS.textOnAccent or COLORS.text))
            end)
        end
    end
end

local function refreshToggleDisplay(control)
    if type(control) ~= "table" or not P.isValid(control.widget) then return end
    local focused = false
    if control.focusIndex == state.focusIndex then focused = true end
    local signature = focused and "focus" or "normal"
    if signature == control.visualSignature then return end
    control.visualSignature = signature
    styleToggle(control.widget)
    if focused then
        pcall(function()
            local style = control.widget.WidgetStyle
            style.UncheckedImage = tintBrush(
                style.UncheckedImage, COLORS.borderFocus)
            control.widget.WidgetStyle = style
        end)
    end
end

local function refreshRowDisplay(control)
    if type(control) ~= "table" or not P.isValid(control.rowFrame) then return end
    local focused = false
    if control.passive == true then
        focused = false
    elseif control.focusIndex == state.focusIndex then
        focused = true
    end
    local signature = focused and "focus" or "normal"
    if signature == control.rowVisualSignature then return end
    control.rowVisualSignature = signature
    styleSurfaceButton(control.rowFrame,
        focused and COLORS.rowFocus or COLORS.transparent,
        focused and COLORS.rowFocus or COLORS.rowHover,
        COLORS.rowHover, COLORS.transparent, {
            normal = COLORS.text,
            hovered = COLORS.text,
            pressed = COLORS.text,
        })
end

local function setNumberEditorText(control, value)
    if type(control) ~= "table" or control.kind ~= "number" then return false end
    local textValue = tostring(value)
    local updated = false
    if P.isValid(control.input) then
        updated = pcall(function()
            control.input:SetText(FText(textValue))
        end) or updated
    end
    if P.isValid(control.displayText) then
        updated = pcall(function()
            control.displayText:SetText(FText(textValue))
        end) or updated
    end
    control.displayedText = textValue
    return updated == true
end

local function syncNumberPresentation(control, editingOverride)
    if type(control) ~= "table" or control.kind ~= "number"
        or not P.isValid(control.input)
        or not P.isValid(control.displayButton) then return false end
    local edit = state.numberEdit
    local editing = editingOverride
    if type(editing) ~= "boolean" then
        editing = type(edit) == "table" and edit.control == control
            and (edit.mode == "keyboard" or edit.mode == "mouse")
    end
    local synchronized = pcall(function()
        if editing then
            control.displayButton:SetVisibility(VIS_COLLAPSED)
            control.input:SetVisibility(VIS_VISIBLE)
            control.input:SetForegroundColor(COLORS.textOnAccent)
        else
            control.input:SetVisibility(VIS_COLLAPSED)
            control.displayButton:SetVisibility(VIS_VISIBLE)
        end
    end)
    control.editingVisual = editing == true
    if type(control.trigger) == "table" then
        control.trigger.selected = type(edit) == "table" and edit.control == control
    end
    return synchronized == true
end

local function copyConfig(source)
    local out = {}
    for _, key in ipairs(SETTING_KEYS) do out[key] = source[key] end
    return out
end

local function validateCandidate(candidate)
    local shortcut, shortcutError = Settings.validateShortcut(candidate)
    if shortcut == nil then return nil, shortcutError end
    local resultDisplay, resultError = Settings.validateResultDisplay(
        candidate.ResultDisplay)
    if resultDisplay == nil then return nil, resultError end
    local eggRouting, eggError = Settings.validatePalEggRouting(
        candidate.PalEggRouting)
    if eggRouting == nil then return nil, eggError end
    local relicRouting, relicError = Settings.validateRelicRouting(
        candidate.RelicRouting)
    if relicRouting == nil then return nil, relicError end
    local holyWater, holyWaterError = Settings.validateWorldTreeHolyWaterMinimum(
        candidate.WorldTreeHolyWaterMinimum)
    if holyWater == nil then return nil, holyWaterError end
    local ammoSellItems, ammoSellItemsError = Settings.validateAmmoSellItems(
        candidate.AmmoSellItems)
    if ammoSellItems == nil then return nil, ammoSellItemsError end
    local palSphereSellItems, palSphereSellItemsError =
        Settings.validatePalSphereSellItems(candidate.PalSphereSellItems)
    if palSphereSellItems == nil then return nil, palSphereSellItemsError end
    local fishingBaitSellItems, fishingBaitSellItemsError =
        Settings.validateFishingBaitSellItems(candidate.FishingBaitSellItems)
    if fishingBaitSellItems == nil then return nil, fishingBaitSellItemsError end
    local valuableSellItems, valuableSellItemsError =
        Settings.validateValuableSellItems(candidate.ValuableSellItems)
    if valuableSellItems == nil then return nil, valuableSellItemsError end
    if type(candidate.IncludeExcludedItems) ~= "boolean"
        or type(candidate.IncludeNewItems) ~= "boolean"
        or type(candidate.IncludeGuildChest) ~= "boolean"
        or type(candidate.AutoSellValuables) ~= "boolean"
        or type(candidate.AutoSellAmmo) ~= "boolean"
        or type(candidate.AutoSellPalSpheres) ~= "boolean"
        or type(candidate.AutoSellFishingBait) ~= "boolean"
        or type(candidate.KeepSaleItemsWhenNoMerchant) ~= "boolean"
        or type(candidate.BreedingFarmCakeFirst) ~= "boolean"
        or type(candidate.FoodBoxFirst) ~= "boolean"
        or type(candidate.MedicineRackFirst) ~= "boolean"
        or type(candidate.IncludeSmallIncubators) ~= "boolean" then
        return nil, "Quick Stack toggle values must be boolean"
    end
    local normalized = copyConfig(state.config)
    normalized.Key = shortcut.Key
    normalized.Shift = shortcut.Shift
    normalized.Ctrl = shortcut.Ctrl
    normalized.Alt = shortcut.Alt
    normalized.ResultDisplay = resultDisplay
    normalized.IncludeExcludedItems = candidate.IncludeExcludedItems
    normalized.IncludeNewItems = candidate.IncludeNewItems
    normalized.IncludeGuildChest = candidate.IncludeGuildChest
    normalized.AutoSellValuables = candidate.AutoSellValuables
    normalized.ValuableSellItems = valuableSellItems
    normalized.AutoSellAmmo = candidate.AutoSellAmmo
    normalized.AmmoSellItems = ammoSellItems
    normalized.AutoSellPalSpheres = candidate.AutoSellPalSpheres
    normalized.PalSphereSellItems = palSphereSellItems
    normalized.AutoSellFishingBait = candidate.AutoSellFishingBait
    normalized.FishingBaitSellItems = fishingBaitSellItems
    normalized.KeepSaleItemsWhenNoMerchant =
        candidate.KeepSaleItemsWhenNoMerchant
    normalized.BreedingFarmCakeFirst = candidate.BreedingFarmCakeFirst
    normalized.FoodBoxFirst = candidate.FoodBoxFirst
    normalized.MedicineRackFirst = candidate.MedicineRackFirst
    normalized.IncludeSmallIncubators = candidate.IncludeSmallIncubators
    normalized.PalEggRouting = eggRouting
    normalized.RelicRouting = relicRouting
    normalized.WorldTreeHolyWaterMinimum = holyWater
    return normalized, nil
end

function SettingsUI.apply(candidate, source)
    if type(state.config) ~= "table" then return false, "settings are unavailable" end
    local normalized, validationError = validateCandidate(candidate)
    if normalized == nil then return false, validationError end
    local previous = copyConfig(state.config)
    local shortcutChanged = Settings.chordSignature(normalized)
        ~= Settings.chordSignature(previous)
    for _, key in ipairs(SETTING_KEYS) do state.config[key] = normalized[key] end
    local registered, registerError = true, nil
    if shortcutChanged and type(state.registerShortcut) == "function" then
        registered, registerError = state.registerShortcut(state.config)
    end
    local saved, saveError = false, nil
    if registered then saved, saveError = Settings.save(state.configPath, state.config) end
    if not registered or not saved then
        for _, key in ipairs(SETTING_KEYS) do state.config[key] = previous[key] end
        if shortcutChanged and type(state.registerShortcut) == "function" then
            state.registerShortcut(state.config)
        end
        return false, registerError or saveError or "settings cannot be saved"
    end
    if type(state.onApplied) == "function" then
        state.onApplied(source or "settings-ui")
    end
    return true, nil
end

local function setStatus(message, failed)
    if not P.isValid(state.statusText) then return end
    pcall(function()
        state.statusText:SetText(FText(tostring(message or "")))
        state.statusText:SetColorAndOpacity(slateColor(
            failed and COLORS.danger or COLORS.muted))
    end)
end

currentStrings = function()
    local ok, value = pcall(Localization.settings)
    return ok and type(value) == "table" and value or {
        title = "Quick Stack Settings",
        tabGeneral = "General",
        sectionBasics = "Basics",
        sectionAutoSell = "Automatic sale",
        sectionStorage = "Storage rules",
        sectionSpecial = "Special items",
        shortcut = "Quick Stack shortcut",
        resultDisplay = "Result display",
        resultDefault = "Automatic",
        resultText = "Text only",
        resultWindow = "Result window",
        resultDisplayHelper = "Automatic: show the result window when triggered from the inventory; otherwise show text.",
        includeExcluded = "Store ignored items",
        includeNew = "Store items not already in storage",
        includeGuildChest = "Use Guild Chest",
        autoSellValuables = "Sell high-value merchant items",
        keptValuables = "High-value items to keep",
        valuablePickerTitle = "High-value items to keep",
        valuablePickerHelper = "Checked items stay in your backpack and are not sold.",
        valuableKeptSummary = "Keep %d / %d",
        autoSellAmmo = "Sell selected ammunition",
        keptAmmo = "Ammunition to keep",
        ammoPickerTitle = "Ammunition to keep",
        ammoPickerHelper = "Checked ammunition stays in your backpack and is not sold.",
        ammoPickerDone = "Done",
        ammoKeptSummary = "Keep %d / %d",
        autoSellPalSpheres = "Sell selected Pal Spheres",
        keptPalSpheres = "Pal Spheres to keep",
        palSpherePickerTitle = "Pal Spheres to keep",
        palSpherePickerHelper = "Checked Pal Spheres stay in your backpack and are not sold.",
        palSphereKeptSummary = "Keep %d / %d",
        autoSellFishingBait = "Sell selected fishing bait",
        keptFishingBait = "Fishing bait to keep",
        fishingBaitPickerTitle = "Fishing bait to keep",
        fishingBaitPickerHelper = "Checked fishing bait stays in your backpack and is not sold.",
        fishingBaitKeptSummary = "Keep %d / %d",
        saleBonusNotice = "Automatic selling reads party Pals' Noble and Fine Furs passives and applies them to sale prices.",
        keepSaleItemsWhenNoMerchant = "Keep sale items if no merchant is found",
        keepSaleItemsWhenNoMerchantHelper = "F5 finds an available merchant automatically. Turn this off to send unsold items through normal storage rules when none is found.",
        breedingFarmCakeFirst = "Cakes to Breeding Farms first",
        breedingFarmCakeFirstHelper = "All 5 cakes use cold storage, then regular storage if no usable Breeding Farm has room. Cakes never go to Pal Food Boxes.",
        foodBoxFirst = "Food to Pal Food Boxes first",
        foodBoxFirstHelper = "Other food uses cold storage, then regular storage if no usable Pal Food Box has room. Use Tab → R in the inventory to keep a food type in your backpack.",
        medicineRackFirst = "Medical supplies to Medicine Racks first",
        medicineRackFirstHelper = "If no usable Medicine Rack is available or all are full, medical supplies still go to regular storage.",
        includeSmallIncubators = "Use small incubators (large first)",
        eggRouting = "Pal Egg routing",
        eggOnly = "Incubators only",
        eggStorage = "Incubators, then storage",
        manualPlacement = "Manual placement",
        relicRouting = "Ancient Relic routing",
        relicOnly = "Relic Recyclers only",
        relicStorage = "Relic Recyclers, then storage",
        holyWater = "World Tree Holy Water per Recycler",
        reset = "Restore defaults",
        about = "About",
        creator = "by cratexnet",
        close = "Close",
        saved = "Settings saved",
        saveFailed = "Could not save settings: %s",
        standalone = "Standalone",
        hosted = "Opened from Pal Insight",
        footer = "F6 / Esc closes this panel",
        footerHosted = "Esc / Back returns to Pal Insight · F6 closes all settings",
        inputHelpTitle = "Controls",
        inputDeviceKeyboardMouse = "Keyboard / Mouse",
        inputDeviceGamepad = "Controller",
        shortcutKeyboardMouseOnly = "Use a keyboard or mouse to change this shortcut.",
        navigate = "Navigate",
        switchTabs = "Switch tabs",
        adjust = "Adjust",
        confirm = "Confirm",
        toggleSettings = "Settings",
        externalShortcutConflict = "Possible UE4SS shortcut conflict: %s. Another UE4SS mod may use the same shortcut; both actions may run. Rebind one.",
        voteLike = "Like Quick Stack",
        voteReconsider = "Changed your mind? Click to like",
        voteThanks = "Thank you for your support!",
        downvoteTitle = "Thank you for continuing to use Quick Stack",
        downvoteMessage = "Quick Stack represents a great deal of my spare time and care. If it has not met your expectations, I would sincerely appreciate specific feedback that can help me improve it. Thank you for giving it your time.",
        downvoteConfirm = "Confirm",
        voteChecking = "Checking Steam Workshop status…",
    }
end

local FooterGuide = {
    KEYBOARD_KEY_GUIDE = {
        Up = "Up", Down = "Down", Left = "Left", Right = "Right",
        Enter = "Enter", Escape = "Esc", Esc = "Esc",
        SpaceBar = "Space", Space = "Space", Tab = "Tab",
        LeftControl = "Ctrl", Ctrl = "Ctrl", RightControl = "Ctrl_R",
        LeftShift = "shift", Shift = "shift", RightShift = "Shift_R",
        LeftAlt = "Alt", Alt = "Alt", RightAlt = "Alt_R",
    },
    KEYBOARD_LEADING_PADDING = {
        Enter = 3.0, Esc = 4.0, Space = 5.0, Tab = 5.0,
        Ctrl = 5.0, Ctrl_R = 5.0, shift = 5.0, Shift_R = 5.0,
        Alt = 5.0, Alt_R = 5.0,
    },
    MOUSE_KEY_GUIDE = {
        LeftMouseButton = "T_MenuKeyGuide_MouseButtonLeft",
        RightMouseButton = "T_MenuKeyGuide_MouseButtonRight",
        MiddleMouseButton = "T_MenuKeyGuide_MouseWheelButton",
        ThumbMouseButton = "T_MenuKeyGuide_MouseButton4",
        ThumbMouseButton2 = "T_MenuKeyGuide_MouseButton5",
        MouseScrollUp = "T_MenuKeyGuide_MouseSceollUp",
        MouseScrollDown = "T_MenuKeyGuide_MouseSceollDown",
        MouseWheelAxis = "T_MenuKeyGuide_MouseWheelAxis",
    },
    XINPUT_KEY_GUIDE = {
        Gamepad_DPad_Up = "CrossU", Gamepad_DPad_Down = "CrossD",
        Gamepad_DPad_Left = "CrossL", Gamepad_DPad_Right = "CrossR",
        Gamepad_LeftStick_UD = "StickL_UD",
        Gamepad_LeftStick_LR = "StickL_LR",
        Gamepad_FaceButton_Bottom = "A",
        Gamepad_FaceButton_Right = "B",
        Gamepad_LeftShoulder = "L1", Gamepad_RightShoulder = "R1",
    },
    DUALSENSE_KEY_GUIDE = {
        Gamepad_DPad_Up = "DirectionalU",
        Gamepad_DPad_Down = "DirectionalD",
        Gamepad_DPad_Left = "DirectionalL",
        Gamepad_DPad_Right = "DirectionalR",
        Gamepad_LeftStick_UD = "StickL_UD",
        Gamepad_LeftStick_LR = "StickL_LR",
        Gamepad_FaceButton_Bottom = "Cross",
        Gamepad_FaceButton_Right = "Circle",
        Gamepad_LeftShoulder = "L1", Gamepad_RightShoulder = "R1",
    },
    GAMEPAD_LEADING_PADDING = {
        xinput = { CrossU = 2.0, CrossD = 2.0, CrossL = 5.0,
            CrossR = 5.0 },
        dualsense = {},
    },
}

function FooterGuide.readGamepadFamily(force)
    local current = state.gamepadKeyGuideFamily or "xinput"
    if force ~= true then return current end
    local controller = P.isValid(state.controller)
        and state.controller or P.currentController()
    local subsystemLibrary = staticObject(
        "/Script/Engine.Default__SubsystemBlueprintLibrary")
    local subsystemClass = staticObject(
        "/Script/CommonInput.CommonInputSubsystem")
    if not P.isValid(controller) or subsystemLibrary == nil
        or subsystemClass == nil then return current end
    local subsystem
    pcall(function()
        subsystem = subsystemLibrary:GetLocalPlayerSubsystemFromPlayerController(
            controller, subsystemClass)
    end)
    if not P.isValid(subsystem) then return current end
    local gamepadName
    pcall(function() gamepadName = subsystem:GetCurrentGamepadName() end)
    gamepadName = P.unwrap(gamepadName)
    local normalized = tostring(gamepadName or ""):lower()
    local family = (normalized:find("ps5", 1, true) ~= nil
            or normalized:find("dualsense", 1, true) ~= nil
            or normalized:find("playstation", 1, true) ~= nil)
        and "dualsense" or "xinput"
    state.gamepadKeyGuideFamily = family
    return family
end

function FooterGuide.keyGuideTexturePath(device, value, gamepadFamily)
    value = tostring(value or "")
    local packagePath
    if device == "gamepad" then
        gamepadFamily = gamepadFamily
            or state.gamepadKeyGuideFamily or "xinput"
        local suffix = gamepadFamily == "dualsense"
            and FooterGuide.DUALSENSE_KEY_GUIDE[value]
            or FooterGuide.XINPUT_KEY_GUIDE[value]
        if suffix ~= nil then
            if gamepadFamily == "dualsense" then
                packagePath = "/Game/Pal/Texture/UI/KeyGuide/DualSense/"
                    .. "T_KeyGuide_DualSense_" .. suffix
            else
                packagePath = "/Game/Pal/Texture/UI/KeyGuide/T_KeyGuide_"
                    .. suffix
            end
        end
    else
        local mouseAsset = FooterGuide.MOUSE_KEY_GUIDE[value]
        if mouseAsset ~= nil then
            packagePath = "/Game/Pal/Texture/UI/KeyGuide/mouse/" .. mouseAsset
        else
            local suffix = FooterGuide.KEYBOARD_KEY_GUIDE[value]
            if suffix == nil and (value:match("^[A-Z]$")
                or value:match("^[0-9]$") or value:match("^F%d%d?$")) then
                suffix = value
            end
            if suffix ~= nil then
                packagePath = "/Game/Pal/Texture/UI/KeyGuide/keyboard/"
                    .. "T_KeyGuide_Keyboard_" .. suffix
            end
        end
    end
    if packagePath == nil then return nil end
    local assetName = packagePath:match("([^/]+)$")
    return packagePath .. "." .. tostring(assetName or "")
end

function FooterGuide.footerKeycapWidth(value, nativeTexture, inline)
    if nativeTexture == true or inline ~= true then
        return SIZE.footerKeyGuide
    end
    return math.max(SIZE.inlineShortcutMinWidth,
        math.min(SIZE.inlineShortcutMaxWidth,
            16.0 + (#tostring(value or "") * 7.0)))
end

function FooterGuide.refreshFooterKeycap(record, value, visible, device,
        gamepadFamily)
    if type(record) ~= "table" or not P.isValid(record.badge)
        or not P.isValid(record.nativeSurface) then return false end
    device = device or record.device or "keyboard"
    local texturePath = FooterGuide.keyGuideTexturePath(
        device, value, gamepadFamily)
    local nativeTexture = false
    if texturePath ~= nil then
        local texture = staticObject(texturePath)
        if texture == nil and type(LoadAsset) == "function" then
            pcall(function() texture = LoadAsset(texturePath) end)
            if P.isValid(texture) then staticObjects[texturePath] = texture end
        end
        if P.isValid(texture) then
            nativeTexture = pcall(function()
                record.nativeSurface:SetBrushFromTexture(texture)
            end)
        end
    end
    local requested = visible ~= false
    local fallbackVisible = requested and not nativeTexture
        and record.inline == true and P.isValid(record.fallbackSurface)
        and P.isValid(record.text)
    local width = FooterGuide.footerKeycapWidth(
        value, nativeTexture, record.inline)
    local updated = pcall(function()
        record.nativeSurface:SetBrushColor(COLORS.white)
        record.nativeSurface:SetPadding({ Left = 0, Top = 0, Right = 0, Bottom = 0 })
        record.nativeSurface:SetVisibility(requested and nativeTexture
            and VIS_VISIBLE or VIS_COLLAPSED)
        if P.isValid(record.fallbackSurface) and P.isValid(record.text) then
            record.fallbackSurface:SetBrushColor(COLORS.controlPressed)
            record.fallbackSurface:SetPadding({ Left = 2, Top = 1,
                Right = 2, Bottom = 1 })
            record.text:SetText(FText(tostring(value or "")))
            record.fallbackSurface:SetVisibility(fallbackVisible
                and VIS_VISIBLE or VIS_COLLAPSED)
        end
        record.badge:SetWidthOverride(width)
        record.badge:SetVisibility(requested
            and (nativeTexture or fallbackVisible)
            and VIS_VISIBLE or VIS_COLLAPSED)
    end)
    if updated then
        record.device = device
        record.texturePath = nativeTexture and texturePath or nil
        record.nativeTexture = nativeTexture
    end
    return updated
end

function FooterGuide.makeFooterKeycap(tree, value, visible, device, inline,
        gamepadFamily)
    local box = construct(tree, "/Script/UMG.SizeBox")
    local nativeSurface = construct(tree, "/Script/UMG.Border")
    if box == nil or nativeSurface == nil then return nil end
    local record = {
        badge = box, nativeSurface = nativeSurface,
        device = device, inline = inline == true,
    }
    local ok = pcall(function()
        box:SetWidthOverride(SIZE.footerKeyGuide)
        box:SetHeightOverride(SIZE.footerKeyGuide)
        nativeSurface:SetVisibility(VIS_COLLAPSED)
        if record.inline then
            local overlay = construct(tree, "/Script/UMG.Overlay")
            local fallbackSurface = construct(tree, "/Script/UMG.Border")
            local label = makeText(tree, value or "", 13,
                COLORS.text, TEXT_CENTER)
            if overlay == nil or fallbackSurface == nil or label == nil then
                error("footer keycap fallback is unavailable")
            end
            record.fallbackSurface = fallbackSurface
            record.text = label
            align(overlay:AddChildToOverlay(nativeSurface), ALIGN_FILL, ALIGN_FILL)
            align(fallbackSurface:AddChild(label), ALIGN_CENTER, ALIGN_CENTER)
            align(overlay:AddChildToOverlay(fallbackSurface),
                ALIGN_FILL, ALIGN_FILL)
            align(box:AddChild(overlay), ALIGN_FILL, ALIGN_FILL)
        else
            align(box:AddChild(nativeSurface), ALIGN_FILL, ALIGN_FILL)
        end
    end)
    if not ok then return nil end
    FooterGuide.refreshFooterKeycap(record, value, visible, device,
        gamepadFamily)
    return record
end

function FooterGuide.addFooterKeycap(tree, parent, value, visible, device,
        leadingPadding, inline, gamepadFamily)
    if not P.isValid(parent) then return nil end
    local record = FooterGuide.makeFooterKeycap(tree, value, visible,
        device, inline, gamepadFamily)
    if record == nil then return nil end
    local slot
    pcall(function() slot = parent:AddChild(record.badge) end)
    if slot == nil then return nil end
    align(slot, ALIGN_FILL, ALIGN_CENTER)
    setPadding(slot, tonumber(leadingPadding) or 0, 0, 0, 0)
    record.slot = slot
    return record
end

function FooterGuide.separatorAt(spec, device, index)
    if type(spec) ~= "table" then return nil end
    if spec.dynamic == true then return "+" end
    local separators = spec[device .. "Separators"]
    return type(separators) == "table" and separators[index] or nil
end

function FooterGuide.leadingPadding(device, value, gamepadFamily)
    if device == "gamepad" then
        gamepadFamily = gamepadFamily
            or state.gamepadKeyGuideFamily or "xinput"
        local suffixMap = gamepadFamily == "dualsense"
            and FooterGuide.DUALSENSE_KEY_GUIDE
            or FooterGuide.XINPUT_KEY_GUIDE
        local suffix = suffixMap[tostring(value or "")]
        local familyPadding = FooterGuide.GAMEPAD_LEADING_PADDING[gamepadFamily]
            or FooterGuide.GAMEPAD_LEADING_PADDING.xinput
        return tonumber(suffix ~= nil and familyPadding[suffix] or nil) or 0.0
    end
    local suffix = FooterGuide.KEYBOARD_KEY_GUIDE[tostring(value or "")]
    return tonumber(suffix ~= nil
        and FooterGuide.KEYBOARD_LEADING_PADDING[suffix] or nil) or 0.0
end

function FooterGuide.addGroup(tree, parent, spec, groupRecords, device,
        rowIndex, pairIndex, gamepadFamily)
    if not P.isValid(parent) or type(spec) ~= "table" then return nil end
    device = device == "gamepad" and "gamepad" or "keyboard"
    rowIndex = tonumber(rowIndex) or 0
    pairIndex = tonumber(pairIndex) or 0
    local titleColumn = pairIndex * 2
    local valueColumn = titleColumn + 1
    local keys = construct(tree, "/Script/UMG.HorizontalBox")
    local actionLabel = makeText(tree, spec.action or "", 11,
        COLORS.text, TEXT_LEFT)
    if keys == nil or actionLabel == nil then return nil end
    local actionSlot, keysSlot
    local added = pcall(function()
        actionLabel:SetAutoWrapText(false)
        actionSlot = parent:AddChildToGrid(actionLabel, rowIndex, titleColumn)
        keysSlot = parent:AddChildToGrid(keys, rowIndex, valueColumn)
    end)
    if not added or actionSlot == nil or keysSlot == nil then return nil end
    align(actionSlot, ALIGN_LEFT, ALIGN_CENTER)
    align(keysSlot, ALIGN_LEFT, ALIGN_CENTER)
    local rowTop = rowIndex > 0 and SIZE.footerHelpRowGap or 0
    setPadding(actionSlot,
        pairIndex > 0 and SIZE.footerHelpGroupGap or 0,
        rowTop, SIZE.footerHelpActionGap, 0)
    setPadding(keysSlot, FooterGuide.leadingPadding(
        device, (spec[device] or {})[1], gamepadFamily), rowTop, 0, 0)
    local keycapCount = math.max(#(spec.keyboard or {}), #(spec.gamepad or {}))
    if spec.dynamic == true then keycapCount = math.max(4, keycapCount) end
    local groupRecord = {
        id = spec.id, keycaps = {}, separatorRecords = {},
        actionLabel = actionLabel, keys = keys, keysSlot = keysSlot,
        rowIndex = rowIndex,
    }
    local values = spec[device] or {}
    for index = 1, keycapCount do
        local value = values[index]
        local previousSeparator = index > 1
            and FooterGuide.separatorAt(spec, device, index - 1) or nil
        local keyGap = index > 1 and previousSeparator == nil
            and SIZE.footerHelpKeyGap or 0
        local keycap = FooterGuide.addFooterKeycap(tree, keys, value or "",
            value ~= nil, device, keyGap, spec.dynamic == true, gamepadFamily)
        if keycap == nil then return nil end
        groupRecord.keycaps[index] = keycap
        local keyboardSeparator = FooterGuide.separatorAt(
            spec, "keyboard", index)
        local gamepadSeparator = FooterGuide.separatorAt(
            spec, "gamepad", index)
        if index < keycapCount
            and (keyboardSeparator ~= nil or gamepadSeparator ~= nil) then
            local separatorGlyph = FooterGuide.separatorAt(spec, device, index)
            local separator = makeText(tree, separatorGlyph or "", 13,
                COLORS.muted, TEXT_CENTER)
            if separator == nil then return nil end
            separator:SetVisibility(separatorGlyph ~= nil
                and values[index] ~= nil and values[index + 1] ~= nil
                and VIS_VISIBLE or VIS_COLLAPSED)
            local separatorSlot = keys:AddChild(separator)
            align(separatorSlot, ALIGN_FILL, ALIGN_CENTER)
            setPadding(separatorSlot, SIZE.footerHelpSeparatorGap, 0,
                SIZE.footerHelpSeparatorGap, 0)
            groupRecord.separatorRecords[index] = separator
        end
    end
    groupRecords[#groupRecords + 1] = groupRecord
    return actionSlot
end

function FooterGuide.footerHelpSpecs(strings)
    strings = strings or currentStrings()
    local hosted = (state.footerMode or state.mode) == "hosted"
    return {
        {
            id = "navigation", action = strings.navigate,
            keyboard = { "Up", "Down", "W", "S", "Tab" },
            keyboardSeparators = { [2] = "/", [4] = "/" },
            gamepad = { "Gamepad_DPad_Up", "Gamepad_DPad_Down",
                "Gamepad_LeftStick_UD" },
            gamepadSeparators = { [2] = "/" },
        },
        {
            id = "switch-tabs", action = strings.switchTabs or "Switch tabs",
            keyboard = { "Q", "E" },
            keyboardSeparators = { [1] = "/" },
            gamepad = { "Gamepad_LeftShoulder", "Gamepad_RightShoulder" },
            gamepadSeparators = { [1] = "/" },
        },
        {
            id = "adjust", action = strings.adjust,
            keyboard = { "Left", "Right", "A", "D" },
            keyboardSeparators = { [2] = "/" },
            gamepad = { "Gamepad_DPad_Left", "Gamepad_DPad_Right",
                "Gamepad_LeftStick_LR" },
            gamepadSeparators = { [2] = "/" },
        },
        {
            id = "confirm", action = strings.confirm,
            keyboard = { "Enter", "SpaceBar" },
            keyboardSeparators = { [1] = "/" },
            gamepad = { "Gamepad_FaceButton_Bottom" },
        },
        {
            id = "close", action = hosted
                and strings.returnToPalInsight or strings.close,
            keyboard = { "Escape" },
            gamepad = { "Gamepad_FaceButton_Right" },
        },
        {
            id = "toggle", action = hosted
                and strings.closeAllSettings or strings.toggleSettings,
            keyboard = { "F6" }, gamepad = {},
        },
    }
end

function FooterGuide.refreshFooterHelp(force)
    local records = state.footerGuideRecords
    if type(records) ~= "table" or type(records.groups) ~= "table" then
        return false
    end
    local displayDevice = state.lastInputDevice == "gamepad"
        and "gamepad" or "keyboard"
    local gamepadFamily = displayDevice == "gamepad"
        and FooterGuide.readGamepadFamily(force)
        or state.gamepadKeyGuideFamily or "xinput"
    local signature = displayDevice .. "|" .. gamepadFamily .. "|"
        .. tostring(state.footerMode or state.mode or "standalone")
    if force ~= true and state.footerGuideSignature == signature then
        return false
    end
    local strings = currentStrings()
    local specs = FooterGuide.footerHelpSpecs(strings)
    local changed = pcall(function()
        local footerTitle = strings.inputHelpTitle or strings.footer or "Controls"
        records.title:SetText(FText(footerTitle))
        records.deviceLabel:SetText(FText(displayDevice == "gamepad"
            and (strings.inputDeviceGamepad or "Controller")
            or (strings.inputDeviceKeyboardMouse or "Keyboard / Mouse")))
        for groupIndex, spec in ipairs(specs) do
            local group = records.groups[groupIndex]
            local values = spec[displayDevice] or {}
            if type(group) == "table" then
                local hasValues = #values > 0
                group.actionLabel:SetText(FText(spec.action or ""))
                group.actionLabel:SetVisibility(hasValues
                    and VIS_VISIBLE or VIS_COLLAPSED)
                group.keys:SetVisibility(hasValues
                    and VIS_VISIBLE or VIS_COLLAPSED)
                for index, keycap in ipairs(group.keycaps or {}) do
                    local value = values[index]
                    local previousSeparator = index > 1
                        and FooterGuide.separatorAt(
                            spec, displayDevice, index - 1) or nil
                    setPadding(keycap.slot,
                        index > 1 and previousSeparator == nil
                            and SIZE.footerHelpKeyGap or 0, 0, 0, 0)
                    FooterGuide.refreshFooterKeycap(keycap, value,
                        value ~= nil, displayDevice, gamepadFamily)
                end
                for index, separator in pairs(
                        group.separatorRecords or {}) do
                    local glyph = FooterGuide.separatorAt(
                        spec, displayDevice, index)
                    separator:SetText(FText(glyph or ""))
                    separator:SetVisibility(glyph ~= nil
                        and values[index] ~= nil and values[index + 1] ~= nil
                        and VIS_VISIBLE or VIS_COLLAPSED)
                end
                setPadding(group.keysSlot, FooterGuide.leadingPadding(
                    displayDevice, values[1], gamepadFamily),
                    (tonumber(group.rowIndex) or 0) > 0
                        and SIZE.footerHelpRowGap or 0, 0, 0)
            end
        end
    end)
    if changed then state.footerGuideSignature = signature end
    return changed
end

function FooterGuide.markInputDevice(device)
    if device ~= "keyboard" and device ~= "mouse"
        and device ~= "gamepad" then return false end
    if state.lastInputDevice == device then return false end
    state.lastInputDevice = device
    if state.open then
        FooterGuide.refreshFooterHelp(device == "gamepad")
    end
    return true
end

local refreshShortcutConflictWarning

local function applyControlPatch(patch, source)
    local candidate = copyConfig(state.config)
    for key, value in pairs(type(patch) == "table" and patch or {}) do
        candidate[key] = value
    end
    local applied, applyError = SettingsUI.apply(candidate, source)
    local strings = currentStrings()
    if applied then
        setStatus("", false)
        refreshShortcutConflictWarning()
        FooterGuide.refreshFooterHelp(false)
        return true
    end
    if applyError == "F6 is reserved for the settings surface"
        or applyError == "Escape is reserved for the settings surface"
        or applyError == "LeftMouseButton is reserved for the settings surface" then
        setStatus("", false)
        FooterGuide.refreshFooterHelp(false)
        return false
    end
    setStatus(string.format(strings.saveFailed, tostring(applyError)), true)
    return false
end

refreshShortcutConflictWarning = function()
    local warning = state.shortcutWarningText
    local control = state.shortcutControl
    if not P.isValid(warning) or type(control) ~= "table" then return false end
    local chord = {
        Key = state.config.Key,
        Shift = state.config.Shift,
        Ctrl = state.config.Ctrl,
        Alt = state.config.Alt,
    }
    local conflict = false
    if type(state.shortcutConflict) == "function" then
        local ok, value = pcall(state.shortcutConflict, chord)
        conflict = ok and value == true
    end
    pcall(function()
        if conflict then
            local template = currentStrings().externalShortcutConflict
                or "Possible UE4SS shortcut conflict: %s"
            warning:SetText(FText(string.format(template, chordLabel(chord))))
            warning:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        else
            warning:SetText(FText(""))
            warning:SetVisibility(VIS_COLLAPSED)
        end
    end)
    return conflict
end

local function resetControlsToConfig()
    for _, control in ipairs(state.controls) do
        if control.kind == "toggle" and P.isValid(control.widget) then
            state.toggleEventsSuppressed = true
            pcall(function()
                control.widget:SetIsChecked(state.config[control.key] == true)
            end)
            state.toggleEventsSuppressed = false
            control.last = state.config[control.key] == true
            refreshToggleDisplay(control)
        elseif control.kind == "choice" then
            for index, value in ipairs(control.values) do
                if value == state.config[control.key] then control.index = index end
            end
            if P.isValid(control.text) then
                pcall(function()
                    control.text:SetText(FText(control.labels[control.index]))
                end)
            end
        elseif SettingsUI.isItemPicker(control) and P.isValid(control.text) then
            pcall(function()
                control.text:SetText(FText(control.catalog.summary(
                    currentStrings()[control.summaryKey],
                    state.config[control.key])))
            end)
        elseif control.kind == "number" then
            control.value = tonumber(state.config[control.key]) or control.minimum
            setNumberEditorText(control, control.value)
            syncNumberPresentation(control, false)
        elseif control.kind == "shortcut" and P.isValid(control.widget) then
            local chord = {
                Key = state.config.Key,
                Shift = state.config.Shift,
                Ctrl = state.config.Ctrl,
                Alt = state.config.Alt,
            }
            setSelectorChord(control.widget, chord)
            control.last = chordSignature(chord)
            control.selecting = false
            refreshShortcutDisplay(control, false)
            refreshShortcutConflictWarning()
        end
    end
end

local function inputKeyDown(controller, keyName)
    if not P.isValid(controller) or type(FName) ~= "function" then return nil end
    local ok, down = pcall(function()
        return controller:IsInputKeyDown({ KeyName = FName(keyName) })
    end)
    return ok and type(down) == "boolean" and down or nil
end

local function controllerWorldAddress(controller)
    if not P.isValid(controller) then return nil end
    local world
    local ok = pcall(function() world = controller:GetWorld() end)
    return ok and P.objectAddress(world) or nil
end

local openChoiceModal
local ensureChoiceModal
local closeAboutModal
local moveAboutFocus
local activateAboutAction
local closeAboutRoster
local closeAboutPreview
local logicalViewportSize
local commitNumberEditor
local focusedNumberControl
local handleNumberPreview
local commitNumber
local selectorCapturing
local windowCacheMatches
local completeClose

local function focusNavigationRoot()
    if not P.isValid(state.widget) then return false end
    local focused = pcall(function()
        if P.isValid(state.controller) then state.widget:SetUserFocus(state.controller) end
        state.widget:SetKeyboardFocus()
    end)
    return focused == true
end

do
    local function focusNumberEditorInput(control)
        if type(control) ~= "table" or control.kind ~= "number"
            or not P.isValid(control.input) then return false end
        -- Slate applies the requested focus after the current pointer event returns.
        -- Checking HasKeyboardFocus() synchronously here rejects a valid request and
        -- immediately tears the editor back down on its first mouse click.
        return pcall(function()
            if P.isValid(state.controller) then
                control.input:SetUserFocus(state.controller)
            end
            control.input:SetKeyboardFocus()
        end)
    end
    state.numberEditorOps.focusNumberEditorInput = focusNumberEditorInput
end

local function focusEntry(index, device, scrollIntoView)
    local count = #(state.focusEntries or {})
    if count < 1 then return false end
    index = ((tonumber(index) or 1) - 1) % count + 1
    local control = state.focusEntries[index]
    if type(control) ~= "table" or not P.isValid(control.widget) then return false end
    state.focusIndex = index
    FooterGuide.markInputDevice(device or state.lastInputDevice)
    focusNavigationRoot()
    refreshTriggerSurfaces()
    if scrollIntoView ~= false and P.isValid(state.scroll)
        and P.isValid(control.scrollTarget) then
        pcall(function()
            state.scroll:ScrollWidgetIntoView(control.scrollTarget, false, 0, 12.0)
        end)
    end
    return true
end

local function scheduleShortcutFocusRestore(control)
    if type(control) ~= "table" then return false end
    state.shortcutFocusRestoreToken = state.shortcutFocusRestoreToken + 1
    local token = state.shortcutFocusRestoreToken
    local generation = state.generation
    local windowSession = state.windowSession
    local widgetAddress = P.objectAddress(state.widget)
    local controllerAddress = P.objectAddress(state.controller)
    local worldAddress = controllerWorldAddress(state.controller)
    if widgetAddress == nil or controllerAddress == nil or worldAddress == nil then
        return false
    end
    local pointerReturnFocusIndex = control.pointerReturnFocusIndex
    local index = pointerReturnFocusIndex or control.focusIndex or state.focusIndex
    local device = pointerReturnFocusIndex ~= nil and "mouse" or "keyboard"
    control.pointerReturnFocusIndex = nil
    local callback
    callback = function()
        if state.shortcutFocusRestoreToken ~= token then return end
        state.shortcutFocusRestoreCallback = nil
        if not state.open or state.lifecycle ~= "open"
            or state.generation ~= generation
            or state.windowSession ~= windowSession
            or P.objectAddress(state.widget) ~= widgetAddress
            or P.objectAddress(state.controller) ~= controllerAddress
            or controllerWorldAddress(state.controller) ~= worldAddress then return end
        focusEntry(index, device, true)
    end
    state.shortcutFocusRestoreCallback = callback
    if type(ExecuteInGameThreadWithDelay) == "function" then
        local scheduled = pcall(ExecuteInGameThreadWithDelay, 1, callback)
        if scheduled then return true end
    end
    if type(ExecuteInGameThread) == "function" then
        local scheduled = pcall(ExecuteInGameThread, callback)
        if scheduled then return true end
    end
    callback()
    return true
end

local function moveFocus(direction, device)
    if state.activeChoice ~= nil then
        local count = #((state.activeChoice or {}).labels or {})
        if count < 1 then return true end
        state.modalIndex = ((tonumber(state.modalIndex) or 1) - 1 + direction) % count + 1
        local option = (state.modalOptions or {})[state.modalIndex]
        if type(option) == "table" and P.isValid(option.widget) then
            focusNavigationRoot()
            if P.isValid(state.nestedScroll) and P.isValid(option.box) then
                pcall(function()
                    state.nestedScroll:ScrollWidgetIntoView(
                        option.box, false, 0, 8.0)
                end)
            end
        end
        for index, candidate in ipairs(state.modalOptions or {}) do
            candidate.selected = index == state.modalIndex
        end
        refreshTriggerSurfaces()
        return true
    end
    local count = #(state.focusEntries or {})
    if count < 1 then return false end
    local index = tonumber(state.focusIndex) or 1
    for _ = 1, count do
        index = ((index - 1 + direction) % count) + 1
        local control = state.focusEntries[index]
        if type(control) == "table" and control.passive ~= true then
            return focusEntry(index, device or "keyboard", true)
        end
    end
    return false
end

local HEADER_FOCUS_KINDS = {
    steamVote = true,
    releaseNotes = true,
    about = true,
    reset = true,
    close = true,
}

local function moveHeaderFocus(direction, device)
    local current = (state.focusEntries or {})[tonumber(state.focusIndex) or 1]
    if type(current) ~= "table" or HEADER_FOCUS_KINDS[current.kind] ~= true then
        return false
    end
    local indices = {}
    local currentPosition
    for index, control in ipairs(state.focusEntries or {}) do
        if type(control) == "table" and control.passive ~= true
            and HEADER_FOCUS_KINDS[control.kind] == true then
            indices[#indices + 1] = index
            if control == current then currentPosition = #indices end
        end
    end
    if currentPosition == nil or #indices < 2 then return false end
    local targetPosition = ((currentPosition - 1 + direction) % #indices) + 1
    return focusEntry(indices[targetPosition], device or "keyboard", false)
end

state.navigationDirection = function(keyName)
    if keyName == "W" or keyName == "Up"
        or keyName == "Gamepad_DPad_Up"
        or keyName == "Gamepad_LeftStick_Up" then
        return "y", -1
    end
    if keyName == "S" or keyName == "Down"
        or keyName == "Gamepad_DPad_Down"
        or keyName == "Gamepad_LeftStick_Down" then
        return "y", 1
    end
    if keyName == "A" or keyName == "Left"
        or keyName == "Gamepad_DPad_Left"
        or keyName == "Gamepad_LeftStick_Left" then
        return "x", -1
    end
    if keyName == "D" or keyName == "Right"
        or keyName == "Gamepad_DPad_Right"
        or keyName == "Gamepad_LeftStick_Right" then
        return "x", 1
    end
    return nil
end

local function navigationRepeatScope()
    if state.releaseNotesOpen == true then return "releaseNotes", nil end
    if state.aboutOpen == true then return "about", nil end
    if state.activeChoice ~= nil then return "choice", state.activeChoice end
    return "root", nil
end

local function cancelNavigationRepeat(keyName)
    local record = state.navigationRepeat
    if type(record) ~= "table" then return false end
    if keyName ~= nil and record.keyName ~= keyName then return false end
    state.navigationRepeat = nil
    return true
end

local function startNavigationRepeat(keyName, device)
    local axis, direction = state.navigationDirection(keyName)
    if axis == nil or not state.open or state.lifecycle ~= "open" then
        return false
    end
    if device ~= "gamepad" then return false end
    if axis == "x" and keyName ~= "Gamepad_DPad_Left"
        and keyName ~= "Gamepad_DPad_Right" then return false end
    local scope, owner = navigationRepeatScope()
    local controllerAddress = P.objectAddress(state.controller)
    local worldAddress = controllerWorldAddress(state.controller)
    local widgetAddress = P.objectAddress(state.widget)
    if controllerAddress == nil or worldAddress == nil or widgetAddress == nil then
        return false
    end
    state.navigationRepeat = {
        keyName = keyName,
        axis = axis,
        direction = direction,
        device = device,
        scope = scope,
        owner = owner,
        generation = state.generation,
        windowSession = state.windowSession,
        controllerAddress = controllerAddress,
        worldAddress = worldAddress,
        widgetAddress = widgetAddress,
        nextRepeatAt = os.clock() + state.navigationRepeatInitialMs / 1000.0,
    }
    return true
end

local function navigationRepeatOwnsPress(keyName)
    local record = state.navigationRepeat
    return type(record) == "table" and record.keyName == keyName
        and record.generation == state.generation
        and record.windowSession == state.windowSession
end

local function navigationRepeatHeld(record)
    if tostring(record.keyName):find("Gamepad_LeftStick_", 1, true) == 1 then
        local value = tonumber((state.axisValues or {})[record.axis]) or 0.0
        return math.abs(value) >= 0.55
            and (record.axis == "y"
                and ((record.direction < 0 and value > 0)
                    or (record.direction > 0 and value < 0))
                or record.axis == "x"
                and ((record.direction < 0 and value < 0)
                    or (record.direction > 0 and value > 0)))
    end
    if tostring(record.keyName):find("Gamepad_", 1, true) == 1 then
        return state.controllerDown[record.keyName] == true
    end
    return inputKeyDown(state.controller, record.keyName) == true
end

local function pollNavigationRepeat()
    local record = state.navigationRepeat
    if type(record) ~= "table" then return end
    local scope, owner = navigationRepeatScope()
    if not state.open or state.lifecycle ~= "open"
        or record.generation ~= state.generation
        or record.windowSession ~= state.windowSession
        or record.controllerAddress ~= P.objectAddress(state.controller)
        or record.worldAddress ~= controllerWorldAddress(state.controller)
        or record.widgetAddress ~= P.objectAddress(state.widget)
        or record.scope ~= scope or record.owner ~= owner
        or selectorCapturing() or not navigationRepeatHeld(record) then
        cancelNavigationRepeat()
        return
    end
    local now = os.clock()
    if now < record.nextRepeatAt then return end
    record.nextRepeatAt = now + state.navigationRepeatIntervalMs / 1000.0
    FooterGuide.markInputDevice(record.device)
    local horizontal = record.axis == "x" and record.direction or 0
    local vertical = record.axis == "y" and record.direction or 0
    if record.scope == "releaseNotes" then
        state.moveReleaseNotesFocus(horizontal, vertical)
    elseif record.scope == "about" then
        moveAboutFocus(horizontal, vertical)
    elseif record.scope == "choice" then
        if vertical ~= 0 or (horizontal ~= 0
                and type(record.owner) == "table"
                and record.owner.kind == "resetConfirmation") then
            moveFocus(record.direction, record.device)
        end
    elseif vertical ~= 0 then
        moveFocus(vertical, record.device)
    elseif not moveHeaderFocus(horizontal, record.device) then
        local editedNumber = focusedNumberControl ~= nil
            and focusedNumberControl() or nil
        if editedNumber ~= nil and handleNumberPreview ~= nil then
            handleNumberPreview(editedNumber, record.keyName, nil, "repeat")
        else
            local control = (state.focusEntries or {})[state.focusIndex]
            if type(control) == "table" and control.kind == "number" then
                commitNumber(control, control.value + horizontal,
                    horizontal < 0 and "number-left-repeat"
                        or "number-right-repeat")
            end
        end
    end
end

local function commitChoice(control, index, source)
    if type(control) ~= "table" or control.kind ~= "choice"
        or control.labels[index] == nil then return false end
    local previous = control.index
    control.index = index
    if not applyControlPatch({
            [control.key] = control.values[index],
        }, source or ("choice:" .. control.key)) then
        control.index = previous
    end
    if P.isValid(control.text) then
        pcall(function()
            control.text:SetText(FText(control.labels[control.index]))
        end)
    end
    return control.index ~= previous or control.index == index
end

local function commitToggle(control, source)
    if type(control) ~= "table" or control.kind ~= "toggle"
        or not P.isValid(control.widget) then return false end
    local ok, value = pcall(function() return control.widget:IsChecked() end)
    if not ok or type(value) ~= "boolean" then return false end
    if value == control.last then return false end
    local previous = control.last
    control.last = value
    if not applyControlPatch({
            [control.key] = value,
        }, source or ("toggle:" .. control.key)) then
        control.last = previous
        state.toggleEventsSuppressed = true
        pcall(function() control.widget:SetIsChecked(previous) end)
        state.toggleEventsSuppressed = false
        return false
    end
    return true
end

local function activateToggle(control, source)
    if type(control) ~= "table" or control.kind ~= "toggle"
        or not P.isValid(control.widget) then return false end
    local ok, current = pcall(function() return control.widget:IsChecked() end)
    if not ok or type(current) ~= "boolean" then return false end
    local target = not current
    state.toggleEventsSuppressed = true
    local changed = pcall(function() control.widget:SetIsChecked(target) end)
    state.toggleEventsSuppressed = false
    if not changed then return false end
    return commitToggle(control, source or ("toggle:" .. control.key))
end

local function commitNativeToggleChanges(source)
    if not state.open or state.toggleEventsSuppressed == true then return false end
    for _, control in ipairs(state.controls or {}) do
        if control.kind == "toggle" and P.isValid(control.widget) then
            local ok, value = pcall(function() return control.widget:IsChecked() end)
            if ok and type(value) == "boolean" and value ~= control.last then
                cancelNavigationRepeat()
                FooterGuide.markInputDevice("mouse")
                state.focusIndex = control.focusIndex
                local edit = state.numberEdit
                if type(edit) == "table" and type(edit.control) == "table" then
                    commitNumberEditor(edit.control, "number-navigation", true)
                end
                commitToggle(control, source or ("toggle:" .. control.key))
                refreshToggleDisplay(control)
                refreshRowDisplay(control)
                refreshTriggerSurfaces()
                return true
            end
        end
    end
    return false
end

commitNumber = function(control, value, source)
    if type(control) ~= "table" or control.kind ~= "number" then return false end
    value = tonumber(value)
    if value == nil or math.floor(value) ~= value
        or value < control.minimum or value > control.maximum then return false end
    local previous = control.value
    control.value = value
    if value ~= previous and not applyControlPatch({
            [control.key] = value,
        }, source or ("number:" .. control.key)) then
        control.value = previous
        value = previous
    end
    setNumberEditorText(control, control.value)
    return control.value == value
end

local function resetFromDefaults()
    local edit = state.numberEdit
    if type(edit) == "table" and type(edit.control) == "table" then
        commitNumberEditor(edit.control, "number-reset", false)
    end
    local candidate = copyConfig(state.config)
    for key, value in pairs(DEFAULTS) do candidate[key] = value end
    local applied, applyError = SettingsUI.apply(candidate, "reset")
    if applied then
        resetControlsToConfig()
        setStatus("", false)
        return true
    end
    setStatus(string.format(currentStrings().saveFailed,
        tostring(applyError)), true)
    return false
end

local function commitNestedModalSelection(source)
    local control = state.activeChoice
    if type(control) ~= "table" then return false end
    local index = tonumber(state.modalIndex) or control.index or 1
    if control.kind == "resetConfirmation" then
        local confirmed = index == 2
        closeChoiceModal(true)
        if confirmed then return resetFromDefaults() end
        return true
    end
    if control.kind == "downvoteAcknowledgement" then
        if index ~= 1 then return true end
        return closeChoiceModal(false)
    end
    if control.kind == "steamVoteChecking" then return true end
    if SettingsUI.isItemPicker(control) then
        local catalog = control.catalog
        if index > #catalog.items then return closeChoiceModal(true) end
        local staticId = catalog.items[index]
        local selected = catalog.sellSet(state.config[control.key])
        selected[staticId] = selected[staticId] ~= true and true or nil
        local values = {}
        for _, candidate in ipairs(catalog.items) do
            if selected[candidate] then values[#values + 1] = candidate end
        end
        local value = table.concat(values, ",")
        if not applyControlPatch({ [control.key] = value },
                source or control.source) then return false end
        local option = state.modalOptions[index]
        if type(option) == "table" and P.isValid(option.ammoMark) then
            pcall(function()
                option.ammoMark:SetText(FText(
                    selected[staticId] ~= true and "✓" or ""))
            end)
        end
        if P.isValid(control.text) then
            pcall(function()
                control.text:SetText(FText(catalog.summary(
                    currentStrings()[control.summaryKey],
                    state.config[control.key])))
            end)
        end
        refreshTriggerSurfaces()
        return true
    end
    commitChoice(control, index, source or ("choice:" .. tostring(control.key)))
    closeChoiceModal(true)
    return true
end

local function activateControl(control, source, returnFocusIndex)
    if type(control) ~= "table" then return false end
    if control.passive == true then
        if source == "mouse" then return false end
        return moveFocus(1, source or "keyboard")
    end
    local edit = state.numberEdit
    if type(edit) == "table" and edit.control ~= control
        and type(edit.control) == "table" then
        commitNumberEditor(edit.control, "number-navigation", true)
    end
    if control.kind == "choice" then
        return openChoiceModal(control, returnFocusIndex)
    elseif SettingsUI.isItemPicker(control) then
        return Deferred.openAmmoPickerModal(control, returnFocusIndex)
    elseif control.kind == "toggle" then
        return activateToggle(control, source)
    elseif control.kind == "number" then
        local edit = state.numberEdit
        if type(edit) == "table" and edit.control == control then
            return commitNumberEditor(control, "number-commit", true)
        end
        local sourceName = tostring(source or "")
        local mode = sourceName == "mouse" and "mouse"
            or sourceName:find("^gamepad") ~= nil and "controller"
            or "keyboard"
        return Deferred.beginNumberEditor(control, mode)
    elseif control.kind == "shortcut" then
        local sourceName = tostring(source or "")
        if sourceName:find("^gamepad") ~= nil then
            setStatus(currentStrings().shortcutKeyboardMouseOnly
                or "Use a keyboard or mouse to change this shortcut.", false)
            focusNavigationRoot()
            refreshTriggerSurfaces()
            return true
        end
        if source == "mouse" then
            control.pointerReturnFocusIndex = tonumber(returnFocusIndex)
                or state.focusIndex
        end
        control.selecting = true
        pcall(function()
            if P.isValid(state.controller) then control.widget:SetUserFocus(state.controller) end
            control.widget:SetKeyboardFocus()
        end)
        return true
    elseif control.kind == "steamVote" then
        return activateSteamVote()
    elseif control.kind == "releaseNotes" then
        return Deferred.openReleaseNotesModal(returnFocusIndex
            or control.focusIndex or state.focusIndex,
            source == "mouse" and "mouse"
                or tostring(source or ""):find("^gamepad") ~= nil
                    and "gamepad" or "keyboard")
    elseif control.kind == "about" then
        return Deferred.openAboutModal()
    elseif control.kind == "reset" then
        return Deferred.openResetConfirmation(returnFocusIndex
            or control.focusIndex or state.focusIndex)
    elseif control.kind == "close" then
        return SettingsUI.close(source or "activate")
    end
    return false
end

local function activateFocused(source)
    if state.activeChoice ~= nil then
        return commitNestedModalSelection(source)
    end
    local control = (state.focusEntries or {})[tonumber(state.focusIndex) or 1]
    return activateControl(control, source, nil)
end

local function activeShortcutCapture()
    for _, control in ipairs(state.controls or {}) do
        if control.kind == "shortcut" and P.isValid(control.widget) then
            local ok, selecting = pcall(function()
                return control.widget:GetIsSelectingKey()
            end)
            if ok and selecting == true then return control end
        end
    end
    return nil
end

selectorCapturing = function()
    return activeShortcutCapture() ~= nil
end

local function shortcutControlForSelector(selector)
    local selectorAddress = P.objectAddress(selector)
    if selectorAddress == nil then return nil end
    for _, control in ipairs(state.controls or {}) do
        if control.kind == "shortcut" and P.isValid(control.widget)
            and P.objectAddress(control.widget) == selectorAddress then
            return control
        end
    end
    return nil
end

local function selectorSelectedKeyHook(context, chordParam)
    if not state.open or state.selectorChordProgrammatic == true then return end
    local selector = P.unwrap(context)
    local control = shortcutControlForSelector(selector)
    if control == nil then return end
    local selecting = false
    pcall(function() selecting = selector:GetIsSelectingKey() == true end)
    if not selecting and control.selecting ~= true then return end
    local chord
    local ok = pcall(function() chord = chordParam:get() end)
    if not ok then chord = P.unwrap(chordParam) end
    local keyName
    pcall(function() keyName = P.nameString(chord.Key.KeyName) end)
    if type(keyName) ~= "string" or keyName == "" then return end
    -- The selector owns this physical press. Remove the delayed global fallback
    -- and retain ownership briefly so the captured key cannot also navigate or
    -- activate the settings surface after native capture ends.
    InputOwner.discardPendingKey(keyName)
    state.synchronousNavigationUntil[keyName] = os.clock() + 0.30
end

local function cancelShortcutCapture(keyName)
    local control = activeShortcutCapture()
    if control == nil then return false end
    local persisted = {
        Key = state.config.Key,
        Shift = state.config.Shift,
        Ctrl = state.config.Ctrl,
        Alt = state.config.Alt,
    }
    keyName = tostring(keyName or "")
    if keyName ~= "" then
        InputOwner.discardPendingKey(keyName)
        state.synchronousNavigationUntil[keyName] = os.clock() + 0.30
        state.shortcutCaptureCancelKey = keyName
        state.shortcutCaptureCancelUntil = os.clock() + 0.50
    end
    setSelectorChord(control.widget, persisted)
    control.last = chordSignature(persisted)
    control.selecting = false
    scheduleShortcutFocusRestore(control)
    refreshShortcutDisplay(control, false)
    refreshShortcutConflictWarning()
    return true
end

local function claimSynchronousNavigation(keyName, source)
    if type(keyName) ~= "string" then return false end
    local now = os.clock()
    local claim = state.synchronousNavigationUntil[keyName]
    local ownedUntil = type(claim) == "table"
        and (tonumber(claim.untilAt) or 0.0) or tonumber(claim) or 0.0
    if source ~= "global" and source ~= "preview"
        and source ~= "actor" then return false end
    if ownedUntil > now and (type(claim) ~= "table"
        or claim.source ~= source) then return true end
    state.synchronousNavigationUntil[keyName] = {
        untilAt = now + 0.30,
        source = source,
    }
    if source ~= "global" then InputOwner.discardPendingKey(keyName) end
    return false
end

local function handlePressed(keyName, device, source, shiftDown)
    if not state.open then return false end
    if state.lifecycle ~= "open" and state.lifecycle ~= "recovering" then return true end
    device = device or (tostring(keyName):find("^Gamepad_") and "gamepad" or "keyboard")
    if shiftDown ~= true and keyName == "Tab" then
        shiftDown = inputKeyDown(state.controller, "LeftShift") == true
            or inputKeyDown(state.controller, "RightShift") == true
    end
    FooterGuide.markInputDevice(device)
    if state.shortcutCaptureCancelKey == keyName then
        if os.clock() < (tonumber(state.shortcutCaptureCancelUntil) or 0.0) then
            return true
        end
        state.shortcutCaptureCancelKey = nil
        state.shortcutCaptureCancelUntil = 0.0
    end
    if selectorCapturing() then
        if keyName == "Gamepad_FaceButton_Right" then
            return cancelShortcutCapture(keyName)
        end
        return true
    end
    local navigationAxis = state.navigationDirection(keyName)
    if navigationAxis == nil then cancelNavigationRepeat() end
    if navigationAxis ~= nil and navigationRepeatOwnsPress(keyName) then return true end
    if state.releaseNotesOpen == true then
        if keyName == "Escape" then return state.closeReleaseNotesModal(true) end
        if keyName == "W" or keyName == "Up"
            or keyName == "Gamepad_DPad_Up"
            or keyName == "Gamepad_LeftStick_Up" then
            local moved = state.moveReleaseNotesFocus(0, -1)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        elseif keyName == "S" or keyName == "Down"
            or keyName == "Gamepad_DPad_Down"
            or keyName == "Gamepad_LeftStick_Down" then
            local moved = state.moveReleaseNotesFocus(0, 1)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        elseif keyName == "A" or keyName == "Left"
            or keyName == "Gamepad_DPad_Left"
            or keyName == "Gamepad_LeftStick_Left" then
            local moved = state.moveReleaseNotesFocus(-1, 0)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        elseif keyName == "D" or keyName == "Right"
            or keyName == "Gamepad_DPad_Right"
            or keyName == "Gamepad_LeftStick_Right" then
            local moved = state.moveReleaseNotesFocus(1, 0)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        elseif keyName == "Tab" then
            state.releaseNotesFocusPane = state.releaseNotesFocusPane % 3 + 1
            refreshTriggerSurfaces()
            return true
        elseif keyName == "Enter" or keyName == "SpaceBar" then
            return state.activateReleaseNotesAction()
        elseif keyName == "Gamepad_FaceButton_Bottom" then
            state.gamepadAcceptDown = true
        elseif keyName == "Gamepad_FaceButton_Right" then
            state.gamepadBackDown = true
        end
        return true
    end
    if state.aboutOpen == true then
        if state.aboutPreviewOpen == true then
            if keyName == "Escape" or keyName == "Enter"
                or keyName == "SpaceBar" then
                return closeAboutPreview(true)
            elseif keyName == "Gamepad_FaceButton_Bottom" then
                state.gamepadAcceptDown = true
            elseif keyName == "Gamepad_FaceButton_Right" then
                state.gamepadBackDown = true
            end
            return true
        elseif state.aboutRosterOpen == true then
            if keyName == "Escape" or keyName == "Enter"
                or keyName == "SpaceBar" then
                return closeAboutRoster(true)
            elseif keyName == "Gamepad_FaceButton_Bottom" then
                state.gamepadAcceptDown = true
            elseif keyName == "Gamepad_FaceButton_Right" then
                state.gamepadBackDown = true
            end
            return true
        end
        if keyName == "Escape" then return closeAboutModal(true) end
        if keyName == "W" or keyName == "Up"
            or keyName == "Gamepad_DPad_Up"
            or keyName == "Gamepad_LeftStick_Up" then
            local moved = moveAboutFocus(0, -1)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        elseif keyName == "S" or keyName == "Down"
            or keyName == "Gamepad_DPad_Down"
            or keyName == "Gamepad_LeftStick_Down" then
            local moved = moveAboutFocus(0, 1)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        elseif keyName == "A" or keyName == "Left"
            or keyName == "Gamepad_DPad_Left"
            or keyName == "Gamepad_LeftStick_Left" then
            local moved = moveAboutFocus(-1, 0)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        elseif keyName == "D" or keyName == "Right"
            or keyName == "Gamepad_DPad_Right"
            or keyName == "Gamepad_LeftStick_Right" then
            local moved = moveAboutFocus(1, 0)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        elseif keyName == "Enter" or keyName == "SpaceBar" then
            return activateAboutAction()
        elseif keyName == "Tab" then
            return true
        elseif keyName == "Gamepad_FaceButton_Bottom" then
            state.gamepadAcceptDown = true
        elseif keyName == "Gamepad_FaceButton_Right" then
            state.gamepadBackDown = true
        end
        return true
    end
    local numberControl = focusedNumberControl ~= nil and focusedNumberControl() or nil
    if numberControl ~= nil and handleNumberPreview ~= nil then
        return handleNumberPreview(numberControl, keyName, nil, source)
    end
    if claimSynchronousNavigation(keyName, source) then return true end
    if state.activeChoice ~= nil then
        if keyName == "Escape" then
            if state.activeChoice.kind == "downvoteAcknowledgement"
                or state.activeChoice.kind == "steamVoteChecking" then return true end
            return closeChoiceModal(true)
        end
        if keyName == "Gamepad_FaceButton_Bottom" then
            state.gamepadAcceptDown = true
            return true
        end
        if keyName == "Gamepad_FaceButton_Right" then
            state.gamepadBackDown = true
            return true
        end
        if keyName == "W" or keyName == "Up"
            or keyName == "Gamepad_DPad_Up"
            or keyName == "Gamepad_LeftStick_Up" then
            local moved = moveFocus(-1, device)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        end
        if keyName == "S" or keyName == "Down"
            or keyName == "Gamepad_DPad_Down"
            or keyName == "Gamepad_LeftStick_Down" then
            local moved = moveFocus(1, device)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        end
        if (state.activeChoice.kind == "resetConfirmation"
                or state.activeChoice.kind == "downvoteAcknowledgement")
            and (keyName == "A" or keyName == "Left"
                or keyName == "Gamepad_DPad_Left"
                or keyName == "Gamepad_LeftStick_Left") then
            local moved = moveFocus(-1, device)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        end
        if (state.activeChoice.kind == "resetConfirmation"
                or state.activeChoice.kind == "downvoteAcknowledgement")
            and (keyName == "D" or keyName == "Right"
                or keyName == "Gamepad_DPad_Right"
                or keyName == "Gamepad_LeftStick_Right") then
            local moved = moveFocus(1, device)
            if moved then startNavigationRepeat(keyName, device) end
            return moved
        end
        if keyName == "Enter" or keyName == "SpaceBar" then
            return activateFocused(device .. "-accept")
        end
        return true
    end
    if keyName == "Escape" then
        state.trailingReleaseUntil.Escape = os.clock() + 0.50
        return Deferred.deferInputClose("escape")
    end
    if keyName == "Q" or keyName == "Gamepad_LeftShoulder" then
        return state.switchSettingsPage(-1, device)
    elseif keyName == "E" or keyName == "Gamepad_RightShoulder" then
        return state.switchSettingsPage(1, device)
    elseif keyName == "W" or keyName == "Up" or keyName == "Tab"
        or keyName == "Gamepad_DPad_Up"
        or keyName == "Gamepad_LeftStick_Up" then
        local direction = keyName == "Tab" and (shiftDown and -1 or 1) or -1
        local moved = moveFocus(direction, device)
        if moved and keyName ~= "Tab" then startNavigationRepeat(keyName, device) end
        return moved
    elseif keyName == "S" or keyName == "Down"
        or keyName == "Gamepad_DPad_Down"
        or keyName == "Gamepad_LeftStick_Down" then
        local moved = moveFocus(1, device)
        if moved then startNavigationRepeat(keyName, device) end
        return moved
    elseif keyName == "A" or keyName == "Left"
        or keyName == "Gamepad_DPad_Left"
        or keyName == "Gamepad_LeftStick_Left" then
        if moveHeaderFocus(-1, device) then
            startNavigationRepeat(keyName, device)
            return true
        end
        local control = (state.focusEntries or {})[state.focusIndex]
        if type(control) == "table" and control.kind == "number" then
            local committed = commitNumber(
                control, control.value - 1, "number-left")
            if committed then startNavigationRepeat(keyName, device) end
            return committed
        end
        return true
    elseif keyName == "D" or keyName == "Right"
        or keyName == "Gamepad_DPad_Right"
        or keyName == "Gamepad_LeftStick_Right" then
        if moveHeaderFocus(1, device) then
            startNavigationRepeat(keyName, device)
            return true
        end
        local control = (state.focusEntries or {})[state.focusIndex]
        if type(control) == "table" and control.kind == "number" then
            local committed = commitNumber(
                control, control.value + 1, "number-right")
            if committed then startNavigationRepeat(keyName, device) end
            return committed
        end
        return true
    elseif keyName == "Enter" or keyName == "SpaceBar" then
        return activateFocused(device .. "-accept")
    elseif keyName == "Gamepad_FaceButton_Bottom" then
        state.gamepadAcceptDown = true
        return true
    elseif keyName == "Gamepad_FaceButton_Right" then
        state.gamepadBackDown = true
        return true
    end
    return true
end

local function handleReleased(keyName)
    if not state.open then return false end
    if state.lifecycle ~= "open" and state.lifecycle ~= "recovering" then return true end
    if type(keyName) == "string" then
        state.synchronousNavigationUntil[keyName] = nil
        cancelNavigationRepeat(keyName)
    end
    if state.shortcutCaptureCancelKey == keyName then
        state.shortcutCaptureCancelKey = nil
        state.shortcutCaptureCancelUntil = 0.0
        state.gamepadBackDown = false
        return true
    end
    if state.releaseNotesOpen == true then
        if keyName == "Gamepad_FaceButton_Bottom" then
            local armed = state.gamepadAcceptDown == true
            state.gamepadAcceptDown = false
            if armed then return state.activateReleaseNotesAction() end
        elseif keyName == "Gamepad_FaceButton_Right" then
            local armed = state.gamepadBackDown == true
            state.gamepadBackDown = false
            if armed then return state.closeReleaseNotesModal(true) end
        end
        return true
    end
    if state.aboutOpen == true then
        if keyName == "Gamepad_FaceButton_Bottom" then
            local armed = state.gamepadAcceptDown == true
            state.gamepadAcceptDown = false
            if armed and state.aboutPreviewOpen == true then
                return closeAboutPreview(true)
            end
            if armed and state.aboutRosterOpen == true then
                return closeAboutRoster(true)
            end
            if armed then return activateAboutAction() end
        elseif keyName == "Gamepad_FaceButton_Right" then
            local armed = state.gamepadBackDown == true
            state.gamepadBackDown = false
            if armed and state.aboutPreviewOpen == true then
                return closeAboutPreview(true)
            end
            if armed and state.aboutRosterOpen == true then
                return closeAboutRoster(true)
            end
            if armed then return closeAboutModal(true) end
        end
        return true
    end
    if keyName == "Gamepad_FaceButton_Bottom" then
        local armed = state.gamepadAcceptDown == true
        state.gamepadAcceptDown = false
        if armed then return activateFocused("gamepad-accept") end
    elseif keyName == "Gamepad_FaceButton_Right" then
        local armed = state.gamepadBackDown == true
        state.gamepadBackDown = false
        if armed then
            if type(state.activeChoice) == "table"
                and (state.activeChoice.kind == "downvoteAcknowledgement"
                    or state.activeChoice.kind == "steamVoteChecking") then return true end
            if state.activeChoice ~= nil then return closeChoiceModal(true) end
            if selectorCapturing() then return true end
            state.trailingReleaseUntil[keyName] = os.clock() + 0.50
            return Deferred.deferInputClose("gamepad-back")
        end
    end
    return true
end

local controllerInput = {}

function controllerInput.noteSource(eventName, keyName, source)
    if type(state.config) ~= "table"
        or state.config.PerformanceCapture ~= true then return end
    source = tostring(source or "unknown")
    local signature = tostring(eventName) .. ":" .. source
    if state.controllerInputSources[signature] == true then return end
    state.controllerInputSources[signature] = true
    log(string.format(
        "settings_input|device=gamepad|event=%s|source=%s|key=%s",
        tostring(eventName), source, tostring(keyName)))
end

function controllerInput.selectOwner(source, snapshot)
    source = type(source) == "string" and source or nil
    if source == nil or state.controllerInputOwner == source then return false end
    snapshot = type(snapshot) == "table" and snapshot or {}
    local connected = snapshot.connected ~= false
    local buttons = connected and math.floor(tonumber(snapshot.buttons) or 0) or 0
    state.controllerInputOwner = source
    state.controllerDown = {}
    for _, binding in ipairs(state.hostedControllerButtons) do
        state.controllerDown[binding.key] = (buttons & binding.mask) ~= 0
    end
    state.axisValues = {
        x = connected and (tonumber(snapshot.leftX) or 0.0) or 0.0,
        y = connected and (tonumber(snapshot.leftY) or 0.0) or 0.0,
    }
    state.axisArmed = {
        x = math.abs(state.axisValues.x) <= 0.30,
        y = math.abs(state.axisValues.y) <= 0.30,
    }
    state.gamepadBackDown = false
    state.gamepadAcceptDown = false
    cancelNavigationRepeat()
    return true
end

function controllerInput.isOwnedBy(source)
    return type(source) == "string" and state.controllerInputOwner == source
end

local function dispatchControllerPressed(keyName, source)
    if not controllerInput.isOwnedBy(source) then return true end
    if state.controllerDown[keyName] == true then return true end
    state.controllerDown[keyName] = true
    controllerInput.noteSource("pressed", keyName, source)
    return handlePressed(keyName, "gamepad", source)
end

local function dispatchControllerReleased(keyName, source)
    if not controllerInput.isOwnedBy(source) then return true end
    if state.controllerDown[keyName] ~= true then return true end
    state.controllerDown[keyName] = false
    controllerInput.noteSource("released", keyName, source)
    return handleReleased(keyName)
end

local function handleAxis(axis, value, source)
    if not state.open then return false end
    if not controllerInput.isOwnedBy(source) then return true end
    value = tonumber(value)
    if type(value) ~= "number" or (axis ~= "x" and axis ~= "y") then return false end
    state.axisValues[axis] = value
    if type(state.axisArmed) ~= "table" then
        state.axisArmed = { x = true, y = true }
    end
    local magnitude = math.abs(value)
    local armed = state.axisArmed[axis] ~= false
    if magnitude <= 0.30 then
        state.axisArmed[axis] = true
        if axis == "y" then
            local record = state.navigationRepeat
            if type(record) == "table"
                and (record.keyName == "Gamepad_LeftStick_Up"
                    or record.keyName == "Gamepad_LeftStick_Down") then
                cancelNavigationRepeat()
            end
        end
        return true
    end
    if not armed or magnitude < 0.55 then return true end
    state.axisArmed[axis] = false
    if axis == "x" then
        return handlePressed(value < 0 and "Gamepad_LeftStick_Left"
            or "Gamepad_LeftStick_Right", "gamepad", "axis")
    end
    return handlePressed(value > 0 and "Gamepad_LeftStick_Up"
        or "Gamepad_LeftStick_Down", "gamepad", "axis")
end

focusedNumberControl = function()
    local edit = state.numberEdit
    local control = type(edit) == "table" and edit.control or nil
    return state.open and type(control) == "table" and control.kind == "number"
        and P.isValid(control.widget)
        and edit.windowSession == state.windowSession
        and edit.worldAddress == controllerWorldAddress(state.controller)
        and edit.widgetAddress == P.objectAddress(state.widget)
        and edit.controlAddress == P.objectAddress(control.widget)
        and control or nil
end

do
    local function numberEditorRawText(control)
        if type(control) ~= "table" or not P.isValid(control.input) then return nil end
        local ok, raw = pcall(function() return control.input:GetText() end)
        if not ok or raw == nil then return nil end
        if type(raw) ~= "string" then
            local convertedOk, converted = pcall(function() return raw:ToString() end)
            raw = convertedOk and converted or tostring(raw)
        end
        return type(raw) == "string" and raw:match("^%s*(.-)%s*$") or nil
    end
    state.numberEditorOps.numberEditorRawText = numberEditorRawText
end

Deferred.beginNumberEditor = function(control, mode)
    if type(control) ~= "table" or control.kind ~= "number"
        or not P.isValid(control.widget) then return false end
    mode = mode == "mouse" and "mouse"
        or mode == "controller" and "controller" or "keyboard"
    local existing = state.numberEdit
    if type(existing) == "table" and type(existing.control) == "table" then
        commitNumberEditor(existing.control, "number-navigation", true)
    end
    local widgetAddress = P.objectAddress(state.widget)
    local controlAddress = P.objectAddress(control.widget)
    local worldAddress = controllerWorldAddress(state.controller)
    if widgetAddress == nil or controlAddress == nil or worldAddress == nil then
        return false
    end
    state.numberEdit = {
        control = control,
        windowSession = state.windowSession,
        worldAddress = worldAddress,
        widgetAddress = widgetAddress,
        controlAddress = controlAddress,
        buffer = tostring(control.value),
        replaceOnType = mode == "keyboard",
        mode = mode,
    }
    setNumberEditorText(control, control.value)
    syncNumberPresentation(control, mode ~= "controller")
    -- Pal Insight 1.8.0 used native Slate editing only for pointer activation.
    -- Keyboard and controller editing retain root focus and use the bounded
    -- settings-owned integer buffer.
    local focused
    if mode == "mouse" then
        focused = state.numberEditorOps.focusNumberEditorInput(control)
    else
        focused = focusNavigationRoot()
    end
    if focused ~= true then
        state.numberEdit = nil
        setNumberEditorText(control, control.value)
        syncNumberPresentation(control, false)
        return false
    end
    refreshRowDisplay(control)
    refreshTriggerSurfaces()
    return true
end

commitNumberEditor = function(control, source, commit)
    if type(control) ~= "table" or control.kind ~= "number" then return false end
    local edit = state.numberEdit
    if type(edit) ~= "table" or edit.control ~= control then return false end
    if edit.windowSession ~= state.windowSession
        or edit.worldAddress ~= controllerWorldAddress(state.controller)
        or edit.widgetAddress ~= P.objectAddress(state.widget)
        or edit.controlAddress ~= P.objectAddress(control.widget) then
        state.numberEdit = nil
        return false
    end
    local applied = true
    if commit ~= false then
        local raw = edit.mode == "mouse"
            and state.numberEditorOps.numberEditorRawText(control)
            or edit.buffer
        local parsed = tonumber(raw)
        if parsed ~= nil and math.floor(parsed) == parsed then
            parsed = math.max(control.minimum, math.min(control.maximum, parsed))
            state.numberEdit = nil
            applied = commitNumber(control, parsed, source)
        else
            state.numberEdit = nil
            applied = false
        end
    else
        state.numberEdit = nil
    end
    setNumberEditorText(control, control.value)
    syncNumberPresentation(control, false)
    focusNavigationRoot()
    refreshRowDisplay(control)
    refreshTriggerSurfaces()
    return applied
end

local function adjustNumberEditor(control, direction)
    local edit = state.numberEdit
    local raw = type(edit) == "table" and edit.control == control
        and (edit.mode == "mouse"
            and state.numberEditorOps.numberEditorRawText(control)
            or edit.buffer) or nil
    local parsed = tonumber(raw)
    local base = parsed ~= nil and math.floor(parsed) == parsed
        and parsed >= control.minimum and parsed <= control.maximum
        and parsed or control.value
    local target = math.max(control.minimum,
        math.min(control.maximum, base + direction))
    if type(edit) == "table" and edit.control == control then
        edit.buffer = tostring(target)
        edit.replaceOnType = true
        setNumberEditorText(control, target)
        syncNumberPresentation(control)
        refreshTriggerSurfaces()
        return true
    end
    return false
end

Deferred.deferInputClose = function(reason)
    if not state.open then return true end
    local generation = state.generation
    local windowSession = state.windowSession
    local pending = state.deferredInputClose
    if type(pending) == "table"
        and pending.generation == generation
        and pending.windowSession == windowSession then return true end
    state.deferredInputClose = {
        generation = generation,
        windowSession = windowSession,
        reason = tostring(reason or "input"),
    }
    state.deferredInputCloseCallback = state.deferredInputCloseCallback
        or function()
            local request = state.deferredInputClose
            state.deferredInputClose = nil
            if type(request) ~= "table" or not state.open
                or state.generation ~= request.generation
                or state.windowSession ~= request.windowSession then return end
            if request.reason == "gamepad-back" then
                SettingsUI.close("gamepad-back")
            else
                SettingsUI.close(request.reason)
            end
        end
    local scheduled = false
    if type(ExecuteInGameThreadWithDelay) == "function" then
        local ok, handle = pcall(ExecuteInGameThreadWithDelay, 0,
            state.deferredInputCloseCallback)
        scheduled = ok and handle ~= false
    end
    if not scheduled and type(ExecuteInGameThread) == "function" then
        local ok, result = pcall(ExecuteInGameThread,
            state.deferredInputCloseCallback)
        scheduled = ok and result ~= false
    end
    if not scheduled then
        state.deferredInputClose = nil
        log("settings input close could not be deferred")
    end
    -- Even if dispatch is unavailable, consume the owned input instead of
    -- closing inside the UMG callback and risking an invalid reflected reply.
    return true
end

local function previewKeyEvent(keyEventParam)
    if keyEventParam == nil then return nil end
    local ok, event = pcall(function() return keyEventParam:get() end)
    if not ok then event = keyEventParam end
    return event
end

local function previewKeyName(keyEvent)
    if keyEvent == nil then return nil end
    local ok, keyName = pcall(function()
        return P.nameString(keyEvent.Key.KeyName)
    end)
    return ok and type(keyName) == "string" and keyName or nil
end

local function previewModifierDown(keyEvent, modifier)
    if keyEvent == nil then return false end
    local directName = modifier == "control" and "IsControlDown" or "IsShiftDown"
    local ok, down = pcall(function() return keyEvent[directName](keyEvent) end)
    if ok and type(down) == "boolean" then return down end
    local modifiers
    ok = pcall(function()
        modifiers = keyEvent.ModifierKeysState or keyEvent.ModifierKeys
    end)
    if not ok or modifiers == nil then return false end
    local leftName = modifier == "control"
        and "bIsLeftControlDown" or "bIsLeftShiftDown"
    local rightName = modifier == "control"
        and "bIsRightControlDown" or "bIsRightShiftDown"
    local leftOk, left = pcall(function() return modifiers[leftName] end)
    local rightOk, right = pcall(function() return modifiers[rightName] end)
    return (leftOk and left == true) or (rightOk and right == true)
end

do
    local NUMBER_NATIVE_EDIT_KEYS = {
        Zero = true, One = true, Two = true, Three = true, Four = true,
        Five = true, Six = true, Seven = true, Eight = true, Nine = true,
        NumPadZero = true, NumPadOne = true, NumPadTwo = true,
        NumPadThree = true, NumPadFour = true, NumPadFive = true,
        NumPadSix = true, NumPadSeven = true, NumPadEight = true,
        NumPadNine = true,
        BackSpace = true, Delete = true, Home = true, End = true,
    }
    local function nativeNumberEditKeyAllowed(control, keyName, controlDown, shiftDown)
        if type(control) ~= "table" then return false end
        if controlDown == true then
            return shiftDown ~= true and keyName == "A"
        end
        if shiftDown == true then return false end
        if NUMBER_NATIVE_EDIT_KEYS[keyName] == true then return true end
        return (keyName == "Hyphen" or keyName == "Subtract")
            and (control.minimum or 0) < 0
    end
    state.numberEditorOps.nativeNumberEditKeyAllowed = nativeNumberEditKeyAllowed
end

handleNumberPreview = function(control, keyName, keyEvent, source)
    source = source or "preview"
    local controlDown = previewModifierDown(keyEvent, "control")
    local shiftDown = previewModifierDown(keyEvent, "shift")
    local edit = state.numberEdit
    if type(edit) ~= "table" or edit.control ~= control then return false end
    if edit.mode == "mouse" and state.numberEditorOps.nativeNumberEditKeyAllowed(
            control, keyName, controlDown, shiftDown) then
        FooterGuide.markInputDevice("keyboard")
        cancelNavigationRepeat()
        -- Preview remains unhandled so Slate can update the focused editor;
        -- duplicate global/actor observations are consumed here.
        return source ~= "preview"
    end
    local digit = NUMBER_KEY_DIGITS[keyName]
    if claimSynchronousNavigation(keyName, source) then return true end
    if digit ~= nil then
        if not controlDown and not shiftDown then
            local raw = edit.replaceOnType == true and digit
                or tostring(edit.buffer or "") .. digit
            local maxDigits = math.max(#tostring(math.abs(control.minimum or 0)),
                #tostring(math.abs(control.maximum or 0)))
            if #raw <= maxDigits then
                edit.buffer = raw
                edit.replaceOnType = false
                setNumberEditorText(control, raw)
            end
        end
        return true
    end
    if keyName == "BackSpace" or keyName == "Delete" then
        if not controlDown and not shiftDown then
            local clear = keyName == "Delete" or edit.replaceOnType == true
            local raw = clear and "" or tostring(edit.buffer or ""):sub(1, -2)
            edit.buffer = raw
            edit.replaceOnType = false
            setNumberEditorText(control, raw)
        end
        return true
    end
    if controlDown == true and shiftDown ~= true and keyName == "A" then
        edit.replaceOnType = true
        return true
    end
    if controlDown or shiftDown then return true end
    if not controlDown and not shiftDown
        and (keyName == "A" or keyName == "Left"
            or keyName == "Gamepad_DPad_Left"
            or keyName == "Gamepad_LeftStick_Left") then
        adjustNumberEditor(control, -1)
        if source ~= "repeat" then startNavigationRepeat(keyName, "gamepad") end
        return true
    end
    if not controlDown and not shiftDown
        and (keyName == "D" or keyName == "Right"
            or keyName == "Gamepad_DPad_Right"
            or keyName == "Gamepad_LeftStick_Right") then
        adjustNumberEditor(control, 1)
        if source ~= "repeat" then startNavigationRepeat(keyName, "gamepad") end
        return true
    end
    if keyName == "Enter" or keyName == "SpaceBar"
        or keyName == "Gamepad_FaceButton_Bottom" then
        commitNumberEditor(control, "number-commit", true)
        return true
    end
    if keyName == "Q" or keyName == "E"
        or keyName == "Gamepad_LeftShoulder"
        or keyName == "Gamepad_RightShoulder" then
        commitNumberEditor(control, "number-page-switch", true)
        local direction = (keyName == "Q"
            or keyName == "Gamepad_LeftShoulder") and -1 or 1
        local device = keyName:find("Gamepad_", 1, true) == 1
            and "gamepad" or "keyboard"
        return state.switchSettingsPage(direction, device)
    end
    if keyName == "W" or keyName == "Up" or keyName == "Tab"
        or keyName == "S" or keyName == "Down"
        or keyName == "Gamepad_DPad_Up"
        or keyName == "Gamepad_DPad_Down"
        or keyName == "Gamepad_LeftStick_Up"
        or keyName == "Gamepad_LeftStick_Down" then
        commitNumberEditor(control, "number-navigation", true)
        local direction = keyName == "Tab" and (shiftDown and -1 or 1)
            or (keyName == "W" or keyName == "Up"
            or keyName == "Gamepad_DPad_Up"
            or keyName == "Gamepad_LeftStick_Up") and -1 or 1
        local device = keyName:find("Gamepad_", 1, true) == 1
            and "gamepad" or "keyboard"
        local moved = moveFocus(direction,
            device)
        if moved and keyName ~= "Tab" then startNavigationRepeat(keyName, device) end
        return moved
    end
    if keyName == "Escape" or keyName == "Gamepad_FaceButton_Right" then
        return commitNumberEditor(control, "number-cancel", false)
    end
    return true
end

local function previewKeyHook(context, _geometryParam, keyEventParam)
    local ok, reply = pcall(function()
        if not state.open or not P.isValid(state.widget) then return nil end
        local owner = P.unwrap(context)
        if not P.isValid(owner)
            or P.objectAddress(owner) ~= P.objectAddress(state.widget) then return nil end
        local keyEvent = previewKeyEvent(keyEventParam)
        local keyName = previewKeyName(keyEvent)
        if type(keyName) ~= "string" then return nil end
        if selectorCapturing() then return nil end
        local gamepad = keyName:find("Gamepad_", 1, true) == 1
        local numberControl = focusedNumberControl()
        local handled
        if gamepad then
            handled = dispatchControllerPressed(keyName, "preview")
        elseif numberControl ~= nil then
            handled = handleNumberPreview(numberControl, keyName, keyEvent, "preview")
        else
            handled = handlePressed(keyName,
                "keyboard", "preview",
                previewModifierDown(keyEvent, "shift"))
        end
        if handled ~= true then return nil end
        local library = staticObject("/Script/UMG.Default__WidgetBlueprintLibrary")
        return library ~= nil and library:Handled() or nil
    end)
    if not ok then
        local signature = "preview:" .. tostring(reply)
        if signature ~= state.pollFailureSignature then
            state.pollFailureSignature = signature
            log("settings preview input failed: " .. tostring(reply))
        end
        return nil
    end
    return reply
end

local function hoveredWidget(widget)
    if not P.isValid(widget) then return false end
    local hovered = false
    pcall(function() hovered = widget:IsHovered() == true end)
    return hovered
end

local function isRootSettingControl(control)
    if type(control) ~= "table" or control.focusIndex == nil
        or control.passive == true then return false end
    return control.kind == "toggle" or control.kind == "choice"
        or SettingsUI.isItemPicker(control)
        or control.kind == "number" or control.kind == "shortcut"
end

local function pointerControlHovered(control)
    if not isRootSettingControl(control) then return false end
    if control.kind == "number" then
        return hoveredWidget(control.displayButton)
            or hoveredWidget(control.widget)
    end
    return hoveredWidget(control.widget)
end

local function hoveredRootPointerControl()
    if not state.open or (state.lifecycle ~= "open"
        and state.lifecycle ~= "recovering")
        or state.releaseNotesOpen == true or state.aboutOpen == true
        or state.activeChoice ~= nil then return nil end
    for _, control in ipairs(state.controls or {}) do
        if isRootSettingControl(control) and pointerControlHovered(control) then
            return control
        end
    end
    for _, control in ipairs(state.controls or {}) do
        if isRootSettingControl(control)
            and hoveredWidget(control.rowFrame) then return control end
    end
    return nil
end

local function promoteHoveredRootSelection()
    local control = hoveredRootPointerControl()
    if control == nil then return false end
    cancelNavigationRepeat()
    FooterGuide.markInputDevice("mouse")
    state.focusIndex = control.focusIndex
    return true
end

local function hoveredPointerAction()
    if not state.open or (state.lifecycle ~= "open"
        and state.lifecycle ~= "recovering") then return nil end
    if state.releaseNotesOpen == true then
        for index, record in ipairs(state.releaseNotesPickerButtons or {}) do
            if hoveredWidget(record.widget) then
                return { scope = "release-notes-version", index = index, owner = record }
            end
        end
        for index, record in ipairs(state.releaseNotesButtons or {}) do
            if hoveredWidget(record.widget) then
                return { scope = "release-notes", index = index, owner = record }
            end
        end
        return nil
    end
    if state.aboutOpen == true then
        if state.aboutPreviewOpen == true then
            if hoveredWidget(state.aboutPreviewCloseWidget) then
                return { scope = "about-preview" }
            end
            return nil
        end
        if state.aboutRosterOpen == true then
            local closeWidget = (state.aboutRosterCloseWidgets or {})[
                state.aboutRosterMode]
            if hoveredWidget(closeWidget) then
                return {
                    scope = "about-roster",
                    owner = state.aboutRosterMode,
                }
            end
            return nil
        end
        for index, action in ipairs(state.aboutActions or {}) do
            if hoveredWidget(action.widget) then
                return { scope = "about", index = index, owner = action }
            end
        end
        return nil
    end
    if state.activeChoice ~= nil then
        local control = state.activeChoice
        for index, option in ipairs(state.modalOptions or {}) do
            if control.labels[index] ~= nil and hoveredWidget(option.widget) then
                return { scope = "choice", index = index, owner = control }
            end
        end
        return nil
    end
    if hoveredWidget(state.settingsTabPreviousButton) then
        return { scope = "settings-tab-shift", direction = -1,
            owner = state.settingsTabPreviousButton }
    end
    if hoveredWidget(state.settingsTabNextButton) then
        return { scope = "settings-tab-shift", direction = 1,
            owner = state.settingsTabNextButton }
    end
    for index, record in ipairs(state.settingsTabButtons or {}) do
        if hoveredWidget(record.widget) then
            return { scope = "settings-tab", index = index, owner = record }
        end
    end
    for _, control in ipairs(state.controls or {}) do
        local pointerHovered = control.kind == "number"
            and (hoveredWidget(control.displayButton)
                or hoveredWidget(control.widget))
            or hoveredWidget(control.widget)
        if pointerHovered and control.kind ~= "toggle"
            and control.kind ~= "shortcut" and control.passive ~= true then
            return { scope = "root", owner = control }
        end
    end
    return nil
end

local function rememberPointerAction(action)
    if type(action) ~= "table" then return nil end
    action.generation = state.generation
    action.windowSession = state.windowSession
    state.pointerAction = action
    return action
end

local function pointerActionIsCurrent(action)
    if type(action) ~= "table" or not state.open
        or (state.lifecycle ~= "open" and state.lifecycle ~= "recovering")
        or action.generation ~= state.generation
        or action.windowSession ~= state.windowSession then return false end
    if action.scope == "about-preview" then
        return state.aboutOpen == true and state.aboutPreviewOpen == true
    end
    if action.scope == "release-notes-version" then
        return state.releaseNotesOpen == true
            and (state.releaseNotesPickerButtons or {})[action.index] == action.owner
    end
    if action.scope == "release-notes" then
        return state.releaseNotesOpen == true
            and (state.releaseNotesButtons or {})[action.index] == action.owner
    end
    if action.scope == "about-roster" then
        return state.aboutOpen == true and state.aboutRosterOpen == true
            and action.owner == state.aboutRosterMode
    end
    if action.scope == "about" then
        return state.aboutOpen == true and state.aboutPreviewOpen ~= true
            and state.aboutRosterOpen ~= true
            and (state.aboutActions or {})[action.index] == action.owner
    end
    if action.scope == "choice" then
        return state.releaseNotesOpen ~= true and state.aboutOpen ~= true
            and state.activeChoice == action.owner
            and action.owner.labels[action.index] ~= nil
    end
    if action.scope == "settings-tab" then
        return state.releaseNotesOpen ~= true and state.aboutOpen ~= true
            and state.activeChoice == nil
            and (state.settingsTabButtons or {})[action.index] == action.owner
    end
    if action.scope == "settings-tab-shift" then
        return state.releaseNotesOpen ~= true and state.aboutOpen ~= true
            and state.activeChoice == nil
            and (action.direction == -1
                and action.owner == state.settingsTabPreviousButton
                or action.direction == 1
                and action.owner == state.settingsTabNextButton)
    end
    if action.scope == "root" and state.releaseNotesOpen ~= true
        and state.aboutOpen ~= true
        and state.activeChoice == nil then
        for _, control in ipairs(state.controls or {}) do
            if control == action.owner then return true end
        end
    end
    return false
end

local function capturePointerAction()
    local action = hoveredPointerAction()
    if action == nil then
        state.pointerAction = nil
        return nil
    end
    return rememberPointerAction(action)
end

local function aboutPointerCloseMode(action)
    if type(action) ~= "table" then return nil end
    if action.scope == "release-notes-version" then
        return "release-notes-select"
    end
    if action.scope == "about-preview" then return "preview" end
    if action.scope == "about-roster" then return "roster" end
    if action.scope == "about" and type(action.owner) == "table"
        and action.owner.kind == "close" then return "about" end
    if action.scope == "release-notes" and type(action.owner) == "table"
        and action.owner.kind == "close" then return "release-notes" end
    return nil
end

local function queueAboutPointerClose(action)
    local mode = aboutPointerCloseMode(action)
    if mode == nil then return false end
    state.pendingAboutPointerClose = {
        mode = mode,
        rosterMode = mode == "roster" and action.owner or nil,
        selectionIndex = mode == "release-notes-select" and action.index or nil,
        generation = state.generation,
        windowSession = state.windowSession,
        aboutRevision = state.aboutRevision,
        releaseNotesRevision = state.releaseNotesRevision,
        widgetAddress = P.objectAddress(state.widget),
        controllerAddress = P.objectAddress(state.controller),
        worldAddress = controllerWorldAddress(state.controller),
    }
    return true
end

local function pendingAboutPointerCloseIsCurrent(record)
    if type(record) ~= "table" or not state.open
        or state.lifecycle ~= "open"
        or record.generation ~= state.generation
        or record.windowSession ~= state.windowSession
        or record.widgetAddress == nil
        or record.widgetAddress ~= P.objectAddress(state.widget)
        or record.controllerAddress == nil
        or record.controllerAddress ~= P.objectAddress(state.controller)
        or record.worldAddress == nil
        or record.worldAddress ~= controllerWorldAddress(state.controller)
        then return false end
    if record.mode == "release-notes"
        or record.mode == "release-notes-select" then
        return state.releaseNotesOpen == true
            and record.releaseNotesRevision == state.releaseNotesRevision
    end
    if record.aboutRevision ~= state.aboutRevision then return false end
    if state.aboutOpen ~= true then return false end
    if record.mode == "preview" then
        return state.aboutPreviewOpen == true
    end
    if record.mode == "roster" then
        return state.aboutRosterOpen == true
            and record.rosterMode == state.aboutRosterMode
    end
    return record.mode == "about" and state.aboutPreviewOpen ~= true
        and state.aboutRosterOpen ~= true
end

local function drainPendingAboutPointerClose()
    local record = state.pendingAboutPointerClose
    if type(record) ~= "table" then return false end
    state.pendingAboutPointerClose = nil
    if not pendingAboutPointerCloseIsCurrent(record) then return false end
    FooterGuide.markInputDevice("mouse")
    if record.mode == "preview" then return closeAboutPreview(true) end
    if record.mode == "roster" then return closeAboutRoster(true) end
    if record.mode == "release-notes" then return state.closeReleaseNotesModal(true) end
    if record.mode == "release-notes-select" then
        return Deferred.selectReleaseNotesVersion(record.selectionIndex)
    end
    return closeAboutModal(true)
end

local function refreshInputFocusVisuals()
    if type(state.shortcutControl) == "table" then
        refreshShortcutDisplay(state.shortcutControl, selectorCapturing())
    end
    for _, control in ipairs(state.controls or {}) do
        if control.kind == "toggle" then refreshToggleDisplay(control) end
        refreshRowDisplay(control)
    end
    refreshTriggerSurfaces()
end

local function activateHoveredDirectAction()
    if not state.open then return false end
    local selectionHandled = promoteHoveredRootSelection()
    local cached = state.pointerAction
    local action = capturePointerAction() or cached
    if not pointerActionIsCurrent(action) then
        state.pointerAction = nil
        if selectionHandled then refreshInputFocusVisuals() end
        return selectionHandled
    end
    cancelNavigationRepeat()
    state.pointerAction = nil
    if queueAboutPointerClose(action) then return true end
    FooterGuide.markInputDevice("mouse")
    local handled = false
    if action.scope == "release-notes-version" then
        state.releaseNotesFocusPane = 1
        handled = Deferred.selectReleaseNotesVersion(action.index)
    elseif action.scope == "release-notes" then
        state.releaseNotesFocusPane = tonumber(action.owner.navPane) or 3
        handled = state.activateReleaseNotesAction()
    elseif action.scope == "about-preview" then
        handled = closeAboutPreview(true)
    elseif action.scope == "about-roster" then
        handled = closeAboutRoster(true)
    elseif action.scope == "about" then
        state.aboutFocusIndex = action.index
        state.aboutPreferredColumn = tonumber(action.owner.navColumn) or 1
        handled = activateAboutAction()
    elseif action.scope == "choice" then
        state.modalIndex = action.index
        handled = commitNestedModalSelection("mouse")
    elseif action.scope == "settings-tab" then
        handled = state.showSettingsPage(action.owner.pageId, "mouse")
    elseif action.scope == "settings-tab-shift" then
        handled = state.switchSettingsPage(action.direction, "mouse")
    elseif action.scope == "root" then
        local control = action.owner
        if control.kind == "choice" or SettingsUI.isItemPicker(control)
            or control.kind == "number"
            or control.kind == "shortcut" or control.kind == "toggle" then
            state.focusIndex = control.focusIndex
        end
        local returnFocusIndex = state.focusIndex
        local numberEdit = state.numberEdit
        local activeNumber = control.kind == "number"
            and type(numberEdit) == "table" and numberEdit.control == control
        if control.kind == "choice" then
            state.choiceReturnFocusIndex = returnFocusIndex
            handled = openChoiceModal(control)
            if handled ~= true then state.choiceReturnFocusIndex = nil end
        elseif control.kind == "number" and activeNumber then
            handled = true
        else
            handled = activateControl(control, "mouse", returnFocusIndex)
        end
    end
    if handled == true or selectionHandled then refreshInputFocusVisuals() end
    return handled == true or selectionHandled
end

local function keyUpHook(context, _geometryParam, keyEventParam)
    local ok, reply = pcall(function()
        local keyName = previewKeyName(previewKeyEvent(keyEventParam))
        if type(keyName) ~= "string" then return nil end
        if not state.open then
            local ownedUntil = tonumber(state.trailingReleaseUntil[keyName]) or 0.0
            if ownedUntil <= os.clock() then return nil end
            state.trailingReleaseUntil[keyName] = nil
            if keyName == "Escape" then
                InputOwner.releaseEscapeClose("focused-key-up")
            end
            local library = staticObject("/Script/UMG.Default__WidgetBlueprintLibrary")
            return library ~= nil and library:Handled() or nil
        end
        if not P.isValid(state.widget) then return nil end
        local owner = P.unwrap(context)
        if not P.isValid(owner)
            or P.objectAddress(owner) ~= P.objectAddress(state.widget) then return nil end
        if selectorCapturing() then return nil end
        if keyName:find("Gamepad_", 1, true) == 1 then
            dispatchControllerReleased(keyName, "preview")
        else
            handleReleased(keyName)
        end
        local library = staticObject("/Script/UMG.Default__WidgetBlueprintLibrary")
        return library ~= nil and library:Handled() or nil
    end)
    if not ok then
        local signature = "key-up:" .. tostring(reply)
        if signature ~= state.pollFailureSignature then
            state.pollFailureSignature = signature
            log("settings key-up input failed: " .. tostring(reply))
        end
        return nil
    end
    return reply
end

local function installPreviewKeyHook()
    if state.previewKeyHookReady then return true end
    if type(RegisterHook) ~= "function"
        or staticObject(PREVIEW_KEY_FUNCTION) == nil then return false end
    local ok, preId, postId = pcall(RegisterHook,
        PREVIEW_KEY_FUNCTION, previewKeyHook)
    if not ok or type(preId) ~= "number" then return false end
    state.previewKeyHookReady = true
    state.previewKeyHookPreId = preId
    state.previewKeyHookPostId = postId
    return true
end

local function installKeyUpHook()
    if state.keyUpHookReady then return true end
    if type(RegisterHook) ~= "function"
        or staticObject(KEY_UP_FUNCTION) == nil then return false end
    local ok, preId, postId = pcall(RegisterHook, KEY_UP_FUNCTION, keyUpHook)
    if not ok or type(preId) ~= "number" then return false end
    state.keyUpHookReady = true
    state.keyUpHookPreId = preId
    state.keyUpHookPostId = postId
    return true
end

local function ensureSettingsCursor()
    if not state.open or not P.isValid(state.controller) then return false end
    local visible = false
    local ok = pcall(function() visible = state.controller.bShowMouseCursor == true end)
    if ok and visible then return true end
    local repaired, cursorVisible = pcall(function()
        state.controller.bShowMouseCursor = true
        return state.controller.bShowMouseCursor == true
    end)
    return repaired == true and cursorVisible == true
end

local function settingsPointerOwner(context)
    if not state.open or (state.lifecycle ~= "open"
        and state.lifecycle ~= "recovering")
        or not P.isValid(state.widget) then return false end
    local owner = P.unwrap(context)
    return P.isValid(owner)
        and P.objectAddress(owner) == P.objectAddress(state.widget)
end

local function mouseMoveHook(context)
    if not settingsPointerOwner(context) then return nil end
    cancelNavigationRepeat()
    local edit = state.numberEdit
    if type(edit) == "table" and edit.mode == "controller"
        and type(edit.control) == "table" then
        commitNumberEditor(edit.control, "number-pointer", true)
    end
    local changedDevice = FooterGuide.markInputDevice("mouse")
    capturePointerAction()
    ensureSettingsCursor()
    if changedDevice then refreshInputFocusVisuals() end
    return nil
end

local function mouseLeaveHook(context)
    if not settingsPointerOwner(context) then return nil end
    cancelNavigationRepeat()
    state.pointerAction = nil
    local changedDevice = FooterGuide.markInputDevice("mouse")
    ensureSettingsCursor()
    local edit = state.numberEdit
    if type(edit) == "table" and edit.mode == "mouse"
        and type(edit.control) == "table" then
        commitNumberEditor(edit.control, "number-pointer-leave", true)
    else
        focusNavigationRoot()
    end
    if changedDevice then refreshInputFocusVisuals() end
    return nil
end

local function installPointerHooks()
    if type(RegisterHook) ~= "function" then return false end
    if not state.mouseMoveHookReady then
        if staticObject(MOUSE_MOVE_FUNCTION) == nil then return false end
        local ok, preId, postId = pcall(RegisterHook,
            MOUSE_MOVE_FUNCTION, mouseMoveHook)
        if not ok or type(preId) ~= "number" then return false end
        state.mouseMoveHookReady = true
        state.mouseMoveHookPreId = preId
        state.mouseMoveHookPostId = postId
    end
    if not state.mouseLeaveHookReady then
        if staticObject(MOUSE_LEAVE_FUNCTION) == nil then return false end
        local ok, preId, postId = pcall(RegisterHook,
            MOUSE_LEAVE_FUNCTION, mouseLeaveHook)
        if not ok or type(preId) ~= "number" then return false end
        state.mouseLeaveHookReady = true
        state.mouseLeaveHookPreId = preId
        state.mouseLeaveHookPostId = postId
    end
    return true
end

local function installSelectorSelectedKeyHook()
    if state.selectorSelectedKeyHookReady then return true end
    local path = "/Script/UMG.InputKeySelector:SetSelectedKey"
    if type(RegisterHook) ~= "function" or staticObject(path) == nil then
        return false
    end
    local ok, preId, postId = pcall(RegisterHook, path, selectorSelectedKeyHook)
    if not ok or type(preId) ~= "number" then return false end
    state.selectorSelectedKeyHookReady = true
    state.selectorSelectedKeyHookPreId = preId
    state.selectorSelectedKeyHookPostId = postId
    return true
end

local function pollControls()
    if not state.open then return end
    if drainPendingAboutPointerClose() then return end
    pollSteamVote()
    if state.pendingDownvoteAcknowledgement == true
        and state.activeChoice == nil then
        if Deferred.openDownvoteAcknowledgement() then
            state.pendingDownvoteAcknowledgement = false
            return
        end
    end
    if type(state.steamVoteControl) == "table"
        and state.steamVoteControl.passive == true
        and state.steamVoteControl.focusIndex == state.focusIndex then
        moveFocus(1, state.lastInputDevice)
    end
    if state.steamVotePalVisualReady ~= true then
        refreshSteamVotePalVisuals()
    end
    if state.releaseNotesOpen == true then
        state.updateReleaseNotesVisuals()
        return
    end
    if state.aboutOpen == true then
        refreshTriggerSurfaces()
        return
    end
    if state.activeChoice ~= nil then
        refreshTriggerSurfaces()
        return
    end
    commitNativeToggleChanges("toggle-poll")
    for _, control in ipairs(state.controls) do
        if control.kind == "shortcut" then
            local chord = selectedChord(control.widget)
            local signature = chordSignature(chord)
            if chord ~= nil and signature ~= control.last then
                local previous = control.last
                local reserved = chord.Key == "F6" or chord.Key == "Escape"
                    or chord.Key == "LeftMouseButton"
                if reserved then
                    InputOwner.discardPendingKey(chord.Key)
                    local persisted = {
                        Key = state.config.Key,
                        Shift = state.config.Shift,
                        Ctrl = state.config.Ctrl,
                        Alt = state.config.Alt,
                    }
                    setSelectorChord(control.widget, persisted)
                    control.last = chordSignature(persisted)
                    control.selecting = false
                    scheduleShortcutFocusRestore(control)
                else
                    control.last = signature
                    if not applyControlPatch({
                        Key = chord.Key,
                        Shift = chord.Shift,
                        Ctrl = chord.Ctrl,
                        Alt = chord.Alt,
                        }, "shortcut") then
                        control.last = previous
                        setSelectorChord(control.widget, {
                            Key = state.config.Key,
                            Shift = state.config.Shift,
                            Ctrl = state.config.Ctrl,
                            Alt = state.config.Alt,
                        })
                        refreshShortcutConflictWarning()
                    end
                end
            end
            local selecting = false
            if P.isValid(control.widget) then
                local selectingOk, selectingValue = pcall(function()
                    return control.widget:GetIsSelectingKey()
                end)
                selecting = selectingOk and selectingValue == true
            end
            local wasSelecting = control.selecting == true
            if selecting and not wasSelecting then
                if state.lastInputDevice == "mouse" then
                    state.focusIndex = control.focusIndex
                    control.pointerReturnFocusIndex = control.focusIndex
                else
                    control.pointerReturnFocusIndex = nil
                end
            end
            control.selecting = selecting
            if selecting and type(state.numberEdit) == "table"
                and type(state.numberEdit.control) == "table" then
                commitNumberEditor(
                    state.numberEdit.control, "number-navigation", true)
            end
            if wasSelecting and not selecting then
                scheduleShortcutFocusRestore(control)
            end
            refreshShortcutDisplay(control, selecting)
        end
    end
    for _, control in ipairs(state.controls) do
        if control.kind == "toggle" then refreshToggleDisplay(control) end
        refreshRowDisplay(control)
    end
    refreshTriggerSurfaces()
end

local function pollHostedController()
    if state.mode ~= "hosted"
        or type(state.readHostedControllerSnapshot) ~= "function" then
        return false
    end
    local ok, snapshot = pcall(state.readHostedControllerSnapshot)
    if not ok or type(snapshot) ~= "table" then
        -- Shared scalar publication is revision-guarded, so one read may land
        -- between the host's field writes. Keep an already established owner
        -- instead of briefly enabling a second controller route.
        return state.controllerInputOwner == "host-native"
    end
    local connected = snapshot.connected == true
    local buttons = connected and math.floor(tonumber(snapshot.buttons) or 0) or 0
    local edgeRevision = math.floor(tonumber(snapshot.edgeRevision) or 0)
    local pressedEdges = math.floor(tonumber(snapshot.pressedEdges) or 0)
    local releasedEdges = math.floor(tonumber(snapshot.releasedEdges) or 0)
    if not connected then
        if state.controllerInputOwner == "host-native" then
            state.controllerInputOwner = nil
            state.controllerDown = {}
            state.axisValues = { x = 0.0, y = 0.0 }
            state.axisArmed = { x = true, y = true }
            cancelNavigationRepeat()
        end
        return false
    end
    if controllerInput.selectOwner("host-native", snapshot) then
        state.lastHostedControllerEdgeRevision = edgeRevision
        if type(state.ackHostedControllerSnapshot) == "function" then
            pcall(state.ackHostedControllerSnapshot, edgeRevision)
        end
        return true
    end
    local previousEdgeRevision = state.lastHostedControllerEdgeRevision
    local consumeEdges = previousEdgeRevision == nil
        or edgeRevision > previousEdgeRevision
    for _, binding in ipairs(state.hostedControllerButtons) do
        local down = (buttons & binding.mask) ~= 0
        local wasDown = state.controllerDown[binding.key] == true
        local pressed = consumeEdges and (pressedEdges & binding.mask) ~= 0
        local released = consumeEdges and (releasedEdges & binding.mask) ~= 0
        if pressed and released then
            if down then
                if wasDown then
                    dispatchControllerReleased(binding.key, "host-native")
                end
                dispatchControllerPressed(binding.key, "host-native")
            elseif wasDown then
                dispatchControllerReleased(binding.key, "host-native")
            else
                dispatchControllerPressed(binding.key, "host-native")
                dispatchControllerReleased(binding.key, "host-native")
            end
        elseif pressed then
            dispatchControllerPressed(binding.key, "host-native")
        elseif released then
            dispatchControllerReleased(binding.key, "host-native")
        end
        if down then dispatchControllerPressed(binding.key, "host-native")
        else dispatchControllerReleased(binding.key, "host-native") end
    end
    if consumeEdges then state.lastHostedControllerEdgeRevision = edgeRevision end
    handleAxis("x", tonumber(snapshot.leftX) or 0, "host-native")
    handleAxis("y", tonumber(snapshot.leftY) or 0, "host-native")
    if type(state.ackHostedControllerSnapshot) == "function" then
        pcall(state.ackHostedControllerSnapshot, edgeRevision)
    end
    -- A host without an XInput-visible pad must not suppress UE's cooked and
    -- PlayerController fallbacks (for example, a non-XInput controller).
    return connected
end

state.pollNativeController = function()
    if state.mode == "hosted" or not InputOwner.nativeControllerActive() then
        return false
    end
    local snapshot, failure = InputOwner.readNativeControllerSnapshot()
    if type(snapshot) ~= "table" then
        log("native settings controller failed: " .. tostring(failure))
        SettingsUI.close("native-controller-failure")
        return true
    end
    local connected = snapshot.connected == true
    local buttons = connected and math.floor(tonumber(snapshot.buttons) or 0) or 0
    if not connected then
        if state.controllerInputOwner == "standalone-native" then
            state.controllerInputOwner = nil
            state.controllerDown = {}
            state.axisValues = { x = 0.0, y = 0.0 }
            state.axisArmed = { x = true, y = true }
            cancelNavigationRepeat()
        end
        state.nativeControllerInitialized = false
        return false
    end
    if state.nativeControllerInitialized ~= true
        or controllerInput.selectOwner("standalone-native", snapshot) then
        if state.controllerInputOwner ~= "standalone-native" then
            controllerInput.selectOwner("standalone-native", snapshot)
        end
        state.nativeControllerInitialized = true
        return true
    end
    for _, binding in ipairs(state.hostedControllerButtons) do
        local down = (buttons & binding.mask) ~= 0
        if down then dispatchControllerPressed(binding.key, "standalone-native")
        else dispatchControllerReleased(binding.key, "standalone-native") end
    end
    handleAxis("x", tonumber(snapshot.leftX) or 0.0, "standalone-native")
    handleAxis("y", tonumber(snapshot.leftY) or 0.0, "standalone-native")
    return true
end

local function pollStandaloneController()
    if pollHostedController() then return end
    if state.pollNativeController() then return end
    if InputOwner.cookedInputActive() then
        controllerInput.selectOwner("actor", {})
        return
    end
    if state.controllerInputOwner ~= "poll" then
        local x, y = 0.0, 0.0
        if P.isValid(state.controller) and type(FName) == "function" then
            pcall(function()
                x = tonumber(state.controller:GetInputAnalogKeyState(
                    { KeyName = FName("Gamepad_LeftX") })) or 0.0
                y = tonumber(state.controller:GetInputAnalogKeyState(
                    { KeyName = FName("Gamepad_LeftY") })) or 0.0
            end)
        end
        controllerInput.selectOwner("poll", { leftX = x, leftY = y })
        for _, keyName in ipairs(state.controllerPollKeys) do
            state.controllerDown[keyName] = inputKeyDown(
                state.controller, keyName) == true
        end
        return
    end
    for _, keyName in ipairs(state.controllerPollKeys) do
        local down = inputKeyDown(state.controller, keyName)
        if down == true then
            dispatchControllerPressed(keyName, "poll")
        elseif down == false then
            dispatchControllerReleased(keyName, "poll")
        end
    end
    if P.isValid(state.controller) and type(FName) == "function" then
        local x, y
        pcall(function()
            x = state.controller:GetInputAnalogKeyState({ KeyName = FName("Gamepad_LeftX") })
            y = state.controller:GetInputAnalogKeyState({ KeyName = FName("Gamepad_LeftY") })
        end)
        if tonumber(x) ~= nil then handleAxis("x", x, "poll") end
        if tonumber(y) ~= nil then handleAxis("y", y, "poll") end
    end
end

local function safePollPhase(name, callback)
    local ok, errorMessage = pcall(callback)
    if ok then return true end
    local signature = tostring(name) .. ":" .. tostring(errorMessage)
    if signature ~= state.pollFailureSignature then
        state.pollFailureSignature = signature
        log("settings control phase failed: " .. signature)
    end
    return false
end

local function pollSettingsLifecycle()
    if not state.open then return end
    local now = os.clock()
    ensureSettingsCursor()
    if state.lifecycle == "recovering" then
        if (tonumber(state.closeRecoveryDeadline) or 0.0) > 0.0
            and now >= state.closeRecoveryDeadline then
            local closedMode = state.mode
            local widget = state.widget
            local controller = state.controller
            local current = P.currentController()
            local hostUnavailable = state.closeRecoveryReason == "host-unavailable"
                or state.closeRecoveryReason == "context-changed"
                or not P.isValid(current) or not windowCacheMatches(current)
            if InputOwner.emergencyRelease({ hostUnavailable = hostUnavailable }) then
                completeClose(closedMode, "watchdog", widget, controller)
            else
                state.closeRecoveryDeadline = now + 0.5
                state.closeRecoveryRetryAt = now + 0.25
            end
            return
        end
        if now >= (tonumber(state.closeRecoveryRetryAt) or 0.0) then
            SettingsUI.close("recovery-retry")
        end
        return
    end
    if now < (tonumber(state.nextContextCheckAt) or 0.0) then return end
    state.nextContextCheckAt = now + 0.25
    local gameplayContext = P.currentGameplayContext()
    local controller = type(gameplayContext) == "table"
        and gameplayContext.controller or nil
    if not P.isValid(controller) or not windowCacheMatches(controller) then
        SettingsUI.close("context-changed")
        return
    end
end

local schedulePoll
local stopPoll
state.pollGameThreadCallback = function()
    if not state.open or state.generation ~= state.pollGeneration then
        stopPoll()
        return
    end
    state.pollLastTickAt = os.clock()
    safePollPhase("lifecycle", pollSettingsLifecycle)
    safePollPhase("input", InputOwner.drainPendingInput)
    safePollPhase("controls", pollControls)
    safePollPhase("controller", pollStandaloneController)
    safePollPhase("navigation-repeat", pollNavigationRepeat)
end

function SettingsUI.ensurePollAlive()
    if not state.open then return true end
    local now = os.clock()
    local stale = state.pollLastTickAt > 0.0
        and now - state.pollLastTickAt > math.max(0.25, POLL_MS / 250.0)
    if stale and state.pollLoopHandle ~= nil then
        if not stopPoll() then return false end
    end
    return schedulePoll()
end

schedulePoll = function()
    if not state.open or type(LoopInGameThreadWithDelay) ~= "function" then
        return false
    end
    if state.pollLoopHandle ~= nil then
        local valid = true
        if type(IsValidDelayedActionHandle) == "function" then
            local checked, result = pcall(
                IsValidDelayedActionHandle, state.pollLoopHandle)
            valid = checked and result == true
        end
        if valid then
            state.pollPending = true
            state.pollGeneration = state.generation
            return true
        end
        state.pollLoopHandle = nil
        state.pollPending = false
    end
    state.pollPending = true
    state.pollGeneration = state.generation
    local started, handleOrError = pcall(LoopInGameThreadWithDelay,
        POLL_MS, state.pollGameThreadCallback)
    if not started or type(handleOrError) ~= "number" then
        state.pollPending = false
        state.pollLoopHandle = nil
        return false
    end
    state.pollLoopHandle = handleOrError
    return true
end

stopPoll = function()
    local handle = state.pollLoopHandle
    local stopped = handle == nil
    if not stopped and type(CancelDelayedAction) == "function" then
        local cancelled, result = pcall(CancelDelayedAction, handle)
        stopped = cancelled and result == true
    end
    if not stopped and type(IsValidDelayedActionHandle) == "function" then
        local checked, valid = pcall(IsValidDelayedActionHandle, handle)
        stopped = checked and valid == false
    end
    if stopped then
        state.pollLoopHandle = nil
        state.pollPending = false
    end
    return stopped
end

local function registerFocusable(control, scrollTarget, triggerRecord)
    control.scrollTarget = scrollTarget
    control.pageId = state.buildingPageId
    state.allFocusEntries[#(state.allFocusEntries or {}) + 1] = control
    control.focusIndex = #(state.focusEntries or {}) + 1
    state.focusEntries[control.focusIndex] = control
    if type(triggerRecord) == "table" then triggerRecord.control = control end
    if P.isValid(control.widget) then
        pcall(function()
            for direction = 0, 5 do
                control.widget:SetNavigationRule(direction, 3)
            end
        end)
    end
    return control
end

state.rebuildSettingsFocusEntries = function()
    local entries = {}
    for _, control in ipairs(state.allFocusEntries or {}) do
        if control.hiddenFromFocus ~= true
            and (control.pageId == nil
                or control.pageId == state.activeSettingsPage) then
            entries[#entries + 1] = control
            control.focusIndex = #entries
        else
            control.focusIndex = nil
        end
    end
    state.focusEntries = entries
    state.focusIndex = math.max(1, math.min(
        tonumber(state.focusIndex) or 1, #entries))
    return #entries > 0
end

state.showSettingsPage = function(pageId, device)
    if type(state.settingsPages) ~= "table"
        or not P.isValid(state.settingsPages[pageId]) then return false end
    local previous = state.activeSettingsPage
    if previous == pageId then return true end
    if type(state.numberEdit) == "table" and commitNumberEditor ~= nil then
        commitNumberEditor(state.numberEdit.control, "page-switch", true)
    end
    if P.isValid(state.scroll) and previous ~= nil then
        pcall(function()
            state.settingsPageScrollOffsets[previous] =
                tonumber(state.scroll:GetScrollOffset()) or 0.0
        end)
    end
    state.activeSettingsPage = pageId
    state.pointerAction = nil
    for id, page in pairs(state.settingsPages) do
        if P.isValid(page) then
            page:SetVisibility(id == pageId and VIS_VISIBLE or VIS_COLLAPSED)
        end
    end
    state.rebuildSettingsFocusEntries()
    state.focusIndex = 1
    if P.isValid(state.scroll) then
        pcall(function()
            state.scroll:SetScrollOffset(tonumber(
                state.settingsPageScrollOffsets[pageId]) or 0.0)
        end)
    end
    FooterGuide.markInputDevice(device or state.lastInputDevice)
    focusNavigationRoot()
    refreshInputFocusVisuals()
    return true
end

state.switchSettingsPage = function(direction, device)
    local pages = state.settingsPageOrder or {}
    if #pages < 1 then return false end
    local index = 1
    for candidate, pageId in ipairs(pages) do
        if pageId == state.activeSettingsPage then index = candidate break end
    end
    index = ((index - 1 + (tonumber(direction) or 1)) % #pages) + 1
    return state.showSettingsPage(pages[index], device)
end

local function addToggleRow(tree, body, key, label, alternate, indent)
    local row = makeRow(tree, body, label, "toggle", indent)
    local toggle = construct(tree, "/Script/UMG.CheckBox")
    local box = construct(tree, "/Script/UMG.SizeBox")
    if row == nil or toggle == nil or box == nil then return false end
    pcall(function()
        toggle.bIsFocusable = true
        styleToggle(toggle)
        toggle:SetIsChecked(state.config[key] == true)
        box:SetWidthOverride(SIZE.checkbox)
        box:SetHeightOverride(SIZE.control)
        local toggleSlot = box:AddChild(toggle)
        align(toggleSlot, ALIGN_FILL, ALIGN_FILL)
    end)
    addControlToRow(row.row, box, 0)
    local control = {
        kind = "toggle", key = key, widget = toggle,
        rowFrame = row.surface,
        last = state.config[key] == true,
    }
    registerFocusable(control, row.box)
    state.controls[#state.controls + 1] = control
    refreshToggleDisplay(control)
    return true
end

local function addChoiceRow(tree, body, key, label, values, labels, alternate,
        indent)
    local row = makeRow(tree, body, label, "choice", indent)
    if row == nil then return false end
    local index = 1
    for candidate, value in ipairs(values) do
        if value == state.config[key] then index = candidate end
    end
    local trigger = makeTrigger(tree, labels[index], SIZE.choice, false, "▼")
    if trigger == nil then return false end
    addControlToRow(row.row, trigger.box, 0)
    local control = {
        kind = "choice", key = key, widget = trigger.widget,
        text = trigger.text, values = values, labels = labels, index = index,
        label = label, rowFrame = row.surface,
    }
    registerFocusable(control, row.box, trigger)
    state.controls[#state.controls + 1] = control
    return true
end

Deferred.addHelperText = function(tree, body, value)
    local helper = makeText(tree, value, 12, COLORS.muted, TEXT_LEFT)
    if helper == nil then return false end
    setTextWrap(helper, math.max(1.0, state.contentWidth - 52.0))
    local ok = pcall(function()
        helper:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        local slot = body:AddChild(helper)
        setPadding(slot, 36, 2, 16, 8)
        align(slot, ALIGN_FILL, ALIGN_FILL)
    end)
    return ok == true
end

Deferred.addNoticeText = function(tree, body, value)
    local notice = makeText(tree, value, 15, COLORS.actionWarning, TEXT_LEFT)
    if notice == nil then return false end
    setTextWrap(notice, math.max(1.0, state.contentWidth - 28.0))
    local ok = pcall(function()
        notice:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        local slot = body:AddChild(notice)
        setPadding(slot, 12, 4, 16, 10)
        align(slot, ALIGN_FILL, ALIGN_FILL)
    end)
    return ok == true
end

Deferred.addItemPickerRow = function(tree, body, label, kind, key, catalog,
        summaryKey, titleKey, helperKey, source)
    local row = makeRow(tree, body, label, "choice")
    if row == nil then return false end
    local trigger = makeTrigger(tree, catalog.summary(
        currentStrings()[summaryKey], state.config[key]),
        SIZE.choice, false, "▼")
    if trigger == nil then return false end
    addControlToRow(row.row, trigger.box, 0)
    local control = {
        kind = kind, key = key, catalog = catalog,
        summaryKey = summaryKey, titleKey = titleKey,
        helperKey = helperKey, source = source,
        widget = trigger.widget, text = trigger.text,
        label = label, rowFrame = row.surface,
    }
    registerFocusable(control, row.box, trigger)
    state.controls[#state.controls + 1] = control
    return true
end

Deferred.addValuablePickerRow = function(tree, body, label)
    return Deferred.addItemPickerRow(tree, body, label,
        "valuablePicker", "ValuableSellItems", Ammo.valuables,
        "valuableKeptSummary", "valuablePickerTitle",
        "valuablePickerHelper", "valuable-picker")
end

Deferred.addAmmoPickerRow = function(tree, body, label)
    return Deferred.addItemPickerRow(tree, body, label,
        "ammoPicker", "AmmoSellItems", Ammo,
        "ammoKeptSummary", "ammoPickerTitle",
        "ammoPickerHelper", "ammo-picker")
end

Deferred.addPalSpherePickerRow = function(tree, body, label)
    return Deferred.addItemPickerRow(tree, body, label,
        "palSpherePicker", "PalSphereSellItems",
        Ammo.saleConsumables.palSpheres,
        "palSphereKeptSummary", "palSpherePickerTitle",
        "palSpherePickerHelper", "pal-sphere-picker")
end

Deferred.addFishingBaitPickerRow = function(tree, body, label)
    return Deferred.addItemPickerRow(tree, body, label,
        "fishingBaitPicker", "FishingBaitSellItems",
        Ammo.saleConsumables.fishingBait,
        "fishingBaitKeptSummary", "fishingBaitPickerTitle",
        "fishingBaitPickerHelper", "fishing-bait-picker")
end

local function addNumberRow(tree, body, key, label, minimum, maximum, alternate,
        indent)
    local row = makeRow(tree, body, label, "number", indent)
    if row == nil then return false end
    local initial = math.max(minimum, math.min(maximum,
        tonumber(state.config[key]) or minimum))
    initial = math.floor(initial + 0.5)
    local box = construct(tree, "/Script/UMG.SizeBox")
    local layer = construct(tree, "/Script/UMG.Overlay")
    local input = construct(tree, "/Script/UMG.EditableTextBox")
    local displayButton = construct(tree, "/Script/UMG.Button")
    local displayText = makeText(tree, tostring(initial), 14,
        COLORS.text, TEXT_LEFT)
    if box == nil or layer == nil or input == nil
        or displayButton == nil or displayText == nil then return false end
    local ok = pcall(function()
        box:SetWidthOverride(SIZE.number)
        box:SetHeightOverride(SIZE.control)
        displayButton.bIsFocusable = false
        styleSurfaceButton(displayButton, COLORS.control, COLORS.controlHover,
            COLORS.controlPressed, COLORS.controlDisabled, {
                normal = COLORS.text,
                hovered = COLORS.text,
                pressed = COLORS.textOnAccent,
        })
        displayText:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        align(displayButton:AddChild(displayText), ALIGN_CENTER, ALIGN_CENTER)
        state.numberEditorOps.styleEditableNumber(input)
        input:SetText(FText(tostring(initial)))
        input:SetIsReadOnly(false)
        input.IsReadOnly = false
        input.SelectAllTextWhenFocused = true
        input.ClearKeyboardFocusOnCommit = true
        align(layer:AddChild(input), ALIGN_FILL, ALIGN_FILL)
        align(layer:AddChild(displayButton), ALIGN_FILL, ALIGN_FILL)
        input:SetVisibility(VIS_COLLAPSED)
        displayButton:SetVisibility(VIS_VISIBLE)
        align(box:AddChild(layer), ALIGN_FILL, ALIGN_FILL)
    end)
    if not ok then return false end
    addControlToRow(row.row, box, 0)
    local trigger = {
        box = box, widget = displayButton, surface = displayButton,
        text = displayText, directButton = true,
    }
    registerDirectActionButton(displayButton)
    state.triggerSurfaces[#state.triggerSurfaces + 1] = trigger
    local control = {
        kind = "number", key = key, widget = displayButton,
        input = input,
        displayButton = displayButton,
        displayText = displayText, displayedText = tostring(initial),
        editingVisual = false, value = initial,
        minimum = minimum, maximum = maximum,
        rowFrame = row.surface, trigger = trigger,
    }
    registerFocusable(control, row.box, trigger)
    state.controls[#state.controls + 1] = control
    return true
end

local function addShortcutRow(tree, body, strings)
    local row = makeRow(tree, body, strings.shortcut, "binding")
    local selector = construct(tree, "/Script/UMG.InputKeySelector")
    if row == nil or selector == nil then return false end
    local box = construct(tree, "/Script/UMG.SizeBox")
    local overlay = construct(tree, "/Script/UMG.Overlay")
    local valueText = makeText(tree, "", 14, COLORS.text, TEXT_CENTER)
    if box == nil or overlay == nil or valueText == nil then
        return false
    end
    local chord = {
        Key = state.config.Key,
        Shift = state.config.Shift,
        Ctrl = state.config.Ctrl,
        Alt = state.config.Alt,
    }
    local ok = pcall(function()
        selector.bIsFocusable = true
        selector.bAllowModifierKeys = true
        selector.bAllowGamepadKeys = false
        styleShortcutSelector(selector, false, false)
        box:SetWidthOverride(SIZE.binding)
        box:SetHeightOverride(SIZE.control)
        local selectorSlot = overlay:AddChildToOverlay(selector)
        align(selectorSlot, ALIGN_FILL, ALIGN_FILL)
        valueText:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        valueText:SetRenderOpacity(1.0)
        local valueSlot = overlay:AddChildToOverlay(valueText)
        align(valueSlot, ALIGN_CENTER, ALIGN_CENTER)
        local overlaySlot = box:AddChild(overlay)
        align(overlaySlot, ALIGN_FILL, ALIGN_FILL)
        setSelectorChord(selector, chord)
    end)
    if not ok then return false end
    addControlToRow(row.row, box, 4)
    local control = {
        kind = "shortcut", widget = selector,
        text = valueText, rowFrame = row.surface,
        last = chordSignature(chord), selecting = false,
    }
    registerFocusable(control, row.box)
    state.controls[#state.controls + 1] = control
    state.shortcutControl = control
    local warning = makeText(tree, "", 12, COLORS.actionWarning, TEXT_LEFT)
    if warning == nil then return false end
    setTextWrap(warning, math.max(1.0, state.contentWidth - 52.0))
    warning:SetVisibility(VIS_COLLAPSED)
    local warningSlot = body:AddChild(warning)
    setPadding(warningSlot, 36, 4, 16, 8)
    align(warningSlot, ALIGN_FILL, ALIGN_FILL)
    state.shortcutWarningText = warning
    refreshShortcutDisplay(control, false)
    refreshShortcutConflictWarning()
    return true
end

closeChoiceModal = function(restoreFocus)
    local control = state.activeChoice
    local blockedClose = type(control) == "table"
        and (control.kind == "downvoteAcknowledgement"
            or control.kind == "steamVoteChecking")
    local returnFocusIndex = state.choiceReturnFocusIndex
    state.activeChoice = nil
    state.choiceReturnFocusIndex = nil
    state.pointerAction = nil
    if blockedClose and type(state.publishHostedCloseBlocked) == "function" then
        state.publishHostedCloseBlocked(false)
    end
    state.ammoPopulateToken = state.ammoPopulateToken + 1
    if P.isValid(state.nestedOverlay) then
        pcall(function() state.nestedOverlay:SetVisibility(VIS_COLLAPSED) end)
    end
    for _, option in ipairs(state.modalOptions or {}) do
        option.selected = false
    end
    if P.isValid(state.nestedCardBox) then
        pcall(function()
            state.nestedCardBox:SetWidthOverride(state.nestedDefaultWidth)
            state.nestedCardBox:SetMaxDesiredHeight(
                state.nestedDefaultMaxHeight)
        end)
    end
    if P.isValid(state.nestedOutline) then
        pcall(function()
            state.nestedOutline:SetBrushColor(COLORS.outline)
            state.nestedOutline:SetPadding({
                Left = 1, Top = 1, Right = 1, Bottom = 1,
            })
        end)
    end
    if P.isValid(state.nestedPanel) then
        pcall(function()
            state.nestedPanel:SetPadding({
                Left = 16, Top = 16, Right = 16, Bottom = 16,
            })
        end)
    end
    if P.isValid(state.nestedTitle) then
        setTextStyle(state.nestedTitle, 18, COLORS.text, TEXT_LEFT)
    end
    if P.isValid(state.nestedMessage) then
        setTextStyle(state.nestedMessage, 12, COLORS.muted, TEXT_LEFT)
        setTextWrap(state.nestedMessage,
            math.max(1.0, (tonumber(state.nestedOptionWidth) or 288.0) - 8.0))
    end
    for _, option in ipairs(state.modalOptions or {}) do
        if P.isValid(option.box) then
            pcall(function()
                option.box:SetWidthOverride(state.nestedOptionWidth)
                option.box:SetHeightOverride(SIZE.modalOption)
            end)
        end
        if P.isValid(option.text) then
            setTextStyle(option.text, 14, COLORS.text, TEXT_CENTER)
        end
    end
    if restoreFocus == true and type(control) == "table"
        and P.isValid(control.widget) then
        focusEntry(returnFocusIndex or control.focusIndex or state.focusIndex,
            state.lastInputDevice, true)
    end
    return control ~= nil
end

Deferred.showSteamVoteModal = function(kind, title, message, label)
    if not Deferred.ensureChoiceModalCapacity(1) then return false end
    local large = kind == "downvoteAcknowledgement"
    local control = {
        kind = kind,
        label = title,
        labels = label ~= nil and { label } or {},
        index = 0,
    }
    state.activeChoice = control
    state.choiceReturnFocusIndex = nil
    state.pointerAction = nil
    state.modalIndex = 0
    if type(state.publishHostedCloseBlocked) == "function" then
        state.publishHostedCloseBlocked(true)
    end
    if P.isValid(state.nestedCardBox) then
        pcall(function()
            state.nestedCardBox:SetWidthOverride(large
                and state.downvoteDialogWidth or state.nestedDefaultWidth)
            state.nestedCardBox:SetMaxDesiredHeight(large
                and state.downvoteDialogMaxHeight
                or state.nestedDefaultMaxHeight)
        end)
    end
    if P.isValid(state.nestedOutline) then
        pcall(function()
            state.nestedOutline:SetBrushColor(
                large and COLORS.borderFocus or COLORS.outline)
            local border = large and 3 or 1
            state.nestedOutline:SetPadding({ Left = border, Top = border,
                Right = border, Bottom = border })
        end)
    end
    if P.isValid(state.nestedPanel) then
        pcall(function()
            local padding = large and 28 or 16
            state.nestedPanel:SetPadding({ Left = padding, Top = padding,
                Right = padding, Bottom = padding })
        end)
    end
    if P.isValid(state.nestedTitle) then
        setTextStyle(state.nestedTitle, large and 28 or 18,
            large and COLORS.borderFocus or COLORS.text, TEXT_LEFT)
        pcall(function() state.nestedTitle:SetText(FText(title or "")) end)
    end
    if P.isValid(state.nestedMessage) then
        local width = large and math.max(400.0,
            (tonumber(state.downvoteDialogWidth) or 760.0) - 64.0)
            or math.max(1.0, (tonumber(state.nestedOptionWidth) or 288.0) - 8.0)
        setTextStyle(state.nestedMessage, large and 19 or 12,
            COLORS.muted, TEXT_LEFT)
        setTextWrap(state.nestedMessage, width)
        pcall(function()
            state.nestedMessage:SetText(FText(message or ""))
            state.nestedMessage:SetVisibility(message ~= nil and message ~= ""
                and VIS_HIT_TEST_INVISIBLE or VIS_COLLAPSED)
        end)
    end
    for index, option in ipairs(state.modalOptions or {}) do
        local visible = label ~= nil and index == 1
        option.warning = false
        option.selected = false
        option.visualSignature = nil
        pcall(function()
            option.box:SetWidthOverride(large and math.max(400.0,
                (tonumber(state.downvoteDialogWidth) or 760.0) - 56.0)
                or state.nestedOptionWidth)
            option.box:SetHeightOverride(large and 58 or SIZE.modalOption)
            option.box:SetVisibility(visible and VIS_VISIBLE or VIS_COLLAPSED)
            option.text:SetVisibility(VIS_HIT_TEST_INVISIBLE)
            option.ammoContent:SetVisibility(VIS_COLLAPSED)
            if visible then option.text:SetText(FText(label)) end
        end)
        if P.isValid(option.text) then
            setTextStyle(option.text, large and 20 or 14,
                COLORS.text, TEXT_CENTER)
        end
    end
    pcall(function() state.nestedOverlay:SetVisibility(VIS_VISIBLE) end)
    focusNavigationRoot()
    refreshTriggerSurfaces()
    return true
end

Deferred.openDownvoteAcknowledgement = function()
    local strings = currentStrings()
    return Deferred.showSteamVoteModal("downvoteAcknowledgement",
        strings.downvoteTitle, strings.downvoteMessage,
        strings.downvoteConfirm or "Confirm")
end

Deferred.openSteamVoteChecking = function()
    local strings = currentStrings()
    return Deferred.showSteamVoteModal("steamVoteChecking",
        strings.voteChecking or "Checking Steam Workshop status…", nil, nil)
end

openChoiceModal = function(control, returnFocusIndex)
    if type(control) ~= "table" or control.kind ~= "choice"
        or not ensureChoiceModal() then return false end
    state.activeChoice = control
    state.choiceReturnFocusIndex = tonumber(returnFocusIndex)
        or state.choiceReturnFocusIndex or control.focusIndex or state.focusIndex
    state.pointerAction = nil
    state.modalIndex = tonumber(control.index) or 1
    if P.isValid(state.nestedTitle) then
        pcall(function() state.nestedTitle:SetText(FText(control.label or "")) end)
    end
    if P.isValid(state.nestedMessage) then
        pcall(function()
            state.nestedMessage:SetText(FText(""))
            state.nestedMessage:SetVisibility(VIS_COLLAPSED)
        end)
    end
    local first
    for index, option in ipairs(state.modalOptions or {}) do
        local label = control.labels[index]
        local visible = label ~= nil
        option.warning = false
        option.visualSignature = nil
        pcall(function()
            option.box:SetVisibility(visible and VIS_VISIBLE or VIS_COLLAPSED)
            option.text:SetVisibility(VIS_HIT_TEST_INVISIBLE)
            option.ammoContent:SetVisibility(VIS_COLLAPSED)
            if visible then option.text:SetText(FText(label)) end
        end)
        option.selected = visible and index == state.modalIndex
        if visible and index == state.modalIndex then first = option.widget end
    end
    pcall(function() state.nestedOverlay:SetVisibility(VIS_VISIBLE) end)
    if P.isValid(first) then focusNavigationRoot() end
    return true
end

Deferred.resolveAmmoName = function(staticId)
    return Localization.itemName(staticId)
end

Deferred.populateAmmoRowsSlice = function(control, startIndex, token)
    if state.activeChoice ~= control
        or not SettingsUI.isItemPicker(control)
        or state.ammoPopulateToken ~= token then return end
    local catalog = control.catalog
    local stop = math.min(#catalog.items, startIndex + 3)
    for index = startIndex, stop do
        local option = state.modalOptions[index]
        if type(option) == "table" and P.isValid(option.ammoFallback) then
            local staticId = catalog.items[index]
            local texturePath = catalog.iconPath(staticId)
            local texture = texturePath ~= nil and staticObject(texturePath) or nil
            if not P.isValid(texture) and texturePath ~= nil
                and type(LoadAsset) == "function" then
                local loaded
                pcall(function() loaded = LoadAsset(texturePath) end)
                texture = P.isValid(loaded) and loaded or staticObject(texturePath)
                if P.isValid(texture) then staticObjects[texturePath] = texture end
            end
            local displayName = Deferred.resolveAmmoName(staticId)
            pcall(function()
                option.ammoFallback:SetText(FText(displayName or staticId))
                if P.isValid(texture) and P.isValid(option.ammoIcon) then
                    option.ammoIcon:SetBrushFromTexture(texture, false)
                    option.ammoIcon:SetVisibility(VIS_HIT_TEST_INVISIBLE)
                elseif P.isValid(option.ammoIcon) then
                    option.ammoIcon:SetVisibility(VIS_COLLAPSED)
                end
            end)
        end
    end
    if stop >= #catalog.items then return end
    local callback = function()
        Deferred.populateAmmoRowsSlice(control, stop + 1, token)
    end
    if type(ExecuteInGameThreadWithDelay) == "function"
        and pcall(ExecuteInGameThreadWithDelay, 1, callback) then return end
    callback()
end

Deferred.openAmmoPickerModal = function(control, returnFocusIndex)
    if type(control) ~= "table"
        or not SettingsUI.isItemPicker(control)
        or not ensureChoiceModal() then return false end
    local strings = currentStrings()
    local catalog = control.catalog
    control.labels = {}
    for index, staticId in ipairs(catalog.items) do
        control.labels[index] = staticId
    end
    control.labels[#catalog.items + 1] = strings.ammoPickerDone or "Done"
    state.activeChoice = control
    state.choiceReturnFocusIndex = tonumber(returnFocusIndex)
        or control.focusIndex or state.focusIndex
    state.pointerAction = nil
    state.modalIndex = 1
    if P.isValid(state.nestedTitle) then
        pcall(function()
            state.nestedTitle:SetText(FText(strings[control.titleKey]
                or control.label or "Ammunition to keep"))
        end)
    end
    if P.isValid(state.nestedMessage) then
        pcall(function()
            state.nestedMessage:SetText(FText(strings[control.helperKey] or ""))
            state.nestedMessage:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        end)
    end
    local sellSet = catalog.sellSet(state.config[control.key])
    for index, option in ipairs(state.modalOptions or {}) do
        local ammoId = catalog.items[index]
        local done = index == #catalog.items + 1
        local visible = ammoId ~= nil or done
        option.warning = false
        option.visualSignature = nil
        pcall(function()
            option.box:SetVisibility(visible and VIS_VISIBLE or VIS_COLLAPSED)
            option.text:SetVisibility(done and VIS_HIT_TEST_INVISIBLE
                or VIS_COLLAPSED)
            option.ammoContent:SetVisibility(ammoId ~= nil
                and VIS_HIT_TEST_INVISIBLE or VIS_COLLAPSED)
            if ammoId ~= nil then
                option.ammoIconBox:SetVisibility(VIS_HIT_TEST_INVISIBLE)
                option.ammoIcon:SetVisibility(VIS_COLLAPSED)
                option.ammoFallback:SetText(FText(
                    Deferred.resolveAmmoName(ammoId) or ammoId))
                option.ammoMark:SetText(FText(
                    sellSet[ammoId] ~= true and "✓" or ""))
            elseif done then
                option.text:SetText(FText(control.labels[index]))
            end
        end)
        option.selected = index == state.modalIndex
    end
    pcall(function() state.nestedOverlay:SetVisibility(VIS_VISIBLE) end)
    state.ammoPopulateToken = state.ammoPopulateToken + 1
    Deferred.populateAmmoRowsSlice(control, 1, state.ammoPopulateToken)
    focusNavigationRoot()
    refreshTriggerSurfaces()
    return true
end

Deferred.openResetConfirmation = function(sourceIndex)
    if state.activeChoice ~= nil or not ensureChoiceModal() then return false end
    local edit = state.numberEdit
    if type(edit) == "table" and type(edit.control) == "table" then
        commitNumberEditor(edit.control, "number-reset-confirm", true)
    end
    local strings = currentStrings()
    local control = {
        kind = "resetConfirmation",
        label = strings.reset or "Restore defaults",
        labels = {
            strings.cancel or "Cancel",
            strings.confirmReset or "Restore all",
        },
        index = 1,
        focusIndex = tonumber(sourceIndex) or state.focusIndex,
    }
    state.activeChoice = control
    state.choiceReturnFocusIndex = control.focusIndex
    state.modalIndex = 1
    if P.isValid(state.nestedTitle) then
        pcall(function() state.nestedTitle:SetText(FText(control.label)) end)
    end
    if P.isValid(state.nestedMessage) then
        pcall(function()
            state.nestedMessage:SetText(FText(strings.resetConfirmMessage or ""))
            state.nestedMessage:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        end)
    end
    local first
    for index, option in ipairs(state.modalOptions or {}) do
        local label = control.labels[index]
        local visible = label ~= nil
        option.warning = visible and index == 2
        option.visualSignature = nil
        pcall(function()
            option.box:SetVisibility(visible and VIS_VISIBLE or VIS_COLLAPSED)
            option.text:SetVisibility(VIS_HIT_TEST_INVISIBLE)
            option.ammoContent:SetVisibility(VIS_COLLAPSED)
            if visible then option.text:SetText(FText(label)) end
        end)
        option.selected = visible and index == state.modalIndex
        if option.selected then first = option.widget end
    end
    pcall(function() state.nestedOverlay:SetVisibility(VIS_VISIBLE) end)
    if P.isValid(first) then focusNavigationRoot() end
    refreshTriggerSurfaces()
    return true
end

Deferred.buildChoiceModal = function(
        tree, root, viewportWidth, viewportHeight, optionCapacity)
    local overlay = construct(tree, "/Script/UMG.CanvasPanel")
    local dim = construct(tree, "/Script/UMG.Border")
    local cardBox = construct(tree, "/Script/UMG.SizeBox")
    local outline = construct(tree, "/Script/UMG.Border")
    local panel = construct(tree, "/Script/UMG.Border")
    local scroll = construct(tree, "/Script/UMG.ScrollBox")
    local content = construct(tree, "/Script/UMG.VerticalBox")
    local title = makeText(tree, "", 18, COLORS.text, TEXT_LEFT)
    local message = makeText(tree, "", 12, COLORS.muted, TEXT_LEFT)
    if overlay == nil or dim == nil or cardBox == nil or outline == nil
        or panel == nil
        or scroll == nil or content == nil or title == nil
        or message == nil then return false end
    local vw = tonumber(viewportWidth) or 1280.0
    local vh = tonumber(viewportHeight) or 720.0
    local width = math.max(320.0, math.min(480.0, vw - 48.0))
    local maxHeight = math.min(560.0, math.max(320.0, vh - 48.0))
    local optionWidth = math.max(288.0,
        width - 32.0 - SIZE.scrollbarGutter)
    local ok = pcall(function()
        overlay:SetVisibility(VIS_COLLAPSED)
        dim:SetBrushColor(COLORS.modal)
        local overlaySlot = root:AddChild(overlay)
        overlaySlot:SetAnchors({
            Minimum = { X = 0.0, Y = 0.0 },
            Maximum = { X = 1.0, Y = 1.0 },
        })
        overlaySlot:SetOffsets({ Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0 })
        overlaySlot:SetZOrder(2)
        local dimSlot = overlay:AddChild(dim)
        dimSlot:SetAnchors({
            Minimum = { X = 0.0, Y = 0.0 },
            Maximum = { X = 1.0, Y = 1.0 },
        })
        dimSlot:SetOffsets({ Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0 })
        dimSlot:SetZOrder(0)
        cardBox:SetWidthOverride(width)
        cardBox:SetMaxDesiredHeight(maxHeight)
        outline:SetBrushColor(COLORS.outline)
        outline:SetPadding({ Left = 1, Top = 1, Right = 1, Bottom = 1 })
        panel:SetBrushColor(COLORS.window)
        panel:SetPadding({ Left = 16, Top = 16, Right = 16, Bottom = 16 })
        scroll:SetAlwaysShowScrollbar(false)
        scroll.AlwaysShowScrollbarTrack = false
        scroll:SetScrollbarThickness({
            X = SIZE.scrollbarThickness, Y = SIZE.scrollbarThickness,
        })
        scroll:SetScrollbarPadding({
            Left = SIZE.scrollbarPadding, Top = SIZE.scrollbarPadding,
            Right = SIZE.scrollbarPadding, Bottom = SIZE.scrollbarPadding,
        })
        align(scroll:AddChild(content), ALIGN_FILL, ALIGN_LEFT)
        align(panel:AddChild(scroll), ALIGN_FILL, ALIGN_FILL)
        align(outline:AddChild(panel), ALIGN_FILL, ALIGN_FILL)
        local panelSlot = cardBox:AddChild(outline)
        align(panelSlot, ALIGN_FILL, ALIGN_FILL)
        local cardSlot = overlay:AddChild(cardBox)
        cardSlot:SetAnchors({
            Minimum = { X = 0.5, Y = 0.5 },
            Maximum = { X = 0.5, Y = 0.5 },
        })
        cardSlot:SetAlignment({ X = 0.5, Y = 0.5 })
        cardSlot:SetPosition({ X = 0.0, Y = 0.0 })
        cardSlot:SetAutoSize(true)
        cardSlot:SetZOrder(1)
        local titleSlot = content:AddChild(title)
        setPadding(titleSlot, 4, 0, 4, 12)
        setTextWrap(message, optionWidth - 8.0)
        message:SetVisibility(VIS_COLLAPSED)
        local messageSlot = content:AddChild(message)
        setPadding(messageSlot, 4, 0, 4, 12)
        state.modalOptions = {}
        optionCapacity = math.max(1, math.min(#Ammo.items + 1,
            tonumber(optionCapacity) or #Ammo.items + 1))
        for index = 1, optionCapacity do
            local option = makeTrigger(tree, "", optionWidth, false, nil,
                SIZE.modalOption, true)
            if option == nil then error("choice option is unavailable") end
            local optionLayer = construct(tree, "/Script/UMG.Overlay")
            local ammoContent = construct(tree, "/Script/UMG.HorizontalBox")
            local ammoMarkBox = construct(tree, "/Script/UMG.SizeBox")
            local ammoMark = makeText(tree, "", 16, COLORS.accent, TEXT_CENTER)
            local ammoHost = construct(tree, "/Script/UMG.SizeBox")
            local ammoRow = construct(tree, "/Script/UMG.HorizontalBox")
            local ammoIconBox = construct(tree, "/Script/UMG.SizeBox")
            local ammoIcon = construct(tree, "/Script/UMG.Image")
            local ammoFallback = makeText(tree, "", 14, COLORS.text, TEXT_LEFT)
            if optionLayer == nil or ammoContent == nil or ammoMarkBox == nil
                or ammoMark == nil or ammoHost == nil
                or ammoRow == nil or ammoIconBox == nil or ammoIcon == nil
                or ammoFallback == nil then
                error("ammunition option controls are unavailable")
            end
            option.widget:ClearChildren()
            local textSlot = optionLayer:AddChildToOverlay(option.text)
            align(textSlot, ALIGN_CENTER, ALIGN_CENTER)
            ammoMark:SetVisibility(VIS_HIT_TEST_INVISIBLE)
            ammoMarkBox:SetWidthOverride(36.0)
            ammoMarkBox:SetHeightOverride(32.0)
            align(ammoMarkBox:AddChild(ammoMark), ALIGN_CENTER, ALIGN_CENTER)
            align(ammoContent:AddChild(ammoMarkBox), ALIGN_CENTER, ALIGN_CENTER)
            ammoHost:SetWidthOverride(math.max(220.0, optionWidth - 60.0))
            ammoHost:SetHeightOverride(34.0)
            ammoIconBox:SetWidthOverride(30.0)
            ammoIconBox:SetHeightOverride(30.0)
            ammoIconBox:SetVisibility(VIS_HIT_TEST_INVISIBLE)
            align(ammoIconBox:AddChild(ammoIcon), ALIGN_FILL, ALIGN_FILL)
            local iconSlot = ammoRow:AddChild(ammoIconBox)
            setPadding(iconSlot, 0, 0, 8, 0)
            align(iconSlot, ALIGN_LEFT, ALIGN_CENTER)
            align(ammoRow:AddChild(ammoFallback), ALIGN_LEFT, ALIGN_CENTER)
            align(ammoHost:AddChild(ammoRow), ALIGN_FILL, ALIGN_CENTER)
            local hostSlot = ammoContent:AddChild(ammoHost)
            setFill(hostSlot)
            align(hostSlot, ALIGN_FILL, ALIGN_CENTER)
            ammoContent:SetVisibility(VIS_COLLAPSED)
            local ammoSlot = optionLayer:AddChildToOverlay(ammoContent)
            align(ammoSlot, ALIGN_FILL, ALIGN_CENTER)
            align(option.widget:AddChild(optionLayer), ALIGN_FILL, ALIGN_FILL)
            option.ammoContent = ammoContent
            option.ammoMark = ammoMark
            option.ammoHost = ammoHost
            option.ammoIconBox = ammoIconBox
            option.ammoIcon = ammoIcon
            option.ammoFallback = ammoFallback
            local optionSlot = content:AddChild(option.box)
            setPadding(optionSlot, 0, index == 1 and 0 or 4, 0, 0)
            option.box:SetVisibility(VIS_COLLAPSED)
            state.modalOptions[index] = option
        end
    end)
    if not ok then return false end
    state.nestedOverlay = overlay
    state.nestedCardBox = cardBox
    state.nestedOutline = outline
    state.nestedPanel = panel
    state.nestedTitle = title
    state.nestedMessage = message
    state.nestedContent = content
    state.nestedScroll = scroll
    state.nestedOptionWidth = optionWidth
    state.nestedDefaultWidth = width
    state.nestedDefaultMaxHeight = maxHeight
    state.downvoteDialogWidth = math.max(480.0,
        math.min(760.0, vw - 64.0))
    state.downvoteDialogMaxHeight = math.min(720.0,
        math.max(420.0, vh - 64.0))
    state.nestedOptionCapacity = optionCapacity
    return true
end

ensureChoiceModal = function()
    return Deferred.ensureChoiceModalCapacity(#Ammo.items + 1)
end

Deferred.ensureChoiceModalCapacity = function(requiredCapacity)
    requiredCapacity = math.max(1,
        tonumber(requiredCapacity) or #Ammo.items + 1)
    if P.isValid(state.nestedOverlay)
        and (tonumber(state.nestedOptionCapacity) or 0) >= requiredCapacity then
        return true
    end
    if not P.isValid(state.widgetTree) or not P.isValid(state.root) then return false end
    if P.isValid(state.nestedOverlay) then
        pcall(function() state.nestedOverlay:SetVisibility(VIS_COLLAPSED) end)
    end
    local viewportWidth, viewportHeight = logicalViewportSize(state.controller)
    local built = Deferred.buildChoiceModal(state.widgetTree, state.root,
        viewportWidth, viewportHeight, requiredCapacity)
    if built and InputOwner.cookedInputActive()
        and not InputOwner.bindActionButtons(state.directActionButtons) then
        log("choice native action delegates unavailable; using mouse fallback")
    end
    return built
end

state.updateReleaseNotesVisuals = function()
    for index, record in ipairs(state.releaseNotesPickerButtons or {}) do
        local focused = state.releaseNotesFocusPane == 1
            and index == state.releaseNotesPickerIndex
            and state.lastInputDevice ~= "mouse"
        local selected = index == state.releaseNotesSelectedIndex
        if P.isValid(record.widget) then
            styleSurfaceButton(record.widget,
                focused and COLORS.controlFocus
                    or selected and COLORS.surfaceSelected
                    or COLORS.control,
                COLORS.controlHover,
                COLORS.controlPressed,
                COLORS.controlDisabled,
                nil,
                { Left = 8, Top = 0, Right = 8, Bottom = 0 })
        end
        if P.isValid(record.labelWidget) then
            pcall(function()
                record.labelWidget:SetColorAndOpacity(slateColor(COLORS.text))
            end)
        end
    end
    for _, record in ipairs(state.releaseNotesButtons or {}) do
        if P.isValid(record.widget) then
            styleHeaderButton(record.widget, record.role or "close",
                state.releaseNotesFocusPane == (record.navPane or 3)
                    and state.lastInputDevice ~= "mouse",
                false, false)
        end
    end
    return true
end

state.renderReleaseNotesVersion = function()
    local versions = SettingsUI.releaseNotes.versions or {}
    local index = math.max(1, math.min(#versions,
        tonumber(state.releaseNotesSelectedIndex) or 1))
    local entry = versions[index]
    local content = state.releaseNotesContent
    if type(entry) ~= "table" or not P.isValid(content) then return false end
    state.releaseNotesSelectedIndex = index
    local strings = SettingsUI.releaseNotes.current()
    local english = SettingsUI.releaseNotes.current("en")
    pcall(function() content:ClearChildren() end)
    local width = math.max(140.0, tonumber(state.releaseNotesContentWidth) or 360.0)
    local headingRow = construct(state.widgetTree, "/Script/UMG.HorizontalBox")
    local heading = makeText(state.widgetTree,
        "v" .. tostring(entry.version or ""), 22, COLORS.text)
    local dateValue = tostring(entry.dateUtc or "")
    if dateValue ~= "" then dateValue = dateValue .. " UTC" end
    local date = makeText(state.widgetTree, dateValue, 13, COLORS.textMuted, TEXT_RIGHT)
    if headingRow == nil or heading == nil or date == nil then return false end
    local headingSlot = headingRow:AddChild(heading)
    setFill(headingSlot)
    align(headingSlot, ALIGN_LEFT, ALIGN_CENTER)
    align(headingRow:AddChild(date), ALIGN_RIGHT, ALIGN_CENTER)
    local rowSlot = content:AddChild(headingRow)
    setPadding(rowSlot, 0, 0, 0, 8)
    local category = {
        added = strings.added, changed = strings.changed,
        performance = strings.performance, fixed = strings.fixed,
    }
    for sectionIndex, section in ipairs(entry.groups or {}) do
        local title = makeText(state.widgetTree,
            tostring(category[section.kind] or section.kind or ""),
            18, COLORS.text)
        if title == nil then return false end
        local titleSlot = content:AddChild(title)
        setPadding(titleSlot, 0,
            sectionIndex == 1 and 0 or SIZE.aboutSectionGap, 0, 6)
        for itemIndex, copyIndex in ipairs(section.items or {}) do
            local value = strings[copyIndex] or english[copyIndex] or ""
            local bullet = makeText(state.widgetTree,
                "• " .. tostring(value), 16, COLORS.muted)
            if bullet == nil then return false end
            setTextWrap(bullet, width)
            local bulletSlot = content:AddChild(bullet)
            setPadding(bulletSlot, 0, itemIndex == 1 and 0 or 5, 0, 0)
        end
    end
    if P.isValid(state.releaseNotesScroll) then
        pcall(function() state.releaseNotesScroll:ScrollToStart() end)
    end
    return true
end

Deferred.selectReleaseNotesVersion = function(index)
    local versions = SettingsUI.releaseNotes.versions or {}
    index = math.max(1, math.min(#versions, tonumber(index) or 1))
    if type(versions[index]) ~= "table" then return false end
    state.releaseNotesPickerIndex = index
    state.releaseNotesSelectedIndex = index
    if not state.renderReleaseNotesVersion() then return false end
    state.updateReleaseNotesVisuals()
    local record = (state.releaseNotesPickerButtons or {})[index]
    if type(record) == "table" and P.isValid(record.widget)
        and P.isValid(state.releaseNotesPickerScroll) then
        pcall(function()
            state.releaseNotesPickerScroll:ScrollWidgetIntoView(
                record.widget, false, 0, 8.0)
        end)
    end
    return true
end

state.moveReleaseNotesFocus = function(horizontal, vertical)
    if state.releaseNotesOpen ~= true then return false end
    horizontal = tonumber(horizontal) or 0
    vertical = tonumber(vertical) or 0
    if horizontal ~= 0 then
        state.releaseNotesFocusPane = math.max(1, math.min(3,
            state.releaseNotesFocusPane + (horizontal < 0 and -1 or 1)))
    elseif vertical ~= 0 then
        if state.releaseNotesFocusPane == 1 then
            local target = math.max(1, math.min(#(SettingsUI.releaseNotes.versions or {}),
                state.releaseNotesPickerIndex + (vertical < 0 and -1 or 1)))
            if target ~= state.releaseNotesPickerIndex then
                return Deferred.selectReleaseNotesVersion(target)
            end
        elseif state.releaseNotesFocusPane == 2
            and P.isValid(state.releaseNotesScroll) then
            pcall(function()
                local offset = tonumber(state.releaseNotesScroll:GetScrollOffset()) or 0.0
                state.releaseNotesScroll:SetScrollOffset(
                    math.max(0.0, offset + (vertical < 0 and -64.0 or 64.0)))
            end)
        end
    end
    state.updateReleaseNotesVisuals()
    return true
end

state.activateReleaseNotesAction = function()
    if state.releaseNotesOpen ~= true then return false end
    if state.releaseNotesFocusPane == 3 then
        return state.closeReleaseNotesModal(true)
    end
    if state.releaseNotesFocusPane == 1 then
        return Deferred.selectReleaseNotesVersion(state.releaseNotesPickerIndex)
    end
    return true
end

state.closeReleaseNotesModal = function(restoreFocus)
    if state.releaseNotesOpen ~= true then return false end
    cancelNavigationRepeat()
    state.pointerAction = nil
    state.pendingAboutPointerClose = nil
    state.releaseNotesOpen = false
    state.releaseNotesRevision = state.releaseNotesRevision + 1
    if P.isValid(state.releaseNotesOverlay) then
        pcall(function() state.releaseNotesOverlay:SetVisibility(VIS_COLLAPSED) end)
    end
    local returnIndex = state.releaseNotesReturnFocusIndex
    state.releaseNotesReturnFocusIndex = nil
    if restoreFocus == true and state.open and returnIndex ~= nil then
        focusEntry(returnIndex, state.lastInputDevice, false)
    end
    refreshTriggerSurfaces()
    return true
end

Deferred.buildReleaseNotesModal = function(tree, root, strings,
        viewportWidth, viewportHeight)
    local width = math.min(SIZE.aboutWidth, math.max(320.0, viewportWidth - 48.0))
    local height = math.min(SIZE.aboutHeight, math.max(360.0, viewportHeight - 48.0))
    local innerWidth = width - SIZE.windowOutline * 2.0 - 32.0
    local indexWidth = math.min(SIZE.releaseNotesIndexWidth,
        math.max(96.0, innerWidth * 0.22))
    local overlay = construct(tree, "/Script/UMG.CanvasPanel")
    local dim = construct(tree, "/Script/UMG.Border")
    local box = construct(tree, "/Script/UMG.SizeBox")
    local outline = construct(tree, "/Script/UMG.Border")
    local panel = construct(tree, "/Script/UMG.Border")
    local layout = construct(tree, "/Script/UMG.VerticalBox")
    local header = construct(tree, "/Script/UMG.HorizontalBox")
    local body = construct(tree, "/Script/UMG.HorizontalBox")
    local indexBox = construct(tree, "/Script/UMG.SizeBox")
    local indexSurface = construct(tree, "/Script/UMG.Border")
    local indexScroll = construct(tree, "/Script/UMG.ScrollBox")
    local indexList = construct(tree, "/Script/UMG.VerticalBox")
    local dividerBox = construct(tree, "/Script/UMG.SizeBox")
    local divider = construct(tree, "/Script/UMG.Border")
    local contentSurface = construct(tree, "/Script/UMG.Border")
    local scroll = construct(tree, "/Script/UMG.ScrollBox")
    local content = construct(tree, "/Script/UMG.VerticalBox")
    if overlay == nil or dim == nil or box == nil or outline == nil
        or panel == nil or layout == nil or header == nil or body == nil
        or indexBox == nil or indexSurface == nil or indexScroll == nil
        or indexList == nil or dividerBox == nil or divider == nil
        or contentSurface == nil or scroll == nil or content == nil then
        return false
    end
    state.releaseNotesOverlay = overlay
    state.releaseNotesScroll = scroll
    state.releaseNotesContent = content
    state.releaseNotesPickerScroll = indexScroll
    state.releaseNotesButtons = {}
    state.releaseNotesPickerButtons = {}
    state.releaseNotesContentWidth = math.max(96.0,
        innerWidth - indexWidth - SIZE.aboutSectionGap - 49.0
            - SIZE.scrollbarGutter)
    local overlaySlot = root:AddChild(overlay)
    overlaySlot:SetAnchors({ Minimum = { X = 0, Y = 0 }, Maximum = { X = 1, Y = 1 } })
    overlaySlot:SetOffsets({ Left = 0, Top = 0, Right = 0, Bottom = 0 })
    overlaySlot:SetZOrder(3)
    overlay:SetVisibility(VIS_COLLAPSED)
    dim:SetBrushColor(COLORS.modal)
    local dimSlot = overlay:AddChild(dim)
    dimSlot:SetAnchors({ Minimum = { X = 0, Y = 0 }, Maximum = { X = 1, Y = 1 } })
    dimSlot:SetOffsets({ Left = 0, Top = 0, Right = 0, Bottom = 0 })
    dimSlot:SetZOrder(0)
    box:SetWidthOverride(width)
    box:SetHeightOverride(height)
    local boxSlot = overlay:AddChild(box)
    boxSlot:SetAnchors({ Minimum = { X = 0.5, Y = 0.5 }, Maximum = { X = 0.5, Y = 0.5 } })
    boxSlot:SetAlignment({ X = 0.5, Y = 0.5 })
    boxSlot:SetPosition({ X = 0, Y = 0 })
    boxSlot:SetAutoSize(true)
    boxSlot:SetZOrder(1)
    outline:SetBrushColor(COLORS.outline)
    outline:SetPadding({ Left = 1, Top = 1, Right = 1, Bottom = 1 })
    panel:SetBrushColor(COLORS.content)
    panel:SetPadding({ Left = 16, Top = 16, Right = 16, Bottom = 12 })
    align(box:AddChild(outline), ALIGN_FILL, ALIGN_FILL)
    align(outline:AddChild(panel), ALIGN_FILL, ALIGN_FILL)
    align(panel:AddChild(layout), ALIGN_FILL, ALIGN_FILL)
    local title = makeText(tree, strings.title, 20, COLORS.text)
    local close = makeIconTrigger(tree, "×", currentStrings().close, "close")
    if title == nil or close == nil then return false end
    local titleSlot = header:AddChild(title)
    setFill(titleSlot)
    align(titleSlot, ALIGN_LEFT, ALIGN_CENTER)
    align(header:AddChild(close.box), ALIGN_RIGHT, ALIGN_CENTER)
    local headerSlot = layout:AddChild(header)
    setPadding(headerSlot, 0, 0, 0, SIZE.aboutSectionGap)
    state.releaseNotesButtons = {
        { kind = "close", role = "close", widget = close.widget,
          navPane = 3, tooltip = currentStrings().close },
    }
    indexBox:SetWidthOverride(indexWidth)
    indexSurface:SetBrushColor(COLORS.section)
    indexSurface:SetPadding({ Left = 4, Top = 4, Right = 4, Bottom = 4 })
    indexScroll:SetAlwaysShowScrollbar(false)
    indexScroll.AlwaysShowScrollbarTrack = false
    align(indexScroll:AddChild(indexList), ALIGN_FILL, ALIGN_FILL)
    align(indexSurface:AddChild(indexScroll), ALIGN_FILL, ALIGN_FILL)
    align(indexBox:AddChild(indexSurface), ALIGN_FILL, ALIGN_FILL)
    local indexSlot = body:AddChild(indexBox)
    setPadding(indexSlot, 0, 0, 8, 0)
    dividerBox:SetWidthOverride(SIZE.windowOutline)
    divider:SetBrushColor(COLORS.outline)
    align(dividerBox:AddChild(divider), ALIGN_FILL, ALIGN_FILL)
    local dividerSlot = body:AddChild(dividerBox)
    setPadding(dividerSlot, 0, 0, SIZE.aboutSectionGap, 0)
    contentSurface:SetBrushColor(mixLinearColor(
        COLORS.content, COLORS.section, 0.35))
    contentSurface:SetPadding({ Left = 16, Top = 14, Right = 16, Bottom = 14 })
    scroll:SetAlwaysShowScrollbar(false)
    scroll.AlwaysShowScrollbarTrack = false
    align(scroll:AddChild(content), ALIGN_FILL, ALIGN_LEFT)
    align(contentSurface:AddChild(scroll), ALIGN_FILL, ALIGN_FILL)
    local contentSlot = body:AddChild(contentSurface)
    setFill(contentSlot)
    align(contentSlot, ALIGN_FILL, ALIGN_FILL)
    local bodySlot = layout:AddChild(body)
    setFill(bodySlot)
    align(bodySlot, ALIGN_FILL, ALIGN_FILL)
    for index, entry in ipairs(SettingsUI.releaseNotes.versions or {}) do
        local rowBox = construct(tree, "/Script/UMG.SizeBox")
        local button = construct(tree, "/Script/UMG.Button")
        local buttonContent = construct(tree, "/Script/UMG.HorizontalBox")
        local markerBox = construct(tree, "/Script/UMG.SizeBox")
        local labelValue = "v" .. tostring(entry.version or "")
        local label = makeText(tree, labelValue, 12, COLORS.text)
        if rowBox == nil or button == nil or buttonContent == nil
            or markerBox == nil or label == nil then return false end
        rowBox:SetHeightOverride(SIZE.releaseNotesPickerRowHeight)
        button.bIsFocusable = true
        local buttonStyle = button.WidgetStyle
        buttonStyle.NormalPadding = { Left = 8, Top = 0, Right = 8, Bottom = 0 }
        buttonStyle.PressedPadding = buttonStyle.NormalPadding
        button.WidgetStyle = buttonStyle
        markerBox:SetWidthOverride(22.0)
        local labelSlot = buttonContent:AddChild(label)
        setFill(labelSlot)
        align(labelSlot, ALIGN_LEFT, ALIGN_CENTER)
        if tostring(entry.version or "") == tostring(state.version) then
            local star = makeText(tree, "★", 14, COLORS.currentVersion)
            if star == nil then return false end
            align(markerBox:AddChild(star), ALIGN_CENTER, ALIGN_CENTER)
        end
        align(buttonContent:AddChild(markerBox), ALIGN_CENTER, ALIGN_CENTER)
        align(button:AddChild(buttonContent), ALIGN_FILL, ALIGN_CENTER)
        align(rowBox:AddChild(button), ALIGN_FILL, ALIGN_FILL)
        local rowSlot = indexList:AddChild(rowBox)
        setPadding(rowSlot, 0, index == 1 and 0 or 4, 0, 0)
        registerDirectActionButton(button)
        state.releaseNotesPickerButtons[index] = {
            kind = "version", widget = button, labelWidget = label,
        }
    end
    return state.renderReleaseNotesVersion()
end

Deferred.ensureReleaseNotesModal = function()
    if P.isValid(state.releaseNotesOverlay) then return true end
    if not state.open or not P.isValid(state.widgetTree)
        or not P.isValid(state.root) then return false end
    local viewportWidth, viewportHeight = logicalViewportSize(state.controller)
    local built = Deferred.buildReleaseNotesModal(state.widgetTree, state.root,
        SettingsUI.releaseNotes.current(), viewportWidth, viewportHeight)
    if built and InputOwner.cookedInputActive()
        and not InputOwner.bindActionButtons(state.directActionButtons) then
        log("version updates native action delegates unavailable; using mouse fallback")
    end
    if not built then
        if P.isValid(state.releaseNotesOverlay) then
            pcall(function() state.releaseNotesOverlay:RemoveFromParent() end)
        end
        state.releaseNotesOverlay = nil
    end
    return built
end

Deferred.openReleaseNotesModal = function(sourceIndex, device)
    if not Deferred.ensureReleaseNotesModal()
        or not P.isValid(state.releaseNotesOverlay) then return false end
    cancelNavigationRepeat()
    FooterGuide.markInputDevice(device or "keyboard")
    state.pointerAction = nil
    state.pendingAboutPointerClose = nil
    state.releaseNotesOpen = true
    state.releaseNotesRevision = state.releaseNotesRevision + 1
    state.releaseNotesReturnFocusIndex = tonumber(sourceIndex) or state.focusIndex
    state.releaseNotesFocusPane = 1
    local currentIndex = 1
    for index, entry in ipairs(SettingsUI.releaseNotes.versions or {}) do
        if tostring(entry.version or "") == tostring(state.version) then
            currentIndex = index
            break
        end
    end
    state.releaseNotesPickerIndex = currentIndex
    state.releaseNotesSelectedIndex = currentIndex
    if not Deferred.selectReleaseNotesVersion(currentIndex) then return false end
    pcall(function() state.releaseNotesOverlay:SetVisibility(VIS_VISIBLE) end)
    state.updateReleaseNotesVisuals()
    focusNavigationRoot()
    return true
end

local function openAboutUrl(urlKey)
    local url = ABOUT_URLS[tostring(urlKey or "")]
    local system = staticObject("/Script/Engine.Default__KismetSystemLibrary")
    if type(url) ~= "string" or url == "" or system == nil then return false end
    local ok, opened = pcall(function()
        if system:CanLaunchURL(url) ~= true then return false end
        system:LaunchURL(url)
        return true
    end)
    return ok and opened == true
end

local function aboutAssetPath(fileName)
    local approved = {
        ["pal-insight-preview.jpg"] = true,
        ["quick-stack-preview.png"] = true,
        ["breeding-calculator-preview.png"] = true,
        ["curseforge.png"] = true,
        ["cratex.png"] = true,
        ["nexus.png"] = true,
        ["steam.png"] = true,
        ["x.png"] = true,
        ["discord.png"] = true,
        ["buy-me-a-coffee.png"] = true,
        ["unicorn.png"] = true,
        ["sports-medal.png"] = true,
        ["red-heart.png"] = true,
    }
    fileName = tostring(fileName or "")
    if approved[fileName] ~= true then return nil end
    local inspected, info = pcall(function() return debug.getinfo(1, "S") end)
    local source = inspected and info ~= nil and info.source or nil
    if type(source) ~= "string" or source == ""
        or source:sub(1, 1) == "=" then return nil end
    if source:sub(1, 1) == "@" then source = source:sub(2) end
    local scriptsDirectory = source:match("^(.*)[/\\][^/\\]+$")
    local modDirectory = scriptsDirectory ~= nil
        and scriptsDirectory:match("^(.*)[/\\][^/\\]+$") or nil
    if type(modDirectory) ~= "string" or modDirectory == "" then return nil end
    return modDirectory .. "/assets/about/" .. fileName
end

local function aboutTexture(fileName)
    local cached = state.aboutTextures[fileName]
    if P.isValid(cached) then return cached end
    local path = aboutAssetPath(fileName)
    local rendering = staticObject("/Script/Engine.Default__KismetRenderingLibrary")
    local world
    if P.isValid(state.widget) then
        pcall(function() world = state.widget:GetWorld() end)
    end
    if not P.isValid(world) then
        local controller = P.currentController()
        if P.isValid(controller) then
            pcall(function() world = controller:GetWorld() end)
        end
    end
    if type(path) ~= "string" or rendering == nil
        or not P.isValid(world) then return nil end
    local texture
    pcall(function() texture = rendering:ImportFileAsTexture2D(world, path) end)
    if P.isValid(texture) then state.aboutTextures[fileName] = texture end
    return P.isValid(texture) and texture or nil
end

local function makeAboutLogoButton(tree, spec)
    spec = type(spec) == "table" and spec or {}
    local box = construct(tree, "/Script/UMG.SizeBox")
    local button = construct(tree, "/Script/UMG.Button")
    local iconBox = construct(tree, "/Script/UMG.SizeBox")
    if box == nil or button == nil or iconBox == nil then
        return nil
    end

    local label = type(spec.label) == "string" and spec.label or nil
    local textOnly = spec.textOnly == true and label ~= nil
    local vertical = label ~= nil and spec.orientation == "vertical"
    local horizontalLeft = label ~= nil and spec.orientation == "horizontal-left"
    local horizontalCenter = label ~= nil
        and spec.orientation == "horizontal-center"
    local requestedWidth = tonumber(spec.width)
    local requestedHeight = tonumber(spec.height)
    local requestedIconWidth = tonumber(spec.iconWidth)
    local requestedIconHeight = tonumber(spec.iconHeight)
    local width = requestedWidth or (label ~= nil and 160.0 or 52.0)
    local height = label ~= nil and not vertical
        and SIZE.aboutLinkHeight
        or tonumber(spec.height) or 52.0
    local iconWidth = label ~= nil and not vertical
        and SIZE.aboutLinkIcon
        or tonumber(spec.iconWidth) or 34.0
    local iconHeight = label ~= nil and not vertical
        and SIZE.aboutLinkIcon
        or tonumber(spec.iconHeight) or 34.0
    if horizontalCenter then
        height = requestedHeight or height
        iconWidth = requestedIconWidth or iconWidth
        iconHeight = requestedIconHeight or iconHeight
    end
    local content
    local labelWidget
    local texture = not textOnly and aboutTexture(spec.asset) or nil
    local image = not textOnly and P.isValid(texture)
        and construct(tree, "/Script/UMG.Image") or nil
    if not textOnly and image == nil then
        iconWidth = tonumber(spec.fallbackIconWidth) or iconWidth
        iconHeight = tonumber(spec.fallbackIconHeight) or iconHeight
    end
    local fallback = nil
    if textOnly then
        content = nil
    elseif image ~= nil then
        pcall(function() image:SetBrushFromTexture(texture, false) end)
        content = image
    else
        fallback = makeText(tree, tostring(spec.fallback or "?"),
            tonumber(spec.fallbackFontSize) or 13, COLORS.text, TEXT_CENTER)
        content = fallback
    end
    if not textOnly and content == nil then return nil end

    local ok = pcall(function()
        if spec.fillWidth ~= true and (requestedWidth ~= nil or label == nil) then
            box:SetWidthOverride(width)
        end
        box:SetHeightOverride(height)
        if not textOnly then
            iconBox:SetWidthOverride(iconWidth)
            iconBox:SetHeightOverride(iconHeight)
            align(iconBox:AddChild(content),
                image ~= nil and ALIGN_FILL or ALIGN_CENTER,
                image ~= nil and ALIGN_FILL or ALIGN_CENTER)
        end

        local buttonContent = iconBox
        if label ~= nil then
            local contentPanel = not textOnly and construct(tree, vertical
                and "/Script/UMG.VerticalBox" or "/Script/UMG.HorizontalBox") or nil
            labelWidget = makeText(tree, label,
                tonumber(spec.labelFontSize) or 11, COLORS.text,
                (horizontalLeft or horizontalCenter) and TEXT_LEFT
                    or TEXT_CENTER)
            if labelWidget == nil or (not textOnly and contentPanel == nil) then
                error("labeled About content")
            end
            if textOnly then
                labelWidget:SetAutoWrapText(true)
                buttonContent = labelWidget
            elseif vertical then
                labelWidget:SetAutoWrapText(true)
                align(contentPanel:AddChild(iconBox), ALIGN_CENTER, ALIGN_CENTER)
                local labelSlot = contentPanel:AddChild(labelWidget)
                setPadding(labelSlot, 0, SIZE.aboutLinkGap, 0, 0)
                align(labelSlot, ALIGN_CENTER, ALIGN_CENTER)
            else
                local iconColumn = construct(tree, "/Script/UMG.SizeBox")
                if iconColumn == nil then error("About icon column") end
                if horizontalCenter then
                    iconColumn:SetWidthOverride(iconWidth + 8.0)
                else
                    iconBox:SetWidthOverride(SIZE.aboutLinkIcon)
                    iconBox:SetHeightOverride(SIZE.aboutLinkIcon)
                    iconColumn:SetWidthOverride(SIZE.aboutLinkIconColumn)
                end
                align(iconColumn:AddChild(iconBox), ALIGN_CENTER, ALIGN_CENTER)
                align(contentPanel:AddChild(iconColumn), ALIGN_CENTER, ALIGN_CENTER)
                local labelSlot = contentPanel:AddChild(labelWidget)
                if not horizontalCenter then setFill(labelSlot) end
                setPadding(labelSlot, SIZE.aboutLinkGap * 0.5, 0,
                    horizontalCenter and 0 or SIZE.aboutLinkGap * 0.5, 0)
                align(labelSlot, ALIGN_LEFT, ALIGN_CENTER)
                labelWidget:SetAutoWrapText(true)
            end
            if not textOnly then buttonContent = contentPanel end
        end

        button.bIsFocusable = true
        button:SetToolTipText(FText(spec.tooltip or label or ""))
        local style = button.WidgetStyle
        local padding = label ~= nil and not vertical
            and { Left = 6, Top = 0, Right = 6, Bottom = 0 }
            or { Left = 0, Top = 0, Right = 0, Bottom = 0 }
        style.NormalPadding = padding
        style.PressedPadding = padding
        button.WidgetStyle = style
        styleHeaderButton(button, spec.role or "aboutLink", false, false, false)
        align(button:AddChild(buttonContent),
            horizontalLeft and ALIGN_FILL or ALIGN_CENTER, ALIGN_CENTER)
        if P.isValid(labelWidget) then
            labelWidget:SetColorAndOpacity({
                SpecifiedColor = COLORS.text,
                ColorUseRule = 2,
            })
        end
        box:AddChild(button)
    end)
    if not ok then return nil end
    local record = {
        box = box, widget = button,
        visualButton = button, directButton = true,
        labelWidget = labelWidget or fallback, label = label,
        tooltip = spec.tooltip or label,
        urlKey = spec.urlKey,
        kind = spec.kind or (spec.urlKey ~= nil and "link" or "close"),
        rosterMode = spec.rosterMode,
        role = spec.role or "aboutLink",
        navRow = spec.navRow,
        navColumn = spec.navColumn,
    }
    registerDirectActionButton(button)
    if spec.deferRegistration ~= true then
        state.aboutActions[#state.aboutActions + 1] = record
    end
    return record
end

local function makeAboutAction(tree, label, urlKey, width, role, height, fontSize,
        navRow, navColumn)
    local box = construct(tree, "/Script/UMG.SizeBox")
    local button = construct(tree, "/Script/UMG.Button")
    local text = makeText(tree, label, fontSize or 13, COLORS.text, TEXT_CENTER)
    if box == nil or button == nil or text == nil then return nil end
    local ok = pcall(function()
        box:SetWidthOverride(width or 160.0)
        box:SetHeightOverride(height or 40.0)
        button.bIsFocusable = true
        button:SetToolTipText(FText(label or ""))
        local style = button.WidgetStyle
        local padding = { Left = 12, Top = 4, Right = 12, Bottom = 4 }
        style.NormalPadding = padding
        style.PressedPadding = padding
        button.WidgetStyle = style
        text:SetColorAndOpacity({
            SpecifiedColor = COLORS.text,
            ColorUseRule = 2,
        })
        styleHeaderButton(button, role or "about", false, false, false)
        align(button:AddChild(text), ALIGN_CENTER, ALIGN_CENTER)
        align(box:AddChild(button), ALIGN_FILL, ALIGN_FILL)
    end)
    if not ok then return nil end
    local record = {
        box = box, widget = button, visualButton = button,
        directButton = true,
        labelWidget = text, label = label, urlKey = urlKey,
        kind = urlKey ~= nil and "link" or "close",
        role = role or "about",
        navRow = navRow,
        navColumn = navColumn,
    }
    registerDirectActionButton(button)
    state.aboutActions[#state.aboutActions + 1] = record
    return record
end

local function buildAboutPreviewOverlay(tree, root, strings,
        viewportWidth, viewportHeight)
    local overlay = construct(tree, "/Script/UMG.CanvasPanel")
    local dim = construct(tree, "/Script/UMG.Border")
    local previewBox = construct(tree, "/Script/UMG.SizeBox")
    local previewOutline = construct(tree, "/Script/UMG.Border")
    local close = makeIconTrigger(tree, "×", strings.close, "close")
    local hintBox = construct(tree, "/Script/UMG.SizeBox")
    local hint = makeText(tree, "Esc / B · " .. tostring(strings.close or "Close"),
        11, COLORS.muted, TEXT_CENTER)
    if overlay == nil or dim == nil or previewBox == nil
        or previewOutline == nil or close == nil or hintBox == nil
        or hint == nil then return false end

    local availableWidth = math.max(1.0,
        (tonumber(viewportWidth) or 1280.0) - 64.0)
    local availableHeight = math.max(1.0,
        (tonumber(viewportHeight) or 720.0) - 104.0)
    local aspect = 1668.0 / 932.0
    local previewWidth = math.min(
        SIZE.aboutPreviewMaxWidth, availableWidth, availableHeight * aspect)
    local previewHeight = previewWidth / aspect

    local texture = aboutTexture("breeding-calculator-preview.png")
    local previewContent = P.isValid(texture)
        and construct(tree, "/Script/UMG.Image") or nil
    if previewContent ~= nil then
        pcall(function() previewContent:SetBrushFromTexture(texture, false) end)
    else
        previewContent = makeText(tree,
            strings.aboutCalculator or "Palworld Breeding Calculator",
            13, COLORS.text, TEXT_CENTER)
    end
    if previewContent == nil then return false end

    local ok = pcall(function()
        overlay:SetVisibility(VIS_COLLAPSED)
        dim:SetBrushColor(COLORS.modal)
        local overlaySlot = root:AddChild(overlay)
        overlaySlot:SetAnchors({
            Minimum = { X = 0.0, Y = 0.0 },
            Maximum = { X = 1.0, Y = 1.0 },
        })
        overlaySlot:SetOffsets({ Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0 })
        overlaySlot:SetZOrder(4)
        local dimSlot = overlay:AddChild(dim)
        dimSlot:SetAnchors({
            Minimum = { X = 0.0, Y = 0.0 },
            Maximum = { X = 1.0, Y = 1.0 },
        })
        dimSlot:SetOffsets({ Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0 })
        dimSlot:SetZOrder(0)

        previewBox:SetWidthOverride(previewWidth)
        previewBox:SetHeightOverride(previewHeight)
        local previewSlot = overlay:AddChild(previewBox)
        previewSlot:SetAnchors({
            Minimum = { X = 0.5, Y = 0.5 },
            Maximum = { X = 0.5, Y = 0.5 },
        })
        previewSlot:SetAlignment({ X = 0.5, Y = 0.5 })
        previewSlot:SetPosition({ X = 0.0, Y = -12.0 })
        previewSlot:SetSize({ X = previewWidth, Y = previewHeight })
        previewSlot:SetZOrder(1)
        previewOutline:SetBrushColor(COLORS.border)
        previewOutline:SetPadding({ Left = 1, Top = 1, Right = 1, Bottom = 1 })
        align(previewOutline:AddChild(previewContent), ALIGN_FILL, ALIGN_FILL)
        align(previewBox:AddChild(previewOutline), ALIGN_FILL, ALIGN_FILL)

        local closeSlot = overlay:AddChild(close.box)
        closeSlot:SetAnchors({
            Minimum = { X = 0.5, Y = 0.5 },
            Maximum = { X = 0.5, Y = 0.5 },
        })
        closeSlot:SetAlignment({ X = 1.0, Y = 0.0 })
        closeSlot:SetSize({ X = SIZE.headerAction, Y = SIZE.headerAction })
        closeSlot:SetPosition({
            X = previewWidth * 0.5 - 8.0,
            Y = -previewHeight * 0.5 + 8.0,
        })
        closeSlot:SetZOrder(2)

        hintBox:SetWidthOverride(previewWidth)
        hintBox:SetHeightOverride(24.0)
        align(hintBox:AddChild(hint), ALIGN_CENTER, ALIGN_CENTER)
        local hintSlot = overlay:AddChild(hintBox)
        hintSlot:SetAnchors({
            Minimum = { X = 0.5, Y = 0.5 },
            Maximum = { X = 0.5, Y = 0.5 },
        })
        hintSlot:SetAlignment({ X = 0.5, Y = 0.0 })
        hintSlot:SetPosition({ X = 0.0, Y = previewHeight * 0.5 })
        hintSlot:SetSize({ X = previewWidth, Y = 24.0 })
        hintSlot:SetZOrder(2)
    end)
    if not ok then return false end
    state.aboutPreviewOverlay = overlay
    state.aboutPreviewCloseWidget = close.widget
    state.aboutPreviewCloseAction = close
    return true
end

moveAboutFocus = function(horizontal, vertical)
    local actions = state.aboutActions or {}
    local count = #actions
    if count < 1 then return false end
    local currentIndex = math.max(1,
        math.min(count, tonumber(state.aboutFocusIndex) or 1))
    local current = actions[currentIndex]
    if type(current) ~= "table" then return false end
    local currentRow = tonumber(current.navRow) or currentIndex
    local currentColumn = tonumber(current.navColumn) or 1
    horizontal = tonumber(horizontal) or 0
    vertical = tonumber(vertical) or 0
    local targetIndex
    if horizontal ~= 0 then
        local targetColumn = currentColumn + (horizontal < 0 and -1 or 1)
        for index, action in ipairs(actions) do
            if tonumber(action.navRow) == currentRow
                and tonumber(action.navColumn) == targetColumn then
                targetIndex = index
                break
            end
        end
        if targetIndex == nil then return true end
        state.aboutPreferredColumn = targetColumn
    elseif vertical ~= 0 then
        local rows = {}
        local minRow, maxRow = currentRow, currentRow
        for _, action in ipairs(actions) do
            local row = tonumber(action.navRow)
            if row ~= nil then
                rows[row] = true
                minRow = math.min(minRow, row)
                maxRow = math.max(maxRow, row)
            end
        end
        local targetRow = currentRow
        local step = vertical < 0 and -1 or 1
        repeat
            targetRow = targetRow + step
            if targetRow < minRow then targetRow = maxRow end
            if targetRow > maxRow then targetRow = minRow end
        until rows[targetRow] == true or targetRow == currentRow
        local preferred = tonumber(state.aboutPreferredColumn) or currentColumn
        local bestDistance
        for index, action in ipairs(actions) do
            if tonumber(action.navRow) == targetRow then
                local column = tonumber(action.navColumn) or 1
                local distance = math.abs(column - preferred)
                if bestDistance == nil or distance < bestDistance then
                    targetIndex = index
                    bestDistance = distance
                end
            end
        end
        if targetIndex == nil then return true end
    else
        return false
    end
    state.aboutFocusIndex = targetIndex
    local action = actions[targetIndex]
    focusNavigationRoot()
    if type(action) == "table" and action.kind ~= "close"
        and P.isValid(state.aboutScroll)
        and P.isValid(action.box) then
        pcall(function()
            state.aboutScroll:ScrollWidgetIntoView(action.box, false, 0, 12.0)
        end)
    end
    refreshTriggerSurfaces()
    return true
end

activateAboutAction = function()
    local action = (state.aboutActions or {})[
        tonumber(state.aboutFocusIndex) or 1]
    if type(action) ~= "table" then return false end
    if action.kind == "close" then return closeAboutModal(true) end
    if action.kind == "preview" then return Deferred.openAboutPreview() end
    if action.kind == "roster" then
        return Deferred.openAboutRoster(action.rosterMode)
    end
    if action.kind == "link" then
        local opened = openAboutUrl(action.urlKey)
        if not opened then log("About link could not be opened: "
            .. tostring(action.urlKey)) end
        focusNavigationRoot()
        return true
    end
    return false
end

closeAboutPreview = function(restoreFocus, refreshVisuals)
    local wasOpen = state.aboutPreviewOpen == true
    if not wasOpen then return false end
    state.pendingAboutPointerClose = nil
    state.aboutPreviewOpen = false
    state.aboutPreviewSourceIndex = nil
    state.aboutRevision = state.aboutRevision + 1
    if P.isValid(state.aboutPreviewOverlay) then
        pcall(function() state.aboutPreviewOverlay:SetVisibility(VIS_COLLAPSED) end)
    end
    if restoreFocus == true then focusNavigationRoot() end
    if refreshVisuals ~= false then refreshTriggerSurfaces() end
    return true
end

Deferred.openAboutPreview = function()
    if state.aboutOpen ~= true or not P.isValid(state.aboutPreviewOverlay) then
        return false
    end
    closeAboutRoster(false, false)
    state.pendingAboutPointerClose = nil
    state.aboutPreviewSourceIndex = state.aboutFocusIndex
    state.aboutPreviewOpen = true
    state.aboutRevision = state.aboutRevision + 1
    pcall(function() state.aboutPreviewOverlay:SetVisibility(VIS_VISIBLE) end)
    focusNavigationRoot()
    refreshTriggerSurfaces()
    return true
end

closeAboutRoster = function(restoreFocus, refreshVisuals)
    local wasOpen = state.aboutRosterOpen == true
    if not wasOpen then return false end
    local mode = state.aboutRosterMode
    local overlay = (state.aboutRosterOverlays or {})[mode]
    state.pendingAboutPointerClose = nil
    state.aboutRosterOpen = false
    state.aboutRosterMode = nil
    state.aboutRevision = state.aboutRevision + 1
    if P.isValid(overlay) then
        pcall(function() overlay:SetVisibility(VIS_COLLAPSED) end)
    end
    if restoreFocus == true then focusNavigationRoot() end
    if refreshVisuals ~= false then refreshTriggerSurfaces() end
    return true
end

Deferred.openAboutRoster = function(mode)
    if state.aboutOpen ~= true
        or (mode ~= "thanks" and mode ~= "supporters") then return false end
    local overlay = (state.aboutRosterOverlays or {})[mode]
    if not P.isValid(overlay) then return false end
    state.pendingAboutPointerClose = nil
    state.aboutRosterMode = mode
    state.aboutRosterOpen = true
    state.aboutRevision = state.aboutRevision + 1
    pcall(function()
        overlay:SetVisibility(VIS_VISIBLE)
    end)
    focusNavigationRoot()
    refreshTriggerSurfaces()
    return true
end

closeAboutModal = function(restoreFocus)
    local wasOpen = state.aboutOpen == true
    state.pendingAboutPointerClose = nil
    local previewClosed = closeAboutPreview(false, false)
    local rosterClosed = closeAboutRoster(false, false)
    state.aboutOpen = false
    if wasOpen then state.aboutRevision = state.aboutRevision + 1 end
    if wasOpen and P.isValid(state.aboutOverlay) then
        pcall(function() state.aboutOverlay:SetVisibility(VIS_COLLAPSED) end)
    end
    local focusRestored = false
    if restoreFocus == true and state.aboutReturnFocusIndex ~= nil then
        focusRestored = focusEntry(
            state.aboutReturnFocusIndex, state.lastInputDevice, false)
    end
    state.aboutReturnFocusIndex = nil
    if focusRestored ~= true and (wasOpen or previewClosed or rosterClosed) then
        refreshTriggerSurfaces()
    end
    return wasOpen
end

Deferred.openAboutModal = function()
    if not Deferred.ensureAboutModal() then return false end
    closeChoiceModal(false)
    local edit = state.numberEdit
    if type(edit) == "table" and type(edit.control) == "table" then
        commitNumberEditor(edit.control, "about-open", true)
    end
    state.aboutReturnFocusIndex = state.focusIndex
    state.aboutFocusIndex = tonumber(state.aboutDefaultFocusIndex) or 1
    local defaultAction = (state.aboutActions or {})[state.aboutFocusIndex]
    state.aboutPreferredColumn = type(defaultAction) == "table"
        and (tonumber(defaultAction.navColumn) or 1) or 1
    state.pendingAboutPointerClose = nil
    state.aboutPreviewOpen = false
    state.aboutPreviewSourceIndex = nil
    state.aboutOpen = true
    state.aboutRevision = state.aboutRevision + 1
    pcall(function()
        state.aboutOverlay:SetVisibility(VIS_VISIBLE)
        if P.isValid(state.aboutScroll) then state.aboutScroll:SetScrollOffset(0.0) end
    end)
    focusNavigationRoot()
    refreshTriggerSurfaces()
    return true
end

Deferred.ensureAboutModal = function()
    if P.isValid(state.aboutOverlay) then return true end
    if not state.open or not P.isValid(state.widgetTree)
        or not P.isValid(state.root) then return false end
    local viewportWidth, viewportHeight, viewportScale =
        logicalViewportSize(state.controller)
    local built = Deferred.buildAboutModal(state.widgetTree, state.root, currentStrings(),
        viewportWidth, viewportHeight, viewportScale)
    if built and InputOwner.cookedInputActive()
        and not InputOwner.bindActionButtons(state.directActionButtons) then
        log("About native action delegates unavailable; using mouse fallback")
    end
    return built
end

Deferred.buildAboutModal = function(tree, root, strings, viewportWidth, viewportHeight,
        viewportScale)
    local overlay = construct(tree, "/Script/UMG.CanvasPanel")
    local dim = construct(tree, "/Script/UMG.Border")
    local cardBox = construct(tree, "/Script/UMG.SizeBox")
    local outline = construct(tree, "/Script/UMG.Border")
    local panel = construct(tree, "/Script/UMG.Border")
    local content = construct(tree, "/Script/UMG.VerticalBox")
    local header = construct(tree, "/Script/UMG.HorizontalBox")
    local identity = construct(tree, "/Script/UMG.VerticalBox")
    local closeStack = construct(tree, "/Script/UMG.VerticalBox")
    local closeHintBox = construct(tree, "/Script/UMG.SizeBox")
    local titleRow = construct(tree, "/Script/UMG.HorizontalBox")
    local versionBox = construct(tree, "/Script/UMG.SizeBox")
    local versionBadge = construct(tree, "/Script/UMG.Border")
    local scroll = construct(tree, "/Script/UMG.ScrollBox")
    local body = construct(tree, "/Script/UMG.VerticalBox")
    local title = makeText(tree, "Quick Stack", 20, COLORS.text, TEXT_LEFT)
    local version = makeText(tree, "v" .. tostring(state.version), 11,
        COLORS.muted, TEXT_CENTER)
    local summary = makeText(tree, strings.aboutSummary or "", 12,
        COLORS.muted, TEXT_LEFT)
    local close = makeIconTrigger(tree, "×", strings.close, "close")
    local closeHint = makeText(tree, "", 11, COLORS.muted, TEXT_CENTER)
    if overlay == nil or dim == nil or cardBox == nil or outline == nil
        or panel == nil or content == nil or header == nil or identity == nil
        or closeStack == nil or closeHintBox == nil or closeHint == nil
        or titleRow == nil or versionBox == nil or versionBadge == nil
        or scroll == nil or body == nil or title == nil or version == nil
        or summary == nil or close == nil then return false end

    state.aboutActions = {}
    state.aboutFocusIndex = 1
    state.aboutDefaultFocusIndex = nil
    state.aboutPreferredColumn = 2
    state.aboutScroll = scroll
    state.aboutActionHint = closeHint
    state.aboutRosterOverlays = {}
    state.aboutRosterCloseWidgets = {}
    state.aboutRosterCloseActions = {}

    local width = math.min(SIZE.aboutWidth,
        math.max(320.0, (tonumber(viewportWidth) or 1280.0) - 48.0))
    local maxHeight = math.min(SIZE.aboutHeight,
        math.max(360.0, (tonumber(viewportHeight) or 720.0) - 48.0))
    local aboutContentWidth = math.max(1.0, width
        - 2.0 * SIZE.windowOutline - 32.0)
    local scrollContentWidth = math.max(
        1.0, aboutContentWidth - SIZE.scrollbarGutter)
    local aboutCardInnerWidth = math.max(1.0,
        scrollContentWidth - (SIZE.aboutSectionGap * 2.0))
    local summaryWrapWidth = math.max(120.0,
        aboutContentWidth - SIZE.headerAction - SIZE.aboutSectionGap)
    local creatorCopyWrapWidth = math.max(120.0, aboutCardInnerWidth
        - (SIZE.aboutCreatorLinkWidth * 2.0)
        - (SIZE.aboutSectionGap * 2.0))
    local communityColumnWidth = SIZE.aboutCommunityWidth
    local supportCopyWrapWidth = math.max(96.0, aboutCardInnerWidth
        - communityColumnWidth - SIZE.aboutLinkGap
        - SIZE.aboutSupportActionWidth - 36.0)
    local rosterWidth = math.min(SIZE.aboutRosterWidth,
        math.max(320.0, (tonumber(viewportWidth) or 1280.0) - 64.0))
    local rosterMaxHeight = math.min(SIZE.aboutRosterMaxHeight,
        math.max(300.0, (tonumber(viewportHeight) or 720.0) - 96.0))

    local function addCopy(parent, value, size, color, top, wrapWidth)
        local widget = makeText(tree, value or "", size, color, TEXT_LEFT)
        if widget == nil then return nil end
        if wrapWidth ~= nil then setTextWrap(widget, wrapWidth) end
        local slot = parent:AddChild(widget)
        setPadding(slot, 0, top or 0, 0, 0)
        align(slot, ALIGN_LEFT, ALIGN_CENTER)
        return widget
    end

    local function makeCard(addBottomGap)
        local card = construct(tree, "/Script/UMG.Border")
        local stack = construct(tree, "/Script/UMG.VerticalBox")
        if card == nil or stack == nil then return nil, nil end
        card:SetBrushColor(mixLinearColor(COLORS.content, COLORS.control, 0.30))
        card:SetPadding({ Left = 12, Top = 12, Right = 12, Bottom = 12 })
        align(card:AddChild(stack), ALIGN_FILL, ALIGN_FILL)
        local slot = body:AddChild(card)
        setPadding(slot, 0, 0, 0,
            addBottomGap == false and 0 or SIZE.aboutSectionGap)
        align(slot, ALIGN_FILL, ALIGN_FILL)
        return card, stack
    end

    local function addCreditGroup(parent, label, names, accent, singleColumn)
        if type(names) ~= "table" or #names == 0 then return true end
        local group = construct(tree, "/Script/UMG.Border")
        local groupStack = construct(tree, "/Script/UMG.VerticalBox")
        local columns = construct(tree, "/Script/UMG.HorizontalBox")
        local creditColumns = {}
        local columnCount = singleColumn == true and 1
            or (rosterWidth >= 560.0 and 3 or 2)
        if group == nil or groupStack == nil or columns == nil then
            return false
        end
        for index = 1, columnCount do
            creditColumns[index] = construct(tree, "/Script/UMG.VerticalBox")
            if creditColumns[index] == nil then return false end
        end
        group:SetBrushColor(mixLinearColor(COLORS.control, accent, 0.12))
        group:SetPadding({ Left = 12, Top = 10, Right = 12, Bottom = 10 })
        align(group:AddChild(groupStack), ALIGN_FILL, ALIGN_FILL)
        local groupSlot = parent:AddChild(group)
        setPadding(groupSlot, 0, 0, 0, 8)
        addCopy(groupStack, label, 11, accent, 0, rosterWidth - 58.0)
        local columnsSlot = groupStack:AddChild(columns)
        setPadding(columnsSlot, 0, 6, 0, 0)
        setFill(columnsSlot)
        for index, column in ipairs(creditColumns) do
            local columnSlot = columns:AddChild(column)
            setFill(columnSlot)
            if index < columnCount then
                setPadding(columnSlot, 0, 0, 8, 0)
            end
        end
        local function displayName(entry)
            if type(entry) ~= "table" then return tostring(entry) end
            local prefix = ""
            if type(entry.utf8Prefix) == "table" then
                local ok, value = pcall(function()
                    return string.char(table.unpack(entry.utf8Prefix))
                end)
                if ok then prefix = value end
            end
            return prefix .. (prefix ~= "" and " " or "")
                .. tostring(entry.name or "")
        end
        local function creditIconAsset(entry)
            if type(entry) ~= "table" or type(entry.utf8Prefix) ~= "table" then
                return nil
            end
            local bytes = entry.utf8Prefix
            if #bytes == 4 and bytes[1] == 0xF0 and bytes[2] == 0x9F
                and bytes[3] == 0xA6 and bytes[4] == 0x84 then
                return "unicorn.png"
            end
            return nil
        end
        for index, entry in ipairs(names) do
            local column = creditColumns[((index - 1) % columnCount) + 1]
            local name = type(entry) == "table"
                and tostring(entry.name or "") or tostring(entry)
            local iconAsset = creditIconAsset(entry)
            local iconTexture = iconAsset ~= nil
                and aboutTexture(iconAsset) or nil
            local mounted = false
            if P.isValid(iconTexture) then
                local row = construct(tree, "/Script/UMG.HorizontalBox")
                local iconBox = construct(tree, "/Script/UMG.SizeBox")
                local image = construct(tree, "/Script/UMG.Image")
                local labelWidget = makeText(tree, name, 12,
                    COLORS.text, TEXT_LEFT)
                if row ~= nil and iconBox ~= nil and image ~= nil
                    and labelWidget ~= nil then
                    local applied = pcall(function()
                        image:SetBrushFromTexture(iconTexture, false)
                    end)
                    if applied then
                        iconBox:SetWidthOverride(12.0)
                        iconBox:SetHeightOverride(12.0)
                        align(iconBox:AddChild(image), ALIGN_FILL, ALIGN_FILL)
                        local iconSlot = row:AddChild(iconBox)
                        setPadding(iconSlot, 0, 0, SIZE.aboutLinkGap * 0.5, 0)
                        align(iconSlot, ALIGN_LEFT, ALIGN_CENTER)
                        align(row:AddChild(labelWidget), ALIGN_LEFT, ALIGN_CENTER)
                        local rowSlot = column:AddChild(row)
                        setPadding(rowSlot, 0, 2, 0, 2)
                        mounted = true
                    end
                end
            end
            if not mounted then
                local labelWidget = makeText(tree, displayName(entry), 12,
                    COLORS.text, TEXT_LEFT)
                if labelWidget == nil then return false end
                local labelSlot = column:AddChild(labelWidget)
                setPadding(labelSlot, 0, 2, 0, 2)
                align(labelSlot, ALIGN_LEFT, ALIGN_CENTER)
            end
        end
        return true
    end

    local function addAction(parent, label, urlKey, width, left, height,
            kind, rosterMode, top, fontSize)
        local action = makeAboutAction(tree, label, urlKey, width, "about", height,
            fontSize)
        if action == nil then return nil end
        if kind ~= nil then action.kind = kind end
        action.rosterMode = rosterMode
        local slot = parent:AddChild(action.box)
        setPadding(slot, left or 0, top or 0, 0, 0)
        align(slot, ALIGN_LEFT, ALIGN_CENTER)
        return action
    end

    local function buildRosterOverlay(mode)
        local rosterOverlay = construct(tree, "/Script/UMG.CanvasPanel")
        local rosterDim = construct(tree, "/Script/UMG.Border")
        local rosterBox = construct(tree, "/Script/UMG.SizeBox")
        local rosterOutline = construct(tree, "/Script/UMG.Border")
        local rosterPanel = construct(tree, "/Script/UMG.Border")
        local rosterContent = construct(tree, "/Script/UMG.VerticalBox")
        local rosterHeader = construct(tree, "/Script/UMG.HorizontalBox")
        local rosterScroll = construct(tree, "/Script/UMG.ScrollBox")
        local rosterBody = construct(tree, "/Script/UMG.VerticalBox")
        local thanks = mode == "thanks"
        local titleValue = thanks and strings.aboutSpecialThanks
            or strings.aboutSupporters
        local descriptionValue = thanks and strings.aboutSpecialThanksDescription
            or strings.aboutSupportersDescription
        local emptyValue = thanks and strings.aboutSpecialThanksEmpty
            or strings.aboutSupportersEmpty
        local rosterTitle = makeText(tree, titleValue or "", 18,
            COLORS.text, TEXT_LEFT)
        local rosterDescription = makeText(tree, descriptionValue or "", 11,
            COLORS.muted, TEXT_LEFT)
        local rosterClose = makeIconTrigger(tree, "×", strings.close, "close")
        if rosterOverlay == nil or rosterDim == nil or rosterBox == nil
            or rosterOutline == nil or rosterPanel == nil
            or rosterContent == nil or rosterHeader == nil
            or rosterScroll == nil or rosterBody == nil
            or rosterTitle == nil or rosterDescription == nil
            or rosterClose == nil then return false end

        state.aboutRosterOverlays[mode] = rosterOverlay
        state.aboutRosterCloseWidgets[mode] = rosterClose.widget
        state.aboutRosterCloseActions[mode] = rosterClose
        local ok = pcall(function()
            rosterOverlay:SetVisibility(VIS_COLLAPSED)
            rosterDim:SetBrushColor(COLORS.modal)
            local overlaySlot = root:AddChild(rosterOverlay)
            overlaySlot:SetAnchors({
                Minimum = { X = 0.0, Y = 0.0 },
                Maximum = { X = 1.0, Y = 1.0 },
            })
            overlaySlot:SetOffsets({
                Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0,
            })
            overlaySlot:SetZOrder(4)

            local dimSlot = rosterOverlay:AddChild(rosterDim)
            dimSlot:SetAnchors({
                Minimum = { X = 0.0, Y = 0.0 },
                Maximum = { X = 1.0, Y = 1.0 },
            })
            dimSlot:SetOffsets({
                Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0,
            })
            dimSlot:SetZOrder(0)

            rosterBox:SetWidthOverride(rosterWidth)
            rosterBox:SetMaxDesiredHeight(rosterMaxHeight)
            local boxSlot = rosterOverlay:AddChild(rosterBox)
            boxSlot:SetAnchors({
                Minimum = { X = 0.5, Y = 0.5 },
                Maximum = { X = 0.5, Y = 0.5 },
            })
            boxSlot:SetAlignment({ X = 0.5, Y = 0.5 })
            boxSlot:SetPosition({ X = 0.0, Y = 0.0 })
            boxSlot:SetAutoSize(true)
            boxSlot:SetZOrder(1)

            rosterOutline:SetBrushColor(COLORS.border)
            rosterOutline:SetPadding({ Left = 1, Top = 1, Right = 1, Bottom = 1 })
            rosterPanel:SetBrushColor(COLORS.content)
            rosterPanel:SetPadding({ Left = 16, Top = 16, Right = 16, Bottom = 16 })
            align(rosterPanel:AddChild(rosterContent), ALIGN_FILL, ALIGN_FILL)
            align(rosterOutline:AddChild(rosterPanel), ALIGN_FILL, ALIGN_FILL)
            align(rosterBox:AddChild(rosterOutline), ALIGN_FILL, ALIGN_FILL)

            local titleSlot = rosterHeader:AddChild(rosterTitle)
            setFill(titleSlot)
            align(titleSlot, ALIGN_LEFT, ALIGN_CENTER)
            align(rosterHeader:AddChild(rosterClose.box), ALIGN_RIGHT, ALIGN_CENTER)
            local headerSlot = rosterContent:AddChild(rosterHeader)
            setPadding(headerSlot, 0, 0, 0, 8)

            setTextWrap(rosterDescription, rosterWidth - 34.0)
            local descriptionSlot = rosterContent:AddChild(rosterDescription)
            setPadding(descriptionSlot, 0, 0, 0, 12)

            rosterScroll:SetAlwaysShowScrollbar(false)
            rosterScroll.AlwaysShowScrollbarTrack = false
            align(rosterScroll:AddChild(rosterBody), ALIGN_FILL, ALIGN_LEFT)
            local scrollSlot = rosterContent:AddChild(rosterScroll)
            setFill(scrollSlot)
            align(scrollSlot, ALIGN_FILL, ALIGN_FILL)
        end)
        if not ok then return false end

        local credits = ABOUT_CREDITS[mode] or {}
        local hasCredits = type(credits.nexus) == "table" and #credits.nexus > 0
            or type(credits.steam) == "table" and #credits.steam > 0
        if hasCredits then
            if not addCreditGroup(rosterBody, "NEXUS MODS", credits.nexus,
                    COLORS.actionWarning)
                or not addCreditGroup(rosterBody, "STEAM WORKSHOP", credits.steam,
                    COLORS.actionInfo) then return false end
        else
            local emptyCard = construct(tree, "/Script/UMG.Border")
            local emptyText = makeText(tree, emptyValue or "", 13,
                COLORS.muted, TEXT_CENTER)
            if emptyCard == nil or emptyText == nil then return false end
            local mounted = pcall(function()
                emptyCard:SetBrushColor(COLORS.control)
                emptyCard:SetPadding({ Left = 16, Top = 20, Right = 16, Bottom = 20 })
                align(emptyCard:AddChild(emptyText), ALIGN_CENTER, ALIGN_CENTER)
                align(rosterBody:AddChild(emptyCard), ALIGN_FILL, ALIGN_FILL)
            end)
            if not mounted then return false end
        end
        return true
    end

    local ok = pcall(function()
        overlay:SetVisibility(VIS_COLLAPSED)
        dim:SetBrushColor(COLORS.modal)
        local overlaySlot = root:AddChild(overlay)
        overlaySlot:SetAnchors({
            Minimum = { X = 0.0, Y = 0.0 },
            Maximum = { X = 1.0, Y = 1.0 },
        })
        overlaySlot:SetOffsets({ Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0 })
        overlaySlot:SetZOrder(3)
        local dimSlot = overlay:AddChild(dim)
        dimSlot:SetAnchors({
            Minimum = { X = 0.0, Y = 0.0 },
            Maximum = { X = 1.0, Y = 1.0 },
        })
        dimSlot:SetOffsets({ Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0 })
        dimSlot:SetZOrder(0)
        cardBox:SetWidthOverride(width)
        cardBox:SetMaxDesiredHeight(maxHeight)
        outline:SetBrushColor(COLORS.outline)
        outline:SetPadding({ Left = 1, Top = 1, Right = 1, Bottom = 1 })
        panel:SetBrushColor(COLORS.content)
        panel:SetPadding({ Left = 16, Top = 16, Right = 16, Bottom = 12 })
        align(panel:AddChild(content), ALIGN_FILL, ALIGN_FILL)
        align(outline:AddChild(panel), ALIGN_FILL, ALIGN_FILL)
        align(cardBox:AddChild(outline), ALIGN_FILL, ALIGN_FILL)
        local cardSlot = overlay:AddChild(cardBox)
        cardSlot:SetAnchors({
            Minimum = { X = 0.5, Y = 0.5 },
            Maximum = { X = 0.5, Y = 0.5 },
        })
        cardSlot:SetAlignment({ X = 0.5, Y = 0.5 })
        cardSlot:SetPosition({ X = 0.0, Y = 0.0 })
        cardSlot:SetAutoSize(true)
        cardSlot:SetZOrder(1)

        local identitySlot = header:AddChild(identity)
        setFill(identitySlot)
        setPadding(identitySlot, 0, 0, 12, 0)
        align(identitySlot, ALIGN_LEFT, ALIGN_CENTER)
        align(identity:AddChild(titleRow), ALIGN_FILL, ALIGN_CENTER)
        align(titleRow:AddChild(title), ALIGN_LEFT, ALIGN_CENTER)
        versionBox:SetHeightOverride(24.0)
        versionBadge:SetBrushColor(COLORS.control)
        versionBadge:SetPadding({ Left = 8, Top = 2, Right = 8, Bottom = 2 })
        align(versionBadge:AddChild(version), ALIGN_CENTER, ALIGN_CENTER)
        align(versionBox:AddChild(versionBadge), ALIGN_FILL, ALIGN_FILL)
        local versionSlot = titleRow:AddChild(versionBox)
        setPadding(versionSlot, 8, 0, 0, 0)
        align(versionSlot, ALIGN_LEFT, ALIGN_CENTER)
        setTextWrap(summary, summaryWrapWidth)
        local summarySlot = identity:AddChild(summary)
        setPadding(summarySlot, 0, 6, 0, 0)
        align(summarySlot, ALIGN_LEFT, ALIGN_CENTER)
        align(closeStack:AddChild(close.box), ALIGN_CENTER, ALIGN_CENTER)
        closeHintBox:SetHeightOverride(16.0)
        align(closeHintBox:AddChild(closeHint), ALIGN_CENTER, ALIGN_CENTER)
        align(closeStack:AddChild(closeHintBox), ALIGN_CENTER, ALIGN_CENTER)
        align(header:AddChild(closeStack), ALIGN_CENTER, ALIGN_FILL)
        local headerSlot = content:AddChild(header)
        setPadding(headerSlot, 0, 0, 0, 12)
        align(headerSlot, ALIGN_FILL, ALIGN_FILL)

        scroll:SetAlwaysShowScrollbar(false)
        scroll.AlwaysShowScrollbarTrack = false
        align(scroll:AddChild(body), ALIGN_FILL, ALIGN_LEFT)
        local scrollSlot = content:AddChild(scroll)
        setFill(scrollSlot)
        align(scrollSlot, ALIGN_FILL, ALIGN_FILL)

        local productsCard, products = makeCard()
        local productShelfInnerWidth = math.max(1.0,
            scrollContentWidth - 24.0)
        local productGap = SIZE.aboutLinkGap
        local productsGrid = construct(tree, "/Script/UMG.UniformGridPanel")
        if productsCard == nil or products == nil or productsGrid == nil then
            error("About product shelf unavailable")
        end
        local productCardColor = mixLinearColor(
            COLORS.content, COLORS.control, 0.18)
        local productFrameColor = COLORS.outline
        addCopy(products, strings.aboutProducts or "CRATEXNET PALWORLD TOOLS",
            13, COLORS.text, 0, productShelfInnerWidth)
        productsGrid:SetSlotPadding({
            Left = productGap * 0.5, Top = 0,
            Right = productGap * 0.5, Bottom = 0,
        })
        local productsGridSlot = products:AddChild(productsGrid)
        setPadding(productsGridSlot, 0, 8, 0, 0)
        align(productsGridSlot, ALIGN_FILL, ALIGN_CENTER)
        local productWidth = math.max(1.0,
            (productShelfInnerWidth / 3.0) - productGap)
        local productOutlineWidth = SIZE.aboutProductCurrentOutline
        local productInnerWidth = math.max(1.0,
            productWidth - (productOutlineWidth * 2.0))
        local productMediaFrameWidth = 1.0
        local productMediaInset = 3.0
        local productMediaChrome = 2.0
            * (productMediaFrameWidth + productMediaInset)
        local productImageWidth = math.max(1.0, math.min(
            productInnerWidth - productMediaChrome,
            92.0 * (1668.0 / 932.0)))
        local productImageHeight = productImageWidth * (932.0 / 1668.0)
        local productActionHeight = SIZE.aboutProductLinkHeight
        viewportScale = math.max(0.01, tonumber(viewportScale) or 1.0)
        local productActionGapPixels = SIZE.aboutProductLinkGapPixels
        local productActionAvailableWidth = math.max(3.0,
            productInnerWidth - 12.0)
        local productActionAvailablePixels = math.max(3,
            math.floor(productActionAvailableWidth * viewportScale))
        local productActionButtonPixels = math.floor(
            (productActionAvailablePixels - (productActionGapPixels * 2)) / 3)
        productActionButtonPixels = math.max(1, productActionButtonPixels)
        local productActionButtonWidth = productActionButtonPixels / viewportScale
        local productActionGap = productActionGapPixels / viewportScale
        local productActionStripWidth = (productActionButtonPixels * 3
            + productActionGapPixels * 2) / viewportScale
        local function addProductLink(stack, spec, visibleLabel,
                navRow, navColumn)
            local iconSize = visibleLabel ~= nil and 16.0
                or SIZE.aboutProductLinkIcon
            local action = makeAboutLogoButton(tree, {
                asset = spec.asset, fallback = spec.fallback,
                label = visibleLabel, tooltip = spec.label,
                urlKey = spec.urlKey,
                height = productActionHeight,
                iconWidth = iconSize, iconHeight = iconSize,
                labelFontSize = 10, textOnly = spec.textOnly,
                orientation = visibleLabel ~= nil and "horizontal-center" or nil,
                navRow = navRow, navColumn = navColumn,
                role = "productLink", fillWidth = true,
            })
            if action == nil then return false end
            local slot = stack:AddChild(action.box)
            align(slot, ALIGN_FILL, ALIGN_CENTER)
            return true
        end
        local function makeProductMedia(spec)
            local mediaBox = construct(tree, "/Script/UMG.SizeBox")
            local mediaStack = construct(tree, "/Script/UMG.VerticalBox")
            local imageStageBox = construct(tree, "/Script/UMG.SizeBox")
            local imageStage = construct(tree, "/Script/UMG.Border")
            local imageOverlay = construct(tree, "/Script/UMG.Overlay")
            local imageBox = construct(tree, "/Script/UMG.SizeBox")
            local imageFrame = construct(tree, "/Script/UMG.Border")
            local imageSurface = construct(tree, "/Script/UMG.Border")
            local titleBox = construct(tree, "/Script/UMG.SizeBox")
            local titleSurface = construct(tree, "/Script/UMG.Border")
            local titleWidget = makeText(tree, spec.title, 10,
                COLORS.text, TEXT_CENTER)
            if mediaBox == nil or mediaStack == nil
                or imageStageBox == nil or imageStage == nil or imageOverlay == nil
                or imageBox == nil or imageFrame == nil or imageSurface == nil
                or titleBox == nil or titleSurface == nil
                or titleWidget == nil then return nil end
            local mediaWidth = math.max(1.0, tonumber(spec.iconWidth))
            local mediaHeight = math.max(1.0, tonumber(spec.iconHeight))
            local media
            local textureApplied = false
            if spec.preview == true then
                local preview = makeAboutLogoButton(tree, {
                    asset = spec.asset, fallback = spec.fallback,
                    tooltip = spec.previewTooltip,
                    width = mediaWidth, height = mediaHeight,
                    iconWidth = math.max(1.0, mediaWidth - 4.0),
                    iconHeight = math.max(1.0, mediaHeight - 4.0),
                    kind = "preview", role = "brand",
                    navRow = spec.previewNavRow,
                    navColumn = spec.previewNavColumn,
                })
                media = preview ~= nil and preview.box or nil
            else
                local texture = aboutTexture(spec.asset)
                if P.isValid(texture) then
                    local image = construct(tree, "/Script/UMG.Image")
                    if image ~= nil then
                        local applied = pcall(function()
                            image:SetBrushFromTexture(texture, false)
                        end)
                        if applied then
                            media = image
                            textureApplied = true
                        end
                    end
                end
            end
            if media == nil then
                media = makeText(tree, tostring(spec.fallback or "?"),
                    13, COLORS.text, TEXT_CENTER)
            end
            if media == nil then return nil end
            setTextWrap(titleWidget, productInnerWidth - 8.0)
            local ok = pcall(function()
                mediaBox:SetHeightOverride(130.0)
                local framedMediaHeight = mediaHeight + productMediaChrome
                imageStageBox:SetHeightOverride(framedMediaHeight)
                imageStage:SetBrushColor(COLORS.transparent)
                local imageVisual
                if spec.preview == true then
                    imageVisual = media
                else
                    imageBox:SetWidthOverride(mediaWidth)
                    imageBox:SetHeightOverride(mediaHeight)
                    align(imageBox:AddChild(media),
                        textureApplied and ALIGN_FILL or ALIGN_CENTER,
                        textureApplied and ALIGN_FILL or ALIGN_CENTER)
                    imageVisual = imageBox
                end
                imageFrame:SetBrushColor(productFrameColor)
                imageFrame:SetPadding({
                    Left = productMediaFrameWidth,
                    Top = productMediaFrameWidth,
                    Right = productMediaFrameWidth,
                    Bottom = productMediaFrameWidth,
                })
                imageSurface:SetBrushColor(COLORS.content)
                imageSurface:SetPadding({
                    Left = productMediaInset,
                    Top = productMediaInset,
                    Right = productMediaInset,
                    Bottom = productMediaInset,
                })
                align(imageSurface:AddChild(imageVisual),
                    ALIGN_CENTER, ALIGN_CENTER)
                align(imageFrame:AddChild(imageSurface),
                    ALIGN_FILL, ALIGN_FILL)
                align(imageOverlay:AddChild(imageFrame),
                    ALIGN_CENTER, ALIGN_CENTER)
                align(imageStage:AddChild(imageOverlay), ALIGN_FILL, ALIGN_FILL)
                align(imageStageBox:AddChild(imageStage), ALIGN_FILL, ALIGN_FILL)
                titleBox:SetHeightOverride(math.max(30.0,
                    130.0 - framedMediaHeight))
                titleSurface:SetBrushColor(mixLinearColor(
                    productCardColor, COLORS.control, 0.55))
                titleSurface:SetPadding({
                    Left = 10, Top = 4,
                    Right = 10, Bottom = 4,
                })
                align(titleSurface:AddChild(titleWidget),
                    ALIGN_FILL, ALIGN_CENTER)
                align(titleBox:AddChild(titleSurface), ALIGN_FILL, ALIGN_FILL)
                align(mediaStack:AddChild(titleBox), ALIGN_FILL, ALIGN_FILL)
                align(mediaStack:AddChild(imageStageBox),
                    ALIGN_FILL, ALIGN_CENTER)
                align(mediaBox:AddChild(mediaStack), ALIGN_FILL, ALIGN_FILL)
            end)
            return ok and mediaBox or nil
        end
        local function addProduct(spec, column)
            local productBox = construct(tree, "/Script/UMG.SizeBox")
            local productFrame = construct(tree, "/Script/UMG.Border")
            local productContent = construct(tree, "/Script/UMG.Border")
            local productStack = construct(tree, "/Script/UMG.VerticalBox")
            if productBox == nil or productFrame == nil
                or productContent == nil or productStack == nil then return false end
            local mediaBox = makeProductMedia(spec)
            if mediaBox == nil then return false end
            local ok = pcall(function()
                productBox:SetHeightOverride(SIZE.aboutProductCardHeight)
                productFrame:SetBrushColor(productFrameColor)
                productFrame:SetPadding({
                    Left = productOutlineWidth, Top = productOutlineWidth,
                    Right = productOutlineWidth, Bottom = productOutlineWidth,
                })
                productContent:SetBrushColor(productCardColor)
                align(productFrame:AddChild(productContent),
                    ALIGN_FILL, ALIGN_FILL)
                align(productContent:AddChild(productStack),
                    ALIGN_FILL, ALIGN_FILL)
                align(productBox:AddChild(productFrame), ALIGN_FILL, ALIGN_FILL)
                local mediaSlot = productStack:AddChild(mediaBox)
                setPadding(mediaSlot, 0, 0, 0, 0)
                align(mediaSlot, ALIGN_FILL, ALIGN_CENTER)
            end)
            if not ok then return false end
            local productSpacer = construct(tree, "/Script/UMG.SizeBox")
            if productSpacer == nil then return false end
            local spacerSlot = productStack:AddChild(productSpacer)
            setFill(spacerSlot)
            local links = spec.links or {}
            local productFooter = construct(tree, "/Script/UMG.Border")
            if productFooter == nil then return false end
            productFooter:SetBrushColor(COLORS.transparent)
            productFooter:SetPadding({ Left = 6, Top = 3, Right = 6, Bottom = 3 })
            local stripBox = construct(tree, "/Script/UMG.SizeBox")
            if stripBox == nil then return false end
            stripBox:SetWidthOverride(productActionStripWidth)
            if #links == 3 then
                local platformRow = construct(tree, "/Script/UMG.HorizontalBox")
                if platformRow == nil then return false end
                align(stripBox:AddChild(platformRow),
                    ALIGN_FILL, ALIGN_CENTER)
                local baseColumn = tonumber(spec.navColumnBase) or 0
                local navRow = tonumber(spec.navRow) or 2
                for index, link in ipairs(links) do
                    local cell = construct(tree, "/Script/UMG.SizeBox")
                    if cell == nil then return false end
                    cell:SetWidthOverride(productActionButtonWidth)
                    local cellSlot = platformRow:AddChild(cell)
                    align(cellSlot, ALIGN_FILL, ALIGN_FILL)
                    if not addProductLink(cell, link, nil, navRow,
                            baseColumn + index) then
                        return false
                    end
                    if index < #links then
                        local gap = construct(tree, "/Script/UMG.SizeBox")
                        if gap == nil then return false end
                        gap:SetWidthOverride(productActionGap)
                        platformRow:AddChild(gap)
                    end
                end
            else
                for index, link in ipairs(links) do
                    if not addProductLink(stripBox, link, link.label,
                            tonumber(spec.navRow) or 2,
                            (tonumber(spec.navColumnBase) or 0) + index) then
                        return false
                    end
                end
            end
            align(productFooter:AddChild(stripBox),
                ALIGN_CENTER, ALIGN_CENTER)
            local footerSlot = productStack:AddChild(productFooter)
            align(footerSlot, ALIGN_FILL, ALIGN_CENTER)
            local slot = productsGrid:AddChildToUniformGrid(
                productBox, 0, column - 1)
            align(slot, ALIGN_FILL, ALIGN_FILL)
            return true
        end
        if not addProduct({
                asset = "pal-insight-preview.jpg", fallback = "PI",
                title = "Pal Insight",
                iconWidth = productImageHeight,
                iconHeight = productImageHeight,
                navRow = 2, navColumnBase = 0,
                links = {
                    { asset = "steam.png", fallback = "S",
                        label = "Steam Workshop", urlKey = "palInsightWorkshop" },
                    { asset = "nexus.png", fallback = "N",
                        label = "Nexus Mods", urlKey = "palInsight" },
                    { asset = "curseforge.png", fallback = "CF",
                        label = "CurseForge", urlKey = "palInsightCurseForge" },
                },
            }, 1) then error("Pal Insight product card unavailable") end
        state.aboutDefaultFocusIndex = #state.aboutActions + 1
        if not addProduct({
                asset = "quick-stack-preview.png", fallback = "QS",
                title = "Pal Insight: Quick Stack",
                iconWidth = productImageHeight,
                iconHeight = productImageHeight,
                navRow = 2, navColumnBase = 3,
                links = {
                    { asset = "steam.png", fallback = "S",
                        label = "Steam Workshop", urlKey = "quickStackWorkshop" },
                    { asset = "nexus.png", fallback = "N",
                        label = "Nexus Mods", urlKey = "quickStackNexus" },
                    { asset = "curseforge.png", fallback = "CF",
                        label = "CurseForge", urlKey = "quickStackCurseForge" },
                },
            }, 2)
            or not addProduct({
                asset = "breeding-calculator-preview.png", fallback = "BC",
                title = strings.aboutCalculator or "Palworld Breeding Calculator",
                iconWidth = productImageWidth, iconHeight = productImageHeight,
                preview = true,
                previewTooltip = strings.aboutCalculator
                    or "Palworld Breeding Calculator",
                previewNavRow = 1, previewNavColumn = 7,
                navRow = 2, navColumnBase = 6,
                links = {
                    { textOnly = true, label = strings.aboutVisitCalculator
                            or "View breeding tool",
                        urlKey = "calculator" },
                },
            }, 3) then error("About product card unavailable") end

        local _, creator = makeCard()
        if creator == nil then error("About creator card unavailable") end
        local creatorRow = construct(tree, "/Script/UMG.HorizontalBox")
        local creatorCopy = construct(tree, "/Script/UMG.VerticalBox")
        local creatorActions = construct(tree, "/Script/UMG.VerticalBox")
        if creatorRow == nil or creatorCopy == nil or creatorActions == nil then
            error("About creator columns unavailable")
        end
        align(creator:AddChild(creatorRow), ALIGN_FILL, ALIGN_CENTER)
        local website = makeAboutLogoButton(tree, {
            asset = "cratex.png", fallback = "C", label = "CrateX.app",
            tooltip = "CrateX.app", urlKey = "website",
            width = SIZE.aboutCreatorLinkWidth,
            height = (SIZE.aboutLinkHeight * 2.0) + SIZE.aboutLinkGap,
            iconWidth = 48.0, iconHeight = 48.0, orientation = "vertical",
            navRow = 4, navColumn = 1,
        })
        if website == nil then
            error("About website action unavailable")
        end
        local websiteSlot = creatorRow:AddChild(website.box)
        setPadding(websiteSlot, 0, 0, 12, 0)
        align(websiteSlot, ALIGN_LEFT, ALIGN_CENTER)
        local creatorCopySlot = creatorRow:AddChild(creatorCopy)
        setFill(creatorCopySlot)
        setPadding(creatorCopySlot, 0, 0, 12, 0)
        align(creatorCopySlot, ALIGN_FILL, ALIGN_CENTER)
        addCopy(creatorCopy, strings.aboutCreator or "Creator", 13,
            COLORS.text, 0, creatorCopyWrapWidth)
        addCopy(creatorCopy, "cratexnet", 14, COLORS.text, 2,
            creatorCopyWrapWidth)
        addCopy(creatorCopy, strings.aboutCreatorDescription or "", 11,
            COLORS.muted, 4, creatorCopyWrapWidth)
        local function addRosterAction(label, asset, fallback, mode, role, navRow)
            local action = makeAboutLogoButton(tree, {
                asset = asset, fallback = fallback, fallbackFontSize = 14,
                iconWidth = 22, iconHeight = 22,
                label = label, tooltip = label,
                width = SIZE.aboutCreatorLinkWidth,
                orientation = "horizontal-left", kind = "roster",
                deferRegistration = true,
                rosterMode = mode, role = role,
                navRow = navRow, navColumn = 2,
            })
            if action == nil then return false end
            local actionSlot = creatorActions:AddChild(action.box)
            align(actionSlot, ALIGN_CENTER, ALIGN_CENTER)
            local halfGap = SIZE.aboutLinkGap * 0.5
            if navRow == 4 then
                setPadding(actionSlot, 0, 0, 0, halfGap)
            else
                setPadding(actionSlot, 0, halfGap, 0, 0)
            end
            state.aboutActions[#state.aboutActions + 1] = action
            return true
        end
        if not addRosterAction(strings.aboutSpecialThanks,
                "sports-medal.png", "✦", "thanks", "thanks", 4)
            or not addRosterAction(strings.aboutSupporters,
                "red-heart.png", "♥", "supporters", "supporters", 5) then
            error("About roster actions unavailable")
        end
        local creatorActionsSlot = creatorRow:AddChild(creatorActions)
        align(creatorActionsSlot, ALIGN_CENTER, ALIGN_CENTER)

        local communityAndSupport = construct(tree, "/Script/UMG.HorizontalBox")
        local communityBox = construct(tree, "/Script/UMG.SizeBox")
        local communityCard = construct(tree, "/Script/UMG.Border")
        local communityStack = construct(tree, "/Script/UMG.VerticalBox")
        local communityRow = construct(tree, "/Script/UMG.HorizontalBox")
        local supportCard = construct(tree, "/Script/UMG.Border")
        local supportStack = construct(tree, "/Script/UMG.VerticalBox")
        local supportRow = construct(tree, "/Script/UMG.HorizontalBox")
        local supportCopy = construct(tree, "/Script/UMG.VerticalBox")
        if communityAndSupport == nil or communityBox == nil
            or communityCard == nil or communityStack == nil
            or communityRow == nil or supportCard == nil
            or supportStack == nil or supportRow == nil
            or supportCopy == nil then
            error("About community and support unavailable")
        end
        communityBox:SetWidthOverride(communityColumnWidth)
        communityCard:SetBrushColor(mixLinearColor(
            COLORS.content, COLORS.control, 0.30))
        communityCard:SetPadding({ Left = 12, Top = 12, Right = 12, Bottom = 12 })
        align(communityCard:AddChild(communityStack), ALIGN_FILL, ALIGN_FILL)
        align(communityBox:AddChild(communityCard), ALIGN_FILL, ALIGN_FILL)
        align(communityAndSupport:AddChild(communityBox), ALIGN_CENTER, ALIGN_FILL)
        addCopy(communityStack, strings.aboutCommunity or "Community",
            13, COLORS.text, 0, communityColumnWidth - 24.0)
        local communityRowSlot = communityStack:AddChild(communityRow)
        setPadding(communityRowSlot, 0, 8, 0, 0)
        align(communityRowSlot, ALIGN_FILL, ALIGN_CENTER)

        supportCard:SetBrushColor(mixLinearColor(
            COLORS.content, COLORS.control, 0.30))
        supportCard:SetPadding({ Left = 12, Top = 12, Right = 12, Bottom = 12 })
        align(supportCard:AddChild(supportStack), ALIGN_FILL, ALIGN_FILL)
        local supportCardSlot = communityAndSupport:AddChild(supportCard)
        setFill(supportCardSlot)
        setPadding(supportCardSlot, SIZE.aboutLinkGap, 0, 0, 0)
        align(supportCardSlot, ALIGN_FILL, ALIGN_FILL)
        addCopy(supportStack, strings.aboutSupport or "Support",
            13, COLORS.text, 0,
            aboutCardInnerWidth - communityColumnWidth - SIZE.aboutLinkGap - 24.0)
        local supportRowSlot = supportStack:AddChild(supportRow)
        setPadding(supportRowSlot, 0, 8, 0, 0)
        align(supportRowSlot, ALIGN_FILL, ALIGN_CENTER)
        local function addCommunityAction(spec, leftGap)
            local action = makeAboutLogoButton(tree, spec)
            if action == nil then return nil end
            local column = construct(tree, "/Script/UMG.SizeBox")
            if column == nil then return nil end
            local columnSlot = communityRow:AddChild(column)
            setFill(columnSlot)
            local halfGap = SIZE.aboutLinkGap * 0.5
            if leftGap then
                setPadding(columnSlot, halfGap, 0, 0, 0)
            else
                setPadding(columnSlot, 0, 0, halfGap, 0)
            end
            align(columnSlot, ALIGN_FILL, ALIGN_CENTER)
            align(column:AddChild(action.box), ALIGN_CENTER, ALIGN_CENTER)
            return action
        end
        if not addCommunityAction({
                asset = "x.png", fallback = "X",
                tooltip = "X", urlKey = "x",
                width = SIZE.aboutLinkHeight,
                height = SIZE.aboutLinkHeight,
                iconWidth = 24.0, iconHeight = 24.0,
                navRow = 6, navColumn = 1,
            }, false)
            or not addCommunityAction({
                asset = "discord.png", fallback = "D",
                tooltip = "Discord", urlKey = "discord",
                width = SIZE.aboutLinkHeight,
                height = SIZE.aboutLinkHeight,
                iconWidth = 24.0, iconHeight = 24.0,
                navRow = 6, navColumn = 2,
            }, true) then
            error("About community action unavailable")
        end
        local supportCopySlot = supportRow:AddChild(supportCopy)
        setFill(supportCopySlot)
        setPadding(supportCopySlot, 0, 0, 8, 0)
        align(supportCopySlot, ALIGN_FILL, ALIGN_CENTER)
        addCopy(supportCopy, strings.aboutSupportDescription or "", 11,
            COLORS.muted, 0, supportCopyWrapWidth)
        local bmc = makeAboutLogoButton(tree, {
            asset = "buy-me-a-coffee.png", fallback = "BMC",
            tooltip = "Buy Me a Coffee", urlKey = "bmc", role = "brand",
            width = SIZE.aboutSupportActionWidth,
            height = SIZE.aboutSupportActionHeight,
            iconWidth = SIZE.aboutSupportLogoWidth,
            iconHeight = SIZE.aboutSupportLogoHeight,
            navRow = 6, navColumn = 3,
        })
        if bmc == nil then
            error("About support action unavailable")
        end
        align(supportRow:AddChild(bmc.box), ALIGN_CENTER, ALIGN_CENTER)
        local shelfSlot = body:AddChild(communityAndSupport)
        align(shelfSlot, ALIGN_FILL, ALIGN_FILL)

        state.aboutActions[#state.aboutActions + 1] = {
            box = close.box, widget = close.widget,
            visualButton = close.visualButton, labelWidget = close.text,
            kind = "close", role = "close", label = strings.close,
            tooltip = strings.close, navRow = 7, navColumn = 2,
        }
    end)
    if not ok or #(state.aboutActions or {}) < 2 then return false end
    if not buildRosterOverlay("thanks")
        or not buildRosterOverlay("supporters") then return false end
    if not buildAboutPreviewOverlay(tree, root, strings,
            viewportWidth, viewportHeight) then return false end
    state.aboutOverlay = overlay
    state.aboutCloseWidget = close.widget
    return true
end

logicalViewportSize = function(controller)
    local width, height = 1280.0, 720.0
    local viewportScale = 1.0
    local layout = staticObject("/Script/UMG.Default__WidgetLayoutLibrary")
    if layout == nil then return width, height, viewportScale end
    pcall(function()
        local size = layout:GetViewportSize(controller)
        width = tonumber(size.X) or width
        height = tonumber(size.Y) or height
        viewportScale = tonumber(layout:GetViewportScale(controller)) or 1.0
        if viewportScale <= 0 then viewportScale = 1.0 end
        width, height = width / viewportScale, height / viewportScale
    end)
    return width, height, viewportScale
end

local function clearWindowReferences()
    cancelNavigationRepeat()
    InputOwner.unbindActionButtons()
    InputOwner.unbindToggleControls()
    state.shortcutFocusRestoreToken = state.shortcutFocusRestoreToken + 1
    state.shortcutFocusRestoreCallback = nil
    state.widget = nil
    state.widgetTree = nil
    state.root = nil
    state.controls = {}
    state.allFocusEntries = {}
    state.settingsPages = {}
    state.settingsTabButtons = {}
    state.settingsTabPreviousButton = nil
    state.settingsTabNextButton = nil
    state.activeSettingsPage = "general"
    state.settingsPageScrollOffsets = {}
    state.buildingPageId = nil
    state.triggerSurfaces = {}
    state.directActionButtons = {}
    state.headerActionVisuals = {}
    state.statusText = nil
    state.modeText = nil
    state.footerHelp = nil
    state.footerGuideRecords = nil
    state.footerGuideSignature = nil
    state.footerMode = nil
    state.shortcutWarningText = nil
    state.shortcutControl = nil
    state.headerActionHint = nil
    state.aboutOverlay = nil
    state.aboutCloseWidget = nil
    state.aboutOpen = false
    state.aboutReturnFocusIndex = nil
    state.aboutActions = {}
    state.aboutFocusIndex = 1
    state.aboutDefaultFocusIndex = nil
    state.aboutPreferredColumn = 1
    state.aboutActionHint = nil
    state.aboutScroll = nil
    state.aboutRosterOverlays = {}
    state.aboutRosterCloseWidgets = {}
    state.aboutRosterCloseActions = {}
    state.aboutRosterOpen = false
    state.aboutRosterMode = nil
    state.aboutPreviewOverlay = nil
    state.aboutPreviewCloseWidget = nil
    state.aboutPreviewCloseAction = nil
    state.aboutPreviewOpen = false
    state.aboutPreviewSourceIndex = nil
    state.steamVoteControl = nil
    state.steamVoteBox = nil
    state.steamVoteNoneWidget = nil
    state.steamVoteNoneSurface = nil
    state.steamVoteUpSurface = nil
    state.steamVoteDisplayStatus = nil
    state.steamVotePendingUp = false
    state.pendingDownvoteAcknowledgement = false
    state.steamVotePalVisuals = {}
    state.steamVotePalVisualReady = false
    state.steamVotePalRetryAt = 0
    state.steamVoteActionVisuals = {}
    state.steamVoteTextures = {}
    state.steamVotePalTexture = nil
    state.aboutTextures = {}
    state.releaseNotesOverlay = nil
    state.releaseNotesOpen = false
    state.releaseNotesReturnFocusIndex = nil
    state.releaseNotesFocusPane = 1
    state.releaseNotesPickerIndex = 1
    state.releaseNotesSelectedIndex = 1
    state.releaseNotesButtons = {}
    state.releaseNotesPickerButtons = {}
    state.releaseNotesPickerScroll = nil
    state.releaseNotesScroll = nil
    state.releaseNotesContent = nil
    state.scroll = nil
    state.nestedOverlay = nil
    state.nestedCardBox = nil
    state.nestedOutline = nil
    state.nestedPanel = nil
    state.nestedTitle = nil
    state.nestedMessage = nil
    state.nestedContent = nil
    state.nestedScroll = nil
    state.nestedOptionWidth = nil
    state.nestedDefaultWidth = nil
    state.nestedDefaultMaxHeight = nil
    state.nestedOptionCapacity = nil
    state.downvoteDialogWidth = nil
    state.downvoteDialogMaxHeight = nil
    state.ammoPopulateToken = state.ammoPopulateToken + 1
    state.modalOptions = {}
    state.activeChoice = nil
    state.choiceReturnFocusIndex = nil
    state.pointerAction = nil
    state.pendingAboutPointerClose = nil
    state.numberEdit = nil
    state.toggleEventsSuppressed = false
    state.modalIndex = 1
    state.focusEntries = {}
    state.focusIndex = 1
    state.windowCache = { ready = false }
end

local function windowContext(controller)
    if not P.isValid(controller) then return nil end
    local world
    local ok = pcall(function() world = controller:GetWorld() end)
    local controllerAddress = P.objectAddress(controller)
    local worldAddress = ok and P.objectAddress(world) or nil
    if controllerAddress == nil or worldAddress == nil then return nil end
    local width, height = logicalViewportSize(controller)
    return {
        controllerAddress = controllerAddress,
        worldAddress = worldAddress,
        viewportWidth = width,
        viewportHeight = height,
        strings = currentStrings(),
    }
end

windowCacheMatches = function(controller)
    local cache = state.windowCache
    local context = windowContext(controller)
    if type(cache) ~= "table" or cache.ready ~= true or context == nil
        or not P.isValid(state.widget) or not P.isValid(state.widgetTree)
        or not P.isValid(state.root)
        or P.objectAddress(state.widget) ~= cache.widgetAddress
        or context.controllerAddress ~= cache.controllerAddress
        or context.worldAddress ~= cache.worldAddress
        or context.strings ~= cache.strings
        or math.abs(context.viewportWidth
            - (tonumber(cache.viewportWidth) or -100000.0)) > 0.5
        or math.abs(context.viewportHeight
            - (tonumber(cache.viewportHeight) or -100000.0)) > 0.5 then
        return false
    end
    return true
end

local function rememberWindowCache(controller)
    local context = windowContext(controller)
    local widgetAddress = P.objectAddress(state.widget)
    if context == nil or widgetAddress == nil
        or not P.isValid(state.widgetTree) or not P.isValid(state.root) then
        state.windowCache = { ready = false }
        return false
    end
    context.ready = true
    context.widgetAddress = widgetAddress
    state.windowCache = context
    return true
end

local function discardWindowCache()
    local removed = true
    if P.isValid(state.widget) then
        removed = pcall(function() state.widget:RemoveFromParent() end)
    end
    if not removed then return false end
    clearWindowReferences()
    return true
end

local function prepareWindowForOpen(mode)
    if not P.isValid(state.widget) then return false end
    local strings = currentStrings()
    closeChoiceModal(false)
    state.closeReleaseNotesModal(false)
    closeAboutModal(false)
    state.pointerAction = nil
    state.pendingAboutPointerClose = nil
    state.numberEdit = nil
    resetControlsToConfig()
    state.rebuildSettingsFocusEntries()
    state.focusIndex = 1
    state.lastInputDevice = "keyboard"
    state.pollFailureSignature = nil
    setStatus("", false)
    if state.steamVoteControl ~= nil and SteamVote.ready() then
        applySteamVoteVisual(SteamVote.status(), true)
    end
    if P.isValid(state.modeText) then
        pcall(function()
            state.modeText:SetText(FText(strings.creator or "by cratexnet"))
        end)
    end
    state.footerMode = mode
    state.footerGuideSignature = nil
    FooterGuide.refreshFooterHelp(true)
    for _, record in ipairs(state.triggerSurfaces or {}) do
        record.visualSignature = nil
        record.selected = false
    end
    for pageId, page in pairs(state.settingsPages or {}) do
        if P.isValid(page) then
            pcall(function()
                page:SetVisibility(pageId == state.activeSettingsPage
                    and VIS_VISIBLE or VIS_COLLAPSED)
            end)
        end
    end
    if P.isValid(state.scroll) then
        pcall(function()
            state.scroll:SetScrollOffset(tonumber(
                state.settingsPageScrollOffsets[state.activeSettingsPage]) or 0.0)
        end)
    end
    local shown = pcall(function()
        state.widget.bIsFocusable = true
        state.widget:SetRenderOpacity(0.0)
        state.widget:SetVisibility(VIS_VISIBLE)
    end)
    refreshTriggerSurfaces()
    return shown
end

local function buildSettingsWindow(controller, mode)
    local world
    local ok = pcall(function() world = controller:GetWorld() end)
    local library = staticObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    local userWidgetClass = staticObject("/Script/UMG.UserWidget")
    if not ok or not P.isValid(world) or library == nil
        or userWidgetClass == nil then return nil, "UMG is unavailable" end
    local widget
    ok = pcall(function() widget = library:Create(world, userWidgetClass, controller) end)
    if not ok or not P.isValid(widget) then return nil, "settings widget cannot be created" end
    local tree = widget.WidgetTree
    if not P.isValid(tree) then
        pcall(function() widget:RemoveFromParent() end)
        return nil, "settings widget tree is unavailable"
    end

    local root = construct(tree, "/Script/UMG.CanvasPanel")
    local shield = construct(tree, "/Script/UMG.Border")
    local cardBox = construct(tree, "/Script/UMG.SizeBox")
    local outline = construct(tree, "/Script/UMG.Border")
    local card = construct(tree, "/Script/UMG.Border")
    local layout = construct(tree, "/Script/UMG.VerticalBox")
    local contentViewport = construct(tree, "/Script/UMG.SizeBox")
    local contentFrame = construct(tree, "/Script/UMG.Border")
    local scroll = construct(tree, "/Script/UMG.ScrollBox")
    local contentBox = construct(tree, "/Script/UMG.SizeBox")
    local contentLayer = construct(tree, "/Script/UMG.Overlay")
    local generalBody = construct(tree, "/Script/UMG.VerticalBox")
    local automaticSaleBody = construct(tree, "/Script/UMG.VerticalBox")
    local specialItemsBody = construct(tree, "/Script/UMG.VerticalBox")
    if root == nil or shield == nil or cardBox == nil or outline == nil
        or card == nil or layout == nil or contentViewport == nil
        or contentFrame == nil or scroll == nil or contentBox == nil
        or contentLayer == nil or generalBody == nil
        or automaticSaleBody == nil or specialItemsBody == nil then
        pcall(function() widget:RemoveFromParent() end)
        return nil, "settings controls cannot be created"
    end
    local strings = currentStrings()
    local viewportWidth, viewportHeight = logicalViewportSize(controller)
    local width = math.min(920.0, math.max(720.0, viewportWidth - 120.0),
        math.max(320.0, viewportWidth - 48.0))
    local height = math.min(math.max(500.0, viewportHeight * 0.60), 640.0,
        math.max(320.0, viewportHeight - 48.0))
    local contentWidth = math.max(1.0, width
        - 2.0 * SIZE.windowOutline - 32.0 - SIZE.scrollbarGutter)
    state.contentWidth = contentWidth
    state.controls = {}
    state.allFocusEntries = {}
    state.settingsPages = {
        general = generalBody,
        automaticSale = automaticSaleBody,
        specialItems = specialItemsBody,
    }
    state.settingsTabButtons = {}
    state.settingsTabPreviousButton = nil
    state.settingsTabNextButton = nil
    state.activeSettingsPage = "general"
    state.settingsPageScrollOffsets = {
        general = 0.0, automaticSale = 0.0, specialItems = 0.0,
    }
    state.buildingPageId = nil
    state.triggerSurfaces = {}
    state.nestedOverlay = nil
    state.nestedCardBox = nil
    state.nestedOutline = nil
    state.nestedPanel = nil
    state.nestedTitle = nil
    state.nestedMessage = nil
    state.nestedContent = nil
    state.nestedScroll = nil
    state.nestedOptionWidth = nil
    state.nestedDefaultWidth = nil
    state.nestedDefaultMaxHeight = nil
    state.nestedOptionCapacity = nil
    state.downvoteDialogWidth = nil
    state.downvoteDialogMaxHeight = nil
    state.modalOptions = {}
    state.activeChoice = nil
    state.choiceReturnFocusIndex = nil
    state.pointerAction = nil
    state.modalIndex = 1
    state.focusEntries = {}
    state.focusIndex = 1
    state.scroll = scroll
    state.widgetTree = tree
    state.root = root

    ok = pcall(function()
        widget.bIsFocusable = true
        tree.RootWidget = root
        shield:SetBrushColor(COLORS.shield)
        shield:SetVisibility(VIS_VISIBLE)
        shield:SetIsEnabled(true)
        local shieldSlot = root:AddChild(shield)
        shieldSlot:SetAnchors({
            Minimum = { X = 0.0, Y = 0.0 },
            Maximum = { X = 1.0, Y = 1.0 },
        })
        shieldSlot:SetOffsets({ Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0 })
        shieldSlot:SetZOrder(0)

        cardBox:SetWidthOverride(width)
        cardBox:SetHeightOverride(height)
        outline:SetBrushColor(COLORS.outline)
        outline:SetPadding({
            Left = SIZE.windowOutline, Top = SIZE.windowOutline,
            Right = SIZE.windowOutline, Bottom = SIZE.windowOutline,
        })
        card:SetBrushColor(COLORS.window)
        local cardSurfaceSlot = outline:AddChild(card)
        align(cardSurfaceSlot, ALIGN_FILL, ALIGN_FILL)
        local outlineSlot = cardBox:AddChild(outline)
        align(outlineSlot, ALIGN_FILL, ALIGN_FILL)
        card:SetPadding({ Left = 16, Top = 12, Right = 16, Bottom = 12 })
        local layoutSlot = card:AddChild(layout)
        align(layoutSlot, ALIGN_FILL, ALIGN_FILL)
        local cardSlot = root:AddChild(cardBox)
        cardSlot:SetZOrder(1)
        cardSlot:SetAutoSize(false)
        cardSlot:SetSize({ X = width, Y = height })
        cardSlot:SetAlignment({ X = 0.0, Y = 0.0 })
        cardSlot:SetPosition({
            X = math.floor((viewportWidth - width) * 0.5),
            Y = math.floor((viewportHeight - height) * 0.5),
        })

        local headerSize = construct(tree, "/Script/UMG.SizeBox")
        local header = construct(tree, "/Script/UMG.Border")
        local headerRow = construct(tree, "/Script/UMG.HorizontalBox")
        local identity = construct(tree, "/Script/UMG.VerticalBox")
        local titleRow = construct(tree, "/Script/UMG.HorizontalBox")
        local versionBox = construct(tree, "/Script/UMG.SizeBox")
        local versionButton = construct(tree, "/Script/UMG.Button")
        local versionBadge = construct(tree, "/Script/UMG.Border")
        local headerActionArea = construct(tree, "/Script/UMG.SizeBox")
        local headerActionStack = construct(tree, "/Script/UMG.VerticalBox")
        local headerActionRow = construct(tree, "/Script/UMG.HorizontalBox")
        local headerActionHintBox = construct(tree, "/Script/UMG.SizeBox")
        local headerActionHint = makeText(tree, "", 11, COLORS.muted, TEXT_CENTER)
        local title = makeText(tree, "Quick Stack", 20, COLORS.text)
        local version = makeText(tree,
            "v" .. tostring(state.version), 11, COLORS.textMuted, TEXT_CENTER)
        local modeText = makeText(tree,
            strings.creator or "by cratexnet",
            11, COLORS.textMuted, TEXT_LEFT)
        local voteBox = makeSteamVoteControl(tree, strings)
        local releaseStrings = SettingsUI.releaseNotes.current()
        local aboutAction = makeIconTrigger(
            tree, "ⓘ", strings.about, "about", true)
        local resetAction = makeIconTrigger(
            tree, "↻", strings.reset, "reset", true)
        local closeAction = makeIconTrigger(
            tree, "×", strings.close, "close", true)
        local aboutCell = aboutAction ~= nil
            and makeHeaderActionCell(tree, aboutAction.box) or nil
        local resetCell = resetAction ~= nil
            and makeHeaderActionCell(tree, resetAction.box) or nil
        local closeCell = closeAction ~= nil
            and makeHeaderActionCell(tree, closeAction.box) or nil
        if headerSize == nil or header == nil or headerRow == nil
            or identity == nil or titleRow == nil or versionBox == nil
            or versionButton == nil or versionBadge == nil
            or title == nil or version == nil
            or modeText == nil or headerActionArea == nil
            or headerActionStack == nil or headerActionRow == nil
            or headerActionHintBox == nil or headerActionHint == nil
            or aboutAction == nil or resetAction == nil or closeAction == nil
            or aboutCell == nil
            or resetCell == nil or closeCell == nil then
            error("settings header is unavailable")
        end
        headerSize:SetMinDesiredHeight(64.0)
        header:SetBrushColor(COLORS.chrome)
        header:SetPadding({ Left = 12, Top = 6, Right = 12, Bottom = 6 })
        local identitySlot = headerRow:AddChild(identity)
        setFill(identitySlot)
        align(identitySlot, ALIGN_LEFT, ALIGN_CENTER)
        local titleRowSlot = identity:AddChild(titleRow)
        align(titleRowSlot, ALIGN_FILL, ALIGN_CENTER)
        local titleSlot = titleRow:AddChild(title)
        align(titleSlot, ALIGN_LEFT, ALIGN_CENTER)
        versionBox:SetHeightOverride(24.0)
        versionButton.bIsFocusable = true
        versionButton:SetToolTipText(FText(releaseStrings.title))
        local versionButtonStyle = versionButton.WidgetStyle
        versionButtonStyle.NormalPadding = { Left = 0, Top = 0, Right = 0, Bottom = 0 }
        versionButtonStyle.PressedPadding = { Left = 0, Top = 0, Right = 0, Bottom = 0 }
        versionButton.WidgetStyle = versionButtonStyle
        styleHeaderButton(versionButton, "releaseNotes", false, false, false, true)
        versionBadge:SetBrushColor(COLORS.transparent)
        versionBadge:SetPadding({ Left = 8, Top = 2, Right = 8, Bottom = 2 })
        version:SetColorAndOpacity({
            SpecifiedColor = COLORS.text,
            ColorUseRule = 2,
        })
        local versionTextSlot = versionBadge:AddChild(version)
        align(versionTextSlot, ALIGN_CENTER, ALIGN_CENTER)
        local versionBadgeSlot = versionBox:AddChild(versionBadge)
        align(versionBadgeSlot, ALIGN_FILL, ALIGN_FILL)
        align(versionButton:AddChild(versionBox), ALIGN_FILL, ALIGN_FILL)
        local versionSlot = titleRow:AddChild(versionButton)
        setPadding(versionSlot, 8, 0, 0, 0)
        align(versionSlot, ALIGN_LEFT, ALIGN_CENTER)
        local modeSlot = identity:AddChild(modeText)
        setTextWrap(modeText, math.max(1.0,
            contentWidth - 24.0 - (voteBox ~= nil and 74.0 or 0.0) - 168.0))
        setPadding(modeSlot, 0, 2, 0, 0)
        align(modeSlot, ALIGN_LEFT, ALIGN_CENTER)
        if voteBox ~= nil then
            local voteSlot = headerRow:AddChild(voteBox)
            setPadding(voteSlot, 0, 0, 10, 0)
            align(voteSlot, ALIGN_CENTER, ALIGN_LEFT)
        end
        headerActionArea:SetWidthOverride(
            SIZE.headerAction * 3.0 + SIZE.headerActionGap * 2.0)
        headerActionArea:SetHeightOverride(52.0)
        local aboutSlot = headerActionRow:AddChild(aboutCell)
        align(aboutSlot, ALIGN_CENTER, ALIGN_CENTER)
        if not addHeaderActionGap(tree, headerActionRow) then
            error("settings header About gap is unavailable")
        end
        local resetSlot = headerActionRow:AddChild(resetCell)
        align(resetSlot, ALIGN_CENTER, ALIGN_CENTER)
        if not addHeaderActionGap(tree, headerActionRow) then
            error("settings header reset gap is unavailable")
        end
        local closeSlot = headerActionRow:AddChild(closeCell)
        align(closeSlot, ALIGN_CENTER, ALIGN_CENTER)
        local actionRowSlot = headerActionStack:AddChild(headerActionRow)
        align(actionRowSlot, ALIGN_CENTER, ALIGN_CENTER)
        headerActionHintBox:SetHeightOverride(16.0)
        align(headerActionHintBox:AddChild(headerActionHint),
            ALIGN_CENTER, ALIGN_CENTER)
        align(headerActionStack:AddChild(headerActionHintBox),
            ALIGN_CENTER, ALIGN_CENTER)
        align(headerActionArea:AddChild(headerActionStack),
            ALIGN_FILL, ALIGN_FILL)
        align(headerRow:AddChild(headerActionArea), ALIGN_CENTER, ALIGN_FILL)
        state.headerActionHint = headerActionHint
        local headerRowSlot = header:AddChild(headerRow)
        align(headerRowSlot, ALIGN_FILL, ALIGN_FILL)
        local headerSurfaceSlot = headerSize:AddChild(header)
        align(headerSurfaceSlot, ALIGN_FILL, ALIGN_FILL)
        local headerSlot = layout:AddChild(headerSize)
        align(headerSlot, ALIGN_FILL, ALIGN_FILL)
        setPadding(headerSlot, 0, 0, 0, 8)

        local tabsSize = construct(tree, "/Script/UMG.SizeBox")
        local tabsSurface = construct(tree, "/Script/UMG.Border")
        local tabsRow = construct(tree, "/Script/UMG.HorizontalBox")
        if tabsSize == nil or tabsSurface == nil or tabsRow == nil then
            error("settings tab bar is unavailable")
        end
        tabsSize:SetHeightOverride(SIZE.settingsTabs)
        tabsSurface:SetBrushColor(COLORS.chrome)
        tabsSurface:SetPadding({ Left = 4, Top = 3, Right = 4, Bottom = 3 })
        local previousBox, previousButton =
            state.makeSettingsTabArrow(tree, "‹")
        if previousBox == nil or previousButton == nil then
            error("previous settings tab arrow is unavailable")
        end
        local previousSlot = tabsRow:AddChild(previousBox)
        align(previousSlot, ALIGN_CENTER, ALIGN_CENTER)
        setPadding(previousSlot, 0, 0, 4, 0)
        state.settingsTabPreviousButton = previousButton
        local tabLabels = {
            general = strings.tabGeneral or "General",
            automaticSale = strings.sectionAutoSell,
            specialItems = strings.sectionSpecial,
        }
        for index, pageId in ipairs(state.settingsPageOrder) do
            local button = construct(tree, "/Script/UMG.Button")
            local label = makeText(tree, tabLabels[pageId] or pageId,
                14, COLORS.muted, TEXT_CENTER)
            if button == nil or label == nil then
                error("settings tab is unavailable")
            end
            button.bIsFocusable = false
            label:SetVisibility(VIS_HIT_TEST_INVISIBLE)
            align(button:AddChild(label), ALIGN_FILL, ALIGN_CENTER)
            local buttonSlot = tabsRow:AddChild(button)
            setFill(buttonSlot)
            align(buttonSlot, ALIGN_FILL, ALIGN_FILL)
            if index > 1 then
                setPadding(buttonSlot, SIZE.settingsTabGap, 0, 0, 0)
            end
            local record = { pageId = pageId, widget = button, text = label }
            state.settingsTabButtons[#state.settingsTabButtons + 1] = record
            registerDirectActionButton(button)
        end
        local nextBox, nextButton = state.makeSettingsTabArrow(tree, "›")
        if nextBox == nil or nextButton == nil then
            error("next settings tab arrow is unavailable")
        end
        local nextSlot = tabsRow:AddChild(nextBox)
        align(nextSlot, ALIGN_CENTER, ALIGN_CENTER)
        setPadding(nextSlot, 4, 0, 0, 0)
        state.settingsTabNextButton = nextButton
        align(tabsSurface:AddChild(tabsRow), ALIGN_FILL, ALIGN_FILL)
        align(tabsSize:AddChild(tabsSurface), ALIGN_FILL, ALIGN_FILL)
        local tabsSlot = layout:AddChild(tabsSize)
        align(tabsSlot, ALIGN_FILL, ALIGN_FILL)
        setPadding(tabsSlot, 0, 0, 0, 8)

        -- The fixed content width reserves a scrollbar gutter, so pages that
        -- need scrolling cannot move their right-aligned controls.
        scroll:SetAlwaysShowScrollbar(false)
        scroll.AlwaysShowScrollbarTrack = false
        scroll:SetScrollbarThickness({
            X = SIZE.scrollbarThickness, Y = SIZE.scrollbarThickness,
        })
        scroll:SetScrollbarPadding({
            Left = SIZE.scrollbarPadding, Top = SIZE.scrollbarPadding,
            Right = SIZE.scrollbarPadding, Bottom = SIZE.scrollbarPadding,
        })
        contentFrame:SetBrushColor(COLORS.content)
        contentFrame:SetPadding({ Left = 0, Top = 0, Right = 0, Bottom = 0 })
        local frameScrollSlot = contentFrame:AddChild(scroll)
        align(frameScrollSlot, ALIGN_FILL, ALIGN_FILL)
        contentViewport:SetWidthOverride(contentWidth + SIZE.scrollbarGutter)
        local viewportFrameSlot = contentViewport:AddChild(contentFrame)
        align(viewportFrameSlot, ALIGN_FILL, ALIGN_FILL)
        local contentViewportSlot = layout:AddChild(contentViewport)
        setFill(contentViewportSlot)
        align(contentViewportSlot, ALIGN_FILL, ALIGN_FILL)
        contentBox:SetWidthOverride(contentWidth)
        contentBox:SetMinDesiredHeight(math.max(
            SIZE.contentMinimum, height - 296.0))
        for pageId, page in pairs(state.settingsPages) do
            local pageSlot = contentLayer:AddChildToOverlay(page)
            align(pageSlot, ALIGN_FILL, ALIGN_FILL)
            page:SetVisibility(pageId == state.activeSettingsPage
                and VIS_VISIBLE or VIS_COLLAPSED)
        end
        local contentLayerSlot = contentBox:AddChild(contentLayer)
        align(contentLayerSlot, ALIGN_FILL, ALIGN_FILL)
        local bodySlot = scroll:AddChild(contentBox)
        align(bodySlot, ALIGN_FILL, ALIGN_LEFT)

        state.buildingPageId = "general"
        if not addSection(tree, generalBody, strings.sectionBasics, 0)
            or not addShortcutRow(tree, generalBody, strings)
            or not addChoiceRow(tree, generalBody, "ResultDisplay",
                strings.resultDisplay,
                { "Default", "TextOnly", "ResultWindow" },
                { strings.resultDefault, strings.resultText,
                    strings.resultWindow }, true)
            or not Deferred.addHelperText(tree, generalBody,
                strings.resultDisplayHelper)
            or not addSection(tree, generalBody, strings.sectionStorage, 16)
            or not addToggleRow(tree, generalBody, "IncludeExcludedItems",
                strings.includeExcluded, false)
            or not addToggleRow(tree, generalBody, "IncludeNewItems",
                strings.includeNew, false)
            or not addToggleRow(tree, generalBody, "IncludeGuildChest",
                strings.includeGuildChest, true) then
            error("general settings rows cannot be created")
        end

        state.buildingPageId = "automaticSale"
        if not addSection(tree, automaticSaleBody,
                strings.sectionAutoSell, 0)
            or not Deferred.addNoticeText(tree, automaticSaleBody,
                strings.saleBonusNotice)
            or not addToggleRow(tree, automaticSaleBody,
                "KeepSaleItemsWhenNoMerchant",
                strings.keepSaleItemsWhenNoMerchant, false)
            or not Deferred.addHelperText(tree, automaticSaleBody,
                strings.keepSaleItemsWhenNoMerchantHelper)
            or not addToggleRow(tree, automaticSaleBody, "AutoSellValuables",
                strings.autoSellValuables, false)
            or not Deferred.addValuablePickerRow(tree, automaticSaleBody,
                strings.keptValuables)
            or not addToggleRow(tree, automaticSaleBody, "AutoSellAmmo",
                strings.autoSellAmmo, true)
            or not Deferred.addAmmoPickerRow(tree, automaticSaleBody,
                strings.keptAmmo)
            or not addToggleRow(tree, automaticSaleBody, "AutoSellPalSpheres",
                strings.autoSellPalSpheres, false)
            or not Deferred.addPalSpherePickerRow(tree, automaticSaleBody,
                strings.keptPalSpheres)
            or not addToggleRow(tree, automaticSaleBody, "AutoSellFishingBait",
                strings.autoSellFishingBait, false)
            or not Deferred.addFishingBaitPickerRow(tree, automaticSaleBody,
                strings.keptFishingBait) then
            error("automatic-sale settings rows cannot be created")
        end

        state.buildingPageId = "specialItems"
        if not addSection(tree, specialItemsBody, strings.sectionSpecial, 0)
            or not addToggleRow(tree, specialItemsBody,
                "BreedingFarmCakeFirst", strings.breedingFarmCakeFirst, true)
            or not Deferred.addHelperText(tree, specialItemsBody,
                strings.breedingFarmCakeFirstHelper)
            or not addToggleRow(tree, specialItemsBody, "FoodBoxFirst",
                strings.foodBoxFirst, true)
            or not Deferred.addHelperText(tree, specialItemsBody,
                strings.foodBoxFirstHelper)
            or not addToggleRow(tree, specialItemsBody, "MedicineRackFirst",
                strings.medicineRackFirst, true)
            or not Deferred.addHelperText(tree, specialItemsBody,
                strings.medicineRackFirstHelper)
            or not addChoiceRow(tree, specialItemsBody, "PalEggRouting",
                strings.eggRouting,
                { "IncubatorOnly", "IncubatorThenStorage", "ManualPlacement" },
                { strings.eggOnly, strings.eggStorage,
                    strings.manualPlacement }, false)
            or not addToggleRow(tree, specialItemsBody,
                "IncludeSmallIncubators", strings.includeSmallIncubators,
                false, 20.0)
            or not addChoiceRow(tree, specialItemsBody, "RelicRouting",
                strings.relicRouting,
                { "RecyclerOnly", "RecyclerThenStorage", "ManualPlacement" },
                { strings.relicOnly, strings.relicStorage,
                    strings.manualPlacement }, true)
            or not addNumberRow(tree, specialItemsBody,
                "WorldTreeHolyWaterMinimum",
                strings.holyWater, 1, 100, false) then
            error("special-item settings rows cannot be created")
        end
        state.buildingPageId = nil
        for _, page in pairs(state.settingsPages) do
            local pageEnd = construct(tree, "/Script/UMG.SizeBox")
            if pageEnd == nil then
                error("settings page end spacing is unavailable")
            end
            pageEnd:SetHeightOverride(SIZE.pageEdge)
            page:AddChild(pageEnd)
        end

        local versionAction = {
            box = versionButton, widget = versionButton,
            surface = versionButton, text = version,
            visualButton = versionButton, directButton = true,
            role = "releaseNotes", tooltip = releaseStrings.title,
            neutralForeground = true,
        }
        registerDirectActionButton(versionButton)
        state.headerActionVisuals[#state.headerActionVisuals + 1] = versionAction
        local releaseNotesControl = {
            kind = "releaseNotes", widget = versionButton,
            tooltip = releaseStrings.title,
        }
        local aboutControl = {
            kind = "about", widget = aboutAction.widget, tooltip = strings.about,
        }
        local resetControl = {
            kind = "reset", widget = resetAction.widget, tooltip = strings.reset,
        }
        local closeControl = {
            kind = "close", widget = closeAction.widget, tooltip = strings.close,
        }
        registerFocusable(releaseNotesControl, versionButton, versionAction)
        state.controls[#state.controls + 1] = releaseNotesControl
        if state.steamVoteControl ~= nil and voteBox ~= nil then
            registerFocusable(state.steamVoteControl, voteBox)
            state.controls[#state.controls + 1] = state.steamVoteControl
        end
        registerFocusable(aboutControl, aboutAction.box, aboutAction)
        registerFocusable(resetControl, resetAction.box, resetAction)
        registerFocusable(closeControl, closeAction.box, closeAction)
        state.controls[#state.controls + 1] = aboutControl
        state.controls[#state.controls + 1] = resetControl
        state.controls[#state.controls + 1] = closeControl
        state.rebuildSettingsFocusEntries()

        local footerSize = construct(tree, "/Script/UMG.SizeBox")
        local footer = construct(tree, "/Script/UMG.Border")
        local footerStack = construct(tree, "/Script/UMG.VerticalBox")
        local footerHeaderSize = construct(tree, "/Script/UMG.SizeBox")
        local footerHeader = construct(tree, "/Script/UMG.HorizontalBox")
        local footerGrid = construct(tree, "/Script/UMG.GridPanel")
        local footerTitleCopy = strings.inputHelpTitle
            or (mode == "hosted" and strings.footerHosted or strings.footer)
            or "Controls"
        local footerTitle = makeText(tree, footerTitleCopy, 12, COLORS.text)
        local footerDevice = makeText(tree,
            strings.inputDeviceKeyboardMouse or "Keyboard / Mouse",
            11, COLORS.accent)
        local footerSpacer = construct(tree, "/Script/UMG.SizeBox")
        state.statusText = makeText(tree, "", 11, COLORS.muted, TEXT_RIGHT)
        state.modeText = modeText
        state.footerHelp = nil
        state.footerMode = mode
        if footerSize == nil or footer == nil or footerStack == nil
            or footerHeaderSize == nil or footerHeader == nil
            or footerGrid == nil or footerTitle == nil
            or footerDevice == nil or footerSpacer == nil
            or state.statusText == nil then
            error("settings footer is unavailable")
        end
        footerSize:SetHeightOverride(SIZE.footer)
        footerHeaderSize:SetHeightOverride(SIZE.footerHelpHeader)
        footer:SetBrushColor(COLORS.chrome)
        footer:SetPadding({ Left = 12, Top = 8, Right = 12, Bottom = 8 })
        align(footerHeader:AddChild(footerTitle), ALIGN_LEFT, ALIGN_CENTER)
        local deviceSlot = footerHeader:AddChild(footerDevice)
        setPadding(deviceSlot, 8, 0, 0, 0)
        align(deviceSlot, ALIGN_LEFT, ALIGN_CENTER)
        local spacerSlot = footerHeader:AddChild(footerSpacer)
        setFill(spacerSlot)
        align(spacerSlot, ALIGN_FILL, ALIGN_FILL)
        align(footerHeader:AddChild(state.statusText), ALIGN_RIGHT, ALIGN_CENTER)
        align(footerHeaderSize:AddChild(footerHeader), ALIGN_FILL, ALIGN_FILL)
        align(footerStack:AddChild(footerHeaderSize), ALIGN_FILL, ALIGN_FILL)
        for valueColumn = 1, 5, 2 do
            footerGrid:SetColumnFill(valueColumn, 1.0)
        end
        local gridSlot = footerStack:AddChild(footerGrid)
        align(gridSlot, ALIGN_FILL, ALIGN_FILL)
        setPadding(gridSlot, 0, 4, 0, 0)
        local footerStackSlot = footer:AddChild(footerStack)
        align(footerStackSlot, ALIGN_FILL, ALIGN_FILL)
        align(footerSize:AddChild(footer), ALIGN_FILL, ALIGN_FILL)
        local footerSpecs = FooterGuide.footerHelpSpecs(strings)
        local footerGroups = {}
        for index, spec in ipairs(footerSpecs) do
            local rowIndex = index > 3 and 1 or 0
            local pairIndex = (index - 1) % 3
            if FooterGuide.addGroup(tree, footerGrid, spec, footerGroups,
                    "keyboard", rowIndex, pairIndex,
                    state.gamepadKeyGuideFamily) == nil then
                error("settings footer group is unavailable")
            end
        end
        state.footerGuideRecords = {
            groups = footerGroups,
            title = footerTitle,
            deviceLabel = footerDevice,
        }
        state.footerGuideSignature = nil
        FooterGuide.refreshFooterHelp(true)
        local footerSlot = layout:AddChild(footerSize)
        align(footerSlot, ALIGN_FILL, ALIGN_FILL)
        setPadding(footerSlot, 0, 8, 0, 0)
        if not Deferred.buildChoiceModal(
                tree, root, viewportWidth, viewportHeight, 1) then
            error("settings acknowledgement modal cannot be initialized")
        end
        widget:SetVisibility(VIS_COLLAPSED)
        widget:AddToViewport(120)
        refreshTriggerSurfaces()
    end)
    if not ok then
        pcall(function() widget:RemoveFromParent() end)
        clearWindowReferences()
        return nil, "settings layout cannot be initialized"
    end
    return widget, nil
end

local function acquireInput(controller, widget, mode, hostedInputRoute)
    local controllerAddress = P.objectAddress(controller)
    if controllerAddress == nil then return false, "local controller identity is unavailable" end
    state.controller = controller
    local acquired, acquireError, retainedTransaction = InputOwner.acquire(
        controller, widget, {
        allowWithoutBridge = true,
        modalUIOnly = true,
        hostedParent = mode == "hosted",
        exclusiveController = mode ~= "hosted",
        useCookedBridge = mode ~= "hosted"
            or hostedInputRoute == "extension-cooked",
        onPressed = function(keyName, source)
            if tostring(keyName):find("Gamepad_", 1, true) == 1 then
                return dispatchControllerPressed(keyName, source or "actor")
            end
            return handlePressed(keyName, nil, source)
        end,
        onReleased = function(keyName, source)
            if tostring(keyName):find("Gamepad_", 1, true) == 1 then
                return dispatchControllerReleased(keyName, source or "actor")
            end
            return handleReleased(keyName)
        end,
        onAxisX = function(value) handleAxis("x", value, "actor") end,
        onAxisY = function(value) handleAxis("y", value, "actor") end,
        onClicked = function() activateHoveredDirectAction() end,
        onToggleChanged = function()
            commitNativeToggleChanges("toggle-native")
        end,
        onClose = function(source) SettingsUI.close(source) end,
    })
    if not acquired then
        if retainedTransaction ~= true then state.controller = nil end
        return false, acquireError, retainedTransaction == true
    end
    if not InputOwner.bindActionButtons(state.directActionButtons)
        and InputOwner.cookedInputActive() then
        log("native action delegates unavailable; using mouse fallback")
    end
    if not InputOwner.bindToggleControls(state.controls)
        and InputOwner.cookedInputActive() then
        log("native toggle delegates unavailable; using poll fallback")
    end
    return true, nil
end

function SettingsUI.configure(options)
    options = type(options) == "table" and options or {}
    state.version = tostring(options.version or "")
    state.config = options.config
    state.configPath = options.configPath
    state.registerShortcut = options.registerShortcut
    state.shortcutConflict = options.shortcutConflict
    state.readHostedControllerSnapshot = options.readHostedControllerSnapshot
    state.ackHostedControllerSnapshot = options.ackHostedControllerSnapshot
    state.publishHostedCloseBlocked = options.publishHostedCloseBlocked
    state.log = options.log
    state.onApplied = options.onApplied
    state.onClosed = options.onClosed
    InputOwner.configure(state.log)
    SteamVote.configure(state.log)
    installPreviewKeyHook()
    installKeyUpHook()
    installSelectorSelectedKeyHook()
    installPointerHooks()
end

function SettingsUI.prepare()
    local prepareStarted = os.clock()
    local inputHooksReady = installPreviewKeyHook()
        and installKeyUpHook()
        and installSelectorSelectedKeyHook()
    installPointerHooks()
    local gameplayContext = P.currentGameplayContext()
    local controller = type(gameplayContext) == "table"
        and gameplayContext.controller or nil
    if state.open and (not P.isValid(controller)
            or not windowCacheMatches(controller)) then
        SettingsUI.close("context-changed")
        gameplayContext = P.currentGameplayContext()
        controller = type(gameplayContext) == "table"
            and gameplayContext.controller or nil
    end
    local bridgeReady = InputOwner.prepare()
    local bridgeCacheHit = false
    if P.isValid(controller) then
        local prepared, cacheHit = InputOwner.prepareForController(controller)
        bridgeReady = prepared or bridgeReady
        bridgeCacheHit = cacheHit == true
    end
    local windowReady = P.isValid(controller) and windowCacheMatches(controller)
    local windowCacheHit = windowReady == true
    if not state.open and type(state.config) == "table"
        and P.isValid(controller) and not windowReady then
        local staleReleased = true
        if (P.isValid(state.widget)
                or (type(state.windowCache) == "table"
                    and state.windowCache.ready == true)) then
            staleReleased = discardWindowCache()
        end
        if staleReleased then
            local widget = select(1, buildSettingsWindow(controller, "standalone"))
            if P.isValid(widget) then
                state.widget = widget
                windowReady = rememberWindowCache(controller)
            end
        end
    end
    if windowReady and state.steamVotePalVisualReady ~= true then
        refreshSteamVotePalVisuals()
    end
    local prepareFinished = os.clock()
    state.lastPrepareDiagnostics = {
        startedAt = prepareStarted,
        finishedAt = prepareFinished,
        totalMs = (prepareFinished - prepareStarted) * 1000.0,
        didWork = windowCacheHit ~= true
            or (bridgeReady == true and bridgeCacheHit ~= true),
    }
    return inputHooksReady, bridgeReady, windowReady
end

function SettingsUI.preflightSteamVote()
    local gameplayContext = P.currentGameplayContext()
    local controller = type(gameplayContext) == "table"
        and gameplayContext.controller or nil
    if not P.isValid(controller) then return false end
    if not SteamVote.initialize() then return true end
    SteamVote.poll()
    return not SteamVote.polling()
end

function SettingsUI.open(mode, options)
    options = type(options) == "table" and options or {}
    local openStarted = os.clock()
    local prewarm = state.lastPrepareDiagnostics
    local includePrewarm = type(prewarm) == "table" and prewarm.didWork == true
        and openStarted - (tonumber(prewarm.finishedAt) or -1.0) <= 0.05
    local transactionStarted = includePrewarm
        and tonumber(prewarm.startedAt) or openStarted
    local capturePerformance = type(state.config) == "table"
        and state.config.PerformanceCapture == true
    local hookFinished = openStarted
    local cacheFinished = openStarted
    local buildFinished = openStarted
    local prepareFinished = openStarted
    mode = mode == "hosted" and "hosted" or "standalone"
    local hostedInputRoute = mode == "hosted" and options.hostedInputRoute or nil
    if mode == "hosted" and hostedInputRoute ~= "host-native"
        and hostedInputRoute ~= "extension-cooked" then
        return false, "hosted input route is unavailable"
    end
    local initialInputDevice = options.initialInputDevice
    if initialInputDevice ~= "gamepad" and initialInputDevice ~= "mouse" then
        initialInputDevice = "keyboard"
    end
    if state.open then
        if state.mode == mode then return true, nil end
        return false, "settings surface is already open"
    end
    if type(state.config) ~= "table" then return false, "settings are unavailable" end
    local gameplayContext = P.currentGameplayContext()
    local controller = type(gameplayContext) == "table"
        and gameplayContext.controller or nil
    if not P.isValid(controller) then
        return false, "local gameplay context is unavailable"
    end
    local resolvedSteamVote = SteamVote.resolvedStatus()
    local steamVoteReady = SteamVote.initialize()
    local steamVoteStatus = steamVoteReady and SteamVote.poll() or nil
    local steamVotePending = steamVoteReady and SteamVote.polling()
    local stableSteamVote = steamVoteStatus or resolvedSteamVote
    if not installPreviewKeyHook() or not installKeyUpHook()
        or not installSelectorSelectedKeyHook() then
        return false, "focus-scoped settings input is unavailable"
    end
    installPointerHooks()
    hookFinished = os.clock()
    local reuseWindow = windowCacheMatches(controller)
    cacheFinished = os.clock()
    if not reuseWindow and (P.isValid(state.widget)
        or (type(state.windowCache) == "table" and state.windowCache.ready == true))
        and not discardWindowCache() then
        return false, "stale settings window cannot be released"
    end
    local widget = state.widget
    if not reuseWindow then
        local buildError
        widget, buildError = buildSettingsWindow(controller, mode)
        if widget == nil then
            clearWindowReferences()
            return false, buildError
        end
        state.widget = widget
        rememberWindowCache(controller)
    end
    buildFinished = os.clock()
    state.lifecycle = "opening"
    state.windowSession = state.windowSession + 1
    state.generation = state.generation + 1
    state.mode = mode
    state.open = true
    state.closeRecoveryDeadline = 0.0
    state.closeRecoveryRetryAt = 0.0
    state.closeRecoveryReason = nil
    state.nextContextCheckAt = 0.0
    state.gamepadBackDown = false
    state.gamepadAcceptDown = false
    state.controllerInputOwner = nil
    state.controllerDown = {}
    state.controllerInputSources = {}
    state.lastHostedControllerEdgeRevision = nil
    state.nativeControllerInitialized = false
    state.axisArmed = { x = true, y = true }
    state.axisValues = { x = 0.0, y = 0.0 }
    state.pointerAction = nil
    state.pendingAboutPointerClose = nil
    cancelNavigationRepeat()
    state.synchronousNavigationUntil = {}
    state.deferredInputClose = nil
    state.shortcutCaptureCancelKey = nil
    state.shortcutCaptureCancelUntil = 0.0
    state.trailingReleaseUntil = {}
    if not prepareWindowForOpen(mode) then
        state.open = false
        state.lifecycle = "closed"
        state.mode = nil
        discardWindowCache()
        return false, "settings window cannot be activated"
    end
    prepareFinished = os.clock()
    local acquired, acquireError, retainedTransaction = acquireInput(
        controller, widget, mode, hostedInputRoute)
    if not acquired then
        if retainedTransaction == true then
            state.lifecycle = "recovering"
            state.closeRecoveryDeadline = os.clock() + 3.0
            state.closeRecoveryRetryAt = os.clock() + 0.25
            state.closeRecoveryReason = "open-rollback"
            setStatus(currentStrings().inputRestoreFailed
                or "Could not restore input. The panel remains open; try Close again.", true)
            for _, keyName in ipairs(state.controllerKeys) do
                state.controllerDown[keyName] = inputKeyDown(controller, keyName) == true
            end
            state.pollPending = false
            schedulePoll()
            focusEntry(1, initialInputDevice, true)
            pcall(function() state.widget:SetRenderOpacity(1.0) end)
            log("settings open rollback retained a visible modal transaction")
            -- The child still owns at least part of the modal transaction. Keep
            -- the host suspended and expose the same panel as the recovery
            -- surface; hiding it would create an unrecoverable transparent lock.
            return true, nil
        end
        state.open = false
        state.lifecycle = "closed"
        state.mode = nil
        state.controller = nil
        pcall(function()
            widget.bIsFocusable = false
            widget:SetVisibility(VIS_COLLAPSED)
        end)
        return false, acquireError or "settings input ownership cannot be acquired"
    end
    for _, keyName in ipairs(state.controllerKeys) do
        state.controllerDown[keyName] = inputKeyDown(controller, keyName) == true
    end
    local downvoteAcknowledgementOpen = false
    local steamVoteCheckingOpen = false
    state.pendingDownvoteAcknowledgement = false
    if steamVoteReady and type(state.steamVoteControl) == "table" then
        applySteamVoteVisual(stableSteamVote or SteamVote.status(), true)
        if stableSteamVote == SteamVote.statuses.down then
            downvoteAcknowledgementOpen =
                Deferred.openDownvoteAcknowledgement() == true
            state.pendingDownvoteAcknowledgement = not downvoteAcknowledgementOpen
        elseif steamVotePending then
            steamVoteCheckingOpen = Deferred.openSteamVoteChecking() == true
        end
    end
    if not downvoteAcknowledgementOpen and not steamVoteCheckingOpen then
        focusEntry(1, initialInputDevice, true)
    end
    state.lifecycle = "open"
    pcall(function() state.widget:SetRenderOpacity(1.0) end)
    refreshInputFocusVisuals()
    state.pollPending = false
    state.pollLastTickAt = os.clock()
    schedulePoll()
    if capturePerformance then
        local bridge = InputOwner.lastAcquireDiagnostics() or {}
        local finished = os.clock()
        log(string.format(
            "settings_perf|mode=%s|window_cache=%s|bridge_cache=%s"
                .. "|bridge_created=%s|bridge_mounted=%s"
                .. "|prewarm_included=%s|prewarm_ms=%.3f"
                .. "|hooks_ms=%.3f|cache_ms=%.3f|build_ms=%.3f"
                .. "|prepare_ms=%.3f|input_ms=%.3f|total_ms=%.3f",
            mode, reuseWindow and "hit" or "miss",
            bridge.bridgeCacheHit == true and "hit" or "miss",
            tostring(bridge.bridgeCreated == true),
            tostring(bridge.bridgeMounted == true),
            tostring(includePrewarm == true),
            includePrewarm and (tonumber(prewarm.totalMs) or 0.0) or 0.0,
            (hookFinished - openStarted) * 1000.0,
            (cacheFinished - hookFinished) * 1000.0,
            (buildFinished - cacheFinished) * 1000.0,
            (prepareFinished - buildFinished) * 1000.0,
            (finished - prepareFinished) * 1000.0,
            (finished - transactionStarted) * 1000.0))
    end
    log("settings opened (" .. mode .. ")")
    return true, nil
end

completeClose = function(closedMode, reason, widget, controller, escapeClose)
    local preserveWindow = windowCacheMatches(controller)
    state.open = false
    state.lifecycle = "closed"
    state.mode = nil
    if type(state.publishHostedCloseBlocked) == "function" then
        state.publishHostedCloseBlocked(false)
    end
    state.generation = state.generation + 1
    state.closeRecoveryDeadline = 0.0
    state.closeRecoveryRetryAt = 0.0
    state.closeRecoveryReason = nil
    state.nextContextCheckAt = 0.0
    cancelNavigationRepeat()
    stopPoll()
    state.gamepadBackDown = false
    state.gamepadAcceptDown = false
    state.controllerInputOwner = nil
    state.controllerDown = {}
    state.controllerInputSources = {}
    state.lastHostedControllerEdgeRevision = nil
    state.axisValues = { x = 0.0, y = 0.0 }
    state.pointerAction = nil
    state.pendingAboutPointerClose = nil
    state.synchronousNavigationUntil = {}
    state.deferredInputClose = nil
    state.pollLastTickAt = 0.0
    state.shortcutCaptureCancelKey = nil
    state.shortcutCaptureCancelUntil = 0.0
    if preserveWindow and P.isValid(widget) then
        local hidden = pcall(function()
            widget.bIsFocusable = false
            widget:SetVisibility(VIS_COLLAPSED)
        end)
        if not hidden then
            preserveWindow = false
            discardWindowCache()
        end
    elseif not preserveWindow then
        discardWindowCache()
    end
    state.controller = nil
    if escapeClose then InputOwner.noteEscapeWindowClosed() end
    if type(state.onClosed) == "function" then state.onClosed(closedMode, reason) end
    log("settings closed (" .. tostring(reason or "request") .. ")")
    return true
end

function SettingsUI.close(reason)
    if SettingsUI.closeBlocked() then
        local internalClose = reason == "native-controller-failure"
            or reason == "recovery-retry" or reason == "context-changed"
            or reason == "host-takeover" or reason == "runtime-superseded"
            or reason == "host-unavailable"
            or reason == "host-open-ack-failed"
        if not internalClose then return false end
    end
    if not state.open then return true end
    if state.lifecycle == "closing" then return false end
    local escapeClose = reason == "escape"
    if escapeClose then InputOwner.armEscapeClose(reason) end
    local closedMode = state.mode
    local widget = state.widget
    local controller = state.controller
    state.lifecycle = "closing"
    cancelNavigationRepeat()
    local numberControl = focusedNumberControl()
    if numberControl ~= nil then
        commitNumberEditor(numberControl, "number-close")
    end
    closeChoiceModal(false)
    state.closeReleaseNotesModal(false)
    closeAboutModal(false)
    local unavailableOwner = reason == "host-unavailable"
        or reason == "context-changed"
        or state.closeRecoveryReason == "host-unavailable"
        or state.closeRecoveryReason == "context-changed"
    if not InputOwner.release({
            hostUnavailable = unavailableOwner,
        }) then
        if escapeClose then InputOwner.cancelEscapeClose() end
        local now = os.clock()
        state.lifecycle = "recovering"
        if (tonumber(state.closeRecoveryDeadline) or 0.0) <= now then
            state.closeRecoveryDeadline = now + 3.0
        end
        state.closeRecoveryRetryAt = now + 0.25
        if reason == "host-unavailable" then
            state.closeRecoveryReason = reason
        else
            state.closeRecoveryReason = state.closeRecoveryReason or reason
        end
        pcall(function() state.widget:SetRenderOpacity(1.0) end)
        focusNavigationRoot()
        setStatus(currentStrings().inputRestoreFailed
            or "Could not restore input. The panel remains open; try Close again.", true)
        refreshInputFocusVisuals()
        log("settings close could not restore input; modal transaction retained")
        return false
    end
    return completeClose(closedMode, reason, widget, controller, escapeClose)
end

function SettingsUI.toggle(mode)
    if state.open then
        if SettingsUI.closeBlocked() then return true end
        return SettingsUI.close("shortcut")
    end
    return SettingsUI.open(mode or "standalone")
end

function SettingsUI.closeBlocked()
    return type(state.activeChoice) == "table"
        and (state.activeChoice.kind == "downvoteAcknowledgement"
            or state.activeChoice.kind == "steamVoteChecking")
end

function SettingsUI.mode()
    return state.open and state.mode or nil
end

function SettingsUI.inputGeneration()
    return state.generation
end

return SettingsUI
