local function check_local_project_config_dir(option)
    if type(option) ~= "string" and option ~= nil then
        error("[pilot] option 'local_project_config' must either be string or nil")
    end
end

---@param options Config
local function validate_config(options)
    check_local_project_config_dir(options.local_project_config_dir)
end

return validate_config
