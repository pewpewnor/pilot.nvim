local default_config = require("pilot.default_config")

---@param run_classes RunClasses
local function fill_and_validate_run_classes(run_classes)
    for class_name, class_config in pairs(run_classes) do
        run_classes[class_name] = default_config.fill_run_class(class_config)
        class_config = run_classes[class_name]

        if type(class_config) ~= "table" then
            error(
                "[Pilot] option 'run_classes."
                    .. class_name
                    .. "' must be a table."
            )
        elseif
            type(class_config.run_config_path) ~= "function"
            and type(class_config.run_config_path) ~= "table"
        then
            error(
                "[Pilot] option 'run_classes."
                    .. class_name
                    .. ".run_config_path' must either be a function, table, or nil."
            )
        elseif type(class_config.auto_run_single_command) ~= "boolean" then
            error(
                "[Pilot] option 'run_classes."
                    .. class_name
                    .. ".auto_run_single_command' must be a boolean."
            )
        elseif type(class_config.default_executor) ~= "function" then
            error(
                "[Pilot] option 'run_classes."
                    .. class_name
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
    elseif type(options.run_classes) ~= "table" then
        error("[Pilot] option 'run_classes' must be a table.")
    else
        fill_and_validate_run_classes(options.run_classes)
    end
end

return validate_opts
