--
-- Created by IntelliJ IDEA.
-- User: xiaofa
-- Date: 2016/4/7
-- Time: 17:28
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
        local r,s,m = p.decode_emit_events(data);
        if ( r ) then
            d:dispatch(s,m);
        end
    end
end
ngx.log(ngx.INFO, 'closing')
wb:send_close()