local M = {}

M.get_pilot_data_path = function()
    local pilot_dir_path = fs_utils.get_data_path() .. "/pilot"
    fs_utils.mkdir(pilot_dir_path)
    return pilot_dir_path
end

M.get_file_type_config_file_path = function()
    return M.get_pilot_data_path() .. "/filetypes/" .. fs_utils.get_current_file_type() .. ".json"
end

M.get_project_config_file_path = function()
    if M.config.local_project_config_dir then
        return fs_utils.get_cwd_path() .. "/" .. M.config.local_project_config_dir .. "/pilot.json"
    end
    return M.get_pilot_data_path() .. "/projects/" .. fs_utils.hash_sha_256(fs_utils.get_cwd_path()) .. ".json"
end

return M
