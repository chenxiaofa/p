--
-- Created by IntelliJ IDEA.
-- User: xiaofa
-- Date: 2016/3/30
-- Time: 14:18
-- To change this template use File | Settings | File Templates.
--

local c = require "common";
local mysql = require "mysql_pool"
local args = ngx.req.get_uri_args();


if not args.app_id or not args.signature or not args.nonce or not args.timestamp then
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
end


ngx.log(ngx.INFO,'now:'..ngx.now())
ngx.log(ngx.INFO,'timestamp:'..args.timestamp)
if math.abs(ngx.now() - args.timestamp) > 120 then
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

local ok,app_data = mysql:get_app_by_id(args.app_id)

if not ok then
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- 签名验证信息
local auth_data = {args.app_id,args.nonce,args.timestamp,app_data.secret_key}
table.sort(auth_data)

-- 计算签名
local signature = ngx.md5(table.concat(auth_data,''))
--ngx.log(ngx.INFO,'auth data'..c.dump(auth_data))
ngx.log(ngx.INFO,'signature calced:'..signature)
ngx.log(ngx.INFO,'signature provided:'..args.signature)
if signature ~= args.signature then
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

