local P = require("palworld")
local Settings = require("settings")
local Localization = require("localization")
local InputOwner = require("pal_insight_bridge")
local SteamVote = require("steam_vote")

local SettingsUI = {}

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

local COLORS = {
    white = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 },
    shield = { R = 0.0, G = 0.0, B = 0.0, A = 0.0 },
    window = { R = 0.006, G = 0.008, B = 0.011, A = 0.78 },
    chrome = { R = 0.027, G = 0.033, B = 0.040, A = 0.72 },
    content = { R = 0.031, G = 0.037, B = 0.045, A = 0.88 },
    section = { R = 0.059, G = 0.071, B = 0.082, A = 0.90 },
    control = { R = 0.093, G = 0.112, B = 0.127, A = 0.88 },
    controlHover = { R = 0.147, G = 0.175, B = 0.198, A = 0.94 },
    rowHover = { R = 0.468, G = 0.515, B = 0.552, A = 0.14 },
    rowFocus = { R = 0.058, G = 0.105, B = 0.138, A = 0.88 },
    controlFocus = { R = 0.060, G = 0.156, B = 0.227, A = 0.96 },
    controlSelected = { R = 0.140, G = 0.176, B = 0.207, A = 0.92 },
    controlPressed = { R = 0.056, G = 0.070, B = 0.084, A = 0.98 },
    controlDisabled = { R = 0.047, G = 0.054, B = 0.063, A = 0.64 },
    outline = { R = 0.716, G = 0.807, B = 0.855, A = 0.15 },
    border = { R = 0.761, G = 0.807, B = 0.839, A = 0.54 },
    borderFocus = { R = 0.292, G = 0.610, B = 0.730, A = 1.0 },
    accent = { R = 0.209, G = 0.533, B = 0.665, A = 1.0 },
    accentHover = { R = 0.288, G = 0.580, B = 0.699, A = 1.0 },
    accentPressed = { R = 0.184, G = 0.469, B = 0.585, A = 1.0 },
    actionInfo = { R = 0.209, G = 0.533, B = 0.665, A = 1.0 },
    actionWarning = { R = 0.807, G = 0.451, B = 0.102, A = 1.0 },
    actionDanger = { R = 0.800, G = 0.390, B = 0.380, A = 1.0 },
    text = { R = 0.930, G = 0.947, B = 0.956, A = 1.0 },
    muted = { R = 0.631, G = 0.680, B = 0.708, A = 1.0 },
    textMuted = { R = 0.361, G = 0.407, B = 0.440, A = 1.0 },
    textOnAccent = { R = 0.004, G = 0.009, B = 0.012, A = 1.0 },
    danger = { R = 1.0, G = 0.72, B = 0.48, A = 1.0 },
    voteBlack = { R = 0.0, G = 0.0, B = 0.0, A = 1.0 },
    voteGold = { R = 1.0, G = 0.7379109859, B = 0.0051819999, A = 1.0 },
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
    headerAction = 36.0,
    headerActionGap = 8.0,
    headerActionIconBox = 20.0,
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
    aboutCreatorLinkWidth = 140.0,
    aboutPreviewThumbnailWidth = 160.0,
    aboutPreviewThumbnailHeight = 90.0,
    aboutPrimaryActionWidth = 120.0,
    aboutRosterWidth = 620.0,
    aboutRosterMaxHeight = 500.0,
    aboutSupportActionWidth = 136.0,
    aboutSupportActionHeight = 40.0,
    aboutSupportLogoWidth = 124.0,
    aboutSupportLogoHeight = 35.0,
}

local FONT_SIZE = {
    [11] = 9, [12] = 10, [13] = 11, [14] = 12,
    [15] = 13, [16] = 13, [18] = 15, [20] = 16,
}

local SETTING_KEYS = {
    "Key", "Shift", "Ctrl", "Alt", "ResultDisplay",
    "IncludeExcludedItems", "IncludeNewItems", "PalEggRouting",
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
    PalEggRouting = "IncubatorOnly",
    RelicRouting = "RecyclerOnly",
    WorldTreeHolyWaterMinimum = 10,
}

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
    quickStackCurseForge =
        "https://www.curseforge.com/palworld/lua-code-mods/pal-insight-quick-stack",
    x = "https://x.com/cratexnet",
    discord = "https://discord.gg/JWhE4TKsBN",
    bmc = "https://buymeacoffee.com/cratexnet",
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
    log = nil,
    onApplied = nil,
    onClosed = nil,
    open = false,
    mode = nil,
    generation = 0,
    widget = nil,
    widgetTree = nil,
    root = nil,
    windowCache = { ready = false },
    controller = nil,
    controls = {},
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
    aboutReturnFocusIndex = nil,
    aboutActions = {},
    aboutFocusIndex = 1,
    aboutPreferredColumn = 1,
    aboutActionHint = nil,
    aboutScroll = nil,
    aboutRosterOverlay = nil,
    aboutRosterTitle = nil,
    aboutRosterDescription = nil,
    aboutRosterEmpty = nil,
    aboutRosterCloseWidget = nil,
    aboutRosterCloseAction = nil,
    aboutRosterOpen = false,
    aboutRosterMode = nil,
    aboutTextures = {},
    steamVoteControl = nil,
    steamVoteNoneWidget = nil,
    steamVoteDownWidget = nil,
    steamVoteNoneSurface = nil,
    steamVoteDownSurface = nil,
    steamVoteUpSurface = nil,
    steamVoteDisplayStatus = nil,
    steamVotePendingUp = false,
    steamVoteTextures = {},
    steamVotePalTexture = nil,
    steamVotePalVisuals = {},
    steamVotePalVisualReady = false,
    steamVotePalRetryAt = 0,
    steamVoteActionVisuals = {},
    pollPending = false,
    pollGeneration = 0,
    pollLoopHandle = nil,
    pollGameThreadCallback = nil,
    gamepadBackDown = false,
    gamepadAcceptDown = false,
    controllerDown = {},
    axisArmed = { x = true, y = true },
    triggerSurfaces = {},
    headerActionVisuals = {},
    contentWidth = 640.0,
    scroll = nil,
    nestedOverlay = nil,
    nestedTitle = nil,
    modalOptions = {},
    activeChoice = nil,
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
    selectorSelectedKeyHookReady = false,
    selectorSelectedKeyHookPreId = nil,
    selectorSelectedKeyHookPostId = nil,
    selectorChordProgrammatic = false,
    synchronousNavigationUntil = {},
    numberEdit = nil,
    lastPrepareDiagnostics = nil,
    trailingReleaseUntil = {},
}

local staticObjects = {}
local currentStrings

local function log(message)
    if type(state.log) == "function" then state.log(tostring(message)) end
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

local function styleTrigger(trigger, warning)
    local ok = pcall(function()
        -- The settings root owns navigation. Pointer-only surfaces must not
        -- steal Slate focus and strand later keyboard/controller input.
        trigger.bIsFocusable = false
        local style = trigger.WidgetStyle
        style.CheckBoxType = 1
        style.UncheckedImage = tintBrush(style.UncheckedImage, COLORS.transparent)
        style.UncheckedHoveredImage = tintBrush(
            style.UncheckedHoveredImage, COLORS.transparent)
        style.UncheckedPressedImage = tintBrush(
            style.UncheckedPressedImage, COLORS.transparent)
        style.CheckedImage = tintBrush(style.CheckedImage, COLORS.transparent)
        style.CheckedHoveredImage = tintBrush(
            style.CheckedHoveredImage, COLORS.transparent)
        style.CheckedPressedImage = tintBrush(
            style.CheckedPressedImage, COLORS.transparent)
        style.UncheckedForeground = slateColor(COLORS.transparent)
        style.CheckedForeground = slateColor(COLORS.transparent)
        style.HoveredForeground = slateColor(COLORS.transparent)
        style.PressedForeground = slateColor(COLORS.transparent)
        style.Padding = { Left = 0, Top = 0, Right = 0, Bottom = 0 }
        trigger.WidgetStyle = style
        trigger:SetIsChecked(false)
    end)
    return ok
end

local function styleToggle(toggle)
    return pcall(function()
        toggle:SetIsEnabled(true)
        local style = toggle.WidgetStyle
        style.UncheckedImage = tintBrush(style.UncheckedImage, COLORS.border)
        style.UncheckedHoveredImage = tintBrush(
            style.UncheckedHoveredImage, COLORS.text)
        style.UncheckedPressedImage = tintBrush(
            style.UncheckedPressedImage, COLORS.muted)
        style.CheckedImage = tintBrush(style.CheckedImage, COLORS.accent)
        style.CheckedHoveredImage = tintBrush(
            style.CheckedHoveredImage, COLORS.accent)
        style.CheckedPressedImage = tintBrush(
            style.CheckedPressedImage, COLORS.accentPressed)
        style.UncheckedForeground = slateColor(COLORS.muted)
        style.CheckedForeground = slateColor(COLORS.text)
        style.CheckedHoveredForeground = slateColor(COLORS.text)
        style.CheckedPressedForeground = slateColor(COLORS.text)
        style.HoveredForeground = slateColor(COLORS.text)
        style.PressedForeground = slateColor(COLORS.text)
        toggle.WidgetStyle = style
    end)
end

