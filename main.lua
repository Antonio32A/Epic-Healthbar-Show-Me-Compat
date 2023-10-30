local ATTACK_RANGE = 24
local ATTACK_TAGS = { "attack" }
local widget

local ShowMeHandler = require("showme_handler")
local AttackHandler = require("attack_handler")
-- For some reason using require on a script makes it not able to access some environment variables,
-- in this case AddPrefabPostInit, so we have to use this workaround.
AddPrefabPostInit("player_classified", ShowMeHandler.PlayerClassifiedListener)

AddClassPostConstruct("widgets/epichealthbar", function(self, owner)
    widget = self
end)

local function IsTargetingPlayer(inst)
    if ThePlayer == nil then
        return false
    end
    return inst.replica.combat ~= nil and inst.replica.combat:GetTarget() == ThePlayer
end

local function CheckNearbyMobs()
    if ThePlayer == nil then
        return
    end

    local pos = ThePlayer:GetPosition()
    for i, inst in ipairs(TheSim:FindEntities(pos.x, 0, pos.z, ATTACK_RANGE, ATTACK_TAGS)) do
        if IsTargetingPlayer(inst) then
            ShowMeHandler.FetchHealth(inst)
        end
    end
end

local function RemoveTarget(inst)
    if widget == nil then
        return
    end

    widget.targets[inst] = nil
    if ThePlayer ~= nil then
        ThePlayer:PushEvent("lostepictarget", inst)
    end
end

ShowMeHandler.ListenToHints(function(inst, raw)
    if widget == nil or widget.targets == nil or not IsTargetingPlayer(inst) then
        return
    end

    local health = ShowMeHandler.ParseHealth(raw)
    if health == nil then
        return
    end

    local is_new = widget.targets[inst] == nil
    inst.epichealth = {
        currenthealth = health.value,
        maxhealth = health.max,
        invincible = false,
    }

    if is_new then
        widget.targets[inst] = true
        ThePlayer:PushEvent("newepictarget", inst)
        inst:ListenForEvent("onremove", RemoveTarget)
    end
end)

AttackHandler.ListenToAttacked(function(inst)
    if widget == nil then
        return
    end

    ShowMeHandler.FetchHealth(inst)
end)

staticScheduler:ExecutePeriodic(0.25, function()
    if widget == nil then
        return
    end

    if widget.target ~= nil then
        ShowMeHandler.FetchHealth(widget.target)
    else
        CheckNearbyMobs()
    end
end)
