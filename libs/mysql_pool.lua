--
-- Created by IntelliJ IDEA.
-- User: xiaofa
-- Date: 2016/3/30
-- Time: 15:51
-- To change this template use File | Settings | File Templates.
--

module("mysql_pool", package.seeall)
local comm = require "common"
local mysql = require("resty.mysql")
local mysql_pool = {}
--[[
    先从连接池取连接,如果没有再建立连接.
    返回:
    false,出错信息.
    true,数据库连接
--]]
function mysql_pool:get_connect()
     if ngx.ctx[mysql_pool] then
         return true, ngx.ctx[mysql_pool]
     end

    local client, errmsg = mysql:new()

    if not client then
             return false, "mysql.socket_failed: " .. (errmsg or "nil")
    end

    client:set_timeout(10000)  --10秒

    local options = {
        host = comm.db_host,
        port = comm.db_port,
        user = comm.db_user,
        password = comm.db_password,
        database = comm.db_name
    }
    local result, errmsg, errno, sqlstate = client:connect(options)

    if not result then
        return false, "mysql.cant_connect: " .. (errmsg or "nil") .. ", errno:" .. (errno or "nil") .. ", sql_state:" .. (sqlstate or "nil")
    end

    local query = "SET NAMES " .. comm.db_charset
    local result, errmsg, errno, sqlstate = client:query(query)
    if not result then
        return false, "mysql.query_failed: " .. (errmsg or "nil") .. ", errno:" .. (errno or "nil") ..", sql_state:" .. (sqlstate or "nil")
    end

    ngx.ctx[mysql_pool] = client
    return true, ngx.ctx[mysql_pool]
end


--[[
    把连接返回到连接池
    用set_keepalive代替close() 将开启连接池特性
--]]
function mysql_pool:close()
    if ngx.ctx[mysql_pool] then
        ngx.ctx[mysql_pool]:set_keepalive(60000, 1000)
        ngx.ctx[mysql_pool] = nil
    end
end


--[[
    查询
    有结果数据集时返回结果数据集
    无数据数据集时返回查询影响
    返回:
    false,出错信息,sqlstate结构.
    true,结果集,sqlstate结构.
--]]
function mysql_pool:query(sql, flag)
    local ret, client = self:get_connect(flag)
    if not ret then
        return false, client, nil
    end
    local result, errmsg, errno, sqlstate = client:query(sql)
    self:close()
    if not result then
        errmsg = concat_db_errmsg("mysql.query_failed:", errno, errmsg, sqlstate)
        return false, errmsg, sqlstate
    end
    return true, result, sqlstate
end


--[[
-- @param app_id
-- 查询APP信息
 ]]
function mysql_pool:get_app_by_id(app_id)
    local ok,result = self:query(string.format('select * from p_app where id = \'%s\'',app_id));
    if not ok or #result == 0 then
        return false,nil
    end
    return true,result[1];
end

return mysql_pool