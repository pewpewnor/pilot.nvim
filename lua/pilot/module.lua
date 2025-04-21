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

---@param run_config_dir_path string
local function purge_all_run_config_dir(run_config_dir_path)
    vim.fs.rm(run_config_dir_path, { recursive = true, force = true })
end

---@param config Config
function M.init(config)
    M.config = config
    pathfinder.init(config)
    runner.init(config)
end

function M.run_project()
    runner.select_and_run_entry(
        pathfinder.get_project_run_config_path(),
        "project"
    )
end

function M.run_file_type()
    runner.select_and_run_entry(
        pathfinder.get_file_type_run_config_path(),
        "file type"
    )
end

M.run_last_executed_task = runner.run_last_executed_task

function M.edit_project_run_config()
    edit_run_config(pathfinder.get_project_run_config_path(true))
end

function M.edit_file_type_run_config()
    edit_run_config(pathfinder.get_file_type_run_config_path(true))
end

function M.delete_project_run_config()
    delete_run_config(pathfinder.get_project_run_config_path())
end

function M.delete_file_type_run_config()
    delete_run_config(pathfinder.get_file_type_run_config_path())
end

function M.purge_all_default_project_run_config_dir()
    purge_all_run_config_dir(
        pathfinder.get_default_project_run_config_dir_path()
    )
end

function M.purge_all_default_file_type_run_config_dir()
    purge_all_run_config_dir(
        pathfinder.get_default_file_type_run_config_dir_path()
    )
end

return M
