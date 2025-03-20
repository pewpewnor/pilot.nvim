local M = {}

---@param config Config
function M.init(config)
    M.config = config
end

---@return string
function M.get_pilot_data_path()
    local pilot_data_path = vim.fn.stdpath("data") .. "/pilot"
    if
        not vim.fn.isdirectory(pilot_data_path)
        and not vim.fn.mkdir(pilot_data_path)
    then
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
function M.get_file_type_run_file_path()
    return string.format(
        "%s/filetypes/%s.json",
        M.get_pilot_data_path(),
        vim.bo.filetype
    )
end

---@return string
function M.get_project_run_file_path()
    if M.config.local_project_config_dir then
        return string.format(
            "%s/%s/pilot.json",
            vim.fn.getcwd(),
            M.config.local_project_config_dir
        )
    end
    return string.format(
        "%s/projects/%s.json",
        M.get_pilot_data_path(),
        vim.fn.sha256(vim.fn.getcwd())
    )
end

return M
