-- Gorge Controller
-- Author: flouid
-- Automates QGP and Magmatter Exoticiser cycles.
-- Ctrl+Alt+C to exit.

-- credit where it's due, much of this is stolen Armisael's BEC script: https://github.com/Armisael5/gtnh-bec-controller/tree/main

local component = require("component")
local computer = require("computer")
local event = require("event")

-- ============================================================
-- config
-- ============================================================

ENABLE_AUTO_UPDATE = true
ENABLE_QGP = true
ENABLE_MAGMATTER = true
DEBUG = false
BATCH_MULTIPLIER = 2^16
BATCH_SIZE = {
    ITEM = BATCH_MULTIPLIER,
    FLUID = 1000 * BATCH_MULTIPLIER
}

IO_INPUT_FIRST_SLOT = 1
IO_OUTPUT_FIRST_SLOT = 7
IO_SLOT_COUNT = 6
QGP_OUTPUT_MARKER_SLOT = 11
MAGMATTER_OUTPUT_MARKER_SLOT = 12
OUTPUT_SETTLE_TIME = 0.1
OUTPUT_RESCAN_INTERVAL = 10
EVENT_DEBOUNCE_TIME = 0.05

FABRICATOR_SOURCE_OVERRIDES = {
    ["Infinity Dust"] = {
        name = "molten.infinity",
        label = "Molten Infinity",
        type = "FLUID",
        batchAmount = 144 * BATCH_MULTIPLIER
    },
    ["Dragonblood Dust"] = {
        name = "molten.dragonblood",
        label = "Molten Dragonblood",
        type = "FLUID",
        batchAmount = 144 * BATCH_MULTIPLIER
    },
    ["Celestial Tungsten Dust"] = {
        name = "molten.celestialtungsten",
        label = "Molten Celestial Tungsten",
        type = "FLUID",
        batchAmount = 144 * BATCH_MULTIPLIER
    },
    ["Hypogen Dust"] = {
        name = "molten.hypogen",
        label = "Molten Hypogen",
        type = "FLUID",
        batchAmount = 144 * BATCH_MULTIPLIER
    },
    ["Chromatic Glass Dust"] = {
        name = "molten.chromaticglass",
        label = "Molten Chromatic Glass",
        type = "FLUID",
        batchAmount = 144 * BATCH_MULTIPLIER
    },
    ["Rhugnor Dust"] = {
        name = "molten.rhugnor",
        label = "Molten Rhugnor",
        type = "FLUID",
        batchAmount = 144 * BATCH_MULTIPLIER
    }
}

