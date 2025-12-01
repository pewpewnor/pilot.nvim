---@alias FallbackProjectRunConfig fun(): string

---@class AutomaticallyRunSingleCommand
---@field project boolean
---@field file_type boolean

---@alias Executor fun(command: string, args: [string]?)

---@class DefaultExecutor
---@field project Executor
---@field file_type Executor

---@class CustomLocations
---@field [string] Executor

---@class Config
---@field project_run_config_path string?
---@field file_type_run_config_path string?
---@field fallback_project_run_config FallbackProjectRunConfig?
---@field write_template_to_new_run_config boolean
---@field automatically_run_single_command AutomaticallyRunSingleCommand
---@field default_executor DefaultExecutor
---@field custom_locations CustomLocations?

local module = require("pilot.module")

local M = {
    executors = {},
}

---@param options Config
local function validate_config(options)
    if type(options) ~= "table" and options ~= nil then
        error("[Pilot] given configuration must be a table or nil")
    elseif
        type(options.project_run_config_path) ~= "string"
        and options.project_run_config_path ~= nil
    then
        error(
            "[Pilot] option 'project_run_config_path' must either be a string or nil."
        )
    elseif
        type(options.file_type_run_config_path) ~= "string"
        and options.file_type_run_config_path ~= nil
    then
        error(
            "[Pilot] option 'file_type_run_config_path' must either be a string or nil."
        )
    elseif type(options.automatically_run_single_command) ~= "table" then
        error(
            "[Pilot] option 'automatically_run_single_command' must be a table."
        )
    elseif
        type(options.automatically_run_single_command.project) ~= "boolean"
    then
        error(
            "[Pilot] option 'automatically_run_single_command.project' must be a boolean."
        )
    elseif
        type(options.automatically_run_single_command.file_type) ~= "boolean"
    then
        error(
            "[Pilot] option 'automatically_run_single_command.file_type' must be a boolean."
        )
    elseif
        type(options.fallback_project_run_config) ~= "function"
        and options.fallback_project_run_config ~= nil
    then
        error(
            "[Pilot] option 'fallback_project_run_config' must be a function or nil."
        )
    elseif
        type(options.custom_locations) ~= "table"
        and options.custom_locations ~= nil
    then
        error("[Pilot] option 'custom_locations' must be a table or nil.")
    elseif type(options.default_executor) ~= "table" then
        error("[Pilot] option 'default_executor' must be a table.")
    elseif type(options.default_executor.project) ~= "function" then
        error("[Pilot] option 'default_executor.project' must be a function.")
    elseif type(options.default_executor.file_type) ~= "function" then
        error("[Pilot] option 'default_executor.file_type' must be a function.")
    end
end

---@type Executor
function M.executors.new_tab(command, args)
    if #args == 0 then
        vim.cmd("tabnew | terminal " .. command)
    else
        vim.cmd(args[1] .. "tabnew | terminal " .. command)
    end
end

---@type Executor
function M.executors.current_buffer(command)
    vim.cmd("terminal " .. command)
end

---@type Executor
function M.executors.split(command, args)
    if #args == 0 then
        vim.cmd("rightbelow split | terminal " .. command)
    else
        vim.cmd(args[1] .. " split | terminal " .. command)
    end
end

---@type Executor
function M.executors.vsplit(command, args)
    if #args == 0 then
        vim.cmd("botright vsplit | terminal " .. command)
    else
        vim.cmd(args[1] .. " vsplit | terminal " .. command)
    end
end

---@type Executor
function M.executors.print(command)
    print(vim.fn.system(command))
end

---@type Executor
function M.executors.silent(command)
    vim.fn.system(command)
end

---@type Config
M.config = {
    project_run_config_path = nil,
    file_types_run_config_path = nil,
    fallback_project_run_config = nil,
    write_template_to_new_run_config = true,
    automatically_run_single_command = {
        project = true,
        file_type = true,
    },
    default_executor = {
        project = M.executors.new_tab,
        file_type = M.executors.new_tab,
    },
    custom_locations = nil,
}

---@param options table?
function M.setup(options)
    M.config = vim.tbl_deep_extend("force", M.config, options or {})
    validate_config(M.config)
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
