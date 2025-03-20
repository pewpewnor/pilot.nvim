---@alias LocationExecutor fun(params: ExecutorParams)

---@class AutomaticallyRunSingleCommand
---@field project boolean
---@field file_type boolean

---@alias FallbackProjectRunFile fun(): string

---@class CustomLocations
---@field [string] LocationExecutor

---@class Config
---@field local_project_config_dir string?
---@field automatically_run_single_command AutomaticallyRunSingleCommand
---@field fallback_project_run_config FallbackProjectRunFile?
---@field custom_locations CustomLocations?

local module = require("pilot.module")

local M = {}

---@type Config
M.config = {
    local_project_config_dir = nil,
    automatically_run_single_command = {
        project = false,
        file_type = false,
    },
    fallback_project_run_config = nil,
    custom_locations = nil,
}

---@param options Config
M.setup = function(options)
    M.config = vim.tbl_deep_extend("force", M.config, options or {})
    require("validate")(M.config)
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