QGP_ATLAS = {
    ["Aluminium Dust"] = "plasma.aluminium",
    ["Americium Dust"] = "plasma.americium",
    ["Antimony Dust"] = "plasma.antimony",
    ["Ardite Dust"] = "plasma.ardite",
    ["Argon"] = "plasma.argon",
    ["Arsenic Dust"] = "plasma.arsenic",
    ["Barium Dust"] = "plasma.barium",
    ["Beryllium Dust"] = "plasma.beryllium",
    ["Cadmium Dust"] = "plasma.cadmium",
    ["Caesium Dust"] = "plasma.caesium",
    ["Calcium Dust"] = "plasma.calcium",
    ["Carbon Dust"] = "plasma.carbon",
    ["Cerium Dust"] = "plasma.cerium",
    ["Chlorine"] = "plasma.chlorine",
    ["Cobalt Dust"] = "plasma.cobalt",
    ["Copper Dust"] = "plasma.copper",
    ["Curium Dust"] = "plasma.curium",
    ["Desh Dust"] = "plasma.desh",
    ["Deuterium"] = "plasma.deuterium",
    ["Dysprosium Dust"] = "plasma.dysprosium",
    ["Erbium Dust"] = "plasma.erbium",
    ["Europium Dust"] = "plasma.europium",
    ["Fluorine"] = "plasma.fluorine",
    ["Gadolinium Dust"] = "plasma.gadolinium",
    ["Gallium Dust"] = "plasma.gallium",
    ["Germanium Dust"] = "plasma.germanium",
    ["Gold Dust"] = "plasma.gold",
    ["Hafnium Dust"] = "plasma.hafnium",
    ["Helium"] = "plasma.helium",
    ["Holmium Dust"] = "plasma.holmium",
    ["Hydrogen"] = "plasma.hydrogen",
    ["Indium Dust"] = "plasma.indium",
    ["Iodine Dust"] = "plasma.iodine",
    ["Iron Dust"] = "plasma.iron",
    ["Lanthanum Dust"] = "plasma.lanthanum",
    ["Lithium Dust"] = "plasma.lithium",
    ["Lutetium Dust"] = "plasma.lutetium",
    ["Magnesium Dust"] = "plasma.magnesium",
    ["Manganese Dust"] = "plasma.manganese",
    ["Mercury"] = "plasma.mercury",
    ["Meteoric Iron Dust"] = "plasma.meteoriciron",
    ["Molybdenum Dust"] = "plasma.molybdenum",
    ["Neodymium Dust"] = "plasma.neodymium",
    ["Nickel Dust"] = "plasma.nickel",
    ["Niobium Dust"] = "plasma.niobium",
    ["Nitrogen"] = "plasma.nitrogen",
    ["Oriharukon Dust"] = "plasma.oriharukon",
    ["Palladium Dust"] = "plasma.palladium",
    ["Phosphorus Dust"] = "plasma.phosphorus",
    ["Potassium Dust"] = "plasma.potassium",
    ["Praseodymium Dust"] = "plasma.praseodymium",
    ["Promethium Dust"] = "plasma.promethium",
    ["Radon"] = "plasma.radon",
    ["Raw Silicon Dust"] = "plasma.silicon",
    ["Rhenium Dust"] = "plasma.rhenium",
    ["Rhodium Dust"] = "plasma.rhodium",
    ["Rubidium Dust"] = "plasma.rubidium",
    ["Ruthenium Dust"] = "plasma.ruthenium",
    ["Samarium Dust"] = "plasma.samarium",
    ["Silver Dust"] = "plasma.silver",
    ["Sodium Dust"] = "plasma.sodium",
    ["Strontium Dust"] = "plasma.strontium",
    ["Sulfur Dust"] = "plasma.sulfur",
    ["Tantalum Dust"] = "plasma.tantalum",
    ["Tellurium Dust"] = "plasma.tellurium",
    ["Terbium Dust"] = "plasma.terbium",
    ["Thallium Dust"] = "plasma.thallium",
    ["Thorium 232 Dust"] = "plasma.thorium232",
    ["Thulium Dust"] = "plasma.thulium",
    ["Tin Dust"] = "plasma.tin",
    ["Titanium Dust"] = "plasma.titanium",
    ["Tritium"] = "plasma.tritium",
    ["Tungsten Dust"] = "plasma.tungsten",
    ["Uranium 235 Dust"] = "plasma.uranium235",
    ["Uranium 238 Dust"] = "plasma.uranium",
    ["Vanadium Dust"] = "plasma.vanadium",
    ["Ytterbium Dust"] = "plasma.ytterbium",
    ["Yttrium Dust"] = "plasma.yttrium",
    ["Zinc Dust"] = "plasma.zinc",
    ["Zirconium Dust"] = "plasma.zirconium",
}

MAGMATTER_ATLAS = {
    ["Awakened Draconium Dust"] = "plasma.draconiumawakened",
    ["Bedrockium Dust"] = "plasma.bedrockium",
    ["Celestial Tungsten Dust"] = "plasma.celestialtungsten",
    ["Chromatic Glass Dust"] = "plasma.chromaticglass",
    ["Cosmic Neutronium Dust"] = "plasma.cosmicneutronium",
    ["Draconium Dust"] = "plasma.draconium",
    ["Dragonblood Dust"] = "plasma.dragonblood",
    ["Flerovium Dust"] = "plasma.flerovium_gt5u",
    ["Hypogen Dust"] = "plasma.hypogen",
    ["Ichorium Dust"] = "plasma.ichorium",
    ["Infinity Dust"] = "plasma.infinity",
    ["Neutronium Dust"] = "plasma.neutronium",
    ["Rhugnor Dust"] = "plasma.rhugnor",
    ["Six-Phased Copper Dust"] = "plasma.sixphasedcopper",
    ["Tritanium Dust"] = "plasma.tritanium",
    ["Spatially Enlarged Fluid"] = "spatialfluid",
    ["Tachyon Rich Temporal Fluid"] = "temporalfluid",
}

-- ============================================================
-- discovery helpers
-- ============================================================

local function findMarkedInterface(label)
    for address in component.list("fluid_interface", true) do
        local proxy = component.proxy(address)
        local ok, pattern = pcall(proxy.getInterfacePattern, 1)

        if ok and pattern and pattern.outputs then
            for _, output in pairs(pattern.outputs) do
                if output.label == label then
                    return proxy
                end
            end
        end
    end

    return nil
end

