local P = require("palworld")
local Localization = require("localization")

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
local DETAIL_FOOTER_HEIGHT = 56.0
local DETAIL_CONTENT_PADDING = 16.0
local DETAIL_SCROLLBAR_GUTTER = 13.0
local DETAIL_CONTENT_SLACK = 8.0
local DETAIL_ITEM_COLUMN_GAP = 12.0
local DETAIL_ITEM_ROW_GAP = 4.0
local ITEM_NATIVE_MIN_WIDTH = 360.0
local ITEM_ROW_HEIGHT = 34.0
local ITEM_COUNT_WIDTH = 68.0
local SECTION_HEADER_HEIGHT = 36.0
local COMPACT_DURATION_MS = 2000
local DETAIL_DURATION_SECONDS = 3
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

local COLORS = {
    primary = { R = 0.209, G = 0.533, B = 0.665, A = 1.00 },
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
    detailVisible = false,
    closeInputAvailable = false,
    closeButton = nil,
    countdownText = nil,
    itemRowClass = nil,
    itemRowLoadAttempts = 0,
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

local function construct(tree, classPath)
    local classObject = P.staticObject(classPath)
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
    state.token = state.token + 1
    if P.isValid(state.widget) then
        pcall(function() state.widget:RemoveFromParent() end)
    end
    state.widget = nil
    state.detailVisible = false
    state.closeButton = nil
    state.countdownText = nil
end

local function creationRoots(controller)
    if not P.isValid(controller) then
        return nil, nil, nil, "local controller is unavailable"
    end
    local world
    local ok = pcall(function() world = controller:GetWorld() end)
    local library = P.staticObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    local userWidgetClass = P.staticObject("/Script/UMG.UserWidget")
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
    local layoutLibrary = P.staticObject(
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

local function mountCompactFrame(widget, tree, content, controller, color)
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
        content:SetAutoWrapText(false)
        content.WrapTextAt = metrics.textWidth

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
            - DETAIL_SCROLLBAR_GUTTER)
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
    local sizeBox = construct(tree, "/Script/UMG.SizeBox")
    local outline = construct(tree, "/Script/UMG.Border")
    local surface = construct(tree, "/Script/UMG.Border")
    if root == nil or sizeBox == nil or outline == nil or surface == nil then
        return false, "detailed result frame controls are unavailable"
    end
    local ok = pcall(function()
        tree.RootWidget = root
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

        local slot = root:AddChild(sizeBox)
        slot:SetAnchors({
            Minimum = { X = 0.5, Y = 0.5 },
            Maximum = { X = 0.5, Y = 0.5 },
        })
        slot:SetAlignment({ X = 0.5, Y = 0.5 })
        slot:SetAutoSize(false)
        slot:SetPosition({ X = 0.0, Y = 0.0 })
        slot:SetSize({ X = width, Y = height })
        slot:SetZOrder(0)
        widget.bIsFocusable = false
        root:SetVisibility(VIS_SELF_HIT_TEST_INVISIBLE)
        sizeBox:SetVisibility(VIS_SELF_HIT_TEST_INVISIBLE)
        outline:SetVisibility(VIS_SELF_HIT_TEST_INVISIBLE)
        surface:SetVisibility(VIS_SELF_HIT_TEST_INVISIBLE)
        content:SetVisibility(VIS_SELF_HIT_TEST_INVISIBLE)
        widget:SetVisibility(VIS_SELF_HIT_TEST_INVISIBLE)
        widget:AddToViewport(20)
    end)
    if not ok then return false, "detailed result frame cannot be initialized" end
    return true, nil
end

local function prepareItemRowClass(allowLoad)
    if P.isValid(state.itemRowClass) then return state.itemRowClass end
    state.itemRowClass = P.staticObject(ITEM_ROW_CLASS_PATH)
    if P.isValid(state.itemRowClass) then return state.itemRowClass end
    if allowLoad and state.itemRowLoadAttempts < 2
        and type(LoadAsset) == "function" then
        state.itemRowLoadAttempts = state.itemRowLoadAttempts + 1
        pcall(LoadAsset, ITEM_ROW_ASSET_PATH)
        state.itemRowClass = P.staticObject(ITEM_ROW_CLASS_PATH)
    end
    return P.isValid(state.itemRowClass) and state.itemRowClass or nil
end

local function scheduleItemRowWarmup(delayMs)
    if prepareItemRowClass(false) ~= nil
        or type(ExecuteWithDelay) ~= "function"
        or type(ExecuteInGameThread) ~= "function" then return end
    pcall(ExecuteWithDelay, delayMs or 0, function()
        ExecuteInGameThread(function() prepareItemRowClass(true) end)
    end)
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
        surface:SetPadding({ Left = 4, Top = 0, Right = 8, Bottom = 0 })
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

local function appendItemGrid(stack, tree, world, library, controller,
        items, metrics, strings)
    local shown = math.min(#items, MAX_SECTION_ITEMS)
    local index = 1
    while index <= shown do
        local row = construct(tree, "/Script/UMG.HorizontalBox")
        if row == nil then return false end
        for column = 1, metrics.columns do
            local item = items[index]
            local cell = item ~= nil and createItemRow(
                tree, world, library, controller, item, metrics.itemWidth)
                or createSpacer(tree, metrics.itemWidth, ITEM_ROW_HEIGHT)
            if cell == nil then return false end
            addHorizontal(row, cell)
            if column < metrics.columns then
                local gap = createSpacer(tree, DETAIL_ITEM_COLUMN_GAP, 1.0)
                if gap == nil then return false end
                addHorizontal(row, gap)
            end
            index = index + 1
        end
        addVertical(stack, row,
            { Left = 0, Top = DETAIL_ITEM_ROW_GAP, Right = 0, Bottom = 0 })
    end
    if #items > shown then
        local overflow = makeText(tree,
            Localization.format(strings, "overflow", #items - shown),
            12, COLORS.subtle, 0, true)
        if overflow == nil then return false end
        addVertical(stack, overflow,
            { Left = 12, Top = 8, Right = 0, Bottom = 0 })
    end
    return true
end

local function sectionDesiredHeight(items, columns, helper)
    local shown = math.min(#items, MAX_SECTION_ITEMS)
    local rows = shown > 0 and math.ceil(shown / columns) or 0
    local height = SECTION_HEADER_HEIGHT
        + rows * (ITEM_ROW_HEIGHT + DETAIL_ITEM_ROW_GAP)
    if helper ~= nil then height = height + 24.0 end
    if #items > shown then height = height + 24.0 end
    return height
end

local function createResultSection(tree, world, library, controller,
        spec, metrics, strings)
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

        if spec.helper ~= nil then
            local helper = makeText(tree, spec.helper,
                12, COLORS.muted, 0, true)
            if helper == nil then error("result helper text is unavailable") end
            addVertical(stack, helper,
                { Left = 12, Top = 8, Right = 12, Bottom = 0 })
        end
        if not appendItemGrid(stack, tree, world, library, controller,
                spec.items, metrics, strings) then
            error("result item grid is unavailable")
        end
    end)
    return ok and stack or nil
end

local function createResultHeader(tree, titleValue, titleColor)
    local headerBox = construct(tree, "/Script/UMG.SizeBox")
    local surface = construct(tree, "/Script/UMG.Border")
    local title = makeText(tree, titleValue, 17, titleColor,
        TEXT_JUSTIFY_CENTER, true)
    if headerBox == nil or surface == nil or title == nil then return nil end
    local ok = pcall(function()
        headerBox:SetHeightOverride(DETAIL_HEADER_HEIGHT)
        surface:SetBrushColor(COLORS.surfaceChrome)
        surface:SetPadding({ Left = 16, Top = 0, Right = 16, Bottom = 0 })
        local titleSlot = surface:AddChild(title)
        titleSlot:SetHorizontalAlignment(SLOT_ALIGN_CENTER)
        titleSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        local surfaceSlot = headerBox:AddChild(surface)
        surfaceSlot:SetHorizontalAlignment(0)
        surfaceSlot:SetVerticalAlignment(0)
    end)
    return ok and headerBox or nil
end

local function createResultFooter(tree, strings)
    local footerBox = construct(tree, "/Script/UMG.SizeBox")
    local surface = construct(tree, "/Script/UMG.Border")
    local actions = construct(tree, "/Script/UMG.HorizontalBox")
    local countdown = makeText(tree,
        Localization.format(strings, "countdown", DETAIL_DURATION_SECONDS),
        12, COLORS.muted, 0, true)
    if footerBox == nil or surface == nil or actions == nil
        or countdown == nil then return nil end

    local button
    local ok = pcall(function()
        footerBox:SetHeightOverride(DETAIL_FOOTER_HEIGHT)
        surface:SetBrushColor(COLORS.surfaceChrome)
        surface:SetPadding({ Left = 16, Top = 10, Right = 16, Bottom = 10 })
        local countdownSlot = addHorizontal(actions, countdown,
            { Left = 0, Top = 0, Right = 12, Bottom = 0 })
        countdownSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
        fill(countdownSlot)
        if state.closeInputAvailable then
            local buttonBox = construct(tree, "/Script/UMG.SizeBox")
            button = construct(tree, "/Script/UMG.Button")
            local buttonLabel = makeText(tree,
                strings.confirm, 13, COLORS.textOnAccent,
                TEXT_JUSTIFY_CENTER, true)
            if buttonBox == nil or button == nil or buttonLabel == nil then
                error("result close-button controls are unavailable")
            end
            buttonBox:SetWidthOverride(120.0)
            buttonBox:SetHeightOverride(36.0)
            button.bIsFocusable = false
            styleActionButton(button)
            local labelSlot = button:AddChild(buttonLabel)
            labelSlot:SetHorizontalAlignment(SLOT_ALIGN_CENTER)
            labelSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
            buttonBox:AddChild(button)
            local buttonSlot = addHorizontal(actions, buttonBox)
            buttonSlot:SetVerticalAlignment(SLOT_ALIGN_CENTER)
            button:SetVisibility(VIS_VISIBLE)
        end
        local actionsSlot = surface:AddChild(actions)
        actionsSlot:SetHorizontalAlignment(0)
        actionsSlot:SetVerticalAlignment(0)
        local surfaceSlot = footerBox:AddChild(surface)
        surfaceSlot:SetHorizontalAlignment(0)
        surfaceSlot:SetVerticalAlignment(0)
    end)
    if not ok then return nil end
    return footerBox, button, countdown
end

local function showCompact(controller, message, color)
    clear()
    local widget, tree, _, _, createError = createOwnerWidget(controller)
    if widget == nil then warnOnce(createError); return nil end
    local valueText = makeText(tree, message, 13, COLORS.text,
        TEXT_JUSTIFY_CENTER)
    if valueText == nil then
        pcall(function() widget:RemoveFromParent() end)
        warnOnce("status text cannot be created")
        return nil
    end
    local framed, frameError = mountCompactFrame(
        widget, tree, valueText, controller, color)
    if not framed then
        pcall(function() widget:RemoveFromParent() end)
        warnOnce(frameError)
        return nil
    end
    state.widget = widget
    state.token = state.token + 1
    return state.token
end

local function detailedSectionSpecs(details, strings)
    local moved = type(details.moved) == "table" and details.moved or {}
    local excluded = type(details.excluded) == "table"
        and details.excluded or {}
    local full = type(details.full) == "table" and details.full or {}
    local movedTotal = details.movedTotal or 0
    local excludedTotal = details.excludedTotal or 0
    local fullTotal = details.fullTotal or 0
    local specs = {}

    if fullTotal > 0 and #full > 0 then
        specs[#specs + 1] = {
            label = strings.fullSection,
            color = COLORS.warning,
            summary = Localization.format(strings, "fullSummary",
                #full, fullTotal),
            helper = strings.fullHelper,
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

local function showDetailed(controller, outcome, details, strings)
    clear()
    local widget, tree, world, library, createError = createOwnerWidget(controller)
    if widget == nil then warnOnce(createError); return nil end
    local metrics = detailedMetrics(controller)
    local specs = detailedSectionSpecs(details, strings)
    local layout = construct(tree, "/Script/UMG.VerticalBox")
    local contentBox = construct(tree, "/Script/UMG.SizeBox")
    local contentSurface = construct(tree, "/Script/UMG.Border")
    local scroll = construct(tree, "/Script/UMG.ScrollBox")
    local bodyBox = construct(tree, "/Script/UMG.SizeBox")
    local body = construct(tree, "/Script/UMG.VerticalBox")
    if layout == nil or contentBox == nil or contentSurface == nil
        or scroll == nil or bodyBox == nil or body == nil then
        pcall(function() widget:RemoveFromParent() end)
        warnOnce("detailed result controls are unavailable")
        return nil
    end

    local movedTotal = details.movedTotal or 0
    local fullTotal = details.fullTotal or 0
    local titleValue
    local titleColor = COLORS.text
    if fullTotal > 0 and movedTotal > 0 then
        titleValue = strings.partialTitle
        titleColor = COLORS.warning
    elseif fullTotal > 0 then
        titleValue = strings.failedTitle
        titleColor = COLORS.warning
    elseif outcome == "submitted" then
        titleValue = strings.submittedTitle
    else
        titleValue = strings.completeTitle
    end
    local header = createResultHeader(tree, titleValue, titleColor)
    if header == nil or #specs == 0 then
        pcall(function() widget:RemoveFromParent() end)
        warnOnce("detailed result content cannot be created")
        return nil
    end

    local bodyDesiredHeight = 0.0
    local ok = pcall(function()
        for index, spec in ipairs(specs) do
            local section = createResultSection(
                tree, world, library, controller, spec, metrics, strings)
            if section == nil then
                error("detailed result section cannot be created")
            end
            local top = index > 1 and 16.0 or 0.0
            addVertical(body, section,
                { Left = 0, Top = top, Right = 0, Bottom = 0 })
            bodyDesiredHeight = bodyDesiredHeight + top
                + sectionDesiredHeight(
                    spec.items, metrics.columns, spec.helper)
        end
    end)
    local footer
    local closeButton
    local countdownText
    if ok then
        footer, closeButton, countdownText = createResultFooter(tree, strings)
        ok = footer ~= nil
    end
    local maximumContentHeight = math.max(120.0,
        metrics.maxHeight - 2.0 - DETAIL_HEADER_HEIGHT - DETAIL_FOOTER_HEIGHT)
    local contentHeight = math.min(
        bodyDesiredHeight + DETAIL_CONTENT_PADDING * 2.0
            + DETAIL_CONTENT_SLACK,
        maximumContentHeight)
    local height = 2.0 + DETAIL_HEADER_HEIGHT
        + contentHeight + DETAIL_FOOTER_HEIGHT
    local framed, frameError = false, "detailed result cannot be initialized"
    if ok then
        ok = pcall(function()
            bodyBox:SetWidthOverride(metrics.bodyWidth)
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
    end
    if ok then
        framed, frameError = mountDetailedFrame(
            widget, tree, layout, metrics.width, height)
    end
    if not framed then
        pcall(function() widget:RemoveFromParent() end)
        warnOnce(frameError)
        return nil
    end
    state.widget = widget
    state.detailVisible = true
    state.closeButton = closeButton
    state.countdownText = countdownText
    state.token = state.token + 1
    return state.token
end

local function scheduleClear(token, durationMs)
    if type(ExecuteWithDelay) ~= "function"
        or type(ExecuteInGameThread) ~= "function" then
        clear()
        return
    end
    local scheduled = pcall(ExecuteWithDelay, durationMs, function()
        ExecuteInGameThread(function()
            if token == state.token then clear() end
        end)
    end)
    if not scheduled and token == state.token then clear() end
end

local function scheduleDetailedCountdown(token, strings)
    if type(ExecuteWithDelay) ~= "function"
        or type(ExecuteInGameThread) ~= "function" then
        clear()
        return
    end
    local remaining = DETAIL_DURATION_SECONDS
    local function scheduleTick()
        local scheduled = pcall(ExecuteWithDelay, 1000, function()
            ExecuteInGameThread(function()
                if token ~= state.token or not state.detailVisible then return end
                remaining = remaining - 1
                if remaining <= 0 then
                    clear()
                    return
                end
                if P.isValid(state.countdownText) then
                    local updated = pcall(function()
                        state.countdownText:SetText(FText(Localization.format(
                            strings, "countdown", remaining)))
                    end)
                    if not updated then
                        clear()
                        return
                    end
                end
                scheduleTick()
            end)
        end)
        if not scheduled and token == state.token then clear() end
    end
    scheduleTick()
end

function Notifications.configure(logger)
    state.log = logger
    scheduleItemRowWarmup(3000)
end

function Notifications.setCloseInputAvailable(available)
    state.closeInputAvailable = available == true
end

function Notifications.hasInteractiveResult()
    return state.closeInputAvailable and state.detailVisible
end

function Notifications.closeIfHovered()
    if not state.closeInputAvailable or not state.detailVisible
        or not P.isValid(state.closeButton) then return false end
    local hovered
    local ok = pcall(function() hovered = state.closeButton:IsHovered() end)
    if not ok or hovered ~= true then return false end
    clear()
    return true
end

function Notifications.started(controller)
    local strings = Localization.current()
    local token = showCompact(
        controller, strings.started, COLORS.primary)
    scheduleItemRowWarmup(0)
    return token
end

function Notifications.finished(controller, _startToken, outcome,
        requestCount, itemCount, details)
    local strings = Localization.current()
    details = type(details) == "table" and details or {
        moved = {}, movedTotal = 0,
        excluded = {}, excludedTotal = 0,
        full = {}, fullTotal = 0,
    }
    local showDetails = outcome ~= "stopped" and (
        (details.movedTotal or 0) > 0
        or (details.fullTotal or 0) > 0)
    local token
    local detailed = false
    if showDetails then
        token = showDetailed(controller, outcome, details, strings)
        detailed = token ~= nil
        if token == nil then
            local fallback
            if outcome == "submitted" then
                fallback = strings.submittedCompact
            elseif (details.movedTotal or 0) > 0
                and (details.fullTotal or 0) > 0 then
                fallback = Localization.format(strings, "partialCompact",
                    details.movedTotal, details.fullTotal)
            elseif (details.movedTotal or 0) > 0 then
                fallback = Localization.format(strings, "completeCompact",
                    details.movedTotal)
            else
                fallback = Localization.format(strings, "fullCompact",
                    details.fullTotal or 0)
            end
            token = showCompact(controller, fallback,
                (details.fullTotal or 0) > 0 and COLORS.warning or COLORS.primary)
        end
    else
        local message
        local color = COLORS.primary
        if outcome == "complete" then
            message = Localization.format(strings, "completeContainers",
                itemCount or 0, requestCount or 0)
        elseif outcome == "submitted" then
            message = strings.submittedCompact
        elseif outcome == "noop" then
            message = strings.noop
            color = COLORS.warning
        else
            message = strings.stopped
            color = COLORS.danger
        end
        token = showCompact(controller, message, color)
    end
    if token ~= nil then
        if detailed then
            scheduleDetailedCountdown(token, strings)
        else
            scheduleClear(token, COMPACT_DURATION_MS)
        end
    end
end

return Notifications
