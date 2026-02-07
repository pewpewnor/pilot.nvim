local interpolation = require("pilot.interpolation")
local common = require("pilot.common")
local M = {}

---@param config Config
function M.init(config)
    M.config = config
end

---@param path_resolvers RunConfigPathResolver|RunConfigPathResolver[]
---@return string
local function get_run_config_path(path_resolvers)
    local resolvers
    if type(path_resolvers) == "function" then
        resolvers = { path_resolvers }
    elseif type(path_resolvers) == "table" then
        resolvers = path_resolvers
    end

    local first_interpolated_path = nil

    for _, resolver in ipairs(resolvers) do
        local raw_path = resolver()
        if raw_path ~= nil then
            if type(raw_path) ~= "string" then
                error(
                    "[Pilot] Run config path function must return a string path or nil."
                )
            end
            local interpolated_path = interpolation.interpolate(raw_path)

            if first_interpolated_path == nil then
                first_interpolated_path = interpolated_path
            end

            if common.is_file_and_readable(interpolated_path) then
                return interpolated_path
            end
        end
    end

    if first_interpolated_path ~= nil then
        return first_interpolated_path
    end

    error(
        "[Pilot] You must have at least one run config path function that returns a string for this to work."
    )
end

---@return string
function M.get_project_run_config_path()
    return get_run_config_path(M.config.run_config_path.project)
end

---@return string
function M.get_file_type_run_config_path()
    return get_run_config_path(M.config.run_config_path.file_type)
end

return M
