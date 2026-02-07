---@param options Config
local function validate_opts(options)
    if type(options) ~= "table" then
        error("[Pilot] given configuration must be a table")
    elseif
        type(options.run_config_path.project) ~= "function"
        and type(options.run_config_path.project) ~= "table"
    then
        error(
            "[Pilot] option 'run_config_path.project' must either be a function, table, or nil."
        )
    elseif
        type(options.run_config_path.file_type) ~= "function"
        and type(options.run_config_path.file_type) ~= "table"
    then
        error(
            "[Pilot] option 'run_config_path.file_type' must either be a function, table, or nil."
        )
    elseif type(options.auto_run_single_command) ~= "table" then
        error("[Pilot] option 'auto_run_single_command' must be a table.")
    elseif type(options.auto_run_single_command.project) ~= "boolean" then
        error(
            "[Pilot] option 'auto_run_single_command.project' must be a boolean."
        )
    elseif type(options.auto_run_single_command.file_type) ~= "boolean" then
        error(
            "[Pilot] option 'auto_run_single_command.file_type' must be a boolean."
        )
    elseif type(options.default_executor) ~= "table" then
        error("[Pilot] option 'default_executor' must be a table.")
    elseif type(options.default_executor.project) ~= "function" then
        error("[Pilot] option 'default_executor.project' must be a function.")
    elseif type(options.default_executor.file_type) ~= "function" then
        error("[Pilot] option 'default_executor.file_type' must be a function.")
    elseif type(options.executors) ~= "table" then
        error("[Pilot] option 'executors' must be a table.")
    elseif type(options.placeholders.vars) ~= "table" then
        error("[Pilot] option 'placeholders.vars' must be a table.")
    elseif type(options.placeholders.funcs) ~= "table" then
        error("[Pilot] option 'placeholders.funcs' must be a table.")
    end
end

return validate_opts
