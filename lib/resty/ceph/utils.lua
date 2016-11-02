local _M = {}
_M._VERSION = '0.0.3'

-- [[判断str是否以substr开头。是返回true，否返回false，失败返回失败信息]]
function _M.startswith (str, substr)
    if str == nil or substr == nil then
        return nil, "the string or the sub-stirng parameter is nil"
    end
    if string.find(str, substr) ~= 1 then
        return false
    else
        return true
    end
end

-- [[将str中的小写字母替换成大写字母，返回替换后的新串。失败返回nil和失败信息]]
function _M.upper(str)
    if str == nil then
        return nil, "the string parameter is nil"
    end
    local len = string.len(str)
    local str_tmp = ""
    for i = 1, len do
        local ch = string.sub(str, i, i)
        if ch >= 'a' and ch <= 'z' then
            ch = string.char(string.byte(ch) - 32)
        end
        str_tmp = str_tmp .. ch
    end
    return str_tmp
end

-- [[将str中的大写字母替换成小写字母，返回替换后的新串。失败返回nil和失败信息]]
function _M.lower(str)
    if str == nil then
        return nil, "the string parameter is nil"
    end
    local len = string.len(str)
    local str_tmp = ""
    for i = 1, len do
        local ch = string.sub(str, i, i)
        if ch >= 'A' and ch <= 'Z' then
            ch = string.char(string.byte(ch) + 32)
        end
        str_tmp = str_tmp .. ch
    end
    return str_tmp
end
-- [[检测数组中是否包含某个值]]
function _M.in_array(value, list)
    if not list then
        return false
    else
        for k, v in ipairs(list) do
            if v == value then
                return true
            end
        end
        return false
    end
end

return _M