local M = {}

---@param path string
---@return string?
M.read_file = function(path)
    local success, lines = pcall(vim.fn.readfile, path)
    return success and vim.fn.join(lines) or nil
end

---@param json_string string
---@return any?
M.decode_json = function(json_string)
    local success, result = pcall(vim.fn.json_decode, json_string)
    return success and result or nil
end

return M
