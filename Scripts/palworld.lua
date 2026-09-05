local UEHelpers = require("UEHelpers")

local Palworld = {
    ZERO_GUID = "00000000-00000000-00000000-00000000",
}

local STORAGE_CLASS_PATHS = {
    "/Script/Pal.PalMapObjectItemStorageModel",
    "/Script/Pal.PalMapObjectItemChestModel",
    "/Script/Pal.PalMapObjectSupplyStorageModel",
    "/Script/Pal.PalMapObjectPalFoodBoxModel",
}

local INCUBATOR_CLASS_PATH = "/Script/Pal.PalMapObjectHatchingEggModelBase"
local SMALL_INCUBATOR_CLASS_PATH = "/Script/Pal.PalMapObjectHatchingEggModel"
local GUILD_CHEST_CLASS_PATH = "/Script/Pal.PalMapObjectGuildChestModel"
local MEDICINE_RACK_CLASS_PATH = "/Script/Pal.PalMapObjectPalMedicineBoxModel"
local RECYCLER_CLASS_PATH = "/Script/Pal.PalMapObjectRecyclerModel"

local MAIN_MENU_CLASS_PATH =
    "/Game/Pal/Blueprint/UI/InGameMainMenu/WBP_InGameMainMenu.WBP_InGameMainMenu_C"
local MAIN_MENU_CLASS_NAME = "WBP_InGameMainMenu_C"
local CLIENT_RESTART_FUNCTION = "/Script/Engine.PlayerController:ClientRestart"
local INVENTORY_DISPLAY_CLASS_PATH =
    "/Game/Pal/Blueprint/UI/Inventory/WBP_InventoryEquipment_ForDisplay.WBP_InventoryEquipment_ForDisplay_C"

local inputUi = {
    mainMenu = nil,
    mainMenuAddress = nil,
    inventoryDisplayClass = nil,
    trackingReady = false,
    worldReadyCallback = nil,
    worldReadyHookPreCallback = nil,
    worldReadyHookCallback = nil,
    worldReadyHookPreId = nil,
    worldReadyHookPostId = nil,
    worldReadyTrackingReady = false,
}

function Palworld.isValid(object)
    if object == nil then return false end
    local ok, result = pcall(function() return object:IsValid() end)
    return ok and result == true
end

function Palworld.objectAddress(object)
    if not Palworld.isValid(object) then return nil end
    local ok, address = pcall(function() return object:GetAddress() end)
    if not ok or type(address) ~= "number" or address == 0 then return nil end
    return address
end

function Palworld.staticObject(path)
    local ok, object = pcall(StaticFindObject, path)
    if not ok or not Palworld.isValid(object) then return nil end
    return object
end

function Palworld.guidParts(value)
    if value == nil then return nil end
    local ok, parts = pcall(function()
        return { A = value.A, B = value.B, C = value.C, D = value.D }
    end)
    if not ok or parts.A == nil or parts.B == nil
        or parts.C == nil or parts.D == nil then return nil end
    return parts
end

function Palworld.guidKey(parts)
    if type(parts) ~= "table" or parts.A == nil then return nil end
    local function unsigned32(value)
        value = tonumber(value)
        if value == nil then return nil end
        if value < 0 then return value + 4294967296 end
        return value
    end
    local a = unsigned32(parts.A)
    local b = unsigned32(parts.B)
    local c = unsigned32(parts.C)
    local d = unsigned32(parts.D)
    if a == nil or b == nil or c == nil or d == nil then return nil end
    return string.format("%08X-%08X-%08X-%08X", a, b, c, d)
end

