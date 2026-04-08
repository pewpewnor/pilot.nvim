local pathfinder = require("pilot.pathfinder")
local runner = require("pilot.runner")
local common = require("pilot.common")

local M = {}

---@param config Config
function M.init(config)
    M.config = config
    pathfinder.init(config)
    require("pilot.interpolation").init(config)
    require("pilot.parser").init(config)
    runner.init(config)
end

---@param run_class_name string
local function find_run_class(run_class_name)
    if type(run_class_name) ~= "string" then
        error("[Pilot] Given run class name must be a string.")
    end
    local run_class = M.config.run_classes[run_class_name]
    if not run_class then
        error(
            string.format(
                "[Pilot] Chosen run class '%s' doesn't exist.",
                run_class_name
            )
        )
    end
    return run_class
end

---@param run_class_name string
function M.run(run_class_name)
    local run_class = find_run_class(run_class_name)
    runner.select_and_run_entry({
        name = run_class_name,
        path = pathfinder.get_true_path(run_class.run_config_path),
        auto_run_single_command = run_class.auto_run_single_command,
        default_executor = run_class.default_executor,
    })
end

M.run_previous_task = runner.run_previous_task

---@param run_class_name string
function M.edit_run_config(run_class_name)
    local path =
        pathfinder.get_true_path(find_run_class(run_class_name).run_config_path)
    if
        M.config.write_template_to_new_run_config
        and not common.is_file_and_readable(path)
    then
        vim.fn.writefile({
            "[",
            "    {",
            '        "name": "put name of command here",',
            '        "command": "echo \'Hello, World!\'"',
            "    }",
            "]",
        }, path, "a")
    end
    vim.cmd("tabedit " .. path)
end

---@param run_class_name string
function M.delete_run_config(run_class_name)
    local path =
        pathfinder.get_true_path(find_run_class(run_class_name).run_config_path)
    vim.fs.rm(path, { force = true })
end

return M
