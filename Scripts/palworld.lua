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
local BREEDING_FARM_CLASS_PATH = "/Script/Pal.PalMapObjectBreedFarmModel"
local FOOD_BOX_CLASS_PATH = "/Script/Pal.PalMapObjectPalFoodBoxModel"
local COLD_STORAGE_IDS = {
    CoolerBox = true,
    Refrigerator = true,
    CoolerElectric = true,
    CoolerMedieval = true,
    CoolerAncient = true,
}

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
        inputUi.mainMenu = nil
        inputUi.mainMenuAddress = nil
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

local function mainMenuState()
    local menu = inputUi.mainMenu
    if not Palworld.isValid(menu)
        or Palworld.objectAddress(menu) ~= inputUi.mainMenuAddress then
        inputUi.mainMenu = nil
        inputUi.mainMenuAddress = nil
        return false, false
    end

    local active
    local content
    local ok = pcall(function()
        active = menu:IsActivated()
        content = Palworld.unwrap(menu.CurrentContentWidget)
    end)
    if not ok or active ~= true then return false, false end
    if not Palworld.isValid(content) then return true, false end

    local inventoryClass = inputUi.inventoryDisplayClass
    if not Palworld.isValid(inventoryClass) then
        inventoryClass = Palworld.staticObject(INVENTORY_DISPLAY_CLASS_PATH)
        inputUi.inventoryDisplayClass = inventoryClass
    end
    if inventoryClass == nil then return true, false end

    local typed, isInventory = pcall(function()
        return content:IsA(inventoryClass)
    end)
    return true, typed and isInventory == true
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
    -- F5 仅在缓存缺失或失效时执行同一个有界补录。
    backfillMainMenu()
    return true, nil
end

function Palworld.blockingUiOwnsInput(controller)
    local ok, cursorVisible = pcall(function() return controller.bShowMouseCursor end)
    if not ok then return nil, "input ownership state is unreadable" end
    if not Palworld.isValid(inputUi.mainMenu)
        or Palworld.objectAddress(inputUi.mainMenu) ~= inputUi.mainMenuAddress then
        backfillMainMenu()
    end
    local menuActive, inventoryOpen = mainMenuState()
    if menuActive then return not inventoryOpen, nil, inventoryOpen end
    if cursorVisible == true then return true, nil, false end
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

function Palworld.registeredItemShopContext(job, expected)
    if type(job) ~= "table" or not Palworld.isValid(job.controller) then
        return nil, -1, "local controller is unavailable"
    end
    local utility = Palworld.utility()
    if not Palworld.isValid(utility) then
        return nil, -1, "PalUtility CDO is unavailable"
    end
    local manager
    local shops
    local readable = pcall(function()
        manager = utility:GetShopManager(job.controller)
        if Palworld.isValid(manager) then
            shops = Palworld.unwrap(manager.CreatedItemShopMap_ForServer)
        end
    end)
    if not readable or not Palworld.isValid(manager) or shops == nil then
        return nil, -1, "registered item shop map is unavailable"
    end
    local managerAddress = Palworld.objectAddress(manager)
    if managerAddress == nil
        or (expected ~= nil and managerAddress ~= expected.managerAddress) then
        return nil, -1, "registered item shop manager changed"
    end
    local count = 0
    local matched
    local iterated = pcall(function()
        shops:ForEach(function(rawKey, rawValue)
            count = count + 1
            if matched ~= nil then return end
            local shopId = Palworld.guidParts(Palworld.unwrap(rawKey))
            local shopKey = Palworld.guidKey(shopId)
            local shop = Palworld.unwrap(rawValue)
            local shopAddress = Palworld.objectAddress(shop)
            if shopKey ~= nil and shopKey ~= Palworld.ZERO_GUID
                and shopAddress ~= nil
                and (expected == nil or (shopKey == expected.shopKey
                    and shopAddress == expected.shopAddress)) then
                matched = {
                    source = "registered-shop-map",
                    managerAddress = managerAddress,
                    shop = shop,
                    shopAddress = shopAddress,
                    shopId = shopId,
                    shopKey = shopKey,
                }
            end
        end)
    end)
    if not iterated then
        return nil, -1, "registered item shop map is unreadable"
    end
    if matched == nil then
        return nil, count, expected == nil
            and "registered item shop map contains no readable item shop"
            or "registered item shop entry changed"
    end
    return matched, count, nil