local function styleShortcutSelector(selector, focused)
    return pcall(function()
        selector:SetIsEnabled(true)
        local style = selector.WidgetStyle
        style.Normal = tintBrush(style.Normal, COLORS.transparent)
        style.Hovered = tintBrush(style.Hovered, COLORS.transparent)
        style.Pressed = tintBrush(style.Pressed, COLORS.transparent)
        style.Disabled = tintBrush(style.Disabled, COLORS.transparent)
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

local function makeTrigger(tree, label, width, warning, indicatorText, height)
    local box = construct(tree, "/Script/UMG.SizeBox")
    local surface = construct(tree, "/Script/UMG.Border")
    local trigger = construct(tree, "/Script/UMG.CheckBox")
    local overlay = construct(tree, "/Script/UMG.Overlay")
    local text = makeText(tree, label, 14,
        warning and COLORS.actionWarning or COLORS.text,
        indicatorText ~= nil and TEXT_LEFT or TEXT_CENTER)
    if box == nil or surface == nil or trigger == nil
        or overlay == nil or text == nil then return nil end
    local content
    local indicator
    if indicatorText ~= nil then
        content = construct(tree, "/Script/UMG.HorizontalBox")
        indicator = makeText(tree, indicatorText, 14, COLORS.muted, TEXT_RIGHT)
        if content == nil or indicator == nil then return nil end
    end
    local ok = pcall(function()
        box:SetWidthOverride(width or 170.0)
        box:SetHeightOverride(height or SIZE.control)
        surface:SetBrushColor(COLORS.control)
        surface:SetPadding({ Left = 0, Top = 0, Right = 0, Bottom = 0 })
        styleTrigger(trigger, warning)
        if content ~= nil then
            local labelSlot = content:AddChild(text)
            setFill(labelSlot)
            align(labelSlot, ALIGN_LEFT, ALIGN_CENTER)
            local indicatorSlot = content:AddChild(indicator)
            align(indicatorSlot, ALIGN_RIGHT, ALIGN_CENTER)
            local contentSlot = overlay:AddChildToOverlay(content)
            setPadding(contentSlot, 12, 0, 10, 0)
            align(contentSlot, ALIGN_FILL, ALIGN_CENTER)
        else
            local textSlot = overlay:AddChildToOverlay(text)
            align(textSlot, ALIGN_CENTER, ALIGN_CENTER)
        end
        local triggerSlot = overlay:AddChildToOverlay(trigger)
        align(triggerSlot, ALIGN_FILL, ALIGN_FILL)
        local overlaySlot = surface:AddChild(overlay)
        align(overlaySlot, ALIGN_FILL, ALIGN_FILL)
        local surfaceSlot = box:AddChild(surface)
        align(surfaceSlot, ALIGN_FILL, ALIGN_FILL)
    end)
    if not ok then return nil end
    local record = {
        box = box, widget = trigger, surface = surface, text = text,
        warning = warning == true,
    }
    state.triggerSurfaces[#state.triggerSurfaces + 1] = record
    return record
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

local function styleHeaderButton(button, role, focused, hovered, pressed)
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
        hoverForeground = role == "steamVote" and COLORS.text or roleColor
        pressForeground = role == "steamVote" and COLORS.text or roleColor
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

local function makeIconTrigger(tree, glyph, tooltip, role)
    local box = construct(tree, "/Script/UMG.SizeBox")
    local overlay = construct(tree, "/Script/UMG.Overlay")
    local button = construct(tree, "/Script/UMG.Button")
    local iconBox = construct(tree, "/Script/UMG.SizeBox")
    local trigger = construct(tree, "/Script/UMG.CheckBox")
    local size = role == "close" and 27 or role == "reset" and 17 or 18
    local translation = role == "close" and { X = 1.0, Y = -6.0 }
        or role == "reset" and { X = 1.0, Y = 1.0 }
        or { X = 0.0, Y = -1.0 }
    local icon = makeText(tree, glyph, size, COLORS.text, TEXT_CENTER)
    if box == nil or overlay == nil or button == nil or iconBox == nil
        or trigger == nil or icon == nil then return nil end
    local ok = pcall(function()
        box:SetWidthOverride(SIZE.headerAction)
        box:SetHeightOverride(SIZE.headerAction)
        button.bIsFocusable = false
        button:SetVisibility(VIS_HIT_TEST_INVISIBLE)
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
        align(overlay:AddChildToOverlay(button), ALIGN_FILL, ALIGN_FILL)
        styleTrigger(trigger, false)
        trigger.bIsFocusable = true
        trigger:SetToolTipText(FText(tooltip or ""))
        align(overlay:AddChildToOverlay(trigger), ALIGN_FILL, ALIGN_FILL)
        align(box:AddChild(overlay), ALIGN_FILL, ALIGN_FILL)
    end)
    if not ok then return nil end
    local record = {
        box = box, widget = trigger, surface = button, text = icon,
        visualButton = button, role = role, tooltip = tooltip or "",
    }
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

local function makeSteamVoteContent(tree, thumbAsset, palAngle, thumbColor)
    local row = construct(tree, "/Script/UMG.HorizontalBox")
    if row == nil then return nil end
    if palAngle ~= nil then
        local avatarBox = construct(tree, "/Script/UMG.SizeBox")
        local avatar = construct(tree, "/Script/UMG.Image")
        local texture = steamVotePalTexture()
        if avatarBox ~= nil and avatar ~= nil then
            avatarBox:SetWidthOverride(26.0)
            avatarBox:SetHeightOverride(26.0)
            avatar:SetRenderTransformPivot({ X = 0.5, Y = 0.5 })
            avatar:SetRenderTransformAngle(palAngle)
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
                box = avatarBox, image = avatar, angle = palAngle,
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
    if thumbColor ~= nil then thumb:SetColorAndOpacity(thumbColor) end
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
                record.image:SetRenderTransformAngle(record.angle or 0.0)
                record.box:SetVisibility(VIS_VISIBLE)
            end)
            ready = true
        end
    end
    state.steamVotePalVisualReady = ready
    return ready
end

local function makeSteamVoteAction(tree, content, tooltip)
    local overlay = construct(tree, "/Script/UMG.Overlay")
    local button = construct(tree, "/Script/UMG.Button")
    local trigger = construct(tree, "/Script/UMG.CheckBox")
    if overlay == nil or button == nil or trigger == nil or content == nil then
        return nil
    end
    local ok = pcall(function()
        button.bIsFocusable = false
        button:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        local style = button.WidgetStyle
        local padding = { Left = 4, Top = 3, Right = 4, Bottom = 3 }
        style.NormalPadding = padding
        style.PressedPadding = padding
        button.WidgetStyle = style
        styleHeaderButton(button, "steamVote", false, false, false)
        align(button:AddChild(content), ALIGN_CENTER, ALIGN_CENTER)
        align(overlay:AddChildToOverlay(button), ALIGN_FILL, ALIGN_FILL)
        styleTrigger(trigger, false)
        trigger.bIsFocusable = true
        trigger:SetToolTipText(FText(tooltip or ""))
        align(overlay:AddChildToOverlay(trigger), ALIGN_FILL, ALIGN_FILL)
    end)
    if not ok then return nil end
    local record = {
        widget = trigger, surface = overlay, visualButton = button,
        role = "steamVote", tooltip = tooltip or "",
    }
    state.steamVoteActionVisuals[#state.steamVoteActionVisuals + 1] = record
    return record
end

local function setSteamVoteLocked(locked)
    pcall(function()
        if P.isValid(state.steamVoteNoneWidget) then
            state.steamVoteNoneWidget:SetIsEnabled(locked ~= true)
        end
        if P.isValid(state.steamVoteDownWidget) then
            state.steamVoteDownWidget:SetIsEnabled(locked ~= true)
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
    elseif status ~= statuses.down and status ~= statuses.up then
        status = statuses.noVote
    end
    if not force and state.steamVoteDisplayStatus == status then return false end
    state.steamVoteDisplayStatus = status
    pcall(function()
        state.steamVoteNoneSurface:SetVisibility(
            status == statuses.noVote and VIS_VISIBLE or VIS_COLLAPSED)
        state.steamVoteDownSurface:SetVisibility(
            status == statuses.down and VIS_VISIBLE or VIS_COLLAPSED)
        state.steamVoteUpSurface:SetVisibility(
            status == statuses.up and VIS_VISIBLE or VIS_COLLAPSED)
    end)
    control.widget = status == statuses.noVote and state.steamVoteNoneWidget
        or status == statuses.down and state.steamVoteDownWidget
        or state.steamVoteUpSurface
    local strings = currentStrings()
    control.tooltip = status == statuses.down and strings.voteReconsider
        or status == statuses.up and strings.voteThanks or strings.voteLike
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
    return applySteamVoteVisual(status, false)
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
    if not SteamVote.initialize() then return nil end
    local box = construct(tree, "/Script/UMG.SizeBox")
    local overlay = construct(tree, "/Script/UMG.Overlay")
    local none = makeSteamVoteAction(tree,
        makeSteamVoteContent(tree, "thumb-up-outline.png", nil), strings.voteLike)
    local down = makeSteamVoteAction(tree,
        makeSteamVoteContent(tree, "thumb-down-filled.png", 180.0,
            COLORS.voteBlack), strings.voteReconsider)
    local upSurface = construct(tree, "/Script/UMG.Border")
    local upContent = makeSteamVoteContent(tree, "thumb-up-filled.png", 0.0,
        COLORS.voteGold)
    if box == nil or overlay == nil or none == nil or down == nil
        or upSurface == nil or upContent == nil then return nil end
    upSurface:SetBrushColor(COLORS.control)
    upSurface:SetPadding({ Left = 4, Top = 3, Right = 4, Bottom = 3 })
    upSurface:SetToolTipText(FText(strings.voteThanks or ""))
    align(upSurface:AddChild(upContent), ALIGN_CENTER, ALIGN_CENTER)
    align(overlay:AddChildToOverlay(none.surface), ALIGN_FILL, ALIGN_FILL)
    align(overlay:AddChildToOverlay(down.surface), ALIGN_FILL, ALIGN_FILL)
    align(overlay:AddChildToOverlay(upSurface), ALIGN_FILL, ALIGN_FILL)
    box:SetWidthOverride(64.0)
    box:SetHeightOverride(SIZE.button)
    align(box:AddChild(overlay), ALIGN_FILL, ALIGN_FILL)
    state.steamVoteNoneWidget = none.widget
    state.steamVoteDownWidget = down.widget
    state.steamVoteNoneSurface = none.surface
    state.steamVoteDownSurface = down.surface
    state.steamVoteUpSurface = upSurface
    state.steamVoteControl = { kind = "steamVote", widget = none.widget,
        tooltip = strings.voteLike or "" }
    none.control = state.steamVoteControl
    down.control = state.steamVoteControl
    applySteamVoteVisual(SteamVote.status(), true)
    return box
end

local function makeRow(tree, body, label, role)
    local rowBox = construct(tree, "/Script/UMG.SizeBox")
    local rowSurface = construct(tree, "/Script/UMG.Border")
    local frame = construct(tree, "/Script/UMG.Border")
    local row = construct(tree, "/Script/UMG.HorizontalBox")
    local labelWidget = makeText(tree, label, 15, COLORS.text, TEXT_LEFT)
    if rowBox == nil or rowSurface == nil or frame == nil
        or row == nil or labelWidget == nil then return nil end
    setTextWrap(labelWidget, role)
    local ok = pcall(function()
        rowBox:SetMinDesiredHeight(SIZE.row)
        rowSurface:SetBrushColor(COLORS.transparent)
        rowSurface:SetPadding({ Left = 0, Top = 0, Right = 0, Bottom = 0 })
        frame:SetBrushColor(COLORS.transparent)
        frame:SetPadding({ Left = 12, Top = 4, Right = 12, Bottom = 4 })
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

local function refreshTriggerSurfaces()
    for _, record in ipairs(state.triggerSurfaces or {}) do
        if P.isValid(record.widget) and P.isValid(record.surface) then
            local focused = false
            local hovered = false
            pcall(function() focused = record.widget:HasKeyboardFocus() == true end)
            pcall(function() hovered = record.widget:IsHovered() == true end)
            if type(record.control) == "table"
                and record.control.focusIndex == state.focusIndex
                and state.lastInputDevice ~= "mouse" then focused = true end
            local signature = focused and "focus"
                or record.selected == true and "selected"
                or hovered and "hover" or "normal"
            if signature ~= record.visualSignature then
                record.visualSignature = signature
                local color = focused and COLORS.controlFocus
                or record.selected == true and COLORS.controlSelected
                or hovered and COLORS.controlHover or COLORS.control
                pcall(function() record.surface:SetBrushColor(color) end)
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
                if active and record == state.aboutRosterCloseAction
                    and state.aboutRosterOpen == true
                    and state.lastInputDevice ~= "mouse" then focused = true end
                local hovered = false
                local pressed = false
                if active then
                    pcall(function() hovered = record.widget:IsHovered() == true end)
                    pcall(function() pressed = record.widget:IsChecked() == true end)
                end
                local signature = pressed and "pressed"
                    or focused and "focus" or hovered and "hover" or "normal"
                if signature ~= record.visualSignature then
                    record.visualSignature = signature
                    styleHeaderButton(record.visualButton, record.role,
                        focused, hovered, pressed)
                end
            end
        end
    end
    for index, record in ipairs(state.aboutActions or {}) do
        if P.isValid(record.widget) and P.isValid(record.visualButton) then
            local focused = state.aboutOpen == true
                and state.aboutRosterOpen ~= true
                and index == state.aboutFocusIndex
                and state.lastInputDevice ~= "mouse"
            local hovered = false
            local pressed = false
            if state.aboutOpen == true and state.aboutRosterOpen ~= true then
                pcall(function() hovered = record.widget:IsHovered() == true end)
                pcall(function() pressed = record.widget:IsChecked() == true end)
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
    if P.isValid(state.aboutActionHint) then
        local hint = ""
        if state.aboutOpen == true and state.aboutRosterOpen ~= true
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
        for _, control in ipairs(state.controls or {}) do
            if control.kind == "steamVote" or control.kind == "about"
                or control.kind == "reset" or control.kind == "close" then
                local hovered = false
                if P.isValid(control.widget) then
                    pcall(function() hovered = control.widget:IsHovered() == true end)
                end
                if hovered or (control.focusIndex == state.focusIndex
                        and state.lastInputDevice ~= "mouse") then
                    hint = tostring(control.tooltip or "")
                    break
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
    if P.isValid(control.widget) and not focused then
        local ok, value = pcall(function()
            return control.widget:HasKeyboardFocus()
        end)
        focused = ok and value == true
    end
    if P.isValid(control.widget) then
        pcall(function() hovered = control.widget:IsHovered() == true end)
    end
    if control.focusIndex == state.focusIndex
        and state.lastInputDevice ~= "mouse" then focused = true end
    local signature = focused and "focus" or hovered and "hover" or "normal"
    if P.isValid(control.widget) and signature ~= control.visualSignature then
        control.visualSignature = signature
        styleShortcutSelector(control.widget, focused)
        if P.isValid(control.surface) then
            pcall(function()
                control.surface:SetBrushColor(focused and COLORS.controlFocus
                    or hovered and COLORS.controlHover or COLORS.control)
            end)
        end
    end
end

local function refreshToggleDisplay(control)
    if type(control) ~= "table" or not P.isValid(control.widget) then return end
    local focused = false
    pcall(function() focused = control.widget:HasKeyboardFocus() == true end)
    if control.focusIndex == state.focusIndex
        and state.lastInputDevice ~= "mouse" then focused = true end
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
    local hovered = false
    if P.isValid(control.widget) then
        pcall(function() focused = control.widget:HasKeyboardFocus() == true end)
        pcall(function() hovered = control.widget:IsHovered() == true end)
    end
    if focused and control.focusIndex ~= nil then
        state.focusIndex = control.focusIndex
    elseif control.focusIndex == state.focusIndex
        and state.lastInputDevice ~= "mouse" then
        focused = true
    end
    local signature = focused and "focus" or hovered and "hover" or "normal"
    if signature == control.rowVisualSignature then return end
    control.rowVisualSignature = signature
    local color = focused and COLORS.rowFocus
        or hovered and COLORS.rowHover or COLORS.transparent
    pcall(function() control.rowFrame:SetBrushColor(color) end)
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
    if type(candidate.IncludeExcludedItems) ~= "boolean"
        or type(candidate.IncludeNewItems) ~= "boolean" then
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
        sectionBasics = "Basics",
        sectionStorage = "Storage rules",
        sectionSpecial = "Special items",
        shortcut = "Quick Stack shortcut",
        resultDisplay = "Result display",
        resultDefault = "Automatic",
        resultText = "Text only",
        resultWindow = "Result window",
        includeExcluded = "Store ignored items",
        includeNew = "Store items not already in storage",
        eggRouting = "Pal Egg routing",
        eggOnly = "Incubators only",
        eggStorage = "Incubators, then storage",
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
        navigate = "Navigate",
        adjust = "Adjust",
        confirm = "Confirm",
        toggleSettings = "Settings",
        externalShortcutConflict = "Possible UE4SS shortcut conflict: %s. Another UE4SS mod may use the same shortcut; both actions may run. Rebind one.",
        voteLike = "Like Quick Stack",
        voteReconsider = "Changed your mind? Click to like",
        voteThanks = "Thank you for your support!",
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

local function applyFromControls(source)
    local candidate = copyConfig(state.config)
    for _, control in ipairs(state.controls) do
        if control.kind == "toggle" and P.isValid(control.widget) then
            local ok, value = pcall(function() return control.widget:IsChecked() end)
            if ok and type(value) == "boolean" then candidate[control.key] = value end
        elseif control.kind == "choice" then
            candidate[control.key] = control.values[control.index]
        elseif control.kind == "number" then
            candidate[control.key] = control.value
        elseif control.kind == "shortcut" then
            local chord = selectedChord(control.widget)
            if chord ~= nil then
                candidate.Key = chord.Key
                candidate.Shift = chord.Shift
                candidate.Ctrl = chord.Ctrl
                candidate.Alt = chord.Alt
            end
        end
    end
    local applied, applyError = SettingsUI.apply(candidate, source)
    local strings = currentStrings()
    if applied then
        setStatus(strings.saved, false)
        refreshShortcutConflictWarning()
        FooterGuide.refreshFooterHelp(false)
        return true
    end
    setStatus(string.format(strings.saveFailed, tostring(applyError)), true)
    return false
end

refreshShortcutConflictWarning = function()
    local warning = state.shortcutWarningText
    local control = state.shortcutControl
    if not P.isValid(warning) or type(control) ~= "table" then return false end
    local chord = selectedChord(control.widget) or {
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
            pcall(function()
                control.widget:SetIsChecked(state.config[control.key] == true)
            end)
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
        elseif control.kind == "number" then
            control.value = tonumber(state.config[control.key]) or control.minimum
            if P.isValid(control.text) then
                pcall(function()
                    control.text:SetText(FText(tostring(control.value)))
                end)
            end
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

local function triggerPressed(widget)
    if not P.isValid(widget) then return false end
    local ok, checked = pcall(function() return widget:IsChecked() end)
    if not ok or checked ~= true then return false end
    pcall(function() widget:SetIsChecked(false) end)
    return true
end

local function inputKeyDown(controller, keyName)
    if not P.isValid(controller) or type(FName) ~= "function" then return nil end
    local ok, down = pcall(function()
        return controller:IsInputKeyDown({ KeyName = FName(keyName) })
    end)
    return ok and type(down) == "boolean" and down or nil
end

local closeChoiceModal
local openChoiceModal
local buildChoiceModal
local ensureChoiceModal
local openAboutModal
local closeAboutModal
local buildAboutModal
local ensureAboutModal
local moveAboutFocus
local activateAboutAction
local openAboutRoster
local closeAboutRoster
local logicalViewportSize
local commitNumberEditor
local focusedNumberControl
local handleNumberPreview

local function focusNavigationRoot()
    if not P.isValid(state.widget) then return false end
    local focused = pcall(function()
        if P.isValid(state.controller) then state.widget:SetUserFocus(state.controller) end
        state.widget:SetKeyboardFocus()
    end)
    return focused == true
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
    if scrollIntoView ~= false and P.isValid(state.scroll)
        and P.isValid(control.scrollTarget) then
        pcall(function()
            state.scroll:ScrollWidgetIntoView(control.scrollTarget, false, 0, 12.0)
        end)
    end
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
        end
        for index, candidate in ipairs(state.modalOptions or {}) do
            candidate.selected = index == state.modalIndex
        end
        refreshTriggerSurfaces()
        return true
    end
    return focusEntry((tonumber(state.focusIndex) or 1) + direction,
        device or "keyboard", true)
end

local function commitChoice(control, index, source)
    if type(control) ~= "table" or control.kind ~= "choice"
        or control.labels[index] == nil then return false end
    local previous = control.index
    control.index = index
    if not applyFromControls(source or ("choice:" .. control.key)) then
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
    if value == control.last then
        value = not control.last
        pcall(function() control.widget:SetIsChecked(value) end)
    end
    local previous = control.last
    control.last = value
    if not applyFromControls(source or ("toggle:" .. control.key)) then
        control.last = previous
        pcall(function() control.widget:SetIsChecked(previous) end)
        return false
    end
    return true
end

local function commitNumber(control, value, source)
    if type(control) ~= "table" or control.kind ~= "number" then return false end
    value = tonumber(value)
    if value == nil or math.floor(value) ~= value
        or value < control.minimum or value > control.maximum then return false end
    local previous = control.value
    control.value = value
    if value ~= previous and not applyFromControls(source or ("number:" .. control.key)) then
        control.value = previous
        value = previous
    end
    if P.isValid(control.text) then
        pcall(function() control.text:SetText(FText(tostring(control.value))) end)
    end
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
        setStatus(currentStrings().saved, false)
        return true
    end
    setStatus(string.format(currentStrings().saveFailed,
        tostring(applyError)), true)
    return false
end

local function activateFocused(source)
    if state.activeChoice ~= nil then
        local control = state.activeChoice
        local index = tonumber(state.modalIndex) or control.index or 1
        commitChoice(control, index, "choice:" .. tostring(control.key))
        closeChoiceModal(true)
        return true
    end
    local control = (state.focusEntries or {})[tonumber(state.focusIndex) or 1]
    if type(control) ~= "table" then return false end
    local edit = state.numberEdit
    if type(edit) == "table" and edit.control ~= control
        and type(edit.control) == "table" then
        commitNumberEditor(edit.control, "number-navigation", true)
    end
    if control.kind == "choice" then
        return openChoiceModal(control)
    elseif control.kind == "toggle" then
        return commitToggle(control, source)
    elseif control.kind == "number" then
        local edit = state.numberEdit
        if type(edit) == "table" and edit.control == control then
            return commitNumberEditor(control, "number-commit", true)
        end
        if type(edit) == "table" and type(edit.control) == "table" then
            commitNumberEditor(edit.control, "number-navigation", true)
        end
        state.numberEdit = {
            control = control,
            buffer = tostring(control.value),
            replaceOnType = true,
        }
        if type(control.trigger) == "table" then control.trigger.selected = true end
        focusNavigationRoot()
        refreshTriggerSurfaces()
        return true
    elseif control.kind == "shortcut" then
        control.selecting = true
        pcall(function()
            if P.isValid(state.controller) then control.widget:SetUserFocus(state.controller) end
            control.widget:SetKeyboardFocus()
        end)
        return true
    elseif control.kind == "steamVote" then
        return activateSteamVote()
    elseif control.kind == "about" then
        if P.isValid(control.widget) then
            pcall(function() control.widget:SetIsChecked(false) end)
        end
        return openAboutModal()
    elseif control.kind == "reset" then
        if P.isValid(control.widget) then
            pcall(function() control.widget:SetIsChecked(false) end)
        end
        return resetFromDefaults()
    elseif control.kind == "close" then
        if P.isValid(control.widget) then
            pcall(function() control.widget:SetIsChecked(false) end)
        end
        return SettingsUI.close(source or "activate")
    end
    return false
end

local function selectorCapturing()
    for _, control in ipairs(state.controls or {}) do
        if control.kind == "shortcut" and P.isValid(control.widget) then
            local ok, selecting = pcall(function()
                return control.widget:GetIsSelectingKey()
            end)
            if ok and selecting == true then return true end
        end
    end
    return false
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

local function claimSynchronousNavigation(keyName, source)
    if type(keyName) ~= "string" then return false end
    local now = os.clock()
    local ownedUntil = tonumber(state.synchronousNavigationUntil[keyName]) or 0.0
    if source == "global" then return ownedUntil > now end
    if source ~= "preview" and source ~= "actor" then return false end
    if ownedUntil > now then return true end
    state.synchronousNavigationUntil[keyName] = now + 0.30
    InputOwner.discardPendingKey(keyName)
    return false
end

local function handlePressed(keyName, device, source)
    if not state.open then return false end
    device = device or (tostring(keyName):find("^Gamepad_") and "gamepad" or "keyboard")
    FooterGuide.markInputDevice(device)
    if selectorCapturing() then return true end
    if state.aboutOpen == true then
        if state.aboutRosterOpen == true then
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
            return moveAboutFocus(0, -1)
        elseif keyName == "S" or keyName == "Down"
            or keyName == "Gamepad_DPad_Down"
            or keyName == "Gamepad_LeftStick_Down" then
            return moveAboutFocus(0, 1)
        elseif keyName == "A" or keyName == "Left"
            or keyName == "Gamepad_DPad_Left"
            or keyName == "Gamepad_LeftStick_Left" then
            return moveAboutFocus(-1, 0)
        elseif keyName == "D" or keyName == "Right"
            or keyName == "Gamepad_DPad_Right"
            or keyName == "Gamepad_LeftStick_Right" then
            return moveAboutFocus(1, 0)
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
        if keyName == "Escape" then return closeChoiceModal(true) end
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
            return moveFocus(-1, device)
        end
        if keyName == "S" or keyName == "Down"
            or keyName == "Gamepad_DPad_Down"
            or keyName == "Gamepad_LeftStick_Down" then
            return moveFocus(1, device)
        end
        if keyName == "Enter" or keyName == "SpaceBar" then
            return activateFocused(device .. "-accept")
        end
        return true
    end
    if keyName == "Escape" then
        state.trailingReleaseUntil.Escape = os.clock() + 0.50
        return SettingsUI.close("escape")
    end
    if keyName == "W" or keyName == "Up" or keyName == "Tab"
        or keyName == "Gamepad_DPad_Up"
        or keyName == "Gamepad_LeftStick_Up" then
        return moveFocus(keyName == "Tab" and 1 or -1, device)
    elseif keyName == "S" or keyName == "Down"
        or keyName == "Gamepad_DPad_Down"
        or keyName == "Gamepad_LeftStick_Down" then
        return moveFocus(1, device)
    elseif keyName == "A" or keyName == "Left"
        or keyName == "Gamepad_DPad_Left"
        or keyName == "Gamepad_LeftStick_Left" then
        local control = (state.focusEntries or {})[state.focusIndex]
        if type(control) == "table" and control.kind == "number" then
            return commitNumber(control, control.value - 1, "number-left")
        end
        return true
    elseif keyName == "D" or keyName == "Right"
        or keyName == "Gamepad_DPad_Right"
        or keyName == "Gamepad_LeftStick_Right" then
        local control = (state.focusEntries or {})[state.focusIndex]
        if type(control) == "table" and control.kind == "number" then
            return commitNumber(control, control.value + 1, "number-right")
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
    if type(keyName) == "string" then
        state.synchronousNavigationUntil[keyName] = nil
    end
    if state.aboutOpen == true then
        if keyName == "Gamepad_FaceButton_Bottom" then
            local armed = state.gamepadAcceptDown == true
            state.gamepadAcceptDown = false
            if armed and state.aboutRosterOpen == true then
                return closeAboutRoster(true)
            end
            if armed then return activateAboutAction() end
        elseif keyName == "Gamepad_FaceButton_Right" then
            local armed = state.gamepadBackDown == true
            state.gamepadBackDown = false
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
            if state.activeChoice ~= nil then return closeChoiceModal(true) end
            if selectorCapturing() then return true end
            state.trailingReleaseUntil[keyName] = os.clock() + 0.50
            return SettingsUI.close("gamepad-back")
        end
    end
    return true
end

local function handleAxis(axis, value)
    if not state.open then return false end
    value = tonumber(value)
    if type(value) ~= "number" or (axis ~= "x" and axis ~= "y") then return false end
    if type(state.axisArmed) ~= "table" then
        state.axisArmed = { x = true, y = true }
    end
    local magnitude = math.abs(value)
    local armed = state.axisArmed[axis] ~= false
    if magnitude <= 0.30 then
        state.axisArmed[axis] = true
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
        and P.isValid(control.widget) and control or nil
end

commitNumberEditor = function(control, source, commit)
    if type(control) ~= "table" or control.kind ~= "number" then return false end
    local edit = state.numberEdit
    if type(edit) ~= "table" or edit.control ~= control then return false end
    state.numberEdit = nil
    if type(control.trigger) == "table" then control.trigger.selected = false end
    local applied = true
    if commit ~= false then
        local parsed = tonumber(edit.buffer)
        if parsed ~= nil and math.floor(parsed) == parsed then
            parsed = math.max(control.minimum, math.min(control.maximum, parsed))
            applied = commitNumber(control, parsed, source)
        else
            applied = false
        end
    end
    if P.isValid(control.text) then
        pcall(function()
            control.text:SetText(FText(tostring(control.value)))
        end)
    end
    focusNavigationRoot()
    refreshTriggerSurfaces()
    return applied
end

local function adjustNumberEditor(control, direction)
    local edit = state.numberEdit
    local parsed = type(edit) == "table" and edit.control == control
        and tonumber(edit.buffer) or nil
    local base = parsed ~= nil and math.floor(parsed) == parsed
        and parsed >= control.minimum and parsed <= control.maximum
        and parsed or control.value
    local target = math.max(control.minimum,
        math.min(control.maximum, base + direction))
    local committed = commitNumber(control, target,
        direction < 0 and "number-left" or "number-right")
    if committed and type(edit) == "table" and edit.control == control then
        edit.buffer = tostring(target)
        edit.replaceOnType = true
    end
    return committed
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

handleNumberPreview = function(control, keyName, keyEvent, source)
    source = source or "preview"
    local controlDown = previewModifierDown(keyEvent, "control")
    local shiftDown = previewModifierDown(keyEvent, "shift")
    local edit = state.numberEdit
    if type(edit) ~= "table" or edit.control ~= control then return false end
    if claimSynchronousNavigation(keyName, source) then return true end
    local digit = NUMBER_KEY_DIGITS[keyName]
    if digit ~= nil then
        if not controlDown and not shiftDown then
            local raw = edit.replaceOnType == true and digit
                or tostring(edit.buffer or "") .. digit
            local maxDigits = math.max(#tostring(math.abs(control.minimum or 0)),
                #tostring(math.abs(control.maximum or 0)))
            if #raw <= maxDigits then
                edit.buffer = raw
                edit.replaceOnType = false
                if P.isValid(control.text) then
                    pcall(function() control.text:SetText(FText(raw)) end)
                end
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
            if P.isValid(control.text) then
                pcall(function() control.text:SetText(FText(raw)) end)
            end
        end
        return true
    end
    if controlDown or shiftDown then return true end
    if not controlDown and not shiftDown
        and (keyName == "A" or keyName == "Left"
            or keyName == "Gamepad_DPad_Left"
            or keyName == "Gamepad_LeftStick_Left") then
        adjustNumberEditor(control, -1)
        return true
    end
    if not controlDown and not shiftDown
        and (keyName == "D" or keyName == "Right"
            or keyName == "Gamepad_DPad_Right"
            or keyName == "Gamepad_LeftStick_Right") then
        adjustNumberEditor(control, 1)
        return true
    end
    if keyName == "Enter" or keyName == "SpaceBar"
        or keyName == "Gamepad_FaceButton_Bottom" then
        commitNumberEditor(control, "number-commit", true)
        return true
    end
    if keyName == "W" or keyName == "Up" or keyName == "Tab"
        or keyName == "S" or keyName == "Down"
        or keyName == "Gamepad_DPad_Up"
        or keyName == "Gamepad_DPad_Down"
        or keyName == "Gamepad_LeftStick_Up"
        or keyName == "Gamepad_LeftStick_Down" then
        commitNumberEditor(control, "number-navigation", true)
        local direction = (keyName == "W" or keyName == "Up"
            or keyName == "Gamepad_DPad_Up"
            or keyName == "Gamepad_LeftStick_Up") and -1 or 1
        return moveFocus(direction,
            keyName:find("Gamepad_", 1, true) == 1 and "gamepad" or "keyboard")
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
        if numberControl ~= nil then
            handled = handleNumberPreview(numberControl, keyName, keyEvent, "preview")
        else
            handled = handlePressed(keyName,
                gamepad and "gamepad" or "keyboard", "preview")
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
        handleReleased(keyName)
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
    pollSteamVote()
    if state.steamVotePalVisualReady ~= true then
        refreshSteamVotePalVisuals()
    end
    if state.aboutOpen == true then
        if state.aboutRosterOpen == true then
            if triggerPressed(state.aboutRosterCloseWidget) then
                FooterGuide.markInputDevice("mouse")
                closeAboutRoster(true)
            end
            refreshTriggerSurfaces()
            return
        end
        for index, action in ipairs(state.aboutActions or {}) do
            if triggerPressed(action.widget) then
                FooterGuide.markInputDevice("mouse")
                state.aboutFocusIndex = index
                state.aboutPreferredColumn = tonumber(action.navColumn) or 1
                activateAboutAction()
                if state.aboutOpen ~= true then return end
                break
            end
        end
        refreshTriggerSurfaces()
        return
    end
    if state.activeChoice ~= nil then
        local control = state.activeChoice
        for index, option in ipairs(state.modalOptions or {}) do
            if triggerPressed(option.widget) and control.labels[index] ~= nil then
                FooterGuide.markInputDevice("mouse")
                state.modalIndex = index
                commitChoice(control, index, "choice:" .. control.key)
                closeChoiceModal(true)
                refreshTriggerSurfaces()
                return
            end
        end
        refreshTriggerSurfaces()
        return
    end
    for _, control in ipairs(state.controls) do
        if control.kind == "toggle" and P.isValid(control.widget) then
            local ok, value = pcall(function() return control.widget:IsChecked() end)
            if ok and type(value) == "boolean" and value ~= control.last then
                state.focusIndex = control.focusIndex or state.focusIndex
                FooterGuide.markInputDevice("mouse")
                local edit = state.numberEdit
                if type(edit) == "table" and type(edit.control) == "table" then
                    commitNumberEditor(edit.control, "number-navigation", true)
                end
                local previous = control.last
                control.last = value
                if not applyFromControls("toggle:" .. control.key) then
                    control.last = previous
                    pcall(function() control.widget:SetIsChecked(previous) end)
                end
                focusNavigationRoot()
            end
        elseif control.kind == "choice" and triggerPressed(control.widget) then
            state.focusIndex = control.focusIndex or state.focusIndex
            FooterGuide.markInputDevice("mouse")
            local edit = state.numberEdit
            if type(edit) == "table" and type(edit.control) == "table" then
                commitNumberEditor(edit.control, "number-navigation", true)
            end
            openChoiceModal(control)
        elseif control.kind == "number" then
            if triggerPressed(control.widget) then
                state.focusIndex = control.focusIndex or state.focusIndex
                FooterGuide.markInputDevice("mouse")
                activateFocused("mouse")
            end
        elseif control.kind == "shortcut" then
            local chord = selectedChord(control.widget)
            local signature = chordSignature(chord)
            if chord ~= nil and signature ~= control.last then
                local previous = control.last
                control.last = signature
                if not applyFromControls("shortcut") then
                    control.last = previous
                    setSelectorChord(control.widget, {
                        Key = state.config.Key,
                        Shift = state.config.Shift,
                        Ctrl = state.config.Ctrl,
                        Alt = state.config.Alt,
                    })
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
            control.selecting = selecting
            if selecting and type(state.numberEdit) == "table"
                and type(state.numberEdit.control) == "table" then
                commitNumberEditor(
                    state.numberEdit.control, "number-navigation", true)
            end
            if wasSelecting and not selecting then
                focusEntry(control.focusIndex or state.focusIndex,
                    "keyboard", true)
            end
            refreshShortcutDisplay(control, selecting)
        elseif control.kind == "steamVote" then
            if triggerPressed(state.steamVoteNoneWidget)
                or triggerPressed(state.steamVoteDownWidget) then
                state.focusIndex = control.focusIndex or state.focusIndex
                FooterGuide.markInputDevice("mouse")
                activateSteamVote()
            end
        elseif control.kind == "about" and triggerPressed(control.widget) then
            state.focusIndex = control.focusIndex or state.focusIndex
            FooterGuide.markInputDevice("mouse")
            openAboutModal()
            return
        elseif control.kind == "reset" and triggerPressed(control.widget) then
            FooterGuide.markInputDevice("mouse")
            resetFromDefaults()
        elseif control.kind == "close" and triggerPressed(control.widget) then
            FooterGuide.markInputDevice("mouse")
            SettingsUI.close("button")
            return
        end
    end
    for _, control in ipairs(state.controls) do
        if control.kind == "toggle" then refreshToggleDisplay(control) end
        refreshRowDisplay(control)
    end
    refreshTriggerSurfaces()
end

local CONTROLLER_KEYS = {
    "Gamepad_DPad_Up", "Gamepad_DPad_Down",
    "Gamepad_DPad_Left", "Gamepad_DPad_Right",
    "Gamepad_LeftStick_Up", "Gamepad_LeftStick_Down",
    "Gamepad_LeftStick_Left", "Gamepad_LeftStick_Right",
    "Gamepad_FaceButton_Bottom", "Gamepad_FaceButton_Right",
}

local function pollStandaloneController()
    if InputOwner.cookedInputActive() then return end
    for _, keyName in ipairs(CONTROLLER_KEYS) do
        local down = inputKeyDown(state.controller, keyName) == true
        local previous = state.controllerDown[keyName] == true
        if down and not previous then handlePressed(keyName, "gamepad") end
        if previous and not down then handleReleased(keyName) end
        state.controllerDown[keyName] = down
    end
    if P.isValid(state.controller) and type(FName) == "function" then
        local x, y
        pcall(function()
            x = state.controller:GetInputAnalogKeyState({ KeyName = FName("Gamepad_LeftX") })
            y = state.controller:GetInputAnalogKeyState({ KeyName = FName("Gamepad_LeftY") })
        end)
        if tonumber(x) ~= nil then handleAxis("x", x) end
        if tonumber(y) ~= nil then handleAxis("y", y) end
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

local schedulePoll
local stopPoll
state.pollGameThreadCallback = function()
    if not state.open or state.generation ~= state.pollGeneration then
        stopPoll()
        return
    end
    safePollPhase("input", InputOwner.drainPendingInput)
    safePollPhase("controls", pollControls)
    safePollPhase("controller", pollStandaloneController)
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

local function addToggleRow(tree, body, key, label, alternate)
    local row = makeRow(tree, body, label, "toggle")
    local toggle = construct(tree, "/Script/UMG.CheckBox")
    local box = construct(tree, "/Script/UMG.SizeBox")
    if row == nil or toggle == nil or box == nil then return false end
    pcall(function()
        toggle.bIsFocusable = false
        styleToggle(toggle)
        toggle:SetIsChecked(state.config[key] == true)
        box:SetWidthOverride(SIZE.checkbox)
        box:SetHeightOverride(SIZE.control)
        local toggleSlot = box:AddChild(toggle)
        align(toggleSlot, ALIGN_FILL, ALIGN_FILL)
    end)
    addControlToRow(row.row, box, 12)
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

local function addChoiceRow(tree, body, key, label, values, labels, alternate)
    local row = makeRow(tree, body, label, "choice")
    if row == nil then return false end
    local index = 1
    for candidate, value in ipairs(values) do
        if value == state.config[key] then index = candidate end
    end
    local trigger = makeTrigger(tree, labels[index], SIZE.choice, false, "▼")
    if trigger == nil then return false end
    addControlToRow(row.row, trigger.box, 12)
    local control = {
        kind = "choice", key = key, widget = trigger.widget,
        text = trigger.text, values = values, labels = labels, index = index,
        label = label, rowFrame = row.surface,
    }
    registerFocusable(control, row.box, trigger)
    state.controls[#state.controls + 1] = control
    return true
end

local function addNumberRow(tree, body, key, label, minimum, maximum, alternate)
    local row = makeRow(tree, body, label, "number")
    if row == nil then return false end
    -- Keep Slate out of desktop text-input mode. The focused settings root owns
    -- an integer-only buffer, while this trigger is presentation and pointer input.
    local trigger = makeTrigger(tree, tostring(state.config[key]),
        SIZE.number, false, nil, SIZE.control)
    if trigger == nil then return false end
    addControlToRow(row.row, trigger.box, 12)
    local control = {
        kind = "number", key = key, widget = trigger.widget,
        text = trigger.text, trigger = trigger,
        value = tonumber(state.config[key]) or minimum,
        minimum = minimum, maximum = maximum,
        rowFrame = row.surface,
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
    local surface = construct(tree, "/Script/UMG.Border")
    local valueText = makeText(tree, "", 14, COLORS.text, TEXT_CENTER)
    if box == nil or overlay == nil or surface == nil or valueText == nil then
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
        styleShortcutSelector(selector, false)
        box:SetWidthOverride(SIZE.binding)
        box:SetHeightOverride(SIZE.control)
        surface:SetBrushColor(COLORS.control)
        local surfaceSlot = overlay:AddChildToOverlay(surface)
        align(surfaceSlot, ALIGN_FILL, ALIGN_FILL)
        valueText:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        valueText:SetRenderOpacity(1.0)
        local valueSlot = overlay:AddChildToOverlay(valueText)
        align(valueSlot, ALIGN_CENTER, ALIGN_CENTER)
        local selectorSlot = overlay:AddChildToOverlay(selector)
        align(selectorSlot, ALIGN_FILL, ALIGN_FILL)
        local overlaySlot = box:AddChild(overlay)
        align(overlaySlot, ALIGN_FILL, ALIGN_FILL)
        setSelectorChord(selector, chord)
    end)
    if not ok then return false end
    addControlToRow(row.row, box, 12)
    local control = {
        kind = "shortcut", widget = selector,
        text = valueText, surface = surface, rowFrame = row.surface,
        last = chordSignature(chord), selecting = false,
    }
    registerFocusable(control, row.box)
    state.controls[#state.controls + 1] = control
    state.shortcutControl = control
    local warning = makeText(tree, "", 11, COLORS.danger, TEXT_LEFT)
    if warning == nil then return false end
    setTextWrap(warning, math.max(1.0, state.contentWidth - 24.0))
    warning:SetVisibility(VIS_COLLAPSED)
    local warningSlot = body:AddChild(warning)
    setPadding(warningSlot, 12, 2, 12, 4)
    align(warningSlot, ALIGN_FILL, ALIGN_FILL)
    state.shortcutWarningText = warning
    refreshShortcutDisplay(control, false)
    refreshShortcutConflictWarning()
    return true
end

closeChoiceModal = function(restoreFocus)
    local control = state.activeChoice
    state.activeChoice = nil
    if P.isValid(state.nestedOverlay) then
        pcall(function() state.nestedOverlay:SetVisibility(VIS_COLLAPSED) end)
    end
    for _, option in ipairs(state.modalOptions or {}) do
        option.selected = false
        if P.isValid(option.widget) then
            pcall(function() option.widget:SetIsChecked(false) end)
        end
    end
    if restoreFocus == true and type(control) == "table"
        and P.isValid(control.widget) then
        focusEntry(control.focusIndex or state.focusIndex,
            state.lastInputDevice, true)
    end
    return control ~= nil
end

openChoiceModal = function(control)
    if type(control) ~= "table" or control.kind ~= "choice"
        or not ensureChoiceModal() then return false end
    state.activeChoice = control
    state.modalIndex = tonumber(control.index) or 1
    if P.isValid(control.widget) then
        pcall(function() control.widget:SetIsChecked(false) end)
    end
    if P.isValid(state.nestedTitle) then
        pcall(function() state.nestedTitle:SetText(FText(control.label or "")) end)
    end
    local first
    for index, option in ipairs(state.modalOptions or {}) do
        local label = control.labels[index]
        local visible = label ~= nil
        pcall(function()
            option.box:SetVisibility(visible and VIS_VISIBLE or VIS_COLLAPSED)
            option.widget:SetIsChecked(false)
            if visible then option.text:SetText(FText(label)) end
        end)
        option.selected = visible and index == state.modalIndex
        if visible and index == state.modalIndex then first = option.widget end
    end
    pcall(function() state.nestedOverlay:SetVisibility(VIS_VISIBLE) end)
    if P.isValid(first) then focusNavigationRoot() end
    return true
end

buildChoiceModal = function(tree, root, viewportWidth, viewportHeight)
    local overlay = construct(tree, "/Script/UMG.CanvasPanel")
    local dim = construct(tree, "/Script/UMG.Border")
    local cardBox = construct(tree, "/Script/UMG.SizeBox")
    local panel = construct(tree, "/Script/UMG.Border")
    local scroll = construct(tree, "/Script/UMG.ScrollBox")
    local content = construct(tree, "/Script/UMG.VerticalBox")
    local title = makeText(tree, "", 18, COLORS.text, TEXT_LEFT)
    if overlay == nil or dim == nil or cardBox == nil or panel == nil
        or scroll == nil or content == nil or title == nil then return false end
    local vw = tonumber(viewportWidth) or 1280.0
    local vh = tonumber(viewportHeight) or 720.0
    local width = math.max(320.0, math.min(480.0, vw - 48.0))
    local maxHeight = math.min(560.0, math.max(320.0, vh - 48.0))
    local optionWidth = math.max(288.0, width - 32.0)
    local ok = pcall(function()
        overlay:SetVisibility(VIS_COLLAPSED)
        dim:SetBrushColor({ R = 0.0, G = 0.0, B = 0.0, A = 0.64 })
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
        panel:SetBrushColor(COLORS.window)
        panel:SetPadding({ Left = 16, Top = 16, Right = 16, Bottom = 16 })
        scroll:SetAlwaysShowScrollbar(false)
        scroll.AlwaysShowScrollbarTrack = false
        scroll:SetScrollbarThickness({ X = 9.0, Y = 9.0 })
        align(scroll:AddChild(content), ALIGN_FILL, ALIGN_LEFT)
        align(panel:AddChild(scroll), ALIGN_FILL, ALIGN_FILL)
        local panelSlot = cardBox:AddChild(panel)
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
        state.modalOptions = {}
        for index = 1, 3 do
            local option = makeTrigger(tree, "", optionWidth, false, nil, 40.0)
            if option == nil then error("choice option is unavailable") end
            local optionSlot = content:AddChild(option.box)
            setPadding(optionSlot, 0, index == 1 and 0 or 4, 0, 0)
            option.box:SetVisibility(VIS_COLLAPSED)
            state.modalOptions[index] = option
        end
    end)
    if not ok then return false end
    state.nestedOverlay = overlay
    state.nestedTitle = title
    return true
end

ensureChoiceModal = function()
    if P.isValid(state.nestedOverlay) then return true end
    if not P.isValid(state.widgetTree) or not P.isValid(state.root) then return false end
    local viewportWidth, viewportHeight = logicalViewportSize(state.controller)
    return buildChoiceModal(state.widgetTree, state.root,
        viewportWidth, viewportHeight)
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
        ["breeding-calculator-preview.png"] = true,
        ["curseforge.png"] = true,
        ["cratex.png"] = true,
        ["nexus.png"] = true,
        ["steam.png"] = true,
        ["curseforge.png"] = true,
        ["x.png"] = true,
        ["discord.png"] = true,
        ["buy-me-a-coffee.png"] = true,
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
    local overlay = construct(tree, "/Script/UMG.Overlay")
    local button = construct(tree, "/Script/UMG.Button")
    local trigger = construct(tree, "/Script/UMG.CheckBox")
    local iconBox = construct(tree, "/Script/UMG.SizeBox")
    if box == nil or overlay == nil or button == nil
        or trigger == nil or iconBox == nil then return nil end

    local label = type(spec.label) == "string" and spec.label or nil
    local vertical = label ~= nil and spec.orientation == "vertical"
    local horizontalLeft = label ~= nil and spec.orientation == "horizontal-left"
    local requestedWidth = tonumber(spec.width)
    local width = requestedWidth or (label ~= nil and 160.0 or 52.0)
    local height = tonumber(spec.height)
        or (label ~= nil and not vertical and SIZE.aboutLinkHeight or 52.0)
    local iconWidth = tonumber(spec.iconWidth)
        or (label ~= nil and not vertical and SIZE.aboutLinkIcon or 34.0)
    local iconHeight = tonumber(spec.iconHeight)
        or (label ~= nil and not vertical and SIZE.aboutLinkIcon or 34.0)
    local content
    local labelWidget
    local texture = aboutTexture(spec.asset)
    local image = P.isValid(texture) and construct(tree, "/Script/UMG.Image") or nil
    if image == nil then
        iconWidth = tonumber(spec.fallbackIconWidth) or iconWidth
        iconHeight = tonumber(spec.fallbackIconHeight) or iconHeight
    end
    local fallback = nil
    if image ~= nil then
        pcall(function() image:SetBrushFromTexture(texture, false) end)
        content = image
    else
        fallback = makeText(tree, tostring(spec.fallback or "?"),
            tonumber(spec.fallbackFontSize) or 13, COLORS.text, TEXT_CENTER)
        content = fallback
    end
    if content == nil then return nil end

    local ok = pcall(function()
        if requestedWidth ~= nil or label == nil then
            box:SetWidthOverride(width)
        end
        box:SetHeightOverride(height)
        iconBox:SetWidthOverride(iconWidth)
        iconBox:SetHeightOverride(iconHeight)
        align(iconBox:AddChild(content), image ~= nil and ALIGN_FILL or ALIGN_CENTER,
            image ~= nil and ALIGN_FILL or ALIGN_CENTER)

        local buttonContent = iconBox
        if label ~= nil then
            local contentPanel = construct(tree, vertical
                and "/Script/UMG.VerticalBox" or "/Script/UMG.HorizontalBox")
            labelWidget = makeText(tree, label, 11, COLORS.text,
                horizontalLeft and TEXT_LEFT or TEXT_CENTER)
            if contentPanel == nil or labelWidget == nil then error("labeled About content") end
            if vertical then
                align(contentPanel:AddChild(iconBox), ALIGN_CENTER, ALIGN_CENTER)
                local labelSlot = contentPanel:AddChild(labelWidget)
                setPadding(labelSlot, 0, SIZE.aboutLinkGap, 0, 0)
                align(labelSlot, ALIGN_CENTER, ALIGN_CENTER)
            else
                local iconColumn = construct(tree, "/Script/UMG.SizeBox")
                if iconColumn == nil then error("About icon column") end
                iconColumn:SetWidthOverride(iconWidth + 8.0)
                align(iconColumn:AddChild(iconBox), ALIGN_CENTER, ALIGN_CENTER)
                align(contentPanel:AddChild(iconColumn), ALIGN_CENTER, ALIGN_CENTER)
                local labelSlot = contentPanel:AddChild(labelWidget)
                setFill(labelSlot)
                setPadding(labelSlot, SIZE.aboutLinkGap * 0.5, 0,
                    SIZE.aboutLinkGap * 0.5, 0)
                align(labelSlot, ALIGN_LEFT, ALIGN_CENTER)
                labelWidget:SetAutoWrapText(true)
            end
            buttonContent = contentPanel
        end

        button.bIsFocusable = false
        button:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        local style = button.WidgetStyle
        local padding = label ~= nil and not vertical
            and { Left = 6, Top = 0, Right = 6, Bottom = 0 }
            or { Left = 0, Top = 0, Right = 0, Bottom = 0 }
        style.NormalPadding = padding
        style.PressedPadding = padding
        button.WidgetStyle = style
        styleHeaderButton(button, spec.role or "aboutLink", false, false, false)
        align(button:AddChild(buttonContent), ALIGN_CENTER, ALIGN_CENTER)
        align(overlay:AddChildToOverlay(button), ALIGN_FILL, ALIGN_FILL)
        styleTrigger(trigger, false)
        trigger.bIsFocusable = true
        trigger:SetToolTipText(FText(spec.tooltip or label or ""))
        align(overlay:AddChildToOverlay(trigger), ALIGN_FILL, ALIGN_FILL)
        align(box:AddChild(overlay), ALIGN_FILL, ALIGN_FILL)
    end)
    if not ok then return nil end
    local record = {
        box = box, widget = trigger, visualButton = button,
        labelWidget = labelWidget or fallback, label = label,
        tooltip = spec.tooltip or label,
        urlKey = spec.urlKey,
        kind = spec.kind or (spec.urlKey ~= nil and "link" or "close"),
        rosterMode = spec.rosterMode,
        role = spec.role or "aboutLink",
        navRow = spec.navRow,
        navColumn = spec.navColumn,
    }
    if spec.deferRegistration ~= true then
        state.aboutActions[#state.aboutActions + 1] = record
    end
    return record
end

local function makeAboutAction(tree, label, urlKey, width, role, height, fontSize,
        navRow, navColumn)
    local box = construct(tree, "/Script/UMG.SizeBox")
    local overlay = construct(tree, "/Script/UMG.Overlay")
    local button = construct(tree, "/Script/UMG.Button")
    local trigger = construct(tree, "/Script/UMG.CheckBox")
    local text = makeText(tree, label, fontSize or 13, COLORS.text, TEXT_CENTER)
    if box == nil or overlay == nil or button == nil or trigger == nil
        or text == nil then return nil end
    local ok = pcall(function()
        box:SetWidthOverride(width or 160.0)
        box:SetHeightOverride(height or 40.0)
        button.bIsFocusable = false
        button:SetVisibility(VIS_HIT_TEST_INVISIBLE)
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
        align(overlay:AddChildToOverlay(button), ALIGN_FILL, ALIGN_FILL)
        styleTrigger(trigger, false)
        trigger.bIsFocusable = true
        trigger:SetToolTipText(FText(label or ""))
        align(overlay:AddChildToOverlay(trigger), ALIGN_FILL, ALIGN_FILL)
        align(box:AddChild(overlay), ALIGN_FILL, ALIGN_FILL)
    end)
    if not ok then return nil end
    local record = {
        box = box, widget = trigger, visualButton = button,
        labelWidget = text, label = label, urlKey = urlKey,
        kind = urlKey ~= nil and "link" or "close",
        role = role or "about",
        navRow = navRow,
        navColumn = navColumn,
    }
    state.aboutActions[#state.aboutActions + 1] = record
    return record
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
    if action.kind == "roster" then
        return openAboutRoster(action.rosterMode)
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

closeAboutRoster = function(restoreFocus)
    local wasOpen = state.aboutRosterOpen == true
    state.aboutRosterOpen = false
    state.aboutRosterMode = nil
    if P.isValid(state.aboutRosterOverlay) then
        pcall(function() state.aboutRosterOverlay:SetVisibility(VIS_COLLAPSED) end)
    end
    if P.isValid(state.aboutRosterCloseWidget) then
        pcall(function() state.aboutRosterCloseWidget:SetIsChecked(false) end)
    end
    if restoreFocus == true then focusNavigationRoot() end
    refreshTriggerSurfaces()
    return wasOpen
end

openAboutRoster = function(mode)
    if state.aboutOpen ~= true or not P.isValid(state.aboutRosterOverlay)
        or (mode ~= "thanks" and mode ~= "supporters") then return false end
    local strings = Localization.settings()
    local thanks = mode == "thanks"
    state.aboutRosterMode = mode
    state.aboutRosterOpen = true
    pcall(function()
        state.aboutRosterTitle:SetText(FText(thanks
            and strings.aboutSpecialThanks or strings.aboutSupporters))
        state.aboutRosterDescription:SetText(FText(thanks
            and strings.aboutSpecialThanksDescription
            or strings.aboutSupportersDescription))
        state.aboutRosterEmpty:SetText(FText(thanks
            and strings.aboutSpecialThanksEmpty or strings.aboutSupportersEmpty))
        state.aboutRosterOverlay:SetVisibility(VIS_VISIBLE)
    end)
    focusNavigationRoot()
    refreshTriggerSurfaces()
    return true
end

closeAboutModal = function(restoreFocus)
    local wasOpen = state.aboutOpen == true
    closeAboutRoster(false)
    state.aboutOpen = false
    if P.isValid(state.aboutOverlay) then
        pcall(function() state.aboutOverlay:SetVisibility(VIS_COLLAPSED) end)
    end
    for _, action in ipairs(state.aboutActions or {}) do
        if P.isValid(action.widget) then
            pcall(function() action.widget:SetIsChecked(false) end)
        end
    end
    if restoreFocus == true and state.aboutReturnFocusIndex ~= nil then
        focusEntry(state.aboutReturnFocusIndex, state.lastInputDevice, false)
    end
    state.aboutReturnFocusIndex = nil
    return wasOpen
end

openAboutModal = function()
    if not ensureAboutModal() then return false end
    closeChoiceModal(false)
    local edit = state.numberEdit
    if type(edit) == "table" and type(edit.control) == "table" then
        commitNumberEditor(edit.control, "about-open", true)
    end
    state.aboutReturnFocusIndex = state.focusIndex
    state.aboutFocusIndex = 1
    state.aboutPreferredColumn = 2
    state.aboutOpen = true
    pcall(function()
        state.aboutOverlay:SetVisibility(VIS_VISIBLE)
        if P.isValid(state.aboutScroll) then state.aboutScroll:SetScrollOffset(0.0) end
    end)
    focusNavigationRoot()
    refreshTriggerSurfaces()
    return true
end

ensureAboutModal = function()
    if P.isValid(state.aboutOverlay) then return true end
    if not state.open or not P.isValid(state.widgetTree)
        or not P.isValid(state.root) then return false end
    local viewportWidth, viewportHeight = logicalViewportSize(state.controller)
    return buildAboutModal(state.widgetTree, state.root, currentStrings(),
        viewportWidth, viewportHeight)
end

buildAboutModal = function(tree, root, strings, viewportWidth, viewportHeight)
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
    local rosterOverlay = construct(tree, "/Script/UMG.CanvasPanel")
    local rosterDim = construct(tree, "/Script/UMG.Border")
    local rosterBox = construct(tree, "/Script/UMG.SizeBox")
    local rosterOutline = construct(tree, "/Script/UMG.Border")
    local rosterPanel = construct(tree, "/Script/UMG.Border")
    local rosterContent = construct(tree, "/Script/UMG.VerticalBox")
    local rosterHeader = construct(tree, "/Script/UMG.HorizontalBox")
    local rosterScroll = construct(tree, "/Script/UMG.ScrollBox")
    local rosterBody = construct(tree, "/Script/UMG.VerticalBox")
    local rosterTitle = makeText(tree, strings.aboutSpecialThanks or "", 18,
        COLORS.text, TEXT_LEFT)
    local rosterDescription = makeText(tree,
        strings.aboutSpecialThanksDescription or "", 11, COLORS.muted, TEXT_LEFT)
    local rosterEmptyCard = construct(tree, "/Script/UMG.Border")
    local rosterEmpty = makeText(tree, strings.aboutSpecialThanksEmpty or "", 13,
        COLORS.muted, TEXT_CENTER)
    local rosterClose = makeIconTrigger(tree, "×", strings.close, "close")
    if overlay == nil or dim == nil or cardBox == nil or outline == nil
        or panel == nil or content == nil or header == nil or identity == nil
        or closeStack == nil or closeHintBox == nil or closeHint == nil
        or titleRow == nil or versionBox == nil or versionBadge == nil
        or scroll == nil or body == nil or title == nil or version == nil
        or summary == nil or close == nil or rosterOverlay == nil
        or rosterDim == nil or rosterBox == nil or rosterOutline == nil
        or rosterPanel == nil or rosterContent == nil or rosterHeader == nil
        or rosterScroll == nil or rosterBody == nil
        or rosterTitle == nil or rosterDescription == nil
        or rosterEmptyCard == nil or rosterEmpty == nil
        or rosterClose == nil then return false end

    state.aboutActions = {}
    state.aboutFocusIndex = 1
    state.aboutPreferredColumn = 2
    state.aboutScroll = scroll
    state.aboutActionHint = closeHint

    local width = math.min(SIZE.aboutWidth,
        math.max(320.0, (tonumber(viewportWidth) or 1280.0) - 48.0))
    local maxHeight = math.min(SIZE.aboutHeight,
        math.max(360.0, (tonumber(viewportHeight) or 720.0) - 48.0))
    local aboutContentWidth = math.max(1.0, width - 2.0 - 32.0)
    local scrollContentWidth = math.max(1.0, aboutContentWidth - 13.0)
    local aboutCardInnerWidth = math.max(1.0,
        scrollContentWidth - (SIZE.aboutSectionGap * 2.0))
    local summaryWrapWidth = math.max(120.0,
        aboutContentWidth - SIZE.headerAction - SIZE.aboutSectionGap)
    local creatorCopyWrapWidth = math.max(120.0, aboutCardInnerWidth
        - (SIZE.aboutCreatorLinkWidth * 2.0)
        - (SIZE.aboutSectionGap * 2.0))
    local supportCopyWrapWidth = math.max(120.0, aboutCardInnerWidth
        - SIZE.aboutSupportActionWidth - SIZE.aboutSectionGap)
    local linkHeadingWrapWidth = math.max(96.0,
        ((aboutCardInnerWidth - 8.0) * 0.5) - 24.0)
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

    local ok = pcall(function()
        overlay:SetVisibility(VIS_COLLAPSED)
        dim:SetBrushColor({ R = 0.0, G = 0.0, B = 0.0, A = 0.64 })
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
        scroll:SetScrollbarThickness({ X = 9.0, Y = 9.0 })
        scroll.ScrollbarPadding = { Left = 2, Top = 2, Right = 2, Bottom = 2 }
        align(scroll:AddChild(body), ALIGN_FILL, ALIGN_LEFT)
        local scrollSlot = content:AddChild(scroll)
        setFill(scrollSlot)
        align(scrollSlot, ALIGN_FILL, ALIGN_FILL)

        local productsCard, products = makeCard()
        local productsRow = construct(tree, "/Script/UMG.HorizontalBox")
        if productsCard == nil or products == nil or productsRow == nil then
            error("About product shelf unavailable")
        end
        productsCard:SetBrushColor(mixLinearColor(
            COLORS.content, COLORS.actionInfo, 0.16))
        productsCard:SetPadding({ Left = 8, Top = 8, Right = 8, Bottom = 8 })
        addCopy(products, strings.aboutProducts or "CRATEXNET PALWORLD TOOLS",
            11, COLORS.accent, 0, aboutCardInnerWidth)
        local productsRowSlot = products:AddChild(productsRow)
        setPadding(productsRowSlot, 0, 4, 0, 0)
        align(productsRowSlot, ALIGN_FILL, ALIGN_CENTER)
        local productGap = SIZE.aboutLinkGap
        local productWidth = math.max(120.0,
            (aboutCardInnerWidth - (productGap * 2.0)) / 3.0)
        local function addProduct(spec, column)
            spec.width = productWidth
            spec.height = 78.0
            spec.orientation = "vertical"
            spec.navRow = 1
            spec.navColumn = column
            local status = spec.current
                and (strings.aboutCurrent or "Current")
                or (strings.aboutOpen or "Open")
            spec.label = spec.title .. "\n" .. status
            spec.tooltip = spec.title
            spec.role = spec.current and "primary" or "aboutLink"
            local action = makeAboutLogoButton(tree, spec)
            if action == nil then return false end
            local slot = productsRow:AddChild(action.box)
            if column == 1 then setPadding(slot, 0, 0, productGap, 0)
            elseif column == 3 then setPadding(slot, productGap, 0, 0, 0)
            end
            align(slot, ALIGN_CENTER, ALIGN_CENTER)
            return true
        end
        local workshopBuild = SteamVote.ready()
        if not addProduct({
                asset = "pal-insight-preview.jpg", fallback = "PI",
                title = "Pal Insight",
                urlKey = workshopBuild and "palInsightWorkshop" or "palInsight",
                iconWidth = 42.0, iconHeight = 42.0,
            }, 1)
            or not addProduct({
                asset = "cratex.png", fallback = "QS", title = "Quick Stack",
                urlKey = workshopBuild and "quickStackWorkshop"
                    or "quickStackNexus",
                current = true, iconWidth = 42.0, iconHeight = 42.0,
            }, 2)
            or not addProduct({
                asset = "breeding-calculator-preview.png", fallback = "BC",
                title = strings.aboutCalculator or "Palworld Breeding Calculator",
                urlKey = "calculator", iconWidth = 68.0, iconHeight = 38.0,
            }, 3) then
            error("About product action unavailable")
        end

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
            navRow = 2, navColumn = 1,
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
            COLORS.muted, 0, creatorCopyWrapWidth)
        addCopy(creatorCopy, "cratexnet", 14, COLORS.text, 2,
            creatorCopyWrapWidth)
        addCopy(creatorCopy, strings.aboutCreatorDescription or "", 11,
            COLORS.muted, 4, creatorCopyWrapWidth)
        local creatorActionsSlot = creatorRow:AddChild(creatorActions)
        align(creatorActionsSlot, ALIGN_RIGHT, ALIGN_CENTER)
        local thanks = makeAboutLogoButton(tree, {
            fallback = "★", fallbackFontSize = 14,
            label = strings.aboutSpecialThanks,
            tooltip = strings.aboutSpecialThanks,
            width = SIZE.aboutCreatorLinkWidth,
            orientation = "horizontal-left", kind = "roster",
            rosterMode = "thanks", role = "thanks", navRow = 2, navColumn = 2,
        })
        local supporters = makeAboutLogoButton(tree, {
            fallback = "♥", fallbackFontSize = 13,
            label = strings.aboutSupporters,
            tooltip = strings.aboutSupporters,
            width = SIZE.aboutCreatorLinkWidth,
            orientation = "horizontal-left", kind = "roster",
            rosterMode = "supporters", role = "supporters",
            navRow = 3, navColumn = 2,
        })
        if thanks == nil or supporters == nil then
            error("About roster actions unavailable")
        end
        local halfRosterGap = SIZE.aboutLinkGap * 0.5
        local thanksSlot = creatorActions:AddChild(thanks.box)
        setPadding(thanksSlot, 0, 0, 0, halfRosterGap)
        align(thanksSlot, ALIGN_FILL, ALIGN_CENTER)
        local supportersSlot = creatorActions:AddChild(supporters.box)
        setPadding(supportersSlot, 0, halfRosterGap, 0, 0)
        align(supportersSlot, ALIGN_FILL, ALIGN_CENTER)

        local linkShelf = construct(tree, "/Script/UMG.HorizontalBox")
        local downloadsCard = construct(tree, "/Script/UMG.Border")
        local downloads = construct(tree, "/Script/UMG.VerticalBox")
        local downloadActions = construct(tree, "/Script/UMG.HorizontalBox")
        local communityCard = construct(tree, "/Script/UMG.Border")
        local community = construct(tree, "/Script/UMG.VerticalBox")
        local communityActions = construct(tree, "/Script/UMG.HorizontalBox")
        if linkShelf == nil or downloadsCard == nil or downloads == nil
            or downloadActions == nil or communityCard == nil
            or community == nil or communityActions == nil then
            error("About link shelf unavailable")
        end
        local shelfSlot = body:AddChild(linkShelf)
        setPadding(shelfSlot, 0, 0, 0, SIZE.aboutSectionGap)
        align(shelfSlot, ALIGN_FILL, ALIGN_FILL)
        for index, pair in ipairs({
            { downloadsCard, downloads }, { communityCard, community },
        }) do
            pair[1]:SetBrushColor(mixLinearColor(
                COLORS.content, COLORS.control, 0.30))
            pair[1]:SetPadding({ Left = 12, Top = SIZE.aboutCardPaddingY,
                Right = 12, Bottom = SIZE.aboutCardPaddingY })
            align(pair[1]:AddChild(pair[2]), ALIGN_FILL, ALIGN_FILL)
            local cardSlot = linkShelf:AddChild(pair[1])
            setFill(cardSlot)
            if index == 1 then setPadding(cardSlot, 0, 0, 4, 0)
            else setPadding(cardSlot, 4, 0, 0, 0) end
        end
        addCopy(downloads, strings.aboutDownloads or "Downloads & feedback",
            13, COLORS.muted, 0, linkHeadingWrapWidth)
        local downloadSlot = downloads:AddChild(downloadActions)
        setPadding(downloadSlot, 0, 8, 0, 0)
        align(downloadSlot, ALIGN_FILL, ALIGN_CENTER)
        local function addLogo(parent, spec)
            local action = makeAboutLogoButton(tree, spec)
            if action == nil then return nil end
            local slot = parent:AddChild(action.box)
            setFill(slot)
            local halfGap = SIZE.aboutLinkGap * 0.5
            setPadding(slot, halfGap, 0, halfGap, 0)
            align(slot, ALIGN_FILL, ALIGN_CENTER)
            return action
        end
        if not addLogo(downloadActions, {
                asset = "nexus.png", fallback = "N", label = "Nexus Mods",
                tooltip = "Nexus Mods", urlKey = "quickStackNexus",
                orientation = "horizontal-left", navRow = 4, navColumn = 1,
            })
            or not addLogo(downloadActions, {
                asset = "steam.png", fallback = "S", label = "Steam Workshop",
                tooltip = "Steam Workshop", urlKey = "quickStackWorkshop",
                orientation = "horizontal-left", navRow = 4, navColumn = 2,
            })
            or not addLogo(downloadActions, {
                asset = "curseforge.png", fallback = "CF", label = "CurseForge",
                tooltip = "CurseForge", urlKey = "quickStackCurseForge",
                orientation = "horizontal-left", navRow = 4, navColumn = 3,
            }) then
            error("About download action unavailable")
        end
        addCopy(community, strings.aboutCommunity or "Community", 13,
            COLORS.muted, 0, linkHeadingWrapWidth)
        local communitySlot = community:AddChild(communityActions)
        setPadding(communitySlot, 0, 8, 0, 0)
        align(communitySlot, ALIGN_FILL, ALIGN_CENTER)
        if not addLogo(communityActions, {
                asset = "x.png", fallback = "X", label = "X",
                tooltip = "X", urlKey = "x", orientation = "horizontal-left",
                navRow = 5, navColumn = 1,
            })
            or not addLogo(communityActions, {
                asset = "discord.png", fallback = "D", label = "Discord",
                tooltip = "Discord", urlKey = "discord",
                orientation = "horizontal-left", navRow = 5, navColumn = 2,
            }) then
            error("About community action unavailable")
        end

        local supportCard, support = makeCard(false)
        local supportRow = construct(tree, "/Script/UMG.HorizontalBox")
        local supportCopy = construct(tree, "/Script/UMG.VerticalBox")
        if supportCard == nil or support == nil or supportRow == nil
            or supportCopy == nil then error("About support card unavailable") end
        supportCard:SetBrushColor(mixLinearColor(
            COLORS.content, COLORS.control, 0.30))
        align(support:AddChild(supportRow), ALIGN_FILL, ALIGN_CENTER)
        local supportCopySlot = supportRow:AddChild(supportCopy)
        setFill(supportCopySlot)
        setPadding(supportCopySlot, 0, 0, 12, 0)
        align(supportCopySlot, ALIGN_FILL, ALIGN_CENTER)
        addCopy(supportCopy, strings.aboutSupport or "Support", 13,
            COLORS.text, 0, supportCopyWrapWidth)
        addCopy(supportCopy, strings.aboutSupportDescription or "", 11,
            COLORS.muted, 5, supportCopyWrapWidth)
        local bmc = makeAboutLogoButton(tree, {
            asset = "buy-me-a-coffee.png", fallback = "BMC",
            tooltip = "Buy Me a Coffee", urlKey = "bmc", role = "brand",
            width = SIZE.aboutSupportActionWidth,
            height = SIZE.aboutSupportActionHeight,
            iconWidth = SIZE.aboutSupportLogoWidth,
            iconHeight = SIZE.aboutSupportLogoHeight,
            navRow = 6, navColumn = 2,
        })
        if bmc == nil then
            error("About support action unavailable")
        end
        align(supportRow:AddChild(bmc.box), ALIGN_CENTER, ALIGN_CENTER)

        state.aboutActions[#state.aboutActions + 1] = {
            box = close.box, widget = close.widget,
            visualButton = close.visualButton, labelWidget = close.text,
            kind = "close", role = "close", label = strings.close,
            tooltip = strings.close, navRow = 7, navColumn = 2,
        }
        rosterOverlay:SetVisibility(VIS_COLLAPSED)
        rosterDim:SetBrushColor({ R = 0.0, G = 0.0, B = 0.0, A = 0.72 })
        local rosterOverlaySlot = root:AddChild(rosterOverlay)
        rosterOverlaySlot:SetAnchors({
            Minimum = { X = 0.0, Y = 0.0 },
            Maximum = { X = 1.0, Y = 1.0 },
        })
        rosterOverlaySlot:SetOffsets({
            Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0,
        })
        rosterOverlaySlot:SetZOrder(4)
        local rosterDimSlot = rosterOverlay:AddChild(rosterDim)
        rosterDimSlot:SetAnchors({
            Minimum = { X = 0.0, Y = 0.0 },
            Maximum = { X = 1.0, Y = 1.0 },
        })
        rosterDimSlot:SetOffsets({
            Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0,
        })
        rosterDimSlot:SetZOrder(0)
        rosterBox:SetWidthOverride(rosterWidth)
        rosterBox:SetMaxDesiredHeight(rosterMaxHeight)
        rosterOutline:SetBrushColor(COLORS.outline)
        rosterOutline:SetPadding({ Left = 1, Top = 1, Right = 1, Bottom = 1 })
        rosterPanel:SetBrushColor(COLORS.content)
        rosterPanel:SetPadding({ Left = 16, Top = 16, Right = 16, Bottom = 16 })
        align(rosterPanel:AddChild(rosterContent), ALIGN_FILL, ALIGN_FILL)
        align(rosterOutline:AddChild(rosterPanel), ALIGN_FILL, ALIGN_FILL)
        align(rosterBox:AddChild(rosterOutline), ALIGN_FILL, ALIGN_FILL)
        local rosterBoxSlot = rosterOverlay:AddChild(rosterBox)
        rosterBoxSlot:SetAnchors({
            Minimum = { X = 0.5, Y = 0.5 },
            Maximum = { X = 0.5, Y = 0.5 },
        })
        rosterBoxSlot:SetAlignment({ X = 0.5, Y = 0.5 })
        rosterBoxSlot:SetPosition({ X = 0.0, Y = 0.0 })
        rosterBoxSlot:SetAutoSize(true)
        rosterBoxSlot:SetZOrder(1)
        local rosterTitleSlot = rosterHeader:AddChild(rosterTitle)
        setFill(rosterTitleSlot)
        align(rosterTitleSlot, ALIGN_LEFT, ALIGN_CENTER)
        align(rosterHeader:AddChild(rosterClose.box), ALIGN_RIGHT, ALIGN_CENTER)
        local rosterHeaderSlot = rosterContent:AddChild(rosterHeader)
        setPadding(rosterHeaderSlot, 0, 0, 0, 8)
        setTextWrap(rosterDescription, rosterWidth - 34.0)
        local rosterDescriptionSlot = rosterContent:AddChild(rosterDescription)
        setPadding(rosterDescriptionSlot, 0, 0, 0, 12)
        rosterScroll:SetAlwaysShowScrollbar(false)
        rosterScroll.AlwaysShowScrollbarTrack = false
        rosterScroll:SetScrollbarThickness({ X = 9.0, Y = 9.0 })
        align(rosterScroll:AddChild(rosterBody), ALIGN_FILL, ALIGN_LEFT)
        local rosterScrollSlot = rosterContent:AddChild(rosterScroll)
        setFill(rosterScrollSlot)
        align(rosterScrollSlot, ALIGN_FILL, ALIGN_FILL)
        rosterEmptyCard:SetBrushColor(COLORS.control)
        rosterEmptyCard:SetPadding({ Left = 16, Top = 20, Right = 16, Bottom = 20 })
        align(rosterEmptyCard:AddChild(rosterEmpty), ALIGN_CENTER, ALIGN_CENTER)
        align(rosterBody:AddChild(rosterEmptyCard), ALIGN_FILL, ALIGN_FILL)
    end)
    if not ok or #(state.aboutActions or {}) < 2 then return false end
    state.aboutOverlay = overlay
    state.aboutCloseWidget = close.widget
    state.aboutRosterOverlay = rosterOverlay
    state.aboutRosterTitle = rosterTitle
    state.aboutRosterDescription = rosterDescription
    state.aboutRosterEmpty = rosterEmpty
    state.aboutRosterCloseWidget = rosterClose.widget
    state.aboutRosterCloseAction = rosterClose
    return true
end

logicalViewportSize = function(controller)
    local width, height = 1280.0, 720.0
    local layout = staticObject("/Script/UMG.Default__WidgetLayoutLibrary")
    if layout == nil then return width, height end
    pcall(function()
        local size = layout:GetViewportSize(controller)
        width = tonumber(size.X) or width
        height = tonumber(size.Y) or height
        local scale = tonumber(layout:GetViewportScale(controller)) or 1.0
        if scale > 0 then width, height = width / scale, height / scale end
    end)
    return width, height
end

local function clearWindowReferences()
    state.widget = nil
    state.widgetTree = nil
    state.root = nil
    state.controls = {}
    state.triggerSurfaces = {}
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
    state.aboutPreferredColumn = 1
    state.aboutActionHint = nil
    state.aboutScroll = nil
    state.aboutRosterOverlay = nil
    state.aboutRosterTitle = nil
    state.aboutRosterDescription = nil
    state.aboutRosterEmpty = nil
    state.aboutRosterCloseWidget = nil
    state.aboutRosterCloseAction = nil
    state.aboutRosterOpen = false
    state.aboutRosterMode = nil
    state.steamVoteControl = nil
    state.steamVoteNoneWidget = nil
    state.steamVoteDownWidget = nil
    state.steamVoteNoneSurface = nil
    state.steamVoteDownSurface = nil
    state.steamVoteUpSurface = nil
    state.steamVoteDisplayStatus = nil
    state.steamVotePendingUp = false
    state.steamVotePalVisuals = {}
    state.steamVotePalVisualReady = false
    state.steamVotePalRetryAt = 0
    state.steamVoteActionVisuals = {}
    state.scroll = nil
    state.nestedOverlay = nil
    state.nestedTitle = nil
    state.modalOptions = {}
    state.activeChoice = nil
    state.numberEdit = nil
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

local function windowCacheMatches(controller)
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
    closeAboutModal(false)
    state.numberEdit = nil
    resetControlsToConfig()
    state.focusIndex = 1
    state.lastInputDevice = "keyboard"
    state.pollFailureSignature = nil
    setStatus("", false)
    if state.steamVoteControl ~= nil and SteamVote.ready() then
        SteamVote.refresh()
        applySteamVoteVisual(SteamVote.status(), true)
    end
    if P.isValid(state.modeText) then
        pcall(function()
            state.modeText:SetText(FText(strings.title .. " · "
                .. (mode == "hosted" and strings.hosted or strings.standalone)))
        end)
    end
    state.footerMode = mode
    state.footerGuideSignature = nil
    FooterGuide.refreshFooterHelp(true)
    for _, record in ipairs(state.triggerSurfaces or {}) do
        record.visualSignature = nil
        record.selected = false
        if P.isValid(record.widget) then
            pcall(function() record.widget:SetIsChecked(false) end)
        end
    end
    local shown = pcall(function()
        state.widget.bIsFocusable = true
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
    local body = construct(tree, "/Script/UMG.VerticalBox")
    if root == nil or shield == nil or cardBox == nil or outline == nil
        or card == nil or layout == nil or contentViewport == nil
        or contentFrame == nil or scroll == nil or contentBox == nil
        or body == nil then
        pcall(function() widget:RemoveFromParent() end)
        return nil, "settings controls cannot be created"
    end
    local strings = currentStrings()
    local viewportWidth, viewportHeight = logicalViewportSize(controller)
    local width = math.min(920.0, math.max(720.0, viewportWidth - 120.0),
        math.max(320.0, viewportWidth - 48.0))
    local height = math.min(math.max(500.0, viewportHeight * 0.60), 640.0,
        math.max(320.0, viewportHeight - 48.0))
    local contentWidth = math.max(1.0, width - 2.0 - 32.0 - 13.0)
    state.contentWidth = contentWidth
    state.controls = {}
    state.triggerSurfaces = {}
    state.nestedOverlay = nil
    state.nestedTitle = nil
    state.modalOptions = {}
    state.activeChoice = nil
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
        outline:SetPadding({ Left = 1, Top = 1, Right = 1, Bottom = 1 })
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
            strings.title .. " · "
                .. (mode == "hosted" and strings.hosted or strings.standalone),
            11, COLORS.textMuted, TEXT_LEFT)
        local voteBox = makeSteamVoteControl(tree, strings)
        local aboutAction = makeIconTrigger(tree, "ⓘ", strings.about, "about")
        local resetAction = makeIconTrigger(tree, "↻", strings.reset, "reset")
        local closeAction = makeIconTrigger(tree, "×", strings.close, "close")
        local aboutCell = aboutAction ~= nil
            and makeHeaderActionCell(tree, aboutAction.box) or nil
        local resetCell = resetAction ~= nil
            and makeHeaderActionCell(tree, resetAction.box) or nil
        local closeCell = closeAction ~= nil
            and makeHeaderActionCell(tree, closeAction.box) or nil
        if headerSize == nil or header == nil or headerRow == nil
            or identity == nil or titleRow == nil or versionBox == nil
            or versionBadge == nil or title == nil or version == nil
            or modeText == nil or headerActionArea == nil
            or headerActionStack == nil or headerActionRow == nil
            or headerActionHintBox == nil or headerActionHint == nil
            or aboutAction == nil or resetAction == nil or closeAction == nil
            or aboutCell == nil or resetCell == nil or closeCell == nil then
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
        versionBadge:SetBrushColor(COLORS.control)
        versionBadge:SetPadding({ Left = 8, Top = 2, Right = 8, Bottom = 2 })
        local versionTextSlot = versionBadge:AddChild(version)
        align(versionTextSlot, ALIGN_CENTER, ALIGN_CENTER)
        local versionBadgeSlot = versionBox:AddChild(versionBadge)
        align(versionBadgeSlot, ALIGN_FILL, ALIGN_FILL)
        local versionSlot = titleRow:AddChild(versionBox)
        setPadding(versionSlot, 8, 0, 0, 0)
        align(versionSlot, ALIGN_LEFT, ALIGN_CENTER)
        local modeSlot = identity:AddChild(modeText)
        setTextWrap(modeText, math.max(1.0,
            contentWidth - 24.0 - (voteBox ~= nil and 74.0 or 0.0) - 124.0))
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

        scroll:SetAlwaysShowScrollbar(false)
        scroll:SetScrollbarThickness({ X = 9.0, Y = 9.0 })
        scroll.ScrollbarPadding = { Left = 2, Top = 2, Right = 2, Bottom = 2 }
        contentFrame:SetBrushColor(COLORS.content)
        contentFrame:SetPadding({ Left = 0, Top = 0, Right = 0, Bottom = 0 })
        local frameScrollSlot = contentFrame:AddChild(scroll)
        align(frameScrollSlot, ALIGN_FILL, ALIGN_FILL)
        contentViewport:SetWidthOverride(contentWidth + 13.0)
        local viewportFrameSlot = contentViewport:AddChild(contentFrame)
        align(viewportFrameSlot, ALIGN_FILL, ALIGN_FILL)
        local contentViewportSlot = layout:AddChild(contentViewport)
        setFill(contentViewportSlot)
        align(contentViewportSlot, ALIGN_FILL, ALIGN_FILL)
        contentBox:SetWidthOverride(contentWidth)
        contentBox:SetMinDesiredHeight(math.max(240.0, height - 250.0))
        local contentSlot = contentBox:AddChild(body)
        align(contentSlot, ALIGN_FILL, ALIGN_FILL)
        local bodySlot = scroll:AddChild(contentBox)
        align(bodySlot, ALIGN_FILL, ALIGN_LEFT)

        if not addSection(tree, body, strings.sectionBasics, 0)
            or not addShortcutRow(tree, body, strings)
            or not addChoiceRow(tree, body, "ResultDisplay",
                strings.resultDisplay,
                { "Default", "TextOnly", "ResultWindow" },
                { strings.resultDefault, strings.resultText,
                    strings.resultWindow }, true)
            or not addSection(tree, body, strings.sectionStorage, 16)
            or not addToggleRow(tree, body, "IncludeExcludedItems",
                strings.includeExcluded, false)
            or not addToggleRow(tree, body, "IncludeNewItems",
                strings.includeNew, true)
            or not addSection(tree, body, strings.sectionSpecial, 16)
            or not addChoiceRow(tree, body, "PalEggRouting",
                strings.eggRouting,
                { "IncubatorOnly", "IncubatorThenStorage" },
                { strings.eggOnly, strings.eggStorage }, false)
            or not addChoiceRow(tree, body, "RelicRouting",
                strings.relicRouting,
                { "RecyclerOnly", "RecyclerThenStorage" },
                { strings.relicOnly, strings.relicStorage }, true)
            or not addNumberRow(tree, body, "WorldTreeHolyWaterMinimum",
                strings.holyWater, 1, 100, false) then
            error("settings rows cannot be created")
        end

        if state.steamVoteControl ~= nil and voteBox ~= nil then
            registerFocusable(state.steamVoteControl, voteBox)
            state.controls[#state.controls + 1] = state.steamVoteControl
        end
        local aboutControl = {
            kind = "about", widget = aboutAction.widget, tooltip = strings.about,
        }
        local resetControl = {
            kind = "reset", widget = resetAction.widget, tooltip = strings.reset,
        }
        local closeControl = {
            kind = "close", widget = closeAction.widget, tooltip = strings.close,
        }
        registerFocusable(aboutControl, aboutAction.box, aboutAction)
        registerFocusable(resetControl, resetAction.box, resetAction)
        registerFocusable(closeControl, closeAction.box, closeAction)
        state.controls[#state.controls + 1] = aboutControl
        state.controls[#state.controls + 1] = resetControl
        state.controls[#state.controls + 1] = closeControl

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

local function acquireInput(controller, widget, mode)
    local controllerAddress = P.objectAddress(controller)
    if controllerAddress == nil then return false, "local controller identity is unavailable" end
    state.controller = controller
    local acquired, acquireError, retainedTransaction = InputOwner.acquire(
        controller, widget, {
        allowWithoutBridge = true,
        modalUIOnly = true,
        hostedParent = mode == "hosted",
        onPressed = function(keyName, source) handlePressed(keyName, nil, source) end,
        onReleased = function(keyName) handleReleased(keyName) end,
        onAxisX = function(value) handleAxis("x", value) end,
        onAxisY = function(value) handleAxis("y", value) end,
        onClose = function(source) SettingsUI.close(source) end,
    })
    if not acquired then
        if retainedTransaction ~= true then state.controller = nil end
        return false, acquireError, retainedTransaction == true
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
    state.log = options.log
    state.onApplied = options.onApplied
    state.onClosed = options.onClosed
    InputOwner.configure(state.log)
    SteamVote.configure(state.log)
    installPreviewKeyHook()
    installKeyUpHook()
    installSelectorSelectedKeyHook()
end

function SettingsUI.prepare()
    local prepareStarted = os.clock()
    local inputHooksReady = installPreviewKeyHook() and installKeyUpHook()
        and installSelectorSelectedKeyHook()
    local controller = P.currentController()
    if state.open and (not P.isValid(controller)
            or not windowCacheMatches(controller)) then
        SettingsUI.close("context-changed")
        controller = P.currentController()
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

function SettingsUI.open(mode, options)
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
    if state.open then
        if state.mode == mode then return true, nil end
        return false, "settings surface is already open"
    end
    if type(state.config) ~= "table" then return false, "settings are unavailable" end
    local controller = P.currentController()
    if not P.isValid(controller) then return false, "local controller is unavailable" end
    if not installPreviewKeyHook() or not installKeyUpHook()
        or not installSelectorSelectedKeyHook() then
        return false, "focus-scoped settings input is unavailable"
    end
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
    state.generation = state.generation + 1
    state.mode = mode
    state.open = true
    state.gamepadBackDown = false
    state.gamepadAcceptDown = false
    state.controllerDown = {}
    state.axisArmed = { x = true, y = true }
    state.synchronousNavigationUntil = {}
    state.trailingReleaseUntil = {}
    if not prepareWindowForOpen(mode) then
        state.open = false
        state.mode = nil
        discardWindowCache()
        return false, "settings window cannot be activated"
    end
    prepareFinished = os.clock()
    local acquired, acquireError, retainedTransaction = acquireInput(
        controller, widget, mode)
    if not acquired then
        if retainedTransaction == true then
            setStatus(currentStrings().inputRestoreFailed
                or "Could not restore input. The panel remains open; try Close again.", true)
            for _, keyName in ipairs(CONTROLLER_KEYS) do
                state.controllerDown[keyName] = inputKeyDown(controller, keyName) == true
            end
            state.pollPending = false
            schedulePoll()
            focusEntry(1, "keyboard", true)
            log("settings open rollback retained a visible modal transaction")
            -- The child still owns at least part of the modal transaction. Keep
            -- the host suspended and expose the same panel as the recovery
            -- surface; hiding it would create an unrecoverable transparent lock.
            return true, nil
        end
        state.open = false
        state.mode = nil
        state.controller = nil
        pcall(function()
            widget.bIsFocusable = false
            widget:SetVisibility(VIS_COLLAPSED)
        end)
        return false, acquireError or "settings input ownership cannot be acquired"
    end
    for _, keyName in ipairs(CONTROLLER_KEYS) do
        state.controllerDown[keyName] = inputKeyDown(controller, keyName) == true
    end
    state.pollPending = false
    schedulePoll()
    focusEntry(1, "keyboard", true)
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

function SettingsUI.close(reason)
    if not state.open then return true end
    local escapeClose = reason == "escape"
    if escapeClose then InputOwner.armEscapeClose(reason) end
    local closedMode = state.mode
    local widget = state.widget
    local controller = state.controller
    local numberControl = focusedNumberControl()
    if numberControl ~= nil then
        commitNumberEditor(numberControl, "number-close")
    end
    closeChoiceModal(false)
    closeAboutModal(false)
    if not InputOwner.release({
            hostUnavailable = reason == "host-unavailable",
        }) then
        if escapeClose then InputOwner.cancelEscapeClose() end
        focusNavigationRoot()
        setStatus(currentStrings().inputRestoreFailed
            or "Could not restore input. The panel remains open; try Close again.", true)
        log("settings close could not restore input; modal transaction retained")
        return false
    end
    local preserveWindow = windowCacheMatches(controller)
    state.open = false
    state.mode = nil
    state.generation = state.generation + 1
    stopPoll()
    state.gamepadBackDown = false
    state.gamepadAcceptDown = false
    state.synchronousNavigationUntil = {}
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

function SettingsUI.toggle(mode)
    if state.open then
        return SettingsUI.close("shortcut")
    end
    return SettingsUI.open(mode or "standalone")
end

function SettingsUI.mode()
    return state.open and state.mode or nil
end

return SettingsUI
