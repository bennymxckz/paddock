-- Loads Paddock when the mod is mounted. Manual unload mode keeps it loaded
-- across level changes; it unloads when the mod is deactivated.
--
-- SPDX-License-Identifier: MIT

pcall(setExtensionUnloadMode, "paddock", "manual")
extensions.load("paddock")
