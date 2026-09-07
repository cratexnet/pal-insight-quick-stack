local P = require("palworld")
local Localization = require("localization")
local ResultDialogBridge = require("pal_insight_bridge")

local Notifications = {}

local COMPACT_MIN_WIDTH = 360.0
local COMPACT_MAX_WIDTH = 520.0
local COMPACT_MIN_HEIGHT = 52.0
local COMPACT_SAFE_MARGIN = 48.0
local COMPACT_CHROME_WIDTH = 32.0
local DETAIL_MIN_WIDTH = 920.0
local DETAIL_MAX_WIDTH = 1568.0
local DETAIL_SAFE_MARGIN = 48.0
local DETAIL_MAX_HEIGHT = 664.0
local DETAIL_HEADER_HEIGHT = 64.0
local DETAIL_HEADER_HELPER_HEIGHT = 88.0
local DETAIL_HEADER_HELPER_NARROW_HEIGHT = 112.0
local DETAIL_FOOTER_HEIGHT = 56.0
local DETAIL_CONTENT_PADDING = 16.0
local DETAIL_SCROLLBAR_GUTTER = 13.0
local DETAIL_SCROLLBAR_SAFE_GAP = 12.0
local DETAIL_CONTENT_SLACK = 8.0
local DETAIL_ITEM_COLUMN_GAP = 12.0
local DETAIL_ITEM_ROW_GAP = 4.0
local ITEM_NATIVE_MIN_WIDTH = 360.0
local ITEM_ROW_HEIGHT = 34.0
local ITEM_COUNT_WIDTH = 68.0
local SECTION_HEADER_HEIGHT = 36.0
local DETAIL_BUILD_SLICE_MS = 16
local STATIC_WARMUP_START_MS = 3000
local COMPACT_DURATION_MS = 2000
local MAX_SECTION_ITEMS = 12
local VIS_VISIBLE = 0
local VIS_COLLAPSED = 1
local VIS_HIT_TEST_INVISIBLE = 3
local VIS_SELF_HIT_TEST_INVISIBLE = 4
local TEXT_JUSTIFY_CENTER = 1
local TEXT_JUSTIFY_RIGHT = 2
local SLOT_ALIGN_LEFT = 1
local SLOT_ALIGN_CENTER = 2
local SLOT_ALIGN_RIGHT = 3

local ITEM_ROW_ASSET_PATH =
    "/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Paldex/WBP_Paldex_DropItem"
local ITEM_ROW_CLASS_PATH = ITEM_ROW_ASSET_PATH .. ".WBP_Paldex_DropItem_C"
local STATIC_WARMUP_PATHS = {
    "/Script/UMG.Default__WidgetBlueprintLibrary",
    "/Script/UMG.UserWidget",
    "/Script/UMG.Default__WidgetLayoutLibrary",
    "/Script/UMG.CanvasPanel",
    "/Script/UMG.SizeBox",
    "/Script/UMG.Border",
    "/Script/UMG.TextBlock",
    "/Script/UMG.Spacer",
    "/Script/UMG.Overlay",
    "/Script/UMG.HorizontalBox",
    "/Script/UMG.VerticalBox",
    "/Script/UMG.ScrollBox",
    "/Script/UMG.Button",
}
local STATIC_WARMUP_TASK_COUNT = #STATIC_WARMUP_PATHS + 1

local COLORS = {
    primary = { R = 0.209, G = 0.533, B = 0.665, A = 1.00 },
    success = { R = 0.353, G = 0.773, B = 0.412, A = 1.00 },
    warning = { R = 0.807, G = 0.451, B = 0.102, A = 1.00 },
    danger = { R = 0.800, G = 0.390, B = 0.380, A = 1.00 },
    surface = { R = 0.015, G = 0.021, B = 0.027, A = 0.96 },
    surfaceWindow = { R = 0.006, G = 0.008, B = 0.011, A = 0.78 },
    surfaceChrome = { R = 0.027, G = 0.033, B = 0.040, A = 0.72 },
    surfaceContent = { R = 0.031, G = 0.037, B = 0.045, A = 0.88 },
    surfaceNavigation = { R = 0.040, G = 0.048, B = 0.058, A = 0.76 },
    surfaceSection = { R = 0.059, G = 0.071, B = 0.082, A = 0.90 },
    transparent = { R = 0.0, G = 0.0, B = 0.0, A = 0.0 },
    primaryHover = { R = 0.288, G = 0.580, B = 0.699, A = 1.00 },
    primaryPressed = { R = 0.184, G = 0.469, B = 0.585, A = 1.00 },
    surfaceDisabled = { R = 0.047, G = 0.054, B = 0.063, A = 0.64 },
    windowOutline = { R = 0.716, G = 0.807, B = 0.855, A = 0.15 },
    text = { R = 0.930, G = 0.947, B = 0.956, A = 1.00 },
    textOnAccent = { R = 0.004, G = 0.009, B = 0.012, A = 1.00 },
    muted = { R = 0.631, G = 0.680, B = 0.708, A = 1.00 },
    subtle = { R = 0.361, G = 0.407, B = 0.440, A = 1.00 },
}

local state = {
    log = nil,
    warned = false,
    warnedItemRows = false,
    token = 0,
    widget = nil,
    buildWidget = nil,
    detailVisible = false,
    inputOwned = false,
    closeButton = nil,
    itemRowClass = nil,
    itemRowLoadAttempts = 0,
    staticObjects = {},
    staticWarmupIndex = 1,
    staticWarmupScheduled = false,
    staticWarmupSlices = 0,
    staticWarmupTotalMs = 0,
    staticWarmupMaxMs = 0,
    performanceCapture = false,
}

local function logWarning(prefix, message)
    if type(state.log) == "function" then
        state.log(prefix .. tostring(message))
    end
end

local function warnOnce(message)
    if state.warned then return end
    state.warned = true
    logWarning("in-game notification unavailable: ", message)
end

local function warnItemRowsOnce(message)
    if state.warnedItemRows then return end
    state.warnedItemRows = true
    logWarning("native item result rows unavailable: ", message)
end

local function slateColor(color)
    return {
        SpecifiedColor = color,
        ColorUseRule = 0,
    }
end

local function tintBrush(brush, color)
    if brush == nil then return brush end
    brush.TintColor = slateColor(color)
    return brush
end

local function cachedStaticObject(classPath)
    local classObject = state.staticObjects[classPath]
    if classObject ~= nil then return classObject end
    classObject = P.staticObject(classPath)
    if classObject ~= nil then state.staticObjects[classPath] = classObject end
    return classObject
end

local scheduleStaticObjectWarmup

