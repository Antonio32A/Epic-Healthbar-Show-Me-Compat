local AttackHandler = {}
local attacked_listeners = {}
local OldSendRPCToServer = SendRPCToServer

function AttackHandler.ListenToAttacked(fn)
    attacked_listeners[fn] = true
end

-- This will probably not work in single shard worlds, but the user should be using the server mod anyway.
SendRPCToServer = function(rpc, param1, param2, param3, param4, ...)
    local inst
    if rpc == RPC.AttackButton and param1 ~= nil then -- Attack bind
        inst = param1
    elseif rpc == RPC.LeftClick and param1 == ACTIONS.ATTACK.code and param4 ~= nil then -- Left click
        inst = param4
    end

    if inst ~= nil then
        for fn, _ in pairs(attacked_listeners) do
            fn(inst)
        end
    end

    OldSendRPCToServer(rpc, param1, param2, param3, param4, ...)
end

return AttackHandler
