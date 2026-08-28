-- Gorge Controller
-- Author: flouid
-- Automates one QGP Exoticiser cycle at a time.
-- Ctrl+Alt+C to exit.

-- credit where it's due, much of this is stolen Armisael's BEC script: https://github.com/Armisael5/gtnh-bec-controller/tree/main

local component = require("component")
local computer = require("computer")

-- ============================================================
-- config
-- ============================================================

VERBOSE = true
DEBUG = false
BATCH_MULTIPLIER = 2^16
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
        if item.label == label then
          return proxy
        end
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

local VERSION = "0.2.10"
local UPDATE_VERSION_URL = "https://raw.githubusercontent.com/Flouid/gtnh-gorge-controller/main/VERSION"
local UPDATE_SCRIPT_URL = "https://raw.githubusercontent.com/Flouid/gtnh-gorge-controller/main/gorge-controller.lua"

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
    local cacheBust = tostring(computer.uptime())

    local remoteVersionStr, _ =
        httpGet(UPDATE_VERSION_URL .. "?v=" .. cacheBust)

    local remoteVersion =
        remoteVersionStr:match("^%s*(%d+%.%d+%.%d+)%s*$")

    if VERBOSE then
        print("Current version: " .. VERSION)
        print("Latest version: " .. (remoteVersion or "unknown"))
    end

    if not remoteVersion or remoteVersion == VERSION then
        print("No updates available")
        return
    end

    local newScript, _ =
        httpGet(UPDATE_SCRIPT_URL .. "?v=" .. cacheBust)

    local file = io.open(SCRIPT_PATH, "w")
    file:write(newScript)
    file:close()

    print("Updated to version " .. remoteVersion .. ", restarting...")
    update_applied = true
    os.sleep(3)
end

-- ============================================================
-- cycle steps
-- ============================================================

local function waitForOutputs()
    while true do
        local items = OutputInterface.getItemsInNetwork()
        local fluids = OutputInterface.getFluidsInNetwork()

        for i, item in pairs(items) do
            if item.label == "Output" then
                items[i] = nil
            end
        end

        if next(items) or next(fluids) then
            if VERBOSE then
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

        os.sleep(0.5)
    end
end

local function calculatePlasmaDemand(items, fluids)
    local demand = {}
    for _, item in pairs(items) do
        local plasma = PLASMAS[item.label]
        assert(plasma, "No plasma mapping for item: " .. item.label)
        demand[plasma] = {
            amount = 9 * 144 * item.size,
            source = item
        }
    end

    for _, fluid in pairs(fluids) do
        local plasma = PLASMAS[fluid.label]
        assert(plasma, "No plasma mapping for fluid: " .. fluid.label)
        demand[plasma] = {
            amount = 1000 * fluid.amount,
            source = fluid
        }
    end

    if VERBOSE then
        print("Plasma demand calculated:")
        for plasma, info in pairs(demand) do
            print(plasma, info.amount, info.source.label)
        end
    end

    return demand
end

local function getPlasmaStock()
    local stock = {}

    for _, fluid in pairs(PlasmaInterface.getFluidsInNetwork()) do
        stock[fluid.name] = fluid.amount
    end
    return stock
end

local function ensurePlasmaAvailable(demand)
    ;
end

local function feedPlasma(demand)
    ;
end

-- ============================================================
-- runtime
-- ============================================================

OutputInterface = nil
PlasmaInterface = nil
FabricatorInterface = nil
ExoticizerInterface = nil

local function startup()
    if DEBUG then
        for address, kind in component.list() do
            print(kind, address)
        end
    end

    print("Discovering subnets...")

    OutputInterface = findMarkedInterface("Output")
    assert(OutputInterface, "could not find gorge output subnet")

    PlasmaInterface = findMarkedInterface("Plasma")
    assert(PlasmaInterface, "could not find gorge plasma subnet")

    FabricatorInterface = findMarkedInterface("Fabricator")
    assert(FabricatorInterface, "could not find gorge fabricator")

    ExoticizerInterface = findMarkedInterface("Exoticizer")
    assert(ExoticizerInterface, "could not find gorge exoticizer")
end

local function runOneCycle()
    local items, fluids = waitForOutputs()
    local demand = calculatePlasmaDemand(items, fluids)

    ensurePlasmaAvailable(demand)

    feedPlasma(demand)
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

runOneCycle()

-- while true do
--     runOneCycle()
-- end
