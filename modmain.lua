do
    local GLOBAL = GLOBAL
    local modEnv = GLOBAL.getfenv(1)
    local rawget, setmetatable = GLOBAL.rawget, GLOBAL.setmetatable
    setmetatable(modEnv, {
        __index = function(self, index)
            return rawget(GLOBAL, index)
        end
        -- lack of __newindex means it defaults to modEnv, so we don't mess up globals.
    })

    _G = GLOBAL
end

local EPIC_HEALTHBAR = "workshop-1185229307"

local modinfo = KnownModIndex:GetModInfo(EPIC_HEALTHBAR)
if modinfo == nil then
    print("ERROR: Epic Healthbar is not installed!")
    return
end

local raw_modinfo = KnownModIndex.savedata.known_mods[EPIC_HEALTHBAR]
if raw_modinfo ~= nil and raw_modinfo.temp_enabled then
    -- Server mod is enabled, so there's no point in loading the client mod.
    print("Server mod is enabled. Show Me compatibility will not be loaded.")
    return
end

-- This is stupid, horrible and just overall bad. This will surely break something in the future,
-- but for now it's the only way to make this work from my knowledge.
-- This basically mimics how the game loads mods, see ModWrangler:LoadMods.
-- First off we have to enable it so it shows clientside in the mod list and so the user can edit the settings.
KnownModIndex:Enable(EPIC_HEALTHBAR)
modinfo.all_clients_require_mod = false
modinfo.client_only_mod = true

-- After that we can actually load the mod settings which we just mentioned.
local options = KnownModIndex:LoadModConfigurationOptions(EPIC_HEALTHBAR, false)
KnownModIndex:SetTempModConfigData({ [EPIC_HEALTHBAR] = options })
KnownModIndex:LoadModConfigurationOptions(EPIC_HEALTHBAR, true)

-- We can then create an environment and load the manifest, so Klei's crazy loader can properly work with require,
-- in our case without this we couldn't use AddClassPostConstruct on the widget.
local worldgen = false
local env = CreateEnvironment(EPIC_HEALTHBAR, worldgen)

ManifestManager:LoadModManifest(EPIC_HEALTHBAR, modinfo.version)
package.path = MODS_ROOT .. EPIC_HEALTHBAR .. "\\scripts\\?.lua;" .. package.path
table.insert(package.assetpath, { path = MODS_ROOT .. EPIC_HEALTHBAR .. "\\", manifest = EPIC_HEALTHBAR })

-- Finally we can load the mod itself and our own mod.
ModManager:InitializeModMain(EPIC_HEALTHBAR, env, "modmain.lua")
modimport("main.lua")
