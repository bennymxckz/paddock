-- Paddock: gives modded vehicles their own "Modded" group in the vehicle
-- selector, so they are kept apart from the game's own vehicles.
--
-- It only changes grouping by Type (the selector's default). Other "Group by"
-- options, favourites and recent vehicles work as before. If the selector's
-- code changes in a game update and the hook doesn't fit any more, Paddock
-- does nothing and the selector groups vehicles as usual.
--
-- SPDX-License-Identifier: MIT

local M = {}

M.version = "0.1.0"

local logTag = "paddock"
local groupingModule = "/lua/ge/extensions/ui/vehicleSelector/tileGrouping"
local groupName = "Modded"
-- Before Cars and Trucks (10 for cars, 20 for trucks); favourites (-1) and
-- recent vehicles (-2) stay on top.
local groupOrder = 5
-- Stands in for a modded config's Type while the Modded group is open.
local moddedType = "paddock:Modded"

local grouping
local original = {} -- the selector's functions Paddock wraps
local openGroup -- the group whose configs the selector is listing

local gamePath
local modelCache = {} -- model key -> whether the model comes from a mod

-- Whether a file is mounted from the game's own folder (the same test the game
-- uses to label vehicles "BeamNG - Official").
local function fromGame(path)
  gamePath = gamePath or FS:getGamePath()
  local origin = FS:getFileOriginInfo(path)
  local mount = origin and origin.mountPath
  return type(mount) == "string" and mount:sub(1, #gamePath) == gamePath
end

local function isModdedModel(modelKey)
  local cached = modelCache[modelKey]
  if cached ~= nil then
    return cached
  end
  local data = core_vehicles.getModel(modelKey)
  local model = data and data.model
  local info = "/vehicles/" .. modelKey .. "/info.json"
  local modded = model ~= nil and model.Type ~= "Automation" and FS:fileExists(info) and not fromGame(info)
  modelCache[modelKey] = modded
  return modded
end

-- A config is modded when its vehicle comes from a mod, or the config itself
-- does (a config pack for a game vehicle). Your own saved configs of game
-- vehicles stay with them, and Automation cars keep their own group.
local function isModded(config)
  if type(config) ~= "table" or not config.model_key then
    return false
  end
  if isModdedModel(config.model_key) then
    return true
  end
  return config.modID ~= nil
end

local function forget()
  modelCache = {}
end

-- Lists a modded config in the Modded group (when grouping by Type).
local function getGroupsForConfig(config, groupMode, displayData)
  local groups = original.getGroupsForConfig(config, groupMode, displayData)
  if groupMode ~= "Type" or type(groups) ~= "table" then
    return groups
  end
  local ok, modded = pcall(isModded, config)
  if not ok or not modded then
    return groups
  end
  for _, g in ipairs(groups) do
    if type(g) == "table" and not g.isFavouriteGroup and not g.isRecentGroup then
      g.groupName = groupName
      g.groupOrder = groupOrder
    end
  end
  return groups
end

-- Opening a car in a group lists the configs that belong to that group,
-- checked from their Type alone. Inside the Modded group a modded config's
-- Type reads as Modded, so its configs are found. Anywhere else (such as the
-- random vehicle button, which opens a car through its type group) it reads
-- as usual.
local function getConfigOrModelPropValue(config, prop)
  if prop == "Type" and openGroup == groupName then
    local ok, modded = pcall(isModded, config)
    if ok and modded then
      return moddedType
    end
  end
  return original.getConfigOrModelPropValue(config, prop)
end

local function typeGroup(value)
  if value == moddedType then
    return groupName, groupOrder
  end
  return original.typeGroup(value)
end

local function onVehicleSelectorGetTiles(_, _, _, _, groupMode, name)
  openGroup = groupMode == "Type" and name or nil
end

local function hook()
  local ok, mod = pcall(require, groupingModule)
  if
    not ok
    or type(mod) ~= "table"
    or type(mod.getGroupsForConfig) ~= "function"
    or type(mod.getConfigOrModelPropValue) ~= "function"
    or type(mod.groupModeFunctions) ~= "table"
    or type(mod.groupModeFunctions.Type) ~= "function"
  then
    log("W", logTag, "The vehicle selector's grouping isn't where Paddock expects it; leaving the selector as it is")
    return
  end
  if mod.getGroupsForConfig == getGroupsForConfig then
    return
  end
  grouping = mod
  original.getGroupsForConfig = mod.getGroupsForConfig
  original.getConfigOrModelPropValue = mod.getConfigOrModelPropValue
  original.typeGroup = mod.groupModeFunctions.Type
  mod.getGroupsForConfig = getGroupsForConfig
  mod.getConfigOrModelPropValue = getConfigOrModelPropValue
  mod.groupModeFunctions.Type = typeGroup
  log("I", logTag, "Paddock " .. M.version .. ': modded vehicles are grouped as "' .. groupName .. '"')
end

local function unhook()
  if grouping then
    if grouping.getGroupsForConfig == getGroupsForConfig then
      grouping.getGroupsForConfig = original.getGroupsForConfig
    end
    if grouping.getConfigOrModelPropValue == getConfigOrModelPropValue then
      grouping.getConfigOrModelPropValue = original.getConfigOrModelPropValue
    end
    if grouping.groupModeFunctions.Type == typeGroup then
      grouping.groupModeFunctions.Type = original.typeGroup
    end
  end
  grouping, original, openGroup = nil, {}, nil
end

M.onExtensionLoaded = hook
M.onExtensionUnloaded = unhook
M.onVehicleSelectorGetTiles = onVehicleSelectorGetTiles
-- Mods can be switched on and off while the game runs.
M.onModActivated = forget
M.onModDeactivated = forget
M.onFileChanged = forget
M.isModded = isModded

return M
