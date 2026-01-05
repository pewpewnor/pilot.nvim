---@alias FallbackProjectRunConfig fun(): string

---@alias Executor fun(command: string, args: [string]?)

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

---@class AdditionalPlaceholders
---@field [string] string

---@class Config
---@field run_config_path RunConfigPath
---@field write_template_to_new_run_config boolean
---@field automatically_run_single_command AutomaticallyRunSingleCommand
---@field default_executor DefaultExecutor
---@field executors Executors
---@field custom_placeholders AdditionalPlaceholders

local module = require("pilot.module")

local M = {
    preset_executors = {},
}

---@type Executor
function M.preset_executors.new_tab(command, args)
    if #args == 0 then
        vim.cmd("tabnew | terminal " .. command)
    else
        vim.cmd(args[1] .. "tabnew | terminal " .. command)
    end
end

---@type Executor
function M.preset_executors.current_buffer(command)
    vim.cmd("terminal " .. command)
end

---@type Executor
function M.preset_executors.split(command, args)
    if #args == 0 then
        vim.cmd("rightbelow split | terminal " .. command)
    else
        vim.cmd(args[1] .. " split | terminal " .. command)
    end
end

---@type Executor
function M.preset_executors.vsplit(command, args)
    if #args == 0 then
        vim.cmd("botright vsplit | terminal " .. command)
    else
        vim.cmd(args[1] .. " vsplit | terminal " .. command)
    end
end

---@type Executor
function M.preset_executors.silent(command)
    vim.fn.system(command)
end

---@type Executor
function M.preset_executors.print(command)
    print(vim.fn.system(command))
end

---@type Executor
function M.preset_executors.background_silent(command)
    vim.fn.jobstart(command)
end

---@type Executor
function M.preset_executors.background_exit_status(command)
    vim.fn.jobstart(command, {
        ---@diagnostic disable-next-line: unused-local
        on_exit = function(job_id, exit_code, event)
            print(
                exit_code == 0 and "[Pilot] Command job success (exit code 0)"
                    or "[Pilot] Command job error (exit code 1)"
            )
        end,
    })
end

---@type Config
M.config = {
    run_config_path = {
        project = "{{pilot_data_path}}/projects/{{hash(cwd_path)}}.json",
        file_type = "{{pilot_data_path}}/filetypes/{{file_type}}.json",
        fallback_project = nil,
    },
    write_template_to_new_run_config = true,
    automatically_run_single_command = {
        project = true,
        file_type = true,
    },
    default_executor = {
        project = M.preset_executors.new_tab,
        file_type = M.preset_executors.new_tab,
    },
    executors = {
        new_tab = M.preset_executors.new_tab,
        current_buffer = M.preset_executors.current_buffer,
        split = M.preset_executors.split,
        vsplit = M.preset_executors.vsplit,
        print = M.preset_executors.print,
        silent = M.preset_executors.silent,
        background_silent = M.preset_executors.background_silent,
        background_exit_status = M.preset_executors.background_exit_status,
    },
    custom_placeholders = {},
}

---@param options table?
function M.setup(options)
    M.config = vim.tbl_deep_extend("force", M.config, options or {})
    require("validate_opts")(M.config)
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
