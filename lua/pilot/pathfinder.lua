local interpolation = require("pilot.interpolation")
local common = require("pilot.common")
local M = {}

---@param config Config
function M.init(config)
    M.config = config
end

---@param resolver PilotFilepathResolver
---@return string|nil
local function resolve_path(resolver)
    local raw_path = resolver()
    if raw_path == nil then
        return nil
    end
    common.validate("pilot_file_path resolver return value", raw_path, "string")
    return interpolation.interpolate(raw_path)
end

---@param path_resolvers PilotFilepathResolver|PilotFilepathResolver[]
---@return string
function M.get_true_path(path_resolvers)
    local resolvers
    if type(path_resolvers) == "function" then
        resolvers = { path_resolvers }
    elseif type(path_resolvers) == "table" and #path_resolvers > 0 then
        resolvers = path_resolvers
    else
        error(
            "pilot.nvim: pilot file path must be a function or a list of functions"
        )
    end

    local first_interpolated_path
    for _, resolver in ipairs(resolvers) do
        local interpolated_path = resolve_path(resolver)
        first_interpolated_path = first_interpolated_path or interpolated_path
        if
            interpolated_path and common.is_file_and_readable(interpolated_path)
        then
            return interpolated_path
        end
    end

    if not first_interpolated_path then
        error("pilot.nvim: unexpected: no first interpolated path resolved")
    end
    return first_interpolated_path
end

return M
