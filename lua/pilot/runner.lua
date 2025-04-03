local fs_utils = require("pilot.fs_utils")
local interpolate_command = require("pilot.interpolation")

---@alias RunClassification "project"|"file type"

---@class Entry
---@field name string?
---@field command string?
---@field import string?
---@field location string?

---@alias Entries Entries

---@class Task
---@field command string
---@field executor Executor

local M = {}

---@type Task|nil
M.last_executed_task = nil

---@param entry Entry
local function execute_entry(entry)
    local command = interpolate_command(entry.command)
    local executor

    if entry.location == nil then
        executor = M.config.default_executor
    else
        if not M.config or not M.config.custom_locations then
            error(
                "[Pilot] Error: Attempted to use a custom location, but none have been configured. Please define 'custom_locations' in your configuration."
            )
        end
        executor = M.config.custom_locations[entry.location]
        if not executor then
            error(
                string.format(
                    "[Pilot] Error: Attempted to retrieve custom location '%s' from 'custom_locations' in your configuration, but got nil instead.",
                    entry.location
                )
            )
        end
    end

    M.last_executed_task = {
        command = command,
        executor = executor,
    }
    executor(command)
end

---@return string?
local function read_fallback_project_run_config()
    local fallback_project_run_config = M.config.fallback_project_run_config()
    if not fallback_project_run_config then
        return nil
    end
    if type(fallback_project_run_config) ~= "string" then
        error(
            "[Pilot] Error: 'fallback_project_run_config' must return a string or nil."
        )
    end

    local fallback_path = interpolate_command(fallback_project_run_config)
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

---@param entries Entries
---@param command string
local function add_string_entry(entries, command)
    table.insert(entries, { name = command, command = command })
end

---@param entries Entries
---@param entry Entry
local function add_command_entry(entries, entry)
    entry.name = entry.name or entry.command
    table.insert(entries, entry)
end

---@param entries Entries
---@param imported_entries Entries
local function add_imported_entries(entries, imported_entries)
    for _, imported_entry in ipairs(imported_entries) do
        table.insert(entries, imported_entry)
    end
end

---@param list table<number, table>
---@param run_config_path string
---@return Entries
local function parse_list_to_entries(list, run_config_path)
    if type(list) ~= "table" then
        error(
            string.format(
                "[Pilot] run config must be a valid JSON array in '%s'.",
                run_config_path
            )
        )
    end

    local entries = {}

    for _, item in ipairs(list) do
        local item_type = type(item)
        if item_type ~= "table" and item_type ~= "string" then
            error(
                string.format(
                    "[Pilot] Error: Each entry must be a valid JSON object or string in '%s'.",
                    run_config_path
                )
            )
        end

        if item_type == "string" then
            add_string_entry(entries, item)
        else
            if not item.command and not item.import then
                error(
                    string.format(
                        "[Pilot] Error: Each entry must either have a 'command' or an 'import' attribute in '%s'.",
                        run_config_path
                    )
                )
            end
            if item.command and item.import then
                error(
                    string.format(
                        "[Pilot] Error: Each entry cannot have both the 'command' and 'import' attribute simultaneously in '%s'.",
                        run_config_path
                    )
                )
            end

            if item.command then
                add_command_entry(entries, item)
            else
                local import_path = interpolate_command(item.import)
                local file_content = fs_utils.read_file_to_string(import_path)
                if not file_content then
                    error(
                        string.format(
                            "[Pilot] Error: imported file '%s' doesn't exist",
                            import_path
                        )
                    )
                end
                local imported_list = vim.fn.json_decode(file_content)
                -- TODO: pcall json_decode
                local imported_entries =
                    parse_list_to_entries(imported_list, import_path)
                add_imported_entries(entries, imported_entries)
            end
        end
    end
    return entries
end

---@param run_config_path string
---@param run_classification RunClassification
---@return Entries?
local function parse_run_config(run_config_path, run_classification)
    local file_content = fs_utils.read_file_to_string(run_config_path)
    if not file_content then
        if run_classification == "project" then
            if M.config.fallback_project_run_config == nil then
                print(
                    "[Pilot] Error: No project run config detected and no fallback configuration."
                )
                return
            end
            file_content = read_fallback_project_run_config()
            if not file_content then
                print(
                    "[Pilot] Error: No project run config detected and fallback returns nil."
                )
                return
            end
        else
            print(
                string.format(
                    "[Pilot] No detected run config for file type %s.",
                    vim.bo.filetype
                )
            )
            return
        end
    end

    local list = vim.fn.json_decode(file_content)
    -- TODO: pcall json_decode
    return parse_list_to_entries(list, run_config_path)
end

---@param config Config
M.init = function(config)
    M.config = config
end

---@param run_config_path string
---@param run_classification RunClassification
M.select_command_and_execute = function(run_config_path, run_classification)
    local entries = parse_run_config(run_config_path, run_classification)
    if not entries then
        return
    end

    if
        #entries == 1
        and (
            run_classification == "project"
                and M.config.automatically_run_single_command.project
            or run_classification == "file type"
                and M.config.automatically_run_single_command.file_type
        )
    then
        execute_entry(entries[1])
    else
        for i, entry in ipairs(entries) do
            entries[i].name = i .. ". " .. entry.name
        end
        vim.ui.select(entries, {
            prompt = "Select a run command for this "
                .. run_classification
                .. (
                    run_classification == "file type"
                        and " (" .. vim.bo.filetype .. ")"
                    or ""
                ),
            format_item = function(entry)
                return entry.name
            end,
        }, function(chosen_entry)
            if chosen_entry then
                execute_entry(chosen_entry)
            end
        end)
    end
end

M.run_last_executed_task = function()
    if not M.last_executed_task then
        print("[Pilot] no previously executed task.")
        return
    end
    M.last_executed_task.executor(M.last_executed_task.command)
end

return M
