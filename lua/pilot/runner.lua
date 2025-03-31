local fs_utils = require("pilot.fs_utils")
local interpolate_command = require("pilot.interpolation")
local pathfinder = require("pilot.pathfinder")

---@alias RunClassification "project"|"file type"

---@class TaskEntry
---@field name string?
---@field command string?
---@field import string?
---@field location string?

---@class ExecutorParams
---@field name string
---@field command string

---@class LastExecutedTask
---@field entry TaskEntry
---@field executor fun(params: ExecutorParams)

local M = {
    last_executed_task = nil,
}

---@param entry TaskEntry
---@param known_executor fun(params: ExecutorParams)?
local function execute_task(entry, known_executor)
    local executor_params = {
        name = entry.name or "",
        command = interpolate_command(entry.command or ""),
    }

    if known_executor then
        known_executor(executor_params)
        return
    end

    local executor
    if entry.location == nil then
        executor = M.neovim_integrated_terminal_executor
    else
        if not M.config or not M.config.custom_locations then
            error(
                "[Pilot] Error: Attempted to use a custom location, but none have been configured. Please define 'custom_locations' in your configuration."
            )
        end
        executor = M.config.custom_locations[entry.location]
    end
    if executor == nil then
        error(
            string.format(
                "[Pilot] Error: Attempted to retrieve custom location '%s' from 'custom_locations' in your configuration, but got nil instead.",
                entry.location
            )
        )
    end

    M.last_executed_task = {
        entry = entry,
        executor = executor,
    }
    executor(executor_params)
end

---@return string?
local function read_fallback_project_run_config()
    local fallback_project_run_config = M.config.fallback_project_run_config()
    if type(fallback_project_run_config) ~= "string" then
        error(
            "[Pilot] Error: 'fallback_project_run_config' must return a string or nil."
        )
    end

    local fallback_path = pathfinder.get_pilot_data_path()
        .. "/"
        .. fallback_project_run_config
    local file_content = fs_utils.read_file_to_string(fallback_path)
    if file_content == nil then
        error(
            string.format(
                "[Pilot] Error: Failed to read fallback project run config at '%s', please ensure that the file exists and readable",
                fallback_path
            )
        )
    end
    return file_content
end

---@param entries table
---@param run_classification string
---@return table?
local function parse_entries(entries, run_classification)
    local enumerated_entries = {}

    for _, entry in ipairs(entries) do
        if type(entry) ~= "table" then
            error(
                string.format(
                    "[Pilot] Error: Each entry in the '%s' run config must be a valid JSON object.",
                    run_classification
                )
            )
        end
        if not entry.command and not entry.import then
            error(
                "[Pilot] Error: Each entry must have either a 'command' or 'import' attribute, but not both."
            )
        end

        if entry.command and entry.import then
            error(
                "[Pilot] Error: Entries cannot have both 'command' and 'import' attributes simultaneously."
            )
        end

        if entry.command then
            entry.name = entry.name or entry.command
            table.insert(
                enumerated_entries,
                { index = #enumerated_entries + 1, entry = entry }
            )
        else
            local file_content = fs_utils.read_file_to_string(
                pathfinder.get_pilot_dirpath() .. "/" .. entry.import
            )
            if not file_content then
                return
            end
            local imported_entries = vim.fn.json_decode(file_content)
            if type(imported_entries) ~= "table" then
                error(
                    "[Pilot] Error: Imported run config must be a valid JSON list."
                )
            end
            local imported_enumerated_entries =
                parse_entries(imported_entries, run_classification)
            if not imported_enumerated_entries then
                return
            end

            for _, imported_entry in ipairs(imported_enumerated_entries) do
                local unique = true
                for _, existing_entry in ipairs(enumerated_entries) do
                    if
                        existing_entry.entry.name == imported_entry.entry.name
                    then
                        unique = false
                        break
                    end
                end
                if unique then
                    table.insert(enumerated_entries, {
                        index = #enumerated_entries + 1,
                        entry = imported_entry.entry,
                    })
                end
            end
        end
    end
    return enumerated_entries
end

---@param run_config_path string
---@param run_classification RunClassification
---@return table?
local function parse_run_config(run_config_path, run_classification)
    local file_content = fs_utils.read_file_to_string(run_config_path)
    if not file_content then
        if
            run_classification == "project"
            and M.config.fallback_project_run_config
        then
            if M.config.fallback_project_run_config == nil then
                print(
                    "[Pilot] Error: No project run config detected and no fallback configuration."
                )
                return
            end
            file_content = read_fallback_project_run_config()
        else
            print(
                string.format(
                    "[Pilot] no detected run config for this %s.",
                    run_classification
                )
            )
            return
        end
    end

    local entries = vim.fn.json_decode(file_content)
    if type(entries) ~= "table" then
        error("[Pilot] must be a valid JSON list/array.")
    end
    return parse_entries(entries, run_classification)
end

---@param config Config
---@param neovim_integrated_terminal_executor LocationExecutor
M.init = function(config, neovim_integrated_terminal_executor)
    M.config = config
    M.neovim_integrated_terminal_executor = neovim_integrated_terminal_executor
end

---@param run_config_path string
---@param run_classification RunClassification
M.select_command_and_execute = function(run_config_path, run_classification)
    local enumerated_entries =
        parse_run_config(run_config_path, run_classification)
    if not enumerated_entries then
        print(
            string.format(
                "[Pilot] no command is specified for the %s run config.",
                run_classification
            )
        )
        return
    end

    if
        #enumerated_entries == 1
        and (
            run_classification == "project"
            and M.config.automatically_run_single_command.project
            or run_classification == "file type"
            and M.config.automatically_run_single_command.file_type
        )
    then
        execute_task(enumerated_entries[1].entry)
    else
        vim.ui.select(enumerated_entries, {
            prompt = string.format(
                "Select a run command for this %s"
                .. (
                    run_classification == "file type"
                    and " (" .. vim.bo.filetype .. ")"
                    or ""
                ),
                run_classification
            ),
            format_item = function(entry)
                return string.format("%d. %s", entry.index, entry.entry.name)
            end,
        }, function(selected)
            if selected then
                execute_task(selected.entry)
            end
        end)
    end
end

M.run_last_executed_task = function()
    if not M.last_executed_task then
        print("[Pilot] no previously executed task.")
        return
    end
    execute_task(M.last_executed_task.entry, M.last_executed_task.executor)
end

return M
