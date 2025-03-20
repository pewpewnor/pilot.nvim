local M = {}

---@param str string The string to escape for regex
---@return string Text The escaped string safe for regex patterns
M.escape_for_regex_pattern = function(str)
    return (str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

--The char itself will not be included
--Returns the whole string if the character is not found
---@param str string The input string
---@param char string The character to slice from
---@return string Text The substring after the last occurrence of the character
M.slice_from_last_occur_char_to_end = function(str, char)
    return str:match("([^" .. M.escape_for_regex_pattern(char) .. "]+)$")
end

--The last occurrence of the char will not be included
--Returns the whole string if the character is not found
---@param str string The input string
---@param char string The character to slice up to
---@return string Text The substring before the last occurrence of the character
M.slice_from_start_up_to_last_occur_char = function(str, char)
    local res = str:match("^(.*" .. M.escape_for_regex_pattern(char) .. ")")
    return res ~= nil and res:sub(1, #res - 1) or res
end

return M