end

function Palworld.beginCurrentBaseVenderScan(job)
    if type(job) ~= "table" or not Palworld.isValid(job.base) then
        return nil, "current base is unavailable"
    end
    local componentClass = venderDataClass()
    if componentClass == nil then return nil, "vendor component class is unavailable" end
    local utility = Palworld.utility()
    local baseCampManager
    local workerContainer
    local collector
    local mapObjectManager = job.mapObjectManager
    local managerOk = Palworld.isValid(utility) and pcall(function()
        baseCampManager = utility:GetBaseCampManager(job.controller)
    end)
    if not managerOk or not Palworld.isValid(baseCampManager) then
        return nil, "base manager is unavailable"
    end
    if not Palworld.isValid(mapObjectManager) then
        return nil, "map object manager is unavailable"
    end
    pcall(function()
        workerContainer = job.base.WorkerDirector.CharacterContainer
    end)
    pcall(function()
        collector = utility:GetPalObjectCollector(job.controller)
    end)

    local workerCount = 0
    if Palworld.isValid(workerContainer) then
        local slots
        local readOk = pcall(function() slots = workerContainer.SlotArray end)
        workerCount = readOk and Palworld.arrayLength(slots) or nil
        if workerCount == nil then
            return nil, "current-base worker list is unreadable"
        end
    end

    local humanCount = 0
    if Palworld.isValid(collector) then
        local actors
        local readOk = pcall(function() actors = collector.PalCharacter_NPC end)
        humanCount = readOk and Palworld.arrayLength(actors) or nil
        if humanCount == nil then
            return nil, "loaded human NPC list is unreadable"
        end
    end
    local baseObjectCount = tonumber(job.repCount)
    if baseObjectCount == nil or baseObjectCount < 0 then
        return nil, "current-base object list is unreadable"
    end
    baseObjectCount = math.floor(baseObjectCount)
    if workerCount == 0 and humanCount == 0 and baseObjectCount == 0 then
        return nil, "no current-base merchant sources are available"
    end

    return {
        manager = baseCampManager,
        managerAddress = Palworld.objectAddress(baseCampManager),
        componentClass = componentClass,
        workerContainer = workerContainer,
        workerContainerAddress = Palworld.objectAddress(workerContainer),
        workerCount = workerCount,
        collector = collector,
        collectorAddress = Palworld.objectAddress(collector),
        humanCount = humanCount,
        actorSourceCount = workerCount + humanCount,
        mapObjectManager = mapObjectManager,
        mapObjectManagerAddress = Palworld.objectAddress(mapObjectManager),
        baseObjectCount = baseObjectCount,
        count = workerCount + humanCount + baseObjectCount,
    }, nil
end

local function venderForActor(actor, scan, source)
    if not Palworld.isValid(actor) then return nil, nil end
    local component
    local readable = pcall(function()
        component = actor:GetComponentByClass(scan.componentClass)
    end)
    if not readable then return nil, "merchant actor is unreadable" end
    if not Palworld.isValid(component) then return nil, nil end
    source.component = component
    source.componentAddress = Palworld.objectAddress(component)
    source.actor = actor
    source.actorAddress = Palworld.objectAddress(actor)
    if source.componentAddress == nil or source.actorAddress == nil then
        return nil, "merchant actor identity is unavailable"
    end
    return source, nil
end

