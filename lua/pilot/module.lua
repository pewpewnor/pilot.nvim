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

---@param target_name string
local function find_target(target_name)
    common.validate("target_name", target_name, "string")
    local target = M.config.targets[target_name]
    if not target then
        error(
            string.format(
                "pilot.nvim: target '%s' does not exist",
                target_name
            )
        )
    end
    return target
end

---@param target_name string
---@return any
function M.run_target(target_name)
    local target = find_target(target_name)
    return runner.select_and_run_entry({
        name = target_name,
        path = pathfinder.get_true_path(target.pilot_file_path),
        auto_run_single_command = target.auto_run_single_command,
        default_executor = target.default_executor,
    })
end

M.run_previous_task = runner.run_previous_task

---@param target_name string
function M.edit_pilot_file(target_name)
    local path =
        pathfinder.get_true_path(find_target(target_name).pilot_file_path)
    if
        M.config.write_template_to_new_pilot_file
        and not common.is_file_and_readable(path)
    then
        common.write_file(path, {
            "[",
            "    {",
            '        "name": "put name of command here",',
            '        "command": "echo \'Hello, World!\'"',
            "    }",
            "]",
        }, "a")
    end
    common.run_cmd("tabedit " .. path)
end

---@param target_name string
function M.delete_pilot_file(target_name)
    local path =
        pathfinder.get_true_path(find_target(target_name).pilot_file_path)
    common.path_remove(path)
end

return M
