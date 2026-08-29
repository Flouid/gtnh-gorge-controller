-- Gorge Controller
-- Author: flouid
-- Automates one QGP Exoticiser cycle at a time.
-- Ctrl+Alt+C to exit.

-- credit where it's due, much of this is stolen Armisael's BEC script: https://github.com/Armisael5/gtnh-bec-controller/tree/main

local component = require("component")
local computer = require("computer")
local event = require("event")
local sides = require("sides")

-- ============================================================
-- config
-- ============================================================

DEBUG = false
BATCH_MULTIPLIER = 2^16
BATCH_SIZE = {
    ITEM = BATCH_MULTIPLIER,
    FLUID = 1000 * BATCH_MULTIPLIER
}
PLASMAS = {
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

-- ============================================================
-- discovery helpers
-- ============================================================

local function findMarkedInterface(label)
  for address in component.list("fluid_interface", true) do
    local proxy = component.proxy(address)
    local ok, items = pcall(proxy.getItemsInNetwork)
    if ok and items then
      for _, item in pairs(items) do
        if item.label == label then return proxy end
      end
    end
  end
  return nil
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

local VERSION = "1.1.5"
local UPDATE_VERSION_URL = "https://raw.githubusercontent.com/Flouid/gtnh-gorge-controller/develop/VERSION"
local UPDATE_SCRIPT_URL = "https://raw.githubusercontent.com/Flouid/gtnh-gorge-controller/develop/gorge-controller.lua"

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
-- helpers
-- ============================================================

local function checkOutputEmpty()
    local fluids = OutputInterface.getFluidsInNetwork()
    if next(fluids) then return false end

    local items = OutputInterface.getItemsInNetwork()
    for _, item in pairs(items) do
        if item.label ~= "Output" then return false end
    end

    return true
end

local function getMissingPlasma(demand)
    local stock = {}

    for _, fluid in pairs(PlasmaInterface.getFluidsInNetwork()) do
        stock[fluid.name] = fluid.amount
    end

    local missing = {}
    for plasma, info in pairs(demand) do
        if (stock[plasma] or 0) < info.amount then
            missing[plasma] = info
        end
    end

    return missing
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

local function printMaterialShortages(missing)
    print("Craft failed. Current material shortages:")

    for _, info in pairs(missing) do
        local source = info.source
        local needed = BATCH_SIZE[info.type]
        local stored

        if info.type == "ITEM" then
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

-- ============================================================
-- cycle steps
-- ============================================================

-- Step 1: Check for the exoticizer to output some combination of items and fluids, then return them
local function checkForOutputs()
    local items = OutputInterface.getItemsInNetwork()
    local count = 0

    for i, item in pairs(items) do
        if item.label == "Output" then
            items[i] = nil
        else
            count = count + 1
        end
    end

    local fluids = {}
    if count < 7 then
        fluids = OutputInterface.getFluidsInNetwork()

        for i, fluid in pairs(fluids) do
            if fluid.label == "Degenerate Quark Gluon Plasma" then
                fluids[i] = nil
            else
                count = count + 1
            end
        end
    end

    if count == 7 then
        if DEBUG then
            print("Outputs detected:")
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

-- Step 2: Flush the outputs to main, we do not need them anymore (and prep for next cycle)
local function flushOutputs()
    RedstoneIO.setOutput({
        [sides.bottom] = 15,
        [sides.top] = 15,
        [sides.north] = 15,
        [sides.south] = 15,
        [sides.west] = 15,
        [sides.east] = 15
    })
end

local function finishFlushOutputs()
    RedstoneIO.setOutput({
        [sides.bottom] = 0,
        [sides.top] = 0,
        [sides.north] = 0,
        [sides.south] = 0,
        [sides.west] = 0,
        [sides.east] = 0
    })
end

-- Step 3: Use the outputs from step 1 to calculate the specific plasma types and amounts needed to complete the recipe
local function calculatePlasmaDemand(items, fluids)
    local demand = {}
    for _, item in pairs(items) do
        local plasma = PLASMAS[item.label]
        assert(plasma, "No plasma mapping for item: " .. item.label)
        demand[plasma] = {
            amount = 9 * 144 * item.size,
            source = item,
            type = "ITEM"
        }
    end

    for _, fluid in pairs(fluids) do
        local plasma = PLASMAS[fluid.label]
        assert(plasma, "No plasma mapping for fluid: " .. fluid.label)
        demand[plasma] = {
            amount = 1000 * fluid.amount,
            source = fluid,
            type = "FLUID"
        }
    end

    if DEBUG then
        print("Plasma demand calculated:")
        for plasma, info in pairs(demand) do
            print(plasma, info.amount, info.source.label)
        end
    end

    return demand
end

-- Step 4: Compare stocks to demand and create a pattern requesting the missing plasma types from the fabricator
local function orderPlasmaFabrication(missing)
    local slot = 1
    for _, info in pairs(missing) do
        setPatternInput(FabricatorInterface, slot, info.source, info.type, BATCH_SIZE[info.type])
        slot = slot + 1
    end

    clearUnusedPatternInputs(FabricatorInterface, slot, FabricatorPatternSize)
    FabricatorPatternSize = slot - 1

    return orderPattern(FabricatorRecipe)
end

local function ensurePlasmaAvailable(demand)
    local missing = getMissingPlasma(demand)
    if next(missing) == nil then return true end

    return false, missing, orderPlasmaFabrication(missing)
end

-- Step 5: Feed the plasma into the exoticizer to supply the demand from step 3 and complete the cycle
local function feedPlasma(demand)
    local slot = 1
    for plasma, info in pairs(demand) do
        setPatternInput(PlasmaInterface, slot, {name = plasma}, "FLUID", info.amount)
        slot = slot + 1
    end

    clearUnusedPatternInputs(PlasmaInterface, slot, PlasmaPatternSize)
    PlasmaPatternSize = slot - 1

    return orderPattern(PlasmaRecipe)
end

-- ============================================================
-- event state machine
-- ============================================================

local STATE_WAIT_OUTPUT = 1
local STATE_WAIT_OUTPUT_EMPTY = 2
local STATE_WAIT_PLASMA = 3

local STATE_DISPLAY = {
    [STATE_WAIT_OUTPUT] = "Waiting for exoticizer outputs",
    [STATE_WAIT_OUTPUT_EMPTY] = "Flushing outputs to main",
    [STATE_WAIT_PLASMA] = "Waiting for plasma"
}

local state = nil
local cycleItems = nil
local cycleFluids = nil
local demand = nil
local missingPlasma = nil
local fabricatorCraft = nil
local fabricatorRetryAt = nil
local exoticizerCraft = nil

local function render()
    local text = "QGP: " .. STATE_DISPLAY[state]
    text = text:sub(1, DisplayWidth)

    GPU.set(1, 1, text .. string.rep(" ", DisplayWidth - #text))
end

local function setState(newState)
    if state == newState then return end

    state = newState
    render()
end

local function subscribeOutput()
    PlasmaInterface.setFluidEventSubscription(false)

    OutputInterface.setItemEventSubscription(true)
    OutputInterface.setFluidEventSubscription(true)
end

local function subscribePlasma()
    OutputInterface.setItemEventSubscription(false)
    OutputInterface.setFluidEventSubscription(false)

    PlasmaInterface.setFluidEventSubscription(true)
end

local function pullDebounced(timeout)
    local eventName

    if timeout then
        eventName = event.pull(timeout)
    else
        eventName = event.pull()
    end

    if eventName ~= "network_item_changed"
        and eventName ~= "network_fluid_changed" then
        return eventName
    end

    local deadline = computer.uptime() + 0.05

    while true do
        local remaining = deadline - computer.uptime()
        if remaining <= 0 then break end

        event.pull(remaining)
    end

    return eventName
end

local function beginCycle()
    setState(STATE_WAIT_OUTPUT)
    cycleItems = nil
    cycleFluids = nil
    demand = nil
    missingPlasma = nil
    fabricatorCraft = nil
    fabricatorRetryAt = nil
end

local function finishPlasmaWait()
    fabricatorCraft = nil
    fabricatorRetryAt = nil
    missingPlasma = nil

    subscribeOutput()

    local craft = feedPlasma(demand)
    if DEBUG then exoticizerCraft = craft end

    beginCycle()
end

local function checkExoticizerCraft()
    if not DEBUG or not exoticizerCraft or exoticizerCraft.isComputing() then return end

    if exoticizerCraft.hasFailed() then
        print("WARNING: AE2 reported craft failure, waiting for exoticizer...")
    end

    exoticizerCraft = nil
end

local function advanceQGP(eventName)
    checkExoticizerCraft()

    if state == STATE_WAIT_OUTPUT then
        if eventName and eventName ~= "network_item_changed" and eventName ~= "network_fluid_changed" then return end

        local items, fluids = checkForOutputs()
        if not items then return end

        cycleItems = items
        cycleFluids = fluids
        setState(STATE_WAIT_OUTPUT_EMPTY)
        flushOutputs()
        return
    end

    if state == STATE_WAIT_OUTPUT_EMPTY then
        if eventName ~= "network_item_changed" and eventName ~= "network_fluid_changed" then return end
        if not checkOutputEmpty() then return end

        finishFlushOutputs()
        demand = calculatePlasmaDemand(cycleItems, cycleFluids)
        cycleItems = nil
        cycleFluids = nil

        local ready, missing, craft = ensurePlasmaAvailable(demand)
        if ready then
            finishPlasmaWait()
            return
        end

        missingPlasma = missing
        fabricatorCraft = craft
        fabricatorRetryAt = computer.uptime() + 1
        setState(STATE_WAIT_PLASMA)

        subscribePlasma()

        missingPlasma = getMissingPlasma(demand)
        if next(missingPlasma) == nil then
            finishPlasmaWait()
        end

        return
    end

    if state == STATE_WAIT_PLASMA then
        if eventName ~= "network_fluid_changed" then return end

        missingPlasma = getMissingPlasma(demand)
        if next(missingPlasma) == nil then
            finishPlasmaWait()
        end
    end
end

local function handleFabricatorTimer()
    if state ~= STATE_WAIT_PLASMA or not fabricatorRetryAt then return end

    if fabricatorCraft then
        if fabricatorCraft.isComputing() then
            fabricatorRetryAt = computer.uptime() + 1
            return
        end

        if fabricatorCraft.hasFailed() then
            printMaterialShortages(missingPlasma)
            fabricatorCraft = nil
            fabricatorRetryAt = computer.uptime() + 60
        else
            fabricatorRetryAt = nil
        end

        return
    end

    fabricatorCraft = orderPattern(FabricatorRecipe)
    fabricatorRetryAt = computer.uptime() + 1
end

-- ============================================================
-- runtime
-- ============================================================

OutputInterface = nil
PlasmaInterface = nil
FabricatorInterface = nil
RedstoneIO = nil
FabricatorRecipe = nil
PlasmaRecipe = nil
FabricatorPatternSize = 0
PlasmaPatternSize = 0
GPU = nil
DisplayWidth = 0
DisplayHeight = 0

local function startup()
    if DEBUG then
        for address, kind in component.list() do
            print(kind, address)
        end
    end

    print("Discovering components...")

    OutputInterface = findMarkedInterface("Output")
    assert(OutputInterface, "could not find gorge output subnet")

    PlasmaInterface = findMarkedInterface("Plasma")
    assert(PlasmaInterface, "could not find gorge plasma subnet")

    FabricatorInterface = findMarkedInterface("Fabricator")
    assert(FabricatorInterface, "could not find gorge fabricator")

    FabricatorPatternSize = getPatternSize(FabricatorInterface)
    PlasmaPatternSize = getPatternSize(PlasmaInterface)

    FabricatorRecipe = FabricatorInterface.getCraftables({label = "Fabricator"})[1]
    assert(FabricatorRecipe, "could not find fabricator pattern")

    PlasmaRecipe = PlasmaInterface.getCraftables({label = "Plasma"})[1]
    assert(PlasmaRecipe, "could not find plasma pattern")

    local address = component.list("redstone", true)()
    assert(address, "could not find redstone IO")
    RedstoneIO = component.proxy(address)

    address = component.list("gpu", true)()
    assert(address, "could not find GPU")
    GPU = component.proxy(address)
    DisplayWidth, DisplayHeight = GPU.getResolution()
    GPU.fill(1, 1, DisplayWidth, DisplayHeight, " ")

    subscribeOutput()
end

-- ============================================================
-- persistent loop
-- ============================================================

ensureAutorun()
checkForUpdate()

if update_applied then
    computer.shutdown(true)
end

startup()
beginCycle()
advanceQGP()

while true do
    if fabricatorRetryAt and computer.uptime() >= fabricatorRetryAt then
        handleFabricatorTimer()
    else
        local timeout = nil
        if fabricatorRetryAt then
            timeout = fabricatorRetryAt - computer.uptime()
        end

        local eventName = pullDebounced(timeout)

        if eventName == "network_item_changed" or eventName == "network_fluid_changed" then
            advanceQGP(eventName)
        end
    end
end
