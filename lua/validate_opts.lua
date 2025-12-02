---@param options Config
local function validate_opts(options)
    if type(options) ~= "table" and options ~= nil then
        error("[Pilot] given configuration must be a table or nil")
    elseif
        type(options.project_run_config_path) ~= "string"
        and options.project_run_config_path ~= nil
    then
        error(
            "[Pilot] option 'project_run_config_path' must either be a string or nil."
        )
    elseif
        type(options.file_type_run_config_path) ~= "string"
        and options.file_type_run_config_path ~= nil
    then
        error(
            "[Pilot] option 'file_type_run_config_path' must either be a string or nil."
        )
    elseif type(options.automatically_run_single_command) ~= "table" then
        error(
            "[Pilot] option 'automatically_run_single_command' must be a table."
        )
    elseif
        type(options.automatically_run_single_command.project) ~= "boolean"
    then
        error(
            "[Pilot] option 'automatically_run_single_command.project' must be a boolean."
        )
    elseif
        type(options.automatically_run_single_command.file_type) ~= "boolean"
    then
        error(
            "[Pilot] option 'automatically_run_single_command.file_type' must be a boolean."
        )
    elseif
        type(options.fallback_project_run_config) ~= "function"
        and options.fallback_project_run_config ~= nil
    then
        error(
            "[Pilot] option 'fallback_project_run_config' must be a function or nil."
        )
    elseif type(options.default_executor) ~= "table" then
        error("[Pilot] option 'default_executor' must be a table.")
    elseif type(options.default_executor.project) ~= "function" then
        error("[Pilot] option 'default_executor.project' must be a function.")
    elseif type(options.default_executor.file_type) ~= "function" then
        error("[Pilot] option 'default_executor.file_type' must be a function.")
    elseif type(options.custom_locations) ~= "table" then
        error("[Pilot] option 'custom_locations' must be a table.")
    end
end

return validate_opts
