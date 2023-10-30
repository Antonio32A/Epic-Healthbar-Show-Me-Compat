-- Credits to authors of Show Me for some of this code.
local ShowMeHandler = {}
local HEALTH_INDEX = 34
local FETCH_RATELIMIT = 0.25
local hint_listeners = {}
local last_fetched = {}

function ShowMeHandler.GetHintValue(hint)
    local splitter = string.find(hint, ';', 1, true)
    if splitter == nil then
        return nil
    end

    return hint:sub(splitter + 1)
end

function ShowMeHandler.GetHintGUID(hint)
    local splitter = string.find(hint, ';', 1, true)
    if splitter == nil then
        return nil
    end
    return tonumber(hint:sub(1, splitter - 1))
end

function ShowMeHandler.UnpackData(str, div)
    local pos, arr = 0, {}
    -- for each divider found
    for st, sp in function()
        return string.find(str, div, pos, true)
    end do
        table.insert(arr, string.sub(str, pos, st - 1)) -- Attach chars left of current divider
        pos = sp + 1 -- Jump past current divider
    end
    table.insert(arr, string.sub(str, pos)) -- Attach chars right of last divider
    return arr
end

function ShowMeHandler.DecodeFirstSymbol(sym)
    local c = string.byte(sym);
    local idx;
    if c >= 64 and c <= 126 then
        idx = c - 64 -- '@' is en "error" symbol or use "as is" (a param string). It must be converted to 0.
    elseif c >= 32 and c <= 62 then
        idx = c + 31
    elseif c >= 17 and c <= 31 then
        idx = c + 77
    else
        idx = 0
    end
    return idx
end

function ShowMeHandler.ParseHealth(raw)
    local value = ShowMeHandler.GetHintValue(raw)
    if value == nil then
        return nil
    end

    local unpacked = ShowMeHandler.UnpackData(value, "\2")
    for _, v in ipairs(unpacked) do
        if v ~= "" then
            local param_str = v:sub(2)
            local index = ShowMeHandler.DecodeFirstSymbol(v:sub(1, 1))
            if index == HEALTH_INDEX then
                local param = ShowMeHandler.UnpackData(param_str, ",")
                return { value = tonumber(param[1]), max = tonumber(param[2]) }
            end
        end
    end

    return nil
end

function ShowMeHandler.FetchHealth(inst)
    if inst == nil
        or MOD_RPC == nil
        or MOD_RPC.ShowMeSHint == nil
        or MOD_RPC.ShowMeSHint.Hint == nil
    then
        return
    end

    if last_fetched[inst] ~= nil and GetTime() - last_fetched[inst] < FETCH_RATELIMIT then
        return
    end

    if last_fetched[inst] == nil then
        inst:ListenForEvent("onremove", function(_)
            last_fetched[inst] = nil
        end)
    end

    SendModRPCToServer(MOD_RPC.ShowMeSHint.Hint, inst.GUID, inst)
    last_fetched[inst] = GetTime()
end

function GetHoveredEntity()
    local hovered = TheInput:GetHUDEntityUnderMouse()
    if hovered ~= nil then
        hovered = hovered.widget ~= nil and hovered.widget.parent ~= nil and hovered.widget.parent.item
    else
        hovered = TheInput:GetWorldEntityUnderMouse()
    end

    return hovered
end

function ShowMeHandler.ListenToHints(fn)
    hint_listeners[fn] = true
end

function ShowMeHandler.PlayerClassifiedListener(prefab)
    local old_hint
    prefab:ListenForEvent("showme_hint_dirty2", function(player_classified)
        local raw = player_classified.net_showme_hint2:value();
        local guid = ShowMeHandler.GetHintGUID(raw)

        -- Because we are sending our own hint requests, this messes with Show Me's currently shown hint.
        -- This causes the hint to flicker when we hover over it.
        -- We can easily fix this by reverting the hint back to the old one if the newly received hint
        -- does not belong to the entity that's being hovered.
        local hovered = GetHoveredEntity()
        if hovered ~= nil and hovered.GUID ~= guid and old_hint ~= nil then
            player_classified.showme_hint2 = old_hint;
        else
            old_hint = raw
        end

        local inst = Ents[guid]
        if inst ~= nil then
            for fn, _ in pairs(hint_listeners) do
                fn(inst, raw)
            end
        end
    end)
end

return ShowMeHandler
