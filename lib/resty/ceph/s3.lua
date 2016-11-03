-- A simple Lua wrapper for ceph with s3.
-- more: http://docs.ceph.org.cn/radosgw/s3/
-- @Date    : 2016-05-31 16:35:41
-- @Author  : Linsir (root@linsir.org)
-- @Link    : http://linsir.org
-- @Version : 0.0.3

local cjson = require "cjson"
local os = require "os"
local http = require"resty.http"
local utils = require "resty.ceph.utils"

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 155)
_M._VERSION = '0.0.3'

local mt = { __index = _M }

function _M.new(self, id, key, host)
    local id, key, host = id, key, host

    if not id then
        return nil, "must provide id"
    end
    if not key then
        return nil, "must provide key"
    end
    if not host then
        return nil, "can not find ceph host"
    end
    local httpc = http.new()
    httpc:set_timeout(500)
    local res, err = httpc:request_uri(host, {
        method  = "GET"
    })
    if res.status == 504 then
        ngx.status = 504
        ngx.header["Content-Type"] = "text/plain"
        ngx.say("Opps, can not connect to ceph gateway.")
        ngx.exit(504)
    end
    return setmetatable({ id = id, key = key, base_url = host }, mt)
end

function _M.generate_auth_headers(self, method, destination, req_headers)
    local headers = {}
    headers['content-type'] = ''
    if not self.id or not self.key then
        return nil, "not initialized"
    end

    if req_headers then
        for k, v in pairs(req_headers) do
            if utils.lower(k) == 'content-type' then
                headers['content-type'] = utils.lower(v) or ''
            end
            if utils.lower(k) == 'content-md5' then
                headers['content-md5'] = utils.lower(v) or ''
            end
            if utils.startswith(utils.lower(k), 'x-amz') then
                headers[utils.lower(k)] = utils.lower(v)
            end
        end
    end

    local h_str = ''
    for k, v in pairs(headers) do
        h_str = v..string.char(10)
    end

    local timestamp = os.date("!%a, %d %b %Y %H:%M:%S +0000")

    local StringToSign = method..string.char(10)..string.char(10)..h_str..timestamp..string.char(10)..destination
    local signed = ngx.encode_base64(ngx.hmac_sha1(self.key, StringToSign))
    signed = 'AWS' .. ' ' .. self.id .. ':' .. signed

    headers['Authorization'] = signed
    headers['Date'] = timestamp
    -- ngx.log(ngx.INFO, cjson.encode(headers))
    return headers
end

-- BUCKET OPERATIONS 

function _M.get_all_buckets(self)
    local destination = "/"
    local url = self.base_url .. destination
    local req_headers = ngx.req.get_headers()
    local headers_t = self:generate_auth_headers("GET", destination, req_headers)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "GET",
                -- body = content,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to get_all_buckets: ", destination, ": ", err)
      return
    end

    -- ngx.header["Content-Type"] = "application/xml; charset=UTF-8"
    -- ngx.log(ngx.INFO, "get_all_buckets: ", res.body)
    return res.body
end

function _M.create_bucket(self, bucket, acl)
    local destination = "/" .. bucket
    local url = self.base_url .. destination
    local req_headers = {}
    if acl == nil then
        acl = 'public-read'
    end
    req_headers['x-amz-acl'] = acl
    local headers_t = self:generate_auth_headers("PUT", destination, req_headers)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "PUT",
                -- body = content,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to create_bucket: ", destination, ": ", err)
      return
    end

    if res.status == 409 then
        ngx.status = 409
        ngx.header["Content-Type"] = "text/plain"
        return "Bucket Already Exists."
    end
    if res.status == 200 then
        ngx.status = 200
        ngx.header["Content-Type"] = "text/plain"
        return "Create Bucket Sucessfully."
    end
    return 


end

function _M.del_bucket(self, bucket)
    local destination = "/" .. bucket
    local url = self.base_url .. destination
    local headers_t = self:generate_auth_headers("DELETE", destination)
    
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "DELETE",
                -- body = content,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to del_bucket: ", destination, ": ", err)
      return
    end

    if res.status == 204 then
        ngx.status = 204
    end

    if res.status == 404 then
        ngx.status = 404
        ngx.header["Content-Type"] = "text/plain"
        ngx.say("Opps, Bucket not found.")
        ngx.exit(404)
    end
    
end