local function findTransposerByMarkerSlot(markerSlot)
    for address in component.list("transposer", true) do
        local transposer = component.proxy(address)
        local activeSides = {}
        local markerSide

        for side = 0, 5 do
            local ok, size = pcall(transposer.getInventorySize, side)

            if ok and size and size > 0 then
                table.insert(activeSides, side)

                local stackOk, stack = pcall(transposer.getStackInSlot, side, markerSlot)
                if stackOk and stack then
                    markerSide = side
                end
            end
        end

        if markerSide then
            local otherSide

            for _, side in ipairs(activeSides) do
                if side ~= markerSide then
                    otherSide = side
                end
            end

            if otherSide then
                return {
                    proxy = transposer,
                    markerSide = markerSide,
                    otherSide = otherSide,
                    markerSlot = markerSlot
                }
            end
        end
    end

    return nil
end

local function getDriveSlots(shuttle, side)
    local slots = {}

    for slot = IO_OUTPUT_FIRST_SLOT, IO_OUTPUT_FIRST_SLOT + IO_SLOT_COUNT - 1 do
        if not (side == shuttle.markerSide and slot == shuttle.markerSlot) then
            local ok, stack = pcall(shuttle.proxy.getStackInSlot, side, slot)

            if ok and stack then
                table.insert(slots, slot)
            end
        end
    end

    return slots
end

local function moveDriveSlots(shuttle, sourceSide, targetSide, slots)
    for i, sourceSlot in ipairs(slots) do
        local moved = shuttle.proxy.transferItem(
            sourceSide,
            targetSide,
            1,
            sourceSlot,
            IO_INPUT_FIRST_SLOT + i - 1
        )

        assert(moved and moved > 0, "failed to move output drive")
    end
end

-- ============================================================
-- auto run & updates
-- ============================================================

local SCRIPT_PATH = "/home/gorge-controller.lua"
local SHRC_PATH = "/home/.shrc"

local function ensureAutorun()
    local content = ""
    local file = io.open(SHRC_PATH, "r")

    if file then
        content = file:read("*a") or ""
        file:close()
    end

    if not content:find(SCRIPT_PATH, 1, true) then
        file = assert(io.open(SHRC_PATH, "a"))
        file:write(SCRIPT_PATH .. "\n")
        file:close()
    end
end

-- ============================================================
-- Networking & Auto updates
-- ============================================================

local VERSION = "1.3.8"
local UPDATE_VERSION_URL = "https://raw.githubusercontent.com/Flouid/gtnh-gorge-controller/main/VERSION"
local UPDATE_SCRIPT_URL = "https://raw.githubusercontent.com/Flouid/gtnh-gorge-controller/main/gorge-controller-legacy.lua"

local function httpRequest(url, postData, headers)
    local internetAddress
    for address in component.list("internet", true) do internetAddress = address end
    if not internetAddress then return nil, "no Internet Card found" end
    local internet = component.proxy(internetAddress)

    local requestOk, handle = pcall(internet.request, url, postData, headers)
    if not requestOk or not handle then
        return nil, "request failed: " .. tostring(handle)
    end

    local chunks = {}
    local attempts = 0
    while true do
        local ok, chunk, _ = pcall(handle.read)
        if ok then
            if not chunk then
                pcall(handle.close)
                return table.concat(chunks)
            end
            table.insert(chunks, chunk)
        else
            attempts = attempts + 1
            if attempts > 50 then
                pcall(handle.close)
                return nil, "timed out: " .. tostring(chunk)
            end
            os.sleep(0.1)
        end
    end
end

local function httpGet(url)
    return httpRequest(url, nil, nil)
end

local update_applied = false;

local function checkForUpdate()
    local remoteVersionStr, _ = httpGet(UPDATE_VERSION_URL)
    local remoteVersion = remoteVersionStr:match("^%s*(%d+%.%d+%.%d+)%s*$")

    if DEBUG then
        print("Current version: " .. VERSION)
        print("Latest version: " .. (remoteVersion or "unknown"))
    end

    if not remoteVersion or remoteVersion == VERSION then
        print("No updates available")
        return
    end

    local newScript, _ = httpGet(UPDATE_SCRIPT_URL)

    local file = io.open(SCRIPT_PATH, "w")
    file:write(newScript)
    file:close()

    print("Updated to version " .. remoteVersion .. ", restarting...")
    update_applied = true
    os.sleep(2)
end

-- ============================================================
-- runtime resources
-- ============================================================

FabricatorInterface = nil
FabricatorRecipe = nil
FabricatorPatternSize = 0
FabricatorOwner = nil
PlasmaMonitorInterface = nil
PlasmaSubscribed = false
GPU = nil
DisplayWidth = 0
DisplayHeight = 0

local STATE_WAIT_OUTPUT = 1
local STATE_WAIT_OUTPUT_EMPTY = 2
local STATE_WAIT_FABRICATOR = 3
local STATE_WAIT_PLASMA = 4

