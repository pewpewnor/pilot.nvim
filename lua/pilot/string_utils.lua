local M = {}

---@param str string
---@return string
M.escape_for_regex_pattern = function(str)
    return (str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

---@param str string
---@param char string
---@return string
M.slice_from_last_occur_char_to_end = function(str, char)
    return str:match("([^" .. M.escape_for_regex_pattern(char) .. "]+)$")
end

---@param str string
---@param char string
---@return string
M.slice_from_start_up_to_last_occur_char = function(str, char)
    local res = str:match("^(.*" .. M.escape_for_regex_pattern(char) .. ")")
    return res ~= nil and res:sub(1, #res - 1) or res
end

return M
