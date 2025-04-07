local M = {}

---@param path string
---@return string?
function M.read_file(path)
    local success, lines = pcall(vim.fn.readfile, path)
    return success and vim.fn.join(lines) or nil
end

---@param json_string string
---@return any?
function M.decode_json(json_string)
    local success, result = pcall(vim.fn.json_decode, json_string)
    return success and result or nil
end

return M