scheduleStaticObjectWarmup = function(delayMs)
    if state.staticWarmupScheduled
        or state.staticWarmupIndex > STATIC_WARMUP_TASK_COUNT
        or type(ExecuteInGameThreadWithDelay) ~= "function" then return false end
    state.staticWarmupScheduled = true
    local scheduled = pcall(ExecuteInGameThreadWithDelay, delayMs or 0, function()
        state.staticWarmupScheduled = false
        local startedAt = state.performanceCapture and os.clock() or nil
        if state.staticWarmupIndex <= #STATIC_WARMUP_PATHS then
            cachedStaticObject(STATIC_WARMUP_PATHS[state.staticWarmupIndex])
        else
            Localization.warmup()
        end
        if startedAt ~= nil then
            local duration = math.max(0, (os.clock() - startedAt) * 1000)
            state.staticWarmupSlices = state.staticWarmupSlices + 1
            state.staticWarmupTotalMs = state.staticWarmupTotalMs + duration
            state.staticWarmupMaxMs = math.max(
                state.staticWarmupMaxMs, duration)
        end
        state.staticWarmupIndex = state.staticWarmupIndex + 1
        if state.staticWarmupIndex <= STATIC_WARMUP_TASK_COUNT then
            scheduleStaticObjectWarmup(DETAIL_BUILD_SLICE_MS)
        elseif state.performanceCapture and type(state.log) == "function" then
            state.log(string.format(
                "perf_notification_warmup|tasks=%d|slices=%d|work_ms=%.3f|max_slice_ms=%.3f",
                STATIC_WARMUP_TASK_COUNT,
                state.staticWarmupSlices,
                state.staticWarmupTotalMs,
                state.staticWarmupMaxMs))
        end
    end)
    if not scheduled then state.staticWarmupScheduled = false end
    return scheduled
end

local function construct(tree, classPath)
    local classObject = cachedStaticObject(classPath)
    if classObject == nil or type(StaticConstructObject) ~= "function" then
        return nil
    end
    local ok, object = pcall(StaticConstructObject, classObject, tree)
    if not ok or not P.isValid(object) then return nil end
    return object
end

local function setTextStyle(text, size, color, justification, flat)
    local font = text.Font
    font.Size = size
    text.Font = font
    text:SetFont(font)
    text:SetJustification(justification or 0)
    text:SetColorAndOpacity(slateColor(color or COLORS.text))
    if flat then
        text:SetShadowOffset({ X = 0.0, Y = 0.0 })
        text:SetShadowColorAndOpacity(
            { R = 0.0, G = 0.0, B = 0.0, A = 0.0 })
    else
        text:SetShadowOffset({ X = 1.0, Y = 1.0 })
        text:SetShadowColorAndOpacity(
            { R = 0.0, G = 0.025, B = 0.035, A = 0.92 })
    end
end

local function styleActionButton(button)
    local style = button.WidgetStyle
    style.Normal = tintBrush(style.Normal, COLORS.primary)
    style.Hovered = tintBrush(style.Hovered, COLORS.primaryHover)
    style.Pressed = tintBrush(style.Pressed, COLORS.primaryPressed)
    style.Disabled = tintBrush(style.Disabled, COLORS.surfaceDisabled)
    style.NormalForeground = slateColor(COLORS.textOnAccent)
    style.HoveredForeground = slateColor(COLORS.textOnAccent)
    style.PressedForeground = slateColor(COLORS.textOnAccent)
    style.DisabledForeground = slateColor(COLORS.subtle)
    style.NormalPadding = { Left = 12, Top = 4, Right = 12, Bottom = 4 }
    style.PressedPadding = { Left = 12, Top = 4, Right = 12, Bottom = 4 }
    button.WidgetStyle = style
    button:SetBackgroundColor({ R = 1.0, G = 1.0, B = 1.0, A = 1.0 })
end

local function clear()
    if state.inputOwned and not ResultDialogBridge.release() then
        if P.isValid(state.widget) then
            pcall(function() state.widget:SetRenderOpacity(1.0) end)
        end
        ResultDialogBridge.focusCloseButton()
        logWarning("result dialog input release failed: ",
            "modal transaction retained")
        return false
    end
    state.token = state.token + 1
    if P.isValid(state.widget) then
        pcall(function() state.widget:RemoveFromParent() end)
    end
    if P.isValid(state.buildWidget) and state.buildWidget ~= state.widget then
        pcall(function() state.buildWidget:RemoveFromParent() end)
    end
    state.widget = nil
    state.buildWidget = nil
    state.detailVisible = false
    state.inputOwned = false
    state.closeButton = nil
    return true
end

local function creationRoots(controller)
    if not P.isValid(controller) then
        return nil, nil, nil, "local controller is unavailable"
    end
    local world
    local ok = pcall(function() world = controller:GetWorld() end)
    local library = cachedStaticObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    local userWidgetClass = cachedStaticObject("/Script/UMG.UserWidget")
    if not ok or not P.isValid(world) or library == nil
        or userWidgetClass == nil then
        return nil, nil, nil, "UMG creation roots are unavailable"
    end
    return world, library, userWidgetClass, nil
end

local function createOwnerWidget(controller)
    local world, library, userWidgetClass, rootError = creationRoots(controller)
    if rootError ~= nil then return nil, nil, nil, nil, rootError end
    local widget
    local ok = pcall(function()
        widget = library:Create(world, userWidgetClass, controller)
    end)
    if not ok or not P.isValid(widget) then
        return nil, nil, nil, nil, "status widget cannot be created"
    end
    local tree
    ok = pcall(function() tree = widget.WidgetTree end)
    if not ok or not P.isValid(tree) then
        pcall(function() widget:RemoveFromParent() end)
        return nil, nil, nil, nil, "status widget tree is unavailable"
    end
    return widget, tree, world, library, nil
end

local function logicalViewportSize(controller)
    local width, height = 1280.0, 720.0
    local layoutLibrary = cachedStaticObject(
        "/Script/UMG.Default__WidgetLayoutLibrary")
    if layoutLibrary == nil or not P.isValid(controller) then
        return width, height
    end
    local viewport
    local ok = pcall(function()
        viewport = layoutLibrary:GetViewportSize(controller)
    end)
    if not ok or viewport == nil then return width, height end
    local rawWidth, rawHeight
    ok = pcall(function()
        rawWidth = viewport.X
        rawHeight = viewport.Y
    end)
    if not ok or type(rawWidth) ~= "number" or rawWidth <= 0
        or type(rawHeight) ~= "number" or rawHeight <= 0 then
        return width, height
    end
    local scale = 1.0
    pcall(function() scale = layoutLibrary:GetViewportScale(controller) end)
    if type(scale) ~= "number" or scale <= 0 then scale = 1.0 end
    return rawWidth / scale, rawHeight / scale
end

local function compactMetrics(controller)
    local logicalWidth = logicalViewportSize(controller)
    local safeWidth = math.max(240.0,
        logicalWidth - COMPACT_SAFE_MARGIN)
    local maxWidth = math.min(COMPACT_MAX_WIDTH, safeWidth)
    return {
        minWidth = math.min(COMPACT_MIN_WIDTH, maxWidth),
        maxWidth = maxWidth,
        textWidth = math.max(1.0, maxWidth - COMPACT_CHROME_WIDTH),
    }
end

