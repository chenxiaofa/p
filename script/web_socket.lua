--
-- Created by IntelliJ IDEA.
-- User: xiaofa
-- Date: 2016/1/11
-- Time: 11:46
-- To change this template use File | Settings | File Templates.
--
local p = require "protocol"
local d = require "dispatcher"
local common = require "common"
local server = require "resty.websocket.server"
local wb, err = server:new{
    timeout = 30000,
    max_payload_len = 65535
}

if not wb then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    return ngx.exit(444)
end


local closeFlag = false;
local sessionId = d:getSessionId();
local clientSessionId = common.server_id..common.DEC_HEX(sessionId);
local sema = d:getSemaphore(sessionId)
wb:send_text(p.register_event(clientSessionId))

local function push_thread_function()
    while closeFlag == false do
        local ok,err = sema:wait(300);
        if ok then
            local message = d:getMessage(sessionId);
            if #message > 0 then
                table.foreach(message,
                    function(k,v)
                        wb:send_text(p.message_event(v));
                    end
                )
            end

        else
            ngx.log(ngx.ERR,'timeout')
        end
        if ( closeFlag ) then
            d:destory(sessionId);
            break
        end
    end
end

local push_thread = ngx.thread.spawn(push_thread_function);

while true do
    local data, typ, err = wb:recv_frame()
    if wb.fatal then
        ngx.log(ngx.ERR, 'failed to receive frame: ', err)
        return ngx.exit(444)
    end
    if not data then
        local bytes, err = wb:send_ping()
        if not bytes then
            ngx.log(ngx.ERR, 'failed to send ping: ', err)
            closeFlag = true;
            sema:post(1);
            break
        end
    elseif typ == 'close' then
        closeFlag = true;
        ngx.log(ngx.DEBUG,'closing WS,sessionId:'..clientSessionId)
        sema:post(1);
        break
    elseif typ == 'ping' then
        local bytes, err = wb:send_pong()
        if not bytes then
            ngx.log(ngx.ERR, 'failed to send pong: ', err)
            closeFlag = true;
            sema:post(1);
            break
        end
    elseif typ == 'pong' then
        ngx.log(ngx.INFO, 'client ponged')
    elseif typ == 'text' then
        -- ignore
    elseif typ == 'continuation' then
        -- ignore
    elseif typ == 'binary' then
        -- ignore
    end

end
ngx.thread.wait(push_thread)
ngx.log(ngx.INFO, 'closing')
wb:send_close()