local interpolate = require("pilot.interpolation")

local M = {}

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
---@param create_missing_dirs boolean?
local function custom_run_config_path(path, create_missing_dirs)
    path = interpolate(path)
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

---@return string
---@param create_missing_dirs boolean?
local function get_pilot_data_path(create_missing_dirs)
    local pilot_data_path = vim.fs.joinpath(vim.fn.stdpath("data"), "pilot")
    if create_missing_dirs and not create_dir_path(pilot_data_path) then
        error(
            string.format(
                "[Pilot] Failed to create pilot data directory at '%s'.",
                pilot_data_path
            )
        )
    end
    return pilot_data_path
end

---@param config Config
function M.init(config)
    M.config = config
end

---@param create_missing_dirs boolean?
---@return string
function M.get_default_project_run_config_dir_path(create_missing_dirs)
    local default_dir_path =
        vim.fs.joinpath(get_pilot_data_path(create_missing_dirs), "projects")
    if create_missing_dirs and not create_dir_path(default_dir_path) then
        error(
            string.format(
                "[Pilot] Failed to create file type run configuration directory at '%s'.",
                default_dir_path
            )
        )
    end
    return default_dir_path
end

---@param create_missing_dirs boolean?
---@return string
function M.get_default_file_type_run_config_dir_path(create_missing_dirs)
    local default_dir_path =
        vim.fs.joinpath(get_pilot_data_path(create_missing_dirs), "filetypes")
    if create_missing_dirs and not create_dir_path(default_dir_path) then
        error(
            string.format(
                "[Pilot] Failed to create file type run configuration directory at '%s'.",
                default_dir_path
            )
        )
    end
    return default_dir_path
end

---@param create_missing_dirs boolean?
---@return string
function M.get_project_run_config_path(create_missing_dirs)
    if M.config.project_run_config_path then
        return custom_run_config_path(
            M.config.project_run_config_path,
            create_missing_dirs
        )
    end

    return vim.fs.joinpath(
        M.get_default_project_run_config_dir_path(create_missing_dirs),
        vim.fn.sha256(vim.fn.getcwd())
    ) .. ".json"
end

---@param create_missing_dirs boolean?
---@return string
function M.get_file_type_run_config_path(create_missing_dirs)
    if M.config.file_type_run_config_path then
        return custom_run_config_path(
            M.config.file_type_run_config_path,
            create_missing_dirs
        )
    end

    return vim.fs.joinpath(
        M.get_default_file_type_run_config_dir_path(create_missing_dirs),
        vim.bo.filetype
    ) .. ".json"
end

return M
