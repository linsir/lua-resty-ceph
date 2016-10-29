
config = {
    timeout = 300, -- * 24 * 3600 -- redis timeout (sec)
    ceph_mode = true,
    host = 'http://httpbin.org',
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

    local cephs3 = require("resty.cephs3")
    local app = cephs3:new(config.access_key, config.secret_key, config.host)

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
