---@diagnostic disable-next-line: lowercase-global
fs_utils = require("utils.fs_utils")
local interpolate_command = require("interpolation")
local pathfinder = require("pathfinder")

---@class MyModule
local M = {}
local last_executed_task = nil

local function execute_task(entry, init_commands, given_executor)
    local options = {
        name = entry.name,
        command = interpolate_command(entry.command),
        init_command = interpolate_command(table.concat(init_commands, " && ")),
    }

    if given_executor ~= nil then
        given_executor(options)
    elseif entry.location == nil then
        if enumerated_location ~= nil then
            local executor = enumerated_location.executor
            executor(options)
            last_executed_task = {
                entry = entry,
                init_commands = init_commands,
                executor = executor,
            }
        end
    else
        local executor = get_executor_from_preset(entry.location)
        if executor == nil then
            executor = get_executor_from_pattern_matching(entry.location)
        end
        if executor == nil then
            executor = retrieve_location_executor(entry.location)
        end
        executor(options)
        last_executed_task = {
            entry = entry,
            init_commands = init_commands,
            executor = executor,
        }
    end
end

local function parse_config_file(config_file_path, config_file_type)
    local file_content = file_utils.read_file_to_string(config_file_path)
    if file_content == nil then
        if config_file_type == "project" and config.fallback_project_config_file ~= nil then
            if type(config.fallback_project_config_file) ~= "function" then
                error("[pilot] the fallback project config file configuration must be set to a function")
            end
            local fallback_config_file = config.fallback_project_config_file()
            if fallback_config_file == nil then
                print("[pilot] no project and fallback config file given")
                return
            elseif type(fallback_config_file) ~= "string" then
                error("[pilot] the fallback project config file configuration must return a string or nil")
            end

            file_content = file_utils.read_file_to_string(get_pilot_dirpath() .. "/" .. fallback_config_file)
            if file_content == nil then
                error(
                    "[pilot] error while reading the fallback project config file at '"
                        .. get_pilot_dirpath()
                        .. "/"
                        .. fallback_config_file
                        .. "', does it exist? no read permission?"
                )
            end
        else
            print("[pilot] no config file detected, please create one first")
            return
        end
    end

    local entries = vim.fn.json_decode(file_content)
    if type(entries) ~= "table" then
        error("[pilot] " .. config_file_type .. " config file must be a valid JSON list/array")
    end

    local enumerated_entries = {}
    local init_commands = {}

    for _, entry in ipairs(entries) do
        if type(entry) ~= "table" then
            error(
                "[pilot] each entry in the "
                    .. config_file_type
                    .. " config file's list must be a JSON map/object/table"
            )
        end
        if type(entry.command) ~= "string" and type(entry.import) ~= "string" then
            error(
                "[pilot] missing/invalid attribute 'command' or 'import' for one of the entries in the "
                    .. config_file_type
                    .. " config file's list"
            )
        end
        if type(entry.command) == "string" and type(entry.import) == "string" then
            error(
                "[pilot] attribute 'command' and 'import' cannot coexist for one of the entries in the "
                    .. config_file_type
                    .. " config file's list"
            )
        end

        if type(entry.command) == "string" then
            if entry.name == "__init__" then
                table.insert(init_commands, entry.command)
            else
                if entry.name == nil then
                    entry.name = entry.command
                end
                table.insert(enumerated_entries, { index = #enumerated_entries + 1, entry = entry })
            end
        else
            local imported_enumerated_entries, imported_init_commands =
                parse_config_file(get_pilot_dirpath() .. "/" .. entry.import, false)
            if imported_enumerated_entries == nil or imported_init_commands == nil then
                return
            end

            for _, imported_enumerated_entry in ipairs(imported_enumerated_entries) do
                local unique = true
                for _, enumerated_entry in ipairs(enumerated_entries) do
                    if enumerated_entry.entry.name == imported_enumerated_entry.entry.name then
                        unique = false
                        break
                    end
                end
                if unique then
                    table.insert(enumerated_entries, {
                        index = #enumerated_entries + 1,
                        entry = imported_enumerated_entry.entry,
                    })
                end
            end

            -- TODO: add type validation
            if entry.include_init_command ~= false then
                table_utils.add_all(init_commands, imported_init_commands)
            end
        end
    end

    return enumerated_entries, init_commands
end

-- TODO: add a "project" or a "file_type" for the prompt + error messages
local function parse_select_and_execute(config_file_path, config_file_type)
    local enumerated_entries, init_commands = parse_config_file(config_file_path, config_file_type)
    if enumerated_entries == nil then
        return
    end

    if config.run_immediately_when_only_one_command_is_available == true and #enumerated_entries == 1 then
        execute_task(enumerated_entries[1].entry, init_commands)
    else
        vim.ui.select(enumerated_entries, {
            prompt = "Select a " .. config_file_type .. " run command",
            format_item = function(enumerated_entry)
                return enumerated_entry.index .. ". " .. enumerated_entry.entry.name
            end,
        }, function(enumerated_entry)
            if enumerated_entry ~= nil then
                execute_task(enumerated_entry.entry, init_commands)
            end
        end)
    end
end

-- TODO:
-- use neovim's integrated terminal instead like keymap("n", "<Leader>t", "<Cmd>tabnew | terminal<CR>")
-- change the name 'location' to 'location' instead
-- check if file is readable and writeable using vim.fn
-- validate all configs options from user before moving on with the rest of the code

---@class Config
---@field local_project_config_dir string? Your config option
---@field run_immediately_when_only_one_command_is_available boolean Your config option
---@field fallback_project_config_file function? Your config option
---@field additional_locations table? Your config option
local config = {
    local_project_config_dir = nil,
    run_immediately_when_only_one_command_is_available = false,
    fallback_project_config_file = nil,
    additional_locations = nil,
}

---@type Config
M.config = config

---@param options Config?
M.setup = function(options)
    M.config = vim.tbl_deep_extend("force", M.config, options or {})
    local validate_config = require("validation")
    validate_config(M.config)
end

M.run_project = function()
    parse_select_and_execute(pathfinder.get_project_config_file_path(), "project")
end

M.run_file_type = function()
    parse_select_and_execute(pathfinder.get_file_type_config_file_path(), "file_type")
end

M.run_last_execution_task = function()
    if last_executed_task == nil then
        print("[pilot] there are no previously executed task to be executed again")
        return
    end
    execute_task(last_executed_task.entry, last_executed_task.init_commands, last_executed_task.executor)
end

M.edit_project_config_file = function()
    vim.cmd("tabedit " .. pathfinder.get_project_config_file_path())
end

M.edit_file_type_config_file = function()
    vim.cmd("tabedit " .. pathfinder.get_file_type_config_file_path())
end

M.remove_current_project_config = function()
    file_utils.rm(pathfinder.get_project_config_file_path())
end

M.remove_current_file_type_config = function()
    file_utils.rm(pathfinder.get_file_type_config_file_path())
end

return M