local STATE_DISPLAY = {
    [STATE_WAIT_OUTPUT] = "Waiting for exoticizer outputs",
    [STATE_WAIT_OUTPUT_EMPTY] = "Flushing outputs to main",
    [STATE_WAIT_FABRICATOR] = "Waiting for fabricator",
    [STATE_WAIT_PLASMA] = "Waiting for plasma"
}

local QGP = {
    enabled = ENABLE_QGP,
    name = "QGP",
    atlas = QGP_ATLAS,
    outputMarker = "QGP Output",
    inputMarker = "QGP Input",
    productLabel = "Degenerate Quark Gluon Plasma",
    expectedOutputs = 7,
    outputMarkerSlot = QGP_OUTPUT_MARKER_SLOT,
    outputDriveCount = 3,
    displayRow = 1
}

local Magmatter = {
    enabled = ENABLE_MAGMATTER,
    name = "Magmatter",
    atlas = MAGMATTER_ATLAS,
    outputMarker = "Magmatter Output",
    inputMarker = "Magmatter Input",
    productLabel = "Molten Magmatter",
    expectedOutputs = 3,
    outputMarkerSlot = MAGMATTER_OUTPUT_MARKER_SLOT,
    outputDriveCount = 2,
    displayRow = 2
}

local Modules = {QGP, Magmatter}

-- ============================================================
-- helpers
-- ============================================================

local function checkOutputEmpty(module)
    local fluids = module.outputInterface.getFluidsInNetwork()

    if next(fluids) then return false end

    local items = module.outputInterface.getItemsInNetwork()

    for _, item in pairs(items) do
        if item.label ~= module.outputMarker then return false end
    end

    return true
end

local function getPlasmaStock()
    local stock = {}

    for _, fluid in pairs(PlasmaMonitorInterface.getFluidsInNetwork()) do
        stock[fluid.name] = fluid.amount
    end

    return stock
end

local function getMissingPlasma(demand, stock)
    stock = stock or getPlasmaStock()

    local missing = {}

    for plasma, info in pairs(demand) do
        if (stock[plasma] or 0) < info.amount then
            missing[plasma] = info
        end
    end

    return missing
end

local function getFabricatorSource(source, type)
    local override = FABRICATOR_SOURCE_OVERRIDES[source.label]

    if override then
        return override
    end

    return {
        name = source.name,
        damage = source.damage,
        label = source.label,
        type = type,
        batchAmount = BATCH_SIZE[type]
    }
end

local function getPatternSize(interface)
    local pattern = assert(interface.getInterfacePattern(1), "no pattern in interface")
    local size = 0

    for slot in pairs(pattern.inputs) do
        if slot > size then size = slot end
    end

    return size
end

local function clearUnusedPatternInputs(interface, first, previousSize)
    for slot = first, previousSize do
        interface.clearInterfacePatternInput(1, slot)
    end
end

local function setPatternInput(interface, slot, source, type, amount)
    if type == "ITEM" then
        interface.setInterfacePatternInput(1, slot, {
            name = source.name,
            damage = source.damage,
            size = amount
        }, "item")
    else
        interface.setInterfacePatternInput(1, slot, {
            name = source.name,
            size = amount
        }, "fluid")
    end
end

local function orderPattern(recipe)
    return recipe.request(1)
end

local function printMaterialShortages(module)
    print(module.name .. " craft failed. Current material shortages:")

    for _, info in pairs(module.missingPlasma) do
        local source = info.source
        local needed = source.batchAmount
        local stored

        if source.type == "ITEM" then
            stored = FabricatorInterface.getItemInNetwork(
                source.name,
                source.damage
            )
        else
            stored = FabricatorInterface.getFluidInNetwork(source.name)
        end

        local available = stored and (stored.size or stored.amount) or 0

        if available < needed then
            print("\t" .. source.label .. ": "
                .. available .. " / " .. needed)
        end
    end
end

local function checkForOutputs(module)
    local items = module.outputInterface.getItemsInNetwork()
    local count = 0

    for i, item in pairs(items) do
        if item.label == module.outputMarker then
            items[i] = nil
        else
            count = count + 1
        end
    end

    local fluids = {}

    if count < module.expectedOutputs then
        fluids = module.outputInterface.getFluidsInNetwork()

        for i, fluid in pairs(fluids) do
            if fluid.label == module.productLabel then
                fluids[i] = nil
            else
                count = count + 1
            end
        end
    end

    if count == module.expectedOutputs then
        if DEBUG then
            print(module.name .. " outputs detected:")

            for _, item in pairs(items) do
                print("\t" .. item.size .. " " .. item.label)
            end

            for _, fluid in pairs(fluids) do
                print("\t" .. fluid.amount .. "L " .. fluid.label)
            end
        end

        return items, fluids
    end
