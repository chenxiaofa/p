--
-- Created by IntelliJ IDEA.
-- User: xiaofa
-- Date: 2016/3/29
-- Time: 15:48
-- To change this template use File | Settings | File Templates.
--
local _M = {
    local_ip="10.116.163.54",
    port="80",
    db_host = "qdm217211123.my3w.com",
    db_port = "3306",
    db_user = "qdm217211123",
    db_password = "gonzoopera",
    db_name = "qdm217211123_db",
    db_charset = "utf8"
};

_M.server_id = ngx.md5(_M.local_ip..':'.._M.port);

---
-- dump
-- @param obj
-- @param n
--
local function dump(obj,n)
    local str = '';
    n = n or 0;
    for key,value in pairs(obj) do
        local t = type(value)
        str = str.."\n"..string.rep(' ', n*4)..key..' - '..t

        if (t == 'table') then
            str = str.."\n"..dump(value,n+1);
        end
        if (t == 'string' or t == 'number') then
            str = str.."\n"..string.rep(' ', (n+1)*4)..value
        end
    end
    return str;
end

---
-- 转换为16进制
-- @param IN
--
local function DEC_HEX(IN)
    return IN;
--    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
--    while IN>0 do
--        I=I+1
--        IN,D=math.floor(IN/B),math.mod(IN,B)+1
--        OUT=string.sub(K,D,D)..OUT
--    end
--    return OUT
end

_M.dump = dump;
_M.DEC_HEX = DEC_HEX;
return _M;