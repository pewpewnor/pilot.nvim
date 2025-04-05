local fs_utils = require("pilot.fs_utils")
local pathfinder = require("pilot.pathfinder")
local runner = require("pilot.runner")

local M = {}

---@param config Config
M.init = function(config)
    M.config = config
    pathfinder.init(config)
    runner.init(config)
end

M.run_project = function()
    runner.select_command_and_execute(
        pathfinder.get_project_run_config_path(),
        "project"
    )
end

M.run_file_type = function()
    runner.select_command_and_execute(
        pathfinder.get_file_type_run_config_path(),
        "file type"
    )
end

M.run_last_executed_task = runner.run_last_executed_task

M.edit_project_run_config = function()
    vim.cmd(
        "tabedit "
            .. vim.fn.fnameescape(pathfinder.get_project_run_config_path())
    )
end

M.edit_file_type_run_config = function()
    vim.cmd(
        "tabedit "
            .. vim.fn.fnameescape(pathfinder.get_file_type_run_config_path())
    )
end

M.delete_project_run_config = function()
    vim.fs.rm(pathfinder.get_project_run_config_path(), { force = true })
end

M.delete_file_type_run_config = function()
    vim.fs.rm(pathfinder.get_file_type_run_config_path(), { force = true })
end

return M
