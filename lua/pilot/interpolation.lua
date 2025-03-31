local pathfinder = require("pilot.pathfinder")
local string_utils = require("pilot.string_utils")

---@return string
local function get_current_file_name()
    return vim.fn.fnameescape(vim.fn.expand("%:t"))
end

---@return string
local function get_current_working_dir_path()
    return vim.fn.fnameescape(vim.fn.getcwd())
end

---@param placeholder string
---@return string
local function resolve_command_placeholder(placeholder)
    if placeholder == "file_path" then
        return vim.fn.fnameescape(vim.fn.expand("%:p"))
    elseif placeholder == "file_path_relative" then
        return vim.fn.fnameescape(vim.fn.expand("%"))
    elseif placeholder == "file_name" then
        return get_current_file_name()
    elseif placeholder == "file_name_no_extension" then
        return string_utils.slice_from_start_up_to_last_occur_char(
            get_current_file_name(),
            "."
        )
    elseif placeholder == "file_type" then
        return vim.bo.filetype
    elseif placeholder == "file_extension" then
        return string_utils.slice_from_last_occur_char_to_end(
            get_current_file_name(),
            "."
        )
    elseif placeholder == "dir_path" then
        return vim.fn.fnameescape(vim.fn.expand("%:p:h"))
    elseif placeholder == "dir_name" then
        return vim.fn.fnameescape(vim.fn.expand("%:p:h:t"))
    elseif placeholder == "cwd_path" then
        return get_current_working_dir_path()
    elseif placeholder == "cwd_name" then
        return string_utils.slice_from_last_occur_char_to_end(
            get_current_working_dir_path(),
            "/"
        )
    elseif placeholder == "cword" then
        return vim.fn.expand("<cword>")
    elseif placeholder == "cWORD" then
        return vim.fn.expand("<cWORD>")
    elseif placeholder == "pilot_data_path" then
        return pathfinder.get_pilot_data_path()
    end
    error(
        string.format(
            "[Pilot] Error: Unknown command placeholder '%s'. Surround it with {} to escape.",
            placeholder
        )
    )
end

---@param command string
---@return string
local function interpolate_command(command)
    local required_braces = 2
    local pattern = "({+)([^}]+)(}+)"

    local result = command:gsub(
        pattern,
        function(open_braces, placeholder, closing_braces)
            local open_count = #open_braces
            local close_count = #closing_braces

            if
                open_count > required_braces
                and close_count > required_braces
            then
                return open_braces:sub(1, open_count - 1)
                    .. placeholder
                    .. closing_braces:sub(1, close_count - 1)
            elseif
                open_count < required_braces
                or close_count < required_braces
            then
                return open_braces .. placeholder .. closing_braces
            end

            local interpolated = resolve_command_placeholder(placeholder)
            if open_count > required_braces then
                interpolated = open_braces:sub(1, open_count - required_braces)
                    .. interpolated
            end
            if close_count > required_braces then
                interpolated = interpolated
                    .. closing_braces:sub(1, close_count - required_braces)
            end
            return interpolated
        end
    )
    return result
end

return interpolate_command