local function mountCompactFrame(widget, tree, content, textWidgets,
        controller, color)
    local root = construct(tree, "/Script/UMG.CanvasPanel")
    local sizeBox = construct(tree, "/Script/UMG.SizeBox")
    local outline = construct(tree, "/Script/UMG.Border")
    local surface = construct(tree, "/Script/UMG.Border")
    if root == nil or sizeBox == nil or outline == nil or surface == nil then
        return false, "status widget frame controls are unavailable"
    end
    local metrics = compactMetrics(controller)
    local ok = pcall(function()
        tree.RootWidget = root
        sizeBox:SetMinDesiredWidth(metrics.minWidth)
        sizeBox:SetMaxDesiredWidth(metrics.maxWidth)
        sizeBox:SetMinDesiredHeight(COMPACT_MIN_HEIGHT)
        outline:SetBrushColor(color or COLORS.primary)
        outline:SetPadding({ Left = 2, Top = 2, Right = 2, Bottom = 2 })
        surface:SetBrushColor(COLORS.surface)
        surface:SetPadding({ Left = 14, Top = 10, Right = 14, Bottom = 10 })
        for _, text in ipairs(textWidgets or {}) do
            text:SetAutoWrapText(false)
            text.WrapTextAt = metrics.textWidth
        end

        local contentSlot = surface:AddChild(content)
        local surfaceSlot = outline:AddChild(surface)
        local outlineSlot = sizeBox:AddChild(outline)
        contentSlot:SetHorizontalAlignment(0)
        contentSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        surfaceSlot:SetHorizontalAlignment(0)
        surfaceSlot:SetVerticalAlignment(0)
        outlineSlot:SetHorizontalAlignment(0)
        outlineSlot:SetVerticalAlignment(0)

        local slot = root:AddChild(sizeBox)
        slot:SetAnchors({
            Minimum = { X = 0.5, Y = 0.38 },
            Maximum = { X = 0.5, Y = 0.38 },
        })
        slot:SetAlignment({ X = 0.5, Y = 0.5 })
        slot:SetAutoSize(true)
        slot:SetPosition({ X = 0.0, Y = 0.0 })
        slot:SetZOrder(0)
        root:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        widget.bIsFocusable = false
        widget:SetVisibility(VIS_HIT_TEST_INVISIBLE)
        widget:AddToViewport(20)
    end)
    if not ok then return false, "status widget frame cannot be initialized" end
    return true, nil
end

local function detailedMetrics(controller)
    local logicalWidth, logicalHeight = logicalViewportSize(controller)
    local safeWidth = math.max(320.0, logicalWidth - DETAIL_SAFE_MARGIN)
    local width = math.min(DETAIL_MAX_WIDTH,
        math.max(DETAIL_MIN_WIDTH, logicalWidth - DETAIL_SAFE_MARGIN),
        safeWidth)
    local bodyWidth = math.max(240.0,
        width - 2.0 - DETAIL_CONTENT_PADDING * 2.0
            - DETAIL_SCROLLBAR_GUTTER - DETAIL_SCROLLBAR_SAFE_GAP)
    local columns = bodyWidth >= ITEM_NATIVE_MIN_WIDTH * 4.0
            + DETAIL_ITEM_COLUMN_GAP * 3.0 and 4
        or bodyWidth >= ITEM_NATIVE_MIN_WIDTH * 3.0
            + DETAIL_ITEM_COLUMN_GAP * 2.0 and 3 or 2
    local itemWidth = (bodyWidth
        - DETAIL_ITEM_COLUMN_GAP * (columns - 1)) / columns
    local maxHeight = math.min(DETAIL_MAX_HEIGHT,
        math.max(320.0, logicalHeight - DETAIL_SAFE_MARGIN))
    return {
        width = width,
        columns = columns,
        bodyWidth = bodyWidth,
        itemWidth = itemWidth,
        maxHeight = maxHeight,
    }
end

local function mountDetailedFrame(widget, tree, content, width, height)
    local root = construct(tree, "/Script/UMG.CanvasPanel")
    local inputShield = construct(tree, "/Script/UMG.Border")
    local sizeBox = construct(tree, "/Script/UMG.SizeBox")
    local outline = construct(tree, "/Script/UMG.Border")
    local surface = construct(tree, "/Script/UMG.Border")
    if root == nil or inputShield == nil or sizeBox == nil
        or outline == nil or surface == nil then
        return false, "detailed result frame controls are unavailable"
    end
    local ok = pcall(function()
        tree.RootWidget = root
        inputShield:SetBrushColor(COLORS.transparent)
        inputShield:SetVisibility(VIS_VISIBLE)
        inputShield:SetIsEnabled(true)
        sizeBox:SetWidthOverride(width)
        sizeBox:SetHeightOverride(height)
        outline:SetBrushColor(COLORS.windowOutline)
        outline:SetPadding({ Left = 1, Top = 1, Right = 1, Bottom = 1 })
        surface:SetBrushColor(COLORS.surfaceWindow)

        local contentSlot = surface:AddChild(content)
        contentSlot:SetHorizontalAlignment(0)
        contentSlot:SetVerticalAlignment(0)
        local surfaceSlot = outline:AddChild(surface)
        surfaceSlot:SetHorizontalAlignment(0)
        surfaceSlot:SetVerticalAlignment(0)
        local outlineSlot = sizeBox:AddChild(outline)
        outlineSlot:SetHorizontalAlignment(0)
        outlineSlot:SetVerticalAlignment(0)

        local shieldSlot = root:AddChild(inputShield)
        shieldSlot:SetAnchors({
            Minimum = { X = 0.0, Y = 0.0 },
            Maximum = { X = 1.0, Y = 1.0 },
        })
        shieldSlot:SetOffsets({ Left = 0.0, Top = 0.0, Right = 0.0, Bottom = 0.0 })
        shieldSlot:SetZOrder(0)

        local slot = root:AddChild(sizeBox)
        slot:SetAnchors({
            Minimum = { X = 0.5, Y = 0.5 },
            Maximum = { X = 0.5, Y = 0.5 },
        })
        slot:SetAlignment({ X = 0.5, Y = 0.5 })
        slot:SetAutoSize(false)
        slot:SetPosition({ X = 0.0, Y = 0.0 })
        slot:SetSize({ X = width, Y = height })
        slot:SetZOrder(1)
        widget.bIsFocusable = true
        root:SetVisibility(VIS_VISIBLE)
        sizeBox:SetVisibility(VIS_SELF_HIT_TEST_INVISIBLE)
        outline:SetVisibility(VIS_SELF_HIT_TEST_INVISIBLE)
        surface:SetVisibility(VIS_SELF_HIT_TEST_INVISIBLE)
        content:SetVisibility(VIS_SELF_HIT_TEST_INVISIBLE)
        widget:SetVisibility(VIS_SELF_HIT_TEST_INVISIBLE)
        widget:AddToViewport(100)
    end)
    if not ok then return false, "detailed result frame cannot be initialized" end
    return true, nil
end

