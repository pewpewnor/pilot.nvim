local common = require("pilot.common")

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
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command }):wait()
end

---@type Executor
function M.preset_executors.print(command)
    local result =
        vim.system({ vim.o.shell, vim.o.shellcmdflag, command }, { text = true }):wait()
    print(result.stdout)
end

---@type Executor
function M.preset_executors.background_silent(command)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command })
end

---@type Executor
function M.preset_executors.background_exit_status(command)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command }, {}, function(result)
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
    vim.validate("minimum_target", minimum_target, "table")
    return vim.tbl_deep_extend("force", {
        auto_run_single_command = true,
        default_executor = M.preset_executors.new_tab,
    }, minimum_target)
end

---@type Config
M.default_opts = {
    targets = {
        project = M.fill_target({
            pilot_file_path = function()
                return vim.fs.joinpath(
                    "{{pilot_data_path}}",
                    "projects",
                    "{{hash_sha256(cwd_path)}}.json"
                )
            end,
        }),
        file_type = M.fill_target({
            pilot_file_path = function()
                return vim.fs.joinpath(
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
                return vim.fn.fnameescape(vim.fn.expand("%:p"))
            end,
            file_path_relative = function()
                return vim.fn.fnameescape(vim.fn.expand("%"))
            end,
            file_name = function()
                return vim.fn.fnameescape(vim.fn.expand("%:t"))
            end,
            file_name_no_extension = function()
                return vim.fn.fnameescape(vim.fn.expand("%:t:r"))
            end,
            file_type = function()
                return vim.bo.filetype
            end,
            file_extension = function()
                return vim.fn.fnameescape(vim.fn.expand("%:e"))
            end,
            dir_path = function()
                return vim.fn.fnameescape(vim.fn.expand("%:p:h"))
            end,
            dir_name = function()
                return vim.fn.fnameescape(vim.fn.expand("%:p:h:t"))
            end,
            cwd_path = function()
                return vim.fn.fnameescape(vim.fn.getcwd())
            end,
            cwd_name = function()
                return vim.fn.fnameescape(
                    vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
                )
            end,
            config_path = function()
                return vim.fn.fnameescape(vim.fn.stdpath("config"))
            end,
            data_path = function()
                return vim.fn.fnameescape(vim.fn.stdpath("data"))
            end,
            pilot_data_path = function()
                local pilot_data_path =
                    vim.fs.joinpath(vim.fn.stdpath("data"), "pilot")
                common.mkdir_with_parents(pilot_data_path)
                return vim.fn.fnameescape(pilot_data_path)
            end,
            cword = function()
                return vim.fn.expand("<cword>")
            end,
            cWORD = function()
                return vim.fn.expand("<cWORD>")
            end,
        },
        funcs = {
            hash_sha256 = function(arg)
                return vim.fn.sha256(arg)
            end,
        },
    },
    display = {
        numbered = true,
        last_entry_new_line = false,
    },
}

return M
