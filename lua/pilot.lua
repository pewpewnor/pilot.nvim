---@alias FallbackProjectRunConfig fun(): string

---@alias Executor fun(command: string, args: [string]?)

---@alias PlaceholderVar fun(): string

---@alias PlaceholderFunc fun(arg: string): string

---@alias AdditionalPlaceholder fun(placeholder: string): string?

---@class RunConfigPath
---@field project string|[string]
---@field file_type string
---@field fallback_project FallbackProjectRunConfig?

---@class AutomaticallyRunSingleCommand
---@field project boolean
---@field file_type boolean

---@class DefaultExecutor
---@field project Executor
---@field file_type Executor

---@class Executors
---@field [string] Executor

---@class PlaceholderVars
---@field [string] PlaceholderVar

---@class PlaceholderFuncs
---@field [string] PlaceholderFunc

---@class Placeholders
---@field vars PlaceholderVars
---@field funcs PlaceholderFuncs

---@class Config
---@field run_config_path RunConfigPath
---@field write_template_to_new_run_config boolean
---@field automatically_run_single_command AutomaticallyRunSingleCommand
---@field default_executor DefaultExecutor
---@field executors Executors
---@field placeholders Placeholders

local default_config = require("pilot.default_config")
local module = require("pilot.module")
local validate_opts = require("pilot.validate_opts")
local interpolation = require("pilot.interpolation")

local M = {
    preset_executors = default_config.preset_executors,
    utils = {
        interpolate = interpolation.interpolate,
    },
}

---@param options table?
function M.setup(options)
    M.config =
        vim.tbl_deep_extend("force", default_config.default_opts, options or {})
    validate_opts(M.config)
    module.init(M.config)
end

M.run_project = module.run_project

M.run_file_type = module.run_file_type

M.run_previous_task = module.run_previous_task

M.edit_project_run_config = module.edit_project_run_config

M.edit_file_type_run_config = module.edit_file_type_run_config

M.delete_project_run_config = module.delete_project_run_config

M.delete_file_type_run_config = module.delete_file_type_run_config

M.purge_all_default_project_run_config_dir =
    module.purge_all_default_project_run_config_dir

M.purge_all_default_project_run_config_dir =
    module.purge_all_default_file_type_run_config_dir

return M
