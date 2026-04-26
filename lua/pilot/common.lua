local M = {}

---@param path string
---@return string?
function M.read_file(path)
    local success, lines = pcall(vim.fn.readfile, path)
    return success and vim.fn.join(lines) or nil
end

---@param path string
---@param lines string[]
---@param mode nil|"a"
---@return boolean
function M.write_file(path, lines, mode)
    return vim.fn.writefile(lines, path, mode) == 0
end

---@param json_string string
---@return any?
function M.json_decode(json_string)
    local success, result = pcall(vim.json.decode, json_string)
    return success and result or nil
end

---@param path string
---@return boolean
function M.is_directory(path)
    return vim.fn.isdirectory(path) == 1
end

---@param path string
---@return boolean
function M.is_file_and_readable(path)
    return vim.fn.filereadable(path) == 1
end

---@param path string
---@return boolean
function M.mkdir_with_parents(path)
    if M.is_directory(path) then
        return true
    end
    local parent = vim.fs.dirname(path)
    if parent and parent ~= path then
        M.mkdir_with_parents(parent)
    end
    return vim.uv.fs_mkdir(path, 493) == true
end

return M
