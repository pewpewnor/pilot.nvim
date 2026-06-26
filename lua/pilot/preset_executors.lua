local common = require("pilot.common")

local M = {}

---@type Executor
function M.new_tab(command, args)
    if #args == 0 then
        common.cmd("tabnew | terminal " .. command)
    else
        common.cmd(args[1] .. "tabnew | terminal " .. command)
    end
end

---@type Executor
function M.current_buffer(command)
    common.cmd("terminal " .. command)
end

---@type Executor
function M.split(command, args)
    if #args == 0 then
        common.cmd("rightbelow split | terminal " .. command)
    else
        common.cmd(args[1] .. " split | terminal " .. command)
    end
end

---@type Executor
function M.vsplit(command, args)
    if #args == 0 then
        common.cmd("botright vsplit | terminal " .. command)
    else
        common.cmd(args[1] .. " vsplit | terminal " .. command)
    end
end

---@type Executor
function M.silent(command)
    common.run_shell_silent(command)
end

---@type Executor
function M.print(command)
    print(common.run_shell_output(command))
end

---@type Executor
function M.background_silent(command)
    common.run_shell_async(command)
end

---@type Executor
function M.background_exit_status(command)
    common.run_shell_async(command, function(result)
        print(
            result.code == 0 and "pilot.nvim: command job success (exit code 0)"
                or "pilot.nvim: command job error (exit code 1)"
        )
    end)
end

return M
