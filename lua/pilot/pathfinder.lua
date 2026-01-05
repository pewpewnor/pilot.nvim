local interpolate = require("pilot.interpolation")

local M = {}

---@param config Config
function M.init(config)
    M.config = config
end

---@param dir_path string
---@return string?
local function create_dir_path(dir_path)
    if
        vim.fn.isdirectory(dir_path) == 0
        and vim.fn.mkdir(dir_path, "p") == 0
    then
        return nil
    end
    return dir_path
end

---@param path string
---@param create_missing_dirs boolean
local function custom_run_config_path(path, create_missing_dirs)
    local dir_path = vim.fs.dirname(path)
    if create_missing_dirs and not create_dir_path(dir_path) then
        error(
            string.format(
                "[Pilot] Failed to create custom directory at '%s'.",
                dir_path
            )
        )
    end
    return path
end

---@param create_missing_dirs boolean
---@return string
function M.get_project_run_config_path(create_missing_dirs)
    local first_valid_interpolated_path
    if type(M.config.run_config_path.project) == "string" then
        first_valid_interpolated_path =
            ---@diagnostic disable-next-line: param-type-mismatch
            interpolate(M.config.run_config_path.project)
    else
        ---@diagnostic disable-next-line: param-type-mismatch
        for _, path in pairs(M.config.run_config_path.project) do
            local interpolated_path = interpolate(path)
            if
                not first_valid_interpolated_path
                or vim.fn.filereadable(interpolated_path) == 1
            then
                first_valid_interpolated_path = interpolated_path
            end
        end
    end
    return custom_run_config_path(
        first_valid_interpolated_path,
        create_missing_dirs
    )
end

---@param create_missing_dirs boolean
---@return string
function M.get_file_type_run_config_path(create_missing_dirs)
    local interpolated_path = interpolate(M.config.run_config_path.file_type)
    return custom_run_config_path(interpolated_path, create_missing_dirs)
end

return M