function Palworld.arrayLength(array)
    if array == nil then return nil end
    local ok, count = pcall(function() return array:GetArrayNum() end)
    if not ok or type(count) ~= "number" then
        ok, count = pcall(function() return #array end)
    end
    if not ok or type(count) ~= "number" or count < 0 then return nil end
    return math.floor(count)
end

function Palworld.arrayValue(array, index)
    local ok, value = pcall(function() return array[index] end)
    if not ok then return nil, false end
    return value, true
end

function Palworld.nameString(value)
    if value == nil then return nil end
    if type(value) == "string" then
        return value ~= "" and value or nil
    end
    local ok, result = pcall(function() return value:ToString() end)
    if not ok or type(result) ~= "string" or result == "" then return nil end
    return result
end

function Palworld.unwrap(value)
    if value == nil then return nil end
    local ok, result = pcall(function() return value:get() end)
    if ok and result ~= nil then return result end
    return value
end

function Palworld.enumValue(value)
    value = Palworld.unwrap(value)
    if type(value) == "number" then return value end
    local converted = tonumber(tostring(value))
    if type(converted) ~= "number" then return nil end
    return converted
end

local function booleanValue(value)
    value = Palworld.unwrap(value)
    if type(value) == "boolean" then return value end
    if type(value) == "number" then return value ~= 0 end
    return nil
end

function Palworld.readNameSet(array)
    local count = Palworld.arrayLength(array)
    if count == nil then return nil, "name array is unreadable" end
    local out = {}
    for index = 1, count do
        local raw, readable = Palworld.arrayValue(array, index)
        if not readable then return nil, "name array entry is unreadable" end
        local name = Palworld.nameString(Palworld.unwrap(raw))
        if name == nil then return nil, "name array entry cannot be decoded" end
        if name ~= "None" then out[name] = true end
    end
    return out, nil
end

function Palworld.readEnumSet(array)
    local count = Palworld.arrayLength(array)
    if count == nil then return nil, "enum array is unreadable" end
    local out = {}
    for index = 1, count do
        local raw, readable = Palworld.arrayValue(array, index)
        if not readable then return nil, "enum array entry is unreadable" end
        local value = Palworld.enumValue(raw)
        if value == nil then return nil, "enum array entry cannot be decoded" end
        out[value] = true
    end
    return out, nil
end

function Palworld.isEggId(staticId)
    return type(staticId) == "string" and staticId:find("^PalEgg") ~= nil
end

function Palworld.containerGuid(container)
    local parts
    local ok = pcall(function() parts = Palworld.guidParts(container.ID.ID) end)
    if not ok then return nil, nil end
    return parts, Palworld.guidKey(parts)
end

function Palworld.slotGuid(slot)
    local parts
    local ok = pcall(function() parts = Palworld.guidParts(slot.ContainerId.ID) end)
    if not ok then return nil, nil end
    return parts, Palworld.guidKey(parts)
end

function Palworld.slotStaticId(slot)
    local raw
    local ok = pcall(function() raw = slot.ItemId.StaticId end)
    if not ok or raw == nil then return nil, nil end
    return Palworld.nameString(raw), raw
end

local function isLocalController(controller)
    if not Palworld.isValid(controller) then return false end
    local ok, result = pcall(function()
        return controller:IsLocalPlayerController()
    end)
    return ok and result == true
end

local cachedController

function Palworld.currentController()
    if isLocalController(cachedController) then return cachedController end
    cachedController = nil

    if type(FindFirstOf) == "function" then
        local found, controller = pcall(FindFirstOf, "PlayerController")
        if found and isLocalController(controller) then
            cachedController = controller
            return controller
        end
    end

    local ok, controller = pcall(UEHelpers.GetPlayerController)
    if not ok or not isLocalController(controller) then return nil end
    cachedController = controller
    return controller
end

function Palworld.currentGameplayContext(controller)
    -- Title and loading maps may already own a local controller. Require the
    -- possessed player objects in one live world, but do not wait for later
    -- player-identity replication after gameplay becomes interactive.
    controller = controller or Palworld.currentController()
    if not isLocalController(controller) then return nil end

    local pawn
    local playerState
    local controllerWorld
    local pawnWorld
    local readable = pcall(function()
        pawn = controller.Pawn
        playerState = controller.PlayerState
        controllerWorld = controller:GetWorld()
        pawnWorld = pawn:GetWorld()
    end)
    local controllerWorldAddress = readable
        and Palworld.objectAddress(controllerWorld) or nil
    if not readable or not Palworld.isValid(pawn)
        or not Palworld.isValid(playerState)
        or controllerWorldAddress == nil
        or Palworld.objectAddress(pawnWorld) ~= controllerWorldAddress then
        return nil
    end

    return {
        controller = controller,
    }
end

function Palworld.installWorldReadyTracking(onWorldReady)
    if type(onWorldReady) ~= "function" then
        return false, "world lifecycle callback must be a function"
    end
    inputUi.worldReadyCallback = onWorldReady
    if inputUi.worldReadyTrackingReady then return true, nil end
    if type(RegisterHook) ~= "function" then
        return false, "UE4SS hook API is unavailable"
    end
    inputUi.worldReadyHookPreCallback = function() end
    inputUi.worldReadyHookCallback = function(context)
        local controller = Palworld.unwrap(context)
        if not isLocalController(controller) then return end
        cachedController = controller
        pcall(inputUi.worldReadyCallback, controller)
    end
    local ok, preId, postId = pcall(RegisterHook,
        CLIENT_RESTART_FUNCTION, inputUi.worldReadyHookPreCallback,
        inputUi.worldReadyHookCallback)
    if not ok or type(preId) ~= "number" then
        return false, ok and "ClientRestart hook registration failed" or preId
    end
    inputUi.worldReadyHookPreId = preId
    inputUi.worldReadyHookPostId = postId
    inputUi.worldReadyTrackingReady = true
    return true, nil
end

local function inventoryMenuIsActive()
    local menu = inputUi.mainMenu
    if not Palworld.isValid(menu)
        or Palworld.objectAddress(menu) ~= inputUi.mainMenuAddress then
        inputUi.mainMenu = nil
        inputUi.mainMenuAddress = nil
        return false
    end

    local active
    local content
    local ok = pcall(function()
        active = menu:IsActivated()
        content = Palworld.unwrap(menu.CurrentContentWidget)
    end)
    if not ok or active ~= true or not Palworld.isValid(content) then
        return false
    end

    local inventoryClass = inputUi.inventoryDisplayClass
    if not Palworld.isValid(inventoryClass) then
        inventoryClass = Palworld.staticObject(INVENTORY_DISPLAY_CLASS_PATH)
        inputUi.inventoryDisplayClass = inventoryClass
    end
    if inventoryClass == nil then return false end

    local typed, isInventory = pcall(function()
        return content:IsA(inventoryClass)
    end)
    return typed and isInventory == true
end

local function rememberMainMenu(value)
    local menu = Palworld.unwrap(value)
    local address = Palworld.objectAddress(menu)
    if address == nil then return false end
    inputUi.mainMenu = menu
    inputUi.mainMenuAddress = address
    return true
end

local function backfillMainMenu()
    if Palworld.isValid(inputUi.mainMenu) then return true end
    if type(FindFirstOf) ~= "function" then return false end
    local found, menu = pcall(FindFirstOf, MAIN_MENU_CLASS_NAME)
    return found and rememberMainMenu(menu) or false
end

function Palworld.installInputUiTracking()
    if inputUi.trackingReady then
        backfillMainMenu()
        return true, nil
    end
    if type(NotifyOnNewObject) ~= "function" then
        return false, "UE4SS object lifecycle API is unavailable"
    end

    local ok, errorMessage = pcall(NotifyOnNewObject,
        MAIN_MENU_CLASS_PATH, function(context)
            rememberMainMenu(context)
            return false
        end)
    if not ok then return false, errorMessage end
    inputUi.trackingReady = true
    -- NotifyOnNewObject 只观察后续构造；晚加载或热重载时补录现有菜单。
    -- 查找只属于安装路径，不进入 F5 热路径。
    backfillMainMenu()
    return true, nil
end

function Palworld.blockingUiOwnsInput(controller)
    local ok, cursorVisible = pcall(function() return controller.bShowMouseCursor end)
    if not ok then return nil, "input ownership state is unreadable" end
    if cursorVisible == true then
        local inventoryOpen = inventoryMenuIsActive()
        return not inventoryOpen, nil, inventoryOpen
    end
    return false, nil, false
end

function Palworld.identityFor(controller)
    local playerState
    local pawn
    local insideComponent
    local base
    local world
    local baseId
    local ok = pcall(function()
        playerState = controller.PlayerState
        pawn = controller.Pawn
        insideComponent = pawn.InsideBaseCampCheckComponent
        base = insideComponent:GetInsideBaseCampModel()
        world = controller:GetWorld()
        baseId = Palworld.guidParts(insideComponent.NowInsideBaseCampID)
    end)
    if not ok or not Palworld.isValid(controller)
        or not Palworld.isValid(playerState) or not Palworld.isValid(pawn)
        or not Palworld.isValid(insideComponent) or not Palworld.isValid(base)
        or not Palworld.isValid(world) then
        return nil, "local base context is unavailable"
    end
    local baseKey = Palworld.guidKey(baseId)
    if baseKey == nil or baseKey == Palworld.ZERO_GUID then
        return nil, "not inside a base"
    end

    local identity = {
        controller = controller,
        controllerAddress = Palworld.objectAddress(controller),
        playerState = playerState,
        playerStateAddress = Palworld.objectAddress(playerState),
        pawn = pawn,
        pawnAddress = Palworld.objectAddress(pawn),
        insideComponent = insideComponent,
        insideComponentAddress = Palworld.objectAddress(insideComponent),
        base = base,
        baseAddress = Palworld.objectAddress(base),
        world = world,
        worldAddress = Palworld.objectAddress(world),
        baseId = baseId,
        baseKey = baseKey,
    }
    if identity.controllerAddress == nil or identity.playerStateAddress == nil
        or identity.pawnAddress == nil or identity.insideComponentAddress == nil
        or identity.baseAddress == nil or identity.worldAddress == nil then
        return nil, "local identity is incomplete"
    end
    return identity, nil
end

local cachedUtility
local cachedVenderDataClass

function Palworld.utility()
    if Palworld.isValid(cachedUtility) then return cachedUtility end
    cachedUtility = Palworld.staticObject("/Script/Pal.Default__PalUtility")
    return cachedUtility
end

local function venderDataClass()
    if Palworld.isValid(cachedVenderDataClass) then return cachedVenderDataClass end
    cachedVenderDataClass = Palworld.staticObject(
        "/Script/Pal.PalVenderDataComponent")
    return cachedVenderDataClass
end

function Palworld.beginCurrentBaseVenderScan(job)
    if type(job) ~= "table" or not Palworld.isValid(job.base) then
        return nil, "current base is unavailable"
    end
    local componentClass = venderDataClass()
    if componentClass == nil then return nil, "vendor component class is unavailable" end
    local utility = Palworld.utility()
    local baseCampManager
    local managerOk = Palworld.isValid(utility) and pcall(function()
        baseCampManager = Palworld.unwrap(utility:GetBaseCampManager(job.controller))
    end)
    if not managerOk or not Palworld.isValid(baseCampManager) then
        return nil, "base manager is unavailable"
    end

    local slots
    local readOk = pcall(function()
        slots = Palworld.unwrap(job.base.WorkerDirector:GetCharacterHandleSlots())
    end)
    local count = readOk and Palworld.arrayLength(slots) or nil
    if count == nil then return nil, "current-base worker list is unreadable" end

    return {
        manager = baseCampManager,
        managerAddress = Palworld.objectAddress(baseCampManager),
        componentClass = componentClass,
        slots = slots,
        count = count,
    }, nil
end

function Palworld.currentBaseVenderAt(job, scan, index)
    if type(scan) ~= "table" or not Palworld.isValid(scan.manager)
        or Palworld.objectAddress(scan.manager) ~= scan.managerAddress
        or not Palworld.isValid(scan.componentClass) then
        return nil, "current-base merchant scan became invalid"
    end
    local slot, readable = Palworld.arrayValue(scan.slots, index)
    if not readable or not Palworld.isValid(slot) then
        return nil, "current-base worker slot is unreadable"
    end
    local handle
    local actor
    local component
    local rangedBase
    local ok = pcall(function()
        handle = Palworld.unwrap(slot:GetHandle())
        if Palworld.isValid(handle) then
            actor = Palworld.unwrap(handle:TryGetIndividualActor())
        end
        if Palworld.isValid(actor) then
            rangedBase = Palworld.unwrap(scan.manager:GetInRangedBaseCamp(
                actor:GetActorLocation(), 0))
            if Palworld.isValid(rangedBase)
                and Palworld.objectAddress(rangedBase) == job.baseAddress then
                component = Palworld.unwrap(
                    actor:GetComponentByClass(scan.componentClass))
            end
        end
    end)
    if not ok then return nil, "current-base worker is unreadable" end
    if not Palworld.isValid(component) then return nil, nil end
    return {
        component = component,
        componentAddress = Palworld.objectAddress(component),
        actor = actor,
        actorAddress = Palworld.objectAddress(actor),
    }, nil
end

function Palworld.itemShopContext(vender)
    if type(vender) ~= "table" or not Palworld.isValid(vender.component)
        or Palworld.objectAddress(vender.component) ~= vender.componentAddress
        or not Palworld.isValid(vender.actor)
        or Palworld.objectAddress(vender.actor) ~= vender.actorAddress then
        return nil
    end
    local called, available, outShop = pcall(function()
        return vender.component:TryGetItemShop()
    end)
    local shop = Palworld.unwrap(outShop)
    if called and not Palworld.isValid(shop)
        and Palworld.isValid(Palworld.unwrap(available)) then
        shop = Palworld.unwrap(available)
        available = true
    end
    if not called or available ~= true or not Palworld.isValid(shop) then
        local valid = false
        pcall(function() valid = vender.component:IsValidItemShop() == true end)
        if valid then
            pcall(function() shop = Palworld.unwrap(vender.component.MyItemShop) end)
        end
        if not Palworld.isValid(shop) then return nil end
    end
    local id
    local idOk = pcall(function() id = Palworld.unwrap(shop:GetId()) end)
    if not idOk or Palworld.guidParts(id) == nil then
        pcall(function() id = Palworld.unwrap(shop.MyShopID) end)
    end
    local parts = Palworld.guidParts(id)
    local key = Palworld.guidKey(parts)
    if key == nil or key == Palworld.ZERO_GUID then return nil end
    return {
        vender = vender,
        shop = shop,
        shopAddress = Palworld.objectAddress(shop),
        shopId = parts,
        shopKey = key,
    }
end

function Palworld.setupVenderShop(vender)
    if type(vender) ~= "table" or not Palworld.isValid(vender.component)
        or Palworld.objectAddress(vender.component) ~= vender.componentAddress then
        return false
    end
    return pcall(function() vender.component:SetupShopData() end)
end

function Palworld.revalidateItemShop(job, expected)
    if type(expected) ~= "table" or not Palworld.isValid(expected.shop)
        or Palworld.objectAddress(expected.shop) ~= expected.shopAddress then
        return nil
    end
    local utility = Palworld.utility()
    local baseCampManager
    local rangedBase
    local validBase = Palworld.isValid(utility) and pcall(function()
        baseCampManager = Palworld.unwrap(utility:GetBaseCampManager(job.controller))
        rangedBase = Palworld.unwrap(baseCampManager:GetInRangedBaseCamp(
            expected.vender.actor:GetActorLocation(), 0))
    end)
    if not validBase or not Palworld.isValid(rangedBase)
        or Palworld.objectAddress(rangedBase) ~= job.baseAddress then return nil end
    local current = Palworld.itemShopContext(expected.vender)
    if current ~= nil and current.shopKey == expected.shopKey
        and current.shopAddress == expected.shopAddress then
        return current
    end
    return nil
end

function Palworld.identityMatches(job)
    local current = Palworld.identityFor(job.controller)
    if current == nil then return false end
    return current.controllerAddress == job.controllerAddress
        and current.playerStateAddress == job.playerStateAddress
        and current.pawnAddress == job.pawnAddress
        and current.insideComponentAddress == job.insideComponentAddress
        and current.baseAddress == job.baseAddress
        and current.worldAddress == job.worldAddress
        and current.baseKey == job.baseKey
end

function Palworld.resolveGuildChestContext(job)
    local utility = Palworld.utility()
    if utility == nil then return nil, "PalUtility CDO is unavailable" end

    local playerUid
    local uidOk = pcall(function()
        playerUid = Palworld.unwrap(utility:GetLocalPlayerUID(job.pawn))
    end)
    local playerUidParts = uidOk and Palworld.guidParts(playerUid) or nil
    local playerUidKey = Palworld.guidKey(playerUidParts)
    if playerUidKey == nil or playerUidKey == Palworld.ZERO_GUID then
        return nil, "local player ID is unavailable"
    end

    local guild
    pcall(function()
        guild = Palworld.unwrap(utility:GetGuildByPlayerUId(job.pawn, playerUid))
    end)
    if not Palworld.isValid(guild) then
        pcall(function() guild = Palworld.unwrap(job.playerState.GuildBelongTo) end)
    end
    if not Palworld.isValid(guild) then return nil, "local guild is unavailable" end

    local guildId
    local guildIdOk = pcall(function()
        guildId = Palworld.guidParts(Palworld.unwrap(guild:GetId()))
    end)
    if not guildIdOk or guildId == nil then
        pcall(function() guildId = Palworld.guidParts(guild.ID) end)
    end
    local guildKey = Palworld.guidKey(guildId)
    if guildKey == nil or guildKey == Palworld.ZERO_GUID then
        return nil, "local guild ID is unavailable"
    end
    local guildAddress = Palworld.objectAddress(guild)
    if guildAddress == nil then return nil, "local guild identity is unavailable" end

    local allowed
    local accessOk = pcall(function()
        allowed = guild:CheckGuildChestAccess(playerUid)
    end)
    allowed = accessOk and booleanValue(allowed)
    if allowed == nil then
        return nil, "Guild Chest permission is unavailable"
    end
    if not allowed then
        return nil, "guild role cannot access the Guild Chest"
    end

    return {
        guild = guild,
        guildAddress = guildAddress,
        guildKey = guildKey,
        baseAddress = job.baseAddress,
        playerUid = playerUid,
    }, nil
end

function Palworld.guildChestEligible(concrete, context)
    if not Palworld.isValid(concrete) or type(context) ~= "table"
        or not Palworld.isValid(context.guild)
        or Palworld.objectAddress(context.guild) ~= context.guildAddress then
        return false, "Guild Chest context changed"
    end
    local allowed
    local accessOk = pcall(function()
        allowed = context.guild:CheckGuildChestAccess(context.playerUid)
    end)
    allowed = accessOk and booleanValue(allowed)
    if allowed == nil then
        return false, "Guild Chest permission is unavailable"
    end
    if not allowed then
        return false, "guild role cannot access the Guild Chest"
    end

    local baseCamp
    local ownerId
    local ownerOk = pcall(function()
        baseCamp = Palworld.unwrap(concrete:GetBaseCampModelBelongTo())
        ownerId = Palworld.guidParts(baseCamp:GetGroupIdBelongTo())
    end)
    if not ownerOk or not Palworld.isValid(baseCamp)
        or Palworld.objectAddress(baseCamp) ~= context.baseAddress
        or Palworld.guidKey(ownerId) ~= context.guildKey then
        return false, "Guild Chest does not belong to the current guild base"
    end
    return true, nil
end

function Palworld.ordinaryContainer(concrete)
    if not Palworld.isValid(concrete) then return nil end
    local container
    local ok = pcall(function()
        local module = concrete:GetItemContainerModule()
        if Palworld.isValid(module) then container = module.TargetContainer end
    end)
    if ok and Palworld.isValid(container) then return container end
    return nil
end

function Palworld.currentOrdinaryContainer(candidate, mapObjectManager)
    local ok, container = pcall(function()
        local model = mapObjectManager:FindModel(candidate.instanceId)
        if not Palworld.isValid(model) or not Palworld.isValid(candidate.model)
            or not Palworld.isValid(candidate.concrete) then return nil end
        local concrete = model.ConcreteModel
        if not Palworld.isValid(concrete)
            or Palworld.objectAddress(model) ~= Palworld.objectAddress(candidate.model)
            or Palworld.objectAddress(concrete) ~= Palworld.objectAddress(candidate.concrete) then
            return nil
        end
        return Palworld.ordinaryContainer(concrete)
    end)
    if ok then return container end
    return nil
end

function Palworld.smallIncubatorHasHatchedPal(concrete)
    if not Palworld.isValid(concrete) then
        return nil, "small incubator object is invalid"
    end
    local ok, characterId = pcall(function()
        -- 当前原生 IsValid 只判断 CharacterID != NAME_None；不传递整个存档结构。
        return Palworld.nameString(concrete.HatchedCharacterSaveParameter.CharacterID)
    end)
    if not ok then return nil, "hatched CharacterID read failed: " .. tostring(characterId) end
    if characterId == nil then return nil, "hatched CharacterID is unreadable" end
    return characterId ~= "None"
end

function Palworld.guildChestContainer(concrete)
    local container
    local ok = pcall(function()
        container = Palworld.unwrap(
            concrete:GetItemContainer_ItemContainerAccessInterface())
    end)
    if not ok or not Palworld.isValid(container) then return nil end
    return container
end

function Palworld.readyGuildChestContainer(concrete)
    local container = Palworld.guildChestContainer(concrete)
    if container == nil then return nil end
    local slots
    local expectedSlots
    local ok = pcall(function()
        slots = container.ItemSlotArray
        expectedSlots = tonumber(concrete:GetDisplayContainerSlotNumDefault())
    end)
    local slotCount = ok and Palworld.arrayLength(slots) or nil
    if slotCount == nil or slotCount < 1
        or (expectedSlots ~= nil and expectedSlots > 0
            and slotCount < expectedSlots) then
        return nil
    end
    return container
end

function Palworld.startGuildChestReplication(concrete)
    return Palworld.isValid(concrete) and pcall(function()
        concrete:RequestStartItemContainerReplication()
    end)
end

function Palworld.stopGuildChestReplication(concrete)
    return Palworld.isValid(concrete) and pcall(function()
        concrete:RequestStopItemContainerReplication()
    end)
end

function Palworld.resolveCommonContainer(playerState)
    local inventory
    local commonGuid
    local containers
    local ok = pcall(function()
        inventory = playerState.InventoryData
        commonGuid = Palworld.guidParts(inventory.MyInventoryInfo.CommonContainerId.ID)
        containers = inventory.InventoryMultiHelper.Containers
    end)
    if not ok or not Palworld.isValid(inventory) then
        return nil, nil, nil, "common inventory roots are unavailable"
    end
    local commonKey = Palworld.guidKey(commonGuid)
    if commonKey == nil or commonKey == Palworld.ZERO_GUID then
        return nil, nil, nil, "common container id is unavailable"
    end

    local count = Palworld.arrayLength(containers)
    if count == nil then return nil, nil, nil, "owned container list is unreadable" end
    local matched
    local matchedCount = 0
    for index = 1, count do
        local container, readable = Palworld.arrayValue(containers, index)
        if not readable or not Palworld.isValid(container) then
            return nil, nil, nil, "owned container entry is unreadable"
        end
        local _, key = Palworld.containerGuid(container)
        if key == nil then return nil, nil, nil, "owned container id is unreadable" end
        if key == commonKey then
            matched = container
            matchedCount = matchedCount + 1
        end
    end
    if matchedCount ~= 1 then
        return nil, nil, nil,
            "common container match is missing or ambiguous (" .. matchedCount .. ")"
    end
    return inventory, matched, commonGuid, nil
end

function Palworld.resolveExclusions(playerState)
    local record
    local exclusions
    local ok = pcall(function()
        record = playerState:GetLocalRecordData()
        exclusions = record.Local_ItemQuickMoveExceptionIDList
    end)
    if not ok or not Palworld.isValid(record) or exclusions == nil then
        return nil, "quick-stack exclusion list is unavailable"
    end
    return Palworld.readNameSet(exclusions)
end

local cachedCategorySettingAddress
local cachedCategories

function Palworld.readCategories(gameSetting)
    local settingAddress = Palworld.objectAddress(gameSetting)
    if settingAddress ~= nil and settingAddress == cachedCategorySettingAddress
        and cachedCategories ~= nil then
        return cachedCategories, nil
    end

    local preferenceMap
    local ok = pcall(function()
        preferenceMap = gameSetting.ItemFilterPreference.PreferenceMap
    end)
    if not ok or preferenceMap == nil then
        return nil, "item filter preference map is unavailable"
    end

    local categories = {}
    local names = {}
    local decodeError
    local iterated = pcall(function()
        preferenceMap:ForEach(function(rawKey, rawValue)
            if decodeError ~= nil then return end
            local name = Palworld.nameString(Palworld.unwrap(rawKey))
            local value = Palworld.unwrap(rawValue)
            if name == nil or name == "None" or value == nil or names[name] then
                decodeError = "item filter category is invalid or duplicated"
                return
            end
            local typeA, typeAError = Palworld.readEnumSet(value.TypeA)
            local typeB, typeBError = Palworld.readEnumSet(value.TypeB)
            local typeBExcept, typeBExceptError =
                Palworld.readEnumSet(value.TypeB_Except)
            if typeA == nil or typeB == nil or typeBExcept == nil then
                decodeError = typeAError or typeBError or typeBExceptError
                return
            end
            names[name] = true
            categories[#categories + 1] = {
                name = name,
                typeA = typeA,
                typeB = typeB,
                typeBExcept = typeBExcept,
            }
        end)
    end)
    if not iterated or decodeError ~= nil or #categories == 0 then
        return nil, decodeError or "item filter categories cannot be enumerated"
    end
    cachedCategorySettingAddress = settingAddress
    cachedCategories = categories
    return categories, nil
end

function Palworld.itemCategory(categories, metadata)
    for _, category in ipairs(categories) do
        if next(category.typeB) ~= nil and category.typeB[metadata.typeB] then
            return category.name
        end
    end
    for _, category in ipairs(categories) do
        if next(category.typeB) == nil
            and category.typeA[metadata.typeA]
            and not category.typeBExcept[metadata.typeB] then
            return category.name
        end
    end
    return nil
end

local function isInstanceOf(object, classObject)
    if not Palworld.isValid(object) or not Palworld.isValid(classObject) then return false end
    local ok, result = pcall(function() return object:IsA(classObject) end)
    return ok and result == true
end

local cachedStorageClasses
local cachedIncubatorClass
local cachedGuildChestClass
local cachedMedicineRackClass
local cachedRecyclerClass

local function destinationClassesAreValid(wantsRecycler)
    if type(cachedStorageClasses) ~= "table" or #cachedStorageClasses == 0 then
        return false
    end
    for _, classObject in ipairs(cachedStorageClasses) do
        if not Palworld.isValid(classObject) then return false end
    end
    return Palworld.isValid(cachedGuildChestClass)
        and Palworld.isValid(cachedMedicineRackClass)
        and (cachedIncubatorClass == nil or Palworld.isValid(cachedIncubatorClass))
        and (not wantsRecycler or Palworld.isValid(cachedRecyclerClass))
end

function Palworld.loadDestinationClasses(job)
    if job.config.IncludeSmallIncubators
        and job.config.PalEggRouting ~= "ManualPlacement" then
        job.smallIncubatorClass = Palworld.staticObject(SMALL_INCUBATOR_CLASS_PATH)
        if job.smallIncubatorClass == nil then
            return false, "small incubator model class is unavailable"
        end
    end
    local wantsRecycler = true
    if destinationClassesAreValid(wantsRecycler) then
        job.storageClasses = cachedStorageClasses
        job.incubatorClass = cachedIncubatorClass
        job.guildChestClass = cachedGuildChestClass
        job.medicineRackClass = cachedMedicineRackClass
        job.recyclerClass = wantsRecycler and cachedRecyclerClass or nil
        if job.smallIncubatorClass ~= nil and job.incubatorClass == nil then
            return false, "large incubator model class is unavailable"
        end
        return true, nil
    end

    cachedStorageClasses = {}
    for _, path in ipairs(STORAGE_CLASS_PATHS) do
        local classObject = Palworld.staticObject(path)
        if classObject ~= nil then
            cachedStorageClasses[#cachedStorageClasses + 1] = classObject
        end
    end
    if #cachedStorageClasses == 0 then
        return false, "storage model classes are unavailable"
    end
    cachedIncubatorClass = Palworld.staticObject(INCUBATOR_CLASS_PATH)
    cachedGuildChestClass = Palworld.staticObject(GUILD_CHEST_CLASS_PATH)
    cachedMedicineRackClass = Palworld.staticObject(MEDICINE_RACK_CLASS_PATH)
    if wantsRecycler then
        cachedRecyclerClass = Palworld.staticObject(RECYCLER_CLASS_PATH)
    end
    if cachedGuildChestClass == nil then
        return false, "guild chest model class is unavailable"
    end
    if cachedMedicineRackClass == nil then
        return false, "Medicine Rack model class is unavailable"
    end
    job.storageClasses = cachedStorageClasses
    job.incubatorClass = cachedIncubatorClass
    if job.smallIncubatorClass ~= nil and job.incubatorClass == nil then
        return false, "large incubator model class is unavailable"
    end
    job.guildChestClass = cachedGuildChestClass
    job.medicineRackClass = cachedMedicineRackClass
    if wantsRecycler and cachedRecyclerClass == nil then
        return false, "Ancient Relic Recycler model class is unavailable"
    end
    job.recyclerClass = wantsRecycler and cachedRecyclerClass or nil
    return true, nil
end

function Palworld.destinationKind(job, concreteModel)
    if isInstanceOf(concreteModel, job.guildChestClass) then
        return job.config.IncludeGuildChest and "guild_storage" or nil
    end
    if job.recyclerClass ~= nil
        and isInstanceOf(concreteModel, job.recyclerClass) then return "recycler" end
    if job.incubatorClass ~= nil
        and isInstanceOf(concreteModel, job.incubatorClass) then return "incubator" end
    if job.smallIncubatorClass ~= nil
        and isInstanceOf(concreteModel, job.smallIncubatorClass) then
        return "small_incubator"
    end
    if isInstanceOf(concreteModel, job.medicineRackClass) then
        return job.config.MedicineRackFirst and "medicine_rack" or "storage"
    end
    for _, classObject in ipairs(job.storageClasses) do
        if isInstanceOf(concreteModel, classObject) then
            return "storage"
        end
    end
    return nil
end

function Palworld.readFilterOff(container)
    local array
    local ok = pcall(function() array = container.FilterPreference.FilterOffList end)
    if not ok or array == nil then return nil, "container filter is unavailable" end
    return Palworld.readNameSet(array)
end

function Palworld.readPermission(container)
    local permission
    local typeAArray
    local typeBArray
    local itemIdArray
    local ok = pcall(function()
        permission = container.Permission
        typeAArray = permission.PermissionTypeA
        typeBArray = permission.PermissionTypeB
        itemIdArray = permission.PermissionItemStaticIds
    end)
    if not ok or permission == nil then return nil, "container permission is unavailable" end
    local typeA, typeAError = Palworld.readEnumSet(typeAArray)
    local typeB, typeBError = Palworld.readEnumSet(typeBArray)
    local itemIds, itemIdError = Palworld.readNameSet(itemIdArray)
    if typeA == nil or typeB == nil or itemIds == nil then
        return nil, typeAError or typeBError or itemIdError
    end
    return {
        typeA = typeA,
        typeB = typeB,
        itemIds = itemIds,
        restricted = next(typeA) ~= nil or next(typeB) ~= nil or next(itemIds) ~= nil,
    }, nil
end

function Palworld.destinationAllows(entry, item, metadata)
    if entry.isIncubator then return item.isEgg == true end
    if entry.isRecyclerBoost then
        return item.id == entry.boostItemId
    end
    if entry.isRecycler then
        return entry.permission ~= nil
            and entry.permission.itemIds[item.id] == true
    end
    if metadata == nil or metadata.category == nil
        or entry.filterOff == nil or entry.permission == nil then return false end
    if entry.filterOff[metadata.category] then return false end
    local permission = entry.permission
    if permission.restricted
        and not permission.typeA[metadata.typeA]
        and not permission.typeB[metadata.typeB]
        and not permission.itemIds[item.id] then
        return false
    end
    return true
end

return Palworld
