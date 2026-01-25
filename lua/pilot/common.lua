local M = {}

---@param path string
---@return string?
function M.read_file(path)
    local success, lines = pcall(vim.fn.readfile, path)
    return success and vim.fn.join(lines) or nil
end

---@param json_string string
---@return any?
function M.json_decode(json_string)
    local success, result = pcall(vim.fn.json_decode, json_string)
    return success and result or nil
end

---@param path string
---@return boolean
function M.is_directory(path)
    return vim.fn.isdirectory(path) == 1
end

---@param path string
---@return boolean
function M.mkdir_with_parents(path)
    return vim.fn.mkdir(path, "p") == 1
end

---@param path string
---@return boolean
function M.is_file_and_readable(path)
    return vim.fn.filereadable(path) == 1
end

return M
