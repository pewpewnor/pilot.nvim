local common = require("pilot.common")
local preset_executors = require("pilot.preset_executors")

local M = {
    preset_executors = preset_executors,
}

---@param minimum_target pilot.MinimumTarget
---@return pilot.Target
function M.fill_target(minimum_target)
    common.validate("minimum_target", minimum_target, "table")
    return common.tbl_deep_extend("force", {
        auto_run_single_command = true,
        default_executor = M.preset_executors.new_tab,
    }, minimum_target)
end

---@type pilot.Config
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
        filetype = M.fill_target({
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
        bg_silent = M.preset_executors.bg_silent,
        bg_exit_status = M.preset_executors.bg_exit_status,
    },
    placeholders = {
        vars = {
            file_path = function()
                return common.expand("%:p")
            end,
            file_path_relative = function()
                return common.expand("%")
            end,
            file_name = function()
                return common.expand("%:t")
            end,
            file_name_no_extension = function()
                return common.expand("%:t:r")
            end,
            file_type = function()
                return common.get_filetype()
            end,
            file_extension = function()
                return common.expand("%:e")
            end,
            dir_path = function()
                return common.expand("%:p:h")
            end,
            dir_name = function()
                return common.expand("%:p:h:t")
            end,
            cwd_path = function()
                return common.get_cwd()
            end,
            cwd_name = function()
                return common.fnamemodify(common.get_cwd(), ":t")
            end,
            config_path = function()
                return common.get_stdpath("config")
            end,
            data_path = function()
                return common.get_stdpath("data")
            end,
            pilot_data_path = function()
                local pilot_data_path =
                    common.path_join(common.get_stdpath("data"), "pilot")
                common.mkdir_with_parents(pilot_data_path)
                return pilot_data_path
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
                return common.hash_sha256(arg)
            end,
        },
    },
    display = {
        numbered = true,
        last_entry_new_line = false,
    },
}

return M
