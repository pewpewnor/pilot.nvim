local M = {}

---@param path string
M.rm = function(path)
    vim.fn.system("rm -r " .. path)
end

---@param path string
---@return string?
M.read_file_to_string = function(path)
    local file = io.open(path:gsub("\\ ", " "), "r")
    if not file then
        return nil
    end
    local content = file:read("*all")
    file:close()
    return content
end

return M
