local fs_utils = require("pilot.fs_utils")
local pathfinder = require("pilot.pathfinder")
local runner = require("pilot.runner")

local M = {}

---@param config Config
M.init = function(config)
    M.config = config
    pathfinder.init(config)
    runner.init(config, M.neovim_integrated_terminal_executor)
end

---@type LocationExecutor
M.neovim_integrated_terminal_executor = function(params)
    vim.cmd("tabnew | terminal " .. params.command)
end

M.run_project = function()
    runner.select_command_and_execute(
        pathfinder.get_project_run_file_path(),
        "project"
    )
end

M.run_file_type = function()
    runner.select_command_and_execute(
        pathfinder.get_file_type_run_file_path(),
        "file type"
    )
end

M.run_last_executed_task = runner.run_last_executed_task

M.edit_project_run_config = function()
    vim.cmd("tabedit " .. pathfinder.get_project_run_file_path())
end

M.edit_file_type_run_config = function()
    vim.cmd("tabedit " .. pathfinder.get_file_type_run_file_path())
end

M.remove_project_run_config = function()
    fs_utils.rm(pathfinder.get_project_run_file_path())
end

M.remove_file_type_run_config = function()
    fs_utils.rm(pathfinder.get_file_type_run_file_path())
end

return M
