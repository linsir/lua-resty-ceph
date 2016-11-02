-- tests
config = {
    timeout = 300, -- * 24 * 3600 -- redis timeout (sec)
    ceph_mode = true,
    host = 'http://192.168.2.99', -- s3 api host
    access_key = 'HXKJ2FLL7BAWENBMP0HF',
    secret_key = 'DEeFyCPlBKK2vS7DPJDeeozNiF5WAjL7pVMNpDlO',
    auth_uri = 'http://192.168.2.99/auth',
    swift_user = 'demouserid:swift',
    swift_secret_key  = 'QG1GXO1ZeKr62sUeCLkKge6SKRhpNNoBETqyhetG',

}
local _M = {}

function _M.swiftrun()

    bucket = ngx.var.arg_b
    file = ngx.var.arg_f
    content = ngx.var.arg_c
    del = ngx.var.arg_d
    local cephswift = require("resty.ceph.swift")
    app = cephswift:new(config.swift_user, config.swift_secret_key, config.auth_uri)
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

    local cephs3 = require("resty.ceph.s3")
    local app = cephs3:new(config.access_key, config.secret_key, config.host)
    ngx.header["Content-Type"] = "application/xml; charset=UTF-8"
    local data = ''
    -- data = app:get_buckets_location("pic")
    -- data = app:get_buckets_acl("pic")
    if (bucket and create ) then
        data = app:create_bucket(bucket)
    elseif ((not file) and (not del) and bucket) then
        agrs = 'max-keys=200'
        data = app:get_all_objs(bucket, agrs)
    elseif (file and bucket and content) then
        ngx.header["Content-Type"] = ""
        local data = app:create_obj(bucket, file, content)
    elseif (bucket and file and del) then
        data = app:del_obj(bucket, file)
    elseif ((not file) and bucket and del) then
        data = app:del_bucket(bucket)
    elseif (not del and bucket and file) then
        ngx.header["Content-Type"] = ""
        local existance = app:check_for_existance(bucket, file)
        ngx.say(existance)
        data = app:get_obj(bucket, file)
        -- ngx.say(app:get_obj_acl(bucket, file))

    else
        data = app:get_all_buckets()
    
    end
    ngx.say(data)

end

return _M
