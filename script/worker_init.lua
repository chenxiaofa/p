--
-- Created by IntelliJ IDEA.
-- User: xiaofa
-- Date: 2016/1/26
-- Time: 15:34
-- To change this template use File | Settings | File Templates.
--
local d = require "dispatcher"
local c = require "common"


local function dispatchLooper()
    -- ngx.log(ngx.DEBUG,"dispatchLooper")
    d:dispatchMessage();
    ngx.timer.at(1,dispatchLooper)
end
dispatchLooper();