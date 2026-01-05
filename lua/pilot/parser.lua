---@alias RunClassification "project"|"file type"

---@class RawEntryTable
---@field name string?
---@field command string?
---@field import string?
---@field executor string?

---@alias RawEntry RawEntryTable|string

---@class ProcessedEntry
---@field name string
---@field command string
---@field executor string?

local fs_utils = require("pilot.fs_utils")
local interpolate = require("pilot.interpolation")

local M = {}

---@param config Config
function M.init(config)
    M.config = config
end

---@return string?
local function read_fallback_project_run_config()
    local fallback_project_run_config =
        M.config.run_config_path.fallback_project()
    if not fallback_project_run_config then
        return nil
    end
    if type(fallback_project_run_config) ~= "string" then
        error(
            "[Pilot] 'fallback_project_run_config' must return a string or nil."
        )
    end

    local fallback_path = interpolate(fallback_project_run_config)
    local file_content = fs_utils.read_file(fallback_path)
    if not file_content then
        error(
            string.format(
                "[Pilot] Failed to read fallback project run configuration at '%s'.",
                fallback_path
            )
        )
    end
    return file_content
end

---@param command string
---@param name string?
---@param executor string?
---@return ProcessedEntry
local function create_processed_entry(command, name, executor)
    return {
        name = name or command,
        command = command,
        executor = executor,
    }
end

---@param import_path string
---@return [RawEntry]
local function read_and_decode_imported_path(import_path)
    local file_content = fs_utils.read_file(import_path)
    if not file_content then
        error(
            string.format(
                "[Pilot] Imported file '%s' doesn't exist",
                import_path
            )
        )
    end

    ---@type table?
    local imported_list = fs_utils.decode_json(file_content)

    if not imported_list then
        error(
            string.format(
                "[Pilot] Imported file '%s' has invalid JSON format or is empty.",
                import_path
            )
        )
    end
    if type(imported_list) ~= "table" then
        error(
            string.format(
                "[Pilot] Imported file '%s' should contain JSON array, refer to the documentation for proper run configuration format.",
                import_path
            )
        )
    end
    return imported_list
end

---@param list [RawEntry]
---@param run_config_path string
---@return [ProcessedEntry]
local function parse_list_to_entries(list, run_config_path)
    if type(list) ~= "table" then
        error(
            string.format(
                "[Pilot] Run configuration must be a valid JSON array in '%s'.",
                run_config_path
            )
        )
    end

    local processed_entries = {}

    for _, item in ipairs(list) do
        local item_type = type(item)
        if item_type ~= "table" and item_type ~= "string" then
            error(
                string.format(
                    "[Pilot] Each entry must be a valid JSON object or string in '%s'.",
                    run_config_path
                )
            )
        end

        if item_type == "string" then
            table.insert(processed_entries, create_processed_entry(item))
        else
            if not item.command and not item.import then
                error(
                    string.format(
                        "[Pilot] Each entry must either have a 'command' or an 'import' attribute in '%s'.",
                        run_config_path
                    )
                )
            end
            if item.command and item.import then
                error(
                    string.format(
                        "[Pilot] Each entry cannot have both the 'command' and 'import' attribute simultaneously in '%s'.",
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
                table.insert(
                    processed_entries,
                    create_processed_entry(
                        item.command,
                        item.name,
                        item.executor
                    )
                )
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
                for _, imported_entry in ipairs(imported_entries) do
                    table.insert(processed_entries, imported_entry)
                end
            end
        end
    end
    return processed_entries
end

---@param run_config_path string
---@param run_classification RunClassification
---@return [ProcessedEntry]?
function M.parse_run_config(run_config_path, run_classification)
    local file_content = fs_utils.read_file(run_config_path)
    if not file_content then
        if run_classification == "project" then
            if not M.config.run_config_path.fallback_project then
                print(
                    "[Pilot] No project run configuration detected and no fallback configured."
                )
                return nil
            end
            file_content = read_fallback_project_run_config()
            if not file_content then
                print(
                    "[Pilot] No project run configuration detected and fallback returns nil."
                )
                return nil
            end
        else
            print(
                string.format(
                    "[Pilot] No detected run configuration for file type %s.",
                    vim.bo.filetype
                )
            )
            return nil
        end
    end

    ---@type table?
    local list = fs_utils.decode_json(file_content)

    if not list then
        error(
            string.format(
                "[Pilot] Your %s run configuration has invalid JSON format or is empty.",
                run_classification
            )
        )
    end
    if type(list) ~= "table" then
        error(
            string.format(
                "[Pilot] Your %s run configuration should contain JSON array, refer to the documentation for proper run configuration format.",
                run_classification
            )
        )
    end
    return parse_list_to_entries(list, run_config_path)
end

return M
