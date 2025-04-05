local pathfinder = require("pilot.pathfinder")
local runner = require("pilot.runner")

local M = {}

---@param run_config_path string
local function edit_run_config(run_config_path)
    if vim.fn.filereadable(run_config_path) == 0 then
        vim.fn.writefile({}, run_config_path, "a")
    end
    vim.cmd("tabedit " .. run_config_path)
end

---@param run_config_path string
local function delete_run_config(run_config_path)
    vim.fs.rm(run_config_path, { force = true })
end

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
    edit_run_config(pathfinder.get_project_run_config_path())
end

M.edit_file_type_run_config = function()
    edit_run_config(pathfinder.get_file_type_run_config_path())
end

M.delete_project_run_config = function()
    delete_run_config(pathfinder.get_project_run_config_path())
end

M.delete_file_type_run_config = function()
    delete_run_config(pathfinder.get_file_type_run_config_path())
end

return M
