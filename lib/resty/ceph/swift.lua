-- A simple Lua wrapper for ceph with swift.
-- more: http://docs.ceph.org.cn/radosgw/swift/
-- @Date    : 2016-05-31 16:35:41
-- @Author  : Linsir (root@linsir.org)
-- @Link    : http://linsir.org
-- @Version : 0.0.3


local http = require"resty.http"
local cjson = require "cjson"

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end


local _M = new_tab(0, 155)
_M._VERSION = '0.0.3'


local mt = { __index = _M }

function _M.new(self, user, key, auth_uri)
    local user, key = user, key

    if not user then
        return nil, "must provide auth user"
    end
    if not key then
        return nil, "must provide key"
    end
    auth_token, base_url = self.generate_auth_headers(user, key, auth_uri)
    return setmetatable({ user = user, key = key ,auth_token = auth_token , base_url = base_url }, mt)
end

function _M.generate_auth_headers(user, key, auth_uri)

    -- Make authentication request to Ceph
    headers_t = {}
    headers_t["X-Auth-User"] = user
    headers_t["X-Auth-Key"] = key
    local httpc = http.new()
    local res, err = httpc:request_uri(auth_uri, {
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

-- BUCKET OPERATIONS

function _M.get_all_buckets(self, args)
    -- args : litmit, format, marker
    if not args then
        args = {}
    end
    args['format'] = 'json'

    local url = self.base_url .. "/"

    content_headers= {}
    content_headers["X-Auth-Token"] = self.auth_token
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        headers = content_headers,
        body = args,
        method  = "GET"
    })
    if not res then
      ngx.say("failed to get_all_buckets: ", err)
      return
    end

    return res.body

end

function _M.create_bucket(self, bucket, r_ids, w_ids)
    r_ids = r_ids or "*"
    w_ids = w_ids or "*"
    local url = self.base_url .. "/" .. bucket
    content_headers= {}
    content_headers["X-Auth-Token"] = self.auth_token
    content_headers["X-Container-Read"] = r_ids
    content_headers["X-Container-Write"] = w_ids
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

function _M.get_all_objs(self, bucket, args)
    -- args : litmit, format, marker, prefix, delimiter, path
    if not args then
        args = {}
    end
    args['format'] = 'json'
    local url = self.base_url .. "/" .. bucket

    content_headers= {}
    content_headers["X-Auth-Token"] = self.auth_token
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        headers = content_headers,
        method  = "GET",
        body = args
    })
    if not res then
      ngx.say("failed to get_all_objs: ", err)
      return
    end

    -- ngx.header["Content-Type"] = "application/json; charset=UTF-8"
    -- ngx.say(res.body)
    return res.body

end

function _M.set_bucket_acl(self, bucket, r_ids, w_ids)
    r_ids = r_ids or "*"
    w_ids = w_ids or "*"
    local url = self.base_url .. "/" .. bucket
    content_headers= {}
    content_headers["X-Auth-Token"] = self.auth_token
    content_headers["X-Container-Read"] = r_ids
    content_headers["X-Container-Write"] = w_ids

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        headers = content_headers,
        method  = "POST"
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

-- OBJECT OPERATIONS

function _M.create_obj(self, bucket, file, content, etag, content_type, trans_encoding)
    -- args: ETag, Content-Type, Transfer-Encoding
    local url = self.base_url .. "/" .. bucket .. "/" .. file

    content_headers= {}
    if etag then
        content_headers["ETag"] = etag
    end
    if content_type then
        content_headers["Content-Type"] = content_type
    end
    if trans_encoding then
        content_headers["Transfer-Encoding"] = trans_encoding
    end
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

    return res.body
end


return _M