local function prepareItemRowClass(allowLoad)
    if P.isValid(state.itemRowClass) then return state.itemRowClass end
    state.itemRowClass = cachedStaticObject(ITEM_ROW_CLASS_PATH)
    if P.isValid(state.itemRowClass) then return state.itemRowClass end
    if allowLoad and state.itemRowLoadAttempts < 2
        and type(LoadAsset) == "function" then
        state.itemRowLoadAttempts = state.itemRowLoadAttempts + 1
        pcall(LoadAsset, ITEM_ROW_ASSET_PATH)
        state.staticObjects[ITEM_ROW_CLASS_PATH] = nil
        state.itemRowClass = cachedStaticObject(ITEM_ROW_CLASS_PATH)
    end
    return P.isValid(state.itemRowClass) and state.itemRowClass or nil
end

local function makeText(tree, value, size, color, justification, flat)
    local text = construct(tree, "/Script/UMG.TextBlock")
    if text == nil then return nil end
    local ok = pcall(function()
        setTextStyle(text, size, color, justification, flat)
        text:SetText(FText(value))
    end)
    return ok and text or nil
end

local function addVertical(parent, child, padding)
    local slot = parent:AddChildToVerticalBox(child)
    if padding ~= nil then slot:SetPadding(padding) end
    return slot
end

local function addHorizontal(parent, child, padding)
    local slot = parent:AddChildToHorizontalBox(child)
    if padding ~= nil then slot:SetPadding(padding) end
    return slot
end

local function fill(slot)
    slot:SetSize({ SizeRule = 1, Value = 1.0 })
end

local function createSpacer(tree, width, height)
    local spacer = construct(tree, "/Script/UMG.Spacer")
    if spacer == nil then return nil end
    local ok = pcall(function()
        spacer:SetSize({ X = width or 1.0, Y = height or 1.0 })
    end)
    return ok and spacer or nil
end

local function createCountValue(tree, amount)
    local sizeBox = construct(tree, "/Script/UMG.SizeBox")
    local surface = construct(tree, "/Script/UMG.Border")
    local value = makeText(tree, "×" .. tostring(amount or 0),
        12, COLORS.text, TEXT_JUSTIFY_RIGHT, true)
    if sizeBox == nil or surface == nil or value == nil then
        return nil
    end
    local ok = pcall(function()
        sizeBox:SetWidthOverride(ITEM_COUNT_WIDTH)
        sizeBox:SetHeightOverride(ITEM_ROW_HEIGHT)
        surface:SetBrushColor(COLORS.transparent)
        surface:SetPadding({ Left = 4, Top = 0, Right = 12, Bottom = 0 })
        local valueSlot = surface:AddChild(value)
        valueSlot:SetHorizontalAlignment(0)
        valueSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        local surfaceSlot = sizeBox:AddChild(surface)
        surfaceSlot:SetHorizontalAlignment(0)
        surfaceSlot:SetVerticalAlignment(0)
    end)
    return ok and sizeBox or nil
end

local function createNativeItemRow(tree, world, library, controller, item, width)
    local itemRowClass = prepareItemRowClass(true)
    if itemRowClass == nil then return nil, "native item-row class is unavailable" end
    local itemWidget
    local created = pcall(function()
        itemWidget = library:Create(world, itemRowClass, controller)
    end)
    if not created or not P.isValid(itemWidget) then
        return nil, "native item row cannot be created"
    end
    local setup = pcall(function() itemWidget:Setup(item.staticId) end)
    if not setup then
        pcall(function() itemWidget:RemoveFromParent() end)
        return nil, "native item row setup failed"
    end

    local sizeBox = construct(tree, "/Script/UMG.SizeBox")
    local overlay = construct(tree, "/Script/UMG.Overlay")
    local rowSurface = construct(tree, "/Script/UMG.Border")
    local itemHost = construct(tree, "/Script/UMG.SizeBox")
    local countValue = createCountValue(tree, item.num)
    if sizeBox == nil or overlay == nil or rowSurface == nil
        or itemHost == nil
        or countValue == nil then
        pcall(function() itemWidget:RemoveFromParent() end)
        return nil, "native item-row host controls are unavailable"
    end
    pcall(function() itemWidget:SetClipping(1) end)
    pcall(function() itemWidget.Text_ItemDesc:SetClipping(1) end)
    pcall(function()
        itemWidget.Base:SetVisibility(VIS_COLLAPSED)
        itemWidget.Dot_0:SetVisibility(VIS_COLLAPSED)
        itemWidget.Dot_1:SetVisibility(VIS_COLLAPSED)
        itemWidget.Dot_2:SetVisibility(VIS_COLLAPSED)
        itemWidget.Dot_3:SetVisibility(VIS_COLLAPSED)
    end)
    pcall(function() overlay:SetClipping(1) end)

    local ok = pcall(function()
        sizeBox:SetWidthOverride(width)
        sizeBox:SetHeightOverride(ITEM_ROW_HEIGHT)
        itemHost:SetWidthOverride(math.max(1.0, width - ITEM_COUNT_WIDTH))
        itemHost:SetHeightOverride(ITEM_ROW_HEIGHT)
        itemHost:SetClipping(1)
        rowSurface:SetBrushColor(COLORS.surfaceNavigation)
        local rowSurfaceSlot = overlay:AddChildToOverlay(rowSurface)
        rowSurfaceSlot:SetHorizontalAlignment(0)
        rowSurfaceSlot:SetVerticalAlignment(0)
        local itemWidgetSlot = itemHost:AddChild(itemWidget)
        itemWidgetSlot:SetHorizontalAlignment(0)
        itemWidgetSlot:SetVerticalAlignment(0)
        local itemSlot = overlay:AddChildToOverlay(itemHost)
        itemSlot:SetHorizontalAlignment(SLOT_ALIGN_LEFT)
        itemSlot:SetVerticalAlignment(0)
        local countSlot = overlay:AddChildToOverlay(countValue)
        countSlot:SetHorizontalAlignment(SLOT_ALIGN_RIGHT)
        countSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        local overlaySlot = sizeBox:AddChild(overlay)
        overlaySlot:SetHorizontalAlignment(0)
        overlaySlot:SetVerticalAlignment(0)
    end)
    if not ok then
        pcall(function() itemWidget:RemoveFromParent() end)
        return nil, "native item row cannot be mounted"
    end
    return sizeBox, nil
end

local function createFallbackItemRow(tree, item, width)
    local sizeBox = construct(tree, "/Script/UMG.SizeBox")
    local surface = construct(tree, "/Script/UMG.Border")
    local row = construct(tree, "/Script/UMG.HorizontalBox")
    local text = makeText(tree, tostring(item.id or "?"),
        13, COLORS.text, 0, true)
    local countValue = createCountValue(tree, item.num)
    if sizeBox == nil or surface == nil or row == nil or text == nil
        or countValue == nil then return nil end
    local ok = pcall(function()
        sizeBox:SetWidthOverride(width)
        sizeBox:SetHeightOverride(ITEM_ROW_HEIGHT)
        surface:SetBrushColor(COLORS.surfaceNavigation)
        surface:SetPadding({ Left = 10, Top = 0, Right = 0, Bottom = 0 })
        local textSlot = addHorizontal(row, text,
            { Left = 0, Top = 0, Right = 8, Bottom = 0 })
        textSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        fill(textSlot)
        local countSlot = addHorizontal(row, countValue)
        countSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        local rowSlot = surface:AddChild(row)
        rowSlot:SetHorizontalAlignment(0)
        rowSlot:SetVerticalAlignment(0)
        local surfaceSlot = sizeBox:AddChild(surface)
        surfaceSlot:SetHorizontalAlignment(0)
        surfaceSlot:SetVerticalAlignment(0)
    end)
    return ok and sizeBox or nil
