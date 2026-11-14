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
local configCache = {} -- config file -> whether it comes from a mod

-- Whether a file is mounted from the game's own folder (the same test the game
-- uses to label vehicles "BeamNG - Official").
local function fromGame(path)
  gamePath = gamePath or FS:getGamePath()
  local origin = FS:getFileOriginInfo(path)
  local mount = origin and origin.mountPath
  return type(mount) == "string" and mount:sub(1, #gamePath) == gamePath
end

-- Whether a file comes from an installed mod, found the way the game finds a
-- config's mod. Files in the player's own folder (saved configs) belong to no
-- mod.
local function fromMod(path)
  if type(path) ~= "string" or fromGame(path) then
    return false
  end
  local modmanager = core_modmanager
  if not modmanager or type(modmanager.getModFromOriginArchivePath) ~= "function" then
    return false
  end
  local origin = FS:getFileOriginInfo(path)
  return origin ~= nil and modmanager.getModFromOriginArchivePath(origin.archivePath) ~= nil
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
  -- modID is only set for mods from the BeamNG repository, so mods installed
  -- from a zip are found from the config file's origin.
  if config.modID ~= nil then
    return true
  end
  local pc = config.pcFilename
  if type(pc) ~= "string" then
    return false
  end
  local cached = configCache[pc]
  if cached == nil then
    cached = fromMod(pc)
    configCache[pc] = cached
  end
  return cached
end

local function forget()
  modelCache = {}
  configCache = {}
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
-- Type reads as Modded, so its configs are found. In a game vehicle's own
-- group, configs a mod adds to it read as Modded too, so they are listed only
-- under Modded. A modded vehicle's configs read as usual outside Modded,
-- because the random vehicle button opens a car through its type group.
local function getConfigOrModelPropValue(config, prop)
  if prop == "Type" and openGroup ~= nil then
    local ok, modded = pcall(isModded, config)
    if ok and modded then
      if openGroup == groupName then
        return moddedType
      end
      local okModel, moddedModel = pcall(isModdedModel, config.model_key)
      if okModel and not moddedModel then
        return moddedType
      end
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

-- The random vehicle button picks a config, marks it to be selected, and opens
-- its car in the group its Type gives (Cars and Trucks for a modded car).
-- Paddock notes the config the button marks and, if it's modded, opens the car
-- in the Modded group instead, where the player finds it.
local picking = false -- a selector button is running
local picked -- the config that button marked to be selected

local function overrideDefaultSelectedTile(tile, ...)
  if picking then
    picked = tile
  end
  return original.overrideDefaultSelectedTile(tile, ...)
end

local function openInModded(data)
  local path = type(data) == "table" and type(data.gotoPath) == "table" and data.gotoPath.keys
  if
    type(path) == "table"
    and path[1] == "configsForBrandSubModelOrModel"
    and path[5] == "Type"
    and path[6] ~= groupName
    and isModded(picked)
  then
    path[6] = groupName
  end
end

local function executeButton(...)
  picking, picked = true, nil
  local data = original.executeButton(...)
  picking = false
  pcall(openInModded, data)
  picked = nil
  return data
end

-- The selector's UI extensions can load after Paddock, so this is tried again
-- whenever the selector lists vehicles.
local function hookRandom()
  if original.executeButton or not grouping then
    return
  end
  local general, tiles = ui_vehicleSelector_general, ui_vehicleSelector_tiles
  if
    type(general) ~= "table"
    or type(tiles) ~= "table"
    or type(general.executeButton) ~= "function"
    or type(tiles.overrideDefaultSelectedTile) ~= "function"
  then
    return
  end
  original.executeButton = general.executeButton
  original.overrideDefaultSelectedTile = tiles.overrideDefaultSelectedTile
  general.executeButton = executeButton
  tiles.overrideDefaultSelectedTile = overrideDefaultSelectedTile
end

local function onVehicleSelectorGetTiles(_, _, _, _, groupMode, name)
  openGroup = groupMode == "Type" and name or nil
  hookRandom()
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
  hookRandom()
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
  local general, tiles = ui_vehicleSelector_general, ui_vehicleSelector_tiles
  if type(general) == "table" and general.executeButton == executeButton then
    general.executeButton = original.executeButton
  end
  if type(tiles) == "table" and tiles.overrideDefaultSelectedTile == overrideDefaultSelectedTile then
    tiles.overrideDefaultSelectedTile = original.overrideDefaultSelectedTile
  end
  grouping, original, openGroup = nil, {}, nil
end

M.onExtensionLoaded = hook
M.onExtensionUnloaded = unhook
M.onVehicleSelectorGetTiles = onVehicleSelectorGetTiles
M.onGridSelectorGetTiles = hookRandom
-- Mods can be switched on and off while the game runs.
M.onModActivated = forget
M.onModDeactivated = forget
M.onFileChanged = forget
M.isModded = isModded

return M
