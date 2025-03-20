---@param options Config
local function validate_config(options)
    if options ~= nil and type(options) ~= "table" then
        error("[Pilot] given configuration must be a table or nil")
    end

    if
        options.local_project_config_dir ~= nil
        and type(options.local_project_config_dir) ~= "string"
    then
        error(
            "[Pilot] option 'local_project_config_dir' must either be a string or nil."
        )
    end

    if type(options.automatically_run_single_command) ~= "table" then
        error(
            "[Pilot] option 'automatically_run_single_command' must be a table."
        )
    end
    if type(options.automatically_run_single_command.project) ~= "boolean" then
        error(
            "[Pilot] option 'automatically_run_single_command.project' must be a boolean."
        )
    end
    if
        type(options.automatically_run_single_command.file_type) ~= "boolean"
    then
        error(
            "[Pilot] option 'automatically_run_single_command.file_type' must be a boolean."
        )
    end

    if
        options.fallback_project_run_config ~= nil
        and type(options.fallback_project_run_config) ~= "function"
    then
        error(
            "[Pilot] option 'fallback_project_run_file' must be a function or nil."
        )
    end

    if
        options.custom_locations ~= nil
        and type(options.custom_locations) ~= "table"
    then
        error("[Pilot] option 'custom_locations' must be a table or nil.")
    end
end

return validate_config
