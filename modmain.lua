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

if IsInFrontEnd() then
    -- We are not in gameplay yet, so to not mess with the Mods screen we just do nothing.
    return
end

-- Tykvesh's neat little loader
local function ForceEnableMod(mod)
    local modinfo = KnownModIndex:GetModInfo(mod)
    if modinfo ~= nil and not KnownModIndex:IsModEnabledAny(mod) then
        for i, v in ipairs(ModManager.mods) do
            if v.modname == modname then
                local env = CreateEnvironment(mod)
                env.modinfo = modinfo
                table.insert(ModManager.modnames, mod)
                table.insert(ModManager.mods, i + 1, env) -- This will load the mod right after us.
                KnownModIndex:LoadModConfigurationOptions(mod, true)
                return true
            end
        end
    end
    return false
end

if ForceEnableMod(EPIC_HEALTHBAR) then
    modimport("main.lua")
end
