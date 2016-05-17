--
-- Created by IntelliJ IDEA.
-- User: xiaofa
-- Date: 2016/1/11
-- Time: 18:02
-- To change this template use File | Settings | File Templates.
--
local args = ngx.req.get_uri_args()
for key, val in pairs(args) do
    if type(val) == "table" then
        ngx.say(key, ": ", table.concat(val, ", "))
    else
        ngx.say(key, ": ", val)
    end
end

ngx.say(args["c"])