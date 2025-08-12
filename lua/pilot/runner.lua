local fs_utils = require("pilot.fs_utils")
local interpolate = require("pilot.interpolation")

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
---@field args [string]

local M = {}

---@type Task|nil
M.last_executed_task = nil

---@param task Task
local function execute_task(task)
    task.executor(interpolate(task.command), task.args)
end

---@param entry Entry
local function run_entry(entry)
    local executor
    local args = {}
    if not entry.location then
        executor = M.config.default_executor
    else
        if not M.config.custom_locations then
            error(
                "[Pilot] Error: Attempted to use a custom location, but none have been configured. Please define 'custom_locations' in your configuration."
            )
        end
        args = vim.fn.split(entry.location, " ")
        local executor_name = table.remove(args, 1)
        executor = M.config.custom_locations[executor_name]
        if not executor then
            error(
                string.format(
                    "[Pilot] Error: Attempted to retrieve custom location '%s' from given custom locations in your configuration, but got nil instead.",
                    entry.location
                )
            )
        end
    end

    M.last_executed_task = {
        command = entry.command,
        executor = executor,
        args = args,
    }
    execute_task(M.last_executed_task)
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

    local fallback_path = interpolate(fallback_project_run_config)
    local file_content = fs_utils.read_file(fallback_path)
    if not file_content then
        error(
            string.format(
                "[Pilot] Error: Failed to read fallback project run configuration at '%s'.",
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

---@param import_path string
---@return table
local function read_and_decode_imported_path(import_path)
    local file_content = fs_utils.read_file(import_path)
    if not file_content then
        error(
            string.format(
                "[Pilot] Error: Imported file '%s' doesn't exist",
                import_path
            )
        )
    end
    -- TODO: validate JSON return must be a table (list)
    local imported_list = fs_utils.decode_json(file_content)
    if not imported_list then
        error(
            string.format(
                "[Pilot] Error: Imported file '%s' has invalid JSON format or is empty.",
                import_path
            )
        )
    end
    if type(imported_list) ~= "table" then
        error(
            string.format(
                "[Pilot] Error: Imported file '%s' should contain JSON array, refer to the documentation for proper run configuration format.",
                import_path
            )
        )
    end
    return imported_list
end

---@param list table<number, table>
---@param run_config_path string
---@return Entries
local function parse_list_to_entries(list, run_config_path)
    if type(list) ~= "table" then
        error(
            string.format(
                "[Pilot] run configuration must be a valid JSON array in '%s'.",
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
                if type(item.command) == "table" then
                    ---@diagnostic disable-next-line: param-type-mismatch
                    item.command = table.concat(item.command, " && ")
                elseif type(item.command) ~= "string" then
                    error(
                        "[Pilot] Command must be a string or a list of strings"
                    )
                end
                add_command_entry(entries, item)
            else
                if type(item.import) ~= "string" then
                    error(
                        "[Pilot] Imported item must be a string that resolves to a path of a file"
                    )
                end
                local import_path = interpolate(item.import)
                local imported_list = read_and_decode_imported_path(import_path)
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
    local file_content = fs_utils.read_file(run_config_path)
    if not file_content then
        if run_classification == "project" then
            if not M.config.fallback_project_run_config then
                print(
                    "[Pilot] Error: No project run configuration detected and no fallback configuration."
                )
                return
            end
            file_content = read_fallback_project_run_config()
            if not file_content then
                print(
                    "[Pilot] Error: No project run configuration detected and fallback returns nil."
                )
                return
            end
        else
            print(
                string.format(
                    "[Pilot] No detected run configuration for file type %s.",
                    vim.bo.filetype
                )
            )
            return
        end
    end

    local list = fs_utils.decode_json(file_content)
    if not list then
        error(
            string.format(
                "[Pilot] Error: Your %s run configuration has invalid JSON format or is empty.",
                run_classification
            )
        )
    end
    if type(list) ~= "table" then
        error(
            string.format(
                "[Pilot] Error: Your %s run configuration should contain JSON array, refer to the documentation for proper run configuration format.",
                run_classification
            )
        )
    end
    return parse_list_to_entries(list, run_config_path)
end

---@param config Config
function M.init(config)
    M.config = config
end

---@param run_config_path string
---@param run_classification RunClassification
function M.select_and_run_entry(run_config_path, run_classification)
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
        run_entry(entries[1])
    else
        for i, entry in ipairs(entries) do
            entries[i].name = i .. ". " .. entry.name
        end
        vim.ui.select(entries, {
            prompt = "Run a command for this "
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
                run_entry(chosen_entry)
            end
        end)
    end
end

function M.run_previous_task()
    if not M.last_executed_task then
        print("[Pilot] no previously executed task.")
        return
    end
    execute_task(M.last_executed_task)
end

return M
