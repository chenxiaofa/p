--
-- Created by IntelliJ IDEA.
-- User: xiaofa
-- Date: 2016/1/17
-- Time: 15:33
-- To change this template use File | Settings | File Templates.
--



local d = require "dispatcher"

local args = ngx.req.get_uri_args();

if args['sid'] ~= nil and args['message'] ~= nil then
    local sid = tonumber(args['sid']);
    local message = args['message'];
    d:dispatch(sid,message);
end
ngx.say(ngx.worker.id())
