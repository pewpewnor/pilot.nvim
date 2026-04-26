local common = require("pilot.common")
local default_config = require("pilot.default_config")

---@param targets Targets
local function fill_and_validate_targets(targets)
    ---@diagnostic disable-next-line: undefined-field
    common.iter(targets):each(function(target_name, target_config)
        targets[target_name] = default_config.fill_target(target_config)
        target_config = targets[target_name]

        common.validate("targets." .. target_name, target_config, "table")
        common.validate(
            "targets." .. target_name .. ".pilot_file_path",
            target_config.pilot_file_path,
            { "function", "table", "nil" }
        )
        common.validate(
            "targets." .. target_name .. ".auto_run_single_command",
            target_config.auto_run_single_command,
            "boolean"
        )
        common.validate(
            "targets." .. target_name .. ".default_executor",
            target_config.default_executor,
            "function"
        )
    end)
end

---@param options Config
local function validate_opts(options)
    common.validate("options", options, "table")
    common.validate("options.executors", options.executors, "table")
    common.validate(
        "options.placeholders.vars",
        options.placeholders.vars,
        "table"
    )
    common.validate(
        "options.placeholders.funcs",
        options.placeholders.funcs,
        "table"
    )
    common.validate(
        "options.display.numbered",
        options.display.numbered,
        "boolean"
    )
    common.validate(
        "options.display.last_entry_new_line",
        options.display.last_entry_new_line,
        "boolean"
    )
    common.validate("options.targets", options.targets, "table")
    fill_and_validate_targets(options.targets)
end

return validate_opts
