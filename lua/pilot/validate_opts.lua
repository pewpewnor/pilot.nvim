local default_config = require("pilot.default_config")

---@param targets Targets
local function fill_and_validate_targets(targets)
    vim.iter(targets):each(function(target_name, target_config)
        targets[target_name] = default_config.fill_target(target_config)
        target_config = targets[target_name]

        vim.validate(
            "targets." .. target_name,
            target_config,
            "table"
        )
        vim.validate(
            "targets." .. target_name .. ".pilot_file_path",
            target_config.pilot_file_path,
            { "function", "table", "nil" }
        )
        vim.validate(
            "targets." .. target_name .. ".auto_run_single_command",
            target_config.auto_run_single_command,
            "boolean"
        )
        vim.validate(
            "targets." .. target_name .. ".default_executor",
            target_config.default_executor,
            "function"
        )
    end)
end

---@param options Config
local function validate_opts(options)
    vim.validate("options", options, "table")
    vim.validate("options.executors", options.executors, "table")
    vim.validate("options.placeholders.vars", options.placeholders.vars, "table")
    vim.validate("options.placeholders.funcs", options.placeholders.funcs, "table")
    vim.validate("options.display.numbered", options.display.numbered, "boolean")
    vim.validate("options.display.last_entry_new_line", options.display.last_entry_new_line, "boolean")
    vim.validate("options.targets", options.targets, "table")
    fill_and_validate_targets(options.targets)
end

return validate_opts