end

local function flushOutputs(module)
    local drives = getDriveSlots(module.outputShuttle, module.outputShuttle.otherSide)

    assert(
        #drives == module.outputDriveCount,
        "expected " .. module.outputDriveCount .. " " .. module.name
            .. " output drives, found " .. #drives
    )

    moveDriveSlots(
        module.outputShuttle,
        module.outputShuttle.otherSide,
        module.outputShuttle.markerSide,
        drives
    )
end

local function finishFlushOutputs(module)
    os.sleep(OUTPUT_SETTLE_TIME)

    local drives = getDriveSlots(module.outputShuttle, module.outputShuttle.markerSide)

    assert(
        #drives == module.outputDriveCount,
        "expected " .. module.outputDriveCount .. " " .. module.name
            .. " output drives to return, found " .. #drives
    )

    moveDriveSlots(
        module.outputShuttle,
        module.outputShuttle.markerSide,
        module.outputShuttle.otherSide,
        drives
    )
end

local function calculateQGPDemand(items, fluids)
    local demand = {}

    for _, item in pairs(items) do
        local plasma = QGP_ATLAS[item.label]
        assert(plasma, "No QGP plasma mapping for item: " .. item.label)

        demand[plasma] = {
            amount = 9 * 144 * item.size,
            source = getFabricatorSource(item, "ITEM")
        }
    end

    for _, fluid in pairs(fluids) do
        local plasma = QGP_ATLAS[fluid.label]
        assert(plasma, "No QGP plasma mapping for fluid: " .. fluid.label)

        demand[plasma] = {
            amount = 1000 * fluid.amount,
            source = getFabricatorSource(fluid, "FLUID")
        }
    end

    return demand
end

local function calculateMagmatterDemand(items, fluids)
    local demand = {}
    local spatial
    local temporal

    for _, fluid in pairs(fluids) do
        if fluid.label == "Spatially Enlarged Fluid" then
            spatial = fluid.amount
        elseif fluid.label == "Tachyon Rich Temporal Fluid" then
            temporal = fluid.amount
        end
    end

    assert(spatial, "Magmatter challenge missing Spatially Enlarged Fluid")
    assert(temporal, "Magmatter challenge missing Tachyon Rich Temporal Fluid")

    local plasmaAmount = math.abs(spatial - temporal) * 144

    for _, item in pairs(items) do
        local plasma = MAGMATTER_ATLAS[item.label]
        assert(plasma, "No Magmatter plasma mapping for item: " .. item.label)

        demand[plasma] = {
            amount = plasmaAmount,
            source = getFabricatorSource(item, "ITEM")
        }
    end

    for _, fluid in pairs(fluids) do
        local plasma = MAGMATTER_ATLAS[fluid.label]
        assert(plasma, "No Magmatter plasma mapping for fluid: " .. fluid.label)

        demand[plasma] = {
            amount = fluid.amount,
            source = getFabricatorSource(fluid, "FLUID")
        }
    end

    return demand
end

local function calculatePlasmaDemand(module, items, fluids)
    if module == QGP then
        return calculateQGPDemand(items, fluids)
    end

    return calculateMagmatterDemand(items, fluids)
end

local function writeFabricatorPattern(missing)
    local slot = 1

    for _, info in pairs(missing) do
        local source = info.source
        setPatternInput(FabricatorInterface, slot, source, source.type, source.batchAmount)
        slot = slot + 1
    end

    clearUnusedPatternInputs(FabricatorInterface, slot, FabricatorPatternSize)
    FabricatorPatternSize = slot - 1
end

local function feedPlasma(module)
    local slot = 1

    for plasma, info in pairs(module.demand) do
        setPatternInput(module.inputInterface, slot, {name = plasma}, "FLUID", info.amount)
        slot = slot + 1
    end

    clearUnusedPatternInputs(module.inputInterface, slot, module.inputPatternSize)
    module.inputPatternSize = slot - 1

    return orderPattern(module.inputRecipe)
end

-- ============================================================
-- display
-- ============================================================

