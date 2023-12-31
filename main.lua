local ATTACK_RANGE = 12
local IGNORE_TAGS = { "player" }
local widget

local ShowMeHandler = require("showme_handler")
local AttackHandler = require("attack_handler")
-- For some reason using require on a script makes it not able to access some environment variables,
-- in this case AddPrefabPostInit, so we have to use this workaround.
AddPrefabPostInit("player_classified", ShowMeHandler.PlayerClassifiedListener)

local function IsValidTarget(inst)
    return not inst:HasOneOfTags(IGNORE_TAGS)
        and inst:HasTag(TUNING.EPICHEALTHBAR.TAG)
        and inst.replica.combat ~= nil
        and inst.replica.combat:GetTarget() ~= nil -- in combat
end

local function CheckNearbyMobs()
    if ThePlayer == nil then
        return
    end

    local pos = TheCamera.targetpos
    for i, inst in ipairs(TheSim:FindEntities(pos.x, 0, pos.z, ATTACK_RANGE, { TUNING.EPICHEALTHBAR.TAG }, IGNORE_TAGS)) do
        if IsValidTarget(inst) then
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

local function OnWidgetUpdate(inst)
    if inst.widget.target ~= nil then
        ShowMeHandler.FetchHealth(inst.widget.target)
    else
        CheckNearbyMobs()
    end
end

AddSimPostInit(function()
    TUNING.EPICHEALTHBAR.GLOBAL_NUMBERS = false

    AddClassPostConstruct("widgets/epichealthbar", function(self, owner)
        widget = self
        self.inst:DoPeriodicTask(0.25, OnWidgetUpdate)
        self.inst:ListenForEvent("onremove", function()
            widget = nil
        end)
    end)
end)

ShowMeHandler.ListenToHints(function(inst, raw)
    if widget == nil or widget.targets == nil or not IsValidTarget(inst) then
        return
    end

    local health = ShowMeHandler.ParseHealth(raw)
    if health == nil then
        return
    end

    local is_new = widget.targets[inst] == nil

    if inst.epichealth == nil then
        inst.epichealth = { invincible = false }
    elseif inst.epichealth.currenthealth > health.value then
        inst.epichealth.lastwasdamagedtime = GetTime()
    end

    inst.epichealth.currenthealth = health.value
    inst.epichealth.maxhealth = health.max

    if is_new then
        widget.targets[inst] = true
        ThePlayer:PushEvent("newepictarget", inst)
        inst:ListenForEvent("onremove", RemoveTarget)
    end
end)

AttackHandler.ListenToAttacked(function(inst)
    if widget == nil or not IsValidTarget(inst) then
        return
    end

    ShowMeHandler.FetchHealth(inst)
end)
