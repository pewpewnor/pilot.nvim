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

local interpolation = require("pilot.interpolation")
local common = require("pilot.common")

local M = {}

---@param config Config
function M.init(config)
    M.config = config
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
---@return RawEntry[]
local function read_and_decode_imported_path(import_path)
    local file_content = common.read_file(import_path)
    if not file_content then
        error(
            string.format(
                "pilot.nvim: imported file '%s' does not exist",
                import_path
            )
        )
    end

    ---@type table?
    local imported_list = common.decode_json(file_content)

    if not imported_list then
        error(
            string.format(
                "pilot.nvim: imported file '%s' has invalid JSON format or is empty",
                import_path
            )
        )
    end
    if type(imported_list) ~= "table" then
        error(
            string.format(
                "pilot.nvim: imported file '%s' must contain a JSON array, refer to the documentation for the proper pilot file format",
                import_path
            )
        )
    end
    return imported_list
end

---@param list RawEntry[]
---@param pilot_file_path string
---@return ProcessedEntry[]
local function parse_list_to_entries(list, pilot_file_path)
    if type(list) ~= "table" then
        error(
            string.format(
                "pilot.nvim: pilot file must be a valid JSON array in '%s'",
                pilot_file_path
            )
        )
    end

    local processed_entries = {}

    for _, item in ipairs(list) do
        local item_type = type(item)
        if item_type ~= "table" and item_type ~= "string" then
            error(
                string.format(
                    "pilot.nvim: each entry must be a valid JSON object or string in '%s'",
                    pilot_file_path
                )
            )
        end

        if item_type == "string" then
            table.insert(processed_entries, create_processed_entry(item))
        else
            if not item.command and not item.import then
                error(
                    string.format(
                        "pilot.nvim: each entry must have either a 'command' or an 'import' attribute in '%s'",
                        pilot_file_path
                    )
                )
            end
            if item.command and item.import then
                error(
                    string.format(
                        "pilot.nvim: each entry cannot have both 'command' and 'import' attributes simultaneously in '%s'",
                        pilot_file_path
                    )
                )
            end

            if item.command then
                if type(item.command) == "table" then
                    ---@diagnostic disable-next-line: param-type-mismatch
                    item.command = table.concat(item.command, " && ")
                elseif type(item.command) ~= "string" then
                    error(
                        "pilot.nvim: command must be a string or a list of strings"
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
                        "pilot.nvim: import must be a string that resolves to a file path"
                    )
                end

                local import_path = interpolation.interpolate(item.import)
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

---@param path string
---@param target_name string
---@return ProcessedEntry[]?
function M.parse_pilot_file(path, target_name)
    local file_content = common.read_file(path)
    if not file_content then
        print(
            "pilot.nvim: no suitable pilot file found, all paths do not exist or are unreadable"
        )
        return nil
    end

    ---@type table?
    local list = common.decode_json(file_content)

    if not list then
        error(
            string.format(
                "pilot.nvim: pilot file for '%s' has invalid JSON format or is empty",
                target_name
            )
        )
    end
    if type(list) ~= "table" then
        error(
            string.format(
                "pilot.nvim: pilot file for '%s' must contain a JSON array, refer to the documentation for the proper pilot file format",
                target_name
            )
        )
    end
    return parse_list_to_entries(list, path)
end

return M
