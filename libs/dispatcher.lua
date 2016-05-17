--
-- Created by IntelliJ IDEA.
-- User: xiaofa
-- Date: 2016/1/26
-- Time: 10:31
-- To change this template use File | Settings | File Templates.
--


local semaphore = require "ngx.semaphore"
local common = require "ngx.semaphore"
local _M = { _VERSION = '0.01' }

local semaMap = {}
local messageList = {};
local workerId = ngx.worker.id();
local incrId = 0;
local mask = 2^42;
local smdList = {
    ngx.shared.smd_1,
    ngx.shared.smd_2,
    ngx.shared.smd_3,
    ngx.shared.smd_4
}

local smd = smdList[workerId+1];

smd:set('id',0);


local function getWorkerId(sessionId)
    return math.floor(tonumber(sessionId)/mask);
end
_M.getWorkerId = getWorkerId;

function _M.dispatchToSession(self,sessionId,message)
    ngx.log(ngx.DEBUG,'Worker ID:'..workerId)
    ngx.log(ngx.DEBUG,'Session ID:'..sessionId);
    if ( messageList[sessionId] ~= nil ) then
        table.insert(messageList[sessionId],message);
        self:wakeUp(sessionId)
    else
        ngx.log(ngx.WARN,'invalid session ID:'..sessionId)
    end
end


function _M.getSessionId(self)
    local sessionId = workerId;
    sessionId = sessionId * mask + incrId;
    incrId = incrId + 1;
    messageList[sessionId] = {};
    ngx.log(ngx.DEBUG,'new session:'..sessionId);
    return sessionId;
end

function _M.getSemaphore(self,sessionId)
    if ( semaMap[sessionId] == nil ) then
        semaMap[sessionId] = semaphore.new(0);
    end
    return semaMap[sessionId];
end


function _M.wakeUp(self,sessionId)
    if ( semaMap[sessionId] ~= nil ) then
        semaMap[sessionId]:post(1);
    end
end

function _M.dispatch(self,sessionId,message)
    local wId = getWorkerId(sessionId);
    ngx.log(ngx.DEBUG,'worker ID from Session:'..wId..'-'..sessionId)
    if wId == workerId then ---当前worker

            self:dispatchToSession(sessionId,message);

    else
        local _smd = smdList[wId+1];
        local id = _smd:incr('id',1);
        _smd:set(sessionId..':'..id,message);
    end

end


---
-- 销毁会话
-- @param self
-- @param sessionId
--
function _M.destory(self,sessionId)
    ngx.log(ngx.DEBUG,'destory session,session ID:'..sessionId)
    messageList[sessionId] = nil;
    semaMap[sessionId] = nil;
end

---
-- 根据会话ID获取消息
-- @param self
-- @param sessionId
--
function _M.getMessage(self,sessionId)
    if ( messageList[sessionId] ~= nil ) then
        local messages = {};
        table.foreach(messageList[sessionId],
            function(i, v)
                table.insert(messages,v);
                messageList[sessionId][i] = nil;
            end
        );
        return messages;
    end
end



local function getSessionIdFromKey(key)
    local i,j = string.find(key,':');
    if not i then
        ngx.log(ngx.ERR,'can not find session id from '..key);
        return 0;
    end
    return tonumber(string.sub(key,1,i-1));
end

---
--- 分发消息
-- @param self
--
function _M.dispatchMessage(self)
    local keys = smd:get_keys(10);
--    ngx.log(ngx.DEBUG,'get message count:'..#keys - 1)
    if #keys > 0 then
        table.foreach(keys,
            function (i,key)
                if key == 'id' then
                    return;
                end
                local sessionId = getSessionIdFromKey(key);
                local message = smd:get(key);
                ngx.log(ngx.DEBUG,'Found message from :'..sessionId)
                self:dispatchToSession(sessionId,message);
                smd:delete(key);
            end
        )
    end
end


return _M