end

local function createItemRow(tree, world, library, controller, item, width)
    local row, rowError = createNativeItemRow(
        tree, world, library, controller, item, width)
    if row ~= nil then return row end
    warnItemRowsOnce(rowError)
    return createFallbackItemRow(tree, item, width)
end

local function appendItemGridRow(stack, tree, world, library, controller,
        items, metrics, first)
    local shown = math.min(#items, MAX_SECTION_ITEMS)
    if first > shown then return first, nil end
    local row = construct(tree, "/Script/UMG.HorizontalBox")
    if row == nil then return nil, "result item-grid row is unavailable" end
    local index = first
    for column = 1, metrics.columns do
        local item = index <= shown and items[index] or nil
        local cell = item ~= nil and createItemRow(
            tree, world, library, controller, item, metrics.itemWidth)
            or createSpacer(tree, metrics.itemWidth, ITEM_ROW_HEIGHT)
        if cell == nil then return nil, "result item-grid cell is unavailable" end
        local cellSlot = addHorizontal(row, cell)
        fill(cellSlot)
        if column < metrics.columns then
            local gap = createSpacer(tree, DETAIL_ITEM_COLUMN_GAP, 1.0)
            if gap == nil then return nil, "result item-grid gap is unavailable" end
            addHorizontal(row, gap)
        end
        index = index + 1
    end
    addVertical(stack, row,
        { Left = 0, Top = DETAIL_ITEM_ROW_GAP, Right = 0, Bottom = 0 })
    return index, nil
end

local function appendItemGridOverflow(stack, tree, items, strings)
    local shown = math.min(#items, MAX_SECTION_ITEMS)
    if #items <= shown then return true end
    local overflow = makeText(tree,
        Localization.format(strings, "overflow", #items - shown),
        12, COLORS.subtle, 0, true)
    if overflow == nil then return false end
    addVertical(stack, overflow,
        { Left = 12, Top = 8, Right = 0, Bottom = 0 })
    return true
end

local function sectionDesiredHeight(items, columns)
    local shown = math.min(#items, MAX_SECTION_ITEMS)
    local rows = shown > 0 and math.ceil(shown / columns) or 0
    local height = SECTION_HEADER_HEIGHT
        + rows * (ITEM_ROW_HEIGHT + DETAIL_ITEM_ROW_GAP)
    if #items > shown then height = height + 24.0 end
    return height
end

local function createResultSectionFrame(tree, spec, metrics)
    local stack = construct(tree, "/Script/UMG.VerticalBox")
    local headerBox = construct(tree, "/Script/UMG.SizeBox")
    local headerSurface = construct(tree, "/Script/UMG.Border")
    local header = construct(tree, "/Script/UMG.HorizontalBox")
    local title = makeText(tree, spec.label, 13, spec.color, 0, true)
    local summary = makeText(tree, spec.summary,
        11, COLORS.muted, TEXT_JUSTIFY_RIGHT, true)
    if stack == nil or headerBox == nil or headerSurface == nil
        or header == nil or title == nil or summary == nil then return nil end

    local ok = pcall(function()
        headerBox:SetWidthOverride(metrics.bodyWidth)
        headerBox:SetHeightOverride(SECTION_HEADER_HEIGHT)
        headerSurface:SetBrushColor(COLORS.surfaceSection)
        headerSurface:SetPadding({ Left = 12, Top = 4, Right = 12, Bottom = 4 })
        local titleSlot = addHorizontal(header, title,
            { Left = 0, Top = 0, Right = 12, Bottom = 0 })
        titleSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        fill(titleSlot)
        local summarySlot = addHorizontal(header, summary)
        summarySlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        local headerSlot = headerSurface:AddChild(header)
        headerSlot:SetHorizontalAlignment(0)
        headerSlot:SetVerticalAlignment(0)
        local surfaceSlot = headerBox:AddChild(headerSurface)
        surfaceSlot:SetHorizontalAlignment(0)
        surfaceSlot:SetVerticalAlignment(0)
        addVertical(stack, headerBox)
    end)
    return ok and stack or nil
end

local function createResultHeader(tree, titleValue, titleColor, helperValue, width)
    local headerBox = construct(tree, "/Script/UMG.SizeBox")
    local surface = construct(tree, "/Script/UMG.Border")
    local title = makeText(tree, titleValue, 17, titleColor,
        TEXT_JUSTIFY_CENTER, true)
    if headerBox == nil or surface == nil or title == nil then return nil end
    local headerHeight = DETAIL_HEADER_HEIGHT
    local helper
    local content = title
    if helperValue ~= nil then
        helper = makeText(tree, helperValue, 11, COLORS.muted,
            TEXT_JUSTIFY_CENTER, true)
        content = construct(tree, "/Script/UMG.VerticalBox")
        if helper == nil or content == nil then return nil end
        headerHeight = width < 720.0
            and DETAIL_HEADER_HELPER_NARROW_HEIGHT
            or DETAIL_HEADER_HELPER_HEIGHT
    end
    local ok = pcall(function()
        headerBox:SetHeightOverride(headerHeight)
        surface:SetBrushColor(COLORS.surfaceChrome)
        surface:SetPadding({ Left = 16, Top = 0, Right = 16, Bottom = 0 })
        if helper ~= nil then
            helper:SetAutoWrapText(true)
            helper.WrapTextAt = math.max(240.0, width - 64.0)
            local titleSlot = addVertical(content, title)
            titleSlot:SetHorizontalAlignment(SLOT_ALIGN_CENTER)
            local helperSlot = addVertical(content, helper,
                { Left = 0, Top = 4, Right = 0, Bottom = 0 })
            helperSlot:SetHorizontalAlignment(SLOT_ALIGN_CENTER)
        end
        local contentSlot = surface:AddChild(content)
        contentSlot:SetHorizontalAlignment(SLOT_ALIGN_CENTER)
        contentSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        local surfaceSlot = headerBox:AddChild(surface)
        surfaceSlot:SetHorizontalAlignment(0)
        surfaceSlot:SetVerticalAlignment(0)
    end)
    return ok and headerBox or nil, headerHeight
end

local function createResultFooter(tree, strings)
    local footerBox = construct(tree, "/Script/UMG.SizeBox")
    local surface = construct(tree, "/Script/UMG.Border")
    if footerBox == nil or surface == nil then return nil end

    local button
    local ok = pcall(function()
        footerBox:SetHeightOverride(DETAIL_FOOTER_HEIGHT)
        surface:SetBrushColor(COLORS.surfaceChrome)
        surface:SetPadding({ Left = 16, Top = 10, Right = 16, Bottom = 10 })
        local buttonBox = construct(tree, "/Script/UMG.SizeBox")
        button = construct(tree, "/Script/UMG.Button")
        local buttonLabel = makeText(tree,
            strings.confirm, 13, COLORS.textOnAccent,
            TEXT_JUSTIFY_CENTER, true)
        if buttonBox == nil or button == nil or buttonLabel == nil then
            error("result close-button controls are unavailable")
        end
        buttonBox:SetWidthOverride(240.0)
        buttonBox:SetHeightOverride(36.0)
        button.bIsFocusable = true
        styleActionButton(button)
        local labelSlot = button:AddChild(buttonLabel)
        labelSlot:SetHorizontalAlignment(SLOT_ALIGN_CENTER)
        labelSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        buttonBox:AddChild(button)
        button:SetVisibility(VIS_VISIBLE)
        local buttonSlot = surface:AddChild(buttonBox)
        buttonSlot:SetHorizontalAlignment(SLOT_ALIGN_CENTER)
        buttonSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        local surfaceSlot = footerBox:AddChild(surface)
        surfaceSlot:SetHorizontalAlignment(0)
        surfaceSlot:SetVerticalAlignment(0)
    end)
    if not ok then return nil end
    return footerBox, button
end

local function showCompact(controller, title, message, color)
    if not clear() then return nil end
    local widget, tree, _, _, createError = createOwnerWidget(controller)
    if widget == nil then warnOnce(createError); return nil end
    local layout = construct(tree, "/Script/UMG.VerticalBox")
    local titleText = makeText(tree, title, 14, color or COLORS.primary,
        TEXT_JUSTIFY_CENTER, true)
    local valueText = makeText(tree, message, 13, COLORS.text,
        TEXT_JUSTIFY_CENTER)
    local gap = createSpacer(tree, 1.0, 4.0)
    if layout == nil or titleText == nil or valueText == nil or gap == nil then
        pcall(function() widget:RemoveFromParent() end)
        warnOnce("status text cannot be created")
        return nil
    end
    addVertical(layout, titleText)
    addVertical(layout, gap)
    addVertical(layout, valueText)
    local framed, frameError = mountCompactFrame(
        widget, tree, layout, { titleText, valueText }, controller, color)
    if not framed then
        pcall(function() widget:RemoveFromParent() end)
        warnOnce(frameError)
        return nil
    end
    state.widget = widget
    state.token = state.token + 1
    return state.token
end

local function saleSkippedMessage(details, strings)
    local total = details.saleSkippedTotal or 0
    if total <= 0 then return nil end
    local noMerchant = details.saleSkippedReason == "no-merchant"
    local kept = details.saleSkippedDisposition == "backpack"
    local key = noMerchant and kept and "saleSkippedNoMerchantKept"
        or noMerchant and "saleSkippedNoMerchant"
        or "saleSkippedUnavailable"
    return Localization.format(strings, key, total)
end

local function detailedSectionSpecs(details, strings)
    local moved = type(details.moved) == "table" and details.moved or {}
    local sold = type(details.sold) == "table" and details.sold or {}
    local saleSkipped = type(details.saleSkipped) == "table"
        and details.saleSkipped or {}
    local excluded = type(details.excluded) == "table"
        and details.excluded or {}
    local full = type(details.full) == "table" and details.full or {}
    local movedTotal = details.movedTotal or 0
    local soldTotal = details.soldTotal or 0
    local saleSkippedTotal = details.saleSkippedTotal or 0
    local excludedTotal = details.excludedTotal or 0
    local fullTotal = details.fullTotal or 0
    local specs = {}

    if saleSkippedTotal > 0 and #saleSkipped > 0 then
        specs[#specs + 1] = {
            label = strings.saleSkippedSection,
            color = COLORS.warning,
            summary = Localization.format(strings, "countSummary",
                #saleSkipped, saleSkippedTotal),
            items = saleSkipped,
        }
    end
    if fullTotal > 0 and #full > 0 then
        specs[#specs + 1] = {
            label = strings.fullSection,
            color = COLORS.warning,
            summary = Localization.format(strings, "fullSummary",
                #full, fullTotal),
            items = full,
        }
    end
    if movedTotal > 0 and #moved > 0 then
        specs[#specs + 1] = {
            label = strings.movedSection,
            color = COLORS.primary,
            summary = Localization.format(strings, "countSummary",
                #moved, movedTotal),
            items = moved,
        }
    end
    if soldTotal > 0 and #sold > 0 then
        specs[#specs + 1] = {
            label = strings.soldSection,
            color = COLORS.primary,
            summary = Localization.format(strings, "countSummary",
                #sold, soldTotal),
            items = sold,
        }
    end
    if excludedTotal > 0 and #excluded > 0 then
        specs[#specs + 1] = {
            label = strings.excludedSection,
            color = COLORS.muted,
            summary = Localization.format(strings, "countSummary", #excluded,
                excludedTotal),
            items = excluded,
        }
    end
    return specs
end

local function resultTitle(outcome, details, strings)
    local movedTotal = details.movedTotal or 0
    local soldTotal = details.soldTotal or 0
    local fullTotal = details.fullTotal or 0
    local confirmedTotal = movedTotal + soldTotal
    if outcome == "stopped" then
        return strings.failureTitle, COLORS.danger
    end
    if details.saleConfirmationPending or outcome == "submitted" then
        return strings.attentionTitle, COLORS.warning
    end
    if outcome == "noop" then return strings.noopTitle, COLORS.text end
    if fullTotal > 0 then
        if confirmedTotal > 0 then
            return strings.partialSuccessTitle, COLORS.warning
        end
        return strings.failureTitle, COLORS.danger
    end
    if (details.saleSkippedTotal or 0) > 0 then
        if confirmedTotal > 0 then
            return strings.partialSuccessTitle, COLORS.warning
        end
        return strings.attentionTitle, COLORS.warning
    end
    return strings.successTitle, COLORS.success
end

local function detailedFallbackMessage(outcome, details, strings)
    local messages = {}
    if (details.soldTotal or 0) > 0 then
        messages[#messages + 1] = Localization.format(
            strings, "soldCompact", details.soldTotal)
    end
    if details.saleConfirmationPending then
        messages[#messages + 1] = Localization.format(
            strings, "saleSubmittedCompact", details.salePendingTotal or 0)
    end
    local saleSkipped = saleSkippedMessage(details, strings)
    if saleSkipped ~= nil then messages[#messages + 1] = saleSkipped end
    if (details.movedTotal or 0) > 0 and (details.fullTotal or 0) > 0 then
        messages[#messages + 1] = Localization.format(strings, "partialCompact",
            details.movedTotal, details.fullTotal)
    elseif (details.movedTotal or 0) > 0 then
        messages[#messages + 1] = Localization.format(
            strings, "completeCompact", details.movedTotal)
    elseif (details.fullTotal or 0) > 0 then
        messages[#messages + 1] = Localization.format(
            strings, "fullCompact", details.fullTotal)
    end
    if #messages > 0 then return table.concat(messages, "\n") end
    if outcome == "submitted" then return strings.submittedCompact end
    return strings.noop
end

local function scheduleClear(token, durationMs)
    if type(ExecuteInGameThreadWithDelay) ~= "function" then
        clear()
        return
    end
    local scheduled = pcall(ExecuteInGameThreadWithDelay, durationMs, function()
        if token == state.token then clear() end
    end)
    if not scheduled and token == state.token then clear() end
end

local function detailedBuildElapsedMs(startedAt)
    return math.max(0, (os.clock() - startedAt) * 1000)
end

local function recordDetailedBuildSlice(build, phase, startedAt)
    if not build.performanceCapture then return end
    local duration = detailedBuildElapsedMs(startedAt)
    build.performanceSlices = build.performanceSlices + 1
    build.performanceTotalMs = build.performanceTotalMs + duration
    if duration > build.performanceMaxSliceMs then
        build.performanceMaxSliceMs = duration
        build.performanceMaxPhase = phase
    end
end

local function logDetailedBuild(build, succeeded)
    if not build.performanceCapture or type(state.log) ~= "function" then return end
    state.log(table.concat({
        "perf_result_ui",
        "result=" .. (succeeded and "success" or "failed"),
        string.format("total_ms=%.3f", detailedBuildElapsedMs(build.startedAt)),
        "slices=" .. tostring(build.performanceSlices),
        string.format("work_ms=%.3f", build.performanceTotalMs),
        string.format("max_slice_ms=%.3f", build.performanceMaxSliceMs),
        "max_phase=" .. tostring(build.performanceMaxPhase or "none"),
        "sections=" .. tostring(build.specs ~= nil and #build.specs or 0),
        "visible_items=" .. tostring(build.visibleItems or 0),
    }, "|"))
end

local function discardDetailedBuild(build)
    if state.buildWidget == build.widget then state.buildWidget = nil end
    if P.isValid(build.widget) then
        pcall(function() build.widget:RemoveFromParent() end)
    end
    build.widget = nil
end

local function showDetailedBuildFallback(build, reason, expected)
    if build.failed then return end
    build.failed = true
    discardDetailedBuild(build)
    logDetailedBuild(build, false)
    if build.originToken ~= state.token then return end
    if expected ~= true then
        warnOnce(reason or "detailed result cannot be created")
    end
    local title, statusColor = resultTitle(
        build.outcome, build.details, build.strings)
    local token = showCompact(
        build.controller,
        title,
        detailedFallbackMessage(build.outcome, build.details, build.strings),
        statusColor)
    if token ~= nil then scheduleClear(token, COMPACT_DURATION_MS) end
end

local function setupDetailedBuild(build)
    local widget, tree, world, library, createError =
        createOwnerWidget(build.controller)
    if widget == nil then error(createError) end
    build.widget = widget
    state.buildWidget = widget
    build.tree = tree
    build.world = world
    build.library = library
    build.metrics = detailedMetrics(build.controller)
    build.specs = detailedSectionSpecs(build.details, build.strings)
    if #build.specs == 0 then error("detailed result content is empty") end

    local layout = construct(tree, "/Script/UMG.VerticalBox")
    local contentBox = construct(tree, "/Script/UMG.SizeBox")
    local contentSurface = construct(tree, "/Script/UMG.Border")
    local scroll = construct(tree, "/Script/UMG.ScrollBox")
    local bodyBox = construct(tree, "/Script/UMG.SizeBox")
    local body = construct(tree, "/Script/UMG.VerticalBox")
    if layout == nil or contentBox == nil or contentSurface == nil
        or scroll == nil or bodyBox == nil or body == nil then
        error("detailed result controls are unavailable")
    end

    local titleValue, titleColor = resultTitle(
        build.outcome, build.details, build.strings)
    local saleSkipped = saleSkippedMessage(build.details, build.strings)
    local headerHelper = saleSkipped
    if headerHelper == nil and (build.details.fullTotal or 0) > 0 then
        headerHelper = build.strings.fullHelper
    end
    local header, headerHeight = createResultHeader(
        tree, titleValue, titleColor, headerHelper, build.metrics.width)
    local footer, closeButton = createResultFooter(tree, build.strings)
    if header == nil or footer == nil then
        error("detailed result chrome is unavailable")
    end

    local bodyDesiredHeight = 0.0
    local visibleItems = 0
    for index, spec in ipairs(build.specs) do
        local top = index > 1 and 16.0 or 0.0
        bodyDesiredHeight = bodyDesiredHeight + top
            + sectionDesiredHeight(spec.items, build.metrics.columns)
        visibleItems = visibleItems + math.min(#spec.items, MAX_SECTION_ITEMS)
    end
    local maximumContentHeight = math.max(120.0,
        build.metrics.maxHeight - 2.0
            - headerHeight - DETAIL_FOOTER_HEIGHT)
    local contentHeight = math.min(
        bodyDesiredHeight + DETAIL_CONTENT_PADDING * 2.0
            + DETAIL_CONTENT_SLACK,
        maximumContentHeight)

    local ok = pcall(function()
        bodyBox:SetWidthOverride(build.metrics.bodyWidth)
        local bodySlot = bodyBox:AddChild(body)
        bodySlot:SetHorizontalAlignment(0)
        bodySlot:SetVerticalAlignment(0)

        scroll:SetAlwaysShowScrollbar(false)
        scroll.AlwaysShowScrollbarTrack = false
        scroll:SetScrollbarThickness({ X = 9.0, Y = 9.0 })
        scroll:SetScrollbarPadding(
            { Left = 2.0, Top = 2.0, Right = 2.0, Bottom = 2.0 })
        local scrollSlot = scroll:AddChild(bodyBox)
        scrollSlot:SetHorizontalAlignment(0)
        scrollSlot:SetVerticalAlignment(0)

        contentSurface:SetBrushColor(COLORS.surfaceContent)
        contentSurface:SetPadding({
            Left = DETAIL_CONTENT_PADDING,
            Top = DETAIL_CONTENT_PADDING,
            Right = DETAIL_CONTENT_PADDING,
            Bottom = DETAIL_CONTENT_PADDING,
        })
        local contentScrollSlot = contentSurface:AddChild(scroll)
        contentScrollSlot:SetHorizontalAlignment(0)
        contentScrollSlot:SetVerticalAlignment(0)
        contentBox:SetHeightOverride(contentHeight)
        local contentSurfaceSlot = contentBox:AddChild(contentSurface)
        contentSurfaceSlot:SetHorizontalAlignment(0)
        contentSurfaceSlot:SetVerticalAlignment(0)

        addVertical(layout, header)
        addVertical(layout, contentBox)
        addVertical(layout, footer)
    end)
    if not ok then error("detailed result layout cannot be initialized") end

    build.layout = layout
    build.body = body
    build.closeButton = closeButton
    build.contentHeight = contentHeight
    build.height = 2.0 + headerHeight
        + contentHeight + DETAIL_FOOTER_HEIGHT
    build.specIndex = 1
    build.itemIndex = 1
    build.section = nil
    build.overflowDone = false
    build.visibleItems = visibleItems
end

local function mountDetailedBuild(build)
    state.buildWidget = nil
    local framed, frameError = mountDetailedFrame(
        build.widget, build.tree, build.layout,
        build.metrics.width, build.height)
    if not framed then error(frameError) end
    if not clear() then
        error("existing result input ownership cannot be released")
    end
    state.widget = build.widget
    state.detailVisible = true
    state.closeButton = build.closeButton
    local dialogToken = state.token
    local acquired, acquireError, retainedTransaction = ResultDialogBridge.acquire(
        build.controller, build.widget, function()
            if state.token == dialogToken and state.detailVisible then clear() end
        end)
    state.inputOwned = acquired == true or retainedTransaction == true
    local closeBound = acquired
        and ResultDialogBridge.bindCloseButton(state.closeButton)
    if not acquired or not closeBound then
        if retainedTransaction ~= true then
            retainedTransaction = clear() ~= true
        end
        if retainedTransaction == true then
            build.widget = nil
            ResultDialogBridge.focusCloseButton()
            logWarning("result dialog input acquisition failed: ",
                tostring(acquireError or "close-button bridge is unavailable")
                    .. "; modal transaction retained")
            return true
        end
        -- Keep the compact fallback eligible after the mounted candidate and
        -- its partial input lease have been rolled back.
        build.originToken = state.token
        error(acquireError or "result close-button bridge is unavailable")
    end
    ResultDialogBridge.focusCloseButton()
    build.widget = nil
    return true
end

local function advanceDetailedBuild(build)
    while true do
        if build.specIndex > #build.specs then
            local mounted = mountDetailedBuild(build)
            return true, mounted and "mount" or "compact-fallback"
        end

        local spec = build.specs[build.specIndex]
        if build.section == nil then
            local section = createResultSectionFrame(
                build.tree, spec, build.metrics)
            if section == nil then error("detailed result section cannot be created") end
            local top = build.specIndex > 1 and 16.0 or 0.0
            addVertical(build.body, section,
                { Left = 0, Top = top, Right = 0, Bottom = 0 })
            build.section = section
            build.itemIndex = 1
            build.overflowDone = false
            return false, "section"
        end

        local shown = math.min(#spec.items, MAX_SECTION_ITEMS)
        if build.itemIndex <= shown then
            local nextIndex, rowError = appendItemGridRow(
                build.section,
                build.tree,
                build.world,
                build.library,
                build.controller,
                spec.items,
                build.metrics,
                build.itemIndex)
            if nextIndex == nil then error(rowError) end
            build.itemIndex = nextIndex
            return false, "row"
        end

        if not build.overflowDone and #spec.items > shown then
            if not appendItemGridOverflow(
                    build.section, build.tree, spec.items, build.strings) then
                error("detailed result overflow label cannot be created")
            end
            build.overflowDone = true
            return false, "overflow"
        end

        build.specIndex = build.specIndex + 1
        build.section = nil
    end
end

local runDetailedBuildSlice

local function scheduleDetailedBuildSlice(build)
    if build.originToken ~= state.token then return false end
    if type(ExecuteInGameThreadWithDelay) ~= "function" then return false end
    local scheduled = pcall(ExecuteInGameThreadWithDelay,
        DETAIL_BUILD_SLICE_MS, function() runDetailedBuildSlice(build) end)
    return scheduled
end

runDetailedBuildSlice = function(build)
    if build.originToken ~= state.token then return end
    local phase = build.widget == nil and "setup" or "unknown"
    local startedAt = os.clock()
    local done = false
    local ok, errorMessage = pcall(function()
        if build.widget == nil then
            setupDetailedBuild(build)
        else
            done, phase = advanceDetailedBuild(build)
        end
    end)
    recordDetailedBuildSlice(build, phase, startedAt)
    if not ok then
        showDetailedBuildFallback(build, errorMessage)
        return
    end
    if done then
        if not build.failed then logDetailedBuild(build, true) end
        return
    end
    if not scheduleDetailedBuildSlice(build) then
        showDetailedBuildFallback(build, "detailed result build cannot be scheduled")
    end
end

local function startDetailedBuild(controller, outcome, details, strings)
    if type(ExecuteInGameThreadWithDelay) ~= "function" then return false end
    local build = {
        controller = controller,
        outcome = outcome,
        details = details,
        strings = strings,
        originToken = state.token,
        performanceCapture = details.performanceCapture == true,
        startedAt = os.clock(),
        performanceSlices = 0,
        performanceTotalMs = 0,
        performanceMaxSliceMs = 0,
        performanceMaxPhase = nil,
        failed = false,
    }
    return scheduleDetailedBuildSlice(build)
end

function Notifications.configure(logger, performanceCapture)
    state.log = logger
    state.performanceCapture = performanceCapture == true
    ResultDialogBridge.configure(logger)
    scheduleStaticObjectWarmup(STATIC_WARMUP_START_MS)
end

function Notifications.started(controller)
    local strings = Localization.current()
    local token = showCompact(
        controller, strings.processingTitle, strings.started, COLORS.primary)
    return token
end

function Notifications.finished(controller, _startToken, outcome,
        requestCount, itemCount, details, detailedResultRequested)
    local strings = Localization.current()
    details = type(details) == "table" and details or {
        moved = {}, movedTotal = 0,
        sold = {}, soldTotal = 0,
        saleSkippedReason = nil, saleSkippedDisposition = nil,
        saleSkipped = {}, saleSkippedTotal = 0,
        excluded = {}, excludedTotal = 0,
        full = {}, fullTotal = 0,
    }
    local hasDetailedResult = outcome ~= "stopped" and (
        (details.movedTotal or 0) > 0
        or (details.soldTotal or 0) > 0
        or (details.fullTotal or 0) > 0
        or (details.saleSkippedTotal or 0) > 0)
    local showDetails = detailedResultRequested == true and hasDetailedResult
        and not details.saleConfirmationPending
        and ResultDialogBridge.available()
    local token
    local detailed = false
    local title, statusColor = resultTitle(outcome, details, strings)
    if showDetails then
        detailed = startDetailedBuild(controller, outcome, details, strings)
        if not detailed then
            token = showCompact(controller,
                title,
                detailedFallbackMessage(outcome, details, strings),
                statusColor)
        end
    elseif hasDetailedResult then
        token = showCompact(controller,
            title,
            detailedFallbackMessage(outcome, details, strings),
            statusColor)
    else
        local message
        local saleSkipped = saleSkippedMessage(details, strings)
        if saleSkipped ~= nil then
            message = saleSkipped
        elseif outcome == "complete" then
            message = Localization.format(strings, "completeContainers",
                itemCount or 0, requestCount or 0)
        elseif outcome == "submitted" then
            if details.saleConfirmationPending then
                message = Localization.format(strings, "saleSubmittedCompact",
                    details.salePendingTotal or 0)
            else
                message = strings.submittedCompact
            end
        elseif outcome == "noop" then
            message = strings.noop
        else
            message = strings.stopped
        end
        token = showCompact(controller, title, message, statusColor)
    end
    if token ~= nil then
        scheduleClear(token, COMPACT_DURATION_MS)
    end
end

return Notifications