function _M.get_all_objs(self, bucket, args)
    args = args or ''
    local destination = "/" .. bucket
    local url = self.base_url .. destination .. "?" .. args
    local headers_t = self:generate_auth_headers("GET", destination)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "GET",
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to get_all_objs: ", destination, ": ", err)
      return
    end

    -- ngx.header["Content-Type"] = "application/xml; charset=UTF-8"
    -- ngx.log(ngx.INFO, "get_all_objs: ", res.body)
    return res.body

end

function _M.get_buckets_location(self, bucket)
    local destination = "/" .. bucket .. "?location"
    local url = self.base_url .. destination
    local headers_t = self:generate_auth_headers("GET", destination)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "GET",
                -- body = content,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to get_buckets_location: ", destination, ": ", err)
      return
    end
    return res.body
end

function _M.get_buckets_acl(self, bucket)
    local destination = "/" .. bucket .. "?acl"
    local url = self.base_url .. destination
    local headers_t = self:generate_auth_headers("GET", destination)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "GET",
                -- body = content,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to get_buckets_acl: ", destination, ": ", err)
      return
    end
    return res.body
end

function _M.set_buckets_acl(self, bucket)
    local destination = "/" .. bucket .. "?acl"
    local url = self.base_url .. destination
    local headers_t = self:generate_auth_headers("PUT", destination)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "PUT",
                -- body = content,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to set_buckets_acl: ", destination, ": ", err)
      return
    end
    return res.body
end

-- TODO: upload

-- OBJECT OPERATIONS

function _M.create_obj(self, bucket, object, content)
    local destination = "/" .. bucket .. "/" .. object
    local url = self.base_url .. destination
    local req_headers = ngx.req.get_headers()
    if acl == nil then
        acl = 'public-read'
    end
    req_headers['x-amz-acl'] = acl
    local headers_t = self:generate_auth_headers("PUT", destination, req_headers)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "PUT",
                body = content,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to create_obj: ", destination, ": ", err)
      return
    end
    ngx.log(ngx.INFO, res.status)
    if res.status == 200 then
        ngx.status = 200
        ngx.header["Content-Type"] = "text/plain"
        return "Create Object Sucessfully."
    end
    return 'hhhh'
end

function _M.del_obj(self, bucket, object)
    local destination = "/" .. bucket .. "/" .. object
    local url = self.base_url .. destination
    local headers_t = self:generate_auth_headers("DELETE", destination)
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "DELETE",
                -- body = content,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to del_obj: ", destination, ": ", err)
      return
    end

    if res.status ==204 then
        ngx.status = 204
    end
    return "Delete Object Sucessfully."
end

function _M.get_obj(self, bucket, object)
    local destination = "/" .. bucket .. "/" .. object
    local url = self.base_url .. destination
    local headers_t = self:generate_auth_headers("GET", destination)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "GET",
                -- body = content,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to get_obj: ", destination, ": ", err)
      return
    end
    if res.status == 404 then
        ngx.status = 404
        ngx.header["Content-Type"] = "text/plain"
        ngx.say("Opps, object is not found.")
        ngx.exit(404)
    end
    return res.body
end

function _M.check_for_existance(self, bucket, object)
    local destination = "/" .. bucket .. "/" .. object
    local url = self.base_url .. destination
    local headers_t = self:generate_auth_headers("HEAD", destination)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "HEAD",
                -- body = content,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to check_for_existance: ", destination, ": ", err)
      return false
    end
    if res.status == 200 then
        return true
    else
        ngx.log(ngx.ERR, "failed to connet to ceph gateway : ", res.body)
        return false
    end
end


function _M.get_obj_acl(self, bucket, object)
    local destination = "/" .. bucket .. "/" .. object .. "?acl"
    local url = self.base_url .. destination
    local headers_t = self:generate_auth_headers("GET", destination)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "GET",
                -- body = content,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to get_obj_acl: ", destination, ": ", err)
      return
    end
    return res.body
end

function _M.set_obj_acl(self, bucket, object, args)
    local destination = "/" .. bucket .. "/" .. object .. "?acl"
    local url = self.base_url .. destination
    local headers_t = self:generate_auth_headers("PUT", destination)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
                method  = "PUT",
                body = args,
                headers = headers_t
            })
    if not res then
      ngx.log(ngx.ERR, "failed to get_obj_acl: ", destination, ": ", err)
      return
    end
    return res.body
end

-- TODO: UPLOAD OPS

return _M
