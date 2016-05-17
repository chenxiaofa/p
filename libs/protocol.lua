--
-- Created by IntelliJ IDEA.
-- User: xiaofa
-- Date: 2016/3/29
-- Time: 17:38
-- To change this template use File | Settings | File Templates.
--
local JSON = require("cjson")
local c = require("common")

local _M = {};

local TYPE_REGISTER = 0;
local TYPE_MESSAGE = 1;

function _M.register_event(sessionId)
    return JSON.encode(
        {
            type=TYPE_REGISTER,
            data=sessionId
        }
    );
end

function _M.message_event(message)
    return JSON.encode(
        {
            type=TYPE_MESSAGE,
            data=message
        }
    );
end

function _M.decode_emit_events(recv)
    local ok,json = pcall(JSON.decode,recv);
    if ( ok ) then
        return true,tonumber(string.sub(json['session_id'],33,-1)),json['data'];
    end
    return false;
end

return _M;