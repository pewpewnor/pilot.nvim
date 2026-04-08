local interpolation = require("pilot.interpolation")
local common = require("pilot.common")
local M = {}

---@param config Config
function M.init(config)
    M.config = config
end

---@param resolver RunConfigPathResolver
---@return string|nil
local function resolve_path(resolver)
    local raw_path = resolver()
    if raw_path == nil then
        return nil
    end
    if type(raw_path) ~= "string" then
        error(
            "[Pilot] Run configuration path function must return a string path or nil."
        )
    end
    return interpolation.interpolate(raw_path)
end

---@param path_resolvers RunConfigPathResolver|RunConfigPathResolver[]
---@return string
function M.get_true_path(path_resolvers)
    local resolvers
    if type(path_resolvers) == "function" then
        resolvers = { path_resolvers }
    elseif type(path_resolvers) == "table" and #path_resolvers > 0 then
        resolvers = path_resolvers
    else
        error(
            "[Pilot] Run config path function must be a function or a list of functions."
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
        print("[Pilot] No run configuration file exist.")
    end
    return first_interpolated_path
end

return M
