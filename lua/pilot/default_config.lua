local common = require("pilot.common")

local M = {
    preset_executors = {},
}

---@type Executor
function M.preset_executors.new_tab(command, args)
    if #args == 0 then
        common.run_cmd("tabnew | terminal " .. command)
    else
        common.run_cmd(args[1] .. "tabnew | terminal " .. command)
    end
end

---@type Executor
function M.preset_executors.current_buffer(command)
    common.run_cmd("terminal " .. command)
end

---@type Executor
function M.preset_executors.split(command, args)
    if #args == 0 then
        common.run_cmd("rightbelow split | terminal " .. command)
    else
        common.run_cmd(args[1] .. " split | terminal " .. command)
    end
end

---@type Executor
function M.preset_executors.vsplit(command, args)
    if #args == 0 then
        common.run_cmd("botright vsplit | terminal " .. command)
    else
        common.run_cmd(args[1] .. " vsplit | terminal " .. command)
    end
end

---@type Executor
function M.preset_executors.silent(command)
    common.run_shell_silent(command)
end

---@type Executor
function M.preset_executors.print(command)
    print(common.run_shell_output(command))
end

---@type Executor
function M.preset_executors.background_silent(command)
    common.run_shell_async(command)
end

---@type Executor
function M.preset_executors.background_exit_status(command)
    common.run_shell_async_on_exit(command, function(result)
        print(
            result.code == 0 and "pilot.nvim: command job success (exit code 0)"
                or "pilot.nvim: command job error (exit code 1)"
        )
    end)
end

---@class MinimumTarget
---@field pilot_file_path PilotFilepathResolver|PilotFilepathResolver[]

---@param minimum_target MinimumTarget
---@return Target
function M.fill_target(minimum_target)
    common.validate("minimum_target", minimum_target, "table")
    return common.tbl_deep_extend("force", {
        auto_run_single_command = true,
        default_executor = M.preset_executors.new_tab,
    }, minimum_target)
end

---@type Config
M.default_opts = {
    targets = {
        project = M.fill_target({
            pilot_file_path = function()
                return common.path_join(
                    "{{pilot_data_path}}",
                    "projects",
                    "{{hash_sha256(cwd_path)}}.json"
                )
            end,
        }),
        file_type = M.fill_target({
            pilot_file_path = function()
                return common.path_join(
                    "{{pilot_data_path}}",
                    "filetypes",
                    "{{file_type}}.json"
                )
            end,
        }),
    },
    write_template_to_new_pilot_file = true,
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
    placeholders = {
        vars = {
            file_path = function()
                return common.fnameescape(common.expand("%:p"))
            end,
            file_path_relative = function()
                return common.fnameescape(common.expand("%"))
            end,
            file_name = function()
                return common.fnameescape(common.expand("%:t"))
            end,
            file_name_no_extension = function()
                return common.fnameescape(common.expand("%:t:r"))
            end,
            file_type = function()
                return common.get_filetype()
            end,
            file_extension = function()
                return common.fnameescape(common.expand("%:e"))
            end,
            dir_path = function()
                return common.fnameescape(common.expand("%:p:h"))
            end,
            dir_name = function()
                return common.fnameescape(common.expand("%:p:h:t"))
            end,
            cwd_path = function()
                return common.get_cwd()
            end,
            cwd_name = function()
                return common.fnameescape(
                    common.path_modify(common.get_cwd_raw(), ":t")
                )
            end,
            config_path = function()
                return common.fnameescape(common.get_stdpath("config"))
            end,
            data_path = function()
                return common.fnameescape(common.get_stdpath("data"))
            end,
            pilot_data_path = function()
                local pilot_data_path =
                    common.path_join(common.get_stdpath("data"), "pilot")
                common.mkdir_with_parents(pilot_data_path)
                return common.fnameescape(pilot_data_path)
            end,
            cword = function()
                return common.expand("<cword>")
            end,
            cWORD = function()
                return common.expand("<cWORD>")
            end,
        },
        funcs = {
            hash_sha256 = function(arg)
                return common.sha256(arg)
            end,
        },
    },
    display = {
        numbered = true,
        last_entry_new_line = false,
    },
}

return M
