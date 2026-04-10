local default_config = require("pilot.default_config")

---@param targets Targets
local function fill_and_validate_targets(targets)
    for target_name, target_config in pairs(targets) do
        targets[target_name] = default_config.fill_target(target_config)
        target_config = targets[target_name]

        if type(target_config) ~= "table" then
            error(
                "[Pilot] option 'targets."
                    .. target_name
                    .. "' must be a table."
            )
        elseif
            type(target_config.pilot_file_path) ~= "function"
            and type(target_config.pilot_file_path) ~= "table"
        then
            error(
                "[Pilot] option 'targets."
                    .. target_name
                    .. ".pilot_file_path' must either be a function, table, or nil."
            )
        elseif type(target_config.auto_run_single_command) ~= "boolean" then
            error(
                "[Pilot] option 'targets."
                    .. target_name
                    .. ".auto_run_single_command' must be a boolean."
            )
        elseif type(target_config.default_executor) ~= "function" then
            error(
                "[Pilot] option 'targets."
                    .. target_name
                    .. ".default_executor' must be a function."
            )
        end
    end
end

---@param options Config
local function validate_opts(options)
    if type(options) ~= "table" then
        error("[Pilot] given configuration must be a table")
    elseif type(options.executors) ~= "table" then
        error("[Pilot] option 'executors' must be a table.")
    elseif type(options.placeholders.vars) ~= "table" then
        error("[Pilot] option 'placeholders.vars' must be a table.")
    elseif type(options.placeholders.funcs) ~= "table" then
        error("[Pilot] option 'placeholders.funcs' must be a table.")
    elseif type(options.display.numbered) ~= "boolean" then
        error("[Pilot] option 'display.numbered' must be a boolean.")
    elseif type(options.display.last_entry_new_line) ~= "boolean" then
        error("[Pilot] option 'display.last_entry_new_line' must be a boolean.")
    elseif type(options.targets) ~= "table" then
        error("[Pilot] option 'targets' must be a table.")
    else
        fill_and_validate_targets(options.targets)
    end
end

return validate_opts
