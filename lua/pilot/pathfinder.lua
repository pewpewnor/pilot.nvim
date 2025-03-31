local M = {}

---@param dir_path string
---@return string?
local function create_dir_path(dir_path)
    if vim.fn.isdirectory(dir_path) == 0 and vim.fn.mkdir(dir_path) == 0 then
        return nil
    end
    return dir_path
end

---@param config Config
function M.init(config)
    M.config = config
end

---@return string
function M.get_pilot_data_path()
    local pilot_data_path = vim.fn.stdpath("data") .. "/pilot"
    if not create_dir_path(pilot_data_path) then
        error(
            string.format(
                "[Pilot] Failed to create pilot data directory at '%s'.",
                pilot_data_path
            )
        )
    end
    return pilot_data_path
end

---@return string
function M.get_file_type_run_config_path()
    local project_run_config_dir_path = M.get_pilot_data_path() .. "/projects"
    if not create_dir_path(project_run_config_dir_path) then
        error(
            string.format(
                "[Pilot] Failed to create project run config directory at '%s'.",
                project_run_config_dir_path
            )
        )
    end
    return string.format(
        "%s/filetypes/%s.json",
        M.get_pilot_data_path(),
        vim.bo.filetype
    )
end

---@return string
function M.get_project_run_config_path()
    if M.config.local_project_config_dir then
        return string.format(
            "%s/%s/pilot.json",
            vim.fn.getcwd(),
            M.config.local_project_config_dir
        )
    end
    local project_run_config_dir_path = M.get_pilot_data_path() .. "/projects"
    if not create_dir_path(project_run_config_dir_path) then
        error(
            string.format(
                "[Pilot] Failed to create project run config directory at '%s'.",
                project_run_config_dir_path
            )
        )
    end
    return string.format(
        "%s/%s.json",
        project_run_config_dir_path,
        vim.fn.sha256(vim.fn.getcwd())
    )
end

return M