local function appendMapCharacterActor(out, seen, actor, scan, source)
    if not Palworld.isValid(actor) then return true, nil end
    local actorAddress = Palworld.objectAddress(actor)
    if actorAddress == nil then return false, "displayed character identity is unavailable" end
    if seen[actorAddress] then return true, nil end
    seen[actorAddress] = true
    local vender, venderError = venderForActor(actor, scan, source)
    if venderError ~= nil then return false, venderError end
    if vender ~= nil then out[#out + 1] = vender end
    return true, nil
end

local function mapCharacterVendersAt(job, scan, index)
    if not Palworld.isValid(scan.mapObjectManager)
        or Palworld.objectAddress(scan.mapObjectManager)
            ~= scan.mapObjectManagerAddress then
        return nil, "map object manager changed"
    end
    local repInfo, readable = Palworld.arrayValue(job.repItems, index)
    if not readable or repInfo == nil then
        return nil, "current-base object entry is unreadable"
    end
    local instanceId
    local model
    local concrete
    local module
    local container
    local slots
    local rootsOk = pcall(function()
        instanceId = repInfo.InstanceId
        model = scan.mapObjectManager:FindModel(instanceId)
        if Palworld.isValid(model) then concrete = model.ConcreteModel end
        if Palworld.isValid(concrete) then
            module = concrete:GetCharacterContainerModule()
        end
        if Palworld.isValid(module) then
            container = module.TargetContainer
        end
        if Palworld.isValid(container) then slots = container.SlotArray end
    end)
    if not rootsOk or instanceId == nil then
        return nil, "current-base character-container source is unreadable"
    end
    if not Palworld.isValid(model) or not Palworld.isValid(concrete)
        or not Palworld.isValid(module) or not Palworld.isValid(container) then
        return {}, nil
    end
    local slotCount = Palworld.arrayLength(slots)
    if slotCount == nil then
        return nil, "current-base character-container slots are unreadable"
    end
    local venders = {}
    local seen = {}
    for slotIndex = 1, slotCount do
        local slot, slotReadable = Palworld.arrayValue(slots, slotIndex)
        if not slotReadable then
            return nil, "current-base character-container slot is unreadable"
        end
        if Palworld.isValid(slot) then
            local handle
            local primaryActor
            local parameter
            local handleOk = pcall(function()
                handle = slot.Handle
                if Palworld.isValid(handle) then
                    primaryActor = handle:TryGetIndividualActor()
                    parameter = handle:TryGetIndividualParameter()
                end
            end)
            if not handleOk then
                return nil, "current-base displayed character is unreadable"
            end
            if Palworld.isValid(handle) then
                local common = {
                    source = "map-character-container",
                    handleAddress = Palworld.objectAddress(handle),
                    mapObjectManagerAddress = scan.mapObjectManagerAddress,
                    instanceId = instanceId,
                    modelAddress = Palworld.objectAddress(model),
                    concreteAddress = Palworld.objectAddress(concrete),
                    moduleAddress = Palworld.objectAddress(module),
                    containerAddress = Palworld.objectAddress(container),
                }
                local appended, appendError = appendMapCharacterActor(
                    venders, seen, primaryActor, scan, {
                        source = common.source,
                        handleAddress = common.handleAddress,
                        mapObjectManagerAddress = common.mapObjectManagerAddress,
                        instanceId = common.instanceId,
                        modelAddress = common.modelAddress,
                        concreteAddress = common.concreteAddress,
                        moduleAddress = common.moduleAddress,
                        containerAddress = common.containerAddress,
                    })
                if not appended then return nil, appendError end

                if Palworld.isValid(parameter) then
                    local phantomActors
                    local phantomOk = pcall(function()
                        phantomActors = parameter.PhantomActorReplicateArray
                    end)
                    local phantomCount = phantomOk
                        and Palworld.arrayLength(phantomActors) or nil
                    if phantomCount == nil then
                        return nil, "displayed phantom character list is unreadable"
                    end
                    for phantomIndex = 1, phantomCount do
                        local info, infoReadable = Palworld.arrayValue(
                            phantomActors, phantomIndex)
                        if not infoReadable or info == nil then
                            return nil, "displayed phantom character is unreadable"
                        end
                        local phantomActor
                        local actorOk = pcall(function()
                            phantomActor = info.Character
                        end)
                        if not actorOk then
                            return nil, "displayed phantom character is unreadable"
                        end
                        appended, appendError = appendMapCharacterActor(
                            venders, seen, phantomActor, scan, {
                                source = common.source,
                                handleAddress = common.handleAddress,
                                mapObjectManagerAddress = common.mapObjectManagerAddress,
                                instanceId = common.instanceId,
                                modelAddress = common.modelAddress,
                                concreteAddress = common.concreteAddress,
                                moduleAddress = common.moduleAddress,
                                containerAddress = common.containerAddress,
                            })
                        if not appended then return nil, appendError end
                    end
                end
            end
        end
    end
    return venders, nil
end

function Palworld.currentBaseVendersAt(job, scan, index)
    if type(scan) ~= "table" or not Palworld.isValid(scan.manager)
        or Palworld.objectAddress(scan.manager) ~= scan.managerAddress
        or not Palworld.isValid(scan.componentClass) then
        return nil, "current-base merchant scan became invalid"
    end
    if index > scan.actorSourceCount then
        return mapCharacterVendersAt(
            job, scan, index - scan.actorSourceCount)
    end
    local worker = index <= scan.workerCount
    local handle
    local actor
    local component
    local readable
    if worker then
        if not Palworld.isValid(scan.workerContainer)
            or Palworld.objectAddress(scan.workerContainer)
                ~= scan.workerContainerAddress then
            return nil, "current-base worker container changed"
        end
        local slots
        local slot
        local listOk = pcall(function() slots = scan.workerContainer.SlotArray end)
        if not listOk then return nil, "current-base worker list is unreadable" end
        slot, readable = Palworld.arrayValue(slots, index)
        if not readable or not Palworld.isValid(slot) then
            return nil, nil
        end
        local actorOk = pcall(function()
            handle = slot.Handle
            if Palworld.isValid(handle) then
                actor = handle:TryGetIndividualActor()
            end
        end)
        if not actorOk then return nil, "current-base worker is unreadable" end
    else
        if not Palworld.isValid(scan.collector)
            or Palworld.objectAddress(scan.collector) ~= scan.collectorAddress then
            return nil, "world character collector changed"
        end
        local actors
        local listOk = pcall(function() actors = scan.collector.PalCharacter_NPC end)
        if not listOk then return nil, "loaded human NPC list is unreadable" end
        actor, readable = Palworld.arrayValue(actors, index - scan.workerCount)
        if not readable then return {}, nil end
    end
    if not Palworld.isValid(actor) then return {}, nil end
    local rangedBase
    local ok = pcall(function()
        if not worker then
            rangedBase = scan.manager:GetInRangedBaseCamp(
                actor:GetActorLocation(), 0)
        end
        if worker or (Palworld.isValid(rangedBase)
                and Palworld.objectAddress(rangedBase) == job.baseAddress) then
            component = actor:GetComponentByClass(scan.componentClass)
        end
    end)
    if not ok then
        if worker then
            return nil, "current-base merchant candidate is unreadable"
        end
        return {}, nil
    end
    if not Palworld.isValid(component) then return {}, nil end
    return {{
        component = component,
        componentAddress = Palworld.objectAddress(component),
        actor = actor,
        actorAddress = Palworld.objectAddress(actor),
        handleAddress = Palworld.objectAddress(handle),
        workerContainerAddress = scan.workerContainerAddress,
        collectorAddress = scan.collectorAddress,
        source = worker and "worker" or "loaded-human",
    }}, nil
end

local function handleStillOwnsActor(handle, actorAddress)
    if not Palworld.isValid(handle) or actorAddress == nil then return false end
    local primaryActor
    local parameter
    local readable = pcall(function()
        primaryActor = handle:TryGetIndividualActor()
        parameter = handle:TryGetIndividualParameter()
    end)
    if not readable then return false end
    if Palworld.objectAddress(primaryActor) == actorAddress then return true end
    if not Palworld.isValid(parameter) then return false end
    local phantomActors
    local listOk = pcall(function()
        phantomActors = parameter.PhantomActorReplicateArray
    end)
    local count = listOk and Palworld.arrayLength(phantomActors) or nil
    if count == nil then return false end
    for index = 1, count do
        local info, infoReadable = Palworld.arrayValue(phantomActors, index)
        if infoReadable and info ~= nil then
            local actor
            local actorOk = pcall(function() actor = info.Character end)
            if actorOk and Palworld.objectAddress(actor) == actorAddress then
                return true
            end
        end
    end
    return false
end

local function currentBaseWorkerStillMatches(job, vender)
    if not Palworld.isValid(job.base) or vender.handleAddress == nil then return false end
    local container
    local slots
    local ok = pcall(function()
        container = job.base.WorkerDirector.CharacterContainer
        slots = container.SlotArray
    end)
    if not ok or not Palworld.isValid(container)
        or Palworld.objectAddress(container) ~= vender.workerContainerAddress then
        return false
    end
    local count = ok and Palworld.arrayLength(slots) or nil
    if count == nil then return false end
    for index = 1, count do
        local slot, readable = Palworld.arrayValue(slots, index)
        if readable and Palworld.isValid(slot) then
            local handle
            local handleOk = pcall(function() handle = slot.Handle end)
            if handleOk and Palworld.isValid(handle)
                and Palworld.objectAddress(handle) == vender.handleAddress then
                return true
            end
        end
    end
    return false
end

local function currentBaseMapCharacterStillMatches(job, vender)
    if not Palworld.isValid(job.base) or not Palworld.isValid(job.mapObjectManager)
        or Palworld.objectAddress(job.mapObjectManager)
            ~= vender.mapObjectManagerAddress then
        return false
    end
    local model
    local concrete
    local ownerBase
    local module
    local container
    local slots
    local ok = pcall(function()
        model = job.mapObjectManager:FindModel(vender.instanceId)
        if Palworld.isValid(model) then concrete = model.ConcreteModel end
        if Palworld.isValid(concrete) then
            ownerBase = concrete:GetBaseCampModelBelongTo()
            module = concrete:GetCharacterContainerModule()
        end
        if Palworld.isValid(module) then container = module.TargetContainer end
        if Palworld.isValid(container) then slots = container.SlotArray end
    end)
    if not ok or Palworld.objectAddress(model) ~= vender.modelAddress
        or Palworld.objectAddress(concrete) ~= vender.concreteAddress
        or Palworld.objectAddress(ownerBase) ~= job.baseAddress
        or Palworld.objectAddress(module) ~= vender.moduleAddress
        or Palworld.objectAddress(container) ~= vender.containerAddress then
        return false
    end
    local count = Palworld.arrayLength(slots)
    if count == nil then return false end
    for index = 1, count do
        local slot, readable = Palworld.arrayValue(slots, index)
        if readable and Palworld.isValid(slot) then
            local handle
            local handleOk = pcall(function() handle = slot.Handle end)
            if handleOk and Palworld.objectAddress(handle) == vender.handleAddress then
                return handleStillOwnsActor(handle, vender.actorAddress)
            end
        end
    end
    return false
end

function Palworld.itemShopContext(vender)
    if type(vender) ~= "table" or not Palworld.isValid(vender.component)
        or Palworld.objectAddress(vender.component) ~= vender.componentAddress
        or not Palworld.isValid(vender.actor)
        or Palworld.objectAddress(vender.actor) ~= vender.actorAddress then
        return nil
    end
    local valid = false
    local shop
    local id
    local readable = pcall(function()
        valid = vender.component:IsValidItemShop() == true
        shop = vender.component.MyItemShop
        id = vender.component.MyShopID
    end)
    if not readable or not valid or not Palworld.isValid(shop) then return nil end
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
    if expected.source == "registered-shop-map" then
        return Palworld.registeredItemShopContext(job, expected)
    end
    if type(expected.vender) ~= "table" then return nil end
    local validBase = false
    if expected.vender.source == "worker" then
        validBase = currentBaseWorkerStillMatches(job, expected.vender)
    elseif expected.vender.source == "map-character-container" then
        validBase = currentBaseMapCharacterStillMatches(job, expected.vender)
    else
        local utility = Palworld.utility()
        local collector
        local baseCampManager
        local rangedBase
        local checked = Palworld.isValid(utility) and pcall(function()
            collector = utility:GetPalObjectCollector(job.controller)
            baseCampManager = utility:GetBaseCampManager(job.controller)
            rangedBase = baseCampManager:GetInRangedBaseCamp(
                expected.vender.actor:GetActorLocation(), 0)
        end)
        validBase = checked and Palworld.isValid(collector)
            and Palworld.objectAddress(collector) == expected.vender.collectorAddress
            and Palworld.isValid(rangedBase)
            and Palworld.objectAddress(rangedBase) == job.baseAddress
    end
    if not validBase then return nil end
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
local cachedBreedingFarmClass
local cachedFoodBoxClass

local function destinationClassesAreValid(
    wantsRecycler, wantsFoodFacilities, wantsBreedingFarm)
    if type(cachedStorageClasses) ~= "table" or #cachedStorageClasses == 0 then
        return false
    end
    for _, classObject in ipairs(cachedStorageClasses) do
        if not Palworld.isValid(classObject) then return false end
    end
    return Palworld.isValid(cachedGuildChestClass)
        and Palworld.isValid(cachedMedicineRackClass)
        and (not wantsFoodFacilities or Palworld.isValid(cachedFoodBoxClass))
        and (cachedIncubatorClass == nil or Palworld.isValid(cachedIncubatorClass))
        and (not wantsRecycler or Palworld.isValid(cachedRecyclerClass))
        and (not wantsBreedingFarm
            or Palworld.isValid(cachedBreedingFarmClass))
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
    local wantsFoodFacilities = job.config.BreedingFarmCakeFirst == true
        or job.config.FoodBoxFirst == true
    local wantsBreedingFarm = job.config.BreedingFarmCakeFirst == true
    if destinationClassesAreValid(
        wantsRecycler, wantsFoodFacilities, wantsBreedingFarm) then
        job.storageClasses = cachedStorageClasses
        job.incubatorClass = cachedIncubatorClass
        job.guildChestClass = cachedGuildChestClass
        job.medicineRackClass = cachedMedicineRackClass
        job.recyclerClass = wantsRecycler and cachedRecyclerClass or nil
        job.breedingFarmClass = wantsBreedingFarm
            and cachedBreedingFarmClass or nil
        job.foodBoxClass = wantsFoodFacilities and cachedFoodBoxClass or nil
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
    if wantsFoodFacilities then
        cachedFoodBoxClass = Palworld.staticObject(FOOD_BOX_CLASS_PATH)
    end
    if wantsRecycler then
        cachedRecyclerClass = Palworld.staticObject(RECYCLER_CLASS_PATH)
    end
    if cachedGuildChestClass == nil then
        return false, "guild chest model class is unavailable"
    end
    if cachedMedicineRackClass == nil then
        return false, "Medicine Rack model class is unavailable"
    end
    if wantsFoodFacilities and cachedFoodBoxClass == nil then
        return false, "Pal Food Box model class is unavailable"
    end
    if wantsBreedingFarm then
        cachedBreedingFarmClass = Palworld.staticObject(BREEDING_FARM_CLASS_PATH)
        if cachedBreedingFarmClass == nil then
            return false, "Breeding Farm model class is unavailable"
        end
    end
    job.storageClasses = cachedStorageClasses
    job.incubatorClass = cachedIncubatorClass
    if job.smallIncubatorClass ~= nil and job.incubatorClass == nil then
        return false, "large incubator model class is unavailable"
    end
    job.guildChestClass = cachedGuildChestClass
    job.medicineRackClass = cachedMedicineRackClass
    job.foodBoxClass = wantsFoodFacilities and cachedFoodBoxClass or nil
    job.breedingFarmClass = wantsBreedingFarm and cachedBreedingFarmClass or nil
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
    if job.breedingFarmClass ~= nil
        and isInstanceOf(concreteModel, job.breedingFarmClass) then
        return "breeding_farm"
    end
    if isInstanceOf(concreteModel, job.foodBoxClass) then
        return (job.config.BreedingFarmCakeFirst or job.config.FoodBoxFirst)
            and "food_box" or "storage"
    end
    for _, classObject in ipairs(job.storageClasses) do
        if isInstanceOf(concreteModel, classObject) then
            if job.config.BreedingFarmCakeFirst or job.config.FoodBoxFirst then
                local mapObjectId
                pcall(function()
                    mapObjectId = Palworld.nameString(
                        concreteModel:TryGetMapObjectId())
                end)
                if COLD_STORAGE_IDS[mapObjectId] then return "cold_storage" end
            end
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
