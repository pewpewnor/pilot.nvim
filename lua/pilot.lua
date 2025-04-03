---@alias Executor fun(command: string)

---@class AutomaticallyRunSingleCommand
---@field project boolean
---@field file_type boolean

---@alias FallbackProjectRunConfig fun(): string

---@class CustomLocations
---@field [string] Executor

---@class Config
---@field local_project_config_dir string?
---@field automatically_run_single_command AutomaticallyRunSingleCommand
---@field fallback_project_run_config FallbackProjectRunConfig?
---@field custom_locations CustomLocations?
---@field default_executor Executor

local module = require("pilot.module")

local M = {}

---@type Executor
M.neovim_integrated_terminal_current_buffer_executor = function(command)
    vim.cmd("terminal " .. command)
end

---@type Executor
M.neovim_integrated_terminal_new_tab_executor = function(command)
    vim.cmd("tabnew | terminal " .. command)
end

---@type Config
M.config = {
    local_project_config_dir = nil,
    automatically_run_single_command = {
        project = true,
        file_type = true,
    },
    fallback_project_run_config = nil,
    custom_locations = nil,
    default_executor = M.neovim_integrated_terminal_new_tab_executor,
}

---@param options Config
local function validate_config(options)
    if options ~= nil and type(options) ~= "table" then
        error("[Pilot] given configuration must be a table or nil")
    end

    if
        options.local_project_config_dir ~= nil
        and type(options.local_project_config_dir) ~= "string"
    then
        error(
            "[Pilot] option 'local_project_config_dir' must either be a string or nil."
        )
    end

    if type(options.automatically_run_single_command) ~= "table" then
        error(
            "[Pilot] option 'automatically_run_single_command' must be a table."
        )
    end
    if type(options.automatically_run_single_command.project) ~= "boolean" then
        error(
            "[Pilot] option 'automatically_run_single_command.project' must be a boolean."
        )
    end
    if
        type(options.automatically_run_single_command.file_type) ~= "boolean"
    then
        error(
            "[Pilot] option 'automatically_run_single_command.file_type' must be a boolean."
        )
    end

    if
        options.fallback_project_run_config ~= nil
        and type(options.fallback_project_run_config) ~= "function"
    then
        error(
            "[Pilot] option 'fallback_project_run_config' must be a function or nil."
        )
    end

    if
        options.custom_locations ~= nil
        and type(options.custom_locations) ~= "table"
    then
        error("[Pilot] option 'custom_locations' must be a table or nil.")
    end

    if type(options.default_executor) ~= "function" then
        error("[Pilot] option 'default_executor' must be a function.")
    end
end

---@param options table?
M.setup = function(options)
    M.config = vim.tbl_deep_extend("force", M.config, options or {})
    validate_config(M.config)
    module.init(M.config)
end

M.run_project = module.run_project

M.run_file_type = module.run_file_type

M.run_last_executed_task = module.run_last_executed_task

M.edit_project_run_config = module.edit_project_run_config

M.edit_file_type_run_config = module.edit_file_type_run_config

M.delete_project_run_config = module.delete_project_run_config

M.delete_file_type_run_config = module.delete_file_type_run_config

return M
