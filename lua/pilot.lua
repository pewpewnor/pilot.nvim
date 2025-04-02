---@alias Executor fun(command: string)

---@class AutomaticallyRunSingleCommand
---@field project boolean
---@field file_type boolean

---@class CustomLocations
---@field [string] Executor

---@class Config
---@field local_project_config_dir string?
---@field automatically_run_single_command AutomaticallyRunSingleCommand
---@field fallback_project_run_config fun(): string
---@field custom_locations CustomLocations?

local module = require("pilot.module")

local M = {}

---@type Config
M.config = {
    local_project_config_dir = nil,
    automatically_run_single_command = {
        project = true,
        file_type = true,
    },
    fallback_project_run_config = nil,
    custom_locations = nil,
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

M.remove_project_run_config = module.remove_project_run_config

M.remove_file_type_run_config = module.remove_file_type_run_config

return M
