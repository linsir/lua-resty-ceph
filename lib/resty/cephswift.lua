-- A simple Lua wrapper for ceph with swift.
-- @Date    : 2016-05-31 16:35:41
-- @Author  : Linsir (root@linsir.org)
-- @Link    : http://linsir.org
-- @Version :


local http = require"resty.http"
local cjson = require "cjson"

config = {
    auth_uri = 'http://192.168.2.99/auth',
    swift_user = 'demouserid:swift',
    swift_secret_key  = 'QG1GXO1ZeKr62sUeCLkKge6SKRhpNNoBETqyhetG',

}

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end


local _M = new_tab(0, 155)
_M._VERSION = '0.01'


local mt = { __index = _M }

function _M.new(self, id, key)
    local id, key = id, key

    if not id then
        return nil, "must provide id"
    end
    if not key then
        return nil, "must provide key"
    end
    auth_token, base_url = self.generate_auth_headers(id, key)
    return setmetatable({ id = id, key = key ,auth_token = auth_token , base_url = base_url }, mt)
end

function _M.generate_auth_headers(id, key)

    -- Make authentication request to Ceph
    headers_t = {}
    headers_t["X-Auth-User"] = id
    headers_t["X-Auth-Key"] = key
    local httpc = http.new()
    local res, err = httpc:request_uri(config.auth_uri, {
        headers = headers_t,
        method  = "GET"
    })

    -- Return 403 if not authorized
    if res.status ~= 204 then
      ngx.say("failed to generate_auth_headers: ", err)
      return
    end
    -- ngx.say(cjson.encode(res.headers))
    -- we will get x-storage-token & x-auth-token
    -- OK, we get auth token now
    local auth_token = ''
    auth_token = res.headers["x-auth-token"]
    local base_url = res.headers["x-storage-url"]
    return auth_token, base_url, err
end


function _M.get_all_objs(self, bucket)

    local url = self.base_url .. "/" .. bucket .. "?format=json"
    -- local url = "http://httpbin.org/get"
    content_headers= {}
    content_headers["X-Auth-Token"] = self.auth_token
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        headers = content_headers,
        method  = "GET",
    })
    if not res then
      ngx.say("failed to get_all_objs: ", err)
      return
    end

    ngx.header["Content-Type"] = "application/json; charset=UTF-8"
    ngx.say(res.body)
    return res.body

end
function _M.create_obj(self, bucket, file, content)

    local url = self.base_url .. "/" .. bucket .. "/" .. file
    -- ngx.say(url)
    -- local url ="http://httpbin.org/put"
    content_headers= {}
    content_headers["X-Auth-Token"] = self.auth_token
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        headers = content_headers,
        body = content,
        method  = "PUT"
    })
    if not res then
      ngx.say("failed to create_obj: ", err)
      return
    end
    -- ngx.say(res.body)
    return url
end

function _M.get_obj(self, bucket, file)

    local url = self.base_url .. "/" .. bucket .. "/" .. file
    content_headers= {}
    content_headers["X-Auth-Token"] = self.auth_token

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        headers = content_headers,
        method  = "GET"
    })
    if not res then
      ngx.say("failed to get_obj: ", err)
      return
    end
    -- ngx.say(res.body)
    return res.body
end

function _M.del_obj(self, bucket, file)

    local url = self.base_url .. "/" .. bucket .. "/" .. file
    content_headers= {}
    content_headers["X-Auth-Token"] = self.auth_token
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        headers = content_headers,
        method  = "DELETE"
    })
    if not res then
      ngx.say("failed to del_obj: ", err)
      return
    end

    return "Delete Sucess."
end

function _M.create_bucket(self, bucket)

    local url = self.base_url .. "/" .. bucket
    content_headers= {}
    content_headers["X-Auth-Token"] = self.auth_token
    content_headers["X-Container-Read"] = "*"
    content_headers["X-Container-Write"] = "*"
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        headers = content_headers,
        method  = "PUT"
    })
    if not res then
      ngx.say("failed to del_bucket: ", err)
    end
    if res.status == 409 then
        ngx.say(res.body)
    end
    return res.body

end

function _M.del_bucket(self, bucket)

    local url = self.base_url .. "/" .. bucket
    content_headers= {}
    content_headers["X-Auth-Token"] = self.auth_token
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        headers = content_headers,
        method  = "DELETE"
    })
    if not res then
      ngx.say("failed to del_bucket: ", err)
      return
    end
    if res.status == 404 then
        ngx.status = 404
        ngx.header["Content-Type"] = "text/plain"
        ngx.say("Opps, bucket not found.")
        ngx.exit(404)
    end
    return res.body
end

return _M
