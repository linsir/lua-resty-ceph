# lua-resty-http

A simple Lua wrapper for ceph with s3 and swift.

More: 

1. <http://docs.ceph.org.cn/radosgw/s3/>
2. <http://docs.ceph.org.cn/radosgw/swift/>


# API

* [new](#new)
* [get_all_buckets](#get_all_buckets)
* [get_all_objs](#get_all_objs)
* [get_obj](#get_obj)
* [check_for_existance](#check_for_existance)
* [del_obj](#del_obj)
* [create_bucket](#create_bucket)
* [del_bucket](#del_bucket)

## Synopsis

``` lua
lua_package_path "/path/to/lua-resty-ceph/lib/?.lua;;";

server {
  location  /swift {

      # index index.html;
      default_type text/plain;
      content_by_lua_block {
          require("app").swiftrun()
      }
  }

  location  /s3 {

      # index index.html;
      default_type text/plain;
      content_by_lua_block {
          require("app").s3run()
      }
  }

  location /proxy/ {
      internal;
      set_unescape_uri $date $arg_date;
      set_unescape_uri $auth $arg_auth;
      set_unescape_uri $file $arg_file;
      set_unescape_uri $mime $arg_mime;

      proxy_pass_request_headers off;
      more_clear_headers 'Host';
      more_clear_headers 'Connection';
      more_clear_headers 'Content-Length';
      more_clear_headers 'User-Agent';
      more_clear_headers 'Accept';

      proxy_set_header Date $date;
      proxy_set_header Authorization $auth;
      proxy_set_header content-type $mime;
      # proxy_set_header x-amz-acl 'public-read';
      proxy_set_header Content-MD5 '';

      proxy_pass http://192.168.2.99$file;

      # proxy_pass http://httpbin.org/get;
  }
}
```
and `app.lua`:
```lua
local _M = {}



function _M.go()
    local main = require "main"
    main.run()
end

function _M.swiftrun()

    bucket = ngx.var.arg_b
    file = ngx.var.arg_f
    content = ngx.var.arg_c
    del = ngx.var.arg_d

    app = cephswift:new(config.swift_user, config.swift_secret_key)
    -- app:create_bucket(bucket)
    -- app:get_all_objs(bucket)
    if content then
        local url = app:create_obj(bucket, file, content)
        ngx.say(url)
    end

    if file then
        local data = app:get_obj(bucket, file)
        ngx.say(data)
        -- app:del_obj(bucket, file)
    end

    if del == "y" then
        local res = app:del_bucket(bucket)

    end
end

function _M.s3run()

    bucket = ngx.var.arg_b
    file = ngx.var.arg_f
    content = ngx.var.arg_c
    del = ngx.var.arg_d
    create = ngx.var.arg_cr

    local cephs3 = require("cephs3")
    local app = cephs3:new(config.access_key, config.secret_key)

    if (bucket and create ) then
        local data = app:create_bucket(bucket)
        ngx.say(data)
    elseif ((not file) and (not del) and bucket) then
        app:get_all_objs(bucket)

    elseif (file and bucket and content) then
        local url = app:create_obj(bucket, file, content)
        ngx.say(url)
    elseif (bucket and file and del) then
        local data = app:del_obj(bucket, file)
        ngx.say(data)
    elseif ((not file) and bucket and del) then
        local data = app:del_bucket(bucket)
        ngx.say(data)
    elseif (not del and bucket and file) then
        -- local exsite = app:check_for_existance(bucket, file)
        -- ngx.say(exsite)
        local data = app:get_obj(bucket, file)
        ngx.say(data)
    else
        app:get_all_buckets()
    end

end

return _M

```

# Usage

## new

    local app = cephs3:new(config.access_key, config.secret_key)

## create_bucket

    app:create_bucket(bucket)

## del_bucket

    app:del_bucket(bucket)

## get_all_buckets

    app:get_all_buckets()

## get_all_objs

    app:get_all_objs(bucket)

## create_obj

    app:create_obj(bucket, file, content)

## check_for_existance

    app:check_for_existance(bucket, file)

## get_obj

    app:get_obj(bucket, file)

## del_obj

    app:del_obj(bucket, file)



# Author

Linsir: <https://github.com/vi5i0n>


# Licence

This module is licensed under the 2-clause BSD license.

Copyright (c) 2013-2016, James Hurst <james@pintsized.co.uk>

All rights reserved.