local function renderModule(module)
    local status = module.enabled and STATE_DISPLAY[module.state] or "Disabled"
    local text = module.name .. ": " .. status
    text = text:sub(1, DisplayWidth)

    GPU.set(1, module.displayRow, text .. string.rep(" ", DisplayWidth - #text))
end

local updateSubscriptions

local function setState(module, newState)
    if module.state == newState then return end

    module.state = newState

    if newState == STATE_WAIT_OUTPUT
        or newState == STATE_WAIT_OUTPUT_EMPTY then
        module.outputRescanAt = computer.uptime() + OUTPUT_RESCAN_INTERVAL
    else
        module.outputRescanAt = nil
    end

    renderModule(module)

    if updateSubscriptions then
        updateSubscriptions()
    end
end

-- ============================================================
-- event subscriptions
-- ============================================================

local function setOutputSubscription(module, enabled)
    if not module.enabled or module.outputSubscribed == enabled then return end

    module.outputInterface.setItemEventSubscription(enabled)
    module.outputInterface.setFluidEventSubscription(enabled)
    module.outputSubscribed = enabled
end

updateSubscriptions = function()
    for _, module in ipairs(Modules) do
        if module.enabled then
            local wantsOutput =
                module.state == STATE_WAIT_OUTPUT
                or module.state == STATE_WAIT_OUTPUT_EMPTY

            setOutputSubscription(module, wantsOutput)
        end
    end

    local wantsPlasma = false

    for _, module in ipairs(Modules) do
        if module.enabled and module.state == STATE_WAIT_PLASMA then
            wantsPlasma = true
            break
        end
    end

    if PlasmaMonitorInterface and PlasmaSubscribed ~= wantsPlasma then
        PlasmaMonitorInterface.setFluidEventSubscription(wantsPlasma)
        PlasmaSubscribed = wantsPlasma
    end
end

local function recordEvent(batch, eventName, sourceAddress)
    if not eventName then return end

    batch.types[eventName] = true

    local sources = batch.sources[eventName]
    if not sources then
        sources = {}
        batch.sources[eventName] = sources
    end

    -- A normal component signal always has a source address. Preserve a
    -- source-less event as a wildcard so a malformed or synthetic signal
    -- still causes a safe rescan rather than being ignored.
    sources[sourceAddress or false] = true
end

local function pullDebounced(timeout)
    local batch = {types = {}, sources = {}}
    local eventName, sourceAddress

    if timeout then
        eventName, sourceAddress = event.pull(timeout)
    else
        eventName, sourceAddress = event.pull()
    end

    recordEvent(batch, eventName, sourceAddress)

    if eventName ~= "network_item_changed"
        and eventName ~= "network_fluid_changed" then
        return batch
    end

    local deadline = computer.uptime() + EVENT_DEBOUNCE_TIME

    while true do
        local remaining = deadline - computer.uptime()
        if remaining <= 0 then break end

        local nextEvent, nextSource = event.pull(remaining)
        recordEvent(batch, nextEvent, nextSource)
    end

    return batch
end

local function hasInterfaceEvent(batch, eventName, interface)
    if not batch or not batch.types[eventName] then return false end

    local sources = batch.sources[eventName]
    if not sources or sources[false] then return true end

    local address = interface and interface.address
    return not address or sources[address] == true
end

local function hasOutputEvent(batch, module)
    return hasInterfaceEvent(batch, "network_item_changed", module.outputInterface)
        or hasInterfaceEvent(batch, "network_fluid_changed", module.outputInterface)
end

-- ============================================================
-- fabricator coordination
-- ============================================================

local serviceFabricatorQueue
local finishPlasmaWait

local function tryStartFabrication(module)
    if not module.enabled
        or module.state ~= STATE_WAIT_FABRICATOR
        or FabricatorOwner
        or module.fabricatorRetryAt then
        return
    end

    FabricatorOwner = module
    writeFabricatorPattern(module.missingPlasma)
    module.fabricatorCraft = orderPattern(FabricatorRecipe)
    module.fabricatorRetryAt = computer.uptime() + 1
end

serviceFabricatorQueue = function()
    if FabricatorOwner then return end

    for _, module in ipairs(Modules) do
        if module.enabled
            and module.state == STATE_WAIT_FABRICATOR
            and not module.fabricatorRetryAt then
            tryStartFabrication(module)
            return
        end
    end
end

local function handleFabricatorTimer(module)
    if not module.enabled
        or module.state ~= STATE_WAIT_FABRICATOR
        or not module.fabricatorRetryAt
        or computer.uptime() < module.fabricatorRetryAt then
        return
    end

    if FabricatorOwner == module and module.fabricatorCraft then
        if module.fabricatorCraft.isComputing() then
            module.fabricatorRetryAt = computer.uptime() + 1
            return
        end

        if module.fabricatorCraft.hasFailed() then
            printMaterialShortages(module)
            module.fabricatorCraft = nil
            module.fabricatorRetryAt = computer.uptime() + 60
            FabricatorOwner = nil
            serviceFabricatorQueue()
            return
        end

        module.fabricatorCraft = nil
        module.fabricatorRetryAt = nil
        FabricatorOwner = nil

        setState(module, STATE_WAIT_PLASMA)

        local stock = getPlasmaStock()
        module.missingPlasma = getMissingPlasma(module.demand, stock)

        if next(module.missingPlasma) == nil then
            finishPlasmaWait(module)
        end

        serviceFabricatorQueue()
        return
    end

    if FabricatorOwner and FabricatorOwner ~= module then
        module.fabricatorRetryAt = nil
        return
    end

    module.fabricatorRetryAt = nil
    tryStartFabrication(module)
end

-- ============================================================
-- module state machines
-- ============================================================

local function beginCycle(module)
    module.cycleItems = nil
    module.cycleFluids = nil
    module.demand = nil
    module.missingPlasma = nil
    module.fabricatorCraft = nil
    module.fabricatorRetryAt = nil
    module.exoticizerCraft = nil

    setState(module, STATE_WAIT_OUTPUT)
end

finishPlasmaWait = function(module)
    module.fabricatorCraft = nil
    module.fabricatorRetryAt = nil
    module.missingPlasma = nil

    -- Subscribe to this module's output before ordering the input pattern so
    -- an extremely fast Exoticizer cycle cannot finish before we are listening.
    setState(module, STATE_WAIT_OUTPUT)

    local craft = feedPlasma(module)
    if DEBUG then module.exoticizerCraft = craft end

    module.cycleItems = nil
    module.cycleFluids = nil
    module.demand = nil
end

local function checkExoticizerCraft(module)
    if not DEBUG or not module.exoticizerCraft or module.exoticizerCraft.isComputing() then return end

    if module.exoticizerCraft.hasFailed() then
        print("WARNING: AE2 reported " .. module.name .. " craft failure, waiting for exoticizer...")
    end

    module.exoticizerCraft = nil
end

local function advanceModule(module, eventBatch, plasmaStock)
    if not module.enabled then return end

    checkExoticizerCraft(module)

    if module.state == STATE_WAIT_OUTPUT then
        if eventBatch and not hasOutputEvent(eventBatch, module) then return end

        -- An event-driven scan is as useful as a timer-driven scan. Move the
        -- fallback out so a timer does not immediately duplicate this work,
        -- while still guaranteeing another check if no further event arrives.
        module.outputRescanAt = computer.uptime() + OUTPUT_RESCAN_INTERVAL

        local items, fluids = checkForOutputs(module)
        if not items then return end

        module.cycleItems = items
        module.cycleFluids = fluids

        setState(module, STATE_WAIT_OUTPUT_EMPTY)
        flushOutputs(module)
        return
    end

    if module.state == STATE_WAIT_OUTPUT_EMPTY then
        if eventBatch and not hasOutputEvent(eventBatch, module) then return end

        module.outputRescanAt = computer.uptime() + OUTPUT_RESCAN_INTERVAL

        if not checkOutputEmpty(module) then return end

        finishFlushOutputs(module)

        module.demand = calculatePlasmaDemand(
            module,
            module.cycleItems,
            module.cycleFluids
        )

        module.cycleItems = nil
        module.cycleFluids = nil
        module.missingPlasma = getMissingPlasma(module.demand, plasmaStock)

        if next(module.missingPlasma) == nil then
            finishPlasmaWait(module)
            return
        end

        setState(module, STATE_WAIT_FABRICATOR)
        serviceFabricatorQueue()
        return
    end

    if module.state == STATE_WAIT_PLASMA then
        if not hasInterfaceEvent(
            eventBatch,
            "network_fluid_changed",
            PlasmaMonitorInterface
        ) then
            return
        end

        module.missingPlasma = getMissingPlasma(module.demand, plasmaStock)

        if next(module.missingPlasma) == nil then
            finishPlasmaWait(module)
        end
    end
end

local function advanceQGP(eventBatch, plasmaStock)
    advanceModule(QGP, eventBatch, plasmaStock)
end

local function advanceMagmatter(eventBatch, plasmaStock)
    advanceModule(Magmatter, eventBatch, plasmaStock)
end

local function dispatchEvents(eventBatch)
    local plasmaStock

    if hasInterfaceEvent(
        eventBatch,
        "network_fluid_changed",
        PlasmaMonitorInterface
    ) then
        for _, module in ipairs(Modules) do
            if module.enabled and module.state == STATE_WAIT_PLASMA then
                plasmaStock = getPlasmaStock()
                break
            end
        end
    end

    if ENABLE_QGP then
        advanceQGP(eventBatch, plasmaStock)
    end

    if ENABLE_MAGMATTER then
        advanceMagmatter(eventBatch, plasmaStock)
    end

    serviceFabricatorQueue()
end

local function getNextTimer()
    local nextTimer

    for _, module in ipairs(Modules) do
        if module.enabled then
            if module.fabricatorRetryAt
                and (not nextTimer or module.fabricatorRetryAt < nextTimer) then
                nextTimer = module.fabricatorRetryAt
            end

            if module.outputRescanAt
                and (not nextTimer or module.outputRescanAt < nextTimer) then
                nextTimer = module.outputRescanAt
            end
        end
    end

    return nextTimer
end

local function handleTimers()
    local now = computer.uptime()

    for _, module in ipairs(Modules) do
        if module.enabled
            and module.fabricatorRetryAt
            and now >= module.fabricatorRetryAt then
            handleFabricatorTimer(module)
        end

        if module.enabled
            and (module.state == STATE_WAIT_OUTPUT
                or module.state == STATE_WAIT_OUTPUT_EMPTY)
            and module.outputRescanAt
            and now >= module.outputRescanAt then
            advanceModule(module)
        end
    end

    serviceFabricatorQueue()
end

-- ============================================================
-- runtime
-- ============================================================

local function discoverModule(module)
    module.outputInterface = findMarkedInterface(module.outputMarker)
    assert(module.outputInterface, "could not find " .. module.name .. " output subnet")

    module.inputInterface = findMarkedInterface(module.inputMarker)
    assert(module.inputInterface, "could not find " .. module.name .. " input interface")

    module.outputShuttle = findTransposerByMarkerSlot(module.outputMarkerSlot)
    assert(module.outputShuttle, "could not find " .. module.name .. " output transposer")

    local markerDrives = getDriveSlots(
        module.outputShuttle,
        module.outputShuttle.markerSide
    )

    if #markerDrives > 0 then
        moveDriveSlots(
            module.outputShuttle,
            module.outputShuttle.markerSide,
            module.outputShuttle.otherSide,
            markerDrives
        )

        os.sleep(OUTPUT_SETTLE_TIME)
    end

    local restingDrives = getDriveSlots(
        module.outputShuttle,
        module.outputShuttle.otherSide
    )

    assert(
        #restingDrives == module.outputDriveCount,
        "expected " .. module.outputDriveCount .. " " .. module.name
            .. " output drives at startup, found " .. #restingDrives
    )

    module.inputPatternSize = getPatternSize(module.inputInterface)

    module.inputRecipe = module.inputInterface.getCraftables({label = module.inputMarker})[1]
    assert(module.inputRecipe, "could not find " .. module.name .. " input pattern")

    module.outputSubscribed = false
end

local function startup()
    if DEBUG then
        for address, kind in component.list() do
            print(kind, address)
        end
    end

    print("Discovering components...")

    if ENABLE_QGP then
        discoverModule(QGP)
    end

    if ENABLE_MAGMATTER then
        discoverModule(Magmatter)
    end

    if ENABLE_QGP or ENABLE_MAGMATTER then
        FabricatorInterface = findMarkedInterface("Fabricator")
        assert(FabricatorInterface, "could not find gorge fabricator")

        FabricatorPatternSize = getPatternSize(FabricatorInterface)

        FabricatorRecipe = FabricatorInterface.getCraftables({label = "Fabricator"})[1]
        assert(FabricatorRecipe, "could not find fabricator pattern")

        PlasmaMonitorInterface =
            (ENABLE_QGP and QGP.inputInterface)
            or (ENABLE_MAGMATTER and Magmatter.inputInterface)
    end

    local address = component.list("gpu", true)()
    assert(address, "could not find GPU")

    GPU = component.proxy(address)
    DisplayWidth, DisplayHeight = GPU.getResolution()
    GPU.fill(1, 1, DisplayWidth, DisplayHeight, " ")

    renderModule(QGP)
    renderModule(Magmatter)
end

-- ============================================================
-- persistent loop
-- ============================================================

ensureAutorun()
if ENABLE_AUTO_UPDATE then checkForUpdate() end

if update_applied then
    computer.shutdown(true)
end

startup()

if ENABLE_QGP then
    beginCycle(QGP)
end

if ENABLE_MAGMATTER then
    beginCycle(Magmatter)
end

if ENABLE_QGP then
    advanceQGP()
end

if ENABLE_MAGMATTER then
    advanceMagmatter()
end

updateSubscriptions()

while true do
    handleTimers()

    local nextTimer = getNextTimer()
    local timeout

    if nextTimer then
        timeout = math.max(0, nextTimer - computer.uptime())
    end

    local eventBatch = pullDebounced(timeout)

    if eventBatch.types.network_item_changed
        or eventBatch.types.network_fluid_changed then
        dispatchEvents(eventBatch)
    end
end
