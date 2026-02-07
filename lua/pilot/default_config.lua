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
M.default_opts = {
    run_config_path = {
        project = vim.fs.joinpath(
            "{{pilot_data_path}}",
            "projects",
            "{{hash_sha256(cwd_path)}}.json"
        ),
        file_type = vim.fs.joinpath(
            "{{pilot_data_path}}",
            "filetypes",
            "{{file_type}}.json"
        ),
        fallback_project = nil,
    },
    write_template_to_new_run_config = true,
    auto_run_single_command = {
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
}

return M
